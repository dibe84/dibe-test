public class AsyncOrderCreateTractFlow implements Queueable,Database.AllowsCallouts {
    
    private String oppId;
    
    public AsyncOrderCreateTractFlow (String oppId){
        this.oppId = oppId;
    }
    
    public void execute (QueueableContext context){
   
            UTIL_WSC.WSC_Request req;
            UTIL_WSC.WSC_Result res;
            req = UTIL_WSC.getWSC_Request('WSC_Tract.OrderTract');
            req.init(oppId);
            res = req.call();
            if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
				for(Opportunity opp : [select id from Opportunity where id=:oppId and Account.SelfService__c = true]) {
	                System.enqueueJob(new AsyncGetTractServiceFlow(oppId));   
            	}
            } else {
            		Map<String, Object> response = (Map<String, Object>) res.getResponseData().get('results');
            }
       
}
}