/**
 	Test class 
 	 -> DARTDeliveryWS
 	 
 	 Created date: 12/02/2013
 */
@isTest 
public with sharing class TestDARTDeliveryWS {

	static TestDataGenerator testDATA = new TestDataGenerator();
	
	 //@vitou 08-05-2015
    @testSetup static void setup() {
        testDATA.createTargetingHierarchy();        
        testDATA.createAccount();
        testDATA.createAdvertiser(); 
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createNewOppItemsDart(testDATA.opp.id,1,DARTUtil.DART6,testDATA.targetting[0].Id);
    }
    
	static testMethod void testDartDevDaily()
	{       
		test.startTest();
		      String results =  DARTDeliveryWS.processImportDelivery();		
		      DARTDeliveryWS.processImportDeliveryRS_Daily();
    	test.stopTest();
		
		//System.assertEquals(results,'SUCCESS: Importing Delivery of Opportunity Product is now running in background.');
	}
    
    static testMethod void testDartDevMonthly()
	{      
		test.startTest();
		      String results =  DARTDeliveryWS.processImportDelivery();
		      DARTDeliveryWS.processImportDeliveryRS_Monthly();		
		test.stopTest();
		
		//System.assertEquals(results,'SUCCESS: Importing Delivery of Opportunity Product is now running in background.');
	}


}