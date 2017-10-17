/**
 * @createdDate: 06-12-2016
 * @desc: CD-1398 
 * 	  -The idea to create a batch-job that periodically touches records, and by doing so increasing the LastModified date of those records. 
 *	  Records that run into a validation problem, will not have its Lastmodified date changed.
 *	  -Todo: Get all account where LastmodifiedDate < LAST_WEEK then update those field Touch__c on account with a message 
 */
global class BAT_TouchAccount implements Database.Batchable<sObject>, UTIL_CustomJob.ICustomJob, Database.Stateful {
	public String whereClause;
	global Datetime executeStart;
	
    public BAT_TouchAccount(){
    	UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_TouchAccount');
        this.whereClause = jobDef.setting.WhereClause__c;
        this.numRecords = Database.countQuery('SELECT count() from Account WHERE '+this.whereClause);
        if (this.numRecords>0) readyForRun = true;
    }
    
    public List<Account> start(Database.BatchableContext BC) {
    	return GW_sObject.queryRecords('Account', this.whereClause);
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope) {
    	if(this.executeStart == null) this.executeStart = Datetime.now();
        UTIL.log('Executing BAT_TouchAccount. Scope: '+scope.size()+' records.');
        List<Account> accTobeUpdated = new List<Account>();

    	for (Account acc : scope) {
            acc.Touch__c = 'Touched by API batch job - <'+  System.today() +'>';
            accTobeUpdated.add(acc);
    	}

        if (!accTobeUpdated.isEmpty()) {
	    	try {
	    		Database.update(accTobeUpdated, false);
	    	} catch(Exception ex) {
	    		UTIL.throwError('BAT_TouchAccount: Error updating Accounts',ex );
	   		}
	   	}
    }
    
    public void finish(Database.BatchableContext BC) {
    	UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_TouchAccount', BC.getJobId());
    }
    
    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}