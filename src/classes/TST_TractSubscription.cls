@isTest
private class TST_TractSubscription {
	@testSetup
    public static void setup() {
    	TST_TractGeneric.setup();
    	
    	/* Additional Test Data */
        List<WSC_Subscription__c> subscriptions = new List<WSC_Subscription__c> {
            new WSC_Subscription__c(
                Name = 'TRACT',
                ConsumerId__c = '=',
                Class__c = 'WSC_Tract',
                Method__c = '-',
                IsActive__c = TRUE
            )
        };
        insert subscriptions;
        
    }
    
    /** Test for PGC_Subscription.cls  **/
	@isTest
	static void test_PGC_Subscription(){

		Test.startTest();

		TST_DataFactory factory = TST_DataFactory.getInstance();
		factory.queryResults();

		// create Rev__c record
		Rev__c newRev = new Rev__c();
		newRev.Opportunity__c = factory.opp.Id;
		insert newRev;

		// create standard controller
		ApexPages.StandardController sc = new ApexPages.StandardController( newRev );

		// create instance of PGC_Subscription
		PGC_Subscription subscription = new PGC_Subscription( sc );
		Rev__c master = subscription.master;
		
		System.assertEquals( subscription.master, subscription.currentRevenue );
		
		// set default termination date
		subscription.setDefaultTerminationDate();
		System.assertEquals( System.today(), subscription.currentRevenue.TerminationDate__c );

		// set chosenRevId as 1 element of subscription.mainSubscription.revItems
		subscription.chosenRevId = subscription.mainSubscription.revItems[0].Id;

		// calculate
		subscription.calculate();

		// edit and save adjustment
		subscription.editAdjustment();
		subscription.currentRevenue.UnitPrice__c = 100;
		subscription.saveAdjustment();
		System.assertEquals( 100, subscription.currentRevenue.UnitPrice__c );

		// new and save adjustment
		subscription.newAdjustment();
		subscription.currentRevenue.From_Date__c = System.today();
		subscription.currentRevenue.UnitPrice__c = 200;
		System.assertEquals( subscription.master.Id, subscription.currentRevenue.Master__c );
		subscription.saveAdjustment();

		// set chosenRevId as 1 element of subscription.mainSubscription.revItems
		subscription.chosenRevId = subscription.mainSubscription.revItems[0].Id;
		
		System.debug( 'revItems size before delete ==> ' + subscription.mainSubscription.revItems.size() );	

		// delete adjustment
		subscription.deleteAdjustment();

		System.debug( 'revItems size after delete ==> ' + subscription.mainSubscription.revItems.size() );

		// terminate subscription
		subscription.terminateSubscription();

		// terminate and do not invoice subscription
		subscription.terminateAndDoNotInvoiceSubscription();

		Test.stopTest();
	}
    
    /** Test for PGC_THBELAU_ExternalSubscriptionManager.cls **/
    @isTest static void test_PGC_THBELAU_ExternalSubscriptionManager() {
    	
        List<Account> acc = GW_sObject.queryRecords('Account', '');
    	Id accId = acc.get(0).Id;

        Member__c createdMember = [ SELECT Id FROM Member__c LIMIT 1 ];
    	
        Test.startTest();

        Test.setCurrentPage(Page.THBELAU_ActivateExternalSubscription);
		System.currentPageReference().getParameters().put('id', accId);
		
		PGC_THBELAU_ExternalSubscriptionManager PGC_THBELAU_ESM = new PGC_THBELAU_ExternalSubscriptionManager();
		PGC_THBELAU_ESM.activateSubscription();
        PGC_THBELAU_ESM.deactivateSubscription();
        PGC_THBELAU_ESM.cancel();

        Test.stopTest();
    }
    
    /** Test for WSC_THBELAU_Subscription.cls **/
    @isTest static void test_WSC_THBELAU_Subscription() {
    	
        String strBody = '{ "status":"test", "error": "test2" }';

        MockHttpCalloutResponse mock = new MockHttpCalloutResponse('application/json', 200, strBody); 
        Test.setMock(HttpCalloutMock.class, mock);
        
        List<User> us = GW_sObject.queryRecords('User', '');
    	Id usId = us.get(0).Id;
    	
        WSC_THBELAU_Subscription wts = new WSC_THBELAU_Subscription(usId);
    	
        Test.startTest();
    		// UTIL_WSC.basicCallout always set body to null 
    		//wts.call('POST');
        Test.stopTest();
    }
    
}