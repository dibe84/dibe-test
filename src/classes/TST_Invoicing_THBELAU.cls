@isTest
public class TST_Invoicing_THBELAU {

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

    @isTest
    static void testScenarioTHBELAU_1() {
        Test.startTest();
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers);
        Opportunity opp = result.oppMap.get('THBELAU-1.Opportunity[1]');
        MemberUnit__c mu = result.memberUnits.get(opp.MemberUnit__c);

        System.assertEquals('THBEL', opp.MemberId__c);
        System.assertEquals('Signed', opp.ContractStatus__c);
        System.assertEquals('Previously Approved', opp.ApprovalStatus__c);
        System.assertEquals('Running', opp.Status__c);
        System.assertEquals('1 Invoice per Batch', opp.InvoiceGrouping__c);
        System.assertEquals('Automotive', opp.LineOfBusiness__c);
        System.assertEquals(0, opp.VatAmount__c , 'opp.VatAmount__c incorrect');
        System.assertEquals(0, opp.IndirectDiscountAmount__c, 'opp.IndirectDiscountAmount__c incorrect');
        System.assertEquals(0, opp.IndirectDiscount__c, 'opp.IndirectDiscount__c incorrect');

        OpportunityLineItem oli = result.oliMap.get('THBELAU-1.Opportunity[1].oli[Motor Listings 12 Months]');
        Date fromDate = TODAY_THBELAU.addMonths(-1);
        System.assertEquals('Subscription', oli.Billing_Category__c);
        System.assertEquals('MonthlyProRata', oli.BillingCalc__c);
        System.assertEquals(fromDate, oli.from_Date__c);
        System.assertEquals(fromDate.addMonths(12), oli.until_Date__c);
        System.assertEquals(1, oli.BundleSize__c, 'OLI BundleSize__c not correct');
        System.assertEquals('BEC_12', oli.ProductCode);
        System.assertEquals('Running', oli.Status__c);
        System.assertEquals(1, oli.Quantity, 'OLI Quantity not correct');
        System.assertEquals(1, oli.UPCF__c, 'OLI UPCF__c not correct');
        System.assertEquals(3, oli.ListPrice__c, 'OLI ListPrice not correct');
        System.assertEquals(3, oli.SalesPriceNet__c, 'OLI SalesPriceNet__c not correct');
        System.assertEquals(3, oli.TotalPrice, 'OLI TotalPrice not correct');

