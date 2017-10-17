global class BAT_GenerateInvoiceBatch implements Database.Batchable<sObject>, Database.Stateful  {

    global final InvoiceBatch__c batch;
    global Map<String, Id> newInvoiceIdMap; // Map of Invoices shared by the batches

    global BAT_GenerateInvoiceBatch(InvoiceBatch__c batch) {
        this.batch = batch;
        this.newInvoiceIdMap = new Map<String,Id>();
    }

    global List<InvoiceLine__c> start(Database.BatchableContext BC) {
        List<InvoiceLine__c> ils = GW_Invoice.generateInvoiceLines(this.batch);
        return ils;
    }

    global void execute(Database.BatchableContext BC, List<InvoiceLine__c> ils) {
        GW_InvoiceLine.cacheRelatedRecords(ils);
        Map<String, List<InvoiceLine__c>> newInvoiceLinesMap; // Map InvoiceUID => List<InvoiceLine__c>
        newInvoiceLinesMap = 	GW_InvoiceLine.returnMapInvoiceUIDInvoiceLines(ils);
        Map<String,Invoice__c> 	invsToBeInserted = new Map<String,Invoice__c>();
        
        // first create missing Invoices for all invUID's
        for (String invUID : newInvoiceLinesMap.keySet() ) {
            Invoice__c newInv;
            if ( !newInvoiceIdMap.containsKey(invUID) ) { // this invoice doesn't exist yet, create it based on 1st il
				newInv = GW_Invoice.createInvoiceForInvoiceLine(batch, newInvoiceLinesMap.get(invUID)[0] );                
            }
            if ( newInv != null ) {
                invsToBeInserted.put(invUID,newInv);   
            }
        }
        
        try {
            if (invsToBeInserted.size()>0) insert invsToBeInserted.values();
            for (Invoice__c inv : invsToBeInserted.values()) {
                newInvoiceIdMap.put(inv.UniqueKey__c,inv.Id); // add to global map for use with other batches
            }
        } catch (Exception ex) {
            UTIL.throwError('processBatch: Error saving Invoices - ' + ex.getMessage());
        }
        
        for (InvoiceLine__c il : ils) {
            il.Invoice__c = newInvoiceIdMap.get(il.InvoiceUID__c); 
        } 
         
        try {
            insert ils; 
        } catch (Exception ex) { 
            System.abortJob(BC.getJobId());
            UTIL.throwError('processBatch: Error saving InvoiceLines - ' + ex.getMessage());
        } 
    }

    global void finish(Database.BatchableContext BC) {        
		UTIL.log('~!@: Entered Finish method');
        InvoiceBatch__c invBatch = [Select Id, Status__c From InvoiceBatch__c Where Id = :batch.Id LIMIT 1 FOR UPDATE];
        invBatch.Status__c = 'Ready to Send';
        // Id batchJobId = Database.executeBatch(new BAT_CancelInvoiceBatch(batch.BatchId__c, 'Incorrectly created'), 200);
        try {
            update invBatch; 
        } catch (Exception ex) {
            UTIL.throwError('BAT_CancelInvoiceBatch: Error saving created InvoiceBatch__c - ' + ex.getMessage() + ex.getStackTraceString());
        }    
        
    }

}