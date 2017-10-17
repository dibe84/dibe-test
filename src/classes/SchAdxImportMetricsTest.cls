/**
 * Test class for SchRetrieveLineItemFromDFP.cls
 */
@isTest
private class SchAdxImportMetricsTest{
	static TestDataGenerator testDATA = new TestDataGenerator();
	static testMethod void testSch(){
		test.startTest();
			SchDeliveryOpportunityProduct.start();
		test.stopTest();
		
	}
}