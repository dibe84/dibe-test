@isTest
public class TST_Invoicing_ECGDKAD_Bulk {

    public static List<DF_Scenario> adSalesScenarios;
    public static Map<String, Map<String, String>> usersAdsales;
    public static DF factory;

    static {
        usersAdsales = new Map<String, Map<String, String>> {
            'ECGDKAD_adsalesRep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'ECGDKAD',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep', // should be ECGDK Ad Sales Rep but does not exist on JC1 box
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
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
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 10,
                        DF_Scenario.CONF_PRODUCT_AD_ID => 'ECGDKAD-01-01',
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Dækning & Dominans - Biler [Vertical]',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPM_Delivery',
                                ScheduleAheadTerm__c = 3,
                                ContractPeriodInMonths__c = null,
                                BillingScheme__c = 'Monthly in Arrears',
                                CPC_Price__c = 0.00,
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
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 10,
                        DF_Scenario.CONF_PRODUCT_AD_ID => 'ECGDKAD-02-01',
                        DF_Scenario.CONF_PRODUCT_DATA  => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Curtain / Open Door-Til Boligen [Vertical]',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPD_Delivery',
                                ScheduleAheadTerm__c = 3,
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
                    },
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 10,
                        DF_Scenario.CONF_PRODUCT_AD_ID => 'ECGDKAD-02-02',
                        DF_Scenario.CONF_PRODUCT_DATA  => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Curtain / Open Door-Til Boligen [Vertical]',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPD_Delivery',
                                ScheduleAheadTerm__c = 3,
                                ContractPeriodInMonths__c = null,
                                BillingScheme__c = 'Monthly in Arrears',
                                CPD_Price__c = 40000
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
                    },
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 10,
                        DF_Scenario.CONF_PRODUCT_AD_ID => 'ECGDKAD-02-03',
                        DF_Scenario.CONF_PRODUCT_DATA  => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Curtain / Open Door-Til Boligen [Vertical]',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPD_Delivery',
                                ScheduleAheadTerm__c = 3,
                                ContractPeriodInMonths__c = null,
                                BillingScheme__c = 'Monthly in Arrears',
                                CPD_Price__c = 30000
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
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '2',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                }
            }),
            new DF_Scenario('ECGDKAD-03', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'ECGDK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
                DF_Scenario.CONF_USERS               => new List<String> { 'ECGDKAD_adsalesRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Opportunity per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => 'ECGDKAD_DBA_2016',
                DF_Scenario.CONF_PRODUCTS =>  new List<Map<String, Object>> {
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 10,
                        DF_Scenario.CONF_PRODUCT_AD_ID => 'ECGDKAD-03-01',
                        DF_Scenario.CONF_PRODUCT_DATA  => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Curtain / Open Door-Til Boligen [Vertical]',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPD_Delivery',
                                ScheduleAheadTerm__c = 3,
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
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '2',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                }
            })
        };
    }

    @testSetup
    static void setupAdsales() {
        UTIL.isRunningTestSetup = true;
        factory = new DF(adSalesScenarios, usersAdsales);
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
    static void testBulkScenarioECGDK() {
        UTIL_Log.start();
        Test.startTest();
        DF_Scenario.Result result = new DF_Scenario.Result();
        DF.requeryResults(result,new Set<String>{'rss'});
        addMetrics(result.rss.values());

        GW_Invoice.processBatch('ECGDKAD');
        Test.stopTest();
        
        DF.requeryResults(result,new Set<String>{'invoices','invoiceLines','oppMap','oliMap'});
        
        Set<Id> ads1PerBatch_AccId = new Set<Id>();
        Set<Id> ads1PerOppPerBatch_AccId = new Set<Id>();

        List<Opportunity> adSales1Opp1PerBatch = new List<Opportunity>();
        List<Opportunity> adSales1PerBatch = new List<Opportunity>();

        for(Integer i = 1; i < 3; i++) {
            adSales1PerBatch.add(result.oppMap.get('ECGDKAD-01.Opportunity['+i+']'));
            adSales1PerBatch.add(result.oppMap.get('ECGDKAD-02.Opportunity['+i+']'));
            ads1PerBatch_AccId.add(result.oppMap.get('ECGDKAD-01.Opportunity['+i+']').Billing_Account__c);
            ads1PerBatch_AccId.add(result.oppMap.get('ECGDKAD-02.Opportunity['+i+']').Billing_Account__c);
        }
        for(Integer i = 1; i < 3; i++) {
            adSales1Opp1PerBatch.add(result.oppMap.get('ECGDKAD-03.Opportunity['+i+']'));
            ads1PerOppPerBatch_AccId.add(result.oppMap.get('ECGDKAD-03.Opportunity['+i+']').Billing_Account__c);
        }

        System.assertEquals(result.oppMap.size(),adSales1Opp1PerBatch.size() + adSales1PerBatch.size());
        List<Invoice__c> ads1PerBatch_invList = (List<Invoice__c>) GW_sObject.queryRecords('Invoice__c','BillingAccount__c',UTIL.getIdSetAsStringSet(ads1PerBatch_AccId));
        List<Invoice__c> ads1PerOppPerBatch_invList = (List<Invoice__c>) GW_sObject.queryRecords('Invoice__c','BillingAccount__c',UTIL.getIdSetAsStringSet(ads1PerOppPerBatch_AccId));

        System.assertEquals(result.invoices.size(),ads1PerBatch_invList.size() + ads1PerOppPerBatch_invList.size());
        // INVOICE NUM ASSERT
        System.assertEquals(2,ads1PerBatch_invList.size());
        System.assertEquals(2,ads1PerOppPerBatch_invList.size());

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
        for(Invoice__c inv : ads1PerBatch_invList) {
            for(InvoiceLine__c invLine : invIdToInvLineMap.get(inv.Id)) {
                invLineCount++;
            }
        }
        System.assertEquals(8,invLineCount,'Incorrect number of inv lines for adsales 1 inv per batch');

        invLineCount = 0;
        for(Invoice__c inv : ads1PerOppPerBatch_invList) {
            for(InvoiceLine__c invLine : invIdToInvLineMap.get(inv.Id)) {
                invLineCount++;
            }
        }
        System.assertEquals(2,invLineCount,'Incorrect number of inv lines for adsales 1 inv per batch');
        UTIL_Log.end();
    }
}