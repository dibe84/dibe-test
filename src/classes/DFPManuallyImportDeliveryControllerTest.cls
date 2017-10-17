/**
 * @Created: Sochanra(Chr) - 19-11-2015
 * @Desc: Test Biz logic in DFPManuallyImportDeliveryController.cls
 */
@isTest
private class DFPManuallyImportDeliveryControllerTest {

	static TestDataGenerator testDATA = new TestDataGenerator();
	static Rev__c rev;
	static Metric__c mtr;

	//Create data
	static void createTestData(){
        // Generate data opp/oppItem
        testDATA.createNewProduct2TypeDART(1,DARTUtil.DART6);
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(1));
        testDATA.createNewOppItemsDart(testDATA.opp.id,1,DARTUtil.DART6,testDATA.targetting[0].Id);
        List<OpportunityLineItem> items = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});

        rev = new Rev__c();

        //rev.OpportunityLineItemId__c    = items[0].Id;
        rev.Opportunity__c              = items[0].OpportunityId;
        rev.Product__c                  = items[0].PriceBookEntry.Product2Id;
        rev.from_Date__c                = items[0].from_Date__c;
        rev.until_Date__c               = items[0].until_Date__c; // default copies from items[0]
        rev.BillingCategory__c          = items[0].Billing_Category__c;
        rev.QuantityBooked__c           = items[0].Quantity;
        rev.ExtLineItemId__c            = items[0].Ad_Id__c;
		insert rev;

		RS__c rs = new RS__c();
        rs.Rev__c = rev.Id;
        rs.Opportunity__c = rev.Opportunity__c;
        rs.From_Date__c = items[0].from_Date__c;
        rs.Until_Date__c = items[0].until_Date__c;
        rs.StartOfPeriod__c = items[0].from_Date__c;
        rs.EndOfPeriod__c = items[0].until_Date__c;
        rs.UniqueKey__c = ((Datetime) items[0].from_Date__c).format('yyyyMMdd') + '_' + rev.Id + 'XX_XX'; 
        insert rs;


        List<Metric__c> lstMt = new List<Metric__c>();

		for(Date dt=items[0].from_Date__c; dt<=items[0].until_Date__c; dt = dt.addDays(1)){
		     Metric__c m = new Metric__c();
		    	m.RS__c = rs.id;
		    	m.Opportunity__c = rev.Opportunity__c;
		    	m.MetricDate__c = dt;
		        m.UniqueKey__c = ((Datetime) dt).format('yyyyMMdd');
			lstMt.add(m);
		}

		insert lstMt;

	}


    private static testMethod void testManuallyImport(){
    	createTestData();
        Test.startTest();
            Pagereference pg = Page.DFPManuallyImportDelivery;
            Test.setCurrentPageReference(pg);
            pg.getParameters().put('parId', testDATA.opp.Id);
            pg.getParameters().put('recIds',rev.Id);
            DFPManuallyImportDeliveryController controller = new DFPManuallyImportDeliveryController();
            controller.checkProductListServers();
            controller.pollReportRequest();
            controller.pollReportStatus();

            controller.pollReportRequest();
            controller.pollReportStatus();
            DFPManuallyImportDeliveryController.cancellDDS();
        Test.stopTest();

    }

}