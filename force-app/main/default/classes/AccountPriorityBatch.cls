// Task 3: Update Account Based on Contacts
// Requirement:
// For every Account:
// Count related Contacts.
// If Contact count is greater than 5, set CustomerPriority__c = 'High'.
// Otherwise, set CustomerPriority__c = 'Medium'
public class AccountPriorityBatch implements Database.Batchable<sObject>, System.Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Fetch accounts and up to 6 contacts per account to prevent governor limit hits
        return Database.getQueryLocator([
            SELECT Id, CustomerPriority__c, (SELECT Id FROM Contacts LIMIT 6) 
            FROM Account
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : scope) {
            // Evaluates to 'High' if 6 or more contacts exist, otherwise 'Normal'
            String targetPriority = (acc.Contacts.size() > 5) ? 'High' : 'Normal';

            // Only stage for update if value actually changed
            if (acc.CustomerPriority__c != targetPriority) {
                acc.CustomerPriority__c = targetPriority;
                accountsToUpdate.add(acc);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            Database.update(accountsToUpdate, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('AccountPriorityBatch execution completed.');
    }

    public void execute(System.SchedulableContext sc) {
        AccountPriorityBatch batchJob = new AccountPriorityBatch();
        Database.executeBatch(batchJob, 200);
    }
}