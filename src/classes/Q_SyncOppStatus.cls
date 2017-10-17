public class Q_SyncOppStatus implements System.Queueable, UTIL_CustomJob.ICustomJob {

    public List<Opportunity> opps = new List<Opportunity>();

    public Q_SyncOppStatus() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('Q_SyncOppStatus');
        this.opps = (List<Opportunity>) GW_sObject.queryRecords('Opportunity', UTIL_CustomJob.getWhereQuery(jobDef));
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'Opportunity'));

        if (this.numRecords > 0) readyForRun = true;    
    }

    public void execute(QueueableContext qc) {
        try {
			HNDL_Opportunity.isQ_SyncJobUpdate = true;
            UTIL_CustomJob.updateJobExecuteStartTime(qc.getJobId(), Datetime.now());
            GW_Opportunity.checkStatusChangeAndUpdate(this.opps);
        } catch(Exception ex) {
            UTIL.throwError('Q_SyncOppStatus: ',ex);
        } finally {
            UTIL_CustomJob.markJobFinished('Q_SyncOppStatus', qc.getJobId());
        }
    }

    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}