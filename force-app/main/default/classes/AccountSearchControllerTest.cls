@isTest
private class AccountSearchControllerTest {

    @testSetup
    static void setupData() {

        // Create Accounts
        List<Account> accList = new List<Account>();

        accList.add(new Account(
            Name = 'ABC Technologies',
            Industry = 'Technology'
        ));

        accList.add(new Account(
            Name = 'XYZ Solutions',
            Industry = 'Banking'
        ));

        insert accList;

        // Create Contacts
        List<Contact> conList = new List<Contact>();

        conList.add(new Contact(
            LastName = 'John',
            Title = 'Manager',
            Phone = '9876543210',
            Email = 'john@test.com',
            AccountId = accList[0].Id
        ));

        conList.add(new Contact(
            LastName = 'David',
            Title = 'Developer',
            Phone = '9999999999',
            Email = 'david@test.com',
            AccountId = accList[0].Id
        ));

        insert conList;
    }

    @isTest
    static void testSearchAccounts_WithValidSearchKey() {

        Test.startTest();

        List<Account> result =
            AccountSearchController.searchAccounts('ABC');

        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('ABC Technologies', result[0].Name);
        System.assertEquals(2, result[0].Contacts.size());
    }

    @isTest
    static void testSearchAccounts_WithBlankSearchKey() {

        Test.startTest();

        List<Account> result =
            AccountSearchController.searchAccounts('');

        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @isTest
    static void testDeleteContact() {

        Contact con = [
            SELECT Id
            FROM Contact
            LIMIT 1
        ];

        Test.startTest();

        AccountSearchController.deleteContact(con.Id);

        Test.stopTest();

        Integer countContacts = [
            SELECT Count()
            FROM Contact
            WHERE Id = :con.Id
        ];

        System.assertEquals(0, countContacts);
    }
}