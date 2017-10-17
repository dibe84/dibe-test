/**
   Test class 
    -> DARTBookingWS
    
    Created date: 11/02/2013
 */  
 
@istest(SeeAllData=false) 
public with sharing class TestDARTBookingWS {
  
    static TestDataGenerator testDATA = new TestDataGenerator();
    //@vitou 11-05-2015
    static void setup() {
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(1));
        testDATA.createOppTeamMember(testDATA.opp.id);
        testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id); 
    }
  
    // Test dart 6
    static testMethod void selectedSomeItemsTest6() {
        setup();
        test.startTest();
            //@vitou 11-05-2015 => get Test Data
            String lineItemIds = testDATA.lstLineItems.get(0).id + ',';
            String result = DARTBookingWS.processWebservice(testDATA.opp.Id, lineItemIds);
            System.assertEquals(result, 'OK','');
        test.stopTest();
    }   
    
    // Test Dart6 -> Account no AdvertiserId
    static testMethod void testDart6NoAdvertiserId() {
        setup();
        test.startTest();
            //@vitou 11-05-2015 => get Test Data 
            String lineItemIds = testDATA.lstLineItems.get(0).id + ',';
            DARTBookingWS.processWebservice(testDATA.opp.Id, lineItemIds);
         test.stopTest();
    }
    
    //test with failling batch
    static testMethod void failTest() {
        setup();
        test.startTest();
            //@vitou 11-05-2015 => get Test Data 
            String result = DARTBookingWS.processWebservice(testDATA.opp.Id, '');
            system.assertEquals(true, (result.contains('Error')));
        test.stopTest();
    }    
}