@isTest
private class TST_BAT_ActivateFreespeeNumber extends TSTDF_Base{
    public TST_BAT_ActivateFreespeeNumber(TSTDF_Dataset dataset) {
        super(dataset);
    }
    
	public class TSTDF_Dataset extends TSTDF_BaseDataSet {
        public override List<Webservice_Settings__c> constructWebserviceSettings(List<Webservice_Settings__c> wss){
            wss = new List<Webservice_Settings__c>();
            wss.add(new Webservice_Settings__c(Name = WSC_Freespee.APINAME + '_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
            wss.add(new Webservice_Settings__c(Name = WSC_Freespee.APINAME + '_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
            return wss;
        }
    }
    
	public static TST_BAT_ActivateFreespeeNumber factory = new TST_BAT_ActivateFreespeeNumber(new TST_BAT_ActivateFreespeeNumber.TSTDF_Dataset());
	
	@testSetup static void setup(){
        UTIL.isRunningTestSetup = true;
        TST_BAT_ActivateFreespeeNumber.factory.createTestSet();
    }
    
    static testMethod void testActivateNumber() {
    	Account acc = [select id from Account limit 1]; 
    	acc.Phone = '+39085593300003'; 
    	acc.UniquePlatformId__c = 'ECITA-2961564';
    	update acc;
    	
    	Test.startTest();
    		Set<String> localPlatformIds = new Set<String>{'11111','222222','2961564' };
    		BAT_ActivateFreespeeNumber batch = new BAT_ActivateFreespeeNumber(localPlatformIds);
    		Database.executeBatch(batch, 1);
    	Test.stopTest();
    	
    	acc = [select id, CustomerId__c, SourceId__c, CallTrackingPhoneNumber__c from Account where id = :acc.id];
    	system.assertEquals(acc.CustomerId__c, 808117);
    	system.assertEquals(acc.SourceId__c, 501556018);
    	system.assertEquals(acc.CallTrackingPhoneNumber__c, '+390859960036');
    }
}