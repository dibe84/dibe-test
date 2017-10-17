public class AsyncLocalAccountPushFlow implements Queueable,Database.AllowsCallouts {
    
    private String oppId;
    
    public AsyncLocalAccountPushFlow (String oppId){
        this.oppId= oppId;
    }
    
    public void execute (QueueableContext context){
    
            Opportunity opp = GW_Opportunity.getRecord(oppId);
            if(UTIL_WSC_Subscription.isAccOnlyAdsales(opp.AccountId)) return;

            UTIL_WSC.WSC_Request req;
            UTIL_WSC.WSC_Result res;
            req = UTIL_WSC.getWSC_Request('WSC_API_SFECG_v1.AccountPush');
            req.init(opp.AccountId);
            res = req.call();
            if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
                //call another quable class;
               AsyncLocalBookingFlow albf = new AsyncLocalBookingFlow(oppId);
               System.enqueueJob(albf);
                
            } else {
             Map<String, Object> response = (Map<String, Object>) res.getResponseData().get('results');
            }
}
}