        System.runAs(result.users.get('autosRep')) {
            
            GW_Invoice.processBatch('THBELAU');
            Test.stopTest();
            DF.requeryResults(result,new Set<String>{'invoices','invoiceLines'});

            InvoiceLine__c invLine;
            for(InvoiceLine__c iLine : result.invoicelines.values()) {
                if(iLine.Billing_Category__c == 'Subscription' && iLine.FQ_ProductCode__c == 'BEC_12') {
                    invLine = iLine;
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
            System.assertEquals(inv.MemberId__c,'THBEL');
            System.assertEquals(inv.IndirectDiscountAmount__c,0);
            System.assertEquals(inv.NumLineItems__c,1);
            System.assertEquals(inv.NumStatus__c,6);
            System.assertEquals(inv.Status__c,'Ready for Invoicing');
            System.assertEquals(inv.StartDate__c, oli.from_Date__c);

            System.assertEquals(invLine.Billing_Category__c,'Subscription');
            System.assertEquals(invLine.LineOfBusiness__c,'Automotive');
            System.assertEquals(invLine.Cancelled__c,FALSE);
            System.assertEquals(invLine.CurrencyIsoCode,'EUR');
            System.assertEquals(invLine.FQ_ProductCode__c,'BEC_12');
            System.assertEquals(invLine.FQ_ProductSubType__c,'Banners');
            System.assertEquals(invLine.FQ_ProductType__c,'Banners');
            System.assertEquals(invLine.IndirectDiscountAmount__c,0);
            System.assertEquals(invLine.InvoiceNumStatus__c,6);
            System.assertEquals(invLine.MemberUnitId__c,'THBELAU');
            System.assertEquals(invLine.Missing_RS__c,0);
            System.assertEquals(invLine.NumStatus__c,6);
            System.assertEquals(invLine.Status__c,'Ready for Invoicing');
            System.assertEquals(invLine.UPCF__c,1);
            System.assertEquals(invLine.VatPercentage__c,'0');
            System.assertEquals(invLine.UnitPrice__c,3);
            System.assertEquals(invLine.InvoiceLineDescription__c,'Motor Listings 12 Months');
            System.assertNotEquals(invLine.StartDate__c,null);
            System.assertNotEquals(invLine.EndDate__c,null);
        }
    }

    @isTest
    static void testScenarioTHBELAU_2() {
        
        Test.startTest();
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers);
        Opportunity opp = result.oppMap.get('THBELAU-2.Opportunity[1]');
        MemberUnit__c mu = result.memberUnits.get(opp.MemberUnit__c);

        System.assertEquals('THBEL', opp.MemberId__c);
        System.assertEquals('Signed', opp.ContractStatus__c);
        System.assertEquals('Previously Approved', opp.ApprovalStatus__c);
        System.assertEquals('Running', opp.Status__c);
        System.assertEquals('1 Invoice per Batch', opp.InvoiceGrouping__c);
        System.assertEquals('Automotive', opp.LineOfBusiness__c);
        System.assertEquals(0, opp.VatAmount__c);
        System.assertEquals(0, opp.IndirectDiscountAmount__c);
        System.assertEquals(0, opp.IndirectDiscount__c);

        OpportunityLineItem oli = result.oliMap.get('THBELAU-2.Opportunity[1].oli[Automotive Listings 6 months]');
        Date fromDate = TODAY_THBELAU.addMonths(-1);
        System.assertEquals('Subscription', oli.Billing_Category__c);
        System.assertEquals('MonthlyProRata', oli.BillingCalc__c);
        System.assertEquals(fromDate, oli.from_Date__c);
        System.assertEquals(fromDate.addMonths(6), oli.until_Date__c);
        System.assertEquals(0, oli.BundleSize__c, 'OLI BundleSize__c not correct');
        System.assertEquals('BEC_6', oli.ProductCode);
        System.assertEquals('Running', oli.Status__c); // !!! scenario script said 'Draft', but should be 'Running'
        System.assertEquals(1, oli.Quantity, 'OLI Quantity not correct');
        System.assertEquals(1, oli.UPCF__c, 'OLI UPCF__c not correct');
        System.assertEquals(38.57, oli.ListPrice__c, 'OLI ListPrice not correct');
        System.assertEquals(38.57, oli.SalesPriceNet__c, 'OLI SalesPriceNet__c not correct');
        System.assertEquals(38.57, oli.TotalPrice, 'OLI TotalPrice not correct');

        System.runAs(result.users.get('autosRep')) {
            
            GW_Invoice.processBatch('THBELAU');
            Test.stopTest();

            DF.requeryResults(result,new Set<String>{'invoices','invoiceLines'});

            Invoice__c inv;
            for(InvoiceLine__c iLine : result.invoicelines.values()) {
                if(iLine.FQ_ProductCode__c == 'BEC_6') {
                    inv = result.invoices.get(iLine.Invoice__c);
                    break;
                }
            }
            List<InvoiceLine__c> invLines = (List<InvoiceLine__c>) GW_sObject.getChildren(new Set<Id>{inv.Id}, 'InvoiceLines__r');
            System.assertNotEquals(inv,NULL);
            System.assertNotEquals(invLines,NULL);

            InvoiceLine__c invLine = invLines.get(0);
            System.assertEquals(inv.Amount__c,invLine.Amount__c);
            System.assertEquals(inv.MemberId__c,'THBEL');
            System.assertEquals(inv.IndirectDiscountAmount__c,0);
            System.assertEquals(inv.NumLineItems__c,1);
            System.assertEquals(inv.NumStatus__c,6);
            System.assertEquals(inv.Status__c,'Ready for Invoicing');
            System.assertEquals(inv.StartDate__c, oli.from_Date__c);

            System.assertEquals(invLine.Billing_Category__c,'Subscription');
            System.assertEquals(invLine.LineOfBusiness__c,'Automotive');
            System.assertEquals(invLine.Cancelled__c,FALSE);
            System.assertEquals(invLine.CurrencyIsoCode,'EUR');
            System.assertEquals(invLine.FQ_ProductCode__c,'BEC_6');
            System.assertEquals(invLine.FQ_ProductSubType__c,'Banners');
            System.assertEquals(invLine.FQ_ProductType__c,'Banners');
            System.assertEquals(invLine.IndirectDiscountAmount__c,0);
            System.assertEquals(invLine.InvoiceNumStatus__c,6);
            System.assertEquals(invLine.MemberUnitId__c,'THBELAU');
            System.assertEquals(invLine.Missing_RS__c,0);
            System.assertEquals(invLine.NumStatus__c,6);
            System.assertEquals(invLine.Status__c,'Ready for Invoicing');
            System.assertEquals(invLine.UPCF__c,1);
            System.assertEquals(invLine.VatPercentage__c,'0');
            System.assertEquals(invLine.UnitPrice__c,38.57);
            System.assertNotEquals(invLine.StartDate__c,null);
            System.assertNotEquals(invLine.EndDate__c,null);
        }
    }

