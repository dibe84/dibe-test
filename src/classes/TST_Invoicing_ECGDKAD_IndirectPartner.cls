/**
 * Created by ronvelzeboer on 18/08/16.
 */

@isTest
public with sharing class TST_Invoicing_ECGDKAD_IndirectPartner {
    public static DF factory;

    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;

        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        

        System.runAs(factory.userMap.get('admin')) {
            UTIL_CustomJob.createTestCustomJobs();
            //UTIL_CustomJob.startAllCustomJobs();
        }
        UTIL.isRunningTestSetup = false;
    }

    @isTest
    static void testScenarioECGDKAD_01() {
        Test.startTest();
        UTIL_CustomJob.startAllCustomJobs();
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers);
        Opportunity opp = result.oppMap.get('ECGDKAD-01.Opportunity[1]');
        Test.stopTest();

        System.assertEquals('DKK', opp.CurrencyIsoCode);
        System.assertEquals('ECGDK', opp.MemberId__c);
        System.assertEquals('Signed', opp.ContractStatus__c);
        System.assertEquals('Previously Approved', opp.ApprovalStatus__c);
        System.assertEquals('1 Invoice per Batch', opp.InvoiceGrouping__c);
        System.assertEquals('AdSales', opp.LineOfBusiness__c);
        System.assertEquals(0, opp.VatAmount__c, 'opp.VatAmount__c not correct');
        System.assertEquals(10, opp.IndirectDiscount__c, 'opp.IndirectDiscount__c not correct');
        System.assertEquals(11.11, opp.IndirectDiscountAmount__c, 'opp.IndirectDiscountAmount__c not correct ' + opp.TotalAmountNet__c);
        OpportunityLineItem oli = result.oliMap.get('ECGDKAD-01.Opportunity[1].oli[Desktop: DBA Dækning & Dominans - Biler [Vertical]]');
        Date fromDate = Date.today().addMonths(-1);
        System.assertEquals('CPM', oli.Billing_Category__c);
        System.assertEquals('Delivery', oli.BillingCalc__c);
        System.assertEquals(fromDate, oli.from_Date__c);
        System.assertEquals(fromDate.addMonths(1), oli.until_Date__c);
        System.assertEquals(10, oli.BundleSize__c, 'OLI BundleSize__c not correct');
        System.assertEquals('DBA_BAN', oli.ProductCode);
        System.assertEquals(1000, oli.Quantity, 'OLI Quantity not correct');
        System.assertEquals(0.001, oli.UPCF__c, 'OLI UPCF__c not correct');
        System.assertEquals(100, oli.ListPrice__c, 'OLI ListPrice not correct');
        System.assertEquals(100, Math.round( oli.SalesPriceNet__c ), 'OLI SalesPriceNet__c not correct');
        System.assertEquals(100, oli.TotalAmountNet__c, 'OLI TotalAmountNet__c not correct');

        // Fill metrics, required for AD Sales scenarios
        
        for(Metric__c metric : result.metrics.values()) {
            metric.AD_Amount__c = 1000;
            metric.AD_Clicks__c = 1000;
            metric.AD_Impressions__c = 1000;
            metric.AD_OSI__c = 1000;
        }
        update result.metrics.values();
        update result.rss.values();
        update result.revs.values();
        
    }

    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;

    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'ECGDKAD_adsalesRep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'ECGDKAD',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep', // should be ECGDK Ad Sales Rep but does not exist on JC1 box
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
        };

        scenarios = new List<DF_Scenario> {

            new DF_Scenario('ECGDKAD-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'ECGDK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
                DF_Scenario.CONF_USERS               => new List<String> { 'ECGDKAD_adsalesRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_ACCOUNT_HAS_INDIRECT_PARTNER => true,
                DF_Scenario.CONF_CONTRACT_DISCOUNT   => 0,
                DF_Scenario.CONF_INDIRECT_DISCOUNT   => 10,
                DF_Scenario.CONF_PRICEBOOK           => 'ECGDKAD_DBA_2016',
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>> {
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1000,
                        DF_Scenario.CONF_PRODUCT_AD_ID => '12345678901234567890',
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Dækning & Dominans - Biler [Vertical]',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPM_Delivery',
                                ScheduleAheadTerm__c = 12,
                                ContractPeriodInMonths__c = null,
                                BillingScheme__c = 'Monthly in Arrears',
                                CPC_Price__c = 0.00,
                                CPM_Price__c = 100.00
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
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                }
            }),
            new DF_Scenario('ECGDKAD-03', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'ECGDK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
                DF_Scenario.CONF_USERS               => new List<String> { 'ECGDKAD_adsalesRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => 'ECGDKAD_DBA_2016',
                DF_Scenario.CONF_PRODUCTS =>  new List<Map<String, Object>> {
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1000,
                        DF_Scenario.CONF_PRODUCT_DATA  => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Curtain / Open Door-Til Boligen [Vertical]',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'ServiceFee_OneTime',
                                ScheduleAheadTerm__c = 12,
                                ContractPeriodInMonths__c = null,
                                ServiceFee_Price__c = 5000.00,
                                BillingScheme__c = 'Monthly in Arrears'
                            ),
                            new PricebookEntry(
                                PriceCalculator__c = null,
                                Tiered_OffsetPrice__c = 0.00,
                                Tiered_AdditionalPrice__c = 0.00,
                                Fixed_PricePerMonth__c = 0.00,
                                Tiered_Tiersize__c = 0.00,
                                Tiered_FinalAdjustment__c = 0.00,
                                UnitPrice = 1.00,
                                MaxDiscountPercent__c = 30.00,
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
}