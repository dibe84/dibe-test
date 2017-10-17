@isTest
public class TST_WSC_Fiqas2  extends TSTDF_Base {

    public TST_WSC_Fiqas2(TSTDF_Dataset dataset) {
        super(dataset);
    }

    public static TST_WSC_Fiqas2 factory = new TST_WSC_Fiqas2(new TSTDF_Dataset());

    public class TSTDF_Dataset extends TSTDF_BaseDataSet {
        public override List<Webservice_Settings__c> constructWebserviceSettings(List<Webservice_Settings__c> wss){
            wss = new List<Webservice_Settings__c>();
            wss.add(new Webservice_Settings__c(Name = 'WSC_Fiqas2_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
            wss.add(new Webservice_Settings__c(Name = 'WSC_Fiqas2_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
            return wss;
        }
    }

    public override void queryAdditionalResults() {}


    @testSetup static void setup(){
        UTIL.isRunningTestSetup = true;
        factory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }

    @isTest static void TST_InvoiceGetPDF(){
        UTIL_WSC.TESTMOCK = 'getSuccess';
        
            factory.queryResults();
    
            Invoice__c inv = new Invoice__c(UniqueKey__c='TestFQInv', BillingAccount__c = factory.data.accounts[0].id, FQ_InvoiceID__c='BEC1507000', StartDate__c = System.today(), EndDate__c = System.today());
            insert inv;
    
            System.assertEquals(False, inv.Invoice_PDF_Retrieved__c);
    
            UTIL_WSC.WSC_Request req;
            UTIL_WSC.WSC_Result res;
        System.runAs(factory.data.testUsers.get('testUser')){
            Test.startTest();
        
                UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(New Set<Id>{inv.Id});
                req = UTIL_WSC.getWSC_Request('WSC_Fiqas2.InvoiceGetPDF');
                req.init(inv.id);
                res = req.call();
                UTIL_WSC.bulkHandler.commitAll();
             Test.stopTest();
        }
       
        Invoice__c updatedInv = [SELECT Id, Invoice_PDF_Retrieved__c FROM Invoice__c WHERE UniqueKey__c =: 'TestFQInv'];
        List<Attachment> attList = [SELECT Name FROM Attachment WHERE Parentid =: updatedInv.id];

        System.assertEquals(1, attList.size());
        System.assertEquals(True, updatedInv.Invoice_PDF_Retrieved__c);
    }

    @isTest static void TST_ViewInvoicePDF(){
        factory.queryResults();

        Invoice__c inv = new Invoice__c(UniqueKey__c='TestFQInv', BillingAccount__c = factory.data.accounts[0].id, FQ_InvoiceID__c='BEC1507000', StartDate__c = System.today(), EndDate__c = System.today());
        insert inv;

        Test.startTest();
        FQ_ViewInvoicePDF controller = new FQ_ViewInvoicePDF();
        PageReference ref;

        /// Invalid Invoice / No access
        ref = new PageReference('/apex/FQ_ViewInvoicePDF?Id=12345');
        Test.setCurrentPage(ref);
        controller.loadPDF();

        /// Invoice PDF not available yet
        ref = new PageReference('/apex/FQ_ViewInvoicePDF?Id=' + inv.Id);
        Test.setCurrentPage(ref);
        controller.loadPDF();

        /// Failed
        inv.Invoice_PDF_Retrieved__c = True;
        update inv;

        ref = new PageReference('/apex/FQ_ViewInvoicePDF?Id=' + inv.Id);
        Test.setCurrentPage(ref);
        controller.loadPDF();

        /// Success
        Attachment att = new Attachment(Name=inv.id+'_'+inv.FQ_InvoiceID__c+'.pdf', Parentid=inv.Id, Body = Blob.valueOf('test123'));
        insert att;

        ref = new PageReference('/apex/FQ_ViewInvoicePDF?Id=' + inv.Id);
        Test.setCurrentPage(ref);
        controller.loadPDF();

        ///Asserts
        List<Apexpages.Message> msgs = ApexPages.getMessages();

        System.assert(true, msgs[0].getDetail().contains('Insufficient access'));
        System.assert(true, msgs[1].getDetail().contains('The PDF file isn\'t available yet.'));
        System.assert(true, msgs[2].getDetail().contains('The invoice PDF file can\'t be found, please contact your system administrator.'));

        Test.stopTest();

    }

    @isTest static void TST_ResendInvoicePDF(){
        factory.queryResults();

        Invoice__c tInv = new Invoice__c(UniqueKey__c='TestFQInv', BillingAccount__c = factory.data.accounts[0].id, FQ_InvoiceID__c='BEC1507000', StartDate__c = System.today(), EndDate__c = System.today());
        insert tInv;

        contact invCon = [Select email FROM Contact WHERE id =: factory.data.accounts[0].Finance_contact__c];
        invCon.email = 'TestEmail@Ebay.com';
        Update invCon;

        Invoice__c inv = [SELECT Id, Finance_Contact_Email__c FROM Invoice__c WHERE id =: tInv.Id ];

        Test.startTest();
        System.runAs( factory.data.testUsers.get('testUser') ){
            UTIL_WSC.TESTMOCK = 'getSuccess';
            String result = WSC_Fiqas2.FQ_ResendInvoicePDF(inv.Id);
            System.assertEquals('The invoice has been sent out succesfully', result);

            UTIL_WSC.TESTMOCK = 'getFailed';
            result = WSC_Fiqas2.FQ_ResendInvoicePDF(inv.Id);
            Boolean expectedResult = result.contains('The re-sending has failed:') ? true : false;
            System.assertEquals(True, expectedResult);
        }
        Test.stopTest();

    }

}