    @isTest
    static void testScenarioTHBELAU_3() {
        Test.startTest();
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers);
        Opportunity opp = result.oppMap.get('THBELAU-3.Opportunity[1]');
        Account account = result.accounts.get(opp.AccountId);
        MemberUnit__c mu = result.memberUnits.get(opp.MemberUnit__c);
        System.assertEquals(null, account.DefaultIndirect__c, 'Default Indirect Account should be null');

        System.assertEquals('THBEL', opp.MemberId__c);
        System.assertEquals('Signed', opp.ContractStatus__c);
        System.assertEquals('Previously Approved', opp.ApprovalStatus__c);
        System.assertEquals('Running', opp.Status__c);
        System.assertEquals('1 Invoice per Batch', opp.InvoiceGrouping__c);
        System.assertEquals('Automotive', opp.LineOfBusiness__c);
        System.assertEquals(0, opp.VatAmount__c);
        System.assertEquals(0, opp.IndirectDiscountAmount__c);
        System.assertEquals(0, opp.IndirectDiscount__c);

        OpportunityLineItem oli = result.oliMap.get('THBELAU-3.Opportunity[1].oli[AutoScout24 24 Months]');
        Date fromDate = TODAY_THBELAU.addMonths(-1);
        System.assertEquals('Subscription', oli.Billing_Category__c);
        System.assertEquals('MonthlyProRata', oli.BillingCalc__c);
        System.assertEquals(fromDate, oli.from_Date__c);
        System.assertEquals(fromDate.addMonths(24), oli.until_Date__c);
        System.assertEquals(10, oli.BundleSize__c, 'OLI BundleSize__c not correct');
        System.assertEquals(oli.ProductCode, 'BEC_24');
        System.assertEquals('Running', oli.Status__c); // !!! scenario script said 'Draft', but should be 'Running'
        System.assertEquals(1, oli.Quantity, 'OLI Quantity not correct');
        System.assertEquals(1, oli.UPCF__c, 'OLI UPCF__c not correct');
        System.assertEquals(50, oli.ListPrice__c, 'OLI ListPrice not correct');
        System.assertEquals(50, oli.SalesPriceNet__c, 'OLI SalesPriceNet__c not correct');
        System.assertEquals(50, oli.TotalPrice, 'OLI TotalPrice not correct');

        System.runAs(result.users.get('autosRep')) {
            
            GW_Invoice.processBatch('THBELAU');
            Test.stopTest();

            DF.requeryResults(result,new Set<String>{'invoices','invoiceLines'});

            Invoice__c inv;
            for(InvoiceLine__c iLine : result.invoicelines.values()) {
                if(iLine.FQ_ProductCode__c == 'BEC_24') {
                    inv = result.invoices.get(iLine.Invoice__c);
                    break;
                }
            }
            List<InvoiceLine__c> invLines = (List<InvoiceLine__c>) GW_sObject.getChildren(new Set<Id>{inv.Id}, 'InvoiceLines__r');
            System.assertNotEquals(inv,NULL);
            System.assertNotEquals(invLines,NULL);

            InvoiceLine__c invLine = invLines.get(0);
            System.assertEquals(inv.Amount__c,invLine.Amount__c);
            System.assertEquals(inv.MemberId__c,'THBEL');
            System.assertEquals(inv.IndirectDiscountAmount__c,0);
            System.assertEquals(inv.NumLineItems__c,1);
            System.assertEquals(inv.NumStatus__c,6);
            System.assertEquals(inv.Status__c,'Ready for Invoicing');
            System.assertEquals(inv.StartDate__c, oli.from_Date__c);

            System.assertEquals(invLine.Billing_Category__c,'Subscription');
            System.assertEquals(invLine.LineOfBusiness__c,'Automotive');
            System.assertEquals(invLine.Cancelled__c,FALSE);
            System.assertEquals(invLine.CurrencyIsoCode,'EUR');
            System.assertEquals(invLine.FQ_ProductCode__c,'BEC_24');
            System.assertEquals(invLine.FQ_ProductSubType__c,'Banners');
            System.assertEquals(invLine.FQ_ProductType__c,'Banners');
            System.assertEquals(invLine.IndirectDiscountAmount__c,0);
            System.assertEquals(invLine.InvoiceNumStatus__c,6);
            System.assertEquals(invLine.MemberUnitId__c,'THBELAU');
            System.assertEquals(invLine.Missing_RS__c,0);
            System.assertEquals(invLine.NumStatus__c,6);
            System.assertEquals(invLine.Status__c,'Ready for Invoicing');
            System.assertEquals(invLine.UPCF__c,1);
            System.assertEquals(invLine.VatPercentage__c,'0');
            System.assertEquals(invLine.UnitPrice__c,50);
            System.assertNotEquals(invLine.StartDate__c,null);
            System.assertNotEquals(invLine.EndDate__c,null);
        }
    }

}