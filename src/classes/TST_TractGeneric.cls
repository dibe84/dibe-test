@isTest
public class TST_TractGeneric {
    
    @testSetup
    public static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();

        List<Webservice_Settings__c> wss = new List<Webservice_Settings__c>();
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        insert wss;

        //Create Product2 
        Product2 prod = GW_Product.insertSObject('Test Prod-1');
        //Assign Tract Id
        prod.Tract_Id__c = 'Tract12345';
        update prod;
    
        //Create PBE
        PricebookEntry pbe = GW_Product.insertPricebookEntry(prod, new Pricebook2(Id=Test.getStandardPricebookId()), 100.0);
        
        //Create PBE
        /* END Additional Test Data */
        UTIL_CustomJob.createMissingCustomJobs();
        UTIL.isRunningTestSetup = false;
    }
    
    /** Test for SchAdxImportMetrics.cls */
    static testMethod void test_SchAdxImportMetrics() {
        Test.startTest();
            SchAdxImportMetrics s = new SchAdxImportMetrics();
            s.execute(null);
            SchAdxImportMetrics.start();
        Test.stopTest();
        
    }
    
    /** Test for PGC_PlacementCalendar.cls */
    static testMethod void test_PGC_PlacementCalendar() {
        Opportunity opp = [select id from Opportunity limit 1];
        Test.setCurrentPageReference(new PageReference('PlacementCalendar')); 
        System.currentPageReference().getParameters().put('opportunityId', opp.id);
        Test.startTest();
            PGC_PlacementCalendar con = new PGC_PlacementCalendar();
            con.buildCalendar();
            con.doBuildCalendar( new List<Rev__c>(), system.today(), system.today().addDays(30));
            con.removeRevsFromPoolEndedOnDate(system.today(), new Set<Rev__c>());
            con.buildWaitPool(new List<Rev__c>(), null);
            
            PGC_PlacementCalendar.CalendarItem conC = new PGC_PlacementCalendar.CalendarItem(system.today(), new Set<Rev__c>());
        Test.stopTest();
        
    }
    
    /** Test for PGC_PermissionGroups.cls */
    static testMethod void test_PGC_PermissionGroups() {
        Test.startTest();
            PGC_PermissionGroups con = new PGC_PermissionGroups();
            con.applyChanges();
            con.applyUserChanges();
            con.applyFilter();
            con.getGraphBuilderString();
            Object o = con.apexPermissionGroupList;
            PGC_PermissionGroups.Action conA = new PGC_PermissionGroups.Action(new User());
        Test.stopTest();
        
    }
    
    /** Test for c_Login.cls, c_DefaultContactController.cls, c_DefaultHomeController.cls, c_URLRewriter.cls, ......*/
    static testMethod void test_c_DefaultContactController() {
        Test.startTest();
            
            Test.setCurrentPageReference(new PageReference('c_Login')); 
            System.currentPageReference().getParameters().put('startURL', 'test.com');
            System.currentPageReference().getParameters().put('display', 'test');
            c_Login cc = new c_Login();
            cc.forwardToAuthPage();
            
            Object o = new c_DefaultContactController();
            o = new c_DefaultHomeController();
            
            c_URLRewriter wr = new c_URLRewriter();
            wr.mapRequestUrl(new PageReference('c_Login'));
            
            //c_DefaultTemplate dt = new c_DefaultTemplate();
            c_ExceptionController ec = new c_ExceptionController();
            c_DefaultProfileController dpc = new c_DefaultProfileController();      

        Test.stopTest();
        
    }
    
    /** Test for Util_Lookup.cls */
    static testMethod void test_Util_Lookup() {
        Member__c createdMember = [ SELECT Id FROM Member__c LIMIT 1 ];
        Test.startTest();
            Util_Lookup.queryListLookup('Contact', 'test', new List<String>{'Name'}, 1, '');
            Util_Lookup.queryLookupItem(createdMember.id, 'Member__c');
        Test.stopTest();
        
    }
    
    /** Test for ChatterAnswersAuthProviderRegistration.cls */
    static testMethod void test_ChatterAnswersAuthProviderRegistration() {
        
        Test.startTest();
            ChatterAnswersAuthProviderRegistration a = new ChatterAnswersAuthProviderRegistration();
            a.getSiteAdminUserId();
            a.createUser(null, null);
            //a.updateUser(null, null, null);
        Test.stopTest();
        
    }
    
    /** Test for LSC_SiteUserController.cls */
    static testMethod void test_LSC_SiteUserController() {
        Member__c createdMember = [ SELECT Id FROM Member__c LIMIT 1 ];
        MemberUnit__c createdMemberUnit = [ SELECT Id FROM MemberUnit__c LIMIT 1 ];
        
        List<Object>lstContatDetails = new List<Object>{
            new Map<String, Object>{ 'name' => 'LastName', 'value' => 'testCon' }   
        };
        
        List<Object>lstAccountDetails = new List<Object>{
            new Map<String, Object>{ 'name' => 'Name', 'value' => 'testAcc' }   
        };
        String contactDetail = JSON.serialize(lstContatDetails);
        String accountDetail = JSON.serialize(lstAccountDetails);
            
        Test.startTest();
            LSC_SiteUserController con = new LSC_SiteUserController();
            
            LSC_SiteUserController.doRegisterUser( contactDetail, accountDetail, null, createdMemberUnit.Id, '', '' );
            LSC_SiteUserController.createLead( contactDetail, null, createdMemberUnit.Id, 'Goods');
            LSC_SiteUserController.deleteLead('');
            LSC_SiteUserController.checkExistingUser('axu@test.com');
            LSC_SiteUserController.getExistingInfo('Name', 'axu@test.com');
            LSC_SiteUserController.queryMemberUnit('EBAYK');
        Test.stopTest();
    }
    
    /** Test for SiteUserRegistration.cls */
    static testMethod void test_SiteUserRegistration() {
        Member__c createdMember = [ SELECT Id FROM Member__c LIMIT 1 ];
        MemberUnit__c createdMemberUnit = [ SELECT Id FROM MemberUnit__c LIMIT 1 ];
        
        List<Object>lstContatDetails = new List<Object>{
            new Map<String, Object>{ 'name' => 'LastName', 'value' => 'testCon' }   
        };
        
        List<Object>lstAccountDetails = new List<Object>{
            new Map<String, Object>{ 'name' => 'Name', 'value' => 'testAcc' }   
        };
        String contactDetail = JSON.serialize(lstContatDetails);
        String accountDetail = JSON.serialize(lstAccountDetails);
            
        Test.startTest();
            SiteUserRegistration con = new SiteUserRegistration();
            
            SiteUserRegistration.doRegisterUser( contactDetail, accountDetail, null);
            SiteUserRegistration.createLead( contactDetail, null, createdMemberUnit.Id);
            SiteUserRegistration.deleteLead('');
            SiteUserRegistration.checkExistingUser('axu@test.com');
            SiteUserRegistration.getExistingInfo('Name', 'axu@test.com');
        Test.stopTest();
    }
    
    /** Test for TSTDF_BulkDataSet.cls and TST_DataSet.cls*/
    static testMethod void test_TSTDF_BulkDataSet() {
        Test.startTest();
            TSTDF_BulkDataSet df = new TSTDF_BulkDataSet(new TSTDF_BulkDataSet.Config());
            df.getSObjectByRef('test');
            TST_DataSet ds = new TST_DataSet();
        Test.stopTest();
    }
    
    /** Test for LC_SalesPathSummaryWindow.cls */
    static testMethod void test_LC_SalesPathSummaryWindow() {
        Opportunity opp = [select id from Opportunity limit 1];
        Test.startTest();
            LC_SalesPathSummaryWindow.getAllItemsStatus(opp.id);
            LC_SalesPathSummaryWindow.checkExistingTopic(new List<String>());
            //LC_SalesPathSummaryWindow.doForceBookingPushTract(opp.id);
            LC_SalesPathSummaryWindow.doForceOrderTract(opp.id);
            //LC_SalesPathSummaryWindow.doForceAccountSentToPlatform(opp.id);
        Test.stopTest();
    }
    
    /** Test for WSI_Opportunity.cls */
    static testMethod void test_WSI_Opportunity() {
        Account billingAcc = GW_Account.createSObject();
        billingAcc.Status__c = 'Ready To Sell';
        insert billingAcc;
        
        Opportunity opp = [select id from Opportunity limit 1];
        opp.Billing_Account__c = billingAcc.id;
        update opp;
        
        Test.startTest();
            WSI_Opportunity.sendForApproval(opp.id);
            WSI_Opportunity.sendForApproval(null);
        Test.stopTest();
    }
    /** Test for HNDL_Rule.cls and GW_Rule.cls */
    static testMethod void test_GW_Rule() {
        Rule__c rule = new Rule__c(Name = 'TST_CodeCoverage');
        Test.startTest();
            insert rule;
            GW_Rule.getRecord(rule.id); 
            GW_Rule.getAll();   
            GW_Rule.getAllAssociations();   
        Test.stopTest();
    }
    
    /** Test for WSI_API_SFECG_v1.cls */
    static testMethod void test_WSI_API_SFECG_v1() {
        RestRequest req = new RestRequest();
        req.requestURI = '/api/v1/accounts';
        req.requestBody = Blob.valueOf('{}');
        RestResponse res = new RestResponse();
        Test.startTest();
            WSI_API_SFECG_v1.process('AccountUpdate', new WSI_CTRL.APIResponse(req, res));
        Test.stopTest();
    }
    
    /** Test for BAT_AccountValidationAndEnrichment.cls */
    static testMethod void test_BAT_AccountValidationAndEnrichment() {
        List<Account> accs = GW_sObject.queryRecords('Account', '');
        try {
            Test.startTest();
            GW_Account.batchAccountValidationAndEnrichment(accs);
            Test.stopTest();
        } catch (Exception ex) {
            return; // some accounts created for testing are not validated
        }
        system.assert(false); // this line will never reached.
    }
    
    /** Test for BAT_ProductImportFromTRACT **/
    @isTest static void test_BAT_ProductImportFromTRACT () {

        Test.startTest();
            BAT_ProductImportFromTRACT bat = new BAT_ProductImportFromTRACT();
            bat = new BAT_ProductImportFromTRACT(new Set<String>(), null, '1');
            Database.executeBatch(bat);
        Test.stopTest();
    }

    
    /** Test for BAT_SyncOliStatus **/
    @isTest static void test_BAT_SyncOliStatus () {

        Test.startTest();
            UTIL_CustomJob.createMissingCustomJobs();
            UTIL_CustomJob.startCustomJob('BAT_SyncOliStatus');
        Test.stopTest();

    } 
    
    /** Test for LC_SalesPathSummaryWindow ( To Be Investigated ) **/
    /*@isTest static void test_LC_SalesPathSummaryWindow () {

        
        TST_DataFactory fac = TST_DataFactory.getInstance();
        fac.queryResults();

        System.debug('###MN - opp :: ' + fac.opp);
        System.debug('###MN - acc :: ' + fac.acc);

        List<WS_ScheduledCallout__c> lstwss = new List<WS_ScheduledCallout__c>();
        lstwss.add(new WS_ScheduledCallout__c(RecordId__c=fac.acc.Id, method__c = 'AccountPush', status__c='done'));
        lstwss.add(new WS_ScheduledCallout__c(RecordId__c=fac.opp.Id, method__c = 'BookingPushTract', status__c='done'));
        lstwss.add(new WS_ScheduledCallout__c(RecordId__c=fac.opp.Id, method__c = 'OrderTract', status__c='done'));
        insert lstwss;
        System.debug('###MN - lstwss :: ' + lstwss);

        List<WS_Log__c> lstWSLogs = new List<WS_Log__c>();
        for (WS_ScheduledCallout__c wss : lstwss) {
            lstWSLogs.add(new WS_Log__c(Status__c='test',ScheduledCallout__c=wss.Id,CalloutName__c='test'));
        }
        insert lstWSLogs;

        LC_SalesPathSummaryWindow ctrl = new LC_SalesPathSummaryWindow();

        Test.startTest();

        String strReturn;

        //@method getOppApprovedStatus()
        strReturn = LC_SalesPathSummaryWindow.getOppApprovedStatus(fac.opp.Id);
        System.assert( strReturn.equalsIgnoreCase('false') );

        //@method getContractSignedStatus()
        strReturn = LC_SalesPathSummaryWindow.getContractSignedStatus(fac.opp.Id);
        System.assert( strReturn.equalsIgnoreCase('false') );

        //@method getAccSentToLocalPlatformStatus()
        strReturn = LC_SalesPathSummaryWindow.getAccSentToLocalPlatformStatus(fac.opp.Id);
        System.assert( strReturn.equalsIgnoreCase('test') );

        //@method getBookingSentToLocalPlatformStatus()
        strReturn = LC_SalesPathSummaryWindow.getBookingSentToLocalPlatformStatus(fac.opp.Id);
        System.assert( strReturn.equalsIgnoreCase('test') );

        //@method getBookingSentToTractStatus()
        strReturn = LC_SalesPathSummaryWindow.getBookingSentToTractStatus(fac.opp.Id);
        System.assert( strReturn.equalsIgnoreCase('test') );

        Test.stopTest();        
    }*/

    /** Test for HNDL_WS_Log **/
    @isTest static void test_HNDL_WS_Log () {

        TST_DataFactory fac = TST_DataFactory.getInstance();
        fac.queryResults();

        List<WS_ScheduledCallout__c> lstwss = new List<WS_ScheduledCallout__c>();
        lstwss.add(new WS_ScheduledCallout__c(RecordId__c=fac.acc.Id, method__c = 'AccountPush', status__c='done'));
        insert lstwss;
        

        Test.startTest();

        //Scenario-1 : Insert
        List<WS_Log__c> lstWSLogs = new List<WS_Log__c>();
        for (WS_ScheduledCallout__c wss : lstwss) {
            lstWSLogs.add(new WS_Log__c( Status__c='test', ScheduledCallout__c=wss.Id, CalloutName__c='AccountPush', Success__c=TRUE, ParentId__c=fac.acc.Id));
        }
        insert lstWSLogs;


        //Scenario-2 : Update
        update lstWSLogs;

        Test.stopTest();
    }
    
    /** Test for GW_WS_Log **/
    @isTest static void test_GW_WS_Log () {

        TST_DataFactory fac = TST_DataFactory.getInstance();
        fac.queryResults();
        
        Test.startTest();
        List<WS_ScheduledCallout__c> lstwss = new List<WS_ScheduledCallout__c>();
        lstwss.add(new WS_ScheduledCallout__c(RecordId__c=fac.acc.Id, method__c = 'AccountPush', status__c='done'));
        insert lstwss;
        
        List<WS_Log__c> lstWSLogs = new List<WS_Log__c>();
        for (WS_ScheduledCallout__c wss : lstwss) {
            lstWSLogs.add(new WS_Log__c( Status__c='test', ScheduledCallout__c=wss.Id, CalloutName__c='AccountPush', Success__c=TRUE, ParentId__c=fac.acc.Id));
        }
        insert lstWSLogs;

        Test.stopTest();

            //@method: getRecord()
            WS_Log__c log = GW_WS_Log.getRecord(lstWSLogs[0].Id);
            System.assertNotEquals(NULL, log);
            System.assertEquals('AccountPush', log.CalloutName__c);

            //@method: getMap()
            Map<id,WS_Log__c> logMap = GW_WS_Log.getMap(new Set<Id>{lstWSLogs[0].Id});
            System.assert( logMap.containsKey(lstWSLogs[0].Id) );

            //@method: getList()
            List<WS_Log__c> logList = GW_WS_Log.getList(new Set<Id>{lstWSLogs[0].Id});
            System.assertNotEquals( 0, logList.size() );            

        
    }
    

    
    /** Test for WSC_THBELAU_OPENIBAN.cls */
    static testMethod void WSC_THBELAU_OPENIBAN_Test() {
       
        WSC_THBELAU_OPENIBAN wscOpenIbanObj = new WSC_THBELAU_OPENIBAN();
        
        Test.startTest();
        WSC_THBELAU_OPENIBAN.OpenIBANResponse res = wscOpenIbanObj.BankAccountDetailsGet('testIBAN');
        Test.stopTest();
        
        system.assertEquals('NL67ABNA0628492812', res.IBAN);
    }
    
    /** Test for Catalyst_ProductConfigureRedirectorCon.cls */
    static testMethod void Catalyst_ProductConfigureRedirectorCon_Test(){
        
        list<Opportunity> lstOpp = (list<Opportunity>) GW_sObject.queryRecords('Opportunity','');
        Opportunity opp = lstOpp.get(0); 
         
        ApexPages.StandardController stdCont = new ApexPages.StandardController(opp);
        
        Test.startTest();
        Catalyst_ProductConfigureRedirectorCon cont = new Catalyst_ProductConfigureRedirectorCon(stdCont);
        cont.getBaseURL();
        Test.stopTest();
        
    }
    
     /** Test for PGC_AccountCustomAttributes.cls */ 
    static testMethod void PGC_AccountCustomAttributes_Test(){
        
        list<Account> lstAcc = (list<Account>) GW_sObject.queryRecords('Account','');      
        Account acc = lstAcc.get(0);
        
        // Create custome attribute for account
        TST_DataFactory.createMemberUnit(acc.id);
        List<MemberUnit__c> testMUList = [SELECT Id, Name FROM MemberUnit__c];
        
        CustomAttributeDefinition__c cad =TST_DataFactory.createCustomAttributeDefinition(testMUList.get(0).Id,'Account','String');
        
        TST_DataFactory.createCustomAttributeForAccount(cad, 'testKey', acc.id);
          
        ApexPages.StandardController stdCont = new ApexPages.StandardController(acc);
        
        Test.startTest();
        PGC_AccountCustomAttributes cont = new PGC_AccountCustomAttributes(stdCont);
        cont.save();
        Test.stopTest();
    } 
    
     /** Test for WS_UI.cls */ 
    static testMethod void WS_UI_EBAYKRE_SendFTPEmail_Test(){
  
        list<Account> lstAcc = (list<Account>) GW_sObject.queryRecords('Account','');      
        Account acc = lstAcc.get(0); 
        
        Test.startTest();
        string result = WS_UI.EBAYKRE_SendFTPEmail(acc.id);
        Test.stopTest();
    }
    
    static testMethod void WS_UI_EBAYKRE_signOpportunity_Test(){
       
        list<Opportunity> lstOpp = GW_sObject.queryRecords('Opportunity','');    
        Opportunity opp = lstOpp.get(0); 
        
        Test.startTest();
        string result = WS_UI.signOpportunity(opp.id);
        Test.stopTest();
    }
    
    /** Test for VIESVATCheckController.cls */
    static testMethod void VIESVATCheckController_Test(){ 
        
        VIESVATCheckController cont = new VIESVATCheckController();
        VIES.VATCheck vatCheckObj = cont.getVATCheck();
        vatCheckObj.vatID = 'DE812639372';
        vatCheckObj.vatNumber = '812639372';
        vatCheckObj.countryCode = 'DE';
        
        Test.startTest();
        cont.validate();
        String status = cont.getStatus(); 
        Test.stopTest();
        
        system.assertEquals('COMPLETED', status);      
    }
    
    /** Test for PGC_AdjustRevenueDates.cls */
    static testMethod void PGC_AdjustRevenueDates_Test(){
       
        list<OpportunityLineItem> lstOlitem = [select id, OpportunityId, from_Date__c, Until_Date__c, SalesPriceNet__c, AdOperatingSystems__c,   
                       Keywords_KeyValue_combination__c, KeyValueString__c, AdWebBrowsers__c, Ad_Id__c, Adserver_ID_Order_ID__c, AdKeywords__c, 
                       PriceBookEntry.Product2.Fixed_Site__c, Targeting__c, PricebookEntry.Product2.RecordType.Name, PriceBookEntry.Product2.Site__r.Country__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c, Ad_Name__c, Device_Targeting__c, AdDayOfWeek__c, AdHourOfDay__c,
                       AdBrowsersMinorVersion__c, AdBrowsersMajorVersion__c, CurrencyIsoCode, PriceBookEntry.Product2.Target_Platform__c, Billing_Category__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdType__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_Prio__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_Product_Type__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_MasterSize__c,
                       Quantity, Description, FC_Period__c, FC_Ad_served_every__c, FC_Quantity__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_CompanionSize__c, PriceBookEntry.Product2.Name
                       from OpportunityLineItem];
        
        OpportunityLineItem oppItem = lstOlitem.get(0);
                       
        Rev__c rev = new Rev__c();
        rev.OpportunityLineItemId__c    = oppItem.id;
        rev.Opportunity__c              = oppItem.OpportunityId;
        rev.Product__c                  = oppItem.PriceBookEntry.Product2Id;
        rev.from_Date__c                = oppItem.from_Date__c;
        rev.until_Date__c               = oppItem.until_Date__c; // default copies from items[0]
        rev.BillingCategory__c          = oppItem.Billing_Category__c;
        rev.QuantityBooked__c           = oppItem.Quantity;
        rev.ExtLineItemId__c            = oppItem.Ad_Id__c + 'test';
        rev.ExtOrderId__c               = oppItem.Adserver_ID_Order_ID__c + 'test';
        upsert rev OpportunityLineItemId__c;

        Test.startTest();
        Test.setCurrentPageReference(new PageReference('AdjustRevenueDates')); 
        System.currentPageReference().getParameters().put('id', oppItem.OpportunityId);
        PGC_AdjustRevenueDates cont = new PGC_AdjustRevenueDates();
        cont.save();
        Test.stopTest();
    }
    
     /** Test for VAL_Global.cls */
    static testMethod void VAL_Global_validate_Test(){
        
        list<Account> lstAcc = (list<Account>) GW_sObject.queryRecords('Account','');      
        Account acc = lstAcc.get(0); 
        
        TST_DataFactory.createMemberUnit(acc.id);
        MemberUnit__c mu = [select Id, name from MemberUnit__c where Name = 'Test member unit' limit 1];
        
        TST_DataFactory.createAccountMemberUnitAssociation(mu.id, acc.id);
        
        FieldValidation__c fv = new FieldValidation__c(
            Active__c = true,
            Name = 'Global_Account_MemberUnit',
            Object__c = 'Account',
            Scope__c = 'Global',
            delegatedValidator__c = null,
            ErrorMessage__c = 'Account MemberUnit could not be null',
            FieldName__c = '.MemberId__c',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 1,
            MandatoryValue__c = '',
            Param__c = 'AD',
            Regex__c = null
        ); 
        insert fv;
        
        Test.startTest();
        VAL_Global.AccountCustomAttributeValidator accVal = new VAL_Global.AccountCustomAttributeValidator();
        accVal.validate( acc , fv);
        Test.stopTest();
    } 
    
    /** Test for PGC_MandateExtension.cls **/
    @isTest 
    static void test_PGC_MandateExtension() {
        
        Test.startTest();

            TST_DataFactory factory = TST_DataFactory.getInstance();
            factory.queryResults();

            //create echosign_dev1__SIGN_Agreement__c record
            MemberUnit__c createdMemberUnit = [ SELECT Id, Name FROM MemberUnit__c LIMIT 1 ];
            
            echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c();
            agreement.Name = 'test agreement';
            agreement.echosign_dev1__Account__c = factory.acc.Id;
            agreement.MemberUnit__c = createdMemberUnit.Id;
            insert agreement;

            //create standard controller passing echosign_dev1__SIGN_Agreement__c record as param
            ApexPages.StandardController sc = new ApexPages.StandardController( agreement );

            //create instance of PGC_MandateExtension passing standard controller as param
            PGC_MandateExtension mandate = new PGC_MandateExtension( sc );
            
            System.assertEquals( agreement.Id, mandate.agreement.Id );
            System.assertEquals( createdMemberUnit.Id, mandate.memberUnit.Id );

        Test.stopTest();
    }
    
    /** Test for PGC_OpportunityProductEditButtonRedirect.cls **/
    @isTest
    static void test_PGC_OpportunityProductEditButtonRedirect(){

        Test.startTest();

        // create page reference
        PageReference pageRef = Page.OpportunityProductEditButtonRedirect;
        Test.setCurrentPageReference( pageRef );

        // get opportunity line item
        System.debug( 'Opportunity Line Item ==> ' + [ SELECT Id FROM OpportunityLineItem ] );
        OpportunityLineItem createdOpportunityLineItem = [ SELECT Id From OpportunityLineItem LIMIT 1 ];
        
        // set opportunity line item as page param
        pageRef.getParameters().put( 'Id', createdOpportunityLineItem.Id );

        // create instance of class PGC_OpportunityProductEditButtonRedirect
        ApexPages.StandardController sc = new ApexPages.StandardController( createdOpportunityLineItem );
        PGC_OpportunityProductEditButtonRedirect btnRedirect = new PGC_OpportunityProductEditButtonRedirect( sc );

        PageReference pageReturn = btnRedirect.redirect();

        Test.stopTest();
    }

    
    /** Test for UTIL_LandingPageLink.cls **/
    @isTest
    static void test_UTIL_LandingPageLink(){

        Test.startTest();

        TST_DataFactory factory = TST_DataFactory.getInstance();
        factory.queryResults();

        // get member and member unit created record
        Member__c createdMember = [ SELECT Id FROM Member__c LIMIT 1 ];
        MemberUnit__c createdMemberUnit = [ SELECT Id FROM MemberUnit__c LIMIT 1 ];
        
        // create campaign record
        Campaign newCampaign = new Campaign();
        newCampaign.Name = 'test campaign';
        newCampaign.Member__c = createdMember.Id;
        newCampaign.MemberUnit__c = createdMemberUnit.Id;
        insert newCampaign;
        
        // create lead
        Lead newLead = new Lead();
        newLead.LastName = 'test lead';
        newLead.Company = 'test company';
        newLead.Member__c = createdMember.Id;
        newLead.MemberUnit__c = createdMemberUnit.Id;
        insert newLead;

        // create campaign member record
        CampaignMember newCampaignMember = new CampaignMember();
        newCampaignMember.CampaignId = newCampaign.Id;
        newCampaignMember.LeadId = newLead.Id;
        insert newCampaignMember;

        UTIL_LandingPageLink pageLink = new UTIL_LandingPageLink();
        pageLink.styleIn = 'test styleIn';
        pageLink.campaignIdIn = (String) newCampaign.Id;
        pageLink.inputIn = (String) newLead.Id;

        String returnResult = pageLink.getResult();
        System.assertNotEquals( null, returnResult );
        System.debug( 'returnResult ==> ' + returnResult );

        pageLink.inputIn = (String) factory.acc.Id;
        pageLink.extraActionIn = 'testExtractionIn';
        pageLink.baseUrlIn = 'test baseURL';
        returnResult = pageLink.getResult();
        System.assertNotEquals( null, returnResult );
        System.debug( 'returnResult 2 ==> ' + returnResult );

        Test.stopTest();
    }

    /** Test for UTIL_GetDocumentLink.cls **/
    @isTest
    static void test_UTIL_GetDocumentLink(){

        Test.startTest();

        // get existed folder
        Folder existedFolder = [ SELECT Id, DeveloperName FROM Folder WHERE Type = 'Document' LIMIT 1 ];
        System.debug( 'folder ==> ' + existedFolder );

        // create document
        Document doc = new Document();
        doc.Name = 'testDoc';
        doc.Body = Blob.valueOf('some text');
        doc.ContentType = 'application/pdf';
        doc.DeveloperName = 'myDocument';
        doc.IsPublic = true;
        doc.FolderId = existedFolder.Id;
        insert doc;

        System.debug( 'Document created ==> ' + [ SELECT Id FROM Document WHERE Name = 'testDoc' AND Folder.DeveloperName = :existedFolder.DeveloperName ] );

        // create string DocumentName/FolderName
        String searchString = (String) existedFolder.DeveloperName + '/' + (String) doc.Name;

        UTIL_GetDocumentLink getDocumentLink = new UTIL_GetDocumentLink();
        getDocumentLink.searchStringIn = searchString;

        String result = getDocumentLink.getResult();
        System.assertNotEquals( null, result );
        System.debug( 'result ==> ' + result );

        getDocumentLink.result = '';
        getDocumentLink.returnTypeIn = 'img';
        getDocumentLink.widthIn = '200';
        getDocumentLink.heightIn = '200';
        getDocumentLink.heightIn = '200';
        getDocumentLink.altIn = 'img';
        getDocumentLink.titleIn = 'classname';
        getDocumentLink.tagClassIn = 'tag';
        getDocumentLink.styleIn = 'style';
        getDocumentLink.borderIn = 'border';
        result = getDocumentLink.getResult();
        System.assertNotEquals( null, result );
        System.debug( 'result2 ==> ' + result );

        // alter searchString to cover throw exception
        searchString = (String) doc.Name + '/' + (String) existedFolder.DeveloperName + '/test';
        getDocumentLink.searchStringIn = searchString;
        result = getDocumentLink.getResult();
        System.assertEquals( '', result );
        System.debug( 'result3 ==> ' + result );

        Test.stopTest();
    }

    /** Test for UTIL_Email.cls **/
    @isTest
    static void test_UTIL_Email(){

        Test.startTest();

        System.debug( 'OrgWideEmailAddress ==> ' + [ SELECT Id, DisplayName FROM OrgWideEmailAddress LIMIT 2 ] );
        System.debug( 'EmailTemplates ==> ' + [ SELECT Id, Name FROM EmailTemplate LIMIT 2] );
        
        TST_DataFactory factory = TST_DataFactory.getInstance();
        factory.queryResults();

        // create lead
        Lead newLead = new Lead();
        newLead.LastName = 'test lead';
        newLead.Company = 'test company';
        newLead.Email = 'lead@abc.com';
        insert newLead;

        Map<String, OrgWideEmailAddress> resultOrgWideEmail = UTIL_Email.orgWideEmailAddressCache;
        Map<Id, EmailTemplate> resultEmailTemplate = UTIL_Email.emailTemplateCache;
        Map<String,EmailTemplate> resultEmailTemplateName = UTIL_Email.emailTemplateNameCache;
        Map<String,EmailTemplate> resultEmailTemplateDeveloperName = UTIL_Email.emailTemplateDeveloperNameCache;

        System.assertNotEquals( null, resultOrgWideEmail );
        System.assertNotEquals( null, resultEmailTemplate );
        System.assertNotEquals( null, resultEmailTemplateName );
        System.assertNotEquals( null, resultEmailTemplateDeveloperName );

        UTIL_Email.sendSystemAlert( 'something', 'wrong' );
        UTIL_Email.sendSystemAlert( 'something', 'wrong', '<h1>Something Wrong</h1>' );

        List<String> developerNameList = new List<String>(resultEmailTemplateDeveloperName.keySet());
        List<Messaging.SingleEmailMessage> builtMailList = new List<Messaging.SingleEmailMessage>();

        Messaging.SingleEmailMessage builtMail = UTIL_Email.buildEmail( developerNameList[0], factory.acc.Id, factory.con.Id );
        System.assertNotEquals( null, builtMail );
        builtMailList.add( builtMail );

        Map<String, String> mergeFields = new Map<String, String>();
        mergeFields.put( '$AccountName$', factory.acc.Name );
        
        //builtMail = UTIL_Email.buildEmail( developerNameList[0], factory.acc.Id, newLead.Id, factory.acc.Id, mergeFields );
        //System.assertNotEquals( null, builtMail );
        UTIL_Email.sendEmails( builtMailList );

        Test.stopTest();
    }

    /** Test for GW_ApexPage.cls **/
    @isTest
    static void test_GW_ApexPage(){

        // get this from query in dev console
        String pageName = 'SendReminder';
        String language = 'ENG';

        String returnPageName = GW_ApexPage.getExistingTemplateName( pageName, language );
        System.assertEquals( pageName, returnPageName );
        
        //17-07-2017
        try{
            returnPageName = GW_ApexPage.getExistingTemplateName( 'testPage', language ); 
        }catch(exception e){}
        
        pageName = 'IO_THBELAU';
        language = 'NL';

        returnPageName = GW_ApexPage.getExistingTemplateName( pageName, language );
        System.assertEquals( 'IO_THBELAU_NL', returnPageName );
       
    }

    /** Test for GlobalUtils.cls **/
    @isTest
    static void test_GlobalUtils(){

        Test.startTest();

        TST_DataFactory factory = TST_DataFactory.getInstance();
        factory.queryResults();

        List<sObject> sObjectList = new List<sObject>();
        sObjectList.add( (sObject)factory.acc );

        GlobalUtils util = new GlobalUtils();
        util.removeNullValues( sObjectList );
        
        Test.stopTest();
    }

    /** Test for Q_CheckData.cls **/
    @isTest
    static void test_Q_CheckData(){

        Test.startTest();

        Datetime sysTime = System.now().addSeconds(3);
        String cron = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        Q_CheckData scheduleContext = new Q_CheckData();

        String jobId;

        jobId = System.schedule( 'Test executing schedul class Q_CheckData' , cron, scheduleContext);

        Test.stopTest();
    }

    /** Test for GW_ProductRelation.cls **/
    @isTest
    static void test_GW_ProductRelation(){

        Test.startTest();

        // query created product
        Product2 createdProduct = [ SELECT Id FROM Product2 LIMIT 1 ];

        // create ProductRelation record
        ProductRelation__c newProductRelation = new ProductRelation__c();
        newProductRelation.Parent__c = createdProduct.Id;
        newProductRelation.Type__c = 'CHILD';
        insert newProductRelation;

        // cover for method getRecord
        ProductRelation__c result = GW_ProductRelation.getRecord( newProductRelation.Id );
        System.assertEquals( newProductRelation.Id, result.Id );

        // cover for method getMap, getList
        Set<Id> productRelationSet = new Set<Id>{ newProductRelation.Id };
        Map<id,ProductRelation__c> resultMap = GW_ProductRelation.getMap( productRelationSet );
        System.assertNotEquals( null, resultMap.get( newProductRelation.Id ) );

        // cover for method getListFromRelated, getIdSetFromRelated
        List<ProductRelation__c> resultList = GW_ProductRelation.getListFromRelated( createdProduct.Id );
        System.assertEquals( 1, resultList.size() );
        
        resultList = GW_ProductRelation.getListFromRelated( new Set<Id>{ createdProduct.Id } );
        System.assertEquals( 1, resultList.size() );
        
        Set<Id> resultSet = GW_ProductRelation.getIdSetFromRelated( new Set<Id>{ createdProduct.Id } );
        System.assertEquals( 1, resultSet.size() );
        
        Test.stopTest();
    }

    

    /** Test for UTIL_WSC_Tract.cls **/
    static String jsonTractProduct = '[{"name":"Goods - Category Gallery 31 Day","description":"Category Gallery 31 Day","sku":"zagoods-cg31","serialized":false,"taxable":true,"trial":false,"id":"280","short_description":"1 Category Gallery 31 Day Feature","product_type":"addon","state":"AVAILABLE","requires_agreement":false,"default_quantity":1,"prices":[{"price_type":"recurring","id":"356","from_date":"2017-01-01T06:00:00.000+0000","price_override":true,"allow_scheduled_charges":false,"price_ranges":[{"price":964.04,"level":1,"id":"361","quantity_begin_range":0,"currency_code":"ZAR"}],"payment_on_purchase_required":false,"currency_code":"ZAR","price_category":{"charge_category_type":"price","name":"PRI-Marktplaats","priority":46,"status":"ACTIVE","id":"78"},"recurring_payment_required":false,"recurrence_period":"MONTH","prorated_on_order":false,"prorated_on_cancel":false,"prorated_on_order_no_charge":false,"bill_in_advance":true}],"product_category":{"name":"322","description":"Goods and Services","status":"ACTIVE","id":"16"},"min_service_resources":0,"max_service_resources":10,"service_resource_category":{"id":"19","name":"GOODS-ZA","resource_type":"service","status":"ACTIVE","allow_multiple_services":false},"trial_override":false,"product_tags":[{"name":"Goods","priority":24,"id":"20"}],"introduction_date":"2017-01-01T06:00:00.000+0000","rule_override":true,"rule_type":"TAPERED","rule_mode":"APPEND","consume_prepaid_balance":false}]';
    @isTest
    static void test_UTIL_WSC_Tract(){
        List<Object>lstTractProducts = (List<Object>)JSON.deserializeUntyped(jsonTractProduct);
        Test.startTest();

        // query created product
        Product2 createdProduct = [ SELECT Id FROM Product2 LIMIT 1];

        // create product relation
        ProductRelation__c newProductRelation = new ProductRelation__c();
        newProductRelation.Child__c = createdProduct.Id;
        newProductRelation.IsActive__c = true;
        newProductRelation.Type__c = 'CHILD';
        insert newProductRelation;

        // create Pricebook2 record
        Pricebook2 newPricebook = new Pricebook2();
        newPricebook.Name = 'newPricebook';
        insert newPricebook;

        // create PricebookEntry record
        PricebookEntry newPricebookEntry = new PricebookEntry();
        newPricebookEntry.Product2Id = createdProduct.Id;
        newPricebookEntry.Pricebook2Id = newPricebook.Id;
        newPricebookEntry.UnitPrice = 100;
        insert newPricebookEntry;

        // cover for method getTractIdSFDCIdMap
        Map<String, Id> resultMap = UTIL_WSC_Tract.getTractIdSFDCIdMap( new List<sObject>{ newProductRelation } );
        System.assertEquals( 1, resultMap.size() );

        // cover for method parseTractDatetimeString
        DateTime actualDateTime = UTIL_WSC_Tract.parseTractDatetimeString( '2017-04-23T2:00:00' );
        DateTime expectedDateTime = DateTime.newInstanceGmt( 2017, 04, 23, 2, 00, 00 );
        System.assertEquals( expectedDateTime, actualDateTime );

        // cover for method parseTractPercentage
        Decimal resultParse = UTIL_WSC_Tract.parseTractPercentage( 12.12 );
        System.assertEquals( 1212.00, resultParse );

        Map<Id, PricebookEntry> idMapPricebookEntry = new Map<Id, PricebookEntry>([ SELECT Id, Product2Id, Pricebook2Id, UnitPrice FROM PricebookEntry WHERE Id = :newPricebookEntry.Id ]);
        UTIL_WSC_Tract.ProductSync newProductSync = new UTIL_WSC_Tract.ProductSync( newPricebookEntry.Id, lstTractProducts );
        //newProductSync.commitAll(); 
        
        UTIL_WSC_Tract.PriceBookSync newPricebookSync = new UTIL_WSC_Tract.PriceBookSync( lstTractProducts );
        //newPricebookSync.commitAll(); 
        
        UTIL_WSC_Tract.DiscountSync newDiscountSync = new UTIL_WSC_Tract.DiscountSync( lstTractProducts );
        //newDiscountSync.commitAll(); 
        
        UTIL_WSC_Tract.DiscountResourceSync newDiscountResourceSync = new UTIL_WSC_Tract.DiscountResourceSync( lstTractProducts );
        //newDiscountResourceSync.commitAll(); 
        
        /*
        List<List<String>> parsedCSV = new List<List<String>>();
        UTIL_WSC_Tract.TRACTServiceSync newTRACTServiceSync = new UTIL_WSC_Tract.TRACTServiceSync( parsedCSV );
        //newTRACTServiceSync.commitAll(); 
        
        UTIL_WSC_Tract.TRACTInvoiceSync newTRACTInvoiceSync = new UTIL_WSC_Tract.TRACTInvoiceSync( parsedCSV );
        //newTRACTInvoiceSync.commitAll(); 
        
        UTIL_WSC_Tract.TRACTInvoiceItemSync newTRACTInvoiceItemSync = new UTIL_WSC_Tract.TRACTInvoiceItemSync( parsedCSV );
        //newTRACTInvoiceItemSync.commitAll(); 
        
        UTIL_WSC_Tract.TRACTRevenueScheduleSync newTRACTRevenueScheduleSync = new UTIL_WSC_Tract.TRACTRevenueScheduleSync( parsedCSV );
        //newTRACTRevenueScheduleSync.commitAll(); 
        */
        Test.stopTest();
    }



    /** Test for RAC_ProductConfigurator.cls **/
    @isTest static void test_RAC_ProductConfigurator() {
        
        List<Opportunity> opp = GW_sObject.queryRecords('Opportunity', '');
        List<PricebookEntry> pbe = GW_sObject.queryRecords('PricebookEntry', '');
        
        Test.startTest();
            
            // cover for method getOpportunityLineItems
            List<OpportunityLineItem> resultOLI  = RAC_ProductConfigurator.getOpportunityLineItems( opp.get(0).Id );
            for( OpportunityLineItem eachOLI : resultOLI ){
                System.debug( 'eachOLI oppId ==> ' + eachOLI.OpportunityId );
                if( eachOLI.OpportunityId == opp.get(0).Id ){
                    System.assert( true );
                } else {
                    System.assert( false );
                }
            }

            // cover for method getProducts
            List<PricebookEntry> resultPBE = RAC_ProductConfigurator.getProducts( pbe.get(0).Id );
            System.assertEquals( true, resultPBE.isEmpty() );

            // cover for method getUsedProducts
            Map<Id,PricebookEntry> resultPBEMap = RAC_ProductConfigurator.getUsedProducts(opp.get(0).Id);
            System.assertEquals( pbe[0].Id, resultPBEMap.get( pbe[0].Id ).Id );

        Test.stopTest();
    }
    
    /** Test for EBAYKRE_Email_FTP.cls **/
    @isTest static void test_EBAYKRE_Email_FTP() {
        
        Test.startTest();

            List<Account> acc = GW_sObject.queryRecords('Account', '');
            Id accId = acc.get(0).Id;

            List<MemberUnit__c> mu = GW_sObject.queryRecords('MemberUnit__c', '');
            Id memberUnitId = mu.get(0).Id;

            CustomAttributeDefinition__c cad = TST_DataFactory.createCustomAttributeDefinition(memberUnitId, 'Account', 'String');
            CustomAttribute__c ca = TST_DataFactory.createCustomAttributeForAccount(cad, 'ftpUsername', accId);

            EBAYKRE_Email_FTP emailInstance = new EBAYKRE_Email_FTP();
            emailInstance.incAccountId = acc.get(0).Id;
            emailInstance.ftpUsername = 'ftpUsername';
            emailInstance.ftpPassword = 'ftpPassword';

            Map<String,String> resultMap = emailInstance.getResult();
            System.debug( 'resultMap ==> ' + resultMap );
            System.assertEquals( 'y', resultMap.get( 'ftpPassword' ) );
            System.assertEquals( null, resultMap.get( 'ftpUsername' ) );
            
        
        Test.stopTest();
    }
    
    
    
    /** Test for Q_CheckPermissionGroups.cls **/
    @isTest static void test_execute_PermissionGroup() {
        Q_CheckPermissionGroups qcpg = new Q_CheckPermissionGroups();
        Test.startTest();
            System.enqueueJob(qcpg);
        Test.stopTest();
    }
    
    /** Test for DNBWebservices.cls **/
    @isTest static void test_DNBWebservices() {
        Test.startTest();
            
            //params String Name, String CountryCode, String PostCode, String StreetAddress, String BillingState
            DNBWebservices.GetDUNSnumbers( 'test', '111', '1111', '222', 'test' );

            //params String DUNSnumber, String CountryCode
            DNBWebservices.GetCreditRating( '112323432', '111' );

        Test.stopTest();
    }
    
    /** Test for BAT_PriceBookImportFromTRACT.cls **/
    @isTest static void test_BAT_PriceBookImportFromTRACT() {
        Test.startTest();
            UTIL_CustomJob.createMissingCustomJobs();
            UTIL_CustomJob.startCustomJob('BAT_PriceBookImportFromTRACT');
        Test.stopTest();
    }
    
    /** Test for WS_UI.cls **/
    @isTest static void test_WS_UI() {
        Account acc = [Select Id From Account limit 1];
        Opportunity opp = [Select Id From Opportunity limit 1];
        Test.startTest();
            WS_UI.EBAYKRE_SendFTPEmail(acc.Id);
            WS_UI.signOpportunity(opp.Id);
        Test.stopTest();
    }
    
    /** Test for LSC_FormRendererController.cls **/
    @isTest static void test_LSC_FormRendererController() {
        Test.startTest();
            // get field set for company details page
            Set<String> lstAccFieldSet = Schema.SObjectType.Account.fieldSets.getMap().keyset();
            if(!lstAccFieldSet.isEmpty()){
                for(String fieldsetName: lstAccFieldSet){
                    String result = LSC_FormRendererController.getFieldSet( 'Account', fieldsetName);
                    System.assertNotEquals(null, result);
                }
            }
    
            // get field set for user page
            Set<String> lstConFieldSet = Schema.SObjectType.Contact.fieldSets.getMap().keyset();
            if(!lstConFieldSet.isEmpty()){
                for(String fieldsetName: lstConFieldSet){
                    String result = LSC_FormRendererController.getFieldSet( 'Contact', fieldsetName);
                    System.assertNotEquals(null, result);
                }
            }
        Test.stopTest();
    }
    
    /** Test for HNDL_Rule.cls **/
    @isTest static void test_HNDL_Rule() {
        
        Test.startTest();
            HNDL_Rule rule = new HNDL_Rule();
            rule.beforeInsert(new Rule__c(Name='test'));
            rule.beforeUpdate(new Rule__c(Name='test'), new Rule__c(Name='test123'));
        Test.stopTest();
        
    }
    
    /** Test for VAL_SiteUser.cls **/
    @isTest static void test_VAL_SiteUser() {
        
        Test.startTest();
            new VAL_SiteUser();
            VAL_SiteUser.isEmailExist('', '');
            VAL_SiteUser.checkPromotionCode('', '');
        Test.stopTest();
        
    }
    
    /** Test for SchAdxImportMetrics.cls, RAC_ProductConfigurator.cls, c_DefaultContactController.cls, c_DefaultHomeController.cls,
        c_DefaultOverviewController, Util_Lookup.cls, UTIL_LandingPageLink.cls
     */
    @isTest static void my_C_Utils() {
        Test.startTest();
        
        Account acc = GW_Account.createSObject();
        insert acc;
        
        Contact con = GW_Contact.createSObject('testContact',acc);
        insert con;
        
        Member__c mb = new Member__c(Name='Test member', Account__c = acc.id);
        insert mb;
        
        MemberUnit__c mu = new MemberUnit__c(Name = 'Test member unit', Member__c=mb.Id, LineOfBusiness__c='AD');
        insert mu;
        
        Opportunity  opp1 = new Opportunity(name='Test Opp1', closeDate= system.today(), stageName='test', AccountId= acc.id, MemberUnit__c=mu.Id );
        insert opp1;
        
        //Test for Util_Lookup.cls
        RemoteResponse resp1 = Util_Lookup.queryListLookup('Account', 'ACME Inc.', new List<String>{'Name'}, 1, 'Agency');
        resp1 = Util_Lookup.queryListLookup('AccountError', 'ACME Inc.', new List<String>{'Name'}, 1, 'Agency');
        
        con = [SELECT Id FROM Contact WHERE LastName = 'testContact' LIMIT 1];
        RemoteResponse resp2 = Util_Lookup.queryLookupItem(con.Id, 'Contact');
        resp2 = Util_Lookup.queryLookupItem(con.Id, 'ContactError');
        
        //Test for UTIL_LandingPageLink.cls
        UTIL_LandingPageLink landing = new UTIL_LandingPageLink();
        String result = landing.getResult();
        
        landing.inputIn = con.Id;
        result = landing.getResult();
        
        landing.extraActionIn = 'testAction';
        landing.baseUrlIn = 'testbase';
        landing.styleIn = 'testStyle';
        result = landing.getResult();
        //result = landing.getResult();
        
        
        //Test for c_DefaultContactController.cls
        c_DefaultContactController conContact = new c_DefaultContactController();
        
        //Test for c_DefaultHomeController.cls
        c_DefaultHomeController conHome = new c_DefaultHomeController();
        
        //Test for SchAdxImportMetrics.cls
        SchAdxImportMetrics.start();
        
        //Test for c_DefaultOverviewController.cls
        try {
            c_DefaultOverviewController cont = new c_DefaultOverviewController();
            List<c_Common.Subscription> lstComm = cont.activeSubscriptions;
            Contact currentContact = cont.currentContact;
        } catch (Exception ex){}
        //Test for RAC_ProductConfigurator.cls
        PageReference pageRef = Page.ProductConfigurator;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opp1);
        ApexPages.currentPage().getParameters().put('Id',opp1.id);
        RAC_ProductConfigurator conRAC = new RAC_ProductConfigurator(sc);
        List<OpportunityLineItem> lstOppLine = RAC_ProductConfigurator.getOpportunityLineItems(opp1.id);
        Map<Id,PricebookEntry> mPricebook = RAC_ProductConfigurator.getUsedProducts(opp1.id);
        List<PricebookEntry> lstPricebook = RAC_ProductConfigurator.getProducts(Test.getStandardPricebookId());
        
        Test.stopTest();
    }
    
     static testMethod void test_c_DefaultTemplate() {
        Test.startTest();
            Test.setCurrentPageReference(new PageReference('c_EBAYKRE_Template')); 
            System.currentPageReference().getParameters().put('page', 'test');
            c_DefaultTemplate dt = new c_DefaultTemplate(); 
        Test.stopTest();
     }

}