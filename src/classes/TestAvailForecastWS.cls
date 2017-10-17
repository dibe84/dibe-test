/**
    Test class 
     -> AvailForecastWS
     
     Created date: 19/12/2012
 */ 
 
@istest(SeeAllData=false)    
private class TestAvailForecastWS {
    static TestDataGenerator testDATA = new TestDataGenerator();

    //@vitou 08-05-2015
    static void setup() {
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createNewOppItemsDart(testDATA.opp.id,1,DARTUtil.DART6,testDATA.targetting[0].Id);
    }
    
     // Test -> selected all/no selected lineItems of Opp
    static testMethod void noItemSelectedTest() {
        setup();
        test.startTest();
            String lineItemIds = '';
            for(OpportunityLineItem oppItem : testDATA.lstLineItems) {
                lineItemIds += lineItemIds +',';
            }
            AvailForecastWS.processWebservice(testDATA.opp.Id, lineItemIds);
        test.stopTest();
    }
    
    //test dart 6 
     static testMethod void selectedSomeItemsTest6() {
        setup(); 
        test.startTest();    
            String lineItemIds = testDATA.lstLineItems.get(0).id + ',';// + lstItems.get(1).id + ',';
            String result = AvailForecastWS.processWebservice(testDATA.opp.Id, lineItemIds);
        test.stopTest();
    } 
    
    //test in exception case to increase test coverage
    static testMethod void exceptionCase() {
        setup(); 
        test.startTest();
            String result = AvailForecastWS.processWebservice(testDATA.opp.Id, '');
        test.stopTest();
        System.assertEquals(true, result.contains('Error')); 
    } 
}