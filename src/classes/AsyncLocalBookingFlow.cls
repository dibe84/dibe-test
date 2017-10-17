public class AsyncLocalBookingFlow implements Queueable,Database.AllowsCallouts {
    
    private String oppId;
    
    public AsyncLocalBookingFlow(String oppId){
        this.oppId = oppId;
    }
    
    public void execute (QueueableContext context){
            UTIL_WSC.WSC_Request req;
            UTIL_WSC.WSC_Result res;
            req = UTIL_WSC.getWSC_Request('WSC_API_SFECG_v2.BookingPushTract');
            req.init(oppId);
            res = req.call();
            if (res.statusCode == 200 || res.statusCode == 201) {
                //call another quable class;
               System.debug('Finshed');
                
            } else {
             Map<String, Object> response = (Map<String, Object>) res.getResponseData().get('results');
            }
}
}