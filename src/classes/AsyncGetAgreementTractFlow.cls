public class AsyncGetAgreementTractFlow implements Queueable,Database.AllowsCallouts {
    
      
    private String oppId;
    
    public AsyncGetAgreementTractFlow (String oppId){
        this.oppId = oppId;
    }
    
    public void execute (QueueableContext context){
            UTIL_WSC.WSC_Request req;
            UTIL_WSC.WSC_Result res;
            req = UTIL_WSC.getWSC_Request('WSC_Tract.GetAgreementId');
            req.init(oppId);
            res = req.call();
            if (res.statusCode == 200 || res.statusCode == 201) {
                AsyncDraftOrderCreateTractFlow draftOrderCreate = new AsyncDraftOrderCreateTractFlow(oppId);
                //call another quable class;
                System.enqueueJob(draftOrderCreate);   
                
            } else {
             Map<String, Object> response = (Map<String, Object>) res.getResponseData().get('results');
            }
}
}