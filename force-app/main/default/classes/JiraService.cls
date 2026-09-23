public with sharing class JiraService {

    private static final Integer MAX_RETRIES = 3;
    private static final String JIRA_BASE_URL = 'https://project-site-bluethink.atlassian.net/browse/';

    public static void createIssue(Id caseId, String jiraIssueType) {

        Case caseRecord = [
            SELECT Id, Subject, Description, Priority, CaseNumber,
                   Jira_Issue_Key__c, Jira_Retry_Count__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        // Read the current retry count directly off the Case rather than
        // passing it as a parameter — keeps this method's signature
        // identical to the original, so JiraCreateIssueQueueable.cls never
        // needs to change at all (avoids a circular save-order dependency
        // between the two classes).
        Integer retryCount = caseRecord.Jira_Retry_Count__c != null
            ? Integer.valueOf(caseRecord.Jira_Retry_Count__c)
            : 0;

        // Idempotency guard — don't create a second Jira ticket for a Case
        // that already has one, even if this method gets called again.
        if (String.isNotBlank(caseRecord.Jira_Issue_Key__c)) {
            System.debug('Case ' + caseRecord.CaseNumber + ' already has Jira key, skipping.');
            return;
        }

        Http http = new Http();
        Integration_Log__c logRecord = new Integration_Log__c(
            Related_Case__c   = caseRecord.Id,
            Direction__c      = 'SF to Jira',
            Timestamp__c      = System.now()
        );

        try {

            Jira_Mapping__mdt mapping = getMapping(jiraIssueType);

            if (mapping == null) {
                logAndFail(caseRecord, 'No Jira_Mapping__mdt record found for issue type: ' + jiraIssueType, null);
                return;
            }

            String requestBody = JiraPayloadBuilder.buildPayload(caseRecord, mapping);
            logRecord.Request_Payload__c = requestBody;

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Jira_Named_Credential/rest/api/3/issue');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBody);

            HttpResponse res = http.send(req);
            logRecord.Http_Status_Code__c = res.getStatusCode();
            logRecord.Response_Payload__c = res.getBody();

            if (res.getStatusCode() == 201) {

                Map<String, Object> responseMap =
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                String jiraKey = (String) responseMap.get('key');

                // The create-issue response does NOT include the initial
                // workflow status — Jira Cloud only returns id/key/self here.
                // Do one follow-up GET to read the real status name instead
                // of hardcoding "To Do", which breaks the moment someone
                // changes the Jira project's workflow.
                String initialStatus = fetchIssueStatus(jiraKey);

                caseRecord.Jira_Issue_Key__c  = jiraKey;
                caseRecord.Jira_Issue_Type__c = jiraIssueType;
                caseRecord.Jira_Status__c     = initialStatus;
                caseRecord.Jira_Issue_URL__c  = JIRA_BASE_URL + jiraKey;
                caseRecord.Jira_Sync_Status__c = 'Success';
                caseRecord.Jira_Sync_Error__c  = null;
                update caseRecord;

                logRecord.Jira_Key__c = jiraKey;
                logRecord.Status__c   = 'Success';

            } else {
                handleFailure(caseRecord, jiraIssueType, retryCount,
                              'Jira returned status ' + res.getStatusCode() + ': ' + res.getBody());
                logRecord.Status__c = 'Failed';
            }

        } catch (Exception ex) {
            logRecord.Status__c = 'Failed';
            logRecord.Response_Payload__c = ex.getMessage();
            handleFailure(caseRecord, jiraIssueType, retryCount, ex.getMessage());
        }

        insert logRecord;
    }

    /**
     * Follow-up GET to read the actual initial status name for a newly
     * created issue, rather than assuming "To Do".
     */
    private static String fetchIssueStatus(String jiraKey) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Jira_Named_Credential/rest/api/3/issue/' + jiraKey + '?fields=status');
            req.setMethod('GET');
            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> fields = (Map<String, Object>) body.get('fields');
                Map<String, Object> status = (Map<String, Object>) fields.get('status');
                return (String) status.get('name');
            }
        } catch (Exception ex) {
            System.debug('Could not fetch initial status for ' + jiraKey + ': ' + ex.getMessage());
        }
        // Fall back to a neutral placeholder rather than a guessed status name —
        // the scheduled/webhook sync will correct this on the next update anyway.
        return 'Unknown';
    }

    private static Jira_Mapping__mdt getMapping(String jiraIssueType) {
        List<Jira_Mapping__mdt> mappings = [
            SELECT DeveloperName, Keyword_Filter__c, Jira_Project_Key__c, Jira_Issue_Type__c
            FROM Jira_Mapping__mdt
            WHERE Jira_Issue_Type__c = :jiraIssueType
            LIMIT 1
        ];
        if (!mappings.isEmpty()) {
            return mappings[0];
        }
        List<Jira_Mapping__mdt> defaultMapping = [
            SELECT DeveloperName, Keyword_Filter__c, Jira_Project_Key__c, Jira_Issue_Type__c
            FROM Jira_Mapping__mdt
            LIMIT 1
        ];
        return defaultMapping.isEmpty() ? null : defaultMapping[0];
    }

    private static void handleFailure(Case caseRecord, String jiraIssueType, Integer retryCount, String errorMessage) {
        Integer nextRetry = (retryCount == null ? 0 : retryCount) + 1;

        caseRecord.Jira_Sync_Error__c   = errorMessage.abbreviate(32000);
        caseRecord.Jira_Retry_Count__c  = nextRetry;

        if (nextRetry < MAX_RETRIES) {
            caseRecord.Jira_Sync_Status__c = 'Retry Scheduled';
            update caseRecord;
            // Chain another attempt. Kept simple (immediate re-enqueue) for the
            // POC — a production version should add a short delay via
            // Scheduled Apex instead of retrying instantly. Uses the original
            // 2-argument constructor — the updated retry count is already
            // saved on the Case above, so the next run will read it fresh.
            System.enqueueJob(new JiraCreateIssueQueueable(caseRecord.Id, jiraIssueType));
        } else {
            caseRecord.Jira_Sync_Status__c = 'Failed';
            update caseRecord;
            // TODO: notify an admin here — email alert or Chatter post —
            // so a failed sync is never only visible on the Case record.
        }
    }

    private static void logAndFail(Case caseRecord, String errorMessage, String responsePayload) {
        caseRecord.Jira_Sync_Status__c = 'Failed';
        caseRecord.Jira_Sync_Error__c   = errorMessage;
        update caseRecord;

        insert new Integration_Log__c(
            Related_Case__c    = caseRecord.Id,
            Direction__c       = 'SF to Jira',
            Timestamp__c       = System.now(),
            Status__c          = 'Failed',
            Response_Payload__c = responsePayload != null ? responsePayload : errorMessage
        );
    }
}