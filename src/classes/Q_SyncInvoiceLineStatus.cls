public class Q_SyncInvoiceLineStatus implements System.Queueable, UTIL_CustomJob.ICustomJob {

    public List<InvoiceLine__c> ils = new List<InvoiceLine__c>();

    public Q_SyncInvoiceLineStatus() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('Q_SyncInvoiceLineStatus');
        this.ils = (List<InvoiceLine__c>) GW_sObject.queryRecords('InvoiceLine__c', UTIL_CustomJob.getWhereQuery(jobDef));
        UTIL.cache(this.ils);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'InvoiceLine__c'));

        if (this.numRecords > 0) readyForRun = true;
    }

    public void execute(QueueableContext qc) {
        UTIL.cache(GW_Invoice.getMapFromRelated(this.ils).values());

        try {
            UTIL_CustomJob.updateJobExecuteStartTime(qc.getJobId(), Datetime.now());
            GW_InvoiceLine.checkStatusChangeAndUpdate(this.ils);
        } catch(Exception ex) {
            UTIL.throwError('Q_SyncInvoiceLineStatus: ',ex);
        } finally {
            UTIL_CustomJob.markJobFinished('Q_SyncInvoiceLineStatus', qc.getJobId());
        }
    }

    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}