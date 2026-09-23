public class AccountFutureHandler {
    @future
    public static void updateAccounts(Set<Id> accountIds) {
        try {
            List<Account> accounts = [
                SELECT Id, Description
                FROM Account
                WHERE Id IN :accountIds
            ];

            for (Account acc : accounts) {
                acc.Description = 'Processed by Future';
            }

            if (!accounts.isEmpty()) {
                update accounts;
            }

        } catch (Exception e) {
            System.debug('Error in Future Method: ' + e.getMessage());
        }
    }
    public static void processAccounts(Set<Id> accountIds) {
        updateAccounts(accountIds);
    }
}