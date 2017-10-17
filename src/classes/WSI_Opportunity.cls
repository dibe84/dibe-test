/**
 * Created by ronvelzeboer on 19/09/16.
 */

global class WSI_Opportunity {
    webService static String sendForApproval(String oppId) {
        String response = 'OK';
        if (String.isEmpty(oppId)) {
            return 'Opportunity Id should be set!';
        }
		
		Integer OLI_CNT = [select count() from OpportunityLineItem where OpportunityId =: oppId];
        
        if(OLI_CNT==0){
            return 'Please add at least one product in order to submit opportunity for approval.';
        }
		
        Opportunity opp;
		
        try {
            opp = [SELECT Billing_Account__r.Status__c, MemberUnit__r.Approval_Line_Manager__c, MemberUnit__r.Approval_Senior_Manager__c, MemberUnit__r.Approval_Head_of_Business__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
            if (opp.Billing_Account__r.Status__c == 'Ready To Sell') {
                opp.Ready_for_approval__c = true;
                Database.update(opp);  //Before sending for approval the opportunity we make sure all the fields (especially approvers) are the correct ones
                GW_Opportunity.sendForApproval(oppId, 'Please approve');
            } else {
                response = 'REJECTED';
            }
        } catch (Exception e) {
            System.debug('------------>>ERROR::::' + e.getStackTraceString());

            response = 'While trying to submit the Opportunity for approval the following error occured:\n\n';

            if (e.getMessage().contains('NO_APPLICABLE_PROCESS') && null != opp && !opp.HasOpportunityLineItem) {
                response += 'No applicable approval process was found. Please make sure one or more products were added to this opportunity.';
            } else {
                response += e.getMessage();
            }
        }
        return response;
    }
}