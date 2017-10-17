/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: 
 *  - test class of LPC_PageHeaderController
 * @references: 
 *  
 * @changeLog:
 *  - Task #11287: CD-2433 PLACEHOLDER - Add primary contact in salespath 
 *
 */
@isTest
public class LPC_PageHeaderControllerTest {
    
    static TestDataGenerator testDATA = new TestDataGenerator();
    static String oppId;
    static String primaryContactId;
    static String accId;
    static void setup(){
        
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createContact(testDATA.lstAcc.get(0));
                
        oppId = [Select Id From Opportunity limit 1].Id;
        primaryContactId = [Select id From Contact limit 1].Id;
        accId = [Select Id From Account limit 1].Id;
    }
        
    @isTest static void testPageHeaderMethods(){
        
        setup();
        
        RemoteResponse response = LPC_PageHeaderController.followOpp(oppId);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        
        EntitySubscription e = LPC_PageHeaderController.getEs(oppId);
        System.assert(e != null);
        
        response = LPC_PageHeaderController.unFollowOpp(oppId);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        
        // 09-May-2017 - GIS-DevTeam - Task #11287: CD-2433 PLACEHOLDER - Add primary contact in salespath
        LPC_PageHeaderController.updatePrimaryContact(oppId, primaryContactId);
        
        Opportunity opp = [Select id, Primary_Contact__c From Opportunity Where id =: oppId];
        System.assertEquals(primaryContactId, opp.Primary_Contact__c);
        
        List<String> lsCur = LPC_PageHeaderController.getCurrency();
        System.assert(lsCur.size() > 0);
        
        List<String> lsSource = LPC_PageHeaderController.getLeadSource();
        System.assert(lsSource.size() > 0);
        
        List<String> lsStagName = LPC_PageHeaderController.getStageNameList();
        System.assert(lsStagName.size() > 0);
        
        List<String> lsPv = LPC_PageHeaderController.getProductLineValues();
        System.assert(lsPv.size() > 0);
        
        List<String> lsLV = LPC_PageHeaderController.getLostReasonValues();
        System.assert(lsLV.size() > 0);
        
        RemoteResponse res = LPC_PageHeaderController.updateOpportunityDetail(opp.Id, opp);
        System.assert(RemoteResponse.STATUSCODE_OK == res.statusCode);
        
        List<sObject> lo = LPC_PageHeaderController.getAccDet2(accId);
        System.assert(lo.size() > 0);
        
        Opportunity oppTest = new Opportunity(
                Name='Test Opp1',
                StageName='Out of Date',
            CloseDate=date.newInstance(System.today().year(), System.today().month()+1, 01),
            Type='Existing Business',
            CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY,
            Ad_Client_ID__c='123456', // networkID
            MemberUnit__c = opp.MemberUnit__c
        );
        String oppJson = JSON.serialize(oppTest);
        String resCreateOpp = LPC_PageHeaderController.createOpp2(oppJson, accId);
        System.assert(resCreateOpp != 'success');
        
        String resStatus = LPC_PageHeaderController.deleteStreamingApiRecord();
        System.assert(resStatus == 'Success');
        
        String cur = LPC_PageHeaderController.getDefaultCurrency(accId);
        System.assert(resStatus != '');
    }
    
}