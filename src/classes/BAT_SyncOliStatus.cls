global class BAT_SyncOliStatus implements Database.Batchable<sObject>, UTIL_CustomJob.ICustomJob, Database.Stateful {

	global Datetime executeStart;

    public String whereClause;

    public BAT_SyncOliStatus() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_SyncOliStatus');
        this.whereClause = jobDef.setting.WhereClause__c;
        this.numRecords = Database.countQuery('SELECT count() from OpportunityLineItem WHERE '+this.whereClause);
        if (this.numRecords>0) readyForRun = true;
    }

    public List<OpportunityLineItem> start(Database.BatchableContext BC) {
        return GW_sObject.queryRecords('OpportunityLineItem', this.whereClause);
    }

    public void execute(Database.BatchableContext BC, List<OpportunityLineItem> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        UTIL.log('Executing BAT_SyncOliStatus. Scope: '+scope.size()+' records.');
        try {
            GW_OpportunityLineItem.checkStatusChangeAndUpdate(scope);
        } catch(Exception ex) {
            UTIL.throwError('BAT_SyncOliStatus: Error updating olis',ex );
        }
    }

    public void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_SyncOliStatus', BC.getJobId());
    }

    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}