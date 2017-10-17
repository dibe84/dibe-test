public class AsyncGetTractRevenueScheduleFlow implements Queueable,Database.AllowsCallouts {
    
    private String oppId;
    public AsyncGetTractRevenueScheduleFlow (String oppId){
        this.oppId = oppId;
    }
    
	public void execute (QueueableContext context){
		try{
        	WSC_Tract.syncTractRevenueSchedule(oppId);
		}catch(Exception ex){
			UTIL.log('AsyncGetTractRevenueScheduleFlow Error : ' + ex.getMessage());	
		}
        
        for(Opportunity opp : [select id from Opportunity where id=:oppId and Account.SelfService__c = true]) {
            System.enqueueJob(new AsyncLocalAccountPushFlow(oppId));   
        }
    }
    
}