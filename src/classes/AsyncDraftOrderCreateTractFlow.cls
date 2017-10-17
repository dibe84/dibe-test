public class AsyncDraftOrderCreateTractFlow implements Queueable,Database.AllowsCallouts {
    
    private String oppId;
    
    public AsyncDraftOrderCreateTractFlow (String oppId){
        this.oppId = oppId;
    }
    
    public void execute (QueueableContext context){
            UTIL_WSC.WSC_Request req;
            UTIL_WSC.WSC_Result res;
            req = UTIL_WSC.getWSC_Request('WSC_Tract.DraftOrderCreate');
            System.debug('In draft orderQuabeel');
            req.init(oppId);
            res = req.call();
            if (res.statusCode == 200 || res.statusCode == 201) {
                AsyncOrderCreateTractFlow aoctf = new AsyncOrderCreateTractFlow(oppId);
                System.enqueueJob(aoctf);          
                 
                //call another quable class;
               System.debug('Looking Good');
                
            } else {
             Map<String, Object> response = (Map<String, Object>) res.getResponseData().get('results');
            }
}
}