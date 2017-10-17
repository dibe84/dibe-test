@isTest
private class TST_Agreement {

    private static echosign_dev1__SIGN_Agreement__c agg;
    private static echosign_dev1__SIGN_Recipients__c rec;    

    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }

    @isTest
    static void checkAgreementStatus() {
        
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();

        Test.startTest();

        System.runAs ( fac.testUser ) {

            agg = new echosign_dev1__SIGN_Agreement__c();        
            agg.name = 'TestIO';
            agg.echosign_dev1__Status__c = 'Out for Signature';
            agg.echosign_dev1__Opportunity__c = fac.opp.id;
            agg.echosign_dev1__Account__c = fac.acc.id;
            insert agg;
            
            rec = new echosign_dev1__SIGN_Recipients__c();
            rec.echosign_dev1__Agreement__c = agg.Id;
            rec.echosign_dev1__Status__c = 'Waiting for Signature';
            rec.echosign_dev1__Recipient_Role__c = 'Signer';
            rec.echosign_dev1__Recipient_Type__c = 'Email';
            insert rec; 

            rec.echosign_dev1__Status__c = 'Signed';
            update rec;
        }
            
        Test.stopTest();
    }
}