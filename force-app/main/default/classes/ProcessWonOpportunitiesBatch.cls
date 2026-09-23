// Task 4: Batch Apex with Error Handling
// Requirement:
// Process all Opportunities where:
// StageName = 'Closed Won'
// For every Opportunity:
// Update Processed__c = true.
// If any record fails to update, capture its:
// Record Id
// Error message
// Store the error details in a custom object called Batch_Error__c
public class ProcessWonOpportunitiesBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Id FROM Opportunity WHERE StageName = \'Closed Won\'');
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> opp){
        for(Opportunity oppList : opp){
            oppList.Processed__c = true;
        }
        Database.SaveResult[] srList = Database.update(opp, false);
        List<Batch_Error__c> errorLogsToInsert = new List<Batch_Error__c>();
        for (Integer i = 0; i < srList.size(); i++) {
            Database.SaveResult sr = srList[i];
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    Batch_Error__c errorLog = new Batch_Error__c();
                    errorLog.Record_Id__c = opp[i].Id; 
                    errorLog.Error_Message__c = err.getMessage() + ' [Status Code: ' + err.getStatusCode() + ']';
                    errorLog.Batch_Name__c = 'ProcessWonOpportunitiesBatch';
                    
                    errorLogsToInsert.add(errorLog);
                }
            }
        }
        if (!errorLogsToInsert.isEmpty()) {
            Database.insert(errorLogsToInsert, false); 
        }
    }

    public void finish(Database.BatchableContext bc){
        System.debug('ProcessWonOpportunitiesBatch execution is complete.');
    }
}