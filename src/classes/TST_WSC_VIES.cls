@isTest
public class TST_WSC_VIES  extends TSTDF_Base {

    public TST_WSC_VIES(TSTDF_Dataset dataset) {
        super(dataset);
    }

    public static TST_WSC_VIES factory = new TST_WSC_VIES(new TSTDF_Dataset());

    public class TSTDF_Dataset extends TSTDF_BaseDataSet {
        public override List<Webservice_Settings__c> constructWebserviceSettings(List<Webservice_Settings__c> wss){
            wss = new List<Webservice_Settings__c>();
            wss.add(new Webservice_Settings__c(Name = 'WSC_VIES_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
            wss.add(new Webservice_Settings__c(Name = 'WSC_VIES_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
            return wss;
        }
    }

    @testSetup static void setup(){
        UTIL.isRunningTestSetup = true;
        factory.createTestSet();

        List<FieldValidation__c> rules = new List<FieldValidation__c>();
        rules.add(new FieldValidation__c(
            Active__c = true,
            Name = 'Global_Account_VIES_VAT',
            Object__c = 'Account',
            Scope__c = 'Global',
            delegatedValidator__c = 'VAL_VIES.VATValidation',
            ErrorMessage__c = 'VIES VAT Validation result has to be: \'Valid\', currently is: \'{{VAT_Check_Status__c}}\'',
            FieldName__c = 'VAT_Check_Result__c',
            FieldType__c = 'SYNC',
            MandatoryFromStatusNum__c = 1,
            MandatoryValue__c = '1',
            Param__c = null,
            Regex__c = null
        ));
        insert rules;

        insert new Configuration__c(Name='VIESCountries', Value__c='AT,BE,BG,CY,CZ,DE,DK,EE,EL,ES,FI,FR,GB,HU,IE,LT,LU,LV,MT,NL,PL,PT,RO,SE,SK');

        UTIL.isRunningTestSetup = false;
    }

    @isTest static void TST_QueryValidResponse(){
        UTIL_WSC.TESTMOCK = 'callValid';
        factory.queryResults();

        Account acc = factory.data.accounts[0];

        System.assertEquals(null, acc.Company_VAT_No__c);

        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;

        Test.startTest();
        System.runAs(factory.data.testUsers.get('testUser')){
            acc.Company_VAT_No__c = 'BE0454370863';
            acc.BillingCountry = 'Belgium';
            acc.Apply_VAT__c = FALSE;
            update acc;
            // Assert status = valid
            UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(New Set<Id>{acc.Id});
            req = UTIL_WSC.getWSC_Request('WSC_VIES.Query');
            req.init(acc.Id);
            res = req.call();
            UTIL_WSC.bulkHandler.commitAll();
            Account retrievedAcc = GW_Account.getRecord(acc.Id);
            // Assert status = invalid
            System.assertEquals('Valid', retrievedAcc.VAT_Check_Status__c);
            System.assertEquals(1, retrievedAcc.VAT_Check_Result__c);

            // Clear VAT No account stage falled back
            retrievedAcc.Company_VAT_No__c = '';
            retrievedAcc.Apply_VAT__c = FALSE;
            update retrievedAcc;

            retrievedAcc = GW_Account.getRecord(retrievedAcc.Id);

            //New VAT application rules, will prevent Apply VAT to be false when VAT Number is empty.
            System.assertEquals(1, retrievedAcc.VAT_Check_Result__c);
            System.assertEquals('Valid', retrievedAcc.VAT_Check_Status__c);

            retrievedAcc.Apply_VAT__c = TRUE;
            update retrievedAcc;

            retrievedAcc = GW_Account.getRecord(retrievedAcc.Id);
            System.assertEquals(1, retrievedAcc.VAT_Check_Result__c);
            System.assertEquals('Valid', retrievedAcc.VAT_Check_Status__c);
        }
        Test.stopTest();
    }

    @isTest static void TST_QueryAccFieldsUpdateCheck(){
        UTIL_WSC.TESTMOCK = 'callValid';
        factory.queryResults();

        Account acc = factory.data.accounts[0];

        System.assertEquals(null, acc.Company_VAT_No__c);
        System.assertEquals(null, acc.VAT_Check_Result__c);
        System.assertEquals(null, acc.VAT_Check_Status__c);

        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;

        Test.startTest();
        System.runAs(factory.data.testUsers.get('testUser')){
            acc.Company_VAT_No__c = 'BE0454370863';
            acc.BillingCountry = 'Belgium';
            acc.Apply_VAT__c = FALSE;
            update acc;

            Account retrievedAcc = GW_Account.getRecord(acc.Id);
            System.assertEquals('BE0454370863', retrievedAcc.Company_VAT_No__c);
            System.assertEquals(-1, retrievedAcc.VAT_Check_Result__c);
            System.assertEquals('In Progress', retrievedAcc.VAT_Check_Status__c);
            // Assert status = valid
            UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(New Set<Id>{acc.Id});
            req = UTIL_WSC.getWSC_Request('WSC_VIES.Query');
            req.init(acc.Id);
            res = req.call();
            UTIL_WSC.bulkHandler.commitAll();
            Test.stopTest();

            retrievedAcc = GW_Account.getRecord(acc.Id);
            System.assertEquals(1, retrievedAcc.VAT_Check_Result__c);
            System.assertEquals('Valid', retrievedAcc.VAT_Check_Status__c);
        }
    }

    @isTest static void TST_QueryCalloutTimeout(){
        UTIL_WSC.TESTMOCK = 'callTimeoutException';
        factory.queryResults();

        Account acc = factory.data.accounts[0];

        System.assertEquals(null, acc.Company_VAT_No__c);

        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;

        Test.startTest();
        System.runAs(factory.data.testUsers.get('testUser')){
            acc.Company_VAT_No__c = 'BE0454370863';
            update acc;
            // Assert status = valid
            UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(New Set<Id>{acc.Id});
            req = UTIL_WSC.getWSC_Request('WSC_VIES.Query');
            req.init(acc.Id);
            res = req.call();
            UTIL_WSC.bulkHandler.commitAll();
            Account retrievedAcc = GW_Account.getRecord(acc.Id);
            //WS_ScheduledCallout__c wssc = ((List<WS_ScheduledCallout__c>) GW_sObject.queryRecords('WS_ScheduledCallout__c','Id <> NULL')).get(0);

            // Ensure that in case of timeout (null response), the process will be repeated
            //System.assertEquals(TRUE, wssc.Pending__c);
            //System.assertEquals('Queued', wssc.Status__c);
            // Assert fields on account
            //System.assertEquals(-1, retrievedAcc.VAT_Check_Result__c);
            //System.assertEquals('In Progress', retrievedAcc.VAT_Check_Status__c);
        }
        Test.stopTest();
    }
}