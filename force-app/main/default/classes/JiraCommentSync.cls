global class JiraCommentSync implements Database.Batchable<sObject>, Database.AllowsCallouts {

    // ---------- BATCH ENTRY ----------
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Jira_Issue_Key__c, Last_Comment_Sync__c
            FROM Case
            WHERE Jira_Issue_Key__c != null AND IsClosed = false
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Jira_Comment__c> commentsToUpsert = new List<Jira_Comment__c>();
        List<Case> casesToUpdate = new List<Case>();

        for (Case c : scope) {
            List<Jira_Comment__c> fetched = fetchAndPrepareComments(c);
            if (!fetched.isEmpty()) {
                commentsToUpsert.addAll(fetched);
                c.Last_Comment_Sync__c = System.now();
                casesToUpdate.add(c);
            }
        }

        if (!commentsToUpsert.isEmpty()) {
            Database.upsert(commentsToUpsert, Jira_Comment__c.Jira_Comment_Id__c, false);
        }
        if (!casesToUpdate.isEmpty()) {
            Database.update(casesToUpdate, false);
        }
    }

    global void finish(Database.BatchableContext bc) {}

    // ---------- CALLOUT + PREPARE ----------
    private List<Jira_Comment__c> fetchAndPrepareComments(Case c) {
        List<Jira_Comment__c> prepared = new List<Jira_Comment__c>();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Jira_Named_Credential/rest/api/3/issue/'
                         + c.Jira_Issue_Key__c + '/comment?orderBy=created');
        req.setMethod('GET');

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            return prepared;
        }

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> comments = (List<Object>) body.get('comments');
        if (comments == null) return prepared;

        for (Object co : comments) {
            Map<String, Object> cm = (Map<String, Object>) co;
            DateTime createdDt = parseJiraDate((String) cm.get('created'));

            // Skip comments already synced (efficiency)
            if (c.Last_Comment_Sync__c != null && createdDt <= c.Last_Comment_Sync__c) {
                continue;
            }

            Jira_Comment__c rec = new Jira_Comment__c();
            rec.Jira_Comment_Id__c   = (String) cm.get('id');
            rec.Related_Case__c      = c.Id;
            rec.Jira_Issue_Key__c    = c.Jira_Issue_Key__c;
            rec.Comment_Body__c      = toPlainText((Map<String, Object>) cm.get('body'));
            rec.Author_Name__c       = (String) ((Map<String, Object>) cm.get('author')).get('displayName');
            rec.Jira_Created_Date__c = createdDt;
            rec.Jira_Updated_Date__c = parseJiraDate((String) cm.get('updated'));

            prepared.add(rec);
        }
        return prepared;
    }

    // ---------- PARSING HELPER ----------
    private static String toPlainText(Map<String, Object> adfBody) {
        if (adfBody == null) return '';
        String result = '';
        List<Object> content = (List<Object>) adfBody.get('content');
        if (content != null) {
            for (Object block : content) {
                result += extractText((Map<String, Object>) block) + '\n';
            }
        }
        return result.trim();
    }

    private static String extractText(Map<String, Object> node) {
        String text = '';
        if (node.get('type') == 'text') {
            text += (String) node.get('text');
        }
        List<Object> children = (List<Object>) node.get('content');
        if (children != null) {
            for (Object child : children) {
                text += extractText((Map<String, Object>) child);
            }
        }
        return text;
    }

    private static DateTime parseJiraDate(String jiraDate) {
        if (String.isBlank(jiraDate)) return null;
        return (DateTime) JSON.deserialize('"' + jiraDate + '"', DateTime.class);
    }
}