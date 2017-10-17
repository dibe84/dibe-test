public class AsyncGetTractServiceFlow implements Queueable,Database.AllowsCallouts {
    
    private String oppId;
    public AsyncGetTractServiceFlow (String oppId){
        this.oppId = oppId;
    }
    
	public void execute (QueueableContext context){
		try{
			Opportunity opp = GW_Opportunity.getRecord(oppId);
        	WSC_Tract.syncTractService(opp);
		}catch(Exception ex){
			UTIL.log('AsyncGetTractServiceFlow Error : ' + ex.getMessage());
		}
		
        if(!Test.isRunningTest()) System.enqueueJob(new AsyncGetTractRevenueScheduleFlow(oppId));
    }
    
}