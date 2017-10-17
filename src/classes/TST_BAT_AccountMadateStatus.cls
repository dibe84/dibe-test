@isTest
private class TST_BAT_AccountMadateStatus {

    @testSetup 
    private static void setup() {
        
        UTIL.isRunningTestSetup = true;
        
        TST_TractGeneric.setup();

        TST_DataFactory fac = TST_DataFactory.getInstance();

        TST_DataFactory.createAccountMemberUnitAssociation( fac.opp.MemberUnit__c , fac.acc.Id );

        fac.acc.Tract_AccountId__c = '00000';
        fac.acc.Billing_Preference__c = 'Direct Debit';
        fac.acc.BillingCountry = 'Germany';
        fac.acc.BillingCountryCode = 'DE';
        fac.acc.Bank_Name__c = 'testfakeBankName';
        update fac.acc;

        UTIL.isRunningTestSetup = false;
    }
    
    @isTest static void testSuccessfulAccountUpdate() {
        echosign_dev1__SIGN_Data_Mapping__c testDataMapping = new echosign_dev1__SIGN_Data_Mapping__c(Name='Mandate_IO');
        insert testDataMapping;
        
        Test.startTest();
            
            UTIL.isRunningTestSetup = true;
            TST_DataFactory fac = TST_DataFactory.getInstance();
            UTIL.isRunningTestSetup = false;
            echosign_dev1__SIGN_Agreement__c agm = new echosign_dev1__SIGN_Agreement__c();
            
            System.runAs ( fac.testUser ) {

                agm.name = 'TestIO';
                agm.Type__c = 'Mandate';
                agm.Bank_AccountNumber__c = 'DE89370400440532013000';                
                agm.echosign_dev1__Opportunity__c = fac.opp.id;
                agm.echosign_dev1__Account__c = fac.acc.id;
                agm.echosign_dev1__Process_Template__c = testDataMapping.id;
                agm.echosign_dev1__Data_Mapping_Result__c = 'Draft';
                insert agm;
                
                //agm.echosign_dev1__Status__c = 'Singed';
                //agm.echosign_dev1__DateSigned__c = System.now();
                //agm.echosign_dev1__Data_Mapping_Result__c = 'Completed';
                //update agm;
            }        
        
            BAT_AccountMadateStatus batch = new BAT_AccountMadateStatus(new List<echosign_dev1__SIGN_Agreement__c>{agm});
            Database.executeBatch(batch);
            
            batch.readyForRun();
            batch.getNumRecords();
            
        Test.stopTest(); 
        
        //List<Account> lstAccs = [Select Bank_AccountNumber__c , Mandate_Status__c From Account];
        //List<echosign_dev1__SIGN_Agreement__c> lstAgreements = [Select echosign_dev1__Status__c , Mandate_Status__c from echosign_dev1__SIGN_Agreement__c];

        //System.assertEquals('OK', lstAccs[0].Mandate_Status__c);
        //System.assertEquals('Success', lstAgreements[0].Mandate_Status__c);
    }
}