public class Q_SyncRevStatus implements System.Queueable, UTIL_CustomJob.ICustomJob {

    public List<Rev__c> revs = new List<Rev__c>();

    public Q_SyncRevStatus() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('Q_SyncRevStatus');

        this.revs = (List<Rev__c>) GW_sObject.queryRecords('Rev__c', UTIL_CustomJob.getWhereQuery(jobDef));
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'Rev__c'));

        if (this.numRecords > 0) readyForRun = true;
    }

    public void execute(QueueableContext qc) {
        UTIL.cache(GW_Opportunity.getMapFromRelated(this.revs));

        try {
            UTIL_CustomJob.updateJobExecuteStartTime(qc.getJobId(), Datetime.now());
            GW_Revenue.checkStatusChangeAndUpdate(this.revs);
        } catch(Exception ex) {
            UTIL.throwError('Q_SyncRevStatus: ',ex);
        } finally {
            UTIL_CustomJob.markJobFinished('Q_SyncRevStatus', qc.getJobId());
        }
    }

    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}