/**
 * 
 *@changelog
 *          GAEA-SYS TEAM         10-JUL-2017           Increase code coverage + change to use with DF.cls for test data factory    
 *@coverclass
 *      - AsyncAccCreateTractFlow
 *      - LSC_EbaykBookingFormController
 *          + Un-used Methods
 *              - validateTimestamp()
 */

@isTest
private class TST_LSC_EbaykBookingFormController {

    public static DF factory;

    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;

    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            
            'EBAYKPR' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'EBAYKPR',
                DF_Scenario.CONF_USER_PROFILE   => 'Real Estate',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
        };

        scenarios = new List<DF_Scenario> {
            
            new DF_Scenario('EBAYKPR-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'EBAYK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'PR',
                DF_Scenario.CONF_USERS               => new List<String> { 'EBAYKPR' },
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => 'EBAYKPRO_2017',
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>> {
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 2,
                        DF_Scenario.CONF_PRODUCT_AD_ID => '12345678901234567890',
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
                            new Product2(
                                Name = 'PRO Paket TEST',
                                ProductCode = 'PRO_Paket_TEST',
                                Billing_Category__c = 'CPM_Delivery',
                                ScheduleAheadTerm__c = 12,
                                ContractPeriodInMonths__c = null,
                                BillingScheme__c = 'Monthly in Arrears',
                                CPC_Price__c = 1.00,
                                CPM_Price__c = 115.00,
                                Description = 'This is test.',
                                Product_SubType__c = 'PRO',
                                LocalProductId__c = 'PRO_Paket_TEST'
                            ),
                            new PricebookEntry(
                                PriceCalculator__c = null,
                                Tiered_OffsetPrice__c = 0.00,
                                Tiered_AdditionalPrice__c = 0.00,
                                Fixed_PricePerMonth__c = 0.00,
                                Tiered_Tiersize__c = 0.00,
                                Tiered_FinalAdjustment__c = 0.00,
                                UnitPrice = 1.00,
                                MaxDiscountPercent__c = 73.00,
                                UseStandardPrice = false,
                                IsActive = true
                            )
                        }
                    }
                },
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                }
            })
        };
    }

    @testSetup
    static void setup() {

        UTIL.isRunningTestSetup = true;
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        UTIL.isRunningTestSetup = false;
    
    }

    @isTest static void test_get_memeberunit() {

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits','contacts','products'});
        
        Account acc = result.accounts.values().get(0);
        Contact con = result.contacts.values().get(0);
        Product2 pro = result.products.values().get(0);
        
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        //System.assert( LSC_EbaykBookingFormController.memberUnit != null && LSC_EbaykBookingFormController.memberUnit.Id == memberUnit.Id, 'There should be a valid EBAYKPR Member Unit.');
    
    }

    @isTest static void test_getFieldSet () {

        List< List<LSC_Helper.FieldSetMember> > accountFieldSets = new List<List<LSC_Helper.FieldSetMember>>();

        Test.startTest();

        Set<String> lstAccFieldSet = Schema.SObjectType.Account.fieldSets.getMap().keyset();
        if(!lstAccFieldSet.isEmpty()){
            for(String fieldsetName: lstAccFieldSet){
                String result = LSC_EbaykBookingFormController.getFieldSet( 'Account', fieldsetName);
                

                List<LSC_Helper.FieldSetMember> fieldSets = (List<LSC_Helper.FieldSetMember>) JSON.deserialize(result, List<LSC_Helper.FieldSetMember>.class);
                System.debug('### LSC fieldSets :: ' + fieldSets);

                accountFieldSets.add(fieldSets);
            }
        }

        Test.stopTest();

        //There should be 3 Field Sets for Account in SF {EBAYK_SelfBookingSection1, GTZA_CompanyDetail, MP_ADMARKT_CompanyDetail}
        System.assert( accountFieldSets.size() >= 3 , 'There should be 3 Fieldsets for Account in SF such as {EBAYK_SelfBookingSection1, GTZA_CompanyDetail, MP_ADMARKT_CompanyDetail} ');
    }

    @isTest static void test_check_Valid_VATNumber() {
        //Valid informaiton
        String country = 'DE';
        String vatNo = '123456789';

        Map<String, String> result = new Map<String,String>();

        Test.startTest();

        for (Object obj : (List<Object>) LSC_EbaykBookingFormController.checkVATNumber(vatNo, country)) {
            result = (Map<String,String>) obj;
        }

        Test.stopTest();

        System.assertEquals('true', result.get('isSuccess'), 'This vat number should be valid.');

    }

    @isTest static void test_check_Invalid_VATNumber() {

        //Valid informaiton
        String country = 'DE';
        String vatNo = '12345';

        Map<String, String> result = new Map<String,String>();

        Test.startTest();

        for (Object obj : (List<Object>) LSC_EbaykBookingFormController.checkVATNumber(vatNo, country)) {
            result = (Map<String,String>) obj;
        }

        Test.stopTest();
        System.debug('## result :: ' + result.get('isSuccess'));
        System.assertEquals('false', result.get('isSuccess'), 'This vat number should be invalid.');
    }

    @isTest static void test_digestBooking_success() {

        UTIL_CustomJob.createTestCustomJobs();

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits','contacts','products'});
        
        Account acc = result.accounts.values().get(0);
        acc.UniquePlatformId__c = 'ebayK2131';
        update acc;

        Contact con = result.contacts.values().get(0);
        Product2 pro = result.products.values().get(0);

        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = true;
        update memberUnit;

        LSC_EbaykBookingFormController.memberUnit = memberUnit;
        
        Map<String, Object> res = new Map<String, Object>();

        Test.startTest();

        String contactDetail = '[{"name":"Id", "value":"' + con.Id + '"},{"name": "LastName", "value": "' + con.LastName + '"}, {"name":"FirstName", "value":"' + con.FirstName + '"},{"name":"Phone", "value":"123456"}]';
        String accountDetail = '[{"name": "BillingCountry"}, {"name": "Name", "value": "' + acc.Name + '"}, {"name":"Company_VAT_No__c", "value":"123456789"}]';
        String productId = pro.LocalProductId__c;
        String localId = 'ebayK2131';
        String timestamp = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSZ');
        String token = 'test';
        String vat = '';
        String packageNum = 'TEST';


        res = LSC_EbaykBookingFormController.digestBooking(contactDetail, accountDetail, productId, localId, timestamp, token, vat, packageNum, 'true', '1');
        System.debug('### res :: ' + res);

        Test.stopTest();

        /**System.assertEquals( true, res.get('isSuccess'), 'The Digest Booking should be success.');

        //There should be 1 opportunity Name = 'Pro Paket TEST' and it's one line item
        List<Opportunity> opps = [SELECT Name, AccountId, (SELECT Product2Id FROM OpportunityLineItems) FROM Opportunity WHERE Name='Pro Paket TEST' AND AccountId=:acc.Id LIMIT 1];
        System.assertEquals( 1, opps.size(), 'There should be one Pro Paket Opportunity created.');
        

        List<OpportunityLineItem> olis = opps[0].OpportunityLineItems;
        System.assertEquals( 1, olis.size(), 'There should be one Pro Paket Product Line Item created.');
        System.assertEquals( pro.Id, olis[0].Product2Id, 'This Product Line Item should be "PRO Paket TEST" Product.');
		*/
    }

    @isTest static void test_digestBooking_invalidauth() {

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits','contacts','products'});
        
        Account acc = result.accounts.values().get(0);
        acc.UniquePlatformId__c = 'ebayK2131';
        update acc;

        Contact con = result.contacts.values().get(0);
        Product2 pro = result.products.values().get(0);
        
        Map<String, Object> res = new Map<String, Object>();

        Test.startTest();

        String contactDetail = '[{"name":"Id", "value":"' + con.Id + '"},{"name": "LastName", "value": "' + con.LastName + '"}, {"name":"FirstName", "value":"' + con.FirstName + '"},{"name":"Phone", "value":"123456"}]';
        String accountDetail = '[{"name": "BillingCountry"}, {"name": "Name", "value": "' + acc.Name + '"}, {"name":"Company_VAT_No__c", "value":"123456789"}]';
        String productId = pro.LocalProductId__c;
        String localId = '';
        String timestamp = '';
        String token = '';
        String vat = '';
        String packageNum = 'TEST';


        res = LSC_EbaykBookingFormController.digestBooking(contactDetail, accountDetail, productId, localId, timestamp, token, vat, packageNum, 'true', '1');
        System.debug('### res :: ' + res);

        Test.stopTest();

        System.assertEquals( false, res.get('isSuccess'), 'The Digest Booking should be failed.');
        System.assert(!String.isEmpty(String.valueOf(res.get('errMsg'))), 'The digest booking should be failed due to Invalid Authentication.');
        
    }

    @isTest static void test_digestBooking_failed() {

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits','contacts','products'});
        
        Account acc = result.accounts.values().get(0);
        acc.UniquePlatformId__c = 'ebayK2131';
        update acc;

        Contact con = result.contacts.values().get(0);
        Product2 pro = result.products.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = true;
        update memberUnit;

        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        
        Map<String, Object> res = new Map<String, Object>();

        Test.startTest();

        String contactDetail = '[{"name":"Id", "value":"' + con.Id + '"},{"name": "LastName", "value": "' + con.LastName + '"}, {"name":"FirstName", "value":"' + con.FirstName + '"},{"name":"Phone", "value":"123456"}]';
        String accountDetail = '[{"name": "BillingCountry"}, {"name": "Name", "value": "' + acc.Name + '"}, {"name":"Company_VAT_No__c", "value":"123456789"}]';
        String productId = pro.LocalProductId__c;
        String localId = 'ebayK2131';
        String timestamp = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSZ');
        String token = 'test';
        String vat = '';
        String packageNum = 'TEST';


        res = LSC_EbaykBookingFormController.digestBooking(contactDetail, accountDetail, productId, localId, timestamp, token, vat, packageNum, 'true', '1');
        System.debug('### res :: ' + res);

        Test.stopTest();

        System.assertEquals( false, res.get('isSuccess'), 'The Digest Booking should be failed.');
        System.assertEquals( 'Leider ist ein Fehler aufgetreten. Bitte kontaktieren Sie pro@ebay-kleinanzeigen.de oder rufen Sie an unter +49 30 3082 9444 um die Buchung durchzuführen.', res.get('errMsg'), 'The digest booking should be failed and there is an error message');
        
    }
}