public class AccountContactFutureHandler {

    @future
    public static void updateRelatedContacts(Set<Id> accountIds) {

        try {

            // Query all Contacts related to the given Accounts
            List<Contact> contacts = [
                SELECT Id, Status__c, AccountId
                FROM Contact
                WHERE AccountId IN :accountIds
                AND Account.Status__c = 'Processed'
            ];

            // Update the Contact Status
            for (Contact con : contacts) {
                con.Status__c = 'Processed';
            }

            // Save the Contact changes
            if (!contacts.isEmpty()) {
                update contacts;
            }

        } catch (Exception e) {

            System.debug('Error while updating Contacts: ' + e.getMessage());

        }
    }
}