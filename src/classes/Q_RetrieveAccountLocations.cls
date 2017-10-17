public class Q_RetrieveAccountLocations implements System.Queueable, UTIL_CustomJob.ICustomJob, Database.AllowsCallouts {

    public List<Account> accounts = new List<Account>();

    public Q_RetrieveAccountLocations() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('Q_RetrieveAccountLocations');
		this.accounts = (List<Account>) GW_sObject.queryRecords('Account', UTIL_CustomJob.getWhereQuery(jobDef));
        UTIL.cache(this.accounts);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'Account'));
        if (this.numRecords > 0) {
			readyForRun = true;
        }
    }

    public void execute(QueueableContext qc) {
        try {
            UTIL_CustomJob.updateJobExecuteStartTime(qc.getJobId(), Datetime.now());
            GW_Account.retrieveAccountLocations(this.accounts);
        } catch(Exception ex) {
            UTIL.throwError('Q_RetrieveAccountLocations: ',ex);
        } finally {
            UTIL_CustomJob.markJobFinished('Q_RetrieveAccountLocations', qc.getJobId());
        }
    }

    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}