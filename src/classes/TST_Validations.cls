@isTest
public class TST_Validations {
    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;
    public static DF factory;

    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'adsalesRep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'THBELAU_Rep',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
        };

        scenarios = new List<DF_Scenario> {
            new DF_Scenario('THBELAU-1', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'THBEL',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AU',
                DF_Scenario.CONF_USERS               => new List<String> { 'adsalesRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => '2016',
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
                    DF_Scenario.CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION => 'true',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
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
            })
        };
    }

    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        UTIL_Log.start();
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        UTIL.isRunningTestSetup = false;

        System.runAs(factory.userMap.get('admin')) {
            UTIL_CustomJob.startAllCustomJobs();
        }
        UTIL_Log.end();
    }

    @isTest
    static void testRevenueItemDoNotInvoice() {
        UTIL_Log.start();
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'revs'});
        Test.startTest();
        Map<Id, Rev__c> revMap = result.revs;
        System.assertNotEquals(0,revMap.size());
        Rev__c revToTest = revMap.values().get(0);

        // Set checkbox but no reason -> ERROR
        try {
            System.assertEquals(FALSE,revToTest.DoNotInvoice__c);
            revToTest.DoNotInvoice__c = TRUE;
            update revToTest;
        } catch (Exception ex) {
            revToTest = GW_Revenue.getRecord(revToTest.Id);
            System.assertEquals(FALSE,revToTest.DoNotInvoice__c);
        }

        try {
            // Set reason but no checkbox -> ERROR
            revToTest.DoNotInvoiceReason__c = 'Previously invoiced';
            update revToTest;
        } catch (Exception ex) {
            revToTest = GW_Revenue.getRecord(revToTest.Id);
            System.assertEquals(FALSE,revToTest.DoNotInvoice__c);
            System.assertEquals(NULL,revToTest.DoNotInvoiceReason__c);
        }

        // Set reason + checkbox -> OK
        revToTest.DoNotInvoiceReason__c = 'Previously invoiced';
        revToTest.DoNotInvoice__c = TRUE;
        update revToTest;

        revToTest = GW_Revenue.getRecord(revToTest.Id);
        System.assertEquals(TRUE,revToTest.DoNotInvoice__c);
        System.assertEquals('Previously invoiced',revToTest.DoNotInvoiceReason__c);

        try {
            // Uncheck -> ERROR
            revToTest.DoNotInvoice__c = FALSE;
            update revToTest;
        } catch (Exception ex) {
            revToTest = GW_Revenue.getRecord(revToTest.Id);
            System.assertEquals(TRUE,revToTest.DoNotInvoice__c);
            System.assertEquals('Previously invoiced',revToTest.DoNotInvoiceReason__c);
        }

        try {
            // Nullify reason -> ERROR
            revToTest.DoNotInvoiceReason__c = NULL;
            update revToTest;
        } catch (Exception ex) {
            revToTest = GW_Revenue.getRecord(revToTest.Id);
            System.assertEquals(TRUE,revToTest.DoNotInvoice__c);
            System.assertEquals('Previously invoiced',revToTest.DoNotInvoiceReason__c);
        }

        // Change reason -> OK
        revToTest.DoNotInvoiceReason__c = 'Already billed';
        update revToTest;

        revToTest = GW_Revenue.getRecord(revToTest.Id);
        System.assertEquals(TRUE,revToTest.DoNotInvoice__c);
        System.assertEquals('Already billed',revToTest.DoNotInvoiceReason__c);
        Test.stopTest();
    }

    @isTest
    static void testRevenueScheduleDoNotInvoice() {
        UTIL_Log.start();
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'rss'});
        Test.startTest();

        Map<Id, RS__c> rsMap = result.rss;
        System.assertNotEquals(0,rsMap.size());
        RS__c rsToTest = rsMap.values().get(0);

        // Set checkbox but no reason -> ERROR
        try {
            System.assertEquals(FALSE,rsToTest.DoNotInvoice__c);
            rsToTest.DoNotInvoice__c = TRUE;
            update rsToTest;
        } catch (Exception ex) {
            rsToTest = GW_RS.getRecord(rsToTest.Id);
            System.assertEquals(FALSE,rsToTest.DoNotInvoice__c);
        }

        try {
            // Set reason but no checkbox -> ERROR
            rsToTest.DoNotInvoiceReason__c = 'Previously invoiced';
            update rsToTest;
        } catch (Exception ex) {
            rsToTest = GW_RS.getRecord(rsToTest.Id);
            System.assertEquals(FALSE,rsToTest.DoNotInvoice__c);
            System.assertEquals(NULL,rsToTest.DoNotInvoiceReason__c);
        }

        // Set reason + checkbox -> OK
        rsToTest.DoNotInvoiceReason__c = 'Previously invoiced';
        rsToTest.DoNotInvoice__c = TRUE;
        update rsToTest;

        rsToTest = GW_RS.getRecord(rsToTest.Id);
        System.assertEquals(TRUE,rsToTest.DoNotInvoice__c);
        System.assertEquals('Previously invoiced',rsToTest.DoNotInvoiceReason__c);

        try {
            // Uncheck -> ERROR
            rsToTest.DoNotInvoice__c = FALSE;
            update rsToTest;
        } catch (Exception ex) {
            rsToTest = GW_RS.getRecord(rsToTest.Id);
            System.assertEquals(TRUE,rsToTest.DoNotInvoice__c);
            System.assertEquals('Previously invoiced',rsToTest.DoNotInvoiceReason__c);
        }

        try {
            // Nullify reason -> ERROR
            rsToTest.DoNotInvoiceReason__c = NULL;
            update rsToTest;
        } catch (Exception ex) {
            rsToTest = GW_RS.getRecord(rsToTest.Id);
            System.assertEquals(TRUE,rsToTest.DoNotInvoice__c);
            System.assertEquals('Previously invoiced',rsToTest.DoNotInvoiceReason__c);
        }

        // Change reason -> OK
        rsToTest.DoNotInvoiceReason__c = 'Already billed';
        update rsToTest;

        rsToTest = GW_RS.getRecord(rsToTest.Id);
        System.assertEquals(TRUE,rsToTest.DoNotInvoice__c);
        System.assertEquals('Already billed',rsToTest.DoNotInvoiceReason__c);
        Test.stopTest();
    }

    @isTest
    static void testAccountPhoneNumber() {
        UTIL_Log.start();
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts'});
        Test.startTest();
        Map<Id, Account> accMap = result.accounts;
        System.assertNotEquals(0,accMap.size());
        Account accToTest = accMap.values().get(0);

        accToTest.Phone = null;
        accToTest.Other_Phone__c = null;

        update accToTest;

        accToTest = GW_Account.getRecord(accToTest.Id);

        // Update Phone FROM null TO incorrect value -> failed to save
        accToTest.Phone = '301601901';

        try {
            update accToTest;
        } catch(Exception ex) {
            accToTest = GW_Account.getRecord(accToTest.Id);
            System.assertEquals(NULL,accToTest.Phone);
        }

        // Update Phone FROM null TO correct value -> OK value saved
        accToTest.Phone = '+301601901';

        try {
            update accToTest;
        } catch(Exception ex) {
            System.assertEquals(TRUE,FALSE,'Failed to save correct phone number!');
        }
        System.assertEquals('+301601901',accToTest.Phone);

        // Update Other_Phone__c FROM null TO incorrect value -> failed to save
        accToTest.Other_Phone__c = '301601901';

        try {
            update accToTest;
        } catch(Exception ex) {
            accToTest = GW_Account.getRecord(accToTest.Id);
            System.assertEquals(NULL,accToTest.Other_Phone__c);
        }

        // Update Other_Phone__c FROM null TO correct value -> OK value saved
        accToTest.Other_Phone__c = '+301601901';

        try {
            update accToTest;
        } catch(Exception ex) {
            System.assertEquals(TRUE,FALSE,'Failed to save correct other phone number!');
        }
        System.assertEquals('+301601901',accToTest.Other_Phone__c);
        Test.stopTest();
    }

    @isTest
    static void testContactPhoneNumber() {
        UTIL_Log.start();
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'contacts'});

        Test.startTest();

        Map<Id, Contact> conMap = result.contacts;
        System.assertNotEquals(0,conMap.size());
        Contact conToTest = conMap.values().get(0);

        conToTest.OtherPhone = null;
        conToTest.HomePhone = null;
        conToTest.MobilePhone = null;

        update conToTest;

        conToTest = GW_Contact.getRecord(conToTest.Id);

        // Update HomePhone FROM null TO incorrect value -> failed to save
        conToTest.HomePhone = '301601901';

        try {
            update conToTest;
        } catch(Exception ex) {
            conToTest = GW_Contact.getRecord(conToTest.Id);
        }
        System.assertEquals(NULL,conToTest.HomePhone);

        // Update HomePhone FROM null TO correct value -> OK value saved
        conToTest.HomePhone = '+301601901';

        try {
            update conToTest;
        } catch(Exception ex) {
            System.assertEquals(TRUE,FALSE,'Failed to save correct HomePhone number!');
        }
        System.assertEquals('+301601901',conToTest.HomePhone);

        // Update OtherPhone FROM null TO incorrect value -> failed to save
        conToTest.OtherPhone = '301601901';

        try {
            update conToTest;
        } catch(Exception ex) {
            conToTest = GW_Contact.getRecord(conToTest.Id);
        }
        System.assertEquals(NULL,conToTest.OtherPhone);

        // Update OtherPhone FROM null TO correct value -> OK value saved
        conToTest.OtherPhone = '+301601901';

        try {
            update conToTest;
        } catch(Exception ex) {
            System.assertEquals(TRUE,FALSE,'Failed to save correct other phone number!');
        }
        System.assertEquals('+301601901',conToTest.OtherPhone);
        Test.stopTest();
    }

    @isTest
    static void testCasePhoneNumber() {
        Test.startTest();
        MemberUnit__c mu = [SELECT Id, Member__c FROM MemberUnit__c LIMIT 1];
        // Create SIC__c
        SIC__c sic = new SIC__c(Name='Test', Code__c='123456');
        insert sic;

        // Create lead
        Lead l = new Lead();
        l.FirstName = 'Test';
        l.LastName = 'Lead';
        l.Company = 'Test Company';
        l.Email = 'test@lead.com';
        l.OwnerId = UserInfo.getUserId();
        l.Member__c = mu.Member__c;
        l.MemberUnit__c = mu.Id;
        l.Type__c = 'Advertising';
        l.SIC__c = sic.Id;
        l.LeadSource = 'Advertisement';

        insert l;

        Case c = new Case();
        c.Lead__c = l.Id;
        c.Subject = 'test case';
        c.Origin = 'ECITAAU: Campaign Response';

        insert c;

        c.SuppliedPhone = null;
        update c;

        c = GW_Case.getRecord(c.Id);

        // Update SuppliedPhone FROM null TO incorrect value -> failed to save
        c.SuppliedPhone = '301601901';

        try {
            update c;
        } catch(Exception ex) {
            c = GW_Case.getRecord(c.Id);
        }
        System.assertEquals(NULL,c.SuppliedPhone);

        // Update SuppliedPhone FROM null TO correct value -> OK value saved
        c.SuppliedPhone = '+301601901';

        try {
            update c;
        } catch(Exception ex) {
            System.assertEquals(TRUE,FALSE,'Failed to save correct SuppliedPhone number!');
        }
        System.assertEquals('+301601901',c.SuppliedPhone);
        Test.stopTest();
    }
}