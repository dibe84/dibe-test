global class BAT_AutoExtendRevItems implements Database.Batchable<sObject>, UTIL_CustomJob.ICustomJob, Database.Stateful {
    global Datetime executeStart;
    public String queryString;
    public Boolean useForUpdate;

    public BAT_AutoExtendRevItems() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_AutoExtendRevItems');
        this.queryString = UTIL_CustomJob.getWhereQuery(jobDef);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'Rev__c'));
        if (this.numRecords>0) readyForRun = true;
    }

    public List<Rev__c> start(Database.BatchableContext BC) {
        return GW_sObject.queryRecords('Rev__c', this.queryString);
    }

    public void execute(Database.BatchableContext BC, List<Rev__c> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        UTIL.log('Executing BAT_AutoExtendRevItems. Scope: '+scope.size()+' records.');
        List<Rev__c> revsToUpdate = new List<Rev__c>();

    	for (Rev__c rev : scope) {
            if (rev.ScheduleAhead_EndDate__c > rev.Until_Date__c) {
                rev.Until_Date__c = rev.ScheduleAhead_EndDate__c;
                revsToUpdate.add(rev);
            }
    	}

        if (revsToUpdate.size()>0 ) {
	    	try {
                HNDL_Rev.cascadeDML = true;
	    		update revsToUpdate;
	    	} catch(Exception ex) {
	    		UTIL.throwError('BAT_AutoExtendRevItems: Error updating Revs',ex );
	   		}
	   	}
    }

    public void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_AutoExtendRevItems', BC.getJobId());
    }

    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}