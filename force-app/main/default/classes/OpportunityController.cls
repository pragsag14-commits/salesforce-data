public with sharing class OpportunityController{
        
        //for detailed page
        @AuraEnabled(cacheable=true)
        public static Opportunity getOpportunity(Id opportunityId) {
        return [
            SELECT Id,
                   Name,
                   AccountId,
                   Account.Name,
                   StageName,
                   Amount,
                   Probability,
                   OwnerId,
                   Owner.Name,
                   CloseDate,
                   ExpectedRevenue
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunities(String searchKey) {

        String keyword = '%' + (searchKey == null ? '' : searchKey.trim()) + '%';

        return [
            SELECT
                Id,
                Name,
                StageName,
                Amount,
                Probability,
                ExpectedRevenue,
                CloseDate,
                AccountId,
                Account.Name,
                OwnerId,
                Owner.Name,
                Region__c
            FROM Opportunity
            WHERE
                Name LIKE :keyword
                OR Account.Name LIKE :keyword
                OR StageName LIKE :keyword
                OR Owner.Name LIKE :keyword
            ORDER BY LastModifiedDate DESC
        ];
    }

    @AuraEnabled
    public static void updateOpportunityStage(List<Id> opportunityIds, String stageName, String reason){

        List<Opportunity> oppList = [
            SELECT Id, StageName, Closed_Lost_Reason__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];

        for (Opportunity opp : oppList) {
            opp.StageName = stageName;
            if (stageName == 'Closed Lost') {
                opp.Closed_Lost_Reason__c = reason;
            } else {
                opp.Closed_Lost_Reason__c = null;
            }
        }

        update oppList;
    }

    @AuraEnabled
    public static void assignOwner(List<Id> opportunityIds, Id ownerId) {

        List<Opportunity> oppList = [
            SELECT Id, OwnerId
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];

        for (Opportunity opp : oppList) {
            opp.OwnerId = ownerId;
        }

        update oppList;
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getUsers() {
        return [
            SELECT Id, Name
            FROM User
            WHERE IsActive = true
            ORDER BY Name
        ];
    }

    // Returns available Opportunity stages from the org as { label, value } pairs for LWC picklists
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getOpportunityStages() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (OpportunityStage s : [SELECT MasterLabel, ApiName, SortOrder FROM OpportunityStage ORDER BY SortOrder]) {
            Map<String, String> opt = new Map<String, String>();
            opt.put('label', s.MasterLabel);
            opt.put('value', s.MasterLabel);
            options.add(opt);
        }
        return options;
    }

    // Returns available Region values (label,value) for LWC picklists. Tries field describe picklist first and falls back to distinct values on Opportunity.
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRegions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            Schema.DescribeFieldResult d = Opportunity.Region__c.getDescribe();
            for (Schema.PicklistEntry pe : d.getPicklistValues()) {
                if (pe.isActive()) {
                    Map<String, String> opt = new Map<String, String>();
                    opt.put('label', pe.getLabel());
                    opt.put('value', pe.getValue());
                    options.add(opt);
                }
            }
        } catch (Exception e) {
            // ignore and fallback to aggregate query below
        }

        if (options.isEmpty()) {
            for (AggregateResult ar : [SELECT Region__c region FROM Opportunity WHERE Region__c != NULL GROUP BY Region__c ORDER BY Region__c]) {
                String r = (String) ar.get('region');
                Map<String, String> opt = new Map<String, String>();
                opt.put('label', r);
                opt.put('value', r);
                options.add(opt);
            }
        }

        return options;
    }

    // Fetch opportunities filtered by stage names, regions (both multi-select) and/or close date. Falls back to name/account/owner search when no filters are provided.
    @AuraEnabled
    public static List<Opportunity> getOpportunitiesByStages(List<String> stageNames, List<String> regionNames, String searchKey, String closeDate) {
        Date closeDateValue = String.isBlank(closeDate) ? null : Date.valueOf(closeDate);
        String keyword = '%' + (searchKey == null ? '' : searchKey.trim()) + '%';

        List<String> stageNamesBound = (stageNames == null) ? new List<String>() : stageNames;
        List<String> regionNamesBound = (regionNames == null) ? new List<String>() : regionNames;
        Boolean hasStageFilters = (stageNamesBound != null && !stageNamesBound.isEmpty());
        Boolean hasRegionFilters = (regionNamesBound != null && !regionNamesBound.isEmpty());
        Boolean hasCloseDate = (closeDateValue != null);

        if (!hasStageFilters && !hasRegionFilters && !hasCloseDate) {
            return getOpportunities(searchKey);
        }

        List<Opportunity> result;

        if (hasStageFilters && hasRegionFilters && hasCloseDate) {
            result = [
                SELECT
                    Id,
                    Name,
                    StageName,
                    Amount,
                    Probability,
                    ExpectedRevenue,
                    CloseDate,
                    AccountId,
                    Account.Name,
                    OwnerId,
                    Owner.Name,
                    Region__c
                FROM Opportunity
                WHERE
                    StageName IN :stageNamesBound
                    AND Region__c IN :regionNamesBound
                    AND (
                        Name LIKE :keyword
                        OR Account.Name LIKE :keyword
                        OR Owner.Name LIKE :keyword
                    )
                    AND CloseDate = :closeDateValue
                ORDER BY LastModifiedDate DESC
            ];
        } else if (hasStageFilters && hasRegionFilters) {
            result = [
                SELECT
                    Id,
                    Name,
                    StageName,
                    Amount,
                    Probability,
                    ExpectedRevenue,
                    CloseDate,
                    AccountId,
                    Account.Name,
                    OwnerId,
                    Owner.Name,
                    Region__c
                FROM Opportunity
                WHERE
                    StageName IN :stageNamesBound
                    AND Region__c IN :regionNamesBound
                    AND (
                        Name LIKE :keyword
                        OR Account.Name LIKE :keyword
                        OR Owner.Name LIKE :keyword
                    )
                ORDER BY LastModifiedDate DESC
            ];
        } else if (hasStageFilters && hasCloseDate) {
            result = [
                SELECT
                    Id,
                    Name,
                    StageName,
                    Amount,
                    Probability,
                    ExpectedRevenue,
                    CloseDate,
                    AccountId,
                    Account.Name,
                    OwnerId,
                    Owner.Name,
                    Region__c
                FROM Opportunity
                WHERE
                    StageName IN :stageNamesBound
                    AND (
                        Name LIKE :keyword
                        OR Account.Name LIKE :keyword
                        OR Owner.Name LIKE :keyword
                    )
                    AND CloseDate = :closeDateValue
                ORDER BY LastModifiedDate DESC
            ];
        } else if (hasRegionFilters && hasCloseDate) {
            result = [
                SELECT
                    Id,
                    Name,
                    StageName,
                    Amount,
                    Probability,
                    ExpectedRevenue,
                    CloseDate,
                    AccountId,
                    Account.Name,
                    OwnerId,
                    Owner.Name,
                    Region__c
                FROM Opportunity
                WHERE
                    Region__c IN :regionNamesBound
                    AND (
                        Name LIKE :keyword
                        OR Account.Name LIKE :keyword
                        OR Owner.Name LIKE :keyword
                    )
                    AND CloseDate = :closeDateValue
                ORDER BY LastModifiedDate DESC
            ];
        } else if (hasStageFilters) {
            result = [
                SELECT
                    Id,
                    Name,
                    StageName,
                    Amount,
                    Probability,
                    ExpectedRevenue,
                    CloseDate,
                    AccountId,
                    Account.Name,
                    OwnerId,
                    Owner.Name,
                    Region__c
                FROM Opportunity
                WHERE
                    StageName IN :stageNamesBound
                    AND (
                        Name LIKE :keyword
                        OR Account.Name LIKE :keyword
                        OR Owner.Name LIKE :keyword
                    )
                ORDER BY LastModifiedDate DESC
            ];
        } else if (hasRegionFilters) {
            result = [
                SELECT
                    Id,
                    Name,
                    StageName,
                    Amount,
                    Probability,
                    ExpectedRevenue,
                    CloseDate,
                    AccountId,
                    Account.Name,
                    OwnerId,
                    Owner.Name,
                    Region__c
                FROM Opportunity
                WHERE
                    Region__c IN :regionNamesBound
                    AND (
                        Name LIKE :keyword
                        OR Account.Name LIKE :keyword
                        OR Owner.Name LIKE :keyword
                    )
                ORDER BY LastModifiedDate DESC
            ];
        } else {
            result = [
                SELECT
                    Id,
                    Name,
                    StageName,
                    Amount,
                    Probability,
                    ExpectedRevenue,
                    CloseDate,
                    AccountId,
                    Account.Name,
                    OwnerId,
                    Owner.Name,
                    Region__c
                FROM Opportunity
                WHERE
                    (
                        Name LIKE :keyword
                        OR Account.Name LIKE :keyword
                        OR Owner.Name LIKE :keyword
                    )
                    AND CloseDate = :closeDateValue
                ORDER BY LastModifiedDate DESC
            ];
        }

        return result;
    }

    @AuraEnabled
    public static void deleteOpportunities(List<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }
        List<Opportunity> oppsToDelete = [SELECT Id FROM Opportunity WHERE Id IN :opportunityIds];
        if (!oppsToDelete.isEmpty()) {
            delete oppsToDelete;
        }
    }

}
