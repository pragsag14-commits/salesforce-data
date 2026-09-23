public with sharing class JiraCreateIssueQueueable implements Queueable, Database.AllowsCallouts {

    private Id caseId;
    private String jiraIssueType;

    public JiraCreateIssueQueueable(
        Id caseId,
        String jiraIssueType
    ) {
        this.caseId = caseId;
        this.jiraIssueType = jiraIssueType;
    }

    public void execute(QueueableContext context) {

        JiraService.createIssue(
            caseId,
            jiraIssueType
        );

    }

}