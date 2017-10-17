/**
* This batch will run 1 record per transaction because it will use old method from WSC_Freespee
* it will use hard code id since we don't need to run all user
*/
global class BAT_ActivateFreespeeNumber implements Database.Batchable<sObject>, Database.AllowsCallouts{
    private Set<String> iDs;
    
    public BAT_ActivateFreespeeNumber(Set<String> iDs){
    	this.iDs = iDs;
    }
    
    global List<sObject> start(Database.BatchableContext BC){
    	return GW_Sobject.queryRecords('Account', 'LocalPlatformId__c', iDs);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> objs) {  
    	

		try {
			//this will always return 1 record per list
			for(Account acc : (List<Account>)objs) { 
				String result = WSC_Freespee.trackThisAccountPhone(acc.id);
			}
        } catch (Exception ex) {
            UTIL.throwError('BAT_ActivateFreespeeNumber: Error - ' + ex.getMessage() + ex.getStackTraceString());
        }

    }

    global void finish(Database.BatchableContext BC) {
        
    }
    
}