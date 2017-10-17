/**
 * Test class for SchRetrieveLineItemFromDFP.cls
 */
@isTest
private class SchRetrieveLineItemFromDFPTest{
	static TestDataGenerator testDATA = new TestDataGenerator();
	static testMethod void testSch(){
		test.startTest();
			// Generate data opp/oppItem
            testDATA.createTestUser();
            testDATA.createCredential();
            testDATA.createTargetingHierarchy();
            testDATA.createAccount();
            testDATA.createAdvertiser();
            testDATA.createOpp(testDATA.lstAcc.get(0));
            testDATA.createOppTeamMember(testDATA.opp.id);
            testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
			String CRON_EXP = '0 0 0 1 1 ? 2025';  
            //String jobId = System.schedule('testScheduledApex', CRON_EXP, new SchRetrieveLineItemFromDFP() );
            SchRetrieveLineItemFromDFP.start();
		test.stopTest();
		
	}
}