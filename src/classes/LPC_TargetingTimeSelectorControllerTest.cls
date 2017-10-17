/**
 * Task #9389 - CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements 
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: 
 *	- test class of LPC_TargetingTimeSelectorController
 * @references: 
 *	- 
 * @changeLog:
 *
 */
@isTest
public class LPC_TargetingTimeSelectorControllerTest {
    
    static TestDataGenerator testDATA = new TestDataGenerator();
    static OpportunityLineItem oppItem;
    static void setup(){
        
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createOppTeamMember(testDATA.opp.id);
        testDATA.createNewOppItemsDart(testDATA.opp.id, 2, DARTUtil.DART6, testDATA.targetting[0].Id);
        
        oppItem = [Select Id, Targeting__c From OpportunityLineItem limit 1];
                
    }
        
    @isTest static void testTargetingTimeSelector(){
        
        setup();
        
        RemoteResponse response = LPC_TargetingTimeSelectorController.getTargetingTimeSelector(oppItem.Id);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(response.content != null);
        
        Map<String, Object>mData = new Map<String, Object>{
            'DFP_Time_Monday__c' => '0:00 - 0:59',
            'DFP_Time_Tuesday__c' => '1:00 - 1:59',
            'DFP_Time_Wednesday__c' => '2:00 - 2:59',
            'DFP_Time_Thursday__c' => '3:00 - 3:59',
            'DFP_Time_Friday__c' => '4:00 - 4:59',
            'DFP_Time_Saturday__c' => '5:00 - 5:59',
            'DFP_Time_Sunday__c' => '6:00 - 6:59'
        };
        String timeSelector = JSON.serialize(mData);
        response = LPC_TargetingTimeSelectorController.saveTargetingTimeSelector(oppItem.Id, timeSelector);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        
        response = LPC_TargetingTimeSelectorController.getTargetingTimeSelectorTemplate(oppItem.Targeting__c);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(response.content != null);
        
        response = LPC_TargetingTimeSelectorController.saveTargetingTimeSelectorTemplate(oppItem.Targeting__c, timeSelector);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(response.content != null);
        
    }
    
}