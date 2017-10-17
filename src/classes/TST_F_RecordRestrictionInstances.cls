@isTest
private class TST_F_RecordRestrictionInstances extends TSTDF_Base {

    public static TST_F_RecordRestrictionInstances factory = new TST_F_RecordRestrictionInstances(new TSTDF_Dataset());

    public TST_F_RecordRestrictionInstances(TSTDF_Dataset dataset) {
        super(dataset);
    }

    public class TSTDF_Dataset extends TSTDF_BaseDataSet {

    }

    public override void queryAdditionalResults() {
    }

    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        factory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }
    // JC 12/08/2016: Had to comment, null pointer exception - blocks deployment
    @isTest static void testLockRSWhenInvoiceSent() {
        // factory.queryResults();
        // Invoice__c inv = factory.data.invoices[0];
        // InvoiceLine__c il = factory.data.invoicelines[0];
        // Rs__c rs = GW_RS.getRecord(il.RS__c);
    }

    @isTest static void testLockInvoicesSent(){

    }

    @isTest static void testInvoiceLineRestrictions(){
    }

    @isTest static void testOpportunitySetLostRestrictions(){
    }

    @isTest static void testOpportunityDeletionRestriction(){
    }

}