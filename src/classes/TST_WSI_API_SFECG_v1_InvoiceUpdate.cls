@isTest
public class TST_WSI_API_SFECG_v1_InvoiceUpdate extends TSTDF_Base {

    public TST_WSI_API_SFECG_v1_InvoiceUpdate(TSTDF_Dataset dataset) {
        super(dataset);
    }

    public static TST_WSI_API_SFECG_v1_InvoiceUpdate factory = new TST_WSI_API_SFECG_v1_InvoiceUpdate(new TSTDF_Dataset());

    public class TSTDF_Dataset extends TSTDF_BaseDataSet {

        public override Invoice__c constructInvoice(Invoice__c invoice) {
            invoice.UniquePlatformId__c = 'THBEL_12345';
            return invoice;
        }
    }

    public override void queryAdditionalResults() {

    }

    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        factory.createTestSet();
        Invoice__c tInv = new Invoice__c(UniqueKey__c='TestFQInv', BillingAccount__c = factory.data.accounts[0].id, FQ_InvoiceID__c='BEC1507000', StartDate__c = System.today(), EndDate__c = System.today(),UniquePlatformId__c = 'THBEL_12345');
        insert tInv;
        UTIL.isRunningTestSetup = false;
    }

    @isTest static void checkTestDataSet() {
        factory.queryResults(); // will store results in data set 'data'
        system.assertNotEquals(0, factory.data.accounts.size(), 'Number of Accs should be >1' );
        system.assertNotEquals(0, factory.data.invoices.size(), 'Number of Invoices should be >1' );
    }

    @isTest static void TST_WSI_API_SFECG_v1() {
        
        String endPoint = 'v1/invoices/THBEL/12345';
        String body = '{"status":"Partially Paid", "amountPaid":7.75}';
        String method = 'PUT';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = endpoint;
        req.httpMethod = method;
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = res;

        if (method == 'PUT') {
            WSI_CTRL.putRequest();
            WSI_API_SFECG_v1.process('InvoiceUpdate', new WSI_CTRL.APIResponse(req, res));
        }

    }

    @isTest static void checkInvoiceUpdate_Success() {
        String endPoint = 'v1/invoices/THBEL/12345';
        String body = '{"status":"Partially Paid", "amountPaid":7.75}';
        String method = 'PUT';

        Map<String, Object> resultMap = (Map<String, Object>) callAPI(endPoint, body, method);

        System.assertEquals('200', resultMap.get('statusCode'));
        System.assertEquals('OK', resultMap.get('message'));
    }

    @isTest static void checkInvoiceUpdate_SFID_Success() {
        factory.queryResults();
        String endPoint = 'v1/invoices/' + factory.data.invoices[0].id;
        String body = '{"status":"Partially Paid", "amountPaid":7.75}';
        String method = 'PUT';

        Map<String, Object> resultMap = (Map<String, Object>) callAPI(endPoint, body, method);

        System.assertEquals('200', resultMap.get('statusCode'));
        System.assertEquals('OK', resultMap.get('message'));
    }

    @isTest static void checkInvoiceUpdate_InvoiceNotFound() {
        String endPoint = 'v1/invoices/THBEL/12346';
        String body = '{"status":"Partially Paid", "amountPaid":7.75}';
        String method = 'PUT';

        Map<String, Object> resultMap = (Map<String, Object>) callAPI(endPoint, body, method);

        System.assertEquals('404', resultMap.get('statusCode'));
        System.assertEquals('Not Found', resultMap.get('code'));
        System.assert( ((String)resultMap.get('message')).contains('Failed to find Invoice'));
    }

    @isTest static void checkInvoiceUpdate_NoRightsToChange() {
        factory.queryResults();
        String endPoint = 'v1/invoices/THBEL/12345';
        String body = '{"status":"Partially Paid", "amountPaid":"7.75"}';
        String method = 'PUT';

        Map<String, Object> resultMap;
        
        User testUser = GW_User.createTestUser('TstAdSalesIO1@ecgtests.com', 'THBE2AD', 'Ad Sales Rep' );
        System.runAs(testUser) {
            resultMap = (Map<String, Object>) callAPI(endPoint, body, method);
        }
        System.assertEquals('400', resultMap.get('statusCode'));
        System.assertEquals('Bad Request', resultMap.get('code'));
    }


    private static Object callAPI(String endPoint, String body, String method) {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = endpoint;
        req.httpMethod = method;
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = res;

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