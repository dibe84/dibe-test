@isTest
private class TST_WSI_API_SFECG_v1_Booking extends TSTDF_Base{



    public TST_WSI_API_SFECG_v1_Booking(TSTDF_Dataset dataset) {
        super(dataset);
    }

    public static TST_WSI_API_SFECG_v1_Booking factory = new TST_WSI_API_SFECG_v1_Booking(new TSTDF_Dataset());

    public class TSTDF_Dataset extends TSTDF_BaseDataSet {

        public override List<Product2> constructProducts(List<Product2> products) {
            products = new List<Product2>();
            Product2 admanagerSubscription = new Product2(
                name='AdmanagerSubscription',
                ProductCode='AdmanagerSubscription',
                LocalProductId__c='AdmanagerSubscription',
                Billing_Category__c='Subscription_MonthlyRevenueDelivery',
                ContractPeriodInMonths__c = 12,
                isActive=true
            );

            Product2 admanagerListing_Addon_TopGallery = new Product2(
                name='AdmanagerListing_Addon_TopGallery',
                ProductCode='AdmanagerListing_Addon_TopGallery',
                LocalProductId__c='AdmanagerListing_Addon_TopGallery',
                Billing_Category__c='Subscription_MonthlyRevenueDelivery',
                ContractPeriodInMonths__c = 12,
                isActive=true
            );

            products.add(admanagerSubscription);
            products.add(admanagerListing_Addon_TopGallery);
            return products;
        }

        public override List<Account> constructAccounts(List<Account> accounts) {
            for (Account acc : accounts) {
                acc.UniquePlatformId__c = this.COUNTRYROLENAME + '_' + '12345';
            }
            return accounts;
        }

        public override Opportunity constructOpportunity(Opportunity opp) {
            opp.UniquePlatformId__c = 'THBELAU_123456';
            opp.RecordTypeId = UTIL_RecordType.getRecordTypeByName('Opportunity', 'Approved').Id;
            opp.ApprovalStatus__c = 'Previously Approved';
            opp.contractStatus__c = 'Signed';
            return opp;
        }

    }

    public override void insertOpportunity() {
        List<Opportunity> opps = new List<Opportunity>();
        Opportunity opp = dataSet.constructOpportunity(this.data.accounts[0], this.data.pricebooks[0].Id, this.data.contacts[0]);
        opps.add(opp);
        this.data.opps.addAll(opps);
        insert opps;
    }

    public override void insertOlis() {

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        Datetime startDateTime = Datetime.now().addDays(1);
        Date startDate = date.newinstance(startDateTime.year(), startDateTime.month(), startDateTime.day());

        OpportunityLineItem oli = Subscription.createSubscriptionOLI(this.data.opps[0], this.data.pbes[this.data.pbes.size()-1]);
        oli.From_Date__c = startDate;
        oli.BundleSize__c = 10;
        oli.SalesPriceNet__c = 100;
        oli.UnitPrice = 100;
        oli.UniqueLocalBookingId__c = 'THBELAU_EXISTING';
        olis.add(oli);

        insert olis;
    }

    public override void queryAdditionalResults() {

    }

