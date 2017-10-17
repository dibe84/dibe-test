@isTest
public class TST_ETC_GTAUSLeadAutoResponse {
    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }
    @isTest static void test_getApproveComment(){
    		// retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        Test.startTest();
        ETC_GTAUSLeadAutoResponse etc = new ETC_GTAUSLeadAutoResponse();
        etc.uId = fac.testUser.Id;
        String cm = etc.approvedComment;
        System.assert(cm == '');
        Test.stopTest();
    }
}