//Task 1: Update Inactive Accounts — Basic
// Requirement:
// Find all Accounts where:
// Active__c = false (This is a field having Yes or No into it)
// Update Status__c = 'Inactive'  - make this as a custom field having picklist values Active as well as Inactive into it

public class InactiveAccounts implements Database.Batchable<sObject>{
        public Database.QueryLocator start(Database.BatchableContext bc){
            return Database.getQueryLocator('SELECT Id, Update_Status__c, Active__c FROM Account WHERE Active__c = \'No\'');
        }
        public void execute(Database.BatchableContext query, List<Account> scope){
            List<Account> accountsToUpdate = new List<Account>();
            for(Account acc : scope) {
                if(acc.Update_Status__c != 'Inactive') {
                    acc.Update_Status__c = 'Inactive';
                    accountsToUpdate.add(acc);
                }
            }
            if(!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
        }
        public void finish(Database.BatchableContext context){
            System.debug('InActiveAccounts has finished processing.');
        }
}