@isTest
private class TST_TargetingUI {
    public static TestDataGenerator testDATA = new TestDataGenerator();

    //@vitou 15-05-2015
     public static Opportunity opp;
     public static OpportunityLineItem item;
     public static Targeting__c targetting;
     public static Product2 prd;
     public static Devices__c device0, device1, device2;
     public static Connection__c conn0, conn1, conn2;
     public static Geography__c geo0, geo1, geo2;

    //@vitou 15-05-2015
    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createOppTeamMember(testDATA.opp.id);
        testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
        UTIL.isRunningTestSetup = false;
    }

    //@vitou 15-05-2015
    static void getOppLineItems(){
         opp = [select id, Name, Owner.id, Owner.Name, AccountId, CampaignStart__c, CampaignEnd__c, P_O_Number__c from Opportunity limit 1];
         prd = [select id from Product2 where Name='Test product0' limit 1];
         item = [select id, OpportunityId, from_Date__c, Until_Date__c, SalesPriceNet__c, AdOperatingSystems__c,
                       Keywords_KeyValue_combination__c, KeyValueString__c, AdWebBrowsers__c, Ad_Id__c, AdKeywords__c,
                       PriceBookEntry.Product2.Fixed_Site__c, Targeting__c, PricebookEntry.Product2.RecordType.Name, PriceBookEntry.Product2.Site__r.Country__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c, Ad_Name__c, Device_Targeting__c, AdDayOfWeek__c, AdHourOfDay__c,
                       AdBrowsersMinorVersion__c, AdBrowsersMajorVersion__c, CurrencyIsoCode, Billing_Category__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdType__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_Prio__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_Product_Type__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_MasterSize__c,
                       Quantity, Description, FC_Period__c, FC_Ad_served_every__c, FC_Quantity__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_CompanionSize__c, PriceBookEntry.Product2.Name
                       from OpportunityLineItem where Description='Test Desc0' and OpportunityId= :opp.Id];
    }

    //@vitou 15-05-2015
    static void getTargetting(){
        targetting = [select id from Targeting__c where Description__c='test' limit 1];
    }

    //@vitou 15-05-2015
    static void getDevices(){
        device0 = [select id from Devices__c where Name='Test1' AND Dart_ID__c=123456];
        device1 = [select id from Devices__c where Name='Test2' AND Dart_ID__c=555555];
        device2 = [select id from Devices__c where Name='Test3' AND Dart_ID__c=333333];
    }

    //@vitou 15-05-2015
    static void getConnections(){
        conn0 = [select id from Connection__c where Name='Test1' AND Dart_ID__c=123456 ];
        conn1 = [select id from Connection__c where Name='Test3' AND Dart_ID__c=111111 ];
        conn2 = [select id from Connection__c where Name='Test1' AND Dart_ID__c=666666 ];
    }

    //@vitou 15-05-2015
    static void getGeographies(){
        geo0 = [select id from Geography__c where Name='Test1' AND Dart_ID__c=123456 ];
        geo1 = [select id from Geography__c where Name='Test2' AND Dart_ID__c=888888 ];
        geo2 = [select id from Geography__c where Name='Test3' AND Dart_ID__c=999999 ];
    }

    /** -------- Test Tree Device ----------------- */
    @isTest static void testDeviceTargeting() {
        Test.startTest();

            //@vitou 15-05-2015 ==> get Test Data
            getOppLineItems();
            getTargetting();
            getDevices();

            PageReference pg = Page.TreeConnectionSelection;
            Test.setCurrentPage(pg);
            pg.getParameters().put('targetId',targetting.Id ); //pg.getParameters().put('targetId',testDATA.targetting[0].Id );
            pg.getParameters().put('proId',prd.Id ); //pg.getParameters().put('proId',testDATA.lstPrd2[0].Id );
            pg.getParameters().put('itemId',item.Id ); //pg.getParameters().put('itemId',items[0].Id );
            pg.getParameters().put('froIfr','true' );

            TreeDeviceSelectionController treeDev = new TreeDeviceSelectionController();

            //Product2 pro = testDATA.lstPrd2[0];
            //pro.Devices__c = true;
            //pro.Fixed_device__c = true;
            //update pro;
            treeDev = new TreeDeviceSelectionController();
            Boolean ishowcancel = treeDev.isShowCancel;
            List<Devices__c> lstDev = TreeDeviceSelectionController.searchDevice('Test');
            treeDev.selectedDevice = device1.Id+''; //treeDev.selectedDevice = testDATA.lstDevices[1].Id+'';
            treeDev.getDevices();
            treeDev.saveRecords();
            treeDev.addDevice();

        Test.stopTest();
    }


    // Test add parent node
    @isTest static void testDeviceTargeting2() {
        Test.startTest();
            //testDATA.createTargetingHierarchy();
            getDevices();

            String str = '/apex/TreeDeviceSelection?targetId=&itemId=';
            PageReference pageRef = new PageReference(str);
            Test.setCurrentPage(pageRef);
            TreeDeviceSelectionController treeDev = new TreeDeviceSelectionController();
            TreeDeviceSelectionController.searchDevice('Test');
            treeDev.selectedDevice = device0.Id+''; //treeDev.selectedDevice = testDATA.lstDevices[0].Id+'';
            treeDev.addDevice();

             //@vitou 08-04-2015
            treeDev.selectedDevice = device2.Id+''; //treeDev.selectedDevice = testDATA.lstDevices[2].Id+'';
            treeDev.addDevice();

        Test.stopTest();

    }

    /** -------- Test Tree Connection ----------------- */
  @isTest static void testConnectionTargeting() {
        Test.startTest();

            //@vitou 15-05-2015 ==> get Test Data
            getOppLineItems();
            getTargetting();
            getConnections();

            PageReference pg = Page.TreeConnectionSelection;
            Test.setCurrentPage(pg);
            pg.getParameters().put('targetId',targetting.Id ); //pg.getParameters().put('targetId',testDATA.targetting[0].Id );
            pg.getParameters().put('proId',Prd.Id ); //pg.getParameters().put('proId',testDATA.lstPrd2[0].Id );
            pg.getParameters().put('itemId',item.Id ); //pg.getParameters().put('itemId',items[0].Id );
            pg.getParameters().put('froIfr','true' );
            TreeConnectionSelectionController treeConn = new TreeConnectionSelectionController();
            treeConn.isShowCancel = true;
            List<Connection__c> lstDev = TreeConnectionSelectionController.searchConnection('Test');
            treeConn.selectedConnection = conn1.Id+''; //treeConn.selectedConnection = testDATA.lstConns[1].Id+'';
            treeConn.getConnections();
            treeConn.saveRecords();
            treeConn.addConnection();

            treeConn.selectedConnection = conn2.Id+''; //treeConn.selectedConnection = testDATA.lstConns[2].Id+'';
            treeConn.getConnections();
            treeConn.saveRecords();
            treeConn.addConnection();
        Test.stopTest();
    }

    // Test add connection parent node
    @isTest static void testConnectionTargeting2() {
        Test.startTest();
            //testDATA.createTargetingHierarchy();
            getConnections();

            String str = '/apex/TreeConnectionSelection?targetId=&itemId=';
            PageReference pageRef = new PageReference(str);
            Test.setCurrentPage(pageRef);
            TreeConnectionSelectionController treeConn = new TreeConnectionSelectionController();
            treeConn.selectedConnection = conn0.Id+''; //treeConn.selectedConnection = testDATA.lstConns[0].Id+'';
            treeConn.addConnection();

            //@vitou 08-04-2015
            boolean t = treeConn.isShowCancel;
            treeConn.selectedConnection = conn1.Id+''; //treeConn.selectedConnection = testDATA.lstConns[1].Id+'';
            treeConn.addConnection();

        Test.stopTest();
    }

    /** -------- Test Tree Geography ----------------- */
    @isTest static void testGeographyTargeting() {
        Test.startTest();

            //@vitou 15-05-2015 ==> get Test Data
            getOppLineItems();
            getTargetting();
            getGeographies();

            //String str = '/apex/TreeGeographySelecting?targetId='+testDATA.targetting[0].Id+'&itemId='+ items[0].Id ;
            String str = '/apex/TreeGeographySelecting?targetId='+targetting.Id+'&itemId='+ item.Id ;
            PageReference pageRef = new PageReference(str);
            Test.setCurrentPage(pageRef);
            TreeGeographySelectingController treeGeo = new TreeGeographySelectingController();
            treeGeo.isShowCancel = true;
            TreeGeographySelectingController.searchCountry('Test');
            treeGeo.selectedGeography = geo1.Id+''; //treeGeo.selectedGeography = testDATA.lstGeographies[1].Id+'';
            treeGeo.getGeographies();
            treeGeo.saveRecords();
            treeGeo.addCountry();
        Test.stopTest();
    }

    // Test add parent geography
    @isTest static void testGeographyTargeting2() {
        Test.startTest();
            //testDATA.createTargetingHierarchy();
            getGeographies();

            String str = '/apex/TreeGeographySelecting?targetId=&itemId=';
            PageReference pageRef = new PageReference(str);
            Test.setCurrentPage(pageRef);
            TreeGeographySelectingController treeGeo = new TreeGeographySelectingController();
            treeGeo.searchFilter = 'COUNTRY';
            treeGeo.selectedGeography = geo0.Id+''; //treeGeo.selectedGeography = testDATA.lstGeographies[0].Id+'';
            treeGeo.addCountry();

            //@vitou 08-04-2015
            boolean t = treeGeo.isShowCancel;
            treeGeo.searchFilter = 'CITY';
            treeGeo.selectedGeography = geo2.Id+'';  //treeGeo.selectedGeography = testDATA.lstGeographies[2].Id+'';
            treeGeo.addCountry();

        Test.stopTest();
    }

    //---------Content Targeting -----------------//
    @isTest static void testContentTargeting(){
        PageReference pg = Page.TargetingTreeSelection;
        Test.setCurrentPage(pg);
        Test.startTest();

            //@vitou 15-05-2015 ==> get Test Data
            getOppLineItems();
            getTargetting();
            Content__c cont = [ select id from Content__c where Name='40000' limit 1];


            TargetingTreeSelectionController controller = new TargetingTreeSelectionController();
            controller.addContent();
            controller.saveRecords();

            Product2 pro = prd; //Product2 pro = testDATA.lstPrd2[0];
            pro.Content__c = cont.Id; //pro.Content__c = testDATA.contents[0].Id;
            update pro;

            //TargetingTreeSelectionController.searchContent('test', testDATA.contents[0].Id);
            TargetingTreeSelectionController.searchContent('test', cont.Id);
            pg.getParameters().put('targetId',targetting.Id ); //pg.getParameters().put('targetId',testDATA.targetting[0].Id );
            pg.getParameters().put('proId',pro.Id );
            pg.getParameters().put('itemId',item.Id ); //pg.getParameters().put('itemId',items[0].Id );
            pg.getParameters().put('froIfr','true' );

            /*
            testDATA.contents[0].Type__c = 'Dart - ContentCategory';
            testDATA.contents[0].Active__c = true;
            update testDATA.contents[0];*/
            cont.Type__c = 'Dart - ContentCategory';
            cont.Active__c = true;
            update cont;

            Content__c c = new Content__c( Active__c = true, Site_Content_Category__c = cont.Id ,Name='40006666',DartName__c='DartName66006',Type__c = 'Dart - Zone' );
            insert c;

            Content__c c1 = new Content__c( Active__c = true, Site_Content_Category__c = c.Id ,Name='400066633333',DartName__c='DartName66633333',Type__c = 'Dart - Zone' );
            insert c1;

            controller = new TargetingTreeSelectionController();
            controller.selectedContent = c.id;
            controller.addContent();

            controller.selectedContent = c1.id;
            controller.addContent();

            controller.saveRecords();

            //String contentString = controller.contentString;
            Boolean isShowCancel = controller.isShowCancel;

            //controller.getMoreChildContentValue();
            //List<TargetingTreeSelectionController.DTOTreeItem> listdtochild = controller.getLstChild(testDATA.contents[0].Id, new Set<String>());
            //system.assertEquals(1, listdtochild.size());

            controller.resetTree();

        Test.stopTest();
}


    //------- Targeting Configuration -------------------//
    @isTest static void testTargetingConfiguration(){
        		UTIL.isRunningTestSetup = true;
                User currentUser = [ select Id from User where Id = :UserInfo.getUserId() ];
                //User userAdmin;
                User userAdmin = [ select id from User where Username='testUser1@boco.com' limit 1];
                Account acc;

                System.runAs ( currentUser ) {
                /** Profile p=[Select Id From Profile Where Name='System Administrator'  or Name='Systemadministrator' Limit 1];
                    userAdmin = GW_User.createTestUser(p);
                    userAdmin.Username='testUser1111@boco.com';//userAdmin.Username='testUser1@boco.com';
                    userAdmin.LastName='testLastName1';
                    userAdmin.Email='testEmail1@boco.com';
                    userAdmin.Alias='test1';
                    userAdmin.TimeZoneSidKey='Pacific/kiritimati';
                    userAdmin.LocaleSidKey='ar';
                    userAdmin.EmailEncodingKey='UTF-8';
                    userAdmin.ProfileId=p.Id;
                    userAdmin.LanguageLocaleKey='en_US';
                    insert userAdmin; **/

                    acc = new Account(name='Test Account Test class',ownerId= userAdmin.id);
                    insert acc;
                }

                MemberUnit__c mu = [SELECT Id FROM MemberUnit__c WHERE Name = 'Test member unit' AND LineOfBusiness__c = 'AD'];
                Opportunity  opp1 = new Opportunity( MemberUnit__c=mu.Id, name='Test', closeDate= system.today(), stageName='test', AccountId= acc.id );
                system.runAs(userAdmin){
                    insert opp1;
                }

                testDATA.createSite(new Set<String>{'US'});
                Product2 prod = new Product2( Name='Test Ad Spec', Site__c = testDATA.sites[0].Id);
                insert prod;

                DART_KeyValue_2__c key1=  new DART_KeyValue_2__c( Name='TestKey1', Key__c='TSK1',  Key_Value_Name__c='TestKey1');
                insert key1;

                DART_KeyValue_2__c key2=  new DART_KeyValue_2__c( Name='TestKey2', Key__c='TSK2',  Key_Value_Name__c='TestKey2',Key_Value__c='TestKey2', Node_ID__c= key1.id);
                insert key2;

                DART_KeyValue_2__c key3=  new DART_KeyValue_2__c( Name='TestKey3', Key__c='TSK3',  Key_Value_Name__c='TestKey3' ,Key_Value__c='TestKey3', Node_ID__c= key2.id);
                insert key3;


                Targeting__c t = new Targeting__c(TempBinder__c = true);
                insert t;

                List<TargetingKeyValueAssociation__c> lstKeyAss = new List<TargetingKeyValueAssociation__c>();
                lstKeyAss.add( new TargetingKeyValueAssociation__c(Targeting__c = t.id , DART_KeyValue__c   = key1.id , Operator__c= 'OR', targetkeyvalue__c =  (t.id +''+ key1.id )));
                lstKeyAss.add( new TargetingKeyValueAssociation__c(Targeting__c = t.id , DART_KeyValue__c   = key2.id , Operator__c= 'OR', targetkeyvalue__c = (t.id + ''+key2.id)));
                lstKeyAss.add( new TargetingKeyValueAssociation__c(Targeting__c = t.id , DART_KeyValue__c   = key3.id , Operator__c= 'OR', targetkeyvalue__c = (t.id + ''+key3.id)));
                insert lstKeyAss;

                Available_Site__c avai = new Available_Site__c(Product__c = prod.Id);
                Available_Site__c avai2 = new Available_Site__c(Product__c = prod.Id);
                insert new List<Available_Site__c>{avai, avai2};

                testDATA.getPricebook2();
                PricebookEntry pbe1 = new PricebookEntry(UseStandardPrice = false, Product2Id = prod.Id, Pricebook2Id = testDATA.standardPbId, UnitPrice = 1.00, IsActive=true, CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY);
                insert pbe1;



                Test.startTest();

        		OpportunityLineItem oppItem = new OpportunityLineItem(
                                                   opportunityId = opp1.id,
                                                   from_Date__c =  system.today(),
                                                   until_Date__c = system.today().addDays(7),
                                                   Quantity = 1,
                                                   TotalPrice = 0.01,
                                                   PricebookEntryId = pbe1.id,
                                                   Billing_category__c = 'CPM',
                                                   Description = 'item test'
                                                   );

                insert oppItem;


                Pagereference pg = Page.TargetingConfiguration;
                Test.setCurrentPageReference(pg);
                pg.getParameters().put('pos','0');

                    TargetingConfiguration controller =  new TargetingConfiguration();
                    controller.saveRecords();

                    pg.getParameters().put('proId', prod.id);
                    pg.getParameters().put('targetId', t.id);
                    pg.getParameters().put('oppId',opp1.id);
                    pg.getParameters().put('itemId',oppItem.id);
                    controller =  new TargetingConfiguration();

                    prod.Available_Key_Values__c='TestKey1';
                    update prod;

                    controller = new TargetingConfiguration();
                    controller.selectedKey= key1.id;
                    controller.getChildValue();

                    List<TargetingConfiguration.DTOItem> lstObject = new List<TargetingConfiguration.DTOItem>();
                    TargetingConfiguration.DTOItem childItem = new TargetingConfiguration.DTOItem('test',key1.id ,'Test', null);
                    childItem.lstChild.add(new TargetingConfiguration.DTOItem('test',key2.id ,'Test', null));
                    lstObject.add(childItem);

                    List<TargetingConfiguration.DTOSaveKeyValue> lstKeySave = new List<TargetingConfiguration.DTOSaveKeyValue>();
                    lstKeySave.add(new TargetingConfiguration.DTOSaveKeyValue(0,'Test', key1.id, 'test','test') );
                    controller.saveTargetingJson =  JSON.serialize(lstKeySave);
                    controller.jsonObject=   JSON.serialize(lstObject);
                    controller.saveRecords();
                    Boolean isHaveLv2 = controller.isHaveItem;

                    controller = new TargetingConfiguration();
                    controller.isTakeOverDes = true;
                    controller.lineDesc ='testtttttt';
                     controller.saveRecords();

                 Test.stopTest();

        		UTIL.isRunningTestSetup = false;
             }


    private static Targeting__c targ;
    private static OpportunityLineItem lineItem;
    private static OpportunityLineItem lineItem2;
    private static Product2 pro;

    private static void setupContentData() {

        //testDATA.createAccount();
        ///Account acc = testDATA.lstAcc[0];
        Account acc = [select Id from Account where Name='Test Acc0' limit 1];
        User userAdmin = [ select id from User where Username='testUser1@boco.com' limit 1];

        //create content top level
        Content__c con = new Content__c(Name = '90802222', DartName__c = 'Adunit 1', DFPEXTID__c = '90802222', Active__c = true);
        insert con;

        //create content level 2
        List<Content__c> l2cons = new List<Content__c>();
        for (Integer i = 0; i < 5; i++) l2cons.add(new Content__c(Active__c = true, Name = '908022'+i, DartName__c = 'Adunit 2_'+i, Site_Content_Category__c = con.Id, DFPEXTID__c = '908022'+i));
        insert l2cons;

        //create contents level 3
        List<Content__c> l3cons = new List<Content__c>();
        for (Integer i = 5; i < 15; i++) l3cons.add(new Content__c(Active__c = true, Name = '908022'+i, DartName__c = 'Adunit 3_'+i, Site_Content_Category__c = l2cons[0].Id, DFPEXTID__c = '908022'+i));
        insert l3cons;

        pro = new Product2(Name = 'TestProductfroContentTree', IsActive = true, Content__c = con.Id, PredifinedAdunit__c = l2cons[0].Id);
        insert pro;

        Contact contac = new Contact(LastName = 'TestConn', Email='contacteTest0023@testorg.com', FirstName = 'TestFirstName', Title = 'Mr', Salutation = 'Mr');
        insert contac;

        //get pricebook2
        //*testDATA.getPricebook2();

        MemberUnit__c mu = [SELECT Id FROM MemberUnit__c WHERE Name = 'Test member unit' AND LineOfBusiness__c = 'AD']; 

        Opportunity opp2 = new Opportunity();
        opp2.Pricebook2Id = Test.getStandardPricebookId(); //testDATA.standardPbId;
        opp2.Name = 'Test Opp';
        opp2.AccountId = acc.Id;
        opp2.CloseDate = Date.today().addMonths(10);
        opp2.StageName = 'Draft';
        opp2.CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY;
        opp2.MemberUnit__c = mu.Id; //Assign MU manually 

        system.runAs(userAdmin){    //system.runAs(TestDataGenerator.userAdmin){
            insert opp2;
        }

        //create pricebookentry
        PricebookEntry pbe = new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = pro.Id, UnitPrice = 1.00, IsActive = true);
                pbe.CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY;
                insert pbe;

        //create lineitem
        lineItem = new OpportunityLineItem( OpportunityId = opp2.Id, Quantity = 100, TotalPrice = 10000.0, PricebookEntryId = pbe.Id, Description = 'Test@ContentTree');
        insert lineItem;

        targ = new Targeting__c(Description__c = 'Targeting@ContentTree');
        insert targ;

        lineItem2 = new OpportunityLineItem( OpportunityId = opp2.Id, Quantity = 100, TotalPrice = 10000.0, PricebookEntryId = pbe.Id, Description = 'Test2@ContentTree', Targeting__c = targ.Id);
        insert lineItem2;
    }

     @isTest static void testInitContentTree() {
        setupContentData();

        Pagereference pg = Page.TargetingTreeSelection;
        Test.setCurrentPageReference(pg);
        Test.startTest();
            //case no targaeting
            TargetingTreeSelectionController controller = new TargetingTreeSelectionController();
            System.assertEquals(controller.content.treeLv, 1);
            System.assertEquals(controller.content.treeId, 'NoContent');

            //Test case load content with targetId is specified
            //need to select all set up data to avoid null pointer
            String targetId = targ.Id;
            String contentId = [Select Id From Content__c Where Name = '90802222'].get(0).Id;
            List<Content__c> listConts = [Select Id From Content__c Where Site_Content_Category__c =: contentId];
            TargetingContentAssociation__c tca = new TargetingContentAssociation__c(Targeting__c = targetId, TargetingContent__c = listConts[0].Id, Target_Content_Key__c = targetId+listConts[0].Id+'');
            insert tca;

            Product2 pr = new Product2(Id = pro.Id);
            pr.Content__c = null;
            update pr;

            pg.getParameters().put('targetId', targetId);
            pg.getParameters().put('proId', pr.Id);
            controller = new TargetingTreeSelectionController();
            System.assertEquals(controller.content.treeLv, 1);
            System.assertEquals(controller.content.treeId, 'NoContent');

            //
            String toplevelId = [Select Id From Content__c Where Name = '90802222' limit 1].get(0).Id;
            pr.Content__c = toplevelId;
            update pr;
            controller = new TargetingTreeSelectionController();
            System.assertEquals(controller.content.treeId, toplevelId);
        Test.stopTest();
    }

    @isTest static void testSaveContentTree() {
        setupContentData();

        Pagereference pg = Page.TargetingTreeSelection;
        Test.setCurrentPageReference(pg);
        Test.startTest();
            String targetId = targ.Id;
            String contentId = [Select Id From Content__c Where Name = '90802222'].get(0).Id;
            List<Content__c> listConts = [Select Id From Content__c Where Site_Content_Category__c =: contentId];
            TargetingContentAssociation__c tca = new TargetingContentAssociation__c(Targeting__c = targetId, TargetingContent__c = listConts[0].Id, Target_Content_Key__c = targetId+listConts[0].Id+'');
            insert tca;

            pg.getParameters().put('targetId', targetId);
            pg.getParameters().put('proId', pro.Id);
            TargetingTreeSelectionController controller = new TargetingTreeSelectionController();

            String itemId = [Select Id From OpportunityLineItem Where Description = 'Test@ContentTree' limit 1].get(0).Id;
            pg.getParameters().put('targetId', null);
            pg.getParameters().put('itemId', itemId);
            //do select content on the tree
            controller.convertJsonToDTOTreeItem();
            for (TargetingTreeSelectionController.DTOTreeItem dto : controller.content.lstChild)
                dto.isSelected = true;
            controller.convertDTOTreItemToJson();

            controller.targetId = null;
            controller.saveRecords();
            Boolean showCancel = controller.isShowCancel;
        Test.stopTest();
    }

     @isTest static void testSearchContentTree() {
        setupContentData();

        Pagereference pg = Page.TargetingTreeSelection;
        Test.setCurrentPageReference(pg);
        Test.startTest();
            String targetId = targ.Id;
            pg.getParameters().put('targetId', targetId);
            pg.getParameters().put('proId', pro.Id);
            TargetingTreeSelectionController controller = new TargetingTreeSelectionController();
            List<Content__c> results = TargetingTreeSelectionController.searchContent('Adunit', controller.content.treeId);
            System.assertEquals(16, results.size(), 'All conents were created with the name contains "Adunit"');
        Test.stopTest();
    }

    @isTest static void testShowmore() {
        setupContentData();

        Pagereference pg = Page.TargetingTreeSelection;
        Test.setCurrentPageReference(pg);
        Test.startTest();
            String targetId = targ.Id;
            pg.getParameters().put('targetId', targetId);
            pg.getParameters().put('proId', pro.Id);
            TargetingTreeSelectionController controller = new TargetingTreeSelectionController();
            String contentId = [Select Id From Content__c Where Name = '90802222'].get(0).Id;
            List<Content__c> listConts = [Select Id From Content__c Where Site_Content_Category__c =: contentId];
            controller.selectedContent = listConts[0].Id;
            controller.showMore();
        Test.stopTest();
    }
}