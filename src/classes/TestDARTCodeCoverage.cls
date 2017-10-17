/**
 * Test all classes(DART) Forecast/Booking/Delivery
 * CreatedDate: 12/02/2013
 */


@istest(SeeAllData=false)
public with sharing class TestDARTCodeCoverage {

    static TestDataGenerator testDATA = new TestDataGenerator();

    //@vitou 13-05-2015
    public static Opportunity opp;
    public static OpportunityLineItem item;
    public static AdServer_Login__c logIn;


    //@vitou 13-05-2015
    @testSetup static void setup() {
            testDATA.createTestUser();
            testDATA.createCredential();
            testDATA.createTargetingHierarchy();
            testDATA.createAccount();
            testDATA.createAdvertiser();
            testDATA.createOpp(testDATA.lstAcc.get(0));
            testDATA.createOppTeamMember(testDATA.opp.id);
            testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
            testDATA.createTargetingKVHierarchy();
            testDATA.createTargetingKVHierarchy();
    }

      //@vitou 13-05-2015
    static void getTestData(){
        ///
        opp = [select id, Name, IOnumber__c, Owner.id, Owner.Name, AccountId, CampaignStart__c, CampaignEnd__c, P_O_Number__c, MemberUnit__c from Opportunity limit 1];
        logIn = [select id, Refresh_Token__c, Client_Id__c, Client_Secret__c,ExternalLineDescriptionId__c from AdServer_Login__c where User_Name__c='dart6testuser@gmail.com'];
        item = [select id, OpportunityId, from_Date__c, Until_Date__c, SalesPriceNet__c, AdOperatingSystems__c, UniqueAdName__c, 
                       DFP_Time_Monday__c, DFP_Time_Tuesday__c, DFP_Time_Wednesday__c, DFP_Time_Thursday__c, DFP_Time_Friday__c, DFP_Time_Saturday__c, DFP_Time_Sunday__c,
                       Keywords_KeyValue_combination__c, KeyValueString__c, AdWebBrowsers__c, Ad_Id__c, AdKeywords__c,
                       PriceBookEntry.Product2.Fixed_Site__c, Targeting__c, PricebookEntry.Product2.RecordType.Name, PriceBookEntry.Product2.Site__r.Country__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c, Ad_Name__c, Device_Targeting__c, AdDayOfWeek__c, AdHourOfDay__c,
                       AdBrowsersMinorVersion__c, AdBrowsersMajorVersion__c, CurrencyIsoCode, Billing_Category__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdType__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_Prio__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_Product_Type__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_MasterSize__c,
                       Quantity, Description, FC_Period__c, FC_Ad_served_every__c, FC_Quantity__c, Predefined_Adunit__c, Predefined_DeviceCategory__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_CompanionSize__c, PriceBookEntry.Product2.Name
                       from OpportunityLineItem where Description='Test Desc0' and OpportunityId= :opp.Id];
		TST_DataFactory.insertAccountMemberUnitAssociation(opp.AccountId, opp.MemberUnit__c);
    }

    /** DART6 Request Forecast By LineItem */
    static testMethod void testDART6RequestForecast()
    {

        Test.startTest();

            //@vitou 13-05-2015 => get Test Data
            getTestData();

            // Dart6Message
            DART6Message dart6Msg = new DART6Message();
            // Dart6Parser
            DART6Parser dart6Parser = new DART6Parser();
            // DartObject
            DARTObject dartObj = new DARTObject();
            //DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(items.get(0));
            DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(item);

            //List<OpportunityLineItem> items2 = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
            // ForecastController
            //ForecastController fcCont2 = new ForecastController(items2.get(0));
            ForecastController fcCont2 = new ForecastController(item);
            fcCont2.forecastProcess();
            List<DARTObject.DARTForecast> lstFc2 = fcCont2.getObjectForecast();

            //@Vitou 08-04-2015
            DartUtil.generateTableForecast(lstFc2);

        Test.stopTest();

        // Forecast Request by lineItem
        System.assertEquals('300', lstFc2.get(0).getAvailableUnits(), '300, Test data from DARTMokup');
        System.assertEquals('getForecast', fcCont2.getInvokedMethod(), '');

        //System.assertEquals('Multiformat1', dartFC.getPackage(), '');
        System.assertEquals('200', dartFC.getQuantity()+'', '');
        System.assertEquals('Test Desc0', dartFC.getLineDesc(), '');
        System.assertEquals('Test product0', dartFC.getProductName(), '');

    }

    static testMethod void testDart6GetAdvertiser()
    {
        Test.startTest();

            //@vitou 13-05-2015 => get Test Data
            getTestData();

            // Dart6Message
            DART6Message dart6Msg = new DART6Message();
            // Dart6Parser
            DART6Parser dart6Parser = new DART6Parser();
            // DartObject
            DARTObject dartObj = new DARTObject();
            // DARTMockUp
            DARTMockUp mockupdata = new DARTMockUp();

            //DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(items.get(0));
            DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(item);

            //List<OpportunityLineItem> items2 = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
            // Booking
            //BookingController bookingCont2 = new BookingController(opp, items2.get(0));
            BookingController bookingCont2 = new BookingController(opp, item);

            bookingCont2.processSearchAdvertiser();
            List<DARTObject.IDARTObjectAdvertiser> lstAdv = bookingCont2.getListAdvertiser();
            bookingCont2.getExistOrder();

        Test.stopTest();
    }



    /** Test DART6 Booking */
    static testMethod void testDART6Booking()
    {

        Test.startTest();

            //@vitou 13-05-2015 => get Test Data
            getTestData();
            opp.ApprovalStatus__c = 'Previously Approved';
            opp.ContractStatus__c = 'Signed';
            update opp;
            update item;
            getTestData();

            // Dart6Message
            DART6Message dart6Msg = new DART6Message();
            // Dart6Parser
            DART6Parser dart6Parser = new DART6Parser();
            // DartObject
            DARTObject dartObj = new DARTObject();
            // DARTMockUp
            DARTMockUp mockupdata = new DARTMockUp();

            //DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(items.get(0));
            DARTObject.DARTForecast dartFc = new DARTObject.DARTForecast(item);

            //List<OpportunityLineItem> items2 = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
            // Booking
            //BookingController bookingCont2 = new BookingController(opp, items2.get(0));
            BookingController bookingCont2 = new BookingController(opp, item);

            bookingCont2.requestCreateAdvertiser();
            List<DARTObject.IDARTObjectAdvertiser> lstAdv = bookingCont2.getListAdvertiser();


             Advertiser__c adv = new Advertiser__c(Dart6_Advertiser_Id__c=lstAdv.get(0).getDartId());

            Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
            //mapAdvertiser.put(DARTUtil.DART6+'_'+items2.get(0).PriceBookEntry.Product2.Site__r.Country__c, adv);
            mapAdvertiser.put(DARTUtil.DART6+'_'+item.PriceBookEntry.Product2.Site__r.Country__c, adv);

            bookingCont2.processAndSendOrder(mapAdvertiser);
            List<DARTObject.IDARTObjectOrder> lstOrder = bookingCont2.getListOrder();
            bookingCont2.processAndSendLineItem(lstOrder.get(0), mapAdvertiser);
            List<DARTObject.IDARTObjectAds> lstAds = bookingCont2.getListAds();

            //@vitou 08-04-2015
            DARTUtil.generateTableCompaigns(lstOrder);
            DARTUtil.generateTableCompaignItems(lstAds);

        Test.stopTest();

        // Result
        // Advertiser
        System.assertEquals('123456', lstAdv.get(0).getDartId(), '123456, Test data from DARTMokup');
        // Order
        System.assertEquals('22222', lstOrder.get(0).getDartId(), '22222, Test data from DARTMokup');
        //LineItem
        System.assertEquals('123456', lstAds.get(0).getDartId(), '123456, Test data from DARTMokup');
        System.assertEquals('111111', lstAds.get(0).getOrder().getDartId(), '111111, Test data from DARTMokup');
        //System.assertEquals('getLineItemByName', bookingCont2.getInvokedMethod());

    }

    /**
     * Test booking Update lineItem
     * => create new lineItem
     */
    static testMethod void testDART6BookingUpdateLineItem()
    {
        Test.startTest();

           //@vitou 13-05-2015 => get Test Data
            getTestData();
            opp.ApprovalStatus__c = 'Previously Approved';
            opp.ContractStatus__c = 'Signed';
            update opp;
            update item;
            getTestData();

            // Booking
            //BookingController bookingCont2 = new BookingController(opp, items.get(0));
            BookingController bookingCont2 = new BookingController(opp, item);

            bookingCont2.requestCreateAdvertiser();
            List<DARTObject.IDARTObjectAdvertiser> lstAdv = bookingCont2.getListAdvertiser();


            Advertiser__c adv = new Advertiser__c(Dart6_Advertiser_Id__c=lstAdv.get(0).getDartId());

            Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
            //mapAdvertiser.put(DARTUtil.DART6+'_'+items.get(0).PriceBookEntry.Product2.Site__r.Country__c, adv);
            mapAdvertiser.put(DARTUtil.DART6+'_'+item.PriceBookEntry.Product2.Site__r.Country__c, adv);

            bookingCont2.processAndSendOrder(mapAdvertiser);
            List<DARTObject.IDARTObjectOrder> lstOrder = bookingCont2.getListOrder();
            bookingCont2.processAndSendLineItem(lstOrder.get(0), mapAdvertiser);
            List<DARTObject.IDARTObjectAds> lstAds = bookingCont2.getListAds();
         Test.stopTest();
    }

    /** Test DART6 DeliveryReport */

    static testMethod void testDART6DeliveryReport()
    {
        //**testDATA.createCredential();
        getTestData();

        DART_Delivery_Support__c dds = new DART_Delivery_Support__c(
                AdServer_Login__c=logIn.id, //AdServer_Login__c=testDATA.listLogin.get(0).id,
                Schedule_Type__c = 'Daily',
                Sobject__c = 'Opportunity Product',
                Status__c = 'New',
                Attempt__c = 0,
                Query_Start_Date__c = System.today(),
                Query_End_Date__c = System.today().addMonths(1)
                );
        insert dds;
        test.startTest();

        dds = DeliveryController.getDeliverySupportRecord(dds.Id);
        DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = DeliveryController.buildQueryService(dds);
        DeliveryController devCont = new DeliveryController(dds);

        devCont.setReportService(reportService);
        devCont.importDelivery('');

        DeliveryController.checkJobStatus(dds,'');
        DeliveryController.startNextAdServer('Opportunity Product', 'Monthly', '');
        DeliveryController.start('Monthly', 'Opportunity Product');
        DeliveryController.doStart(dds, '');

        DeliveryController.processBatchDelivery(dds, devCont.getListDart());
        DeliveryController devCont2 = new DeliveryController(dds);
        DeliveryController devCont3 = new DeliveryController(logIn, DART6Message.BREAKDOWN_DAILY, DART6Message.DATERANGE_YESTERDAY);

        //@vitou 08-04-2015
        DeliveryController devContTest = new DeliveryController();
        devContTest.proceedImport();
        devContTest.getInvokedMethod();

        test.stopTest();

    }

    /** Test Adx Import Data Metric */

    static testMethod void testAdxImportMetric()
    {
        //**testDATA.createCredential();
        getTestData();

        DART_Delivery_Support__c dds = new DART_Delivery_Support__c(
                AdServer_Login__c=logIn.id, //AdServer_Login__c=testDATA.listLogin.get(0).id,
                Schedule_Type__c = 'Daily',
                Sobject__c = DeliveryController.SOBJECT_METRIC,
                Status__c = 'New',
                Attempt__c = 0,
                Query_Start_Date__c = date.newInstance(System.now().year(), System.now().month(), 1),
                Query_End_Date__c = System.today().addMonths(1)
                );
        insert dds;
        test.startTest();

        dds = DeliveryController.getDeliverySupportRecord(dds.Id);
        DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = DeliveryController.buildQueryService(dds);
        DeliveryController devCont = new DeliveryController(dds);

        devCont.setReportService(reportService);
        devCont.importDelivery(DeliveryController.ADX_IMPORT);

        DeliveryController.checkJobStatus(dds, DeliveryController.ADX_IMPORT);
        DeliveryController.startNextAdServer(DeliveryController.SOBJECT_METRIC, 'Monthly', DeliveryController.ADX_IMPORT);
        DeliveryController.start('Monthly', DeliveryController.SOBJECT_METRIC);
        DeliveryController.doStart(dds, DeliveryController.ADX_IMPORT);

        AdxImportController.processBatchAdxImport(dds, devCont.getListDart());
        DeliveryController devCont2 = new DeliveryController(dds);
        DeliveryController devCont3 = new DeliveryController(logIn, DART6Message.BREAKDOWN_DAILY, DART6Message.DATERANGE_YESTERDAY);

        //@vitou 08-04-2015
        DeliveryController devContTest = new DeliveryController();
        devContTest.proceedImport();
        devContTest.getInvokedMethod();

        test.stopTest();

    }

    /**
     * Test DFPCredentialController
     */
     static testMethod void testDFPCredentialController()
     {
        //@vitou 13-05-2015 => get Test Data
        getTestData();
        logIn.RT_Waiting__c = true;
        logIn.Client_Id__c = 'clientidxxxxx';
        logIn.Client_Secret__c = 'secretxxxx';
        logIn.Refresh_Token__c = 'refxxxxxx';
        update logIn;

        PageReference pageCred = Page.DFPCredentialPage;
        pageCred.getParameters().put('code','1234567890');
        Test.setCurrentPage(pageCred);


        Test.startTest();
        DFPCredentialController con = new DFPCredentialController();

        //assert non selected
        con.processCredential();

        //select one
        con.selectedValue = logIn.Id+''; //con.selectedValue = testDATA.listLogin[0].Id+'';
        con.processCredential();

        con.saveToken();

        logIn.RT_Waiting__c = true; //testDATA.listLogin[0].RT_Waiting__c = true;
        update logIn; //update testDATA.listLogin[0];

        con.cancel();


        Test.stopTest();

     }

     /**
     * Test DFPCredentialController
     * getRunOfNetworkID
     */
     static testMethod void testDFPCredentialConGetRunOfNetwork()
     {

        //@vitou 13-05-2015 => get Test Data
        getTestData();
        logIn.RT_Waiting__c = true;
        logIn.Client_Id__c = 'clientidxxxxx';
        logIn.Client_Secret__c = 'secretxxxx';
        logIn.Refresh_Token__c = 'refxxxxxx';
        update logIn;

        Test.startTest();
        DFPCredentialController con = new DFPCredentialController();
        //select one
        con.selectedValue = logIn.Id+''; //con.selectedValue = testDATA.listLogin[0].Id+'';
        con.getRunOfNetworkID();
        Test.stopTest();

     }

    /** Class DART6_COMPANYSERVICE*/
    static testMethod void testClassDART6_COMPANYSERVICE()
    {
        DART6_COMPANYSERVICE companyService = new DART6_COMPANYSERVICE();
        DART6_COMPANYSERVICE.CompanyServiceInterfacePort compInPort = new DART6_COMPANYSERVICE.CompanyServiceInterfacePort();
        DART6_COMPANYSERVICE.CommonError comErr = new DART6_COMPANYSERVICE.CommonError();
        DART6_COMPANYSERVICE.InternalApiError inApiErr = new DART6_COMPANYSERVICE.InternalApiError();
        DART6_COMPANYSERVICE.BooleanValue bv = new DART6_COMPANYSERVICE.BooleanValue();
        DART6_COMPANYSERVICE.AppliedLabel appLabel = new DART6_COMPANYSERVICE.AppliedLabel();
        DART6_COMPANYSERVICE.UniqueError uniquErr = new DART6_COMPANYSERVICE.UniqueError();
        DART6_COMPANYSERVICE.RequiredError requiErr  = new DART6_COMPANYSERVICE.RequiredError();
        DART6_COMPANYSERVICE.SetValue setval = new DART6_COMPANYSERVICE.SetValue();
        DART6_COMPANYSERVICE.AuthenticationError authErr = new DART6_COMPANYSERVICE.AuthenticationError();
        DART6_COMPANYSERVICE.PermissionError perErr = new DART6_COMPANYSERVICE.PermissionError();
        DART6_COMPANYSERVICE.PublisherQueryLanguageSyntaxError pubQuLangSynErr = new DART6_COMPANYSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_COMPANYSERVICE.String_ValueMapEntry valueMapEnty = new DART6_COMPANYSERVICE.String_ValueMapEntry();
        DART6_COMPANYSERVICE.StringLengthError strLenErr = new DART6_COMPANYSERVICE.StringLengthError();
        DART6_COMPANYSERVICE.Value v = new DART6_COMPANYSERVICE.Value();
        DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element getComByStatResEle = new DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element();
        DART6_COMPANYSERVICE.CompanyPage comPage = new DART6_COMPANYSERVICE.CompanyPage();
        DART6_COMPANYSERVICE.FeatureError FeatureErr = new DART6_COMPANYSERVICE.FeatureError();
        DART6_COMPANYSERVICE.updateCompaniesResponse_element upComResEle = new DART6_COMPANYSERVICE.updateCompaniesResponse_element();
        DART6_COMPANYSERVICE.TypeError typeErr = new DART6_COMPANYSERVICE.TypeError();
        DART6_COMPANYSERVICE.NumberValue numErr = new DART6_COMPANYSERVICE.NumberValue();
        DART6_COMPANYSERVICE.Company comp = new DART6_COMPANYSERVICE.Company();
        DART6_COMPANYSERVICE.SoapResponseHeader soapResHeader = new DART6_COMPANYSERVICE.SoapResponseHeader();
        DART6_COMPANYSERVICE.NotNullError notNullErr = new DART6_COMPANYSERVICE.NotNullError();
        DART6_COMPANYSERVICE.updateCompanies_element updateComEle = new DART6_COMPANYSERVICE.updateCompanies_element();
        DART6_COMPANYSERVICE.DateTimeValue dateValue = new DART6_COMPANYSERVICE.DateTimeValue();
        DART6_COMPANYSERVICE.getCompaniesByStatement_element getComByState = new DART6_COMPANYSERVICE.getCompaniesByStatement_element();
        DART6_COMPANYSERVICE.CompanyCreditStatusError comCrStatusErr = new DART6_COMPANYSERVICE.CompanyCreditStatusError();
        DART6_COMPANYSERVICE.Statement st = new DART6_COMPANYSERVICE.Statement();
        DART6_COMPANYSERVICE.PublisherQueryLanguageContextError publiConErro = new DART6_COMPANYSERVICE.PublisherQueryLanguageContextError();
        DART6_COMPANYSERVICE.ApiError apiErr = new DART6_COMPANYSERVICE.ApiError();
        DART6_COMPANYSERVICE.Date_x dtx = new DART6_COMPANYSERVICE.Date_x();
        DART6_COMPANYSERVICE.SoapRequestHeader soapReqHe = new DART6_COMPANYSERVICE.SoapRequestHeader();
        DART6_COMPANYSERVICE.TeamError teamErr = new DART6_COMPANYSERVICE.TeamError();
        DART6_COMPANYSERVICE.createCompaniesResponse_element createCompaniesResEle = new DART6_COMPANYSERVICE.createCompaniesResponse_element();
        DART6_COMPANYSERVICE.ApiException apiExc = new DART6_COMPANYSERVICE.ApiException();
        DART6_COMPANYSERVICE.QuotaError quaErr = new DART6_COMPANYSERVICE.QuotaError();
        DART6_COMPANYSERVICE.ApplicationException appExc = new DART6_COMPANYSERVICE.ApplicationException();
        DART6_COMPANYSERVICE.ParseError parseErr = new DART6_COMPANYSERVICE.ParseError();
        DART6_COMPANYSERVICE.ApiVersionError apiVerErr = new DART6_COMPANYSERVICE.ApiVersionError();
        DART6_COMPANYSERVICE.LabelEntityAssociationError labelAssErr = new DART6_COMPANYSERVICE.LabelEntityAssociationError();
        DART6_COMPANYSERVICE.ServerError serErr = new DART6_COMPANYSERVICE.ServerError();
        DART6_COMPANYSERVICE.DateTime_x datetimex = new DART6_COMPANYSERVICE.DateTime_x();
        DART6_COMPANYSERVICE.StatementError stateErr = new DART6_COMPANYSERVICE.StatementError();
        DART6_COMPANYSERVICE.TextValue txtVal = new DART6_COMPANYSERVICE.TextValue();
        DART6_COMPANYSERVICE.InvalidEmailError invErr = new DART6_COMPANYSERVICE.InvalidEmailError();
        DART6_COMPANYSERVICE.createCompanies_element createCompaniesEle = new DART6_COMPANYSERVICE.createCompanies_element();

        DART6_COMPANYSERVICE.CollectionSizeError colSizeErr = new DART6_COMPANYSERVICE.CollectionSizeError();
        DART6_COMPANYSERVICE.CompanyError cmpErr= new DART6_COMPANYSERVICE.CompanyError();
        DART6_COMPANYSERVICE.AvailableBillingError availBillErr = new DART6_COMPANYSERVICE.AvailableBillingError();
        DART6_COMPANYSERVICE.ObjectValue objv= new DART6_COMPANYSERVICE.ObjectValue();
        DART6_COMPANYSERVICE.DateValue dtV= new DART6_COMPANYSERVICE.DateValue();
        DART6_COMPANYSERVICE.CrossSellError crosSellErr= new DART6_COMPANYSERVICE.CrossSellError();
        
        Object o = new DART6_COMPANYSERVICE.NullError();
        o = new DART6_COMPANYSERVICE.RequiredCollectionError();
        o = new DART6_COMPANYSERVICE.CompanySettings();
        o = new DART6_COMPANYSERVICE.CustomFieldValueError();
        o = new DART6_COMPANYSERVICE.RegExError();
        Test.startTest(); 
            
            DART6_COMPANYSERVICE.CompanyServiceInterfacePort svc = new DART6_COMPANYSERVICE.CompanyServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_COMPANYSERVICE.updateCompaniesResponse_element()));
            svc.updateCompanies(new DART6_COMPANYSERVICE.Company[0]);
            
        Test.stopTest();
    }


    /** Class DART6_USERSERVICE */
    static testMethod void testClassDART6_USERSERVICE()
    {
        DART6_USERSERVICE userService=new DART6_USERSERVICE();
        DART6_USERSERVICE orderService = new DART6_USERSERVICE();
        DART6_USERSERVICE.CommonError comError = new DART6_USERSERVICE.CommonError();
        DART6_USERSERVICE.InternalApiError inApi = new DART6_USERSERVICE.InternalApiError();
        DART6_USERSERVICE.performUserActionResponse_element pUserAc = new DART6_USERSERVICE.performUserActionResponse_element();
        DART6_USERSERVICE.getUsersByStatementResponse_element userBySt = new DART6_USERSERVICE.getUsersByStatementResponse_element();
        DART6_USERSERVICE.BooleanValue bv = new DART6_USERSERVICE.BooleanValue();
        DART6_USERSERVICE.RequiredError reqerr = new DART6_USERSERVICE.RequiredError();
        DART6_USERSERVICE.PermissionError perErr = new DART6_USERSERVICE.PermissionError();
        DART6_USERSERVICE.AuthenticationError autErr = new DART6_USERSERVICE.AuthenticationError();
        DART6_USERSERVICE.PublisherQueryLanguageSyntaxError pquLaSyn = new DART6_USERSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_USERSERVICE.createUsers_element createUsE = new DART6_USERSERVICE.createUsers_element();
        DART6_USERSERVICE.getAllRolesResponse_element allRolRe = new DART6_USERSERVICE.getAllRolesResponse_element();
        DART6_USERSERVICE.String_ValueMapEntry stValMaEn = new DART6_USERSERVICE.String_ValueMapEntry();
        DART6_USERSERVICE.Value val = new DART6_USERSERVICE.Value();
        DART6_USERSERVICE.performUserAction_element perUsAct = new DART6_USERSERVICE.performUserAction_element();
        DART6_USERSERVICE.createUsersResponse_element creatUserResEle = new DART6_USERSERVICE.createUsersResponse_element();
        DART6_USERSERVICE.updateUsersResponse_element updUseResEle = new DART6_USERSERVICE.updateUsersResponse_element();
        DART6_USERSERVICE.TypeError typErr = new DART6_USERSERVICE.TypeError();
        DART6_USERSERVICE.UserAction usAc = new DART6_USERSERVICE.UserAction();
        DART6_USERSERVICE.updateUsers_element updatUs = new DART6_USERSERVICE.updateUsers_element();
        DART6_USERSERVICE.NumberValue numVal = new DART6_USERSERVICE.NumberValue();
        DART6_USERSERVICE.SoapResponseHeader soapResHeader = new DART6_USERSERVICE.SoapResponseHeader();
        DART6_USERSERVICE.NotNullError notNullErr = new DART6_USERSERVICE.NotNullError();
        DART6_USERSERVICE.Statement str = new DART6_USERSERVICE.Statement();
        DART6_USERSERVICE.PublisherQueryLanguageContextError pbLaCon = new DART6_USERSERVICE.PublisherQueryLanguageContextError();
        DART6_USERSERVICE.ApiError ApiErr = new DART6_USERSERVICE.ApiError();
        DART6_USERSERVICE.Date_x datex = new DART6_USERSERVICE.Date_x();
        DART6_USERSERVICE.SoapRequestHeader soapResHder = new DART6_USERSERVICE.SoapRequestHeader();
        DART6_USERSERVICE.getUsersByStatement_element userByStaEle = new DART6_USERSERVICE.getUsersByStatement_element();
        DART6_USERSERVICE.ApiException apiExeption = new DART6_USERSERVICE.ApiException();
        DART6_USERSERVICE.getAllRoles_element getAllRolesEle = new DART6_USERSERVICE.getAllRoles_element();
        DART6_USERSERVICE.QuotaError quaErr = new DART6_USERSERVICE.QuotaError();
        DART6_USERSERVICE.UserRecord uRec = new DART6_USERSERVICE.UserRecord();
        DART6_USERSERVICE.ApplicationException appExcep = new DART6_USERSERVICE.ApplicationException();
        DART6_USERSERVICE.ParseError parErr = new DART6_USERSERVICE.ParseError();
        DART6_USERSERVICE.ServerError serErr = new DART6_USERSERVICE.ServerError();
        DART6_USERSERVICE.DateTime_x dateTimex = new DART6_USERSERVICE.DateTime_x();
        DART6_USERSERVICE.TextValue txtVal = new DART6_USERSERVICE.TextValue();
        DART6_USERSERVICE.InvalidEmailError invaemailErr = new DART6_USERSERVICE.InvalidEmailError();
        DART6_USERSERVICE.getCurrentUser_element curEle = new DART6_USERSERVICE.getCurrentUser_element();
        DART6_USERSERVICE.Role rol = new DART6_USERSERVICE.Role();
        DART6_USERSERVICE.UpdateResult upResult = new DART6_USERSERVICE.UpdateResult();
        DART6_USERSERVICE.ActivateUsers activeUser = new DART6_USERSERVICE.ActivateUsers();
        DART6_USERSERVICE.StatementError stErr = new DART6_USERSERVICE.StatementError();
        DART6_USERSERVICE.getCurrentUserResponse_element curUsRes = new DART6_USERSERVICE.getCurrentUserResponse_element();
        DART6_USERSERVICE.FeatureError feaErr = new DART6_USERSERVICE.FeatureError();
        DART6_USERSERVICE.DropDownCustomFieldValue dropCusFv = new DART6_USERSERVICE.DropDownCustomFieldValue();
        DART6_USERSERVICE.BaseCustomFieldValue baseCusFv = new DART6_USERSERVICE.BaseCustomFieldValue();
        DART6_USERSERVICE.CustomFieldValue custFv = new DART6_USERSERVICE.CustomFieldValue();
        DART6_USERSERVICE.TeamError teamErr = new DART6_USERSERVICE.TeamError();
        DART6_USERSERVICE.CustomFieldValueError custFvErr = new DART6_USERSERVICE.CustomFieldValueError();
        DART6_USERSERVICE.DateValue dv = new DART6_USERSERVICE.DateValue();
        DART6_USERSERVICE.ApiVersionError apivErr = new DART6_USERSERVICE.ApiVersionError();
        DART6_USERSERVICE.CollectionSizeError colSizeErr = new DART6_USERSERVICE.CollectionSizeError();
        DART6_USERSERVICE.ObjectValue objV= new DART6_USERSERVICE.ObjectValue();
        DART6_USERSERVICE.TimeZoneError timzErr= new DART6_USERSERVICE.TimeZoneError();

        //@vitou 08-04-2015
        DART6_USERSERVICE.SetValue setVal = new DART6_USERSERVICE.SetValue();
        DART6_USERSERVICE.UniqueError uniqErr = new DART6_USERSERVICE.UniqueError();
        DART6_USERSERVICE.DateTimeValue dtVal = new DART6_USERSERVICE.DateTimeValue();
        DART6_USERSERVICE.TokenError tokenErr = new DART6_USERSERVICE.TokenError();
        DART6_USERSERVICE.DeactivateUsers deactUser = new DART6_USERSERVICE.DeactivateUsers();
        
        DART6_USERSERVICE.RequiredCollectionError err = new DART6_USERSERVICE.RequiredCollectionError();
        DART6_USERSERVICE.StringLengthError err1 = new DART6_USERSERVICE.StringLengthError();
            
        Test.startTest(); 
            
        
            DART6_USERSERVICE.UserServiceInterfacePort svc = new DART6_USERSERVICE.UserServiceInterfacePort();
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_USERSERVICE.getAllRolesResponse_element()));
            svc.getAllRoles();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_USERSERVICE.getCurrentUserResponse_element()));
            svc.getCurrentUser();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_USERSERVICE.performUserActionResponse_element()));
            svc.performUserAction(new DART6_USERSERVICE.UserAction(), new DART6_USERSERVICE.Statement());
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_USERSERVICE.createUsersResponse_element()));
            svc.createUsers(new List<DART6_USERSERVICE.User_x>());
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_USERSERVICE.updateUsersResponse_element()));
            svc.updateUsers(new List<DART6_USERSERVICE.User_x>());
        Test.stopTest();
    }

    /** Class DART6_ORDERSERVICE */
    static testMethod void testClassDART6_ORDERSERVICE()
    {
        DART6_ORDERSERVICE orderService = new DART6_ORDERSERVICE();

        DART6_ORDERSERVICE.CommonError ordComErr = new DART6_ORDERSERVICE.CommonError();
        DART6_ORDERSERVICE.ApproveOrdersWithoutReservationChanges ordApWithCh = new DART6_ORDERSERVICE.ApproveOrdersWithoutReservationChanges();
        DART6_ORDERSERVICE.InternalApiError ordInApiErr = new DART6_ORDERSERVICE.InternalApiError();
        DART6_ORDERSERVICE.ApproveOrders ordAppOrd = new DART6_ORDERSERVICE.ApproveOrders();
        DART6_ORDERSERVICE.OrderError ordErr = new DART6_ORDERSERVICE.OrderError();
        DART6_ORDERSERVICE.SubmitOrdersForApprovalAndOverbook ordSubOrdOver = new DART6_ORDERSERVICE.SubmitOrdersForApprovalAndOverbook();
        DART6_ORDERSERVICE.StringLengthError ordStringErr = new DART6_ORDERSERVICE.StringLengthError();
        DART6_ORDERSERVICE.BooleanValue ordBooVal = new DART6_ORDERSERVICE.BooleanValue();
        DART6_ORDERSERVICE.AppliedLabel ordApLab = new DART6_ORDERSERVICE.AppliedLabel();
        DART6_ORDERSERVICE.UniqueError ordUniErr = new DART6_ORDERSERVICE.UniqueError();
        DART6_ORDERSERVICE.RequiredError ordReErr = new DART6_ORDERSERVICE.RequiredError();
        DART6_ORDERSERVICE.PauseOrders ordPauOrd = new DART6_ORDERSERVICE.PauseOrders();
        DART6_ORDERSERVICE.OrderPage ordPage = new DART6_ORDERSERVICE.OrderPage();
        DART6_ORDERSERVICE.AuthenticationError ordAuthErr = new DART6_ORDERSERVICE.AuthenticationError();
        DART6_ORDERSERVICE.PermissionError ordPerErr = new DART6_ORDERSERVICE.PermissionError();
        DART6_ORDERSERVICE.PublisherQueryLanguageSyntaxError ordPUSyErr = new DART6_ORDERSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_ORDERSERVICE.DisapproveOrders ordDisOrd = new DART6_ORDERSERVICE.DisapproveOrders();
        DART6_ORDERSERVICE.String_ValueMapEntry ordStMapEnt = new DART6_ORDERSERVICE.String_ValueMapEntry();
        DART6_ORDERSERVICE.createOrdersResponse_element ordCreResEle = new DART6_ORDERSERVICE.createOrdersResponse_element();
        DART6_ORDERSERVICE.Value ordVal = new DART6_ORDERSERVICE.Value();
        DART6_ORDERSERVICE.DropDownCustomFieldValue ordDroFv = new DART6_ORDERSERVICE.DropDownCustomFieldValue();
        DART6_ORDERSERVICE.ArchiveOrders ordArOrd = new DART6_ORDERSERVICE.ArchiveOrders();
        DART6_ORDERSERVICE.BaseCustomFieldValue ordBasFV = new DART6_ORDERSERVICE.BaseCustomFieldValue();
        DART6_ORDERSERVICE.TypeError ordTypErr = new DART6_ORDERSERVICE.TypeError();
        DART6_ORDERSERVICE.getOrdersByStatement_element ordOrdStaEle = new DART6_ORDERSERVICE.getOrdersByStatement_element();
        DART6_ORDERSERVICE.NumberValue ordNumVal = new DART6_ORDERSERVICE.NumberValue();
        DART6_ORDERSERVICE.SoapResponseHeader ordSoapRes = new DART6_ORDERSERVICE.SoapResponseHeader();
        DART6_ORDERSERVICE.CustomFieldValue ordCusFv = new DART6_ORDERSERVICE.CustomFieldValue();
        DART6_ORDERSERVICE.updateOrdersResponse_element ordUpdRs = new DART6_ORDERSERVICE.updateOrdersResponse_element();
        DART6_ORDERSERVICE.updateOrders_element ordupOrd = new DART6_ORDERSERVICE.updateOrders_element();
        DART6_ORDERSERVICE.SubmitOrdersForApprovalWithoutReservationChanges ordsubForAPch = new DART6_ORDERSERVICE.SubmitOrdersForApprovalWithoutReservationChanges();
        DART6_ORDERSERVICE.NotNullError ordNotNullErr = new DART6_ORDERSERVICE.NotNullError();
        DART6_ORDERSERVICE.SubmitOrdersForApproval ordSuAppva = new DART6_ORDERSERVICE.SubmitOrdersForApproval();
        DART6_ORDERSERVICE.ResumeAndOverbookOrders ordResOvOrd = new DART6_ORDERSERVICE.ResumeAndOverbookOrders();
        DART6_ORDERSERVICE.DateTimeValue ordDateVal = new DART6_ORDERSERVICE.DateTimeValue();
        DART6_ORDERSERVICE.Statement ordStat = new DART6_ORDERSERVICE.Statement();
        DART6_ORDERSERVICE.CompanyCreditStatusError ordComStat = new DART6_ORDERSERVICE.CompanyCreditStatusError();
        DART6_ORDERSERVICE.createOrders_element ordcreOrd = new DART6_ORDERSERVICE.createOrders_element();
        DART6_ORDERSERVICE.PublisherQueryLanguageContextError ordPuConEr = new DART6_ORDERSERVICE.PublisherQueryLanguageContextError();
        DART6_ORDERSERVICE.ApiError ordApiErr = new DART6_ORDERSERVICE.ApiError();
        DART6_ORDERSERVICE.DisapproveOrdersWithoutReservationChanges ordDisWitCh = new DART6_ORDERSERVICE.DisapproveOrdersWithoutReservationChanges();
        DART6_ORDERSERVICE.TeamError ordTeamErr = new DART6_ORDERSERVICE.TeamError();
        DART6_ORDERSERVICE.ApproveAndOverbookOrders ordOverBookOrd = new DART6_ORDERSERVICE.ApproveAndOverbookOrders();
        DART6_ORDERSERVICE.CustomFieldValueError ordCusvalErr = new DART6_ORDERSERVICE.CustomFieldValueError();
        DART6_ORDERSERVICE.performOrderActionResponse_element ordPerOrdresEle = new DART6_ORDERSERVICE.performOrderActionResponse_element();
        DART6_ORDERSERVICE.ResumeOrders ordResOrd = new DART6_ORDERSERVICE.ResumeOrders();
        DART6_ORDERSERVICE.ForecastError ordFcErr = new DART6_ORDERSERVICE.ForecastError();
        DART6_ORDERSERVICE.QuotaError ordQuErr = new DART6_ORDERSERVICE.QuotaError();
        DART6_ORDERSERVICE.OrderActionError ordOrdAcErr = new DART6_ORDERSERVICE.OrderActionError();
        //DART6_ORDERSERVICE.ApplicationException_x ordApiExcep = new DART6_ORDERSERVICE.ApplicationException_x();
        DART6_ORDERSERVICE.RangeError ordranErr = new DART6_ORDERSERVICE.RangeError();
        DART6_ORDERSERVICE.ParseError ordParErr = new DART6_ORDERSERVICE.ParseError();
        DART6_ORDERSERVICE.Money ordMoney = new DART6_ORDERSERVICE.Money();
        DART6_ORDERSERVICE.ApiVersionError ordVerErr = new DART6_ORDERSERVICE.ApiVersionError();
        DART6_ORDERSERVICE.LabelEntityAssociationError ordLaAssErr = new DART6_ORDERSERVICE.LabelEntityAssociationError();
        DART6_ORDERSERVICE.RetractOrdersWithoutReservationChanges ordRetWithCh = new DART6_ORDERSERVICE.RetractOrdersWithoutReservationChanges();
        DART6_ORDERSERVICE.ServerError ordSerErr = new DART6_ORDERSERVICE.ServerError();
        DART6_ORDERSERVICE.OrderAction ordOrAc = new DART6_ORDERSERVICE.OrderAction();
        DART6_ORDERSERVICE.UnarchiveOrders ordUnOrd = new DART6_ORDERSERVICE.UnarchiveOrders();
        DART6_ORDERSERVICE.DateTime_x orddatex = new DART6_ORDERSERVICE.DateTime_x();
        DART6_ORDERSERVICE.StatementError ordStatErr = new DART6_ORDERSERVICE.StatementError();
        DART6_ORDERSERVICE.RequiredCollectionError ordReCollErr = new DART6_ORDERSERVICE.RequiredCollectionError();
        DART6_ORDERSERVICE.TextValue ordTxtVal = new DART6_ORDERSERVICE.TextValue();
        DART6_ORDERSERVICE.InvalidEmailError ordInvEr = new DART6_ORDERSERVICE.InvalidEmailError();
        DART6_ORDERSERVICE.RetractOrders ordRetOrd = new DART6_ORDERSERVICE.RetractOrders();
        DART6_ORDERSERVICE.UpdateResult ordUpResl = new DART6_ORDERSERVICE.UpdateResult();
        DART6_ORDERSERVICE.getOrdersByStatementResponse_element ordByStEle = new DART6_ORDERSERVICE.getOrdersByStatementResponse_element();
        DART6_ORDERSERVICE.performOrderAction_element ordordACEle = new DART6_ORDERSERVICE.performOrderAction_element();
        DART6_ORDERSERVICE.DeleteOrders ordDel = new DART6_ORDERSERVICE.DeleteOrders();
        
        DART6_ORDERSERVICE.TechnologyTargetingError tect = new DART6_ORDERSERVICE.TechnologyTargetingError();
        DART6_ORDERSERVICE.DateTimeRangeTargetingError dateRT= new DART6_ORDERSERVICE.DateTimeRangeTargetingError();
        DART6_ORDERSERVICE.SetValue setv= new DART6_ORDERSERVICE.SetValue();
        DART6_ORDERSERVICE.InventoryTargetingError inerr= new DART6_ORDERSERVICE.InventoryTargetingError();
        DART6_ORDERSERVICE.TemplateInstantiatedCreativeError tempIncr= new DART6_ORDERSERVICE.TemplateInstantiatedCreativeError();
        DART6_ORDERSERVICE.FeatureError feaErr = new DART6_ORDERSERVICE.FeatureError();
        DART6_ORDERSERVICE.LineItemOperationError linOper = new DART6_ORDERSERVICE.LineItemOperationError();
        DART6_ORDERSERVICE.ProgrammaticError  proEr= new DART6_ORDERSERVICE.ProgrammaticError();
        DART6_ORDERSERVICE.EntityLimitReachedError entityReErr= new DART6_ORDERSERVICE.EntityLimitReachedError();
        DART6_ORDERSERVICE.NullError nuLerr= new DART6_ORDERSERVICE.NullError();
        DART6_ORDERSERVICE.ApiException apiErr = new DART6_ORDERSERVICE.ApiException();
        DART6_ORDERSERVICE.ApplicationException appExce= new DART6_ORDERSERVICE.ApplicationException();
        DART6_ORDERSERVICE.GenericTargetingError gerTarErr= new DART6_ORDERSERVICE.GenericTargetingError();
        DART6_ORDERSERVICE.ContentMetadataTargetingError ContMeta= new DART6_ORDERSERVICE.ContentMetadataTargetingError();
        DART6_ORDERSERVICE.FrequencyCapError freCaperr= new DART6_ORDERSERVICE.FrequencyCapError();
        DART6_ORDERSERVICE.LineItemError linErr= new DART6_ORDERSERVICE.LineItemError();
        DART6_ORDERSERVICE.CreativeError creErr= new DART6_ORDERSERVICE.CreativeError();
        DART6_ORDERSERVICE.UserDomainTargetingError urDeoTarErr= new DART6_ORDERSERVICE.UserDomainTargetingError();
        DART6_ORDERSERVICE.AudienceExtensionError audieExerr= new DART6_ORDERSERVICE.AudienceExtensionError();
        DART6_ORDERSERVICE.ClickTrackingLineItemError clickLinErr = new DART6_ORDERSERVICE.ClickTrackingLineItemError();
        DART6_ORDERSERVICE.LineItemCreativeAssociationError lineCreAssErr= new DART6_ORDERSERVICE.LineItemCreativeAssociationError();
        DART6_ORDERSERVICE.InvalidUrlError invurErr= new DART6_ORDERSERVICE.InvalidUrlError();

        //@vitou 08-04-2015
        DART6_ORDERSERVICE.RequiredSizeError reqSizeErr = new DART6_ORDERSERVICE.RequiredSizeError();
        DART6_ORDERSERVICE.RequiredNumberError reqNumErr = new DART6_ORDERSERVICE.RequiredNumberError();
        DART6_ORDERSERVICE.ReservationDetailsError ResDetErr = new DART6_ORDERSERVICE.ReservationDetailsError();
        DART6_ORDERSERVICE.DayPartTargetingError dayTarErr = new DART6_ORDERSERVICE.DayPartTargetingError();
        DART6_ORDERSERVICE.GeoTargetingError geoTarErr = new DART6_ORDERSERVICE.GeoTargetingError();
        DART6_ORDERSERVICE.DateValue dateVal = new DART6_ORDERSERVICE.DateValue();
        
        DART6_ORDERSERVICE.CustomTargetingError custTarErr = new DART6_ORDERSERVICE.CustomTargetingError();
        DART6_ORDERSERVICE.LineItemFlightDateError linItemFligErr = new DART6_ORDERSERVICE.LineItemFlightDateError();
        DART6_ORDERSERVICE.EntityChildrenLimitReachedError entChldLimErr = new DART6_ORDERSERVICE.EntityChildrenLimitReachedError();
        
        Object o = new DART6_ORDERSERVICE.CrossSellError();
        o = new DART6_ORDERSERVICE.TimeZoneError();
        o = new DART6_ORDERSERVICE.VideoPositionTargetingError();
        o = new DART6_ORDERSERVICE.SetTopBoxLineItemError();
        o = new DART6_ORDERSERVICE.ObjectValue();
        o = new DART6_ORDERSERVICE.LineItemActivityAssociationError();
        o = new DART6_ORDERSERVICE.GrpSettingsError();
        o = new DART6_ORDERSERVICE.ImageError();
        o = new DART6_ORDERSERVICE.RegExError();
        o = new DART6_ORDERSERVICE.CollectionSizeError();
        
        o = new DART6_ORDERSERVICE.AudienceSegmentError();
        o = new DART6_ORDERSERVICE.CollectionSizeError();
        o = new DART6_ORDERSERVICE.CollectionSizeError();
        o = new DART6_ORDERSERVICE.CollectionSizeError();
        
        Test.startTest();
            DART6_ORDERSERVICE.OrderServiceInterfacePort svc = new DART6_ORDERSERVICE.OrderServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_ORDERSERVICE.performOrderActionResponse_element()));
            svc.performOrderAction(new DART6_ORDERSERVICE.OrderAction(), new DART6_ORDERSERVICE.Statement());
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_ORDERSERVICE.updateOrdersResponse_element()));
            svc.updateOrders(new List<DART6_ORDERSERVICE.Order>());
        Test.stopTest();
        
    }

    /** Class DART6_LINEITEMSERVICE */
    static testMethod void testClassDART6_LINEITEMSERVICE()
    {
        DART6_LINEITEMSERVICE lineItem  = new DART6_LINEITEMSERVICE();
        DART6_LINEITEMSERVICE.FrequencyCap itemFreCap = new DART6_LINEITEMSERVICE.FrequencyCap();
        DART6_LINEITEMSERVICE.BrowserTargeting item1BwTar= new DART6_LINEITEMSERVICE.BrowserTargeting();
        DART6_LINEITEMSERVICE.CommonError item1ComErr = new DART6_LINEITEMSERVICE.CommonError();
        DART6_LINEITEMSERVICE.Technology item1Technology = new DART6_LINEITEMSERVICE.Technology();
        DART6_LINEITEMSERVICE.ReserveAndOverbookLineItems item1ReAndOverBook = new DART6_LINEITEMSERVICE.ReserveAndOverbookLineItems();
        DART6_LINEITEMSERVICE.TechnologyTargetingError item1 = new DART6_LINEITEMSERVICE.TechnologyTargetingError();
        DART6_LINEITEMSERVICE.ReserveLineItems item2 = new DART6_LINEITEMSERVICE.ReserveLineItems();
        DART6_LINEITEMSERVICE.InternalApiError item3 = new DART6_LINEITEMSERVICE.InternalApiError();
        DART6_LINEITEMSERVICE.LineItemSummary item4 = new DART6_LINEITEMSERVICE.LineItemSummary();
        DART6_LINEITEMSERVICE.BandwidthGroup item5 = new DART6_LINEITEMSERVICE.BandwidthGroup();
        DART6_LINEITEMSERVICE.OrderError item6 = new DART6_LINEITEMSERVICE.OrderError();
        DART6_LINEITEMSERVICE.DateTimeRangeTargetingError item7 = new DART6_LINEITEMSERVICE.DateTimeRangeTargetingError();
        DART6_LINEITEMSERVICE.UserDomainTargeting item9 = new DART6_LINEITEMSERVICE.UserDomainTargeting();
        DART6_LINEITEMSERVICE.InventoryTargetingError item10 = new DART6_LINEITEMSERVICE.InventoryTargetingError();
        DART6_LINEITEMSERVICE.DayPartTargeting item11 = new DART6_LINEITEMSERVICE.DayPartTargeting();
        DART6_LINEITEMSERVICE.BooleanValue itema = new DART6_LINEITEMSERVICE.BooleanValue();
        DART6_LINEITEMSERVICE.RequiredError itemb = new DART6_LINEITEMSERVICE.RequiredError();
        DART6_LINEITEMSERVICE.CustomCriteriaLeaf itemc = new DART6_LINEITEMSERVICE.CustomCriteriaLeaf();
        DART6_LINEITEMSERVICE.AuthenticationError itemd = new DART6_LINEITEMSERVICE.AuthenticationError();
        DART6_LINEITEMSERVICE.PermissionError itemf = new DART6_LINEITEMSERVICE.PermissionError();
        DART6_LINEITEMSERVICE.DeviceManufacturerTargeting itemg = new DART6_LINEITEMSERVICE.DeviceManufacturerTargeting();
        DART6_LINEITEMSERVICE.updateLineItemsResponse_element itemh = new DART6_LINEITEMSERVICE.updateLineItemsResponse_element();
        DART6_LINEITEMSERVICE.InventoryTargeting itemi = new DART6_LINEITEMSERVICE.InventoryTargeting();
        DART6_LINEITEMSERVICE.LineItemOperationError itemgss = new DART6_LINEITEMSERVICE.LineItemOperationError();
        DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting itemk = new DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting();
        DART6_LINEITEMSERVICE.ReleaseLineItems itemRel = new DART6_LINEITEMSERVICE.ReleaseLineItems();
        DART6_LINEITEMSERVICE.OperatingSystemTargeting itemOpsTar = new DART6_LINEITEMSERVICE.OperatingSystemTargeting();
        DART6_LINEITEMSERVICE.MobileDevice itemModdv = new DART6_LINEITEMSERVICE.MobileDevice();
        DART6_LINEITEMSERVICE.BandwidthGroupTargeting itembdTa = new DART6_LINEITEMSERVICE.BandwidthGroupTargeting();
        DART6_LINEITEMSERVICE.CustomCriteria itemcus = new DART6_LINEITEMSERVICE.CustomCriteria();
        DART6_LINEITEMSERVICE.BaseCustomFieldValue itembasFv = new DART6_LINEITEMSERVICE.BaseCustomFieldValue();
        DART6_LINEITEMSERVICE.NumberValue itemnv = new DART6_LINEITEMSERVICE.NumberValue();
        DART6_LINEITEMSERVICE.GeoTargeting itemGo = new DART6_LINEITEMSERVICE.GeoTargeting();
        DART6_LINEITEMSERVICE.TimeOfDay itemToD = new DART6_LINEITEMSERVICE.TimeOfDay();
        DART6_LINEITEMSERVICE.CustomFieldValue itemcFv = new DART6_LINEITEMSERVICE.CustomFieldValue();
        DART6_LINEITEMSERVICE.SoapResponseHeader itemsoapResHe = new DART6_LINEITEMSERVICE.SoapResponseHeader();
        DART6_LINEITEMSERVICE.CustomCriteriaSet itemCusSet = new DART6_LINEITEMSERVICE.CustomCriteriaSet();
        DART6_LINEITEMSERVICE.NotNullError itemNotNul = new DART6_LINEITEMSERVICE.NotNullError();
        DART6_LINEITEMSERVICE.AudienceSegmentCriteria itemAudSeCr = new DART6_LINEITEMSERVICE.AudienceSegmentCriteria();
        DART6_LINEITEMSERVICE.EntityLimitReachedError itemEnReErr = new DART6_LINEITEMSERVICE.EntityLimitReachedError();
        DART6_LINEITEMSERVICE.BrowserLanguageTargeting itemBrowTar = new DART6_LINEITEMSERVICE.BrowserLanguageTargeting();
        DART6_LINEITEMSERVICE.DateTimeValue itemDateTimeVal = new DART6_LINEITEMSERVICE.DateTimeValue();
        DART6_LINEITEMSERVICE.CompanyCreditStatusError itemComStaErr = new DART6_LINEITEMSERVICE.CompanyCreditStatusError();
        DART6_LINEITEMSERVICE.AdUnitTargeting itemAdUnit = new DART6_LINEITEMSERVICE.AdUnitTargeting();
        DART6_LINEITEMSERVICE.PublisherQueryLanguageContextError itemPubLaCon = new DART6_LINEITEMSERVICE.PublisherQueryLanguageContextError();
        DART6_LINEITEMSERVICE.performLineItemAction_element itemPerIAc = new DART6_LINEITEMSERVICE.performLineItemAction_element();
        DART6_LINEITEMSERVICE.SoapRequestHeader itemSoaHe = new DART6_LINEITEMSERVICE.SoapRequestHeader();
        DART6_LINEITEMSERVICE.TeamError itemTeamErr = new DART6_LINEITEMSERVICE.TeamError();
        DART6_LINEITEMSERVICE.ResumeAndOverbookLineItems itemResOvB = new DART6_LINEITEMSERVICE.ResumeAndOverbookLineItems();
        DART6_LINEITEMSERVICE.DeviceCategoryTargeting itemDevCatTar = new DART6_LINEITEMSERVICE.DeviceCategoryTargeting();
        DART6_LINEITEMSERVICE.NullError itemNuErr = new DART6_LINEITEMSERVICE.NullError();
        DART6_LINEITEMSERVICE.ApiException itemApiEx = new DART6_LINEITEMSERVICE.ApiException();
        DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting itemopeverTar = new DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting();
        DART6_LINEITEMSERVICE.ForecastError itemFc = new DART6_LINEITEMSERVICE.ForecastError();
        DART6_LINEITEMSERVICE.LineItemPage itemPage = new DART6_LINEITEMSERVICE.LineItemPage();
        DART6_LINEITEMSERVICE.MobileCarrierTargeting itemMoTar = new DART6_LINEITEMSERVICE.MobileCarrierTargeting();
        DART6_LINEITEMSERVICE.ApplicationException itemAppExc = new DART6_LINEITEMSERVICE.ApplicationException();
        DART6_LINEITEMSERVICE.GenericTargetingError itemGenTarErr = new DART6_LINEITEMSERVICE.GenericTargetingError();
        DART6_LINEITEMSERVICE.ApiVersionError itemApiverErr = new DART6_LINEITEMSERVICE.ApiVersionError();
        DART6_LINEITEMSERVICE.createLineItemsResponse_element itemcreResEle = new DART6_LINEITEMSERVICE.createLineItemsResponse_element();
        DART6_LINEITEMSERVICE.ContentTargeting itemContTar = new DART6_LINEITEMSERVICE.ContentTargeting();
        DART6_LINEITEMSERVICE.ServerError itemSerErr = new DART6_LINEITEMSERVICE.ServerError();
        DART6_LINEITEMSERVICE.FrequencyCapError itemFreErr = new DART6_LINEITEMSERVICE.FrequencyCapError();
        DART6_LINEITEMSERVICE.UnarchiveLineItems itemUna = new DART6_LINEITEMSERVICE.UnarchiveLineItems();
        DART6_LINEITEMSERVICE.DeviceCapabilityTargeting itemdevTar = new DART6_LINEITEMSERVICE.DeviceCapabilityTargeting();
        DART6_LINEITEMSERVICE.LineItemError itemEr = new DART6_LINEITEMSERVICE.LineItemError();
        DART6_LINEITEMSERVICE.performLineItemActionResponse_element itemPeracRes = new DART6_LINEITEMSERVICE.performLineItemActionResponse_element();
        DART6_LINEITEMSERVICE.DeviceCategory itemDev = new DART6_LINEITEMSERVICE.DeviceCategory();
        DART6_LINEITEMSERVICE.DeviceManufacturer itemDevMan = new DART6_LINEITEMSERVICE.DeviceManufacturer();
        DART6_LINEITEMSERVICE.BrowserLanguage itemBrovseLan = new DART6_LINEITEMSERVICE.BrowserLanguage();
        DART6_LINEITEMSERVICE.MobileDeviceSubmodel itemModSub = new DART6_LINEITEMSERVICE.MobileDeviceSubmodel();
        DART6_LINEITEMSERVICE.createLineItems_element itemcreaEl = new DART6_LINEITEMSERVICE.createLineItems_element();
        DART6_LINEITEMSERVICE.CustomCriteriaNode itemCusNod = new DART6_LINEITEMSERVICE.CustomCriteriaNode();
        DART6_LINEITEMSERVICE.StringLengthError itemstrLengErr = new DART6_LINEITEMSERVICE.StringLengthError();
        DART6_LINEITEMSERVICE.UserDomainTargetingError itemUseDoErr = new DART6_LINEITEMSERVICE.UserDomainTargetingError();
        DART6_LINEITEMSERVICE.AppliedLabel itemAppla = new DART6_LINEITEMSERVICE.AppliedLabel();
        DART6_LINEITEMSERVICE.ActivateLineItems itemActivate = new DART6_LINEITEMSERVICE.ActivateLineItems();
        DART6_LINEITEMSERVICE.UniqueError itemuniquErr = new DART6_LINEITEMSERVICE.UniqueError();
        DART6_LINEITEMSERVICE.ResumeLineItems itemResum = new DART6_LINEITEMSERVICE.ResumeLineItems();
        DART6_LINEITEMSERVICE.getLineItemsByStatementResponse_element itemgetLineResEle = new DART6_LINEITEMSERVICE.getLineItemsByStatementResponse_element();
        DART6_LINEITEMSERVICE.PublisherQueryLanguageSyntaxError itemPulbSynErr = new DART6_LINEITEMSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_LINEITEMSERVICE.DeliveryData itemDevData = new DART6_LINEITEMSERVICE.DeliveryData();
        DART6_LINEITEMSERVICE.AudienceExtensionError itemaudErr = new DART6_LINEITEMSERVICE.AudienceExtensionError();
        DART6_LINEITEMSERVICE.ClickTrackingLineItemError itemopSysErr = new DART6_LINEITEMSERVICE.ClickTrackingLineItemError();
        DART6_LINEITEMSERVICE.OperatingSystem itemopSys = new DART6_LINEITEMSERVICE.OperatingSystem();
        DART6_LINEITEMSERVICE.String_ValueMapEntry itemstrValMap = new DART6_LINEITEMSERVICE.String_ValueMapEntry();
        DART6_LINEITEMSERVICE.Size itemSize = new DART6_LINEITEMSERVICE.Size();
        DART6_LINEITEMSERVICE.Value itemval = new DART6_LINEITEMSERVICE.Value();
        DART6_LINEITEMSERVICE.DropDownCustomFieldValue itemDropCus = new DART6_LINEITEMSERVICE.DropDownCustomFieldValue();
        DART6_LINEITEMSERVICE.LineItemCreativeAssociationError itemLineAss = new DART6_LINEITEMSERVICE.LineItemCreativeAssociationError();
        DART6_LINEITEMSERVICE.InvalidUrlError itemInvaUrlErr = new DART6_LINEITEMSERVICE.InvalidUrlError();
        DART6_LINEITEMSERVICE.RequiredSizeError itemReqSizeErr = new DART6_LINEITEMSERVICE.RequiredSizeError();
        DART6_LINEITEMSERVICE.TypeError itemTypeErr = new DART6_LINEITEMSERVICE.TypeError();
        DART6_LINEITEMSERVICE.VideoPositionTargeting itemVaTarg = new DART6_LINEITEMSERVICE.VideoPositionTargeting();
        DART6_LINEITEMSERVICE.RequiredNumberError itemReNumErr = new DART6_LINEITEMSERVICE.RequiredNumberError();
        DART6_LINEITEMSERVICE.ReservationDetailsError itemResDetErr = new DART6_LINEITEMSERVICE.ReservationDetailsError();
        DART6_LINEITEMSERVICE.LineItemAction itemAc = new DART6_LINEITEMSERVICE.LineItemAction();
        DART6_LINEITEMSERVICE.Statement itemStat = new DART6_LINEITEMSERVICE.Statement();
        DART6_LINEITEMSERVICE.ApiError itemApiErr = new DART6_LINEITEMSERVICE.ApiError();
        DART6_LINEITEMSERVICE.Browser itemBw = new DART6_LINEITEMSERVICE.Browser();
        DART6_LINEITEMSERVICE.LineItemServiceInterfacePort itemInfPort = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
        DART6_LINEITEMSERVICE.CustomFieldValueError itemCusErr = new DART6_LINEITEMSERVICE.CustomFieldValueError();
        DART6_LINEITEMSERVICE.DayPartTargetingError itemDayErr = new DART6_LINEITEMSERVICE.DayPartTargetingError();
        DART6_LINEITEMSERVICE.GeoTargetingError itemGeoTarErr = new DART6_LINEITEMSERVICE.GeoTargetingError();
        DART6_LINEITEMSERVICE.QuotaError itemQuoErr = new DART6_LINEITEMSERVICE.QuotaError();
        DART6_LINEITEMSERVICE.MobileDeviceTargeting itemModTar = new DART6_LINEITEMSERVICE.MobileDeviceTargeting();
        DART6_LINEITEMSERVICE.getLineItemsByStatement_element itemBySt = new DART6_LINEITEMSERVICE.getLineItemsByStatement_element();
        DART6_LINEITEMSERVICE.RangeError itemRaErr = new DART6_LINEITEMSERVICE.RangeError();
        DART6_LINEITEMSERVICE.ParseError itemParErr = new DART6_LINEITEMSERVICE.ParseError();
        DART6_LINEITEMSERVICE.PauseLineItems itemPus = new DART6_LINEITEMSERVICE.PauseLineItems();
        DART6_LINEITEMSERVICE.LabelEntityAssociationError itemLaAssErr = new DART6_LINEITEMSERVICE.LabelEntityAssociationError();
        DART6_LINEITEMSERVICE.DeviceCapability itemDevCap = new DART6_LINEITEMSERVICE.DeviceCapability();
        DART6_LINEITEMSERVICE.DeliveryIndicator itemDeInd = new DART6_LINEITEMSERVICE.DeliveryIndicator();
        DART6_LINEITEMSERVICE.StatementError itemstatErr = new DART6_LINEITEMSERVICE.StatementError();
        DART6_LINEITEMSERVICE.ArchiveLineItems itemArch = new DART6_LINEITEMSERVICE.ArchiveLineItems();
        DART6_LINEITEMSERVICE.CreativePlaceholder itemCreHolder = new DART6_LINEITEMSERVICE.CreativePlaceholder();
        DART6_LINEITEMSERVICE.DeleteLineItems itemDelet = new DART6_LINEITEMSERVICE.DeleteLineItems();
        DART6_LINEITEMSERVICE.RequiredCollectionError itemRqueErr = new DART6_LINEITEMSERVICE.RequiredCollectionError();
        DART6_LINEITEMSERVICE.CustomTargetingError itemCustErr = new DART6_LINEITEMSERVICE.CustomTargetingError();
        DART6_LINEITEMSERVICE.TextValue itemTxtVal = new DART6_LINEITEMSERVICE.TextValue();
        DART6_LINEITEMSERVICE.LineItemFlightDateError itemFliDate = new DART6_LINEITEMSERVICE.LineItemFlightDateError();
        DART6_LINEITEMSERVICE.MobileCarrier itemMobCar = new DART6_LINEITEMSERVICE.MobileCarrier();
        DART6_LINEITEMSERVICE.updateLineItems_element itemUpElement = new DART6_LINEITEMSERVICE.updateLineItems_element();
        DART6_LINEITEMSERVICE.Stats itemState = new DART6_LINEITEMSERVICE.Stats();
        DART6_LINEITEMSERVICE.UpdateResult itemupRes = new DART6_LINEITEMSERVICE.UpdateResult();
        //DART6_LINEITEMSERVICE.PostalCodeLocation itemPosLoc = new DART6_LINEITEMSERVICE.PostalCodeLocation();
        DART6_LINEITEMSERVICE.OperatingSystemVersion itemopSysverson = new DART6_LINEITEMSERVICE.OperatingSystemVersion();
        DART6_LINEITEMSERVICE.VideoPositionTargeting vidpos = new DART6_LINEITEMSERVICE.VideoPositionTargeting();
        DART6_LINEITEMSERVICE.GrpSettings grpSet = new DART6_LINEITEMSERVICE.GrpSettings();
        DART6_LINEITEMSERVICE.SetValue sv   = new  DART6_LINEITEMSERVICE.SetValue();
        DART6_LINEITEMSERVICE.DateTime_x dtx   = new  DART6_LINEITEMSERVICE.DateTime_x();
        DART6_LINEITEMSERVICE.Date_x dx = new  DART6_LINEITEMSERVICE.Date_x();
        DART6_LINEITEMSERVICE.FeatureError fE = new  DART6_LINEITEMSERVICE.FeatureError();
        DART6_LINEITEMSERVICE.ProgrammaticError prg = new  DART6_LINEITEMSERVICE.ProgrammaticError();

        Object o = new  DART6_LINEITEMSERVICE.CrossSellError();
        o = new  DART6_LINEITEMSERVICE.CrossSellError();
        o = new  DART6_LINEITEMSERVICE.SetTopBoxInfo();
        o = new  DART6_LINEITEMSERVICE.VideoPositionWithinPod();
        o = new  DART6_LINEITEMSERVICE.ContentMetadataTargetingError();
        o = new  DART6_LINEITEMSERVICE.CreativeError();
        o = new  DART6_LINEITEMSERVICE.EntityChildrenLimitReachedError();
        o = new  DART6_LINEITEMSERVICE.DateValue();
        o = new  DART6_LINEITEMSERVICE.TimeZoneError();
        o = new  DART6_LINEITEMSERVICE.VideoPositionTargetingError();
        o = new  DART6_LINEITEMSERVICE.SetTopBoxLineItemError();
        o = new  DART6_LINEITEMSERVICE.LineItemActivityAssociation();
        o = new  DART6_LINEITEMSERVICE.ObjectValue();
        o = new  DART6_LINEITEMSERVICE.CollectionSizeError();
        o = new  DART6_LINEITEMSERVICE.LineItemActivityAssociationError();
        o = new  DART6_LINEITEMSERVICE.GrpSettingsError();
        o = new  DART6_LINEITEMSERVICE.CreativeTargeting();
        o = new  DART6_LINEITEMSERVICE.ContentMetadataKeyHierarchyTargeting();
        o = new  DART6_LINEITEMSERVICE.OrderActionError();
        o = new  DART6_LINEITEMSERVICE.VideoPosition();
        o = new  DART6_LINEITEMSERVICE.ImageError();
        o = new  DART6_LINEITEMSERVICE.DayPart();
        o = new  DART6_LINEITEMSERVICE.RegExError();
        
        o = new  DART6_LINEITEMSERVICE.VideoPositionTarget();
        o = new  DART6_LINEITEMSERVICE.AudienceSegmentError();
        o = new  DART6_LINEITEMSERVICE.RegExError();
        o = new  DART6_LINEITEMSERVICE.RegExError();
        o = new  DART6_LINEITEMSERVICE.RegExError();
        o = new  DART6_LINEITEMSERVICE.RegExError();
        
        Test.startTest();
            DART6_LINEITEMSERVICE.LineItemServiceInterfacePort svc = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
            svc.createLineItems(new DART6_LINEITEMSERVICE.LineItem[0]);
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_LINEITEMSERVICE.performLineItemActionResponse_element()));
            svc.performLineItemAction(new DART6_LINEITEMSERVICE.LineItemAction(), new DART6_LINEITEMSERVICE.Statement());
            
        Test.stopTest();
    }


    /** Class DART6_FORECASTSERVICE */
    static testMethod void testClassDart6AvailabilityForecast()
    {
        DART6_FORECASTSERVICE dart6FcService = new DART6_FORECASTSERVICE();
        DART6_FORECASTSERVICE.AdUnitCodeError adUnitError = new DART6_FORECASTSERVICE.AdUnitCodeError();
        DART6_FORECASTSERVICE.AdUnitTargeting adUnitTar = new DART6_FORECASTSERVICE.AdUnitTargeting();
        DART6_FORECASTSERVICE.ApiError apiEr = new DART6_FORECASTSERVICE.ApiError();
        DART6_FORECASTSERVICE.ApiException apiEx = new DART6_FORECASTSERVICE.ApiException();
        DART6_FORECASTSERVICE.ApiVersionError apiVerErr = new DART6_FORECASTSERVICE.ApiVersionError();
        DART6_FORECASTSERVICE.ApplicationException appExc = new DART6_FORECASTSERVICE.ApplicationException();
        DART6_FORECASTSERVICE.AppliedLabel applLabel = new DART6_FORECASTSERVICE.AppliedLabel();
        DART6_FORECASTSERVICE.AudienceExtensionError auEx = new DART6_FORECASTSERVICE.AudienceExtensionError();
        DART6_FORECASTSERVICE.AudienceSegmentCriteria auSeg = new DART6_FORECASTSERVICE.AudienceSegmentCriteria();
        DART6_FORECASTSERVICE.BandwidthGroupTargeting bwgt = new DART6_FORECASTSERVICE.BandwidthGroupTargeting();
        DART6_FORECASTSERVICE.BaseCustomFieldValue baseCus = new DART6_FORECASTSERVICE.BaseCustomFieldValue();
        DART6_FORECASTSERVICE.Browser brw = new DART6_FORECASTSERVICE.Browser();
        DART6_FORECASTSERVICE.BrowserLanguage brwLan = new DART6_FORECASTSERVICE.BrowserLanguage();
        DART6_FORECASTSERVICE.BrowserLanguageTargeting bwlt = new DART6_FORECASTSERVICE.BrowserLanguageTargeting();
        DART6_FORECASTSERVICE.BrowserTargeting bt = new DART6_FORECASTSERVICE.BrowserTargeting();
        //DART6_FORECASTSERVICE.CityLocation ctLoc = new DART6_FORECASTSERVICE.CityLocation();
        DART6_FORECASTSERVICE.ClickTrackingLineItemError clTrac = new DART6_FORECASTSERVICE.ClickTrackingLineItemError();
        DART6_FORECASTSERVICE.CompanyCreditStatusError comCred = new DART6_FORECASTSERVICE.CompanyCreditStatusError();
        DART6_FORECASTSERVICE.ContentTargeting contar = new DART6_FORECASTSERVICE.ContentTargeting();
        //DART6_FORECASTSERVICE.CountryLocation counLoc = new DART6_FORECASTSERVICE.CountryLocation();
        DART6_FORECASTSERVICE.CustomTargetingError custarErr = new DART6_FORECASTSERVICE.CustomTargetingError();
        DART6_FORECASTSERVICE.CustomFieldValueError cusFvErr = new DART6_FORECASTSERVICE.CustomFieldValueError();
        DART6_FORECASTSERVICE.CustomFieldValue cusFv = new DART6_FORECASTSERVICE.CustomFieldValue();
        DART6_FORECASTSERVICE.CustomCriteriaSet cusCritSet = new DART6_FORECASTSERVICE.CustomCriteriaSet();
        DART6_FORECASTSERVICE.CustomCriteriaNode custCritNode = new DART6_FORECASTSERVICE.CustomCriteriaNode();
        DART6_FORECASTSERVICE.CustomCriteriaLeaf cusCritLeaf = new DART6_FORECASTSERVICE.CustomCriteriaLeaf();
        DART6_FORECASTSERVICE.CustomCriteria custCrit = new DART6_FORECASTSERVICE.CustomCriteria();
        DART6_FORECASTSERVICE.CreativePlaceholder creatPlh = new DART6_FORECASTSERVICE.CreativePlaceholder();
        DART6_FORECASTSERVICE.DayPart dayPart = new DART6_FORECASTSERVICE.DayPart();
        DART6_FORECASTSERVICE.DayPartTargeting dayPartTar = new DART6_FORECASTSERVICE.DayPartTargeting();
        DART6_FORECASTSERVICE.DropDownCustomFieldValue dropCus = new DART6_FORECASTSERVICE.DropDownCustomFieldValue();
        DART6_FORECASTSERVICE.DeviceManufacturer devManu = new DART6_FORECASTSERVICE.DeviceManufacturer();
        DART6_FORECASTSERVICE.DeviceCategoryTargeting devcateTar = new DART6_FORECASTSERVICE.DeviceCategoryTargeting();
        DART6_FORECASTSERVICE.DeviceCategory devCat = new DART6_FORECASTSERVICE.DeviceCategory();
        DART6_FORECASTSERVICE.DeviceCapabilityTargeting devCap = new DART6_FORECASTSERVICE.DeviceCapabilityTargeting();
        DART6_FORECASTSERVICE.DeviceCapability devCapility = new DART6_FORECASTSERVICE.DeviceCapability();
        DART6_FORECASTSERVICE.DeliveryIndicator devInd = new DART6_FORECASTSERVICE.DeliveryIndicator();
        DART6_FORECASTSERVICE.DeliveryData devData = new DART6_FORECASTSERVICE.DeliveryData();
        DART6_FORECASTSERVICE.DayPartTargetingError dayParErr = new DART6_FORECASTSERVICE.DayPartTargetingError();
        DART6_FORECASTSERVICE.DayPartTargeting dayPartTarg = new DART6_FORECASTSERVICE.DayPartTargeting();
        DART6_FORECASTSERVICE.EntityLimitReachedError entErr = new DART6_FORECASTSERVICE.EntityLimitReachedError();
        DART6_FORECASTSERVICE.ForecastError fcerr = new DART6_FORECASTSERVICE.ForecastError();
        DART6_FORECASTSERVICE.FrequencyCap freq = new DART6_FORECASTSERVICE.FrequencyCap();
        DART6_FORECASTSERVICE.FrequencyCapError freCapErr = new DART6_FORECASTSERVICE.FrequencyCapError();
        DART6_FORECASTSERVICE.GenericTargetingError genTar = new DART6_FORECASTSERVICE.GenericTargetingError();
        DART6_FORECASTSERVICE.GeoTargeting geoTar = new DART6_FORECASTSERVICE.GeoTargeting();
        DART6_FORECASTSERVICE.GeoTargetingError geoTarErr = new DART6_FORECASTSERVICE.GeoTargetingError();
        DART6_FORECASTSERVICE.InvalidUrlError inurlErr = new DART6_FORECASTSERVICE.InvalidUrlError();
        DART6_FORECASTSERVICE.InventoryTargeting invTarg = new DART6_FORECASTSERVICE.InventoryTargeting();
        DART6_FORECASTSERVICE.LabelEntityAssociationError labelEnAss = new DART6_FORECASTSERVICE.LabelEntityAssociationError();
        DART6_FORECASTSERVICE.LineItemCreativeAssociationError itemCreAss = new DART6_FORECASTSERVICE.LineItemCreativeAssociationError();
        DART6_FORECASTSERVICE.LineItemError itemErr = new DART6_FORECASTSERVICE.LineItemError();
        DART6_FORECASTSERVICE.LineItemFlightDateError lineFlighDateErr = new DART6_FORECASTSERVICE.LineItemFlightDateError();
        DART6_FORECASTSERVICE.Location lac = new DART6_FORECASTSERVICE.Location();
        //DART6_FORECASTSERVICE.MetroLocation metroLoc = new DART6_FORECASTSERVICE.MetroLocation();
        DART6_FORECASTSERVICE.MobileCarrier mobileCarr = new DART6_FORECASTSERVICE.MobileCarrier();
        DART6_FORECASTSERVICE.MobileCarrierTargeting mobCarTar = new DART6_FORECASTSERVICE.MobileCarrierTargeting();
        DART6_FORECASTSERVICE.MobileDevice mbDev = new DART6_FORECASTSERVICE.MobileDevice();
        DART6_FORECASTSERVICE.MobileDeviceSubmodel mobDevSub = new DART6_FORECASTSERVICE.MobileDeviceSubmodel();
        DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting mobDebSubModTar = new DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting();
        DART6_FORECASTSERVICE.MobileDeviceTargeting mobDevTar = new DART6_FORECASTSERVICE.MobileDeviceTargeting();
        DART6_FORECASTSERVICE.Money my = new DART6_FORECASTSERVICE.Money();
        DART6_FORECASTSERVICE.NotNullError notnullErr = new DART6_FORECASTSERVICE.NotNullError();
        DART6_FORECASTSERVICE.NullError nullErr = new DART6_FORECASTSERVICE.NullError();
        DART6_FORECASTSERVICE.NumberValue numVal = new DART6_FORECASTSERVICE.NumberValue();
        DART6_FORECASTSERVICE.OperatingSystem opSys = new DART6_FORECASTSERVICE.OperatingSystem();
        DART6_FORECASTSERVICE.OperatingSystemTargeting opSysTar = new DART6_FORECASTSERVICE.OperatingSystemTargeting();
        DART6_FORECASTSERVICE.OperatingSystemVersion optSysVer = new DART6_FORECASTSERVICE.OperatingSystemVersion();
        DART6_FORECASTSERVICE.OperatingSystemVersionTargeting optSysVerTar = new DART6_FORECASTSERVICE.OperatingSystemVersionTargeting();
        DART6_FORECASTSERVICE.QuotaError quotErr = new DART6_FORECASTSERVICE.QuotaError();
        DART6_FORECASTSERVICE.ParseError parsErr = new DART6_FORECASTSERVICE.ParseError();
        //DART6_FORECASTSERVICE.PostalCodeLocation posCodeLoc = new DART6_FORECASTSERVICE.PostalCodeLocation();
        DART6_FORECASTSERVICE.PublisherQueryLanguageContextError pubQueLangCon = new DART6_FORECASTSERVICE.PublisherQueryLanguageContextError();
        DART6_FORECASTSERVICE.PublisherQueryLanguageSyntaxError pbQuLocErr = new DART6_FORECASTSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_FORECASTSERVICE.RangeError rageErr = new DART6_FORECASTSERVICE.RangeError();
        DART6_FORECASTSERVICE.RegExError ReExErr = new DART6_FORECASTSERVICE.RegExError();
        //DART6_FORECASTSERVICE.RegionLocation regLoc = new DART6_FORECASTSERVICE.RegionLocation();
        DART6_FORECASTSERVICE.RequiredCollectionError reqCollErr = new DART6_FORECASTSERVICE.RequiredCollectionError();
        DART6_FORECASTSERVICE.RequiredError reqErr = new DART6_FORECASTSERVICE.RequiredError();
        DART6_FORECASTSERVICE.RequiredNumberError ReNum = new DART6_FORECASTSERVICE.RequiredNumberError();
        DART6_FORECASTSERVICE.RequiredSizeError reqSizeErr = new DART6_FORECASTSERVICE.RequiredSizeError();
        DART6_FORECASTSERVICE.ReservationDetailsError ResDetailErr = new DART6_FORECASTSERVICE.ReservationDetailsError();
        DART6_FORECASTSERVICE.ServerError serErr = new DART6_FORECASTSERVICE.ServerError();
        DART6_FORECASTSERVICE.StatementError stateErr = new DART6_FORECASTSERVICE.StatementError();
        DART6_FORECASTSERVICE.Stats stats  = new DART6_FORECASTSERVICE.Stats();
        DART6_FORECASTSERVICE.StringLengthError strLengErr = new DART6_FORECASTSERVICE.StringLengthError();
        DART6_FORECASTSERVICE.TeamError teatErr = new DART6_FORECASTSERVICE.TeamError();
        DART6_FORECASTSERVICE.Technology technology = new DART6_FORECASTSERVICE.Technology();
        DART6_FORECASTSERVICE.TechnologyTargeting techTar = new DART6_FORECASTSERVICE.TechnologyTargeting();
        DART6_FORECASTSERVICE.TechnologyTargetingError tecTarErr = new DART6_FORECASTSERVICE.TechnologyTargetingError();
        DART6_FORECASTSERVICE.TextValue txtVal = new DART6_FORECASTSERVICE.TextValue();
        DART6_FORECASTSERVICE.TimeOfDay timeofDay = new DART6_FORECASTSERVICE.TimeOfDay();
        DART6_FORECASTSERVICE.TypeError typeErr = new DART6_FORECASTSERVICE.TypeError();
        DART6_FORECASTSERVICE.UniqueError uniqErr = new DART6_FORECASTSERVICE.UniqueError();
        DART6_FORECASTSERVICE.UserDomainTargeting useDomainTar = new DART6_FORECASTSERVICE.UserDomainTargeting();
        DART6_FORECASTSERVICE.UserDomainTargetingError userDomainTarErr = new DART6_FORECASTSERVICE.UserDomainTargetingError();
        DART6_FORECASTSERVICE.VideoPositionTargeting videoPosTar = new DART6_FORECASTSERVICE.VideoPositionTargeting();
        DART6_FORECASTSERVICE.Value val = new DART6_FORECASTSERVICE.Value();
        DART6_FORECASTSERVICE.CommonError commErr = new DART6_FORECASTSERVICE.CommonError();
        DART6_FORECASTSERVICE.InternalApiError internalErr = new DART6_FORECASTSERVICE.InternalApiError();
        DART6_FORECASTSERVICE.LineItemSummary lineItemSum = new DART6_FORECASTSERVICE.LineItemSummary();
        DART6_FORECASTSERVICE.BandwidthGroup banwidthGro = new DART6_FORECASTSERVICE.BandwidthGroup();
        DART6_FORECASTSERVICE.OrderError ordErr = new DART6_FORECASTSERVICE.OrderError();
        DART6_FORECASTSERVICE.DateTimeRangeTargetingError dartTimeRangErr = new DART6_FORECASTSERVICE.DateTimeRangeTargetingError();
        DART6_FORECASTSERVICE.InventoryTargetingError inveTarErr = new DART6_FORECASTSERVICE.InventoryTargetingError();
        DART6_FORECASTSERVICE.BooleanValue booleanVal = new DART6_FORECASTSERVICE.BooleanValue();
        DART6_FORECASTSERVICE.AuthenticationError autErr = new DART6_FORECASTSERVICE.AuthenticationError();
        DART6_FORECASTSERVICE.PermissionError perErr = new DART6_FORECASTSERVICE.PermissionError();
        
        DART6_FORECASTSERVICE.DeviceManufacturerTargeting devManTar = new DART6_FORECASTSERVICE.DeviceManufacturerTargeting();
        DART6_FORECASTSERVICE.LineItemOperationError lineItemErr = new DART6_FORECASTSERVICE.LineItemOperationError();
        DART6_FORECASTSERVICE.InventoryUnitError invUnitErr = new DART6_FORECASTSERVICE.InventoryUnitError();
        DART6_FORECASTSERVICE.SoapResponseHeader soaHearder = new DART6_FORECASTSERVICE.SoapResponseHeader();
        DART6_FORECASTSERVICE.DateTimeValue dateTimeVal = new DART6_FORECASTSERVICE.DateTimeValue();

        //@vitou 08-04-2015
        DART6_FORECASTSERVICE.VideoPositionTarget vdoPosTar = new DART6_FORECASTSERVICE.VideoPositionTarget();
        DART6_FORECASTSERVICE.SetValue setVal = new DART6_FORECASTSERVICE.SetValue();
        DART6_FORECASTSERVICE.FeatureError featErr = new DART6_FORECASTSERVICE.FeatureError();
        DART6_FORECASTSERVICE.ProgrammaticError progErr = new DART6_FORECASTSERVICE.ProgrammaticError();
        DART6_FORECASTSERVICE.VideoPosition vdoPos = new DART6_FORECASTSERVICE.VideoPosition();
        DART6_FORECASTSERVICE.getAvailabilityForecastByIdResponse_element getForeById = new DART6_FORECASTSERVICE.getAvailabilityForecastByIdResponse_element();
        DART6_FORECASTSERVICE.ContentMetadataTargetingError contMetaTarErr =  new DART6_FORECASTSERVICE.ContentMetadataTargetingError();
        DART6_FORECASTSERVICE.CreativeError creativeErr = new DART6_FORECASTSERVICE.CreativeError();
        DART6_FORECASTSERVICE.ContentMetadataKeyHierarchyTargeting contMetaKeyHierTar = new DART6_FORECASTSERVICE.ContentMetadataKeyHierarchyTargeting();
        DART6_FORECASTSERVICE.VideoPositionWithinPod vdoPosWitPod = new DART6_FORECASTSERVICE.VideoPositionWithinPod();
        DART6_FORECASTSERVICE.DateValue dateval = new DART6_FORECASTSERVICE.DateValue();
        DART6_FORECASTSERVICE.ContendingLineItem contLineItem = new DART6_FORECASTSERVICE.ContendingLineItem();
        DART6_FORECASTSERVICE.EntityChildrenLimitReachedError entChldReachErr = new DART6_FORECASTSERVICE.EntityChildrenLimitReachedError();
        
        Object o = new DART6_FORECASTSERVICE.CrossSellError();
        o = new DART6_FORECASTSERVICE.CrossSellError();
        o = new DART6_FORECASTSERVICE.SetTopBoxInfo();
        o = new DART6_FORECASTSERVICE.getAvailabilityForecastById_element();
        o = new DART6_FORECASTSERVICE.LineItemDeliveryForecast();
        o = new DART6_FORECASTSERVICE.AlternativeUnitTypeForecast();
        o = new DART6_FORECASTSERVICE.DeliveryForecast();
        o = new DART6_FORECASTSERVICE.TimeZoneError();
        o = new DART6_FORECASTSERVICE.GrpSettings();
        o = new DART6_FORECASTSERVICE.VideoPositionTargetingError();
        o = new DART6_FORECASTSERVICE.SetTopBoxLineItemError();
        o = new DART6_FORECASTSERVICE.LineItemActivityAssociation();
        o = new DART6_FORECASTSERVICE.DeliveryForecastOptions();
        o = new DART6_FORECASTSERVICE.getDeliveryForecastResponse_element();
        o = new DART6_FORECASTSERVICE.ObjectValue();
        o = new DART6_FORECASTSERVICE.CollectionSizeError();
        o = new DART6_FORECASTSERVICE.getDeliveryForecastByIdsResponse_element();
        o = new DART6_FORECASTSERVICE.LineItemActivityAssociationError();
        o = new DART6_FORECASTSERVICE.TargetingCriteriaBreakdown();
        o = new DART6_FORECASTSERVICE.GrpSettingsError();
        o = new DART6_FORECASTSERVICE.GrpDemographicBreakdown();
        o = new DART6_FORECASTSERVICE.CreativeTargeting();
        o = new DART6_FORECASTSERVICE.getDeliveryForecastByIds_element();
        o = new DART6_FORECASTSERVICE.OrderActionError();
        o = new DART6_FORECASTSERVICE.ImageError();
        o = new DART6_FORECASTSERVICE.getDeliveryForecast_element();
        o = new DART6_FORECASTSERVICE.AudienceSegmentError();
        o = new DART6_FORECASTSERVICE.CrossSellError();
        o = new DART6_FORECASTSERVICE.CrossSellError();
        o = new DART6_FORECASTSERVICE.CrossSellError();
        o = new DART6_FORECASTSERVICE.CrossSellError();
        o = new DART6_FORECASTSERVICE.CrossSellError();
        
        Test.startTest();
            DART6_FORECASTSERVICE.ForecastServiceInterfacePort svc = new DART6_FORECASTSERVICE.ForecastServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_FORECASTSERVICE.getAvailabilityForecastByIdResponse_element()));
            svc.getAvailabilityForecastById(1111, new DART6_FORECASTSERVICE.AvailabilityForecastOptions());
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_FORECASTSERVICE.getDeliveryForecastByIdsResponse_element()));
            svc.getDeliveryForecastByIds(new Long[0], new DART6_FORECASTSERVICE.DeliveryForecastOptions());
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_FORECASTSERVICE.getDeliveryForecastResponse_element()));
            svc.getDeliveryForecast(new DART6_FORECASTSERVICE.ProspectiveLineItem[0], new DART6_FORECASTSERVICE.DeliveryForecastOptions());
            
        Test.stopTest();
        
    }

    /** Test Class DART6_REPORTSERVICE */

    static testMethod void testDART6ReportService()
    {
        DART6_REPORTSERVICE reportsv = new DART6_REPORTSERVICE();

        DART6_REPORTSERVICE.CommonError comErr = new DART6_REPORTSERVICE.CommonError();
        DART6_REPORTSERVICE.getReportDownloadUrlWithOptionsResponse_element getResDwOpRes = new    DART6_REPORTSERVICE.getReportDownloadUrlWithOptionsResponse_element();
        DART6_REPORTSERVICE.DateTimeValue dateTimeVal = new DART6_REPORTSERVICE.DateTimeValue();
        DART6_REPORTSERVICE.getReportDownloadUrlWithOptions_element getRepOpt = new DART6_REPORTSERVICE.getReportDownloadUrlWithOptions_element();
        DART6_REPORTSERVICE.InternalApiError internalErr = new DART6_REPORTSERVICE.InternalApiError();
        DART6_REPORTSERVICE.Statement statements = new DART6_REPORTSERVICE.Statement();
        DART6_REPORTSERVICE.PublisherQueryLanguageContextError publicQuCont = new DART6_REPORTSERVICE.PublisherQueryLanguageContextError();
        DART6_REPORTSERVICE.ApiError apiErr = new DART6_REPORTSERVICE.ApiError();
        DART6_REPORTSERVICE.runReportJobResponse_element runRepJopRes = new DART6_REPORTSERVICE.runReportJobResponse_element();
        DART6_REPORTSERVICE.Date_x datex = new DART6_REPORTSERVICE.Date_x();
        DART6_REPORTSERVICE.SoapRequestHeader soapResHd = new DART6_REPORTSERVICE.SoapRequestHeader();
        DART6_REPORTSERVICE.getReportDownloadURL_element getRepUrl = new DART6_REPORTSERVICE.getReportDownloadURL_element();
        DART6_REPORTSERVICE.getReportDownloadURLResponse_element getdRepUrlResEle = new DART6_REPORTSERVICE.getReportDownloadURLResponse_element();
        DART6_REPORTSERVICE.BooleanValue bval = new DART6_REPORTSERVICE.BooleanValue();
        DART6_REPORTSERVICE.ApiException apiEx = new DART6_REPORTSERVICE.ApiException();
        DART6_REPORTSERVICE.RequiredError reqErr = new DART6_REPORTSERVICE.RequiredError();
        DART6_REPORTSERVICE.AuthenticationError AuthErr = new DART6_REPORTSERVICE.AuthenticationError();
        DART6_REPORTSERVICE.PermissionError perErr = new DART6_REPORTSERVICE.PermissionError();
        DART6_REPORTSERVICE.QuotaError quotaErr = new DART6_REPORTSERVICE.QuotaError();
        DART6_REPORTSERVICE.PublisherQueryLanguageSyntaxError pubQuSynErr = new DART6_REPORTSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_REPORTSERVICE.ReportQuery requery = new DART6_REPORTSERVICE.ReportQuery();
        DART6_REPORTSERVICE.String_ValueMapEntry valMapEn = new DART6_REPORTSERVICE.String_ValueMapEntry();
        DART6_REPORTSERVICE.ApplicationException appEx = new DART6_REPORTSERVICE.ApplicationException();
        DART6_REPORTSERVICE.Value val = new DART6_REPORTSERVICE.Value();
        DART6_REPORTSERVICE.getReportJobStatus_element getJobEle = new DART6_REPORTSERVICE.getReportJobStatus_element();
        DART6_REPORTSERVICE.ApiVersionError apiVerErr = new DART6_REPORTSERVICE.ApiVersionError();
        DART6_REPORTSERVICE.ReportError repErr = new DART6_REPORTSERVICE.ReportError();
        DART6_REPORTSERVICE.ServerError serErr = new DART6_REPORTSERVICE.ServerError();
        DART6_REPORTSERVICE.DateTime_x dateTimex = new DART6_REPORTSERVICE.DateTime_x();
        DART6_REPORTSERVICE.ReportDownloadOptions repDop = new DART6_REPORTSERVICE.ReportDownloadOptions();
        DART6_REPORTSERVICE.StatementError stateErr = new DART6_REPORTSERVICE.StatementError();
        DART6_REPORTSERVICE.NumberValue numVal = new DART6_REPORTSERVICE.NumberValue();
        DART6_REPORTSERVICE.TextValue txtval = new DART6_REPORTSERVICE.TextValue();
        DART6_REPORTSERVICE.ReportServiceInterfacePort reIntPort = new DART6_REPORTSERVICE.ReportServiceInterfacePort();
        DART6_REPORTSERVICE.SoapResponseHeader sheader = new DART6_REPORTSERVICE.SoapResponseHeader();
        DART6_REPORTSERVICE.ReportJob reJob = new DART6_REPORTSERVICE.ReportJob();
        DART6_REPORTSERVICE.runReportJob_element runReJob = new DART6_REPORTSERVICE.runReportJob_element();
        DART6_REPORTSERVICE.getReportJobStatusResponse_element getRejobResEle = new DART6_REPORTSERVICE.getReportJobStatusResponse_element();
        DART6_REPORTSERVICE.NotNullError notNullErr = new DART6_REPORTSERVICE.NotNullError();
        DART6_REPORTSERVICE.CollectionSizeError colSizeErr = new DART6_REPORTSERVICE.CollectionSizeError();
        DART6_REPORTSERVICE.StringLengthError strlenErr= new DART6_REPORTSERVICE.StringLengthError();
        DART6_REPORTSERVICE.ObjectValue objV= new DART6_REPORTSERVICE.ObjectValue();

         //@vitou 08-04-2015
        DART6_REPORTSERVICE.SetValue setVal = new DART6_REPORTSERVICE.SetValue();
        DART6_REPORTSERVICE.FeatureError featErr = new DART6_REPORTSERVICE.FeatureError();
        DART6_REPORTSERVICE.DateValue dateVal = new DART6_REPORTSERVICE.DateValue();
        DART6_REPORTSERVICE.ParseError pasErr = new DART6_REPORTSERVICE.ParseError();
        
        Object o = new DART6_REPORTSERVICE.SavedQuery(); 
        o = new DART6_REPORTSERVICE.RequiredCollectionError(); 
        o = new DART6_REPORTSERVICE.getSavedQueriesByStatementResponse_element(); 
        o = new DART6_REPORTSERVICE.SavedQueryPage(); 
        o = new DART6_REPORTSERVICE.getSavedQueriesByStatement_element(); 
       
        Test.startTest();
            DART6_REPORTSERVICE.ReportServiceInterfacePort svc = new DART6_REPORTSERVICE.ReportServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_REPORTSERVICE.getSavedQueriesByStatementResponse_element()));
            svc.getSavedQueriesByStatement(new DART6_REPORTSERVICE.Statement());
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_REPORTSERVICE.getReportDownloadURLResponse_element()));
            svc.getReportDownloadURL(12312, 'test');
        Test.stopTest();
    }

    /** Test Class DART6_CUSTOMTARGETINGSERVICE */

    static testMethod void testDART6CustomTargetingService()
    {

        DART6_CUSTOMTARGETINGSERVICE customService = new DART6_CUSTOMTARGETINGSERVICE();

        DART6_CUSTOMTARGETINGSERVICE.CommonError comErr = new DART6_CUSTOMTARGETINGSERVICE.CommonError();
        DART6_CUSTOMTARGETINGSERVICE.DeleteCustomTargetingKeys delcusTarKey= new DART6_CUSTOMTARGETINGSERVICE.DeleteCustomTargetingKeys();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyAction custKeyAc= new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyAction();
        DART6_CUSTOMTARGETINGSERVICE.InternalApiError interApiErr = new DART6_CUSTOMTARGETINGSERVICE.InternalApiError();
        DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeys_element cTKeyEle = new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeys_element();
        DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueAction_element perCusValAc= new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueAction_element();
        DART6_CUSTOMTARGETINGSERVICE.BooleanValue bv = new DART6_CUSTOMTARGETINGSERVICE.BooleanValue();
        DART6_CUSTOMTARGETINGSERVICE.UniqueError uerr = new DART6_CUSTOMTARGETINGSERVICE.UniqueError();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey custKey = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey();
        DART6_CUSTOMTARGETINGSERVICE.RequiredError reErr = new DART6_CUSTOMTARGETINGSERVICE.RequiredError();
        DART6_CUSTOMTARGETINGSERVICE.AuthenticationError autErr = new DART6_CUSTOMTARGETINGSERVICE.AuthenticationError();
        DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValuesResponse_element updValResEle= new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValuesResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.PermissionError perErr = new DART6_CUSTOMTARGETINGSERVICE.PermissionError();
        DART6_CUSTOMTARGETINGSERVICE.PublisherQueryLanguageSyntaxError pubQLErr = new DART6_CUSTOMTARGETINGSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_CUSTOMTARGETINGSERVICE.String_ValueMapEntry valMaEnt = new DART6_CUSTOMTARGETINGSERVICE.String_ValueMapEntry();
        DART6_CUSTOMTARGETINGSERVICE.Value val = new DART6_CUSTOMTARGETINGSERVICE.Value();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue custTarVal = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue();
        DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element custValByStat = new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeys_element updCusKeyEle = new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeys_element();
        DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeysResponse_element updTarKeyRes= new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeysResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.TypeError typeErr = new DART6_CUSTOMTARGETINGSERVICE.TypeError();
        DART6_CUSTOMTARGETINGSERVICE.NumberValue numVal = new DART6_CUSTOMTARGETINGSERVICE.NumberValue();
        DART6_CUSTOMTARGETINGSERVICE.SoapResponseHeader SoaHed = new DART6_CUSTOMTARGETINGSERVICE.SoapResponseHeader();
        DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element creaCustValResEle= new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.NotNullError notNullErr = new DART6_CUSTOMTARGETINGSERVICE.NotNullError();
        DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatementResponse_element getCustKeyByResEle = new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatementResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyPage custTargPage = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyPage();
        DART6_CUSTOMTARGETINGSERVICE.DateTimeValue dtVal= new DART6_CUSTOMTARGETINGSERVICE.DateTimeValue();
        DART6_CUSTOMTARGETINGSERVICE.Statement st = new DART6_CUSTOMTARGETINGSERVICE.Statement();
        DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyAction_element perTargKeyAcElement = new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyAction_element();
        DART6_CUSTOMTARGETINGSERVICE.PublisherQueryLanguageContextError pubQlContErr = new DART6_CUSTOMTARGETINGSERVICE.PublisherQueryLanguageContextError();
        DART6_CUSTOMTARGETINGSERVICE.ApiError apiErr= new DART6_CUSTOMTARGETINGSERVICE.ApiError();
        DART6_CUSTOMTARGETINGSERVICE.Date_x dx = new DART6_CUSTOMTARGETINGSERVICE.Date_x();
        DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader sH = new DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort custSerInPort= new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort();
        DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValues_element updVal = new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValues_element();
        DART6_CUSTOMTARGETINGSERVICE.NullError  nulErr = new DART6_CUSTOMTARGETINGSERVICE.NullError();
        DART6_CUSTOMTARGETINGSERVICE.ApiException apiExc = new DART6_CUSTOMTARGETINGSERVICE.ApiException();
        DART6_CUSTOMTARGETINGSERVICE.QuotaError quoaErr = new DART6_CUSTOMTARGETINGSERVICE.QuotaError();
        DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValues_element creatTargValEle  = new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValues_element();
        DART6_CUSTOMTARGETINGSERVICE.ApplicationException appExc = new DART6_CUSTOMTARGETINGSERVICE.ApplicationException();
        DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatement_element getCustTarEle= new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatement_element();
        DART6_CUSTOMTARGETINGSERVICE.ApiVersionError apiVerErr = new DART6_CUSTOMTARGETINGSERVICE.ApiVersionError();
        DART6_CUSTOMTARGETINGSERVICE.ParseError paErr= new DART6_CUSTOMTARGETINGSERVICE.ParseError();
        DART6_CUSTOMTARGETINGSERVICE.ServerError serErr = new DART6_CUSTOMTARGETINGSERVICE.ServerError();
        DART6_CUSTOMTARGETINGSERVICE.DateTime_x dtx= new DART6_CUSTOMTARGETINGSERVICE.DateTime_x();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage cutValPage = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValueAction custValAc = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValueAction();
        DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeysResponse_element creatTaKeyRes = new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeysResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.StatementError staErr= new DART6_CUSTOMTARGETINGSERVICE.StatementError();
        DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyActionResponse_element perCustKeyRes = new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyActionResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatement_element getTarKeyStr = new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatement_element();
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingError custTarErr = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingError();
        DART6_CUSTOMTARGETINGSERVICE.TextValue txVal = new DART6_CUSTOMTARGETINGSERVICE.TextValue();
        DART6_CUSTOMTARGETINGSERVICE.UpdateResult updRes= new DART6_CUSTOMTARGETINGSERVICE.UpdateResult();
        DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueActionResponse_element perCustTarAcRes = new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueActionResponse_element();
        DART6_CUSTOMTARGETINGSERVICE.DeleteCustomTargetingValues delTarVal= new DART6_CUSTOMTARGETINGSERVICE.DeleteCustomTargetingValues();

        DART6_CUSTOMTARGETINGSERVICE.CollectionSizeError colSizeErr = new DART6_CUSTOMTARGETINGSERVICE.CollectionSizeError();
        DART6_CUSTOMTARGETINGSERVICE.ActivateCustomTargetingKeys actCusKey= new DART6_CUSTOMTARGETINGSERVICE.ActivateCustomTargetingKeys();
        DART6_CUSTOMTARGETINGSERVICE.ActivateCustomTargetingValues actCusVal= new DART6_CUSTOMTARGETINGSERVICE.ActivateCustomTargetingValues();
        DART6_CUSTOMTARGETINGSERVICE.EntityLimitReachedError entityReachErr= new DART6_CUSTOMTARGETINGSERVICE.EntityLimitReachedError();
        DART6_CUSTOMTARGETINGSERVICE.ObjectValue objV = new DART6_CUSTOMTARGETINGSERVICE.ObjectValue();
        DART6_CUSTOMTARGETINGSERVICE.EntityChildrenLimitReachedError entityLimReErr= new DART6_CUSTOMTARGETINGSERVICE.EntityChildrenLimitReachedError();

         //@vitou 08-04-2015
        DART6_CUSTOMTARGETINGSERVICE.SetValue setVal = new DART6_CUSTOMTARGETINGSERVICE.SetValue();
        DART6_CUSTOMTARGETINGSERVICE.FeatureError featErr = new DART6_CUSTOMTARGETINGSERVICE.FeatureError();
        DART6_CUSTOMTARGETINGSERVICE.DateValue dateVal = new DART6_CUSTOMTARGETINGSERVICE.DateValue();
        
        Object o = new DART6_CUSTOMTARGETINGSERVICE.RequiredCollectionError();
        o = new DART6_CUSTOMTARGETINGSERVICE.StringLengthError();
        
        Test.startTest();
            DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort svc = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingKeysResponse_element()));
            svc.createCustomTargetingKeys(new List<DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey>());
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingKeysResponse_element()));
            svc.updateCustomTargetingKeys(new List<DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKey>());
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element()));
            svc.createCustomTargetingValues(new List<DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue>());
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element()));
            svc.getCustomTargetingValuesByStatement(new DART6_CUSTOMTARGETINGSERVICE.Statement());
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingValueActionResponse_element()));
            svc.performCustomTargetingValueAction(new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValueAction(), new DART6_CUSTOMTARGETINGSERVICE.Statement());
            
            
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.updateCustomTargetingValuesResponse_element()));
            svc.updateCustomTargetingValues(new List<DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue>());
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.performCustomTargetingKeyActionResponse_element()));
            svc.performCustomTargetingKeyAction(new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingKeyAction(), new DART6_CUSTOMTARGETINGSERVICE.Statement());
            
            
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingKeysByStatementResponse_element()));
            svc.getCustomTargetingKeysByStatement(new DART6_CUSTOMTARGETINGSERVICE.Statement());
             
        Test.stopTest();
    }

     /* @Vitou 08-04-2015    */
     /** Test Class DARTUtil */
     static testMethod void testDARTUtil(){

          /**
          testDATA.createCredential();
          testDATA.createTargetingHierarchy();
          testDATA.createAccount();
          testDATA.createAdvertiser(); **/
          //@vitou 13-05-2015 => get Test Data
          getTestData();

          Targeting__c targeting = [select Id from Targeting__c where Description__c='test' limit 1];
          Account acc = [select Id from Account where Name='Test Acc0'limit 1];

          DART_Browser_Mapper__c map_browser_test = new DART_Browser_Mapper__c();
          map_browser_test.Name = 'Test';
          map_browser_test.Browser_Id__c = 'TE';
          map_browser_test.Dart6_Id__c = 00000000;
          insert map_browser_test;

          DART_OS_Mapper__c map_os_test = new DART_OS_Mapper__c();
          map_os_test.name = 'Test OS';
          insert map_os_test;

          Nullpointerexception Ex = new Nullpointerexception();
          map<String,Exception> mapE = new map<String,Exception>();
          mapE.put('A',Ex);

          Test.startTest();
            DartUtil.composeDigestAuthorizationHeader('paramString1', 'paramString2', 'paramString3', 'paramString4');
            DartUtil.getRequestToken('DE');
            DartUtil.getCredential('Dart6','DE');
            DartUtil.sendMail(new List<String>{'test@test123.comn'}, new List<String>{'test2@test123.comn'}, 'test','test','test');
            DartUtil.getListCities(targeting.Id);//*DartUtil.getListCities(testDATA.targetting[0].Id);
            DartUtil.getListAreaCodes(targeting.Id);//*DartUtil.getListAreaCodes(testDATA.targetting[0].Id);
            DartUtil.getAdvertiser(acc.id, acc.id);//*DartUtil.getAdvertiser(testDATA.lstAcc.get(0).id, testDATA.lstAcc.get(0).id);
            DartUtil.getListAvailSites('xxxxxxx',new set<String>{'test'});
            DartUtil.countCurrentBatch();
            DartUtil.getBrowserMapper('Test');
            DartUtil.extractMessage('test error message');
            DartUtil.getOSMapper('Test OS');
            DartUtil.isNumber('01');
            DartUtil.isNumber('AB');
            DartUtil.encodeHTML('');
            DartUtil.encodeHTML('Test HTML');
            DartUtil.getAccessToken(logIn); //DartUtil.getAccessToken(testDATA.listLogin.get(0));
            DARTUtil.generateTableForecastError(mapE);
          test.stopTest();
     }


    /* @vitou 08-04-2015 ==> increase code coverage of Dart6Message */
    static testMethod void testDARTBooking2()
    {
            //@vitou 13-05-2015 => get Test Data
        getTestData();
        opp.ApprovalStatus__c = 'Previously Approved';
        opp.ContractStatus__c = 'Signed';
        update opp;
        update item;
        getTestData();

        // Dart6Message
        DART6Message dart6Msg = new DART6Message();
        // Dart6Parser
        DART6Parser dart6Parser = new DART6Parser();
        // DartObject
        DARTObject dartObj = new DARTObject();
        // DARTMockUp
        DARTMockUp mockupdata = new DARTMockUp();


        Test.startTest();

            item.Ad_Id__c = '123456'; //items.get(0).Ad_Id__c = '123456';

            //BookingController bookingCont2 = new BookingController(opp, items.get(0));
            BookingController bookingCont2 = new BookingController(opp, item);

            bookingCont2.requestCreateAdvertiser();
            List<DARTObject.IDARTObjectAdvertiser> lstAdv = bookingCont2.getListAdvertiser();


             Advertiser__c adv = new Advertiser__c(Dart6_Advertiser_Id__c=lstAdv.get(0).getDartId());

            Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
            mapAdvertiser.put(DARTUtil.DART6, adv);

            bookingCont2.processAndSendOrder(mapAdvertiser);
            List<DARTObject.IDARTObjectOrder> lstOrder = bookingCont2.getListOrder();
            bookingCont2.processAndSendLineItem(lstOrder.get(0), mapAdvertiser);
            List<DARTObject.IDARTObjectAds> lstAds = bookingCont2.getListAds();


        Test.stopTest();

    }

    //@vitou 08-04-2015 ==> increase code coverage of DartObject
    static testMethod void testDARTObject()
    {
        //@vitou 13-05-2015 => get Test Data
        getTestData();

        DARTObject.DARTOrder dartOrder = new DARTObject.DARTOrder(opp);
        DARTObject.DARTPerson dartPerson = new DARTObject.DARTPerson();
        //DARTObject.DARTForecast dartForecast = new DARTObject.DARTForecast(items.get(0));
        DARTObject.DARTForecast dartForecast = new DARTObject.DARTForecast(item);

        Test.startTest();
            dartOrder.getTempId();
            dartOrder.setTempId('Test');
            dartOrder.setDartErrMsg('Test Error');
            dartOrder.getOwnerId();
            dartOrder.getPrimaryTrafficker();
            dartOrder.getSalepeople();
            dartOrder.getStartMonth();
            dartOrder.getStartDay();
            dartOrder.getStartYear();
            dartOrder.getEndMonth();
            dartOrder.getEndDay();
            dartOrder.getEndYear();
            dartOrder.getOrderAvertiserId();
            dartPerson.getUserEmail();
            dartForecast.getOpportunityId();
            dartForecast.getIncludeCountry();
            dartForecast.getIncludeCity();
            dartForecast.getIncludeAreaCode();
            dartForecast.getOS();
            dartForecast.getWebBrowser();
            dartForecast.getWebBrowerVersion();
            dartForecast.getWebBrowserSubVersion();
            dartForecast.getAdSlotH();
            dartForecast.getAdSlotW();
            dartForecast.getListAdSlotWH();
            dartForecast.getMinorVersion();
            dartForecast.getMajorVersion();
            dartForecast.getMatchingUnits();
        Test.stopTest();
    }

    /** Test Class DART6_NETWORKSERVICE */

    static testMethod void testDART6NetworkService()
    {
        DART6_NETWORKSERVICE.CommonError comErr= new DART6_NETWORKSERVICE.CommonError();
        DART6_NETWORKSERVICE.InternalApiError intapiErr= new DART6_NETWORKSERVICE.InternalApiError();
        DART6_NETWORKSERVICE.CollectionSizeError colsizeErr= new DART6_NETWORKSERVICE.CollectionSizeError();
        DART6_NETWORKSERVICE.makeTestNetworkResponse_element mtResEle= new DART6_NETWORKSERVICE.makeTestNetworkResponse_element();
        DART6_NETWORKSERVICE.PublisherQueryLanguageContextError pubqleEr= new DART6_NETWORKSERVICE.PublisherQueryLanguageContextError();
        DART6_NETWORKSERVICE.ApiError apiErr= new DART6_NETWORKSERVICE.ApiError();
        DART6_NETWORKSERVICE.updateNetworkResponse_element updNetre= new DART6_NETWORKSERVICE.updateNetworkResponse_element();
        DART6_NETWORKSERVICE.SoapRequestHeader SoapRequestHeader= new DART6_NETWORKSERVICE.SoapRequestHeader();
        DART6_NETWORKSERVICE.StringLengthError StringLengthError= new DART6_NETWORKSERVICE.StringLengthError();
        DART6_NETWORKSERVICE.NetworkError NetworkError= new DART6_NETWORKSERVICE.NetworkError();
        DART6_NETWORKSERVICE.ApiException ApiException= new DART6_NETWORKSERVICE.ApiException();
        DART6_NETWORKSERVICE.UniqueError UniqueError= new DART6_NETWORKSERVICE.UniqueError();
        DART6_NETWORKSERVICE.RequiredError RequiredError= new DART6_NETWORKSERVICE.RequiredError();
        DART6_NETWORKSERVICE.FeatureError FeatureError= new DART6_NETWORKSERVICE.FeatureError();
        DART6_NETWORKSERVICE.AuthenticationError AuthenticationError= new DART6_NETWORKSERVICE.AuthenticationError();
        DART6_NETWORKSERVICE.PermissionError PermissionError= new DART6_NETWORKSERVICE.PermissionError();
        DART6_NETWORKSERVICE.QuotaError QuotaError= new DART6_NETWORKSERVICE.QuotaError();
        DART6_NETWORKSERVICE.PublisherQueryLanguageSyntaxError PublisherQueryLanguageSyntaxError= new DART6_NETWORKSERVICE.PublisherQueryLanguageSyntaxError();
        DART6_NETWORKSERVICE.makeTestNetwork_element makeTestNetwork_element= new DART6_NETWORKSERVICE.makeTestNetwork_element();
        DART6_NETWORKSERVICE.ApplicationException ApplicationException= new DART6_NETWORKSERVICE.ApplicationException();
        DART6_NETWORKSERVICE.ExchangeRateError ExchangeRateError= new DART6_NETWORKSERVICE.ExchangeRateError();
        DART6_NETWORKSERVICE.ApiVersionError ApiVersionError= new DART6_NETWORKSERVICE.ApiVersionError();
        DART6_NETWORKSERVICE.ParseError ParseError= new DART6_NETWORKSERVICE.ParseError();
        DART6_NETWORKSERVICE.PrecisionError PrecisionError= new DART6_NETWORKSERVICE.PrecisionError();
        DART6_NETWORKSERVICE.updateNetwork_element updateNetwork_element= new DART6_NETWORKSERVICE.updateNetwork_element();
        DART6_NETWORKSERVICE.getAllNetworks_element getAllNetworks_element= new DART6_NETWORKSERVICE.getAllNetworks_element();
        DART6_NETWORKSERVICE.ServerError ServerError= new DART6_NETWORKSERVICE.ServerError();
        DART6_NETWORKSERVICE.getCurrentNetwork_element getCurrentNetwork_element= new DART6_NETWORKSERVICE.getCurrentNetwork_element();
        DART6_NETWORKSERVICE.getCurrentNetworkResponse_element getCurrentNetworkResponse_element= new DART6_NETWORKSERVICE.getCurrentNetworkResponse_element();
        DART6_NETWORKSERVICE.StatementError StatementError= new DART6_NETWORKSERVICE.StatementError();
        DART6_NETWORKSERVICE.RequiredCollectionError RequiredCollectionError= new DART6_NETWORKSERVICE.RequiredCollectionError();
        DART6_NETWORKSERVICE.TypeError TypeError= new DART6_NETWORKSERVICE.TypeError();
        DART6_NETWORKSERVICE.RequiredNumberError RequiredNumberError= new DART6_NETWORKSERVICE.RequiredNumberError();
        DART6_NETWORKSERVICE.getAllNetworksResponse_element getAllNetworksResponse_element= new DART6_NETWORKSERVICE.getAllNetworksResponse_element();
        DART6_NETWORKSERVICE.InvalidEmailError InvalidEmailError= new DART6_NETWORKSERVICE.InvalidEmailError();
        DART6_NETWORKSERVICE.SoapResponseHeader SoapResponseHeader= new DART6_NETWORKSERVICE.SoapResponseHeader();
        DART6_NETWORKSERVICE.Network Network= new DART6_NETWORKSERVICE.Network();
        DART6_NETWORKSERVICE.NotNullError NotNullError= new DART6_NETWORKSERVICE.NotNullError();
        DART6_NETWORKSERVICE.NetworkServiceInterfacePort NetworkServiceInterfacePort= new DART6_NETWORKSERVICE.NetworkServiceInterfacePort();
        
        Object o = new DART6_NETWORKSERVICE.SetTopBoxCreativeError();
        Test.startTest();
            DART6_NETWORKSERVICE.NetworkServiceInterfacePort svc = new DART6_NETWORKSERVICE.NetworkServiceInterfacePort();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_NETWORKSERVICE.updateNetworkResponse_element()));
            svc.updateNetwork(new DART6_NETWORKSERVICE.Network());
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_NETWORKSERVICE.getAllNetworksResponse_element()));
            svc.getAllNetworks();
            
            Test.setMock(WebServiceMock.class, new DARTMockUp.GenericRespone(new DART6_NETWORKSERVICE.makeTestNetworkResponse_element()));
            svc.makeTestNetwork();
            
        Test.stopTest();
    }
}