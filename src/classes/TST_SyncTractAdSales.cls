@isTest
private class TST_SyncTractAdSales {
    
    public static DF factory;

    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;
    
    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'EBAYKAD' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'EBAYKAD',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
        };

        scenarios = new List<DF_Scenario> {
            new DF_Scenario('EBAYKAD-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'EBAYK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
                DF_Scenario.CONF_USERS               => new List<String> { 'EBAYKAD' },
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => 'EBAYKAD_2017',
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>> {
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 2,
                        DF_Scenario.CONF_PRODUCT_AD_ID => '12345678901234567890',
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: Dominans - Biler [Vertical]',
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
        List<Webservice_Settings__c> wss = new List<Webservice_Settings__c>();
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_UAT', UseProxy__c=true, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_PROD', UseProxy__c=true, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        insert wss;
        
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        UTIL.isRunningTestSetup = false;
    
    }
    
	
	@isTest static void testOrderAdSalesUpdate(){
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'oliMap','users','oppMap'});
        Opportunity opp = result.oppMap.values().get(0);
        
        User user = result.users.get('EBAYKAD');
        OpportunityLineItem oli = result.oliMap.values().get(0);
        oli.ListPriceCorrection__c = 5;
        oli.Quantity = 1000;
        update oli;
        
        Test.startTest();
	        WSC_Tract.getServiceUsageRule(opp.Id, ''); // for coverage only
	        
	        UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.OrderAdSalesUpdate');
	        req.mAdditionalParams.put('oppItemid', oli.id);
	        req.init(opp.Id);
	        req.call();
        Test.stopTest();
    }
}