global class JiraSyncBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    // 1. Query all unresolved cases that have a Jira ticket
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Jira_Issue_Key__c, Jira_Status__c, Jira_Sync_Status__c, Jira_Sync_Error__c 
            FROM Case 
            WHERE Jira_Issue_Key__c != null AND IsClosed = false
        ]);
    }

    // 2. Process them in batches (up to 50 at a time to stay safe on callout limits)
    global void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Case> casesToUpdate = new List<Case>();
        
        for (Case c : scope) {
            try {
                HttpRequest req = new HttpRequest();
                // Using your exact Named Credential API Name
                req.setEndpoint('callout:Jira_Named_Credential/rest/api/3/issue/' + c.Jira_Issue_Key__c + '?fields=status');
                req.setMethod('GET');
                req.setHeader('Accept', 'application/json');

                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200) {
                    // Parse the JSON response
                    Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    Map<String, Object> fields = (Map<String, Object>) results.get('fields');
                    Map<String, Object> statusNode = (Map<String, Object>) fields.get('status');
                    String jiraStatusName = (String) statusNode.get('name');

                    // If the status changed in Jira, prepare to update the Case
                    if (c.Jira_Status__c != jiraStatusName) {
                        c.Jira_Status__c = jiraStatusName;
                        c.Jira_Sync_Status__c = 'Success';
                        c.Jira_Sync_Error__c = null; // Clear any old errors
                        casesToUpdate.add(c);
                    }
                } else {
                    // Log the exact error if Jira rejects the call (e.g., ticket deleted)
                    c.Jira_Sync_Status__c = 'Failed';
                    c.Jira_Sync_Error__c = 'Sync failed. HTTP ' + res.getStatusCode() + ': ' + res.getBody();
                    casesToUpdate.add(c);
                }
            } catch (Exception e) {
                // Catch timeouts or Apex parsing crashes
                c.Jira_Sync_Status__c = 'Failed';
                c.Jira_Sync_Error__c = 'Apex Exception: ' + e.getMessage();
                casesToUpdate.add(c);
            }
        }

        // 3. Save updates back to Salesforce (allOrNone=false so one error doesn't block the rest)
        if (!casesToUpdate.isEmpty()) {
            Database.update(casesToUpdate, false); 
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Required method by the interface, but we don't need any post-processing
    }
}