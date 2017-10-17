@isTest
private class TST_PGC_FreespeePopup  extends TSTDF_Base {
	public TST_PGC_FreespeePopup(TSTDF_Dataset dataset) {
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
    
	public static TST_PGC_FreespeePopup factory = new TST_PGC_FreespeePopup(new TST_PGC_FreespeePopup.TSTDF_Dataset());
	
	@testSetup static void setup(){
        UTIL.isRunningTestSetup = true;
        TST_PGC_FreespeePopup.factory.createTestSet();
    }
    
    static testMethod void testTrackingAndUntracking() {
    	Account acc = [select id from Account limit 1]; 
    	acc.Phone = '+39085593300003'; 
    	acc.UniquePlatformId__c = 'ECITA-2222';
    	update acc;
    	
    	ApexPages.StandardController sc = new ApexPages.StandardController(acc);
    	PGC_FreespeePopup con = new PGC_FreespeePopup(sc);
    	
    	Test.startTest();
    	con.doCreate();
    	acc = [select id, CustomerId__c, SourceId__c, CallTrackingPhoneNumber__c from Account where id = :acc.id];
    	system.assertEquals(acc.CustomerId__c, 808117);
    	system.assertEquals(acc.SourceId__c, 501556018);
    	system.assertEquals(acc.CallTrackingPhoneNumber__c, '+390859960036');
    	
    	con.doDelete();
    	acc = [select id, CustomerId__c, SourceId__c, CallTrackingPhoneNumber__c from Account where id = :acc.id];
    	system.assertEquals(acc.CustomerId__c, 808117);
    	system.assertEquals(acc.SourceId__c, null);
    	system.assertEquals(acc.CallTrackingPhoneNumber__c, null);
    	
    	// for coverage
    	delete [select id from Webservice_Settings__c];
    	con.doCreate();
    	con.doDelete();
    	WSC_Freespee.getErrors(null);
    	WSC_Freespee.getErrors(new UTIL_WSC.WSC_Result());
    	
    	Test.stopTest();
    }
    
}