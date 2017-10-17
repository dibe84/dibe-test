/**
 *  Class for resend invoice to Tract from TRACT Invoices related list of Account detail screen
 *  @date : 24/08/2017
 *  @author : GIS-devteam
 *  @description : call from "Resend Invoice" custom button
 *  @category : TRACT
 */
global class WSI_TractInvoicesController {
    
   webservice static String resendTractInvoices(String[] invIds){
        Set<Id>sInvIds = (Set<Id>) JSON.deserialize(JSON.serialize(invIds), Set<Id>.class);
        List<TRACT_Invoice__c>tractInvs = (List<TRACT_Invoice__c>)GW_sObject.queryRecords('TRACT_Invoice__c', sInvIds);
        String result = '';
        for(TRACT_Invoice__c tInv : tractInvs){
            try {
                UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.InvoiceResend');
                req.mAdditionalParams = new Map<String,Object>{'invoice_id' => tInv.External_Id__c};
                req.init(tInv.Billing_Account__c);
                UTIL_WSC.WSC_Result res = req.call();
                if(res.statusCode == 204) {
                    result += tInv.Name + ': Invoice sent successfully. \n';
                } else {
                    result += tInv.Name + ': Error ';
                    Map<String, Object> response = (Map<String, Object>) res.getResponseData().get('results');
                    if (response == null) result += res.errorMsg;
                    else result += response.get('message');
                    result += '\n ';
                }
            } catch (Exception ex) {
                return ex.getMessage() + '\nError when trying to resend invoice, please try again later. If the problem persists, please, contact your administrator.';
            }
        }
        return result;     
    }
        
}