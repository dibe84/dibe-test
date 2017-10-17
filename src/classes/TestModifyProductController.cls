/**
 * To test the logic in ModifyProductController2
 * @author : Sreymol
 * @createddate : 01-Apr-2014
 *
 * @Revision
 *
 * Date			Author				Description
 * 24/12/2015	Sochanra			#8682 In the class 'modifyproductcontroller2' all code which is used for the exclusive placement functionality should be put in comment.
 */

@isTest
class TestModifyProductController {
    private static User userAdmin;
    private static Product2 adSpec;
    private static Opportunity mediaCampaign;
    private static OpportunityLineItem camItem1;
    private static OpportunityLineItem camItem2;
    private static OpportunityLineItem camItem3;
	private static Id standardPbId;
    private static DART_KeyValue_2__c keyval;
    private static List<Targeting__c> listTars;
    private static List<Rate_Card__c> rateCards = new List<Rate_Card__c>();
    private static PricebookEntry pbeMb;
    private static User currentUser = [ select Id from User where Id = :UserInfo.getUserId() ];

    /**
     * To create data for testing
     */
    static void setupdaData() {
		createTestUser();
        System.runAs(currentUser){

        	createMembers(); //create Member and MemberUnit

	        Account acc = new Account();
	        acc.Name = 'Test Account Quote';
	        acc.BillingStreet = '12345';
	        acc.BillingCity = 'Test';
	        acc.Phone = '+12456796';
	        acc.BillingCountryCode = 'GB';
	        acc.BillingPostalCode = '134697';
	        acc.OwnerId=userAdmin.id;
			insert acc;

	        Contact con = new Contact();
	        con.LastName = 'TestContact';
	        con.AccountId = acc.Id;
	        con.Fax = '1234567';
	        con.Email = 'Test@test.com';
	        con.MobilePhone = '+134697589';
	        insert con;
	    //MS 01-09-2014: block this line for deploying to Gumtree Au
	        //acc.Primary_Contact__c = con.id;
	        //acc.Finance_Contact__c = con.id;
	        //update acc;

	        standardPbId = Test.getStandardPricebookId();

	        Placement__c placement = new Placement__c(Name = 'TestPlacements');
	        insert placement;

	        Advertising_Medium__c adType = new Advertising_Medium__c(Name = 'AdType', related_Mediums__c = 'Skyskraper');
	        insert adType;

			//Bunhor @24-Feb-15: inserting Content__c
			Content__c predifinedContent = new Content__c(Active__c=true, Name='4000',DartName__c='DartName',Type__c='Dart - Zone');
			insert predifinedContent;

	        adSpec = new Product2(PredifinedAdunit__c=predifinedContent.id, Name = 'Test Ad Spec', placement__c = placement.id, AdServer_Keywords_Key_Values__c = 'BBB', Billing_Category__c = 'CPM',Advertising_Medium__c = adType.id, Fixed_price__c = true,IsActive = true );
	        Product2 product = new Product2(PredifinedAdunit__c=predifinedContent.id, Name = 'Test Ad Spec', placement__c = placement.id, AdServer_Keywords_Key_Values__c = 'BBB', Billing_Category__c = 'CPM',Advertising_Medium__c = adType.id, Fixed_price__c = true,IsActive = true );
	        insert new List<Product2>{product, adSpec};

	        MemberUnit__c mu = [SELECT Id FROM MemberUnit__c WHERE Name = 'Test Adsales' AND LineOfBusiness__c = 'AD' LIMIT 1];
	        mediaCampaign = new Opportunity( MemberUnit__c=mu.Id, Billing_Account__c = acc.id, Pricebook2Id = standardPbId, Name = 'Test Media campaign Test', AccountId = acc.id, Description = 'Test', StageName = 'Test', Probability = 50, CloseDate = system.today() );
	        system.runAs(userAdmin){
	        	insert mediaCampaign;
	        }

	        PricebookEntry pbe1 = new PricebookEntry(UseStandardPrice = false, Product2Id = adSpec.Id, Pricebook2Id = standardPbId, UnitPrice = 1.00, IsActive = true, CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY);
	        pbeMb = new PricebookEntry(UseStandardPrice = false, Product2Id = product.Id, Pricebook2Id = standardPbId, UnitPrice = 8.00, IsActive = true, CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY);
	        List < PricebookEntry > lstPric = new List < PricebookEntry > { pbe1, pbeMb };
	        insert lstPric;

	        listTars = new List<Targeting__c>();
	        for (Integer t = 1; t <= 3; t++) listTars.add(new Targeting__c(TempBinder__c = false));
	        insert listTars;

	        Targeting__c targetdel = new Targeting__c(TempBinder__c = false);
	        insert targetdel;

	        rateCards.add(new Rate_Card__c(Quantity__c = '100 to 200', Sales_Price__c = 20000, Product__c = adSpec.Id, Length__c = '12'));
	        insert rateCards;

	        Content__c cont = new Content__c(Name = '787979');
	        insert cont;

	        Available_Site__c avai = new Available_Site__c(Product__c = adSpec.Id, available_Site__c = cont.Id);
	        Available_Site__c avai2 = new Available_Site__c(Product__c = adSpec.Id, available_Site__c = cont.Id);
	        insert new List < Available_Site__c > {
	            avai, avai2
	        };

	        camItem1 = new OpportunityLineItem(OpportunityId = mediaCampaign.id, UnitPrice = 523, Quantity = 3, PricebookEntryId = pbe1.Id, Billing_category__c = 'CPM', UniqueLineDescription__c = 'DesccamItem1',
	                                                Description = 'Test1', from_Date__c = Date.newInstance(2014, 04, 05), until_Date__c = System.today() + 30, Targeting__c = listTars[0].Id);

	        camItem2 = new OpportunityLineItem(OpportunityId = mediaCampaign.id, UnitPrice = 523, Quantity = 3, PricebookEntryId = pbe1.Id, Billing_category__c = 'CPM', UniqueLineDescription__c = 'DesccamItem2',
	                                            Description = 'Test2', from_Date__c = Date.newInstance(2014, 04, 05), until_Date__c = Date.newInstance(2014, 05, 05), Targeting__c = listTars[1].Id);//until_Date__c = Date.newInstance(2050, 3, 29)

	        camItem3 = new OpportunityLineItem(OpportunityId = mediaCampaign.id, UnitPrice = 523, Quantity = 3, PricebookEntryId = pbeMb.Id, Billing_category__c = 'CPM', UniqueLineDescription__c = 'DesccamItem3',
	                                            Description = 'Test3', from_Date__c = Date.newInstance(2014, 04, 05), until_Date__c = Date.newInstance(2015, 3, 29), Targeting__c = listTars[2].Id);//until_Date__c = Date.newInstance(2050, 3, 29)

	        insert new List < OpportunityLineItem > {camItem1, camItem2, camItem3};

	        City__c city = new City__c(Name = 'AAA');
	        insert city;

	        List<TargetingCityAssociation__c> ltca = new List<TargetingCityAssociation__c>();
	        for (Integer c = 0; c < 3; c++){
	            ltca.add(new TargetingCityAssociation__c(City__c = city.Id, Targeting__c = listTars[c].Id));
	        }
	        insert ltca;

	        Country__c coun = new Country__c(Name = 'CCCC');
	        insert coun;

	        List<TargetingCountryAssociation__c> lTarcountAss  = new List<TargetingCountryAssociation__c>();
	        for (Integer country = 0; country < 3; country++){
	            lTarcountAss.add(new TargetingCountryAssociation__c(Country__c = coun.Id, Targeting__c = listTars[country].Id));
	        }
	        insert lTarcountAss;

	        AreaCode__c acode = new AreaCode__c(Name = 'A0009');
	        insert acode;

	        List<TargetingAreaCodeAssociation__c> tacodes = new List<TargetingAreaCodeAssociation__c>();
	        for (Integer ac = 0; ac < 3; ac++){
	            tacodes.add(new TargetingAreaCodeAssociation__c(AreaCode__c = acode.Id, Targeting__c = listTars[ac].Id));
	        }
	        insert tacodes;

	        PlacementTargetingDefinition__c ptd = new PlacementTargetingDefinition__c(Name = 'PTD');
	        insert ptd;

	        List<PlacementTargetingAssociation__c> lptas = new List<PlacementTargetingAssociation__c>();
	        for (Integer p = 0; p < 3; p++) lptas.add(new PlacementTargetingAssociation__c(PlacementTargeting__c = ptd.Id, Targeting__c = listTars[p].Id));
	        insert lptas;

	        List<TargetingContentAssociation__c> lcons = new List<TargetingContentAssociation__c>();
	        for (Integer content = 0; content < 3; content++) lcons.add(new TargetingContentAssociation__c(TargetingContent__c = cont.Id, Targeting__c = listTars[content].Id));
	        insert lcons;

	        keyval = new DART_KeyValue_2__c(Name = 'Key value');
	        insert keyval;

	        List<TargetingKeyValueAssociation__c> kvs = new List<TargetingKeyValueAssociation__c>();
	        for (Integer kv = 0; kv < 3; kv++) kvs.add( new TargetingKeyValueAssociation__c(Operator__c = 'AND', DART_KeyValue__c = keyval.Id, Targeting__c = listTars[kv].Id));
	        insert kvs;

	        Region__c rg = new  Region__c(Name = 'R1', Dart_ID__c = 9999);
	        insert rg;

	        List<TargetingRegionAssociation__c> regs = new List<TargetingRegionAssociation__c>();
	        for (Integer r = 0; r < 3; r++) regs.add(new TargetingRegionAssociation__c(Targeting__c = listTars[r].Id, Region__c = rg.Id));
	        insert regs;

	        
        }
    }

