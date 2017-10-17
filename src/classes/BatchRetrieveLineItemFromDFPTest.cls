/**
 *@created 16-05-2015
 *@autor: Chr
 *@desc: Testclass for BatchRetrieveLineItemValFromDFPToSF.cls
 */
 @isTest
private class BatchRetrieveLineItemFromDFPTest {
    static TestDataGenerator testDATA = new TestDataGenerator();
    static testMethod void testBatch(){
        Test.startTest();
            // Generate data opp/oppItem
            testDATA.createTestUser();
            testDATA.createCredential();
            testDATA.createTargetingHierarchy();
            testDATA.createAccount();
            testDATA.createAdvertiser();
            testDATA.createOpp(testDATA.lstAcc.get(0));
            testDATA.createOppTeamMember(testDATA.opp.id);
            testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
            BatchRetrieveLineItemFromDFP bt = new BatchRetrieveLineItemFromDFP();
            Database.executeBatch(bt, 5);
            bt = new BatchRetrieveLineItemFromDFP('123456');
        Test.stopTest();
        List<OpportunityLineItem> items = [Select id, Ad_ID__c, ExternalBillngCategory__c, ExternalEndDate__c, ExternalFromDate__c, ExternalQuantity__c, ExternalSalesPrice__c From OpportunityLineItem Where id=:testDATA.lstLineItems.get(1).id];
        
        //simulate results
        //data get from DFP DartMockup.getMockDataLineItemByStatement() 
        //mock up data timezoneId='Asia/Bangkok'
        Date dtStart = date.newInstance(2015, 01, 01);//DARTUtil.fixTimezoneDateTime('2015-01-01 14:30:20', 'Asia/Bangkok');//DateTime.newInstance(2015, 1, 1, 14, 30, 20);   
        Date dtEnd = date.newInstance(2015, 01, 31);//DARTUtil.fixTimezoneDateTime('2015-01-31 11:30:30', 'Asia/Bangkok'); //DateTime.newInstance(2015, 1, 31, 11, 30, 30);
        System.assertEquals('123456', items.get(0).Ad_ID__c, '123456, Test data from DARTMokup');
        System.assertEquals(dtEnd, items.get(0).ExternalEndDate__c, '2015-01-31 04:30:30, Test data from DARTMokup');
        System.assertEquals(dtStart, items.get(0).ExternalFromDate__c, '2015-01-01 07:30:20, Test data from DARTMokup');
        System.assertEquals('CPM', items.get(0).ExternalBillngCategory__c, 'CPM, Test data from DARTMokup');
        System.assertEquals(300, items.get(0).ExternalQuantity__c, '300, Test data from DARTMokup');
        System.assertEquals(20, items.get(0).ExternalSalesPrice__c, '20, Test data from DARTMokup');
    }
}