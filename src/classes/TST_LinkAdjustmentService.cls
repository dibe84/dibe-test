@isTest
private class TST_LinkAdjustmentService {
	public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;
    
    private static Date TODAY_THBELAU = system.Today();

    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'autosRep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'THBELAU_Rep',
                DF_Scenario.CONF_USER_PROFILE   => 'Automotive Sales Rep External',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
        };

        scenarios = new List<DF_Scenario> {
            new DF_Scenario('THBELAU-1', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'THBEL',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AU',
                DF_Scenario.CONF_USERS               => new List<String> { 'autosRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => '2016',
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
                    DF_Scenario.CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION => 'true',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(TODAY_THBELAU.addMonths(-1))
                },
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject>{
                            new Product2(
                                Name = 'Motor Listings 12 Months',
                                ProductCode = 'BEC_12',
                                Billing_Category__c = 'Subscription_MonthlyProRata',
                                ScheduleAheadTerm__c = 12,
                                ContractPeriodInMonths__c = 12,
                                BillingScheme__c = 'Monthly in Arrears'
                            ),
                            new PricebookEntry(
                                PriceCalculator__c = 'FixedTiered',
                                Tiered_OffsetPrice__c = 0.00,
                                Tiered_AdditionalPrice__c = 0.00,
                                Tiered_TierCorrection__c = 0.00,
                                ListOrder__c = 5,
                                FixedTiered_JSON__c = '{"1":3,"10":29,"15":41,"20":54,"30":80,"40":106,"60":131,"100":183,"200":234,"999":284}',
                                Tiered_FinalAdjustment__c = 0.00,
                                UnitPrice = 0.00,
                                UseStandardPrice = false,
                                IsActive = true
                            )
                        }
                    }
                }
            }),
            new DF_Scenario('THBELAU-2', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'THBEL',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AU',
                DF_Scenario.CONF_USERS               => new List<String> { 'autosRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => '2016',
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
                    DF_Scenario.CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION => 'true',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(TODAY_THBELAU.addMonths(-1))
                },
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject>{
                            new Product2(
                                Name = 'Automotive Listings 6 months',
                                ProductCode = 'BEC_6',
                                Billing_Category__c = 'Subscription_MonthlyProRata',
                                ScheduleAheadTerm__c = 12,
                                ContractPeriodInMonths__c = 6,
                                BillingScheme__c = 'Monthly in Arrears'
                            ),
                            new PricebookEntry(
                                PriceCalculator__c = 'IterativeTiered',
                                Tiered_OffsetPrice__c = 28.57,
                                Tiered_AdditionalPrice__c = 26.72,
                                Tiered_TierCorrection__c = -0.05,
                                ListOrder__c = 2,
                                Tiered_Tiersize__c = 10,
                                Tiered_FinalAdjustment__c = 10.00,
                                UnitPrice = 1.00,
                                UseStandardPrice = false,
                                IsActive = true
                            )
                        }
                    }
                }
            }),
            new DF_Scenario('THBELAU-3', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'THBEL',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AU',
                DF_Scenario.CONF_USERS               => new List<String> { 'autosRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => '2016',
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
                    DF_Scenario.CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION => 'true',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(TODAY_THBELAU.addMonths(-1))
                },
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject>{
                            new Product2(
                                Name = 'AutoScout24 24 Months',
                                ProductCode = 'BEC_24',
                                Billing_Category__c = 'Subscription_MonthlyProRata',
                                ScheduleAheadTerm__c = 12,
                                ContractPeriodInMonths__c = 24,
                                BillingScheme__c = 'Monthly in Arrears'
                            ),
                            new PricebookEntry(
                                PriceCalculator__c = 'UnlimitedFixed',
                                Tiered_OffsetPrice__c = 0.00,
                                Tiered_AdditionalPrice__c = 0.00,
                                Fixed_PricePerMonth__c = 50.00,
                                Tiered_Tiersize__c = 0.00,
                                Tiered_FinalAdjustment__c = 0.00,
                                UnitPrice = 1.00,
                                UseStandardPrice = false,
                                IsActive = true
                            )
                        }
                    }
                }
            })

        };
    }

    public static DF factory;

    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        UTIL.isRunningTestSetup = false;

        System.runAs(factory.userMap.get('admin')) {
            UTIL_CustomJob.createTestCustomJobs();
        }
    }
    
    @isTest static void test_updateservice() {
		
		DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers);
        Account acc = result.accounts.values().get(0);
        acc.Tract_AccountNumber__c = 'GTZ00001';
        update acc;
        
        Opportunity opp = result.oppMap.get('THBELAU-1.Opportunity[1]');
        Opportunity oppAdj =  result.oppMap.get('THBELAU-2.Opportunity[1]');
        oppAdj.Original_Opportunity__c = opp.Id;
        update oppAdj;
        
        TRACT_Service__c ts = new TRACT_Service__c();
        ts.Name = 'Test';
        ts.Billing_Account__c = acc.Id;
        ts.Opportunity__c = opp.Id;
		ts.External_Id__c = '23456';
        insert ts;
        
        TRACT_Service__c ts2 = new TRACT_Service__c();
        ts2.Name = 'Test';
        ts2.Billing_Account__c = acc.Id;
        ts2.Opportunity__c = opp.Id;
		ts2.External_Id__c = '33333';
		ts2.Status__c = 'Active';
        insert ts2;
        System.assertEquals(2, [Select id From TRACT_Service__c Where Opportunity__c=:opp.Id].size());
        Test.startTest();
	        ts2.Name='Test2';
	        update ts2;
		Test.stopTest();
		
    }
}