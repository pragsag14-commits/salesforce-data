public with sharing class TestController {
    public TestController() {
        @AuraEnabled
        public static List<Opportunity> OpportunityMethod(){
            return [Name, StageName, CloseDate, Account.Name FROM Opportunity ORDER BY CreateDate DESC];
        }
    }
}