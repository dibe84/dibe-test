public class Q_SyncOliStatus implements System.Queueable, UTIL_CustomJob.ICustomJob {

    public List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

    public Q_SyncOliStatus() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('Q_SyncOliStatus');
        this.olis = (List<OpportunityLineItem>) GW_sObject.queryRecords('OpportunityLineItem', UTIL_CustomJob.getWhereQuery(jobDef));
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'OpportunityLineItem'));

        if (this.numRecords > 0) readyForRun = true;
    }

    public void execute(QueueableContext qc) {
        UTIL_CustomJob.updateJobExecuteStartTime(qc.getJobId(), Datetime.now());
        UTIL.cache(GW_Opportunity.getMapFromRelated(this.olis));

        try {
            GW_OpportunityLineItem.checkStatusChangeAndUpdate(this.olis);
        } catch(Exception ex) {
            UTIL.throwError('Q_SyncOliStatus: ',ex);
        } finally {
            UTIL_CustomJob.markJobFinished('Q_SyncOliStatus', qc.getJobId());
        }
    }

    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}