@isTest
public class TST_Lead {
    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
		UTIL.isRunningTestSetup = false;
    }
 
    
    @isTest 
    static void testLeadConversion() {
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
         
        Case c = new Case();
        c.Lead__c = l.Id;
        c.Subject = 'test case';
        c.Origin = 'ECITAAU: Campaign Response';
        
        insert c;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.id);

        LeadStatus convertStatus = [Select Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());            
        
        Case caseAfter = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :c.Id and Lead__c = :l.Id];
        System.assert(caseAfter.AccountId != null);
        System.assert(caseAfter.ContactId != null);
        
        //@Sochanra 17-11-2016
        //Test case of populate fields when converted lead to Account
        Account acc = [Select Id, Type, AccountSource, SIC__c From Account Where Id =: lcr.getAccountId()];
        System.assertEquals(l.Type__c, acc.Type);
        System.assertEquals(l.SIC__c, acc.SIC__c);
        System.assertEquals(l.LeadSource, acc.AccountSource);
                
        Test.stopTest();
    }
}