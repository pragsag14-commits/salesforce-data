public class OpportunityTriggerHandler {
    //Description, Amount as well as LeadSource 
    public static void handleBeforeInsert(List<Opportunity> newOpp){
        for(Opportunity opp: newOpp){
            if(String.isBlank(opp.Description)){
                opp.Description = 'Opportunity created through Salesforce';
            }
            if(opp.Amount == null || opp.Amount <= 0){
                opp.addError('Opportunity amount must be greater than 0');
            }
            if(String.isBlank(opp.LeadSource)){
                opp.LeadSource = 'Web';
            }
        }
    }
    //Opportunity Closed Won update custom field of Account
    public static void handleUpdateStage(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunityMap){
       Set<Id> accountIds = new Set<Id>();

        for (Opportunity opp : newOpportunities) {

            Opportunity oldOpp = oldOpportunityMap.get(opp.Id);

            if (
                opp.StageName == 'Closed Won' &&
                oldOpp.StageName != 'Closed Won' &&
                opp.AccountId != null
            ) {
                accountIds.add(opp.AccountId);
            }
        }

        if(accountIds.isEmpty()){
            return;
        }

        List<Account> accountsToUpdate = [
            SELECT Id, Has_Won_Opportunity__c
            FROM Account
            WHERE Id IN :accountIds
        ];

        for (Account acc : accountsToUpdate) {
            acc.Has_Won_Opportunity__c = true;
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}