/**
 */
@isTest
private class TST_Q_SyncOliStatus {

    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }
    
    @isTest
    static void testSyncOliStatus() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();

        Test.startTest();
        UTIL.log('_'); // Log to ensure limits are reset, Spring 16 bug...
        System.runAs ( fac.testUser ) {
            fac.opp.ApprovalStatus__c = 'Previously Approved';
            update fac.opp;
            TST_DataFactory.completeAccountDetails(fac.acc, fac.con);
        }
		Q_SyncOliStatus qsync = new Q_SyncOliStatus();
        System.enqueueJob(qsync);
        qsync.readyForRun();
        qsync.getNumRecords();
        Test.stopTest();
        
    }
}