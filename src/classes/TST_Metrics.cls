@isTest
public with sharing class TST_Metrics {
    public static DF factory;
    public static List<DF_Scenario> subscriptionScenarios;
    public static List<DF_Scenario> adSalesScenarios;
    public static Map<String, Map<String, String>> usersSubscription;
    public static Map<String, Map<String, String>> usersAdsales;

    static {
        usersSubscription = new Map<String, Map<String, String>> {
            'adsalesRep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'THBELAU_Rep',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
        };

        usersAdsales = new Map<String, Map<String, String>> {
            'ECGDKAD_adsalesRep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'ECGDKAD',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep', // should be ECGDK Ad Sales Rep but does not exist on JC1 box
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
        };

        subscriptionScenarios = new List<DF_Scenario> {
            new DF_Scenario('THBELAU-1', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'THBEL',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AU',
                DF_Scenario.CONF_USERS               => new List<String> { 'adsalesRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => '2016',
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '5',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                },
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 2,
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
            })
        };

        adSalesScenarios = new List<DF_Scenario> {
            new DF_Scenario('ECGDKAD-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'ECGDK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
                DF_Scenario.CONF_USERS               => new List<String> { 'ECGDKAD_adsalesRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => 'ECGDKAD_DBA_2016',
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
                                CPM_Price__c = 115.00
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
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '2',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                }
            }),
            new DF_Scenario('ECGDKAD-02', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'ECGDK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
                DF_Scenario.CONF_USERS               => new List<String> { 'ECGDKAD_adsalesRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => 'ECGDKAD_DBA_2016',
                DF_Scenario.CONF_PRODUCTS =>  new List<Map<String, Object>> {
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 2,
                        DF_Scenario.CONF_PRODUCT_DATA  => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Curtain / Open Door-Til Boligen [Vertical]',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPD_Delivery',
                                ScheduleAheadTerm__c = 12,
                                ContractPeriodInMonths__c = null,
                                BillingScheme__c = 'Monthly in Arrears',
                                CPD_Price__c = 55000
                            ),
                            new PricebookEntry(
                                PriceCalculator__c = null,
                                Tiered_OffsetPrice__c = 0.00,
                                Tiered_AdditionalPrice__c = 0.00,
                                Fixed_PricePerMonth__c = 0.00,
                                Tiered_Tiersize__c = 0.00,
                                Tiered_FinalAdjustment__c = 0.00,
                                UnitPrice = 1.00,
                                MaxDiscountPercent__c = 55.00,
                                UseStandardPrice = false,
                                IsActive = true
                            )
                        }
                    }
                },
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '10',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                }
            })
        };
    }

    @testSetup
    static void setupSubscription_Adsales() {
        /*
        // Subscription
        UTIL.isRunningTestSetup = true;
        factory = new DF(subscriptionScenarios, usersSubscription);
        factory.setup();
        
        // Adsales
        addOppProbabilityCustomSettings();
        factory = new DF(adSalesScenarios, usersAdsales);
        factory.setup();
        UTIL.isRunningTestSetup = false;
        //UTIL_CustomJob.createTestCustomJobs();
        */
    }

    @isTest
    static void testRevenueExpectedWeighted() {
            addOppProbabilityCustomSettings();
        factory = new DF(adSalesScenarios, usersAdsales);
        factory.setup();
        UTIL.isRunningTestSetup = false;

        UTIL_Log.start();
        Test.startTest();
        DF_Scenario.Result result = DF.queryResults(adSalesScenarios, usersAdsales, new Set<String> { 'users', 'oppMap' });
        AccountMemberUnitAssociation__c[] lstAMA = new List<AccountMemberUnitAssociation__c>();
        MemberUnit__c mU = [select id from MemberUnit__c limit 1];
        for(Opportunity opp : result.oppMap.values()) {
            opp.ContractStatus__c = '';
            opp.ApprovalStatus__c = '';
            AccountMemberUnitAssociation__c ama = new AccountMemberUnitAssociation__c(Account__c = opp.AccountId, MemberUnit__c = mU.id);
            lstAMA.add(ama);
        }
        insert lstAMA;
        addFakeMetrics(result.rss.values());
        update result.oppMap.values();
        DF.requeryResults(result,new Set<String>{'oppMap'});
        for(Opportunity opp : result.oppMap.values()) {
            if(opp.NumStatus__c == 0) {
                opp.StageName = 'Proposal';
            }
        }
        update result.oppMap.values();
        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {

            DF.requeryResults(result,new Set<String>{'metrics','oppMap'});
            for(Metric__c metric : result.metrics.values()) {
                if(result.rss.get(metric.RS__c) != null && result.rss.get(metric.RS__c).RevenueExpected__c > 0) {
                    System.assertNotEquals(NULL,metric.RevenueExpectedWeighted__c);
                    System.assertNotEquals(0.0,metric.RevenueExpectedWeighted__c);
                }
            }
            for(Opportunity opp : result.oppMap.values()) {
                if(opp.MemberUnitId__c == 'ECGDKAD') {
                    System.assertEquals('Proposal',opp.StageName,'ECGDKAD should have stage name equal to proposal!');
                    System.assertEquals(65.00,opp.Probability,'ECGDKAD should have prob for proposal equal to 65!');
                }
            }
        }
        Test.stopTest();
        UTIL_Log.end();
    }

    @isTest
    static void testMetricsUID() {
            // Subscription
        UTIL.isRunningTestSetup = true;
        factory = new DF(subscriptionScenarios, usersSubscription);
        factory.setup();
        
        Test.startTest();
        DF_Scenario.Result result = DF.queryResults(adSalesScenarios, usersAdsales, new Set<String> { 'rss' });
        UTIL.log('Limit'+Limits.getLimitDMLStatements());
        List<Metric__c> metricsToInsert = new List<Metric__c>();
        RS__c rs =  result.rss.values().get(0);
        
        for (Integer i = 1; i < 25; i++) {
            Metric__c m = new Metric__c();
            m.RS__c = rs.Id;
            m.AD_Amount__c = 100;
            m.AD_Clicks__c = 100;
            m.AD_Impressions__c = 100;
            m.AD_OSI__c = 100;
            m.UniqueKey__c = String.valueOf(System.today().addDays(i)) + '_' + rs.Id;
            m.MetricDate__c = System.today().addDays(i);
            metricsToInsert.add(m);
        }
        insert metricsToInsert;
        
        DF.requeryResults(result,new Set<String>{'metrics'});

        for(Metric__c met : result.metrics.values()) {
            System.assertNotEquals(NULL,met.ExternalUID__c);
        }
        Test.stopTest();
    }

    private static void addOppProbabilityCustomSettings() {
        List<OpportunityStageProbability__c> oppProbList = new List<OpportunityStageProbability__c>();
        oppProbList.add(new OpportunityStageProbability__c(
            Name = 'ecgdkad1',
            MemberUnit__c = 'ECGDKAD',
            StageName__c = 'Qualification',
            Probability__c = 10.00
        ));
        oppProbList.add(new OpportunityStageProbability__c(
            Name = 'ecgdkad2',
            MemberUnit__c = 'ECGDKAD',
            StageName__c = 'Initial Contact',
            Probability__c = 25.00
        ));
        oppProbList.add(new OpportunityStageProbability__c(
            Name = 'ecgdkad3',
            MemberUnit__c = 'ECGDKAD',
            StageName__c = 'Proposal',
            Probability__c = 65.00
        ));
        oppProbList.add(new OpportunityStageProbability__c(
            Name = 'ecgdkad4',
            MemberUnit__c = 'ECGDKAD',
            StageName__c = 'Verbal Acceptance',
            Probability__c = 75.00
        ));
        // DEFAULT
        oppProbList.add(new OpportunityStageProbability__c(
            Name = 'default1',
            MemberUnit__c = 'default',
            StageName__c = 'Qualification',
            Probability__c = 15.00
        ));
        oppProbList.add(new OpportunityStageProbability__c(
            Name = 'default2',
            MemberUnit__c = 'default',
            StageName__c = 'Initial Contact',
            Probability__c = 30.00
        ));
        oppProbList.add(new OpportunityStageProbability__c(
            Name = 'default3',
            MemberUnit__c = 'default',
            StageName__c = 'Proposal',
            Probability__c = 60.00
        ));
        oppProbList.add(new OpportunityStageProbability__c(
            Name = 'default4',
            MemberUnit__c = 'default',
            StageName__c = 'Verbal Acceptance',
            Probability__c = 80.00
        ));

        insert oppProbList;
    }

    private static void addFakeMetrics(List<RS__c> rsList) {
        List<Metric__c> metricsToInsert = new List<Metric__c>();
        for (RS__c rs : rsList) {
            if(rs.from_Date__c > Date.today()) continue;
            for (Metric__c m : GW_Metric.createAllMetricsFromRS(rs) ) {
                m.AD_Amount__c = 1000;
                m.AD_Clicks__c = 1000;
                m.AD_Impressions__c = 1000;
                m.AD_OSI__c = 1000;
                metricsToInsert.add(m);
            }
        }
        insert metricsToInsert;
    }
}