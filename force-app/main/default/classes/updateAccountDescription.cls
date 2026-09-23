// Task 1 — Update Accounts
// Create a Future method that accepts a Set of Account IDs.
// Requirement:
// Query the Accounts.
// Update Description = 'Processed by Future'.
// Call the Future method from another Apex method.
public class updateAccountDescription {
    @future
    public static void updateAccDesc(Set<Id> accountIds){
        List<Account> accountsToUpdate = [SELECT Id, Description FROM Account WHERE ID IN: accountIds];
        for(Account acc: accountsToUpdate){
            acc.Description = 'Processed by Future';
        }
        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate;
        }      
    }
}