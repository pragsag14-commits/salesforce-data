@isTest
private class AccountDashboardControllerTest {

    @testSetup
    static void createTestData() {

        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            Industry = 'Technology',
            Rating = 'Hot',
            AnnualRevenue = 500000
        );
        insert acc;

        // Create Contacts
        List<Contact> contacts = new List<Contact>();

        for(Integer i = 1; i <= 6; i++){
            contacts.add(new Contact(
                LastName = 'Contact ' + i,
                AccountId = acc.Id,
                Email = 'contact'+i+'@test.com',
                Phone = '999999999'+i
            ));
        }
        insert contacts;

        // Create Opportunities
        List<Opportunity> opps = new List<Opportunity>();

        opps.add(new Opportunity(
            Name='Open Opportunity 1',
            StageName='Prospecting',
            CloseDate=Date.today().addDays(10),
            Amount=1000,
            AccountId=acc.Id
        ));

        opps.add(new Opportunity(
            Name='Open Opportunity 2',
            StageName='Qualification',
            CloseDate=Date.today().addDays(20),
            Amount=2000,
            AccountId=acc.Id
        ));

        insert opps;

        // Create Cases
        List<Case> cases = new List<Case>();

        for(Integer i=1;i<=3;i++){
            cases.add(new Case(
                Subject='Case '+i,
                Status='New',
                Priority='Medium',
                AccountId=acc.Id
            ));
        }

        insert cases;

        // Create Tasks
        List<Task> tasks = new List<Task>();

        tasks.add(new Task(
            Subject='Call Customer',
            Status='Completed',
            Priority='Normal',
            TaskSubtype='Call',
            ActivityDate=Date.today(),
            WhatId=acc.Id
        ));

        tasks.add(new Task(
            Subject='Follow Up',
            Status='Not Started',
            Priority='Normal',
            ActivityDate=Date.today().addDays(-1),
            WhatId=acc.Id
        ));

        insert tasks;

        // Create Events
        Event e = new Event(
            Subject='Customer Meeting',
            StartDateTime=System.now().addDays(1),
            EndDateTime=System.now().addDays(1).addHours(1),
            WhatId=acc.Id
        );

        insert e;
    }

    @isTest
    static void testGetDashboardData() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        AccountDashboardController.DashboardWrapper wrapper =
            AccountDashboardController.getDashboardData(acc.Id);

        Test.stopTest();

        // Verify Account
        System.assertNotEquals(null, wrapper);
        System.assertNotEquals(null, wrapper.acc);

        // Verify Contacts (Recent 5)
        System.assertEquals(5, wrapper.contacts.size());

        // Verify Opportunities
        System.assertEquals(2, wrapper.opportunities.size());

        // Verify Cases
        System.assertEquals(3, wrapper.cases.size());

        // Verify Activities
        System.assert(wrapper.activities.size() > 0);

        // Verify KPIs
        System.assertEquals(3000, wrapper.kpis.totalRevenue);
        System.assertEquals(2, wrapper.kpis.totalOpenOpps);
        System.assertEquals(6, wrapper.kpis.totalContacts);
        System.assertEquals(1500, wrapper.kpis.avgDealSize);
    }

    @isTest
    static void testAccountWithoutRelatedRecords(){

        Account acc = new Account(
            Name='Empty Account'
        );

        insert acc;

        Test.startTest();

        AccountDashboardController.DashboardWrapper wrapper =
            AccountDashboardController.getDashboardData(acc.Id);

        Test.stopTest();

        System.assertEquals(0, wrapper.contacts.size());
        System.assertEquals(0, wrapper.opportunities.size());
        System.assertEquals(0, wrapper.cases.size());
        System.assertEquals(0, wrapper.activities.size());

        System.assertEquals(0, wrapper.kpis.totalRevenue);
        System.assertEquals(0, wrapper.kpis.totalOpenOpps);
        System.assertEquals(0, wrapper.kpis.totalContacts);
        System.assertEquals(0, wrapper.kpis.avgDealSize);
    }
}