@isTest
public class TST_TractSyncAddr {
     
    @testSetup static void setupTestData() {
        List<Webservice_Settings__c> wss = new List<Webservice_Settings__c>();
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        insert wss;
        
        insert new WSC_Subscription__c(Name = 'TRACT', IsActive__c = true, Class__c = 'WSC_Tract', ConsumerId__c = '-', Method__c = '-');
            
        TST_DataFactory.createTestSet();
        list<Account> lstAcc = (list<Account>) GW_sObject.queryRecords('Account','');      
        Account acc = lstAcc.get(0); 
        acc.Tract_AccountId__c = '1111';
        acc.Tract_AccountNumber__c = '2222';
        acc.Tract_ResponsiblePartyId__c = '3333';
        acc.BillingStreet = 'st';
        acc.BillingState = 'Free State'; 
        acc.BillingPostalCode = '112233'; 
        acc.BillingCountryCode = 'ZA';
        acc.BillingCountry = 'South Africa';
        acc.BillingCity = 'Free State';
        update acc;
        
        TST_DataFactory.createMemberUnit(acc.id);
        MemberUnit__c mu = [select Id, name from MemberUnit__c where Member__r.Account__c =:acc.id limit 1];
        mu.EnableTRACT__c = true;
        mu.SyncAccountOnCreationLocalPlatform__c = true;
        update mu;
        TST_DataFactory.createAccountMemberUnitAssociation(mu.id, acc.id);
    }
    
    static testMethod void testBillingAccountUpdateAddr() {
        
        Test.startTest();
            list<Account> lstAcc = (list<Account>) GW_sObject.queryRecords('Account',''); 
        
            GW_AccountMemberUnitAssociation.cacheAMUAForAccounts(lstAcc);   
            Account acc = lstAcc.get(0); 
          
            Boolean isTractEnabled = UTIL_WSC_Subscription.isSubscribedToTRACT(acc);
            system.assertEquals(isTractEnabled, true);
        
            acc.BillingPostalCode = '9999'; 
            update acc;
        Test.stopTest();
    }
    
    static testMethod void testBillingAccountGetFromContact() {
        Test.startTest();
            list<Account> lstAcc = (list<Account>) GW_sObject.queryRecords('Account',''); 
            GW_AccountMemberUnitAssociation.cacheAMUAForAccounts(lstAcc);     
            
            Account acc = lstAcc.get(0);
            Contact con = GW_Contact.insertSObject('TST_TractSyncAddr', acc);
            con.Primary__c=true;
            con.isActive__c=true;
            con.Email='TST_TractSyncAddr_new@apex.test';
            con.FirstName = 'testF';
            con.LastName = 'testL';
            con.Role__c = 'Finance Contact';
            
            Boolean isTractEnabled = UTIL_WSC_Subscription.isSubscribedToTRACT(acc);
            system.assertEquals(isTractEnabled, true);
            
            update con;
        
            // WS_ScheduledCallout__c is created from trigger
            List<WS_ScheduledCallout__c>lstScos = [select id from WS_ScheduledCallout__c where RecordId__c = :con.id]; 
            
            system.assert(!lstScos.isEmpty());
            
            // WS_ScheduledCallout__c handler will do callout and create log
            BAT_WS_ScheduledCalloutHandler.doScheduledCallout_forTest(lstScos[0].id);
            
            WS_Log__c[] logs = [select Response__c from WS_Log__c where CalloutName__c = 'WSC_Tract:BillingAccountGetFromContact' or CalloutName__c = 'WSC_Tract:PeopleUpdateEmail'];
            system.assertEquals(logs.size(), 2);
        Test.stopTest();
    }
}
