/**
 * Created by rvannierop on 2/28/2017.
 */

global class BAT_ProductDiscountImportFromTRACT implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {

    global Datetime executeStart;
    String queryString;

    global BAT_ProductDiscountImportFromTRACT() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_ProductDiscountImportFromTRACT');
        this.queryString = UTIL_CustomJob.getWhereQuery(jobDef);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'Product2'));
        if (this.numRecords>0) readyForRun = true;
    }

    global List<Product2> start(Database.BatchableContext BC) {
        List<Product2> masterProducts = (List<Product2>) GW_sObject.queryRecords('Product2', this.queryString);
        return masterProducts;
    }

    global void execute(Database.BatchableContext BC, List<Product2> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        List<Product2> productsToUpdate = new List<Product2>();
        for (Product2 product : scope) {
            //Only mark master products to sync the discount relations.
            if (product.Parent__c == null && product.Tract_Id__c != null ) {
                product.Tract_NeedsDiscountRelationsSync__c = true;
                productsToUpdate.add(product);
            }
        }

        Savepoint sp = Database.setSavepoint();
        try {
            update productsToUpdate;
        } catch(Exception ex) {
            Database.rollback(sp);
            UTIL.throwError('BAT_ProductDiscountImportFromTRACT - Error updating Tract Products to refresh Product Discount relations',ex);
        }
    }

    global void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_ProductDiscountImportFromTRACT', BC.getJobId());
    }

    // interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }

}