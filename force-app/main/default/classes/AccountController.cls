public with sharing class AccountController {

    @AuraEnabled
    public static Account createAccount(String accName, String phone){

        Account acc = new Account(
            Name = accName,
            Phone = phone
        );

        insert acc;

        return acc;
    }

    @AuraEnabled
    public static Account getAccount(Id accountId){

        return [
            SELECT Id, Name, Phone
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static Account updateAccount(
        Id accountId,
        String accName,
        String phone
    ){

        Account acc = [
            SELECT Id, Name, Phone
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        acc.Name = accName;
        acc.Phone = phone;

        update acc;

        return acc;
    }

    @AuraEnabled
    public static void deleteAccount(Id accountId){

        delete [
            SELECT Id
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
    }
}