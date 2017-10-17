@isTest
public class TST_Invoicing_THBELAU_Bulk {

    public static List<DF_Scenario> subscriptionScenarios;
    public static List<DF_Scenario> adSalesScenarios;
    public static Map<String, Map<String, String>> usersSubscription;
    public static Map<String, Map<String, String>> usersAdsales;
    public static DF factory;

    static {
        usersSubscription = new Map<String, Map<String, String>> {
            'adsalesRep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'THBELAU_Rep',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
        };

        subscriptionScenarios = new List<DF_Scenario> {
            new DF_Scenario('THBELAU-1', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'ECG',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AU',
                DF_Scenario.CONF_USERS               => new List<String> { 'adsalesRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => '2016',
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '5',
                    DF_Scenario.CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION => 'true',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                },
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 5,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject>{
                            new Product2(
                                Name = 'Motor Listings 12 Months',
                                ProductCode = 'BEC_12',
                                Billing_Category__c = 'Subscription_MonthlyProRata',
                                ScheduleAheadTerm__c = 3,
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
                DF_Scenario.CONF_MEMBER              => 'ECG',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AU',
                DF_Scenario.CONF_USERS               => new List<String> { 'adsalesRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => '2016',
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '5',
                    DF_Scenario.CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION => 'true',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                },
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 10,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject>{
                            new Product2(
                                Name = 'Automotive Listings 6 months',
                                ProductCode = 'BEC_6',
                                Billing_Category__c = 'Subscription_MonthlyProRata',
                                ScheduleAheadTerm__c = 3,
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
                    },
                    new Map<String, Object>{
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 10,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject>{
                            new Product2(
                                Name = 'Automotive Listings 6 months XX',
                                ProductCode = 'BEC_6',
                                Billing_Category__c = 'Subscription_MonthlyProRata',
                                ScheduleAheadTerm__c = 3,
                                ContractPeriodInMonths__c = 6,
                                BillingScheme__c = 'Monthly in Arrears'
                            ),
                            new PricebookEntry(
                                PriceCalculator__c = 'IterativeTiered',
                                Tiered_OffsetPrice__c = 28.57,
                                Tiered_AdditionalPrice__c = 26.72,
                                Tiered_TierCorrection__c = -0.95,
                                ListOrder__c = 2,
                                Tiered_Tiersize__c = 10,
                                Tiered_FinalAdjustment__c = 10.00,
                                UnitPrice = 2.00,
                                UseStandardPrice = false,
                                IsActive = true
                            )
                        }
                    },
                    new Map<String, Object>{
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 10,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject>{
                            new Product2(
                                Name = 'Automotive Listings 6 months XXX',
                                ProductCode = 'BEC_6',
                                Billing_Category__c = 'Subscription_MonthlyProRata',
                                ScheduleAheadTerm__c = 3,
                                ContractPeriodInMonths__c = 6,
                                BillingScheme__c = 'Monthly in Arrears'
                            ),
                            new PricebookEntry(
                                PriceCalculator__c = 'IterativeTiered',
                                Tiered_OffsetPrice__c = 28.57,
                                Tiered_AdditionalPrice__c = 26.72,
                                Tiered_TierCorrection__c = -0.25,
                                ListOrder__c = 2,
                                Tiered_Tiersize__c = 10,
                                Tiered_FinalAdjustment__c = 10.00,
                                UnitPrice = 10.00,
                                UseStandardPrice = false,
                                IsActive = true
                            )
                        }
                    }
                }
            }),
            new DF_Scenario('THBELAU-3', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'ECG',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AU',
                DF_Scenario.CONF_USERS               => new List<String> { 'adsalesRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Opportunity per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => '2016',
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '10',
                    DF_Scenario.CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION => 'true',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                },
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 5,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject>{
                            new Product2(
                                Name = 'Automotive Listings 6 months',
                                ProductCode = 'BEC_6',
                                Billing_Category__c = 'Subscription_MonthlyProRata',
                                ScheduleAheadTerm__c = 3,
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
            })
        };
    }

    @testSetup
    static void setupSubscription() {
        UTIL.isRunningTestSetup = true;
        factory = new DF(subscriptionScenarios, usersSubscription);
        factory.setup();
        UTIL.isRunningTestSetup = false;
        UTIL_CustomJob.createTestCustomJobs();
    }

    private static void addMetrics(List<RS__c> rsList) {
        List<Metric__c> metricsToUpsert = new List<Metric__c>();
        for (RS__c rs : rsList) {
            if(rs.from_Date__c > Date.today()) continue;
            for (Metric__c m : GW_Metric.createAllMetricsFromRS(rs) ) {
                m.AD_Amount__c = 100;
                m.AD_Clicks__c = 100;
                m.AD_Impressions__c = 100;
                m.AD_OSI__c = 100;
                metricsToUpsert.add(m);
            }
        }
        insert metricsToUpsert;
    }

    @isTest
    static void testBulkScenarioTHBELAU() {
        UTIL_Log.start();
        DF_Scenario.Result result = new DF_Scenario.Result();
        DF.requeryResults(result,new Set<String>{'rss'});
        System.debug('+++ result :: ' + result);
        Test.startTest();
        addMetrics(result.rss.values());
        GW_Invoice.processBatch('THBELAU');
        Test.stopTest();

        DF.requeryResults(result,new Set<String>{'invoices','invoiceLines','oppMap','oliMap'});
        Set<Id> sub1PerBatch_AccId = new Set<Id>();
        Set<Id> sub1PerOppPerBatch_AccId = new Set<Id>();

        List<Opportunity> sub1Opp1PerBatch = new List<Opportunity>();
        List<Opportunity> sub1PerBatch = new List<Opportunity>();

        for(Integer i = 1; i < 6; i++) {
            sub1PerBatch.add(result.oppMap.get('THBELAU-1.Opportunity['+i+']'));
            sub1PerBatch.add(result.oppMap.get('THBELAU-2.Opportunity['+i+']'));
            sub1PerBatch_AccId.add(result.oppMap.get('THBELAU-1.Opportunity['+i+']').Billing_Account__c);
            sub1PerBatch_AccId.add(result.oppMap.get('THBELAU-2.Opportunity['+i+']').Billing_Account__c);
        }
        for(Integer i = 1; i < 11; i++) {
            sub1Opp1PerBatch.add(result.oppMap.get('THBELAU-3.Opportunity['+i+']'));
            sub1PerOppPerBatch_AccId.add(result.oppMap.get('THBELAU-3.Opportunity['+i+']').Billing_Account__c);
        }

        System.assertEquals(result.oppMap.size(),sub1Opp1PerBatch.size() + sub1PerBatch.size());
        UTIL_Log.d('XX oliMap: ', result.oliMap);
        List<Invoice__c> sub1PerBatch_invList = (List<Invoice__c>) GW_sObject.queryRecords('Invoice__c','BillingAccount__c',UTIL.getIdSetAsStringSet(sub1PerBatch_AccId));
        List<Invoice__c> sub1PerOppPerBatch_invList = (List<Invoice__c>) GW_sObject.queryRecords('Invoice__c','BillingAccount__c',UTIL.getIdSetAsStringSet(sub1PerOppPerBatch_AccId));

        UTIL_Log.d('XX sub1PerBatch_invList: ', sub1PerBatch_invList.size());
        UTIL_Log.d('XX sub1PerOppPerBatch_invList: ', sub1PerOppPerBatch_invList.size());

        System.assertEquals(result.invoices.size(),sub1PerBatch_invList.size() + sub1PerOppPerBatch_invList.size());
        // INVOICE NUM ASSERT
        //System.assertEquals(2,sub1PerBatch_invList.size()); // 2 Accounts (THBEL01, THBEL2), 1 Invoice per batch, 5 opp + 5 opp
        //System.assertEquals(10,sub1PerOppPerBatch_invList.size()); // 1 Account (THBEL03), 1 Invoice per opportunity per batch, 10 opp

        // Invoice line num assert
        Map<Id,List<InvoiceLine__c>> invIdToInvLineMap = new Map<Id,List<InvoiceLine__c>>();
        for(InvoiceLine__c invLine : result.invoiceLines.values()) {
            if(invIdToInvLineMap.get(invLine.Invoice__c) == NULL) {
                invIdToInvLineMap.put(invLine.Invoice__c,new List<InvoiceLine__c>{invLine});
            } else {
                invIdToInvLineMap.get(invLine.Invoice__c).add(invLine);
            }
        }
        Integer invLineCount = 0;
        // 2 Accounts (THBEL01, THBEL2), 1 Invoice per batch, 5 opp / 1 oli + 5 opp / 3 oli = 20 lines
        invLineCount = 0;
        for(Invoice__c inv : sub1PerBatch_invList) {
            for(InvoiceLine__c invLine : invIdToInvLineMap.get(inv.Id)) {
                invLineCount++;
            }
        }
        //System.assertEquals(20,invLineCount,'Incorrect number of inv lines for subscriptions 1 inv per batch');
        // 1 Account (THBEL03), 1 Invoice per opportunity per batch, 10 opp / 1 oli = 10 lines
        invLineCount = 0;
        for(Invoice__c inv : sub1PerOppPerBatch_invList) {
            for(InvoiceLine__c invLine : invIdToInvLineMap.get(inv.Id)) {
                invLineCount++;
            }
        }
        //System.assertEquals(10,invLineCount,'Incorrect number of inv lines for subscriptions 1 inv per opportunity per batch');
        UTIL_Log.end();
    }
}