    /**
     * insert member and member unit for testing
     */
    private static void createMembers() {

        Id RecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        Account memberAccount = new Account(RecordTypeId=RecId, name='MemberAccount', BillingCountry='Netherlands', ShippingCountry='Italy');
        insert memberAccount;
        Member__c member = GW_Member.insertSObject('Test Member', 'TTCLG',memberAccount);
        List<MemberUnit__c> memberUnits = new List<MemberUnit__c>();
        memberUnits.add(GW_MemberUnit.insertObject(member.Id, 'Test Adsales', 'AD'));
        memberUnits.add(GW_MemberUnit.insertObject(member.Id, 'Test Automotive', 'AU'));
        member.DefaultMemberUnit__c = memberUnits[1].Id;
        update member;
    }

    /**
     * insert user for testing
     */
    public static void createTestUser()
    {
    	System.runAs ( currentUser ) {
	        Profile p=[Select Id From Profile Where Name='System Administrator'  or Name='Systemadministrator' Limit 1];
	        userAdmin = GW_User.createTestUser(p);
	        userAdmin.Username='testUser1@boco.com';
	        userAdmin.LastName='testLastName1';
	        userAdmin.Email='testEmail1@boco.com';
	        userAdmin.Alias='test1';
	        userAdmin.TimeZoneSidKey='Pacific/kiritimati';
	        userAdmin.LocaleSidKey='ar';
	        userAdmin.EmailEncodingKey='UTF-8';
	        userAdmin.ProfileId=p.Id;
	        userAdmin.LanguageLocaleKey='en_US';
	        insert userAdmin;
    	}
    }

