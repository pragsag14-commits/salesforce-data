public class AccountContactFutureHandler {

    @future
    public static void updateRelatedContacts(Set<Id> accountIds) {

        try {
            List<Contact> contacts = [
                SELECT Id, Status__c, AccountId
                FROM Contact
                WHERE AccountId IN :accountIds
                AND Account.Status__c = 'Processed'
            ];

            for (Contact con : contacts) {
                con.Status__c = 'Processed';
            }
            if (!contacts.isEmpty()) {
                update contacts;
            }
        } catch (Exception e) {
            System.debug('Error while updating Contacts: ' + e.getMessage());
        }
    }
}