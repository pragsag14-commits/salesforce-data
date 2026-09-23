public with sharing class OppDuplicate {
    @AuraEnabled(cacheable=false)
    public static List<OpportunityWrapper> checkDuplicates(Id accountId) {
        List<OpportunityWrapper> wrappers = new List<OpportunityWrapper>();
        
        // Find open opportunities under this specific account
        for (Opportunity opp : [
            SELECT Id, Name, StageName, CreatedDate, Owner.Name 
            FROM Opportunity 
            WHERE AccountId = :accountId 
            AND IsClosed = false
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ]) {
            wrappers.add(new OpportunityWrapper(opp));
        }
        return wrappers;
    }

    // Wrapper class to flatten the data for the LWC Datatable
    public class OpportunityWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String stage;
        @AuraEnabled public DateTime createdDate;

        public OpportunityWrapper(Opportunity opp) {
            this.id = opp.Id;
            this.name = opp.Name;
            this.ownerName = opp.Owner.Name;
            this.stage = opp.StageName;
            this.createdDate = opp.CreatedDate;
        }
    }
}