@isTest
public class TST_WSI_Lead {
    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
		UTIL.isRunningTestSetup = false;
    }
    @isTest 
    static void test_reOwnerLead() {
    	// retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        
        MemberUnit__c mu = [SELECT Id, Member__c FROM MemberUnit__c LIMIT 1];
        // Create SIC__c 
        SIC__c sic = new SIC__c(Name='Test', Code__c='123456');
        insert sic;
        
        Test.startTest();
        	// Create lead
	        Lead l = new Lead();
	        l.FirstName = 'Test';
	        l.LastName = 'Lead';
	        l.Company = 'Test Company';
	        l.Email = 'test@lead.com';
	        l.OwnerId = fac.testUser.id;
	        l.Member__c = mu.Member__c;
	        l.MemberUnit__c = mu.Id;
	        l.Type__c = 'Advertising';
	        l.SIC__c = sic.Id;
	        l.LeadSource = 'Advertisement';
	        
	        insert l;
	        
	        WSI_Lead.reOwnerLead(l.OwnerId);
	    Test.stopTest();
    }
}