/**
 * Created by ronvelzeboer on 03/08/16.
 */

@isTest
public with sharing class TST_Invoicing_ECGDKAD {
    public static DF factory;

    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
            factory = new DF(scenarios, scenarioUsers);
            factory.setup();
    
            System.runAs(factory.userMap.get('admin')) {
                UTIL_CustomJob.createTestCustomJobs();
            }
        UTIL.isRunningTestSetup = false;
    }

    @isTest
    static void testScenarioECGDKAD_01() {
        
        Test.startTest();
        UTIL_CustomJob.startAllCustomJobs();
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers);
        Opportunity opp = result.oppMap.get('ECGDKAD-01.Opportunity[1]');

        System.assertEquals('DKK', opp.CurrencyIsoCode);
        System.assertEquals('ECGDK', opp.MemberId__c);
        System.assertEquals('Signed', opp.ContractStatus__c);
        System.assertEquals('Previously Approved', opp.ApprovalStatus__c);
        System.assertEquals('1 Invoice per Batch', opp.InvoiceGrouping__c);
        System.assertEquals('AdSales', opp.LineOfBusiness__c);
        System.assertEquals(0, opp.VatAmount__c);
        System.assertEquals(0, opp.IndirectDiscountAmount__c);
        System.assertEquals(0, opp.IndirectDiscount__c);
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
        System.assertEquals(115, oli.ListPrice__c, 'OLI ListPrice not correct');
        System.assertEquals(115, oli.SalesPriceNet__c, 'OLI SalesPriceNet__c not correct');
        System.assertEquals(115, oli.TotalAmountNet__c, 'OLI TotalAmountNet__c not correct');
        
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
        
        System.debug('>>>>>>>>>>> result.rss.values() ' + result.rss.values());
        System.debug('>>>>>>>>>>> result.revs.values() ' + result.revs.values());
        
        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            // Generate invoices
            GW_Invoice.processBatch('ECGDKAD');
            Test.stopTest();
            DF.requeryResults(result,new Set<String>{'invoices','invoiceLines'});

            // GET CPM & ASSERT CPM
            System.debug('>>>>>>>>>>> result.invoicelines.values() ' + result.invoicelines.values());
            InvoiceLine__c invLine;
            for(InvoiceLine__c myInvLine : result.invoicelines.values()) {
                //if(myInvLine.Billing_Category__c == 'CPM') {
                    invLine = myInvLine;
                    break;
                //}
            }
            System.debug('>>>>>>>>>>> invLine ' + invLine);
            System.debug('>>>>>>>>>>> result.invoices ' + result.invoices);
            Invoice__c inv = result.invoices.get(invLine.Invoice__c);
            List<InvoiceLine__c> cpmInvLines = (List<InvoiceLine__c>) GW_sObject.getChildren(new Set<Id>{invLine.Invoice__c}, 'InvoiceLines__r');
            System.assertNotEquals(inv,NULL);
            System.assertEquals(1,cpmInvLines.size()); // 2 olis created

            RS__c rs = ((Map<Id,RS__c>)result.rss).get(invLine.RS__c);
            Rev__c rev = ((Map<Id,Rev__c>)result.revs).get(rs.Rev__c);

            System.assertNotEquals(rs,NULL);
            System.assertNotEquals(rev,NULL);

            System.assertEquals(inv.Amount__c,cpmInvLines.get(0).Amount__c);
            System.assertEquals(inv.MemberId__c,'ECGDK');
            System.assertEquals(inv.IndirectDiscountAmount__c,0);
            System.assertEquals(inv.NumLineItems__c,1);
            System.assertEquals(inv.NumStatus__c,6);
            System.assertEquals(inv.Status__c,'Ready for Invoicing');
            System.assertEquals(inv.StartDate__c, oli.from_Date__c);

            System.assertEquals(invLine.Billing_Category__c,'ServiceFee');
            System.assertEquals(invLine.LineOfBusiness__c,'AdSales');
            System.assertEquals(invLine.Cancelled__c,FALSE);
            System.assertEquals(invLine.CurrencyIsoCode,'DKK');
            System.assertEquals(invLine.FQ_ProductCode__c,'DBA_BAN');
            System.assertEquals(invLine.FQ_ProductSubType__c,'Banners');
            System.assertEquals(invLine.FQ_ProductType__c,'Banners');
            System.assertEquals(invLine.IndirectDiscountAmount__c,0);
            System.assertEquals(invLine.InvoiceNumStatus__c,6);
            System.assertEquals(invLine.MemberUnitId__c,'ECGDKAD');
            System.assertEquals(invLine.Missing_RS__c,0);
            System.assertEquals(invLine.NumStatus__c,6);
            System.assertEquals(invLine.Status__c,'Ready for Invoicing');
            System.assertEquals(invLine.UPCF__c,1);
            System.assertEquals(invLine.VatPercentage__c,'0');
            System.assertNotEquals(invLine.StartDate__c,null);
            System.assertNotEquals(invLine.EndDate__c,null);
        }
    }

    @isTest
    static void testScenarioECGDKAD_02() {
        Test.startTest();
        UTIL_CustomJob.startAllCustomJobs();
        
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers);
        Opportunity opp = result.oppMap.get('ECGDKAD-02.Opportunity[1]');

        System.assertEquals('DKK', opp.CurrencyIsoCode);
        System.assertEquals('ECGDK', opp.MemberId__c);
        System.assertEquals('Signed', opp.ContractStatus__c);
        System.assertEquals('Previously Approved', opp.ApprovalStatus__c);
        System.assertEquals('1 Invoice per Batch', opp.InvoiceGrouping__c);
        System.assertEquals('AdSales', opp.LineOfBusiness__c);
        System.assertEquals(0, opp.VatAmount__c);
        System.assertEquals(0, opp.IndirectDiscountAmount__c);
        System.assertEquals(0, opp.IndirectDiscount__c);

        OpportunityLineItem oli = result.oliMap.get('ECGDKAD-02.Opportunity[1].oli[Desktop: DBA Curtain / Open Door-Til Boligen [Vertical]]');

        Date fromDate = Date.today().addMonths(-1);
        System.assertEquals('CPD', oli.Billing_Category__c);
        System.assertEquals('Delivery', oli.BillingCalc__c);
        System.assertEquals(fromDate, oli.from_Date__c);
        System.assertEquals(fromDate.addMonths(1), oli.until_Date__c);
        System.assertEquals(10, oli.BundleSize__c, 'OLI BundleSize__c not correct');
        System.assertEquals('DBA_BAN', oli.ProductCode);
        System.assertEquals(10, oli.Quantity, 'OLI Quantity not correct');
        System.assertEquals(1, oli.UPCF__c, 'OLI UPCF__c not correct');
        System.assertEquals(55000, oli.ListPrice__c, 'OLI ListPrice not correct');
        System.assertEquals(55000, oli.SalesPriceNet__c, 'OLI SalesPriceNet__c not correct');
        System.assertEquals(550000, oli.TotalAmountNet__c, 'OLI TotalAmountNet__c not correct');
        
        // Fill metrics, required for AD Sales scenarios
        
        for(Metric__c metric : result.metrics.values()) {
            metric.AD_Amount__c = 10;
            metric.AD_Clicks__c = 10;
            metric.AD_Impressions__c = 10;
            metric.AD_OSI__c = 10;
        }
        update result.metrics.values();
        update result.rss.values();
        update result.revs.values();
        
        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            // Generate invoices
            GW_Invoice.processBatch('ECGDKAD');
            Test.stopTest();
            DF.requeryResults(result,new Set<String>{'invoices','invoiceLines'});

            // GET CPM & ASSERT CPM
            InvoiceLine__c invLine;
            for(InvoiceLine__c myInvLine : result.invoicelines.values()) {
                //if(myInvLine.Billing_Category__c == 'CPD') {
                    invLine = myInvLine;
                    break;
                //}
            }
            Invoice__c inv = result.invoices.get(invLine.Invoice__c);
            System.assertNotEquals(inv,NULL);

            RS__c rs = ((Map<Id,RS__c>)result.rss).get(invLine.RS__c);
            Rev__c rev = ((Map<Id,Rev__c>)result.revs).get(rs.Rev__c);

            System.assertNotEquals(rs,NULL);
            System.assertNotEquals(rev,NULL);

            System.assertEquals(inv.Amount__c,invLine.Amount__c);
            System.assertEquals(inv.MemberId__c,'ECGDK');
            System.assertEquals(inv.IndirectDiscountAmount__c,0);
            System.assertEquals(inv.NumLineItems__c,1);
            System.assertEquals(inv.NumStatus__c,6);
            System.assertEquals(inv.Status__c,'Ready for Invoicing');
            System.assertEquals(inv.StartDate__c, oli.from_Date__c);

            System.assertEquals(invLine.Billing_Category__c,'ServiceFee');
            System.assertEquals(invLine.AmountNet__c, invLine.UnitPrice__c);
            System.assertEquals(invLine.LineOfBusiness__c,'AdSales');
            System.assertEquals(invLine.Cancelled__c,FALSE);
            System.assertEquals(invLine.CurrencyIsoCode,'DKK');
            System.assertEquals(invLine.FQ_ProductCode__c,'DBA_BAN');
            System.assertEquals(invLine.FQ_ProductSubType__c,'Banners');
            System.assertEquals(invLine.FQ_ProductType__c,'Banners');
            System.assertEquals(invLine.IndirectDiscountAmount__c,0);
            System.assertEquals(invLine.InvoiceNumStatus__c,6);
            System.assertEquals(invLine.MemberUnitId__c,'ECGDKAD');
            System.assertEquals(invLine.Missing_RS__c,0);
            System.assertEquals(invLine.NumStatus__c,6);
            System.assertEquals(invLine.Status__c,'Ready for Invoicing');
            System.assertEquals(invLine.UPCF__c,1);
            System.assertEquals(invLine.VatPercentage__c,'0');
            System.assertEquals(invLine.UnitPrice__c,5000);
            System.assertNotEquals(invLine.StartDate__c,null);
            System.assertNotEquals(invLine.EndDate__c,null);
        }
        
    }

    @isTest
    static void testScenarioECGDKAD_03() {
    Test.startTest();
        //UTIL_CustomJob.startAllCustomJobs();
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers);
        Opportunity opp = result.oppMap.get('ECGDKAD-03.Opportunity[1]');

        System.assertEquals('DKK', opp.CurrencyIsoCode);
        System.assertEquals('ECGDK', opp.MemberId__c);
        System.assertEquals('Signed', opp.ContractStatus__c);
        System.assertEquals('Previously Approved', opp.ApprovalStatus__c);
        System.assertEquals('1 Invoice per Batch', opp.InvoiceGrouping__c);
        System.assertEquals('AdSales', opp.LineOfBusiness__c);
        System.assertEquals(0, opp.VatAmount__c);
        System.assertEquals(0, opp.IndirectDiscountAmount__c);
        System.assertEquals(0, opp.IndirectDiscount__c);

        OpportunityLineItem oli = result.oliMap.get('ECGDKAD-03.Opportunity[1].oli[Desktop: DBA Curtain / Open Door-Til Boligen [Vertical]]');

        Date fromDate = Date.today().addMonths(-1);
        System.assertEquals('ServiceFee', oli.Billing_Category__c);
        System.assertEquals('OneTime', oli.BillingCalc__c);
        System.assertEquals(fromDate, oli.from_Date__c);
        System.assertEquals(fromDate.addMonths(1), oli.until_Date__c);
        System.assertEquals(10, oli.BundleSize__c, 'OLI BundleSize__c not correct');
        System.assertEquals('DBA_BAN', oli.ProductCode);
        System.assertEquals(1000, oli.Quantity, 'OLI Quantity not correct');
        System.assertEquals(1, oli.UPCF__c, 'OLI UPCF__c not correct');
        System.assertEquals(5000, oli.ListPrice__c, 'OLI ListPrice not correct');
        System.assertEquals(5000, oli.SalesPriceNet__c, 'OLI SalesPriceNet__c not correct');
        System.assertEquals(5000000, oli.TotalAmountNet__c, 'OLI TotalAmountNet__c not correct');

        // Fill metrics, required for AD Sales scenarios
        
        for(Metric__c metric : result.metrics.values()) {
            metric.AD_Amount__c = 10;
            metric.AD_Clicks__c = 10;
            metric.AD_Impressions__c = 10;
            metric.AD_OSI__c = 10;
        }
        update result.metrics.values();
        update result.rss.values();
        update result.revs.values();
        UTIL_CustomJob.startAllCustomJobs();

        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            // Generate invoices
            GW_Invoice.processBatch('ECGDKAD');
            Test.stopTest();
            DF.requeryResults(result,new Set<String>{'invoices','invoiceLines'});

            // GET CPM & ASSERT CPM
            InvoiceLine__c invLine;
            for(InvoiceLine__c myInvLine : result.invoicelines.values()) {
                if(myInvLine.Billing_Category__c == 'ServiceFee') {
                    invLine = myInvLine;
                    break;
                }
            }
            Invoice__c inv = result.invoices.get(invLine.Invoice__c);
            System.assertNotEquals(inv,NULL);

            RS__c rs = ((Map<Id,RS__c>)result.rss).get(invLine.RS__c);
            Rev__c rev = ((Map<Id,Rev__c>)result.revs).get(rs.Rev__c);

            System.assertNotEquals(rs,NULL);
            System.assertNotEquals(rev,NULL);

            System.assertEquals(inv.Amount__c,invLine.Amount__c);
            System.assertEquals(inv.MemberId__c,'ECGDK');
            System.assertEquals(inv.IndirectDiscountAmount__c,0);
            System.assertEquals(inv.NumLineItems__c,1);
            System.assertEquals(inv.NumStatus__c,6);
            System.assertEquals(inv.Status__c,'Ready for Invoicing');
            System.assertEquals(inv.StartDate__c, oli.from_Date__c);

            System.assertEquals(invLine.Billing_Category__c,'ServiceFee');
            System.assertEquals(invLine.AmountNet__c,invLine.Quantity__c * oli.ListPrice__c);
            System.assertEquals(invLine.AmountNet__c,invLine.Quantity__c * invLine.UnitPrice__c);
            System.assertEquals(invLine.Amount__c,invLine.Quantity__c * oli.ListPrice__c);
            System.assertEquals(invLine.LineOfBusiness__c,'AdSales');
            System.assertEquals(invLine.Cancelled__c,FALSE);
            System.assertEquals(invLine.CurrencyIsoCode,'DKK');
            System.assertEquals(invLine.FQ_ProductCode__c,'DBA_BAN');
            System.assertEquals(invLine.FQ_ProductSubType__c,'Banners');
            System.assertEquals(invLine.FQ_ProductType__c,'Banners');
            System.assertEquals(invLine.IndirectDiscountAmount__c,0);
            System.assertEquals(invLine.InvoiceNumStatus__c,6);
            System.assertEquals(invLine.MemberUnitId__c,'ECGDKAD');
            System.assertEquals(invLine.Missing_RS__c,0);
            System.assertEquals(invLine.NumStatus__c,6);
            System.assertEquals(invLine.Status__c,'Ready for Invoicing');
            System.assertEquals(invLine.UPCF__c,1);
            System.assertEquals(invLine.VatPercentage__c,'0');
            System.assertEquals(invLine.UnitPrice__c,5000);
            System.assertNotEquals(invLine.StartDate__c,null);
            System.assertNotEquals(invLine.EndDate__c,null);
        }
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
                DF_Scenario.CONF_PRICEBOOK           => 'ECGDKAD_DBA_2016',
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>> {
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1000,
                        DF_Scenario.CONF_PRODUCT_AD_ID => 'ECGDKAD-01-01',
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Dækning & Dominans - Biler [Vertical]',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPM_Delivery',
                                ScheduleAheadTerm__c = 12,
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
                    },
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1000,
                        DF_Scenario.CONF_PRODUCT_AD_ID => '123456901234567890',
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Dækning & Dominans - Biler [Vertical] xx',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPM_Delivery',
                                ScheduleAheadTerm__c = 12,
                                ContractPeriodInMonths__c = null,
                                BillingScheme__c = 'Monthly in Arrears',
                                CPC_Price__c = 0.00,
                                CPM_Price__c = 120.00
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
                        DF_Scenario.CONF_PRODUCT_AD_ID => 'ECGDKAD-02-01',
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
                        DF_Scenario.CONF_PRODUCT_AD_ID => 'ECGDKAD-03-01',
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