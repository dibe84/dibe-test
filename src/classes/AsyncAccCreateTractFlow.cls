public class AsyncAccCreateTractFlow implements Queueable,Database.AllowsCallouts {
    
    private String oppId;
    
    
    public AsyncAccCreateTractFlow (String oppId){
        this.oppId = oppId;
    }
    
	public void execute (QueueableContext context){
        Opportunity opp = GW_Opportunity.getRecord(oppId);
        Account acc = GW_Account.getRecord(opp.AccountId);
   
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        if(String.isBlank(acc.Tract_AccountId__c)){
            req = UTIL_WSC.getWSC_Request('WSC_Tract.BillingAccountCreate');
        } else if ( !String.isBlank(acc.Tract_AccountId__c) ) {
            req = UTIL_WSC.getWSC_Request('WSC_Tract.BillingAccountUpdate');
        }
        req.init(acc.Id);
        res = req.call();
        if (res.statusCode == 200 || res.statusCode == 201) {
            AsyncGetAgreementTractFlow agatf = new AsyncGetAgreementTractFlow(oppId);
            System.enqueueJob(agatf);              
        } else {
         Map<String, Object> response = (Map<String, Object>) res.getResponseData().get('results');
        }

    }
}