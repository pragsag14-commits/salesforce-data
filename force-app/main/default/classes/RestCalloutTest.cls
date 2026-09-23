@isTest
private class RestCalloutTest {
    @isTest
    static void testFutureCallout() {
        Test.startTest();
        RestCallout.getQuote(
            'SELECT Id FROM Account'
        );
        Test.stopTest();
    }
}