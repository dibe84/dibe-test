/**
 * @CreatedDate: 17-11-2016
 * @CreatedBy: Sochanra
 * @Desc: Test logic on Q_SyncCreditRating.cls
 */
@isTest
private class Test_Q_SyncCreditRating {

	@testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }
    
    @isTest
    static void testSyncCreditRating() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();

        Test.startTest();
        UTIL.log('_'); // Log to ensure limits are reset, Spring 16 bug...
        System.runAs ( fac.testUser ) {
            fac.opp.ApprovalStatus__c = 'Previously Approved';
            update fac.opp;
            
            TST_DataFactory.completeAccountDetails(fac.acc, fac.con);
        }
        Set<Id> accountIdSet = new Set<Id>();
		accountIdSet.add(fac.acc.Id);
        System.enqueueJob( new Q_SyncCreditRating( accountIdSet ) );
        Test.stopTest();
        List<Account> accs = [Select id, sic, Sic__c, SicDesc From Account Where id =: fac.acc.id];
        //After the process the Sic and SicDesc of account must be filled with the correct value from SIC__c)
        System.assertEquals(fac.sic.Code__c, accs[0].sic);
        System.assertEquals(fac.sic.Name, accs[0].SicDesc);
        System.assertEquals(fac.sic.Id, accs[0].SIC__c);
        
    }
}