public class Q_SyncInvoices implements System.Queueable, UTIL_CustomJob.ICustomJob {
    public List<Invoice__c> invoiceList = new List<Invoice__c>();

    public Q_SyncInvoices() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('Q_SyncInvoices');
        this.invoiceList = (List<Invoice__c>) GW_sObject.queryRecords('Invoice__c', UTIL_CustomJob.getWhereQuery(jobDef));
        UTIL.cache(this.invoiceList);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'Invoice__c'));

        if (this.numRecords > 0) readyForRun = true;
    }

    public void execute(QueueableContext qc) {
        UTIL_CustomJob.updateJobExecuteStartTime(qc.getJobId(), Datetime.now());

        try {
            GW_Invoice.checkStatusChangeAndUpdate(invoiceList);
        } catch(Exception ex) {
            UTIL.throwError('Q_SyncInvoices: ',ex);
        } finally {
            UTIL_CustomJob.markJobFinished('Q_SyncInvoices', qc.getJobId());
        }
    }

    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}