@isTest
public class TST_FQInvoices {

    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        TST_DataFactory fac = TST_DataFactory.getInstance();
        UTIL.isRunningTestSetup = false;
    }
    
    @isTest static void TST_InvoicePost(){
        Account acc = new account(name = 'Test', AccountExtId__c = '12345');
        insert acc;
        
        String JsonMsg = '{"FQ_Invoices":[{"custnr": "' + acc.AccountExtId__c + '","name": "INV-000016149","invoiceDate": "2014-06-7","invoiceAmount": 37781.77,"oppid": "","paymentDate": "2012-04-20","paymentStatus": "Sent to Billing","description": "Test REST APIAA","periodFrom": "2014-06-01","periodUntil": "2014-06-30","amountPaid": 25300,"nextstep": "","blocktype": "","blockreason": "","invoiceAmountWrittenoff": 0,"invoiceExtraAmount": 0,"invoiceCurrency": "EUR","invoiceStatus": "","accountId": "' + acc.id +'","id": ""}]} ';

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/PushInvoices';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JsonMsg);
         
        RestContext.request = req;
        RestContext.response= res;
        
        FQ_Invoices.doPost();
        
        Test.stopTest();
    }
    
    @isTest static void TST_RetrieveInvoices(){
        Account acc = new account(name = 'Test');
        insert acc;
        
        Test.startTest();
        FQ_Invoices.retrieveinvoices(acc.id, 'XXXX');
        FQ_Invoices.retrieveinvoices(acc.id, 'XXXX');     
        Test.stopTest();
    } 
}