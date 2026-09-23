public with sharing class JiraRoutingService {

    /*
     * Determines the Jira Issue Type
     * based on Case Subject.
     */

    public static String determineIssueType(Case c){

        if(c == null){
            return 'Task';
        }

        String subject = '';

        if(c.Subject != null){
            subject = c.Subject.toLowerCase();
        }

        // -------------------------------
        // Bug Keywords
        // -------------------------------
        if(
            subject.contains('bug') ||
            subject.contains('error') ||
            subject.contains('issue') ||
            subject.contains('exception') ||
            subject.contains('failure') ||
            subject.contains('crash') ||
            subject.contains('not working')
        ){
            return 'Bug';
        }

        // -------------------------------
        // Story Keywords
        // -------------------------------
        if(
            subject.contains('feature') ||
            subject.contains('enhancement') ||
            subject.contains('improvement') ||
            subject.contains('user story') ||
            subject.contains('story')
        ){
            return 'Story';
        }

        // -------------------------------
        // Epic Keywords
        // -------------------------------
        if(
            subject.contains('epic') ||
            subject.contains('major project') ||
            subject.contains('large feature') ||
            subject.contains('new module')
        ){
            return 'Epic';
        }

        // -------------------------------
        // Task Keywords
        // -------------------------------
        if(
            subject.contains('task') ||
            subject.contains('activity') ||
            subject.contains('work item')
        ){
            return 'Task';
        }

        // -------------------------------
        // Default
        // -------------------------------
        return 'Task';
    }

}