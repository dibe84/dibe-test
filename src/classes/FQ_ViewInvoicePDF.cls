public class FQ_ViewInvoicePDF {

    ///View invoice PDF code
    public void loadPDF(){
        currentInvId = Apexpages.currentPage().getParameters().get('id');
        Invoice__c inv = new Invoice__c();

        try{
        	inv = (Invoice__c) GW_sObject.queryrecord('Invoice__c', id.valueof(currentInvId));
        }catch(exception e){
            isSuccess =  false;
            ApexPages.Message errMessage = new ApexPages.Message(ApexPages.severity.ERROR, 'Insufficient access' );
            ApexPages.addMessage(errMessage);
            return;
        }

        if(inv.Invoice_PDF_Retrieved__c == False){
            isSuccess =  false;
            ApexPages.Message errMessage = new ApexPages.Message(ApexPages.severity.ERROR, 'The PDF file isn\'t available yet.' );
            ApexPages.addMessage(errMessage);
            return;
        }

        try{
			String externalId = inv.FQ_InvoiceID__c != null ? inv.FQ_InvoiceID__c : inv.UniquePlatformId__c;

      		string invName = inv.Id + '_' + externalId + '.pdf';

        	Attachment att = [SELECT body FROM Attachment WHERE ParentId =: inv.id AND Name =: invName];
            pdf = EncodingUtil.base64Encode(att.Body);
        }catch(exception e){
            isSuccess =  false;
            ApexPages.Message errMessage = new ApexPages.Message(ApexPages.severity.ERROR, 'The invoice PDF file can\'t be found, please contact your system administrator.');
            ApexPages.addMessage(errMessage);
            return;
        }

        isSuccess = true;
    }

    public String currentInvId{get;set;}
    public Transient String pdf{get;set;}
    public Boolean isSuccess{get;set;}

}