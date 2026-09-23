public with sharing class AccountSearchController {
    @AuraEnabled
    public static List<Account> searchAccounts(String searchKey) {
        if (String.isBlank(searchKey)) {
            return new List<Account>();
        }
        String key = '%' + searchKey + '%';
        return [
            SELECT Id, Name, Industry, 
                   (SELECT Id, Name, Title, Phone, Email FROM Contacts) 
            FROM Account 
            WHERE Name LIKE :key LIMIT 50
        ];
    }

    @AuraEnabled
    public static void deleteContact(String contactId) {
        try {
            delete new Contact(Id = contactId);
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting contact: ' + e.getMessage());
        }
    }
}