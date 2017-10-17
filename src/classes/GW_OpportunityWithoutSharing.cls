public without sharing class GW_OpportunityWithoutSharing {
    public static void applyOppsChangesToRevenues(Map<Id, Opportunity> oppsUpdateRevBillingDetails, Map<Id, Opportunity> oppsUpdateRevDiscount ){
        
        OpportunityLineItem discountOli;
        Map<Id,OpportunityLineItem> olisWithDiscountChange = new Map<Id,OpportunityLineItem>();
        List<OpportunityLineItem> olisToCheckStatus;
        
        // Loads the revenue items for all changed opps
        List<Rev__c> revsToUpdate = GW_Revenue.getListFromRelated( oppsUpdateRevBillingDetails.keySet() );
        
        // Loads opportunity line items for opps that had their Agency field changed
        if( !oppsUpdateRevDiscount.isEmpty() ){
            olisToCheckStatus = GW_OpportunityLineItem.getListFromRelated( oppsUpdateRevDiscount.keySet() );
            olisWithDiscountChange = new Map<Id,OpportunityLineItem>( olisToCheckStatus );  
        }
        
        // Changes the revenue items with the updated values
        Boolean cascadeDML = false;
        for (Rev__c rev : revsToUpdate) {
            rev.Billing_Account__c = oppsUpdateRevBillingDetails.get(rev.Opportunity__c).Billing_Account__c;
            rev.InvoiceGrouping__c = oppsUpdateRevBillingDetails.get(rev.Opportunity__c).InvoiceGrouping__c;
            discountOli = olisWithDiscountChange.get( rev.OpportunityLineItemId__c ); 
            if( discountOli != null ){
                rev.IndirectDiscountAmount__c = discountOli.IndirectDiscountAmount__c;
                cascadeDML = true; 
            }
        }

        try {
            HNDL_Rev.cascadeDML = cascadeDML;
            update revsToUpdate;
        } catch (Exception ex) {
            UTIL.throwError('HNDL_Opportunity - Error syncing Revenues. ',ex);
        }
    }
}