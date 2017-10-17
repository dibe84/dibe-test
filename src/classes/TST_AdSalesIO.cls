/**
 * 
 *@changelog
 *          GAEA-SYS TEAM         09-JUL-2017           Increase code coverage + change to use with DF.cls for test data factory
 */
@istest
public class TST_AdSalesIO {

    public static DF factory;

    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;
    
    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'EBAYKRE_Rep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'EBAYKAD',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
            
        };

        scenarios = new List<DF_Scenario> {
            new DF_Scenario('EBAYKRE-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'EBAYK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'RE',
                DF_Scenario.CONF_USERS               => new List<String> { 'EBAYKRE_Rep' },
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => 'EBAYKRE_DBA_2017',
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>> {
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 2,
                        DF_Scenario.CONF_PRODUCT_AD_ID => '12345678901234567890',
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Dækning & Dominans - Biler [Vertical]',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPM_Delivery',
                                ScheduleAheadTerm__c = 12,
                                ContractPeriodInMonths__c = null,
                                BillingScheme__c = 'Monthly in Arrears',
                                CPC_Price__c = 1.00,
                                CPM_Price__c = 115.00,
                                Description = 'This is test.',
                                Product_SubType__c = 'RE'
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

        //TST_DataFactory.createTestSet();

        UTIL.isRunningTestSetup = false;
    
    }

    @isTest static void test_load_page () {

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits','oliMap','users','oppMap'});
        Account acc = result.accounts.values().get(0);
        Opportunity opp = result.oppMap.values().get(0);
        User user = result.users.get('EBAYKRE_Rep');
        MemberUnit__c memberUnit = result.memberunits.values().get(0);

        Test.startTest();

        
            System.runAs ( user ) {
                
                ApexPages.StandardController stdCtrl = new ApexPages.StandardController(opp);
                AdSalesIoExtension ctrl  = new AdSalesIoExtension(stdCtrl);

                List<OpportunityLineItem> items = ctrl.getsortrecord();
                String memberUnitId = ctrl.memberUnitId;
                
                System.assertEquals(1, items.size(), 'There should be 1 RE Product Line Item.');
                System.assert( ctrl.availableEmails.contains('immobilien@ebay-kleinanzeigen.de'), 'The availableEmails should be immobilien@ebay-kleinanzeigen.de .');
                System.assertEquals(memberUnit.MemberUnitId__c, memberUnitId, 'This opportunity should has member unit of EBAYKAD.');
            }
        

        Test.stopTest();

    }


    /* 09 JULY 2017: BLOCKER RELATED TO UTIL_Customizer.cls line 203
    @isTest static void testIODisplayController() {
        
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','users','oppMap'});
        Account acc = result.accounts.values().get(0);
        Opportunity opp = result.oppMap.values().get(0);
        User user = result.users.get('EBAYKRE_Rep');
        
        Test.startTest();


            System.runAs ( user ) {

                Pagereference pg=Page.GeneratePdfAndAttach;
                Test.setCurrentPageReference(pg);

                pg.getParameters().put('ApexPdfPage','IO_Classifieds');

                ApexPages.StandardController sc = new Apexpages.StandardController(opp);
                IODisplayController iodc = new IODisplayController(sc);
                echosign_dev1__SIGN_Agreement__c testAgreement = new echosign_dev1__SIGN_Agreement__c();
                testAgreement.name = 'TestIO';
                testAgreement.echosign_dev1__Status__c = 'Cancelled';
                testAgreement.echosign_dev1__Opportunity__c = opp.id;
                testAgreement.echosign_dev1__Account__c = acc.id;
                Insert testAgreement;
                iodc.agreement = testAgreement;

                //primary contact validation
                iodc.createIO();
                iodc.attachRequiredPDFs();

                iodc.getErrorMessage();
                iodc.getShowErrorMessage();
                iodc.cancel();
            }

        Test.stopTest();
    }

    
    @isTest
    static void testIODisplayController2() {
        TST_DataFactory fac = TST_DataFactory.getInstance();

        Test.startTest();
        System.runAs ( fac.testUser ) {
            Pagereference pg=Page.GeneratePdfAndAttach;
            Test.setCurrentPageReference(pg);

            pg.getParameters().put('ApexPdfPage','IO_Classifieds');
            ApexPages.StandardController sc = new Apexpages.StandardController(fac.opp);
            IODisplayController iodc = new IODisplayController(sc);

            iodc.createIO();
            system.assertNotEquals(null, iodc.agreement);
            iodc.attachRequiredPDFs();
            iodc.getErrorMessage();
            iodc.getShowErrorMessage();
            iodc.cancel();
        }
        Test.stopTest();
    }
    
    @isTest
    static void test_ErrorCase() {
        TST_DataFactory fac = TST_DataFactory.getInstance();
        fac.opp.Primary_Contact__c = null;
        update fac.opp;
        
        Test.startTest();
            System.runAs ( fac.testUser ) {
                IODisplayController iodc = new IODisplayController(new Apexpages.StandardController(fac.opp));
                system.assert(String.isNotEmpty(iodc.memberUnitId));
                //error case
                iodc.createIO();
                system.assert(iodc.getShowErrorMessage());
            }
        Test.stopTest();
    }
    */


    /* OLD VERSION => change to use with DF.cls for data factory
    // Using basic AdSales Test set:
    // Account acc
    // Opportunity opp
    // Oli1: 1/1/2030 - 30/6/2030
    // Oli2: 31/1/2030 - 1/6/2030
    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
    	UTIL.isRunningTestSetup = false;
    }
	
    @istest Static void TestAdSalesIoExtension() {
        TST_DataFactory fac = TST_DataFactory.getInstance();

        Test.startTest();
        System.runAs ( fac.testUser ) {
            //ApexPages.currentPage().getParameters().put('lc',objLeadCenter.id);
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(fac.opp);
            AdSalesIoExtension IOExtension  = new AdSalesIoExtension(stdCtrl);

			List<OpportunityLineItem> items = IOExtension.getsortrecord();
			system.assertEquals(2, items.size());

            Pagereference pageRef=Page.IO_GTAUS;
            Test.setCurrentPage(pageRef);

            apexpages.currentpage().getparameters().put('oppId',fac.opp.id);
        }
        Test.stopTest();
    }
    

    @isTest static void testIODisplayController() {
        
        TST_DataFactory fac = TST_DataFactory.getInstance();
        Test.startTest();
        TST_DataFactory.completeContactdetails(fac.con);

        
        System.runAs ( fac.testUser ) {

            Pagereference pg=Page.GeneratePdfAndAttach;
            Test.setCurrentPageReference(pg);

            pg.getParameters().put('ApexPdfPage','IO_Classifieds');

            ApexPages.StandardController sc = new Apexpages.StandardController(fac.opp);
            IODisplayController iodc = new IODisplayController(sc);
            echosign_dev1__SIGN_Agreement__c testAgreement = new echosign_dev1__SIGN_Agreement__c();
            testAgreement.name = 'TestIO';
	        testAgreement.echosign_dev1__Status__c = 'Cancelled';
	        testAgreement.echosign_dev1__Opportunity__c = fac.opp.id;
	        testAgreement.echosign_dev1__Account__c = fac.acc.id;
	        Insert testAgreement;
            iodc.agreement = testAgreement;

            //primary contact validation
			iodc.createIO();
			iodc.attachRequiredPDFs();

            iodc.getErrorMessage();
            iodc.getShowErrorMessage();
            iodc.cancel();
        }

        Test.stopTest();
    }

    //@vitou 08-04-2015
    @isTest
    static void testIODisplayController2() {
        TST_DataFactory fac = TST_DataFactory.getInstance();

        Test.startTest();
        System.runAs ( fac.testUser ) {
            Pagereference pg=Page.GeneratePdfAndAttach;
            Test.setCurrentPageReference(pg);

            pg.getParameters().put('ApexPdfPage','IO_Classifieds');
            ApexPages.StandardController sc = new Apexpages.StandardController(fac.opp);
            IODisplayController iodc = new IODisplayController(sc);

            iodc.createIO();
			system.assertNotEquals(null, iodc.agreement);
			iodc.attachRequiredPDFs();
            iodc.getErrorMessage();
            iodc.getShowErrorMessage();
            iodc.cancel();
        }
        Test.stopTest();
	}
	
	@isTest
    static void test_ErrorCase() {
        TST_DataFactory fac = TST_DataFactory.getInstance();
		fac.opp.Primary_Contact__c = null;
        update fac.opp;
        
        Test.startTest();
	        System.runAs ( fac.testUser ) {
	            IODisplayController iodc = new IODisplayController(new Apexpages.StandardController(fac.opp));
				system.assert(String.isNotEmpty(iodc.memberUnitId));
	            //error case
	            iodc.createIO();
	            system.assert(iodc.getShowErrorMessage());
	        }
        Test.stopTest();
	}
    */
}