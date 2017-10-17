public class Q_SyncRsStatus implements System.Queueable, UTIL_CustomJob.ICustomJob {

    public List<RS__c> rss = new List<RS__c>();

    public Q_SyncRsStatus() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('Q_SyncRsStatus');
        this.rss = (List<RS__c>) GW_sObject.queryRecords('RS__c', UTIL_CustomJob.getWhereQuery(jobDef));
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'RS__c'));

        if (this.numRecords > 0) readyForRun = true;
    }

    public void execute(QueueableContext qc) {
        UTIL_CustomJob.updateJobExecuteStartTime(qc.getJobId(), Datetime.now());
        UTIL.cache(GW_Revenue.getMapFromRelated(this.rss).values());
        try {
            GW_RS.checkStatusChangeAndUpdate(this.rss);
        } catch(Exception ex) {
            UTIL.throwError('Q_SyncRsStatus: ',ex);
        } finally {
            UTIL_CustomJob.markJobFinished('Q_SyncRsStatus', qc.getJobId());
        }
    }

    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}