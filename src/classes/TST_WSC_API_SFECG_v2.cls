/**
 * Created by rvannierop on 2/8/2017.
 */

@isTest
public with sharing class TST_WSC_API_SFECG_v2 {

    public static DF factory;

    @testSetup
    static void setup() {
		Test.startTest();
        UTIL.isRunningTestSetup = true;

        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        UTIL.isRunningTestSetup = false;

        System.runAs(factory.userMap.get('admin')) {
            UTIL_CustomJob.createTestCustomJobs();
            UTIL_CustomJob.startAllCustomJobs();
        }
		Test.stopTest();
    }

    @isTest
    static void testBookingPushV2_ECITAAU_1() {
		Test.startTest();
			DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'accounts', 'oppMap', 'revs'});
			Opportunity opp = result.oppMap.values()[0];
			Account acc = result.accounts.get(opp.AccountId);
			Rev__c rev = result.revs.values()[0];

			System.assertEquals(1, result.revs.size());
			System.assertEquals(null, result.revs.values()[0].LocalBookingId__c);
			//System.assertEquals('Signed', opp.Status__c); //TMP

			System.assertEquals(true, rev.NumStatus__c > 1);
			System.assertEquals(false, acc.LocalPlatformId__c != null);
			System.assertEquals(true, !rev.OutOfSync__c);
			System.assertEquals(true, rev.Type__c == 'Master');

			List<WS_ScheduledCallout__c> schCallouts = [SELECT Id FROM WS_ScheduledCallout__c WHERE RecordId__c = : result.revs.values()[0].Id AND Method__c='BookingPush'];
			System.assertEquals(0, schCallouts.size());

			List<Webservice_Settings__c> wss = new List<Webservice_Settings__c> {
					new Webservice_Settings__c(Name='ECITA_WSC_API_SFECG_v2_UAT', Endpoint__c='http://testing123.test.com', Key__c='notrealyakey', User__c='notrealyausername'),
					new Webservice_Settings__c(Name='ECITA_WSC_API_SFECG_v2_PROD', Endpoint__c='http://testing123.test.com', Key__c='notrealyakey', User__c='notrealyausername'),
					new Webservice_Settings__c(Name='ECITA_WSC_API_SFECG_v1_UAT', Endpoint__c='http://testing123.test.com', Key__c='notrealyakey', User__c='notrealyausername'),
					new Webservice_Settings__c(Name='ECITA_WSC_API_SFECG_v1_PROD', Endpoint__c='http://testing123.test.com', Key__c='notrealyakey', User__c='notrealyausername')
			};

			insert wss;

			List<WSC_Subscription__c> wscs = new List<WSC_Subscription__c> {
					new WSC_Subscription__c(Name='ECITAAU.WSC_API_SFECG_v2.bookingPush', ConsumerId__c='ECITAAU', Method__c='BookingPush', IsActive__c=true, Class__c='WSC_API_SFECG_v2'),
					new WSC_Subscription__c(Name='ECITAAU.WSC_API_SFECG_v1.AccountPush', ConsumerId__c='ECITAAU', Method__c='AcountPush', IsActive__c=true, Class__c='WSC_API_SFECG_v1')
			};
			insert wscs;

			acc.UniquePlatformId__c = 'ECITA_12345';
			update acc;

			UTIL_WSC.TESTMOCK = 'insertSuccess';

			rev.Touch__c = 'Should be enough to trigger outbound call.';
			update rev;

			UTIL_CustomJob.startCustomJob('BAT_WS_ScheduledCalloutHandler');

        Test.stopTest();

        rev = [SELECT Id, LocalBookingId__c FROM Rev__c WHERE Id =: rev.Id ];
        opp = [SELECT Id, Status__c FROM Opportunity WHERE Id =: opp.Id];

        schCallouts = [SELECT Id FROM WS_ScheduledCallout__c WHERE RecordId__c = : rev.Id AND Method__c='BookingPush'];
        System.assertEquals(1, schCallouts.size());

        System.assertEquals('24_v2', rev.LocalBookingId__c);
        //System.assertEquals('Running', opp.Status__c); //TMP
    }

    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;

    static {
        scenarioUsers = new Map<String, Map<String, String>> {
                'ECITAAU_salesRep' => new Map<String, String> {
                        DF_Scenario.CONF_USER_ROLE      => 'ECITAAU',
                        DF_Scenario.CONF_USER_PROFILE   => 'ECITA Automotive Sales Rep', // should be ECGDK Ad Sales Rep but does not exist on JC1 box
                        DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
                }
        };

        scenarios = new List<DF_Scenario> {
                new DF_Scenario('ECITAAU-1', new Map<String, Object> {
                        DF_Scenario.CONF_MEMBER              => 'ECITA',
                        DF_Scenario.CONF_MEMBER_UNIT         => 'AU',
                        DF_Scenario.CONF_USERS               => new List<String> { 'ECITAAU_salesRep' },
                        DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                        DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                        DF_Scenario.CONF_PRICEBOOK           => '2016',
                        DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                                DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
                                DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                        },
                        DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>>{
                                new Map<String, Object>{
                                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1,
                                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject>{
                                                new Product2(
                                                        Name = 'Premium Profile 12 mesi',
                                                        ProductCode = 'KIA',
                                                        LocalProductId__c = '12',
                                                        Billing_Category__c = 'Subscription_MonthlyProRata',
                                                        ScheduleAheadTerm__c = 12,
                                                        ContractPeriodInMonths__c = 12,
                                                        BillingScheme__c = 'Monthly in Arrears'
                                                ),
                                                new PricebookEntry(
                                                        PriceCalculator__c = 'UnlimitedFixed',
                                                        Tiered_OffsetPrice__c = 0.00,
                                                        Tiered_AdditionalPrice__c = 0.00,
                                                        Tiered_TierCorrection__c = 0.00,
                                                        ListOrder__c = 1,
                                                        Fixed_PricePerMonth__c = 49.17,
                                                        Tiered_FinalAdjustment__c = 0.00,
                                                        UnitPrice = 1.00,
                                                        UseStandardPrice = false,
                                                        IsActive = true
                                                )
                                        }
                                }
                        }
                }) //,

        };
    }
}