@isTest
public class TST_Community {
    
     public static DF factory;

    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;
    
    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'EBAYKRE_Rep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'EBAYKAD',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
            
        };

        scenarios = new List<DF_Scenario> {
            new DF_Scenario('EBAYKRE-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'EBAYK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'RE',
                DF_Scenario.CONF_USERS               => new List<String> { 'EBAYKRE_Rep' },
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => 'EBAYKRE_2015',
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>> {
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
                            new Product2(
                                Name = 'Paket S (10 Anzeigen pro Monat)',
                                ProductCode='KA_RE', 
                                IsActive=true, 
                                CurrencyIsoCode='USD', 
                                Product_Type__c='KA-RealEstate', 
                                Billing_Category__c='Subscription_MonthlyProRata', 
                                CommittedPeriodInMonths__c=6, 
                                ContractPeriodInMonths__c=12, 
                                DefaultLineDescription__c='{{Indirect_Prefix__c}} {{ProductName__c}}', 
                                PriceModelPriceCorrection__c=0.00, 
                                AutoExtend__c=true, 
                                ScheduleAheadTerm__c=12
                            ),
                            new PricebookEntry(
                                CurrencyIsoCode='EUR',
                                UnitPrice=99.00, 
                                IsActive=true, 
                                UseStandardPrice=false,  
                                Fixed_PricePerMonth__c=99.00,
                                DefaultAdjustmentFixed__c=-50.00, 
                                DefaultAdjustmentPercentage__c=0,
                                PriceCalculator__c='UnlimitedFixed'
                            )
                        }
                    },
                    
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
                            new Product2(
                                Name = 'Paket M (25 Anzeigen pro Monat)',
                                ProductCode='KA_RE', 
                                IsActive=true, 
                                CurrencyIsoCode='USD', 
                                Product_Type__c='KA-RealEstate', 
                                Billing_Category__c='Subscription_MonthlyProRata', 
                                CommittedPeriodInMonths__c=6, 
                                ContractPeriodInMonths__c=12, 
                                DefaultLineDescription__c='{{Indirect_Prefix__c}} {{ProductName__c}}', 
                                PriceModelPriceCorrection__c=0.00, 
                                AutoExtend__c=true, 
                                ScheduleAheadTerm__c=12
                            ),
                            new PricebookEntry(
                                CurrencyIsoCode='EUR',
                                UnitPrice=199.00, 
                                IsActive=true, 
                                UseStandardPrice=false,  
                                Fixed_PricePerMonth__c=199.00,
                                DefaultAdjustmentFixed__c=-100.00, 
                                DefaultAdjustmentPercentage__c=0,
                                PriceCalculator__c='UnlimitedFixed'
                            )
                        }
                    },
                    
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
                            new Product2(
                                Name = 'Paket XL (unbegrenzte Anzeigenzahl)',
                                ProductCode='KA_RE', 
                                IsActive=true, 
                                CurrencyIsoCode='USD', 
                                Product_Type__c='KA-RealEstate', 
                                Billing_Category__c='Subscription_MonthlyProRata', 
                                CommittedPeriodInMonths__c=6, 
                                ContractPeriodInMonths__c=12, 
                                DefaultLineDescription__c='{{Indirect_Prefix__c}} {{ProductName__c}}', 
                                PriceModelPriceCorrection__c=0.00, 
                                AutoExtend__c=true, 
                                ScheduleAheadTerm__c=12
                            ),
                            new PricebookEntry(
                                CurrencyIsoCode='EUR',
                                UnitPrice=299.00, 
                                IsActive=true, 
                                UseStandardPrice=false,  
                                Fixed_PricePerMonth__c=299.00,
                                DefaultAdjustmentFixed__c=-0, 
                                DefaultAdjustmentPercentage__c=0,
                                PriceCalculator__c='UnlimitedFixed'
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
    

    @testSetup static void setup() { 
        UTIL.isRunningTestSetup = true;
        //TST_DataFactory.createTestSet();
        
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();

        
        CommunityConfiguration__c CC = new CommunityConfiguration__c(
            HomePage__c='c_EBAYKRE_Order', 
            MemberUnit__c='TTCLGAU', 
            CaseOrigin__c='EBAYKRE: Self-Service Portal', 
            Template__c='c_EBAYKRE_Template', 
            Name='eBay_kleinanzeigen', 
            CaseReason__c='Order', 
            OrderProcessor__c='c_SimpleOrderProcessor', 
            CasePriority__c='HIGH', 
            CaseSubject__c='Order:',
            OrderEarliestStartDate__c=Date.newInstance(2016,2,1),
            OrderOpportunityName__c='Portal Launch 2016: {accountName}'
        );
        insert CC;
        
        List<MailTrigger__c> mt = new List<MailTrigger__c>();
        
        mt.add(new MailTrigger__c(
            Name='EBAYKRE Booking from Signed to Running',
            Object__c='Rev__c',
            OldValue__c='2',
            NewValue__c='3',
            Field__c='NumStatus__c',
            ConditionValue__c='EBAYKRE',
            PreventDuplicate__c=true,
            EmailTemplate__c='EBAYKRE_Activation_NEW',
            ConditionField__c='MemberUnitId__c',
            ContactIdField__c='PrimaryContactID__c',
            FromAddress__c='thomas.ward@ebay.com'
        ));
        
        mt.add(new MailTrigger__c(
            Name='EBAYKRE Booking from Signed to Sched',
            Object__c='Rev__c',
            OldValue__c='2',
            NewValue__c='4',
            Field__c='NumStatus__c',
            ConditionValue__c='EBAYKRE',
            PreventDuplicate__c=true,
            EmailTemplate__c='EBAYKRE_Activation_NEW',
            ConditionField__c='MemberUnitId__c',
            ContactIdField__c='PrimaryContactID__c',
            FromAddress__c='thomas.ward@ebay.com'
        ));
        
        mt.add(new MailTrigger__c(
            Name='EBAYKRE FTP Credentials',
            Object__c='Account',
            OldValue__c='false',
            NewValue__c='true',
            Field__c='MandatoryDetailsFilled__c',
            ConditionValue__c='EBAYK',
            PreventDuplicate__c=true,
            EmailTemplate__c='EBAYKRE_FTP_Information',
            ConditionField__c='MemberId__c',
            ContactIdField__c='Portal_User__c',
            FromAddress__c='thomas.ward@ebay.com'
        ));
        
        insert mt;
       
        
        DF_Scenario.Result Result = DF.queryResults(scenarios, scenarioUsers,  new Set<String>{'products','pbes'}) ;
        Product2 p1 = Result.products.values().get(0);
        Product2 p2 = Result.products.values().get(1);
        Product2 p3 = Result.products.values().get(2);
        PricebookEntry pbe = Result.pbes.values().get(0);
         
        PortalProductGrouping__c ppg = new PortalProductGrouping__c(
            Name='eBay Kleinanzeigen Real Estate', 
            CurrencyIsoCode='EUR',
            PortalName__c='eBay_kleinanzeigen', 
            ShowGroupingName__c=false
        );
        insert ppg;
        
        List<PortalProduct__c> portalProducts = new List<PortalProduct__c>();
        
        portalProducts.add(new PortalProduct__c(
            Name='Paket S', 
            CurrencyIsoCode='EUR', 
            Details__c='Sie können mit Ihrer Makler-Software bis zu 10 Anzeigen pro Monat zu eBay Kleinanzeigen exportieren. Diese können jederzeit durch Sie aktualisiert werden.', 
            Headline__c='Bis zu 15 Anzeigen pro Monat', 
            IsFromPrice__c=false, 
            OrderMethod__c='Self-Service', 
            PortalProductGrouping__c=ppg.Id, 
            PriceBook__c= pbe.Pricebook2Id, //pb.Id, 
            Product__c=p1.Id, 
            ShortName__c='S',
            SortOrder__c=1
        ));
        
        portalProducts.add(new PortalProduct__c(
            Name='Paket M', 
            CurrencyIsoCode='EUR', 
            Details__c='Sie können mit Ihrer Makler-Software bis zu 25 Anzeigen pro Monat zu eBay Kleinanzeigen exportieren. Diese können jederzeit durch Sie aktualisiert werden.', 
            Headline__c='Bis zu 25 Anzeigen pro Monat', 
            IsFromPrice__c=false, 
            OrderMethod__c='Self-Service', 
            PortalProductGrouping__c=ppg.Id, 
            PriceBook__c= pbe.Pricebook2Id, //pb.Id,  
            Product__c=p2.Id, 
            ShortName__c='M',
            SortOrder__c=2
        )); 
        
        portalProducts.add(new PortalProduct__c(
            Name='Paket XL', 
            CurrencyIsoCode='EUR',
            Details__c='Mit diesem Paket können Sie eine unbegrenzte Anzahl an Objekten zu eBay Kleinanzeigen exportieren. Sie haben die Möglichkeit, Partner einzuladen, das Paket mit zu nutzen. Für die Buchung dieses Paketes kontaktieren wir Sie.',
            Headline__c='Ohne Begrenzung. Sie können weitere Büros zur Nutzung einladen.', 
            IsFromPrice__c=true,
            OrderMethod__c='Case',
            PortalProductGrouping__c=ppg.Id, 
            PriceBook__c= pbe.Pricebook2Id, //pb.Id, 
            Product__c=p3.Id, 
            ShortName__c='XL',
            SortOrder__c=3
        ));
        
        insert portalProducts;
        
        UTIL_CustomJob.createMissingCustomJobs();
        
        UTIL.isRunningTestSetup = false;
    }
    
    @isTest static void testCommunity(){
        //TST_DataFactory fac = TST_DataFactory.getInstance();
        DF_Scenario.Result Result = DF.queryResults(scenarios, scenarioUsers,  new Set<String>{'accounts','contacts', 'users'}) ;
        Account acc = result.accounts.values().get(0);
        Contact con = Result.contacts.values().get(0);
        
        PortalOrder__c po = new PortalOrder__c();
        po.Contact__c = con.id;
        po.PortalName__c = 'eBay_kleinanzeigen';
        po.Status__c = 'Ready to process';
        po.Account__c = acc.id;
        insert po;
        
        Attachment att = new Attachment();
        att.Name = 'Test Att';
        att.ParentId = po.id;
        att.body = Blob.valueOf('test body');
        insert att;
        
        String strBody = '[{"Account__c": "' + acc.Id + '" }]';
        MockHttpCalloutResponse mock = new MockHttpCalloutResponse('application/json', 200, strBody); 
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        // Need to insert a community user
        List<Profile> allProfiles = GW_User.userProfileMap.values();
        Profile communityProfile = null;
        for (Profile p : allProfiles) {
            if (p.Name == 'Customer Community User') {
                communityProfile = p;
                break;
            }
        }
        
        acc.Portal_User__c = con.id;
        acc.Finance_Contact__c = con.id;
        update acc;
        
        User cu = new User(
            Username = 'ctest_' + con.Email,
            LanguageLocaleKey = 'en_US',
            LastName = con.LastName,
            LocaleSidKey = 'en_US',
            ProfileId = communityProfile.Id,
            TimeZoneSidKey = 'Europe/Amsterdam',
            UserPermissionsMarketingUser = false,
            UserPermissionsOfflineUser = false,
            Alias = 'ctest',
            DefaultGroupNotificationFrequency = 'N',
            DigestFrequency = 'N',
            Email = con.Email,
            EmailEncodingKey = 'UTF-8',
            FederationIdentifier = con.Id,
            ContactId = con.Id
        );
        
        PortalProduct__c prodM = null;
        PortalProduct__c prodXL = null;
        
        List<PortalProduct__c> portalProducts = (List<PortalProduct__c>) GW_sObject.queryRecords('PortalProduct__c', '');
        for (PortalProduct__c pp : portalProducts) {
            if (pp.Name.contains('Paket M')) {
                prodM = pp;
            }
            if (pp.Name.contains('Paket XL')) {
                prodXL = pp;
            }
        }
         
        
        System.runAs(cu) {
            PageReference pageRef = Page.c_EBAYKRE_Order;
            Test.setCurrentPage(pageRef);
            
            c_BaseOrderController boc = new c_BaseOrderController();
            
            String inputJson = '{"product_id":"'+prodM.Id+'","payment_method":"directdebit","bankaccount_name":"aaaa","bankaccount_iban":"DE16300600100000135917","account_name":"JanTest Account 1203","contact_firstname":"xxx","contact_lastname":"Test Contact 1203","billing_street":"Street","billing_postalcode":"12345","billing_city":"Unknown","account_vatnr":"DE123456789","billing_country":"DE"}';
            c_Common.ResponseObject resultObj = c_BaseOrderController.save(inputJson, null);
            
            String inputJsonError = '{"product_id":"'+prodM.Id+'","payment_method":"directdebit","bankaccount_name":"aa","bankaccount_iban":"DE129391239","account_name":"JanTest Account 1203","contact_firstname":"xxx","contact_lastname":"Test Contact 1203","billing_street":"Street","billing_postalcode":"12345","billing_city":"Unknown","account_vatnr":"DE12345","billing_country":"DE"}';
            c_BaseOrderController.save(inputJsonError, null);
            
            String inputJsonCase = '{"product_id":"'+prodXL.Id+'","payment_method":"invoice","bankaccount_name":"","bankaccount_iban":"","account_name":"JanTest Account 1203","contact_firstname":"xxx","contact_lastname":"Test Contact 1203","billing_street":"Street","billing_postalcode":"12345","billing_city":"Unknown","account_vatnr":"DE123456789","billing_country":"DE"}';
            c_BaseOrderController.submitCase(inputJsonCase);       
                                
        }
        
        /*
        c_Common.ResponseObject mockRes = new c_Common.ResponseObject();
        mockRes.success = true;
        mockRes.responseMap = new Map<String,String>{'Account__c' => acc.id};
        Test.setMock(c_Common.ResponseObject.class, mockRes);
        */
        
        System.runAs(Result.users.get('admin')) {
            //UTIL_CustomJob.startCustomJob('BAT_PortalOrders');
            BAT_PortalOrders testBatPortalOrd = new BAT_PortalOrders(new list<PortalOrder__c>{po});
        }
        Test.stopTest();
        
        list<PortalOrder__c> lstPO = GW_sObject.queryRecords('PortalOrder__c','PortalName__c = \'eBay_kleinanzeigen\'');
        system.assertEquals(lstPO.get(0).Status__c, 'Ready to process');
        
    }
   
   //Improved Converage only
   @isTest static void test_ImproveCoverage(){
       
        DF_Scenario.Result Result = DF.queryResults(scenarios, scenarioUsers,  new Set<String>{'accounts','contacts', 'users'}) ;
        Account acc = result.accounts.values().get(0);
        Contact con = Result.contacts.values().get(0);
        
        List<Profile> allProfiles = GW_User.userProfileMap.values();
        Profile communityProfile = null;
        for (Profile p : allProfiles) {
            if (p.Name == 'Customer Community User') {
                communityProfile = p;
                break;
            }
        }
        
        User cu = new User(
            Username = 'ctest_' + con.Email,
            LanguageLocaleKey = 'en_US',
            LastName = con.LastName,
            LocaleSidKey = 'en_US',
            ProfileId = communityProfile.Id,
            TimeZoneSidKey = 'Europe/Amsterdam',
            UserPermissionsMarketingUser = false,
            UserPermissionsOfflineUser = false,
            Alias = 'ctest',
            DefaultGroupNotificationFrequency = 'N',
            DigestFrequency = 'N',
            Email = con.Email, 
            EmailEncodingKey = 'UTF-8',
            FederationIdentifier = con.Id,
            ContactId = con.Id
        );

        test.startTest();     
        System.runAs(cu) { 
            String inputJsonError = '{"product_id":"aoooovdvxx","payment_method":"directdebit","bankaccount_name":"aa","bankaccount_iban":"DE129391239","account_name":"JanTest Account 1203","contact_firstname":"xxx","contact_lastname":"Test Contact 1203","billing_street":"Street","billing_postalcode":"12345","billing_city":"Unknown","account_vatnr":"DE12345","billing_country":"DE"}';
            c_BaseOrderController.validate('"product_id":"xxx"', null);
            c_BaseOrderController.validate(inputJsonError, null);            
            c_BaseOrderController contrl = new c_BaseOrderController();
            String portalProductMap = contrl.portalProductMap;
            String pricingMap       = contrl.pricingMap;
            String currencyMapJSON  = contrl.currencyMapJSON;
            Map<String,String> currencyMap = contrl.currencyMap;
            try{
                contrl.debug(inputJsonError);
            }catch(exception e){}
            try{
                contrl.debugJSON(inputJsonError);
            }catch(exception e){}
       test.stopTest(); 
   }
   }  
}