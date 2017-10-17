@isTest
public class TST_IO {

    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet(); 
        
        echosign_dev1__SIGN_Agreement__c TestIO = new echosign_dev1__SIGN_Agreement__c();
        TST_DataFactory fac = TST_DataFactory.getInstance();
        TST_DataFactory.insertAccountMemberUnitAssociation(fac.opp.AccountId, fac.opp.MemberUnit__c);
        if(GW_MemberUnit.memberUnitCache.get(fac.opp.MemberUnit__c) == null) GW_MemberUnit.memberUnitCache.put(fac.opp.MemberUnit__c, new MemberUnit__c(id=fac.opp.MemberUnit__c));

        TestIO.name = 'TestIO';
        TestIO.echosign_dev1__Status__c = 'Cancelled';
        TestIO.echosign_dev1__Opportunity__c = fac.opp.id;
        TestIO.echosign_dev1__Account__c = fac.acc.id;
        Insert TestIO; 
        UTIL.isRunningTestSetup = false;
    }
    
    @isTest static void testUpdateIO() {
        Test.startTest();
        System.debug(LoggingLevel.ERROR, 'StartTest' + Limits.getQueries()); 
        
        echosign_dev1__SIGN_Agreement__c TestIO = [SELECT name, echosign_dev1__Status__c, echosign_dev1__Opportunity__c FROM echosign_dev1__SIGN_Agreement__c WHERE name =: 'TestIO' ];

        System.assertEquals('Cancelled', TestIO.echosign_dev1__Status__c);
        
        TestIO.echosign_dev1__Status__c = 'Draft';
        Update TestIO;
        
		System.assertEquals('Draft', TestIO.echosign_dev1__Status__c);
        Test.stopTest();
    }
    
    @isTest static void testDeleteIO() {
        Test.startTest();
        System.debug(LoggingLevel.ERROR, 'StartTest' + Limits.getQueries()); 
        echosign_dev1__SIGN_Agreement__c TestIO = [SELECT name, echosign_dev1__Status__c, echosign_dev1__Opportunity__c FROM echosign_dev1__SIGN_Agreement__c WHERE name =: 'TestIO' ];

        System.assertEquals('Cancelled', TestIO.echosign_dev1__Status__c);
       
        Delete TestIO;
        Test.stopTest();
    }
    
    

}