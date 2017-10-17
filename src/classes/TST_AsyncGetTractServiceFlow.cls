@isTest
public class TST_AsyncGetTractServiceFlow {
    
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

        List<WSC_Subscription__c> subscriptions = new List<WSC_Subscription__c> {
            new WSC_Subscription__c(
                Name = 'TRACT',
                ConsumerId__c = '=',
                Class__c = 'WSC_Tract',
                Method__c = '-',
                IsActive__c = TRUE
            )
        };
        //insert subscriptions;

        List<Webservice_Settings__c> wss = new List<Webservice_Settings__c>();
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        insert wss;
        
        UTIL.isRunningTestSetup = false;
    
    }
    
    @isTest static void test_execute_TractServiceSync() {
		
		UTIL_WSC.TESTMOCK = 'callCreateValid';

		DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits', 'oppMap'});
        
        Account acc = result.accounts.values().get(0);
        Opportunity opp = result.oppMap.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        Test.startTest();

        AsyncGetTractServiceFlow aactf = new AsyncGetTractServiceFlow(opp.Id);

        ID jobID = System.enqueueJob(aactf);

        Test.stopTest();


	}
    
}