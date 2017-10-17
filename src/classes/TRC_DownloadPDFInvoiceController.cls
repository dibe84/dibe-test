/**
 * CD-3538
 * Get PDF invoice from tract when user clicks on PDF Link custom field on Tract Invocie detail page.
 * @author : GAEA-SYS TEAM
 * @created date : 19 Aug 2017
 * 
 */
public class TRC_DownloadPDFInvoiceController {
    TRACT_Invoice__c tInvoice;
    
    public TRC_DownloadPDFInvoiceController(ApexPages.StandardController stdController) {
        try {
            String invId  = stdController.getId() ;
            tInvoice = [Select External_Id__c, Billing_Account__c, Name from TRACT_Invoice__c Where Id =:invId];
        } catch(Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex+''));
            return;
        }
    }
    
    public PageReference navigate2DownloadURL() {
        LSC_GTAUSPaymentPortalController.ResponseResult respResult;
        try {
            String jsonResult = LSC_GTAUSPaymentPortalController.doFetchInvoicePDFFromTract(tInvoice.External_Id__c, tInvoice.Billing_Account__c);
            respResult = (LSC_GTAUSPaymentPortalController.ResponseResult) JSON.deserialize(jsonResult, LSC_GTAUSPaymentPortalController.ResponseResult.class);
            system.debug('respResult.result=======' + respResult.result);
            
            if ( !respResult.status.equalsIgnoreCase('success') ) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,respResult.result));
                return null;
            }
        
        } catch(Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex+''));
            return null;
        }
        
        return new PageReference(respResult.result);
    }
     

}