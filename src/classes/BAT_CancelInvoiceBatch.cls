global class BAT_CancelInvoiceBatch implements Database.Batchable<sObject>, Database.Stateful  {

    global final String invBatchId;
    global final String cancellationReason;

    global BAT_CancelInvoiceBatch(String batchId, String cancellationReason) {
        this.invBatchId = batchId;
        this.cancellationReason = cancellationReason;
        if(invBatchId == null) UTIL.throwError('Invoicing Batch ID not defined');
        if(cancellationReason == null || cancellationReason == '') UTIL.throwError('CancellationReason is required');
    }

    global List<Invoice__c> start(Database.BatchableContext BC) {
 		InvoiceBatch__c invBatch = [Select Id, (Select Id From Invoices__r) From InvoiceBatch__c Where BatchId__c = :invBatchId LIMIT 1 FOR UPDATE];        

        invBatch.Status__c = 'Cancelling Batch';
		invBatch.CancellationReason__c = cancellationReason;
		invBatch.CancellationTimestamp__c = System.now();
        
        try {
            update invBatch;
        } catch (Exception ex) {
            UTIL.throwError('BAT_CancelInvoiceBatch: Error cancelling InvoiceBatch__c - ' + ex.getMessage() + ex.getStackTraceString());
        }
        return invBatch.Invoices__r;
    }

    global void execute(Database.BatchableContext BC, List<Invoice__c> invs) {  
		for(Invoice__c inv : invs) { inv.Cancelled__c = TRUE; }

		try {
			update invs;
        } catch (Exception ex) {
            UTIL.throwError('BAT_CancelInvoiceBatch: Error updating Invoices - ' + ex.getMessage() + ex.getStackTraceString());
        }

    }

    global void finish(Database.BatchableContext BC) {
    	InvoiceBatch__c invBatch = [Select Id From InvoiceBatch__c Where BatchId__c = :invBatchId LIMIT 1 FOR UPDATE];        
        invBatch.Status__c = 'Cancelled';
        
        try {
            update invBatch;
        } catch (Exception ex) {
            UTIL.throwError('BAT_CancelInvoiceBatch: Error saving cancelled InvoiceBatch__c - ' + ex.getMessage() + ex.getStackTraceString());
        }    
        
    }

}