    @isTest static void testinitList() {
        setupdaData();
        System.runAs ( currentUser ) {
	        Pagereference pg = Page.ModifyProduct3;
	        ID sID = mediaCampaign.id;
	        Media_Basket__c mbnew = new Media_Basket__c(name='test media', UserId__c=System.Userinfo.getUserId(), AdPriceIdText__c = pbeMb.Id, OpportunityId__c = mediaCampaign.Id);
	        insert mbnew;

	        Test.setCurrentPageReference(pg);
	        ApexPages.StandardController setCon = new ApexPages.StandardController(mediaCampaign);
	        pg.getParameters().put('mcId', mediaCampaign.Id);
	        pg.getParameters().put('retURL', '/' + mediaCampaign.id);
	        pg.getParameters().put('mcPBId', standardPbId);
	        pg.getParameters().put('isClone', 'isCloneButton');
	        ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);
	        ModifyProductController2.KeyValueDTO dtokv = new ModifyProductController2.KeyValueDTO(keyval.Id, 'KV');
	        modifyProduct.oppProb = 26;
	        modifyProduct.lstRecords.get(0).item.from_Date__c = system.today() + 90;
	        modifyProduct.lstRecords.get(0).item.from_Date__c = system.today() + 30;
	        ///modifyProduct.lstRecords.get(0).item.Pricebookentry.Product2.RecordType.Name = 'Autos';
	        modifyProduct.lstRecords.get(0).item.Billing_category__c = 'CPD';
	        modifyProduct.lstRecords.get(0).item.Quantity = 2;
	        modifyProduct.lstRecords.get(0).item.UnitPrice = 3.99;
	        modifyProduct.lstRecords.get(0).isFixedSite = true;
	        modifyProduct.lstRecords.get(0).item.Placement_Targeting__c = 'test';
	        modifyProduct.lstRecords.get(0).item.Rich_Line_Description__c = 'test';
	        modifyProduct.lstRecords.get(0).availableSite = 'test';
	        Test.startTest();
	        	ModifyProductController2.isAdUnitPredifined(camItem1, new Product2());
	        	modifyProduct.doCopyForNewTargeting();
	            modifyProduct.saveRecords();
	            modifyProduct.lstRecords.clear();
	            modifyProduct.saveRecords();
	        Test.stopTest();
        }
    }
    // JvdH: split into TestSaving1 and TestSaving2 to avoid SOQL limit error
    @isTest static void TestSaving1() {
     	createTestUser();
     	System.runAs ( currentUser ) {

     		createMembers();

	        Site__c site = new Site__c(Country__c = 'DE', Name = 'Testsite');
	        insert site;

	        Placement__c pm = new Placement__c(Name = 'Testplacement');
	        insert pm;

	        Advertising_Medium__c am = new Advertising_Medium__c(
	            Name = 'Skyskraper',
	            related_Mediums__c = 'Skyskraper',
	            Site__c = site.id
	        );
	        insert am;
	        RecordType rec = [select id from RecordType where Name = 'DART6'
	                and SobjectType = 'Product2'
	                limit 1
	            ];
	        Product2 prod1 = new Product2(
	            Name = 'ApexTestProd',
	            IsActive = true,
	            Site__c = site.id,
	            Placement__c = pm.id,
	            Advertising_Medium__c = am.id,
	            RecordTypeId = rec.Id);

	        insert prod1;

	    	//Account acc = GW_Account.insertSObject();
	    	Account acc = new Account();
	        acc.Name = 'Test Account Quote1';
	        acc.BillingStreet = '123245';
	        acc.BillingCity = 'Test1';
	        acc.Phone = '+124567296';
	        acc.BillingCountryCode = 'GB';
	        acc.BillingPostalCode = '1346972';
	        acc.OwnerId=userAdmin.id;
			insert acc;

	    	standardPbId = Test.getStandardPricebookId();

	    	MemberUnit__c mu = [SELECT Id FROM MemberUnit__c WHERE Name = 'Test Adsales' AND LineOfBusiness__c = 'AD' LIMIT 1];
	        Opportunity opp1 = new Opportunity(
	            Name = 'Test Opp1',
	            StageName = 'gebucht',
	            CloseDate = System.today(),
	            Probability = 50,
	            Billing_Account__c = acc.id,
	            AccountId = acc.id,
	            Pricebook2Id = standardPbId,
                CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY,
                MemberUnit__c = mu.Id
	        );

	        system.runAs(userAdmin){
	        	insert opp1;
	        }

	        PricebookEntry pbe1std = new PricebookEntry(
	            Pricebook2Id = standardPbId,
	            Product2Id = prod1.Id,
	            UnitPrice = 1.00,
	            IsActive = true,
                CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY
            );
	        insert pbe1std;

	        OpportunityLineItem oli1 = new OpportunityLineItem(
	            OpportunityId = opp1.Id,
	            Quantity = 100,
	            TotalPrice = 100.0,
	            ///from_Date__c = Date.newInstance(2015, 2, 20),
	            from_Date__c = System.today() + 1,
                until_Date__c = System.today() + 30,
	            PricebookEntryId = pbe1std.Id,
	            AdOperatingSystems__c = 'Windows XP',
	            Billing_Category__c = 'CPM',
	            UniqueLineDescription__c = 'Descoli1',
	            Description = 'Test OLI1'
	        );
	        OpportunityLineItem oli2 = new OpportunityLineItem(
	            OpportunityId = opp1.Id,
	            Quantity = 100,
	            TotalPrice = 100.0,
	            ///from_Date__c = Date.newInstance(2015, 2, 20),
                from_Date__c = System.today() + 1,
	            until_Date__c = System.today() + 30,
	            PricebookEntryId = pbe1std.Id,
	            AdOperatingSystems__c = 'Windows XP',
	            Billing_Category__c = 'CPM',
	            UniqueLineDescription__c = 'Descoli2',
	            Description = 'Test OLI2'
	        );
	        insert new List < OpportunityLineItem > { oli1, oli2 };

	        Pagereference pg = Page.ModifyProduct3;

	        Test.setCurrentPageReference(pg);
	        pg.getParameters().put('id', opp1.Id);
	        pg.getParameters().put('modolis', oli1.Id);
	        pg.getParameters().put('retURL', '/' + opp1.Id);
	        pg.getParameters().put('mcPBId', standardPbId);

	        Test.StartTest();
		        ApexPages.StandardController setCon = new ApexPages.StandardController(opp1);
		        ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);

		        //save in case from date equals to null
		        prod1.Product_SubType__c = '';
		        update prod1;
		        modifyProduct.lstRecords.get(0).item.from_Date__c = null;
		        modifyProduct.saveRecords();

		        //save in case until date equals to null
		        modifyProduct = new ModifyProductController2(setCon);
		        modifyProduct.lstRecords.get(0).item.until_Date__c = null;
		        modifyProduct.saveRecords();

		        //save in case not force save from_date__c
		        modifyProduct.forceDateSave = false;
		        modifyProduct.lstRecords.get(0).item.until_Date__c = Date.today().addMonths(3);
		        modifyProduct.saveRecords();

		        //until date < from date
		        modifyProduct.lstRecords.get(0).item.until_Date__c = Date.today().addMonths(-3);
		        modifyProduct.lstRecords.get(0).item.from_Date__c = Date.today().addMonths(3);
		        modifyProduct.saveRecords();

		        //Billing_category__c = null
		        modifyProduct.lstRecords.get(0).item.until_Date__c = Date.today().addMonths(3);
		        modifyProduct.lstRecords.get(0).item.from_Date__c = Date.today().addMonths(-3);
		        modifyProduct.lstRecords.get(0).item.Billing_category__c = null;
		        system.assertEquals(null , modifyProduct.lstRecords.get(0).item.Billing_category__c);
		        modifyProduct.saveRecords();

		        //Quantity = 0
		        modifyProduct.lstRecords.get(0).item.Billing_category__c = 'CPM';
		        modifyProduct.lstRecords.get(0).item.Quantity = 0;
		        modifyProduct.saveRecords();

		        //UnitPrice = null
		        modifyProduct.lstRecords.get(0).item.Quantity = 100;
		        modifyProduct.lstRecords.get(0).item.UnitPrice = null;
		        modifyProduct.saveRecords();

	        Test.stopTest();
     	}
    }

    @isTest static void TestSaving2() {
     	createTestUser();
     	System.runAs ( currentUser ) {

     		createMembers();

	        Site__c site = new Site__c(Country__c = 'DE', Name = 'Testsite');
	        insert site;

	        Placement__c pm = new Placement__c(Name = 'Testplacement');
	        insert pm;

	        Advertising_Medium__c am = new Advertising_Medium__c(
	            Name = 'Skyskraper',
	            related_Mediums__c = 'Skyskraper',
	            Site__c = site.id
	        );
	        insert am;
	        RecordType rec = [select id from RecordType where Name = 'DART6'
	                and SobjectType = 'Product2'
	                limit 1
	            ];
	        Product2 prod1 = new Product2(
	            Name = 'ApexTestProd',
	            IsActive = true,
	            Site__c = site.id,
	            Placement__c = pm.id,
	            Advertising_Medium__c = am.id,
	            RecordTypeId = rec.Id);

	        insert prod1;

	    	//Account acc = GW_Account.insertSObject();
	    	Account acc = new Account();
	        acc.Name = 'Test Account Quote1';
	        acc.BillingStreet = '123245';
	        acc.BillingCity = 'Test1';
	        acc.Phone = '+124567296';
	        acc.BillingCountryCode = 'GB';
	        acc.BillingPostalCode = '1346972';
	        acc.OwnerId=userAdmin.id;
			insert acc;

	    	standardPbId = Test.getStandardPricebookId();

	    	MemberUnit__c mu = [SELECT Id FROM MemberUnit__c WHERE Name = 'Test Adsales' AND LineOfBusiness__c = 'AD' LIMIT 1];
	        Opportunity opp1 = new Opportunity(
	            Name = 'Test Opp1',
	            StageName = 'gebucht',
	            CloseDate = System.today(),
	            Probability = 50,
	            Billing_Account__c = acc.id,
	            AccountId = acc.id,
	            Pricebook2Id = standardPbId,
                CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY,
                MemberUnit__c = mu.Id
	        );

	        system.runAs(userAdmin){
	        	insert opp1;
	        }

	        PricebookEntry pbe1std = new PricebookEntry(
	            Pricebook2Id = standardPbId,
	            Product2Id = prod1.Id,
	            UnitPrice = 1.00,
	            IsActive = true,
                CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY
            );
	        insert pbe1std;

	        OpportunityLineItem oli1 = new OpportunityLineItem(
	            OpportunityId = opp1.Id,
	            Quantity = 100,
	            TotalPrice = 100.0,
	            ///from_Date__c = Date.newInstance(2015, 2, 20),
                from_Date__c = System.today(),
	            until_Date__c = System.today() + 30,
	            PricebookEntryId = pbe1std.Id,
	            AdOperatingSystems__c = 'Windows XP',
	            Billing_Category__c = 'CPM',
	            UniqueLineDescription__c = 'Descoli1',
	            Description = 'Test OLI1'
	        );
	        OpportunityLineItem oli2 = new OpportunityLineItem(
	            OpportunityId = opp1.Id,
	            Quantity = 100,
	            TotalPrice = 100.0,
	            ///from_Date__c = Date.newInstance(2015, 2, 20),
                from_Date__c = System.today(),
	            until_Date__c = System.today() + 30,
	            PricebookEntryId = pbe1std.Id,
	            AdOperatingSystems__c = 'Windows XP',
	            Billing_Category__c = 'CPM',
	            UniqueLineDescription__c = 'Descoli2',
	            Description = 'Test OLI2'
	        );
	        insert new List < OpportunityLineItem > { oli1, oli2 };

	        /*exclusive_Placement__c bp1 = new exclusive_Placement__c(
	            Date__c = System.today(),
	            Opportunity__c = opp1.id,
	            Product__c = prod1.id
	        );
	        insert bp1;*/

	        Pagereference pg = Page.ModifyProduct3;

	        Test.setCurrentPageReference(pg);
	        pg.getParameters().put('id', opp1.Id);
	        pg.getParameters().put('modolis', oli1.Id);
	        pg.getParameters().put('retURL', '/' + opp1.Id);
	        pg.getParameters().put('mcPBId', standardPbId);

	        Test.StartTest();
		        ApexPages.StandardController setCon = new ApexPages.StandardController(opp1);
		        ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);

		        //incase no records to save
		        System.assertEquals(2, modifyProduct.lstRecords.size());
		        modifyProduct.lstRecords.clear();
		        modifyProduct.saveRecords();
		        system.assertEquals(system.Label.No_value_to_insert, modifyProduct.errorMsg);

		        //incase poller mode
		        modifyProduct = new ModifyProductController2(setCon);
		        modifyProduct.isPollerMode = true;
		        modifyProduct.saveRecords();

		        //incase no poller mode and have exclusive_Placement__c
		        modifyProduct = new ModifyProductController2(setCon);
		        modifyProduct.accId = modifyProduct.X_ACCOUNT_ID;
		        modifyProduct.oppProb = 26;
		        modifyProduct.forceDateSave = false;
		        modifyProduct.saveRecords();

		        //incase no exclusive_Placement__c and product subtype is feature
		        ///delete bp1;
		        prod1.Product_SubType__c = 'Features';
		        update prod1;
		        modifyProduct = new ModifyProductController2(setCon);
		        modifyProduct.accId = modifyProduct.X_ACCOUNT_ID;
		        modifyProduct.oppProb = 26;
		        modifyProduct.forceDateSave = false;
		        modifyProduct.saveRecords();

		        // Save in case Rich_Line_Description__c equals to null
		        modifyProduct.lstRecords.get(0).availableSite = 'brantford , bc , bridgewater , bathurst , brandon , belleville , barrie.';
		        modifyProduct.lstRecords.get(0).isFixedSite = false;
		        modifyProduct.lstRecords.get(0).isHasSite= true;
		        modifyProduct.lstRecords.get(0).item.UnitPrice = 0.90;
		        modifyProduct.lstRecords.get(0).item.Rich_Line_Description__c = null;
		        modifyProduct.saveRecords();

		        // Save in case no require any fields
		        modifyProduct = new ModifyProductController2(setCon);
		        modifyProduct.lstRecords.get(0).item.Rich_Line_Description__c = 'Test';
		        modifyProduct.lstRecords.get(0).availableSite = 'brantford , bc , bridgewater , bathurst , brandon , belleville , barrie.';
		        modifyProduct.lstRecords.get(0).isFixedSite = true;
		        modifyProduct.lstRecords.get(0).isHasSite = true;
		        modifyProduct.lstRecords.get(0).item.from_Date__c = System.today();
		        modifyProduct.lstRecords.get(0).item.UnitPrice = 1000;
		        modifyProduct.lstRecords.get(1).item.UnitPrice = 1000;
		        modifyProduct.lstRecords.get(1).item.from_Date__c = System.today();
		        modifyProduct.lstRecords.get(1).item.Rich_Line_Description__c = 'test';
		        modifyProduct.lstRecords.get(1).isFixedSite = true;
		        modifyProduct.lstRecords.get(1).availableSite = 'brantford , bc , bridgewater , bathurst.';
		        modifyProduct.saveRecords();
		        modifyProduct.goPrevious();
		        modifyProduct.copyField();
		        modifyProduct.copyRecords();
	        Test.stopTest();
     	}
    }


	@isTest static void copyFieldFromTopToDown() {
        setupdaData();
        String camtmp = camItem1.id;
        Pagereference pg = Page.ModifyProduct3;
        ID sID = mediaCampaign.id;
        Test.setCurrentPageReference(pg);
        Test.startTest();
        System.runAs(currentUser) {
            ApexPages.StandardController setCon = new ApexPages.StandardController(mediaCampaign);
            ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);

            pg.getParameters().put('id', mediaCampaign.Id);
            pg.getParameters().put('retURL', '/' + mediaCampaign.Id);
            pg.getParameters().put('mcPBId', standardPbId);
            pg.getParameters().put('camItems', camtmp);
            modifyProduct = new ModifyProductController2(setCon);
            modifyProduct.lstRecords.add(new ModifyProductController2.DtoItem(adSpec.Name, camItem1, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 0));
            modifyProduct.lstRecords.add(new ModifyProductController2.DtoItem(adSpec.Name, camItem2, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 1));
            modifyProduct.lstRecords.get(0).position = 0;
            modifyProduct.lstRecords.get(1).position = 1;
            //modifyProduct.selPosition = '0';
            modifyProduct.selPosition = '1';   //@vitou 29-04-2015
            modifyProduct.selColumn = 'AreaCode_Description__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(0).item.Placement_Targeting__c = 'test';
            modifyProduct.selColumn = 'Placement_Targeting__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(0).item.City_Description__c = 'test';
            modifyProduct.selColumn = 'City_Description__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(0).item.Countries_Description__c = 'test';
            modifyProduct.selColumn = 'Countries_Description__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(0).item.FC_Ad_Served_Every__c = 9;
            modifyProduct.selColumn = 'FC_Ad_Served_Every__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(0).item.AdDayofWeek__c = 'Sunday';
            modifyProduct.selColumn = 'AdDayofWeek__c';
            modifyProduct.copyField();
            modifyProduct.selColumn = 'until_Date__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(0).item.KeyValueString__c = 'test';
            modifyProduct.selColumn = 'KeyValueString__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(0).item.UnitPrice = 0.99;
            modifyProduct.selColumn = 'UnitPrice';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(0).item.Check_Inventory__c = true;
            modifyProduct.selColumn = 'Check_Inventory__c';
            modifyProduct.copyField();
            modifyProduct.selColumn = 'Fixed_price__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(0).item.AdBrowsersMinorVersion__c = 'test';
            modifyProduct.selColumn = 'AdBrowsersMinorVersion__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(0).item.Rich_Line_Description__c = 'test';
            modifyProduct.lstRecords[0].isHasSite = false;
            modifyProduct.selColumn = 'Rich_Line_Description__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(0).item.Regions_Description__c = 'test';
            modifyProduct.selColumn = 'Regions_Description__c';
            modifyProduct.forceCopyField();
            modifyProduct.selColumn = 'ListPriceCorrection__c';
            modifyProduct.forceCopyField();
            modifyProduct.selColumn = 'Device_Targeting__c';
            modifyProduct.forceCopyField();
            modifyProduct.selColumn = 'Geography__c';
            modifyProduct.forceCopyField();
            modifyProduct.selColumn = 'Connection_Targeting__c';
            modifyProduct.forceCopyField();

            //modifyProduct.selCopies = '1';   //@vitou 29-04-2015
            modifyProduct.selPosition = '0';   //@vitou 29-04-2015
            modifyProduct.duplicateRecord();
            modifyProduct.deleteRecord();
        }
        Test.stopTest();
    }

    @isTest static void copyFieldFromDownTotop() {
        setupdaData();
        String camtmp = camItem1.id;
        Pagereference pg = Page.ModifyProduct3;
        ID sID = mediaCampaign.id;

        Test.setCurrentPageReference(pg);
        Test.startTest();
        System.runAs(currentUser) {
            ApexPages.StandardController setCon = new ApexPages.StandardController(mediaCampaign);
            ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);

            pg.getParameters().put('id', mediaCampaign.Id);
            pg.getParameters().put('retURL', '/' + mediaCampaign.Id);
            pg.getParameters().put('mcPBId', standardPbId);
            pg.getParameters().put('camItems', camtmp);
            modifyProduct = new ModifyProductController2(setCon);
            modifyProduct.lstRecords.add(new ModifyProductController2.DtoItem(adSpec.Name, camItem1, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 0));
            modifyProduct.lstRecords.add(new ModifyProductController2.DtoItem(adSpec.Name, camItem2, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 1));
            //modifyProduct.lstRecords.get(0).position = 0;
            //modifyProduct.lstRecords.get(1).position = 1;
            modifyProduct.selPosition = '1';
            modifyProduct.lstRecords.get(1).item.Placement_Targeting__c = 'test';
            modifyProduct.selColumn = 'PlacementTargeting__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(1).item.City_Description__c = 'test';
            modifyProduct.selColumn = 'City_Description__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(1).item.Countries_Description__c = 'test';
            modifyProduct.selColumn = 'Countries_Description__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(1).item.FC_Ad_Served_Every__c = 3;
            modifyProduct.selColumn = 'FC_Ad_Served_Every__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(1).item.AdDayofWeek__c = 'Wednesday';
            modifyProduct.selColumn = 'AdDayofWeek__c';
            modifyProduct.copyField();
            modifyProduct.selColumn = 'until_Date__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(1).item.KeyValueString__c = 'test';
            modifyProduct.selColumn = 'KeyValueString__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(1).item.UnitPrice = 3;
            modifyProduct.selColumn = 'UnitPrice';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(1).item.Check_Inventory__c = true;
            modifyProduct.selColumn = 'Check_Inventory__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(1).item.PricebookEntry.Product2.Fixed_price__c = true;
            modifyProduct.selColumn = 'Fixed_price__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(1).item.AdBrowsersMinorVersion__c = '1';
            modifyProduct.selColumn = 'AdBrowsersMinorVersion__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(1).item.Rich_Line_Description__c = 'test';
            modifyProduct.lstRecords[0].isHasSite = false;
            modifyProduct.selColumn = 'Rich_Line_Description__c';
            modifyProduct.copyField();
            modifyProduct.lstRecords.get(1).item.Length_Months__c = 1;
            modifyProduct.selColumn = 'Length_Months__c';
            modifyProduct.forceCopyField();
            modifyProduct.selColumn = 'AreaCode_Description__c';
            modifyProduct.forceCopyField();
            modifyProduct.lstRecords.get(1).item.Regions_Description__c = 'test';
            modifyProduct.selColumn = 'Regions_Description__c';
            modifyProduct.forceCopyField();
            modifyProduct.selColumn = 'ListPriceCorrection__c';
            modifyProduct.forceCopyField();
            modifyProduct.selColumn = 'Device_Targeting__c';
            modifyProduct.forceCopyField();
            modifyProduct.selColumn = 'Geography__c';
            modifyProduct.forceCopyField();
            modifyProduct.selColumn = 'Connection_Targeting__c';
            modifyProduct.forceCopyField();

        }
        Test.stopTest();
    }


    @isTest static void testSplitRecordsWeek() {
        setupdaData();
        String camtmp = camItem1.id;
        Pagereference pg = Page.ModifyProduct3;

        ID sID = mediaCampaign.id;
        Test.setCurrentPageReference(pg);
        Test.startTest();
        System.runAs(currentUser) {
            ApexPages.StandardController setCon = new ApexPages.StandardController(mediaCampaign);
            ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);

            pg.getParameters().put('id', mediaCampaign.Id);
            pg.getParameters().put('retURL', '/' + mediaCampaign.Id);
            pg.getParameters().put('mcPBId', standardPbId);
            pg.getParameters().put('camItems', camtmp);
            modifyProduct = new ModifyProductController2(setCon);
            modifyProduct.lstRecords.add(new ModifyProductController2.DtoItem(adSpec.Name, camItem1, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 0));
            modifyProduct.lstRecords.get(0).position = 0;
            modifyProduct.lstRecords.get(1).position = 1;
            modifyProduct.lstRecords.get(2).position = 2;
            modifyProduct.selPosition = '0';
            modifyProduct.selShare = 'week';
            modifyProduct.splitRecord();
        }
        Test.stopTest();
    }

    @isTest static void testSplitRecordsWeek2() {
        setupdaData();
        String camtmp = camItem1.id;
        Pagereference pg = Page.ModifyProduct3;

        ID sID = mediaCampaign.id;
        Test.setCurrentPageReference(pg);
        Test.startTest();
        System.runAs(currentUser) {
            ApexPages.StandardController setCon = new ApexPages.StandardController(mediaCampaign);
            ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);

            pg.getParameters().put('id', mediaCampaign.Id);
            pg.getParameters().put('retURL', '/' + mediaCampaign.Id);
            pg.getParameters().put('mcPBId', standardPbId);
            pg.getParameters().put('camItems', camtmp);
            modifyProduct = new ModifyProductController2(setCon);
            modifyProduct.lstRecords.add(new ModifyProductController2.DtoItem(adSpec.Name, camItem2, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 1));
            modifyProduct.lstRecords.get(0).position = 0;
            modifyProduct.selPosition = '0';
            modifyProduct.selShare = 'week2';
            modifyProduct.splitRecord();
        }
        Test.stopTest();
    }

    @isTest static void testSplitRecordsMonth() {
        setupdaData();

        String camtmp = camItem1.id;
        Pagereference pg = Page.ModifyProduct3;

        ID sID = mediaCampaign.id;
        Test.setCurrentPageReference(pg);
        Test.startTest();
        System.runAs(currentUser) {
            ApexPages.StandardController setCon = new ApexPages.StandardController(mediaCampaign);
            ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);

            pg.getParameters().put('id', mediaCampaign.Id);
            pg.getParameters().put('retURL', '/' + mediaCampaign.Id);
            pg.getParameters().put('mcPBId', standardPbId);
            pg.getParameters().put('camItems', camtmp);
            modifyProduct = new ModifyProductController2(setCon);
            modifyProduct.lstRecords.add(new ModifyProductController2.DtoItem(adSpec.Name, camItem1, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 2));
            modifyProduct.lstRecords.get(0).position = 0;
            modifyProduct.selPosition = '0';
            modifyProduct.selShare = 'month';
            modifyProduct.splitRecord();
        }
        Test.stopTest();
    }

    @isTest static void testDTOItem() {
        setupdaData();
        String camtmp = camItem1.id;
        Pagereference pg = Page.ModifyProduct3;
        ID sID = mediaCampaign.id;
        Test.setCurrentPageReference(pg);
        Test.startTest();
        System.runAs(currentUser) {
            ApexPages.StandardController setCon = new ApexPages.StandardController(mediaCampaign);
            ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);

            pg.getParameters().put('id', mediaCampaign.Id);
            pg.getParameters().put('retURL', '/' + mediaCampaign.Id);
            pg.getParameters().put('mcPBId', standardPbId);
            pg.getParameters().put('camItems', camtmp);
            modifyProduct = new ModifyProductController2(setCon);
            // dcc 2014-03-28 increment code coverage by testing DtoItem class...
            // this code should ideally be packaged with the DtoItem test coverage
            ModifyProductController2.DtoItem dtoi = new ModifyProductController2.DtoItem(adSpec.Name, camItem1, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 0);
            // JvdH: not compiling // dtoi.setBillingCategory2('the string');
            // JvdH: not compiling // dtoi.getBillingCategory2();
            dtoi.getErrQty();
            dtoi.getErrSalePrice();
            dtoi.getErrBillin();
            dtoi.getDescr();
            dtoi.getFromDate();
            dtoi.getUntilDate();
            dtoi.getTargeting_c();
            dtoi.getquantity();
            dtoi.getsalesPrice();
            dtoi.setsalesPrice('1');
            ModifyProductController2.formatCurrency(12.0, 1);
            ModifyProductController2.formatCurrency(null, 2);
            // end of dcc 2014-03-29
        }
        Test.stopTest();
    }

    static void testCreateNewPro() {
        setupdaData();
        System.runAs(currentUser) {

        	Site__c site = new Site__c(Country__c = 'DE', Name = 'Testsite');
	        insert site;

	        Placement__c pm = new Placement__c(Name = 'Testplacement');
	        insert pm;

	        Advertising_Medium__c am = new Advertising_Medium__c(
	            Name = 'Skyskraper',
	            related_Mediums__c = 'Skyskraper',
	            Site__c = site.id
	        );
	        insert am;
	        RecordType rec = [select id from RecordType where Name = 'DART6'
	                and SobjectType = 'Product2'
	                limit 1
	            ];
	        Product2 prod1 = new Product2(
	            Name = 'ApexTestProd',
	            IsActive = true,
	            Site__c = site.id,
	            Placement__c = pm.id,
	            Advertising_Medium__c = am.id,
	            ///Exclusive_Placement__c = true,
	            RecordTypeId = rec.Id);

	        insert prod1;

	    	//Account acc = GW_Account.insertSObject();
	    	Account acc = new Account();
	        acc.Name = 'Test Account Quote1';
	        acc.BillingStreet = '123245';
	        acc.BillingCity = 'Test1';
	        acc.Phone = '+124567296';
	        acc.BillingCountryCode = 'GB';
	        acc.BillingPostalCode = '1346972';
	        acc.OwnerId=userAdmin.id;
			insert acc;

	    	standardPbId = Test.getStandardPricebookId();

	        Opportunity opp1 = new Opportunity(
	            Name = 'Test Opp1',
	            StageName = 'gebucht',
	            CloseDate = System.today(),
	            Probability = 50,
	            Billing_Account__c = acc.id,
	            AccountId = acc.id,
	            Pricebook2Id = standardPbId
	        );

	        insert opp1;

	        PricebookEntry pbe1std = new PricebookEntry(
	            Pricebook2Id = standardPbId,
	            Product2Id = prod1.Id,
	            UnitPrice = 1.00,
	            IsActive = true);
	        insert pbe1std;

	        OpportunityLineItem oli1 = new OpportunityLineItem(
	            OpportunityId = opp1.Id,
	            Quantity = 100,
	            TotalPrice = 100.0,
	            ///from_Date__c = Date.newInstance(2015, 2, 20),
                from_Date__c = System.today(),
	            until_Date__c = System.today() + 30,
	            PricebookEntryId = pbe1std.Id,
	            AdOperatingSystems__c = 'Windows XP',
	            Billing_Category__c = 'CPM',
	            UniqueLineDescription__c = 'Descoli1',
	            Description = 'Test OLI1'
	        );
	        OpportunityLineItem oli2 = new OpportunityLineItem(
	            OpportunityId = opp1.Id,
	            Quantity = 100,
	            TotalPrice = 100.0,
	            ///from_Date__c = Date.newInstance(2015, 2, 20),
                from_Date__c = System.today(),
	            until_Date__c = System.today() + 30,
	            PricebookEntryId = pbe1std.Id,
	            AdOperatingSystems__c = 'Windows XP',
	            Billing_Category__c = 'CPM',
	            UniqueLineDescription__c = 'Descoli2',
	            Description = 'Test OLI2'
	        );
	        insert new List < OpportunityLineItem > { oli1, oli2 };
			/*
	        exclusive_Placement__c bp1 = new exclusive_Placement__c(
	            Date__c = System.today(),
	            Opportunity__c = opp1.id,
	            Product__c = prod1.id
	        );
	        insert bp1;*/

	        Pagereference pg = Page.ModifyProduct3;

	        Test.setCurrentPageReference(pg);
	        pg.getParameters().put('id', opp1.Id);
	        pg.getParameters().put('modolis', oli1.Id);
	        pg.getParameters().put('retURL', '/' + opp1.Id);
	        pg.getParameters().put('mcPBId', standardPbId);

            test.startTest();
            	ApexPages.StandardController setCon = new ApexPages.StandardController(opp1);
		        ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);
            	modifyProduct = new ModifyProductController2(setCon);
		        modifyProduct.lstRecords.get(0).item.Rich_Line_Description__c = 'Test';
		        modifyProduct.lstRecords.get(0).availableSite = 'brantford , bc , bridgewater , bathurst , brandon , belleville , barrie.';
		        modifyProduct.lstRecords.get(0).isFixedSite = true;
		        modifyProduct.lstRecords.get(0).isHasSite = true;
		        modifyProduct.lstRecords.get(0).item.from_Date__c = System.today();
		        modifyProduct.lstRecords.get(0).item.UnitPrice = 1000;
		        modifyProduct.lstRecords.get(1).item.UnitPrice = 1000;
		        modifyProduct.lstRecords.get(1).item.from_Date__c = System.today();
		        modifyProduct.lstRecords.get(1).item.Rich_Line_Description__c = 'test';
		        modifyProduct.lstRecords.get(1).isFixedSite = true;
		        modifyProduct.lstRecords.get(1).availableSite = 'brantford , bc , bridgewater , bathurst.';
		        modifyProduct.saveRecords();
		        modifyProduct.goPrevious();
		        modifyProduct.copyField();
		        modifyProduct.copyRecords();

            Test.stopTest();
        }
    }

    //**
    @isTest static void testCreateNewPro1() {
        //setupdaData();

		createTestUser();
        //System.runAs(currentUser) {
        System.runAs(userAdmin) {

        	createMembers();

            Account acc = new Account(Name = 'Test Account Quote', BillingStreet = '12345', BillingCity = 'Test', Phone = '+12456796', BillingCountryCode = 'GB',
                BillingPostalCode = '134697', OwnerId=userAdmin.id);
            insert acc;

            Contact con = new Contact();
            con.LastName = 'TestContact';
            con.AccountId = acc.Id;
            con.Fax = '1234567';
            con.Email = 'Test@test.com';
            con.MobilePhone = '+134697589';

            insert con;
      //MS 01-09-2014: block this line for deploying to Gumtree Au
            /*acc.Primary_Contact__c = con.id;
            acc.Finance_Contact__c = con.id;
            update acc;
      */
            //Pricebook2 pb = [select Id from Pricebook2 where IsStandard = false and IsActive = true limit 1];
            //Pricebook2 pbstd1 = [select Id from Pricebook2 where IsStandard = true];

		//**
            Placement__c placement = new Placement__c(Name = 'TestPlacements');
            Placement__c placement2 = new Placement__c(Name = 'TestPlacements2');
            insert new List < Placement__c > {
                placement, placement2
            };

            Advertising_Medium__c adType = new Advertising_Medium__c(Name = 'AdType', related_Mediums__c = 'Skyskraper');
            insert adType;

            RecordType rec = [select id from RecordType where Name = 'DART6'
                and SobjectType = 'Product2'
                limit 1
            ];

            Product2 pro = new Product2(Name = 'Test Ad Spec', placement__c = placement.id, FreeProduct__c = true, AdServer_Keywords_Key_values__c = 'BBB', Advertising_Medium__c = adType.id, Billing_Category__c = 'CPM',RecordTypeId = rec.Id, tech_targeting__c = true, Time__c = true, Fixed_price__c = true, Fixed_Site__c = true, Availablility_Forecast__c = true, Rate_Card__c = true,IsActive = true);
            Product2 pro2 = new Product2(Name = 'Test Ad Spec', placement__c = placement2.id, AdServer_Keywords_Key_values__c = 'BBB', Advertising_Medium__c = adType.id, Billing_Category__c = 'CPM',RecordTypeId = rec.Id,IsActive = true);
            insert new List < Product2 > {
                pro, pro2
            };

            Rate_Card__c rateCard = new Rate_Card__c(Sales_Price__c = 10, Quantity__c = '15 to 24', Product__c = pro.Id, Length__c = '6');
            //insert rateCard;

            Content__c cont = new Content__c(Type__c = 'Dart - Site', Name = 'test', DartName__c = 'test');
            Content__c cont2 = new Content__c(Type__c = 'Dart - Site', Name = 'test2', DartName__c = 'test2');
            insert new List < Content__c > {
                cont, cont2
            };

            Packagecomponent__c pag = new Packagecomponent__c(Singleproduct__c = pro2.Id, Package_product__c = pro.Id, DART_Content__c = cont.Id);
            insert pag;

            Available_Site__c avai = new Available_Site__c(Product__c = pro.Id, available_Site__c = cont.Id);
            Available_Site__c avai2 = new Available_Site__c(Product__c = pro.Id, available_Site__c = cont2.Id);
            insert new List < Available_Site__c > {
                avai, avai2
            };

            MemberUnit__c mu = [SELECT Id FROM MemberUnit__c WHERE Name = 'Test Adsales' AND LineOfBusiness__c = 'AD' LIMIT 1];
            Opportunity Opp = new Opportunity( MemberUnit__c=mu.Id, Pricebook2Id = standardPbId, Name = 'Test Media campaign Test', AccountId = acc.id, Description = 'Test', StageName = 'Test', Probability = 50, CloseDate = system.today() );
            insert Opp;
			standardPbId = Test.getStandardPricebookId();
            //PricebookEntry pbe1std = new PricebookEntry(Pricebook2Id = standardPbId, Product2Id = pro.Id, UnitPrice = 4.00, IsActive = true);
            PricebookEntry pbe1 = new PricebookEntry(UseStandardPrice = false, Product2Id = pro.Id, Pricebook2Id = standardPbId, UnitPrice = 10.00, IsActive = true);
            insert pbe1;   //@vitou 29-04-2015

            //List < PricebookEntry > lstPric = new List < PricebookEntry > {
            //   pbe1std, pbe1
            //};
            //insert lstPric;

            Media_Basket__c media = new Media_Basket__c(UserId__c = userAdmin.Id, OpportunityId__c = Opp.Id, AdPriceIdText__c = pbe1.Id);
            insert media;

            //create targeting
            Targeting__c tmpTar = new Targeting__c(TempBinder__c = true, Description__c = 'test targeting');
            insert tmpTar;

            DART_KeyValue_2__c dart2 = new DART_KeyValue_2__c(Name = 'test', Key_Value__c = 'test1', Key_Value_Name__c = 'test');
            insert dart2;

            String ex_key = tmpTar.Id + '' + cont.Id;
            TargetingContentAssociation__c contar = new TargetingContentAssociation__c(Targeting__c = tmpTar.Id, TargetingContent__c = cont.Id, Target_Content_Key__c = ex_key, Exclude__c = false);
            insert contar;

            ex_key = tmpTar.Id + '' + dart2.Id;
            TargetingKeyValueAssociation__c keyTar = new TargetingKeyValueAssociation__c(Targeting__c = tmpTar.Id, Operator__c = 'AND', DART_KeyValue__c = dart2.Id, targetkeyvalue__c = ex_key);
            insert keyTar;

      OpportunityLineItem item = new OpportunityLineItem(OpportunityId = Opp.id, UnitPrice = 523, Quantity = 3, PricebookEntryId = pbe1.Id, Billing_category__c = 'CPM',
                                                Description = 'Test123', from_Date__c = Date.newInstance(2014, 04, 05), until_Date__c = System.today() + 30 );
      insert item;

            Pagereference pg = Page.ModifyProduct3;
            Test.setCurrentPageReference(pg);

            pg.getParameters().put('id', Opp.Id);
            pg.getParameters().put('retURL', '/' + Opp.Id);
            pg.getParameters().put('mcPBId', standardPbId);
            pg.getParameters().put('mcId', Opp.id);

            test.startTest();
            ApexPages.StandardController setCon = new ApexPages.StandardController(Opp);
            ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);
            //save succecfully

            modifyProduct = new ModifyProductController2(setCon);
            modifyProduct.lstRecords.get(0).item.from_Date__c = system.today();
            modifyProduct.lstRecords.get(0).item.until_Date__c = system.today().addDays(10);
            modifyProduct.lstRecords.get(0).item.Billing_category__c = 'CPA';
            modifyProduct.lstRecords.get(0).item.UnitPrice = 10;
            modifyProduct.lstRecords.get(0).item.Quantity = 16;
            modifyProduct.lstRecords.get(0).item.Length_Months__c = 6;
            modifyProduct.lstRecords.get(0).item.Budget_NetNetNet__c = 2000;
            modifyProduct.lstRecords.get(0).item.Targeting__c = tmpTar.Id;
            modifyProduct.selPosition = '0';
            // modifyProduct.calculateQtyByBudget();

            modifyProduct.saveRecords();
            if(!modifyProduct.lstRecords.isEmpty()){
              modifyProduct.lstRecords.get(0).getErrBillin();
              modifyProduct.lstRecords.get(0).getDescr();
              modifyProduct.lstRecords.get(0).getFromDate();
              modifyProduct.lstRecords.get(0).getUntilDate();
              modifyProduct.lstRecords.get(0).getTargeting_c();
              modifyProduct.lstRecords.get(0).getquantity();
              modifyProduct.lstRecords.get(0).setquantity('16');
              // JvdH: not compiling // modifyProduct.lstRecords.get(0).setBillingCategory2('tetst');
              // JvdH: not compiling // modifyProduct.lstRecords.get(0).getBillingCategory2();
              modifyProduct.lstRecords.get(0).item.Quantity = null;
              modifyProduct.lstRecords.get(0).getErrQty();
              modifyProduct.lstRecords.get(0).item.UnitPrice = null;
              modifyProduct.lstRecords.get(0).getErrSalePrice();
              modifyProduct.lstRecords.get(0).item.Billing_category__c = null;
              modifyProduct.lstRecords.get(0).getErrBillin();
              modifyProduct.lstRecords.get(0).item.KeyValueString__c = 'Key Value String';
              modifyProduct.lstRecords.get(0).setAdKV();
              modifyProduct.lstRecords.get(0).getAdKV();
            }
            modifyProduct.selPosition = '0';
            modifyProduct.goBack();
           // modifyProduct.reCalculateAll();

            Test.stopTest();


        }
    }//**/

    @isTest static void testCalculateMethods() {
        setupdaData();
        String camtmp = camItem1.id;

        Pagereference pg = Page.ModifyProduct3;
        ID sID = mediaCampaign.id;

        Test.setCurrentPageReference(pg);
        Test.startTest();
        System.runAs(currentUser) {
            ApexPages.StandardController setCon = new ApexPages.StandardController(mediaCampaign);
            ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);
            pg.getParameters().put('id', mediaCampaign.Id);
            pg.getParameters().put('retURL', '/' + mediaCampaign.Id);
            pg.getParameters().put('mcPBId', standardPbId);
            pg.getParameters().put('camItems', camtmp);
            modifyProduct.getQuantityFromSalePrice(100, 10);
            modifyProduct.getSalesPriceFromRateCard(rateCards, 2);
            modifyProduct.mappingProAndRateCard(rateCards);
            modifyProduct.getQuantityRang(100);
        }
        Test.stopTest();
    }

    @isTest static void testRateCardSurchargeDiscount() {
        setupdaData();

        Pagereference pg = Page.ModifyProduct3;
        pg.getParameters().put('id', mediaCampaign.Id);
        pg.getParameters().put('retURL', '/' + mediaCampaign.Id);
        pg.getParameters().put('mcPBId', standardPbId);
        pg.getParameters().put('camItems', camItem1.id);

        Test.setCurrentPageReference(pg);

        Test.startTest();
        System.runAs(currentUser) {
            ApexPages.StandardController stdController = new ApexPages.StandardController(mediaCampaign);
            ModifyProductController2 modifyProduct = new ModifyProductController2(stdController);

            modifyProduct.lstRecords.add(new ModifyProductController2.DtoItem(adSpec.Name, camItem1, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 0));
            //modifyProduct.lstRecords.add(new ModifyProductController2.DtoItem(adSpec.Name, camItem2, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 1));
            //modifyProduct.lstRecords.add(new ModifyProductController2.DtoItem(adSpec.Name, camItem3, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 2));
            modifyProduct.lstRecords.get(0).position = 0;
            //modifyProduct.lstRecords.get(1).position = 1;
            //modifyProduct.lstRecords.get(2).position = 2;
            modifyProduct.selPosition = '0';

            // assert Auto Targeting Surcharge
            modifyProduct.lstRecords.get(0).item.Placement_Targeting__c = 'Buy & Sell Network.'; // value of TabSix "Category & KeyValue Targeting" added (10%)
            modifyProduct.lstRecords.get(0).item.City_Description__c = 'City_Description__c';  // value of tab "Geo-targeting (IP)" added (10%)
            modifyProduct.reCalculateAll();
            Decimal autoSurcharge =  modifyProduct.getSurchargeFromCS('TabSix')+modifyProduct.getSurchargeFromCS('TabSeven');
            System.assertEquals(modifyProduct.lstRecords.get(0).item.Auto_Targeting_Surcharge__c, autoSurcharge);

            //MS 01-09-2014: block this line for deploying to Gumtree Au
            // assert Account Discount
            //System.assertEquals(modifyProduct.accountDiscount, 10 );

            // assert Sales Price
            modifyProduct.lstRecords.get(0).item.Billing_category__c = 'cpa'; // cpa will take list pricr from item.PricebookEntry.UnitPrice
            modifyProduct.reCalculateAll();
            Decimal logicSP = modifyProduct.lstRecords.get(0).item.PricebookEntry.UnitPrice + (modifyProduct.lstRecords.get(0).item.PricebookEntry.UnitPrice/100 * (autoSurcharge - 10)); // 10 is assigned to the acc

            //MS 01-09-2014: block this line for deploying to Gumtree Au
            //System.assertEquals(logicSP, modifyProduct.lstRecords.get(0).item.UnitPrice);

            // assert Sales Price Net --- in case Surcharge (% or $)
            modifyProduct.lstRecords.get(0).item.Discount_Type__c = ModifyProductController2.GBP_TYPE;
            modifyProduct.lstRecords.get(0).item.Discount = 0;
            modifyProduct.lstRecords.get(0).item.Sales_Price_Target__c = 0;

            modifyProduct.lstRecords.get(0).item.Surcharge_Type__c = ModifyProductController2.PERCENT_TYPE;
            modifyProduct.lstRecords.get(0).item.Targeting_Surcharge__c = 50; // 50%---------
            modifyProduct.reCalculateAll();

            //MS 01-09-2014: block this line for deploying to Gumtree Au
            //System.assertEquals( modifyProduct.lstRecords.get(0).item.SalesPriceNetNew__c, logicSP*1.5);

            // assert Sales Price Net --- in case Discount (% or $)
            modifyProduct.lstRecords.get(0).item.Discount_Type__c = ModifyProductController2.GBP_TYPE;
            modifyProduct.lstRecords.get(0).item.Discount = 1; // 1$---------
            modifyProduct.lstRecords.get(0).item.Sales_Price_Target__c = 0;

            modifyProduct.lstRecords.get(0).item.Surcharge_Type__c = ModifyProductController2.PERCENT_TYPE;
            modifyProduct.lstRecords.get(0).item.Targeting_Surcharge__c = 0;
            modifyProduct.reCalculateAll();

            //MS 01-09-2014: block this line for deploying to Gumtree Au
            //System.assertEquals( modifyProduct.lstRecords.get(0).item.SalesPriceNetNew__c, logicSP-1);

            // assert Sales Price Net --- in case Sales Price Target
            modifyProduct.lstRecords.get(0).item.Discount_Type__c = ModifyProductController2.GBP_TYPE;
            modifyProduct.lstRecords.get(0).item.Discount = 0;
            modifyProduct.lstRecords.get(0).item.Sales_Price_Target__c = 2;// 2$------

            modifyProduct.lstRecords.get(0).item.Surcharge_Type__c = ModifyProductController2.PERCENT_TYPE;
            modifyProduct.lstRecords.get(0).item.Targeting_Surcharge__c = 0;
            modifyProduct.reCalculateAll();

            //MS 01-09-2014: block this line for deploying to Gumtree Au
            //System.assertEquals( modifyProduct.lstRecords.get(0).item.SalesPriceNetNew__c, 2);

            // assert Line Item Budget
            modifyProduct.lstRecords.get(0).item.Quantity = 2;
            modifyProduct.reCalculateAll();
            //System.assertEquals( modifyProduct.lstRecords.get(0).item.Budget_NetNetNet__c, modifyProduct.lstRecords.get(0).item.SalesPriceNetNew__c*2);

            // coverage
            modifyProduct.lstRecords.get(0).item.Sales_Price_Target__c = 1;
            modifyProduct.reCalculateAll();

            modifyProduct.lstRecords.get(0).item.Sales_Price_Target__c = 0;
            modifyProduct.lstRecords.get(0).item.Targeting_Surcharge__c = 0;
            modifyProduct.lstRecords.get(0).item.Discount = 1;
            modifyProduct.lstRecords.get(0).item.Rebate_In_Kind_Reason__c = null;
            //9/1/2014
            modifyProduct.oppProb = 25;
            modifyProduct.forceDateSave = false;
            modifyProduct.accId = modifyProduct.X_ACCOUNT_ID;
            modifyProduct.saveRecords();

        }
        Test.stopTest();
    }

    //@createddate: 09/1/2014 - to increase test coverage
    static testmethod void testdoCopyForNewTargeting() {
        setupdaData();

        Pagereference pg = Page.ModifyProduct3;
        pg.getParameters().put('id', mediaCampaign.Id);
        pg.getParameters().put('retURL', '/' + mediaCampaign.Id);
        pg.getParameters().put('mcPBId', standardPbId);
        pg.getParameters().put('camItems', camItem1.id);

        Test.setCurrentPageReference(pg);

        Test.startTest();
        System.runAs(currentUser) {
            ApexPages.StandardController stdController = new ApexPages.StandardController(mediaCampaign);
            ModifyProductController2 modifyProduct = new ModifyProductController2(stdController);

            modifyProduct.lstRecords.add(new ModifyProductController2.DtoItem(adSpec.Name, camItem1, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 0));
            modifyProduct.lstRecords.get(0).position = 0;
            modifyProduct.selPosition = '0';
            modifyProduct.lstRecords.get(0).item.Placement_Targeting__c = 'Buy & Sell Network.'; // value of TabSix "Category & KeyValue Targeting" added (10%)
            modifyProduct.lstRecords.get(0).item.City_Description__c = 'City_Description__c';  // value of tab "Geo-targeting (IP)" added (10%)
            modifyProduct.doCopyForNewTargeting();
            modifyProduct.doForceCopyForNewTargeting();

        }
        Test.stopTest();
    }


    //@vitou 09-04-2015
    @isTest
    static void testinitList2() {
        setupdaData();
        //createTestUser();
        String camtmp = camItem1.id;
        Pagereference pg = Page.ModifyProduct3;
        ID sID = mediaCampaign.id;

        adSpec.FreeProduct__c = true;
        update adSpec;

        Media_Basket__c media = new Media_Basket__c(UserId__c = userAdmin.Id, OpportunityId__c = mediaCampaign.id, AdPriceIdText__c = pbeMb.Id);
        insert media;

        Product2 product1 = new Product2(Name = 'Test Product', AdServer_Keywords_Key_Values__c = 'BBB', Billing_Category__c = 'CPD', Fixed_price__c = true,IsActive = true );
        insert product1;


        Test.setCurrentPageReference(pg);
        System.runAs(userAdmin) {
            ApexPages.StandardController setCon = new ApexPages.StandardController(mediaCampaign);
            pg.getParameters().put('mcId', mediaCampaign.Id);
            pg.getParameters().put('retURL', '/' + mediaCampaign.Id);
            pg.getParameters().put('mcPBId', standardPbId);
            pg.getParameters().put('isClone', 'isCloneButton');
            ModifyProductController2 modifyProduct = new ModifyProductController2(setCon);
            modifyProduct.lstRecords.get(0).item.Quantity = 2;
            modifyProduct.lstRecords.get(0).item.Rich_Line_Description__c = 'test';

            Test.startTest();
                modifyProduct.mcName = 'test';
                modifyProduct.accName = 'test acc';
                modifyProduct.selectedRandomNr = 1.00;
                modifyProduct.isFromDateDisabled = 'true';
                modifyProduct.isFromDateDisabled = 'true';
                string str = modifyProduct.tab6Surcharge;
                str = modifyProduct.tab3Surcharge;
                str = modifyProduct.tab4Surcharge;
                str = modifyProduct.tab5Surcharge;
                str = modifyProduct.tab7Surcharge;

                modifyProduct.forceDateSave = true;
                modifyProduct.saveRecords();
                modifyProduct.copyRecords();
                modifyProduct.goPrevious();
                modifyProduct.goNext();
                modifyProduct.goBack();

                modifyProduct.lstRecords.add(new ModifyProductController2.DtoItem(adSpec.Name, camItem1, false, adSpec.Id, null, true, null, 'CPM', adSpec, true, 0));
                modifyProduct.lstRecords.get(0).setquantity('');
                modifyProduct.lstRecords.get(0).setquantity('5');
                modifyProduct.lstRecords.get(0).item.Billing_category__c = null;
                modifyProduct.lstRecords.get(0).getErrBillin();
                modifyProduct.lstRecords.get(0).item.UnitPrice = null;
                modifyProduct.lstRecords.get(0).getErrSalePrice();
                modifyProduct.lstRecords.get(0).item.Quantity = 1;
                modifyProduct.lstRecords.get(0).getErrQty();
                modifyProduct.lstRecords.get(0).keyWords = 'test';
                modifyProduct.lstRecords.get(0).randomNr = 1.0;
                integer maxRec = modifyProduct.getMAXRECORD();

            Test.stopTest();
        }
    }
}