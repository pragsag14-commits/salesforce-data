public with sharing class JiraFlowInvoker {

    @InvocableMethod(label='Create Jira Issue'
                     description='Invokes Queueable to create Jira Issue from Case')
    public static void createJiraIssue(List<Id> caseIds) {

        if(caseIds == null || caseIds.isEmpty()){
            return;
        }

        List<Case> caseList = [
            SELECT Id,
                   CaseNumber,
                   Subject,
                   Description,
                   Priority,
                   Origin,
                   Status
            FROM Case
            WHERE Id IN :caseIds
        ];

        for(Case c : caseList){

            // Determine Jira Issue Type
            String jiraIssueType = JiraRoutingService.determineIssueType(c);

            // Queue the callout
            System.enqueueJob(
                new JiraCreateIssueQueueable(
                    c.Id,
                    jiraIssueType
                )
            );
        }
    }

}