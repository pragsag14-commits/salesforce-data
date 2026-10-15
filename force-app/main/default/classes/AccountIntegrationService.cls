@RestResource(urlMapping='/v1/AccountService/*')
global with sharing class AccountIntegrationService {

    //fetch account by Id
    @HttpGet
    global static Account getAccount(){
        RestRequest req = RestContext.request;
        String accId = req.params.get('id');
        return [SELECT Id, Name, Industry FROM Account WHERE Id = :accId LIMIT 1];
    }

    //POST Request - create a new Account
    @HttpPost
    global static String createAccount(String name, String industry){
        Account acc = new Account( 
            Name = name,
            Industry = industry
            );
            insert acc;
            return acc.Id;
    }
}