    public override void insertPricebookEntries() {

        for (Product2 prod : this.data.products){
            this.data.pbes.addAll(dataSet.constructPricebookEntries(prod));
        }

        for (PricebookEntry pbe : this.data.pbes) {
            pbe.Fixed_PricePerMonth__c = 0;
            pbe.isActive = true;
            pbe.currencyIsoCode = 'USD';
        }


       Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
       insert customPB;
       this.data.pricebooks.add(customPB);

        List<PricebookEntry> newPbes = new List<PricebookEntry>();
        for (PricebookEntry pbe : this.data.pbes) {
            PricebookEntry newPbe = new PricebookEntry(
                Product2Id = pbe.Product2Id,
                Pricebook2Id = customPB.Id,
                UnitPrice = pbe.UnitPrice,
                IsActive = true,
                Fixed_PricePerMonth__c = 0,
                currencyIsoCode = 'USD'
            );
            newPbes.add(newPbe);
        }

        this.data.pbes.addAll(newPbes);

        UTIL.log('added PBEs: ' + this.data.pbes);
        insert this.data.pbes;
        UTIL.log('inserted PBEs: ' + this.data.pbes);
    }

    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        factory.createTestSet();
        factory.queryResults();
        UTIL.isRunningTestSetup = false;
    }

    @isTest static void checkTestDataSet() {
        factory.queryResults(); // will store results in data set 'data'
        system.assertNotEquals(0, factory.data.accounts.size(), 'Number of Accs should be >1' );
        system.assertNotEquals(0, factory.data.opps.size(), 'Number of Opps should be >1' );
    }

    @isTest static void checkBookingInsertNewOpp_Success() {
        Test.startTest();
        String endPoint = '/api/v1/accounts/THBEL/12345/bookings/THBELAU/6789';
        String body = '{"pricebookName": "Custom Pricebook","localProductId": "AdmanagerSubscription","startDate": "'+ Datetime.now().addDays(1).format('yyyy-MM-dd')
        +'", "unitPrice": 10.0, "tresholdQuantity": 20,"localOpportunityId": "newOppId", "lineItems": []}';
        String method = 'POST';
        Map<String, Object> resultMap = (Map<String, Object>) callAPI(endPoint, body, method);
        //System.assertEquals('200', resultMap.get('statusCode'));
        //System.assertEquals('OK', resultMap.get('message'));
        Test.stopTest();
    }

    @isTest static void checkBookingInsert_BookingAlreadyExists() {

        Test.startTest();
        String endPoint = '/api/v1/accounts/THBEL/12345/bookings/THBELAU/EXISTING';
        String body = '{"pricebookName": "Custom Pricebook","localProductId": "AdmanagerSubscription","startDate": "'+ Datetime.now().addDays(1).format('yyyy-MM-dd')
        +'", "unitPrice": 10.0, "tresholdQuantity": 20,"localOpportunityId": "newOppId", "lineItems": [{ "localId": "", "parentLineItemId": "", "productId": "", "quantity": "", "salesPrice": "", "startDate": "", "endDate": "" }]}';
        String method = 'POST';
        Map<String, Object> resultMap = (Map<String, Object>) callAPI(endPoint, body, method);
        //System.assertEquals('409', resultMap.get('statusCode'));
        Test.stopTest();

    }


    @isTest static void checkBookingInsertExistingOpp_Success() {
        Test.startTest();
        String endPoint = '/api/v1/accounts/THBEL/12345/bookings/THBELAU/6789';
        String body = '{"pricebookName": "Custom Pricebook","localProductId": "AdmanagerSubscription","startDate": "'+ Datetime.now().addDays(1).format('yyyy-MM-dd')
        +'", "unitPrice": 10.0, "tresholdQuantity": 20,"localOpportunityId": "123456", "lineItems": []}';
        String method = 'POST';
        Map<String, Object> resultMap = (Map<String, Object>) callAPI(endPoint, body, method);
        //throw new UTIL.CustomException(''+resultMap);
        //System.assertEquals('200', resultMap.get('statusCode'));
        //System.assertEquals('OK', resultMap.get('message'));
        Test.stopTest();
    }

    @isTest static void checkBookingInsert_WrongParameters() {
        Test.startTest();
        String endPoint = '/api/v1/accounts/THBEL/12345/bookings/THBELAU/6789';
        String body = '{"pricebookName": "Custom Pricebook", "startDate": "'+ Datetime.now().addDays(1).format('yyyy-MM-dd')
        +'", "unitPrice": 10.0, "tresholdQuantity": 20,"localOpportunityId": "newOppId", "lineItems": []}';
        String method = 'POST';
        Map<String, Object> resultMap = (Map<String, Object>) callAPI(endPoint, body, method);
        System.assertEquals('400', resultMap.get('statusCode'));
        //System.assertEquals('OK', resultMap.get('message'));
        Test.stopTest();
    }

    @isTest static void checkBookingInsert_WrongParameterFormat() {
        String endPoint = '/api/v1/accounts/THBEL/12345/bookings/THBELAU/6789';
        String body = '{"pricebookName": "Custom Pricebook","localProductId": "Blablabla","startDate": 12, "unitPrice": 10.0, "tresholdQuantity": 20,"localOpportunityId": "newOppId", "lineItems": []}';
        String method = 'POST';
        Map<String, Object> resultMap = (Map<String, Object>) callAPI(endPoint, body, method);
        System.assertEquals('400', resultMap.get('statusCode'));
    }

    @isTest static void checkBookingInsert_NonExistingProduct() {
        Test.startTest();
        String endPoint = '/api/v1/accounts/THBEL/12345/bookings/THBELAU/6789';
        String body = '{"pricebookName": "Custom Pricebook","localProductId": "Blablabla","startDate": "'+ Datetime.now().addDays(1).format('yyyy-MM-dd')
        +'", "unitPrice": 10.0, "tresholdQuantity": 20,"localOpportunityId": "newOppId", "lineItems": []}';
        String method = 'POST';
        Map<String, Object> resultMap = (Map<String, Object>) callAPI(endPoint, body, method);
        System.assertEquals('400', resultMap.get('statusCode'));
        Test.stopTest();
    }

    @isTest static void checkBookingUpdateMaster_Success() {
        List<MemberUnit__c> testMUList = [SELECT Id, Name FROM MemberUnit__c where Member__r.MemberId__c = 'THBEL' limit 1];
        List<Account> testAccList = [SELECT Id, Name FROM Account where Member__r.MemberId__c = 'THBEL' and LocalPlatformId__c = '12345' limit 1];
        TST_DataFactory.createAccountMemberUnitAssociation(testMUList.get(0).Id,testAccList.get(0).Id);
        
        Test.startTest();
            String endPoint = '/api/v1/accounts/THBEL/12345/bookings/THBELAU/THBELAU_EXISTING';
            String body = '{"localOpportunityId": "123456","contractDiscountPercentage": 50.0, "unitPrice": 60, "type": "Master", "localId": "null", "lineItems": []}';
            String method = 'PUT';
        Map<String, Object> resultMap = (Map<String, Object>) callAPI(endPoint, body, method);
        Test.stopTest();

        //System.assertEquals('200', resultMap.get('statusCode'));
        //System.assertEquals('OK', resultMap.get('message'));
    }

    @isTest static void checkBookingAddAdjustment_Success() {
        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE UniqueLocalBookingId__c = 'THBELAU_EXISTING'];
        List<Rev__c> revs = [SELECT Id FROM Rev__c WHERE UniqueLocalBookingId__c = 'THBELAU_EXISTING'];
        System.assertEquals(1, olis.size());
        System.assertEquals(1, revs.size());

        Test.startTest();
        String endPoint = '/api/v1/accounts/THBEL/12345/bookings/THBELAU/EXISTING';
        String body = '{"startDate": "' + Datetime.now().addDays(30).format('yyyy-MM-dd') + '", "contractDiscountPercentage": 80.0, "unitPrice": 70, "type": "Adjusted", "lineItems": [{ "localId": "", "parentLineItemId": "", "productId": "", "quantity": "", "salesPrice": "", "startDate": "", "endDate": "" }]"}';
        String method = 'PUT';
        Map<String, Object> resultMap = (Map<String, Object>) callAPI(endPoint, body, method);
        Test.stopTest();
        //System.assertEquals('200', resultMap.get('statusCode'));
        //System.assertEquals('OK', resultMap.get('message'));
    }
    
    @isTest static void checkAdManagerRevenueCalculation() {
        Datetime startDateTime = Datetime.now().addDays(1);
        String startDateString = startDateTime.format('yyyy-MM-dd');
        Date startDate = date.newinstance(startDateTime.year(), startDateTime.month(), startDateTime.day());
        
        String endPoint = '/api/v1/accounts/THBEL/12345/bookings/THBELAU/EXISTING/metrics/' + startDateString;
        String body = '{"metrics": [{"metricKey":"Revenue", "metricValue":1025.45}, {"metricKey":"Quantity","metricValue":2}]}';
        String method = 'PUT';
            
        Test.startTest();
            Opportunity opp = [Select Name, AccountId From Opportunity limit 1];
            Account acc = new Account(Id = opp.AccountId, UniquePlatformId__c = 'THBEL_12345');
            update acc;
            
            Rev__c rev = [select Id, UniqueLocalBookingId__c from Rev__c Where Opportunity__r.AccountId =: acc.id limit 1];
            rev.UniqueLocalBookingId__c = 'THBELAU_EXISTING';
            update rev;
            
            RS__c rs1 = new RS__c(Rev__c = rev.Id, StartOfPeriod__c = Date.today(), UniqueKey__c = 'xxx1989');
            insert rs1;
            
            Metric__c m = new Metric__c(RS__c = rs1.Id, ExternalUID__c = startDateString.replaceAll('-', '')+'_'+(rev.Id+'').substring(0,15), UniqueKey__c = startDateString+'_'+rev.Id);
            insert m;
        
            Map<String, Object> resultMap = (Map<String, Object>) callAPI(endPoint, body, method);

            System.assertEquals('OK', resultMap.get('message'));
            System.assertEquals('200', resultMap.get('statusCode'));
        Test.stopTest();
        //RS__c rs = [SELECT Id, QuantityBilled__c, Revenue__c FROM RS__c WHERE Rev__r.UniqueLocalBookingId__c = 'THBELAU_EXISTING'];
        //System.assertEquals(rs.QuantityBilled__c, 2);
        //System.assertEquals(rs.Revenue__c, 1025.45);
    }

    private static Object callAPI(String endPoint, String body, String method) {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = endpoint;
        req.httpMethod = method;
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = res;

        if (method == 'POST') {
            WSI_CTRL.postRequest();
        }
        if (method == 'PUT') {
            WSI_CTRL.putRequest();
        }
        if (res.responseBody != null) {
            Object obj = (Object) JSON.deserializeUntyped(res.responseBody.toString());
            return obj;
        } else {
            return null;
        }
    }

}