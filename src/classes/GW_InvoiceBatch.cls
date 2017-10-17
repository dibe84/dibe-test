public with sharing class GW_InvoiceBatch {
    private static final Schema.sObjectType GW_BASEOBJECT = InvoiceBatch__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'InvoiceBatch__c';

    private static String getNewBatchId() {
        return DateTime.now().format('yyyyMMddHHmmss');
    }

    public static InvoiceBatch__c createnewBatch() {
    	return createnewBatch('');
    }

    public static Boolean batchBeingProcessedFor(String memberUnitId) {
        return [SELECT Id FROM InvoiceBatch__c
             WHERE Status__c IN ('Generating Invoices', 'Cancelling Batch')
             AND MemberUnitId__c = :memberUnitId LIMIT 1 ].size() > 0;
    }

    public static InvoiceBatch__c createnewBatch(String memberUnitId) {
        if (batchBeingProcessedFor(memberUnitId)) {
        	UTIL.throwError('Please wait till the generation / cancelling process for this MemberUnit is finished');
        }

        InvoiceBatch__c batch = new InvoiceBatch__c();
        batch.memberUnitId__c = memberUnitId;
        batch.BatchId__c = getnewBatchId();
        batch.GenerationTimestamp__c = System.now();
		batch.User__c = UserInfo.getUserId();
		batch.Status__c = 'Generating Invoices';
		batch.CancellationReason__c = null;
        try {
            insert batch;
        } catch (Exception ex) {
            UTIL.throwError('CreateInvoicingBatch: Error saving InvoiceBatch__c - ' + ex.getMessage() + ex.getStackTraceString());
        }
        return batch;
    }

    public static Boolean batchHasUnhealthyAccounts(String batchId) {
        return ( [SELECT Id FROM Invoice__c WHERE BillingAccount__r.Status__c != 'Ready To Sell' AND InvoiceBatch__r.BatchId__c = :batchId ] ).size() > 0;        
    }

    public static void resendInvoiceBatchFailedInvoices(String batchId) {
        if (String.isEmpty(batchId)) { UTIL.throwError('Invoicing Batch ID not defined'); }
        InvoiceBatch__c invoiceBatch = [ SELECT Id FROM InvoiceBatch__c WHERE BatchId__c = :batchId ];
        List<Invoice__c> invoices = (List<Invoice__c>) GW_sObject.queryRecordsForUpdate('Invoice__c', 'FQ_NumFailedLines__c > 0 AND InvoiceBatch__c = \'' + invoiceBatch.Id + '\'');

        for (Invoice__c invoice : invoices) {
            invoice.FQ_SyncPending__c = true;
        }
		try {
			update invoices;
		} catch (Exception e) {
			UTIL.throwError('resendInvoiceBatchFailedInvoices: Error while trying to mark failed invoices for resend - ' + e.getMessage() + ' ' + e.getStackTraceString());
		}
    }

    public static void sendToBilling(String batchId) {
        Savepoint sp = Database.setSavePoint();
        try {
            InvoiceBatch__c invoiceBatch = [ SELECT Id FROM InvoiceBatch__c WHERE BatchId__c = :batchId ];
            Set<Id> invIds = GW_Invoice.getInvoicesPartOfBatchForUpdate(batchId);
            GW_Invoice.markForSyncToBilling(invIds);

            invoiceBatch.SendInitiatedAt__c = System.now();
            invoiceBatch.Status__c = 'Send To Billing';
            update invoiceBatch;
        } catch (Exception e) {
            Database.rollback(sp);
            UTIL.throwError('sendToBilling: Could not send batch to billing - ' + e.getMessage());
        }
    }

    public static List<InvoiceBatchHistoryItem> getHistoryListWithLimit( Integer numRows , Id memberUnitId ) {
        
    	String muAppendix = null;
    	if( !String.isBlank( memberUnitId ) ){
    	    MemberUnit__c mu = GW_MemberUnit.getRecord( memberUnitId );
            muAppendix = mu.MemberUnitId__c;    	    
    	}
        
        List<InvoiceBatch__c> pendingBatches = GW_sObject.queryRecords(GW_BASEOBJECTNAME, 'Status__c = \'Send To Billing\'');
        Map<String, InvoiceBatch__c> batchLookupByBatchIdString = new Map<String, InvoiceBatch__c>();

        for (InvoiceBatch__c batch : pendingBatches) {
            batchLookupByBatchIdString.put(batch.BatchId__c, batch);
        }
        Set<String> historicBatchIdStrings = batchLookupByBatchIdString.keySet();

        List<InvoiceBatchHistoryItem> hlist = new List<InvoiceBatchHistoryItem>();
        List<AggregateResult> rows = [
            SELECT InvoiceBatch__r.BatchId__c, SUM(NumLineItems__c) numLineItems, COUNT(Id) numInvoices, SUM(Amount__c) invoiceAmount,
                SUM(FQ_SyncPendingNumber__c) numFQSyncPending, SUM(ScheduledCalloutPendingNumber__c) numCalloutSyncPending, SUM(FQ_NumFailedLines__c) numFailedLineItems
            FROM Invoice__c
            WHERE InvoiceBatch__r.BatchId__c IN :historicBatchIdStrings
            AND InvoiceBatch__r.MemberUnitId__c = :muAppendix  
            GROUP BY InvoiceBatch__r.BatchId__c
            ORDER BY InvoiceBatch__r.BatchId__c DESC
            LIMIT :numRows
        ];

        for (AggregateResult ar : rows) {
            hlist.add(new InvoiceBatchHistoryItem(ar, batchLookupByBatchIdString.get((String) ar.get('BatchId__c'))));
        }
        return hlist;
    }

    public virtual class InvoiceBatchItem {
        public String invoiceBatchId { get; set; }
        public Integer numLineItems { get; set; }
        public Integer numInvoices { get; set; }
        public Decimal invoiceAmount { get; set; }
        public InvoiceBatch__c invoiceBatch { get; set; }
        public User createdBy { get; set; }
        public User lastActionBy { get; set; }
        public String status { get; set; }

        public InvoiceBatchItem(AggregateResult ar, InvoiceBatch__c invoiceBatch) {
            this.invoiceBatchId = invoiceBatch.BatchId__c;
            this.numLineItems = null != ar ? Integer.valueOf(ar.get('numLineItems')) : 0;
            this.numInvoices = null != ar ? (Integer) ar.get('numInvoices') : 0;
            this.invoiceAmount = null != ar ? (Decimal) ar.get('invoiceAmount') : 0;
            this.invoiceBatch = invoiceBatch;
            this.status = invoiceBatch.Status__c;
            this.createdBy = (User) UTIL.getCached(invoiceBatch.CreatedById);
        }
    }

    public virtual class InvoiceBatchHistoryItem extends GW_InvoiceBatch.InvoiceBatchItem {
        public Decimal percentageSent { get; set; }
        public Integer numFailedLineItems { get; set; }
        public Integer numInvoicesPending { get; set; }

        public InvoiceBatchHistoryItem(AggregateResult ar, InvoiceBatch__c invoiceBatch) {
            super(ar, invoiceBatch);
			Integer numInvoicesPending = Integer.valueOf(ar.get('numFQSyncPending')) + Integer.valueOf(ar.get('numCalloutSyncPending'));
            this.numInvoicesPending = numInvoicesPending;
            this.percentageSent = ((this.numInvoices - numInvoicesPending) / this.numInvoices) * 100;
			this.numFailedLineItems = Integer.valueOf(ar.get('numFailedLineItems'));
        }
    }

    public static List<GW_InvoiceBatch.InvoiceBatchItem> getInvoicePendingSendBatchList( String memberUnitId ) {
    	
    	String muAppendix = '';
    	if( !String.isBlank( memberUnitId ) ){
    	    MemberUnit__c mu = GW_MemberUnit.getRecord( memberUnitId );
            muAppendix = ' AND MemberUnitId__c = \'' + mu.MemberUnitId__c + '\' ';    	    
    	}

        List<InvoiceBatch__c> pendingBatches = GW_sObject.queryRecords(GW_BASEOBJECTNAME, 'Status__c IN (\'Generating Invoices\', \'Ready To Send\',\'Cancelling Batch\') AND BatchId__c != null' + muAppendix );
        Map<String, InvoiceBatch__c> batchLookupByBatchIdString = new Map<String, InvoiceBatch__c>();

        for (InvoiceBatch__c batch : pendingBatches) {
            batchLookupByBatchIdString.put(batch.BatchId__c, batch);
        }
        Set<String> pendingBatchIdStrings = batchLookupByBatchIdString.keySet();

        List<GW_InvoiceBatch.InvoiceBatchItem> plist = new List<GW_InvoiceBatch.InvoiceBatchItem>();
        List<AggregateResult> rows = [
            SELECT InvoiceBatch__r.BatchId__c, SUM(NumLineItems__c) numLineItems, COUNT(Id) numInvoices, SUM(Amount__c) invoiceAmount
            FROM Invoice__c
            WHERE InvoiceBatch__r.BatchId__c IN :pendingBatchIdStrings
            GROUP BY InvoiceBatch__r.BatchId__c
            ORDER BY InvoiceBatch__r.BatchId__c DESC
        ];
        Map<String, AggregateResult> aggregateResultForBatch = new Map<String, AggregateResult>();
        for (AggregateResult ar : rows) {
            aggregateResultForBatch.put((String) ar.get('BatchId__c'), ar);
        }
        for (InvoiceBatch__c batch : pendingBatches) {
            AggregateResult ar = null;
            if (aggregateResultForBatch.containsKey(batch.BatchId__c)) {
                ar = aggregateResultForBatch.get(batch.BatchId__c);
            }
            if ('Ready To Send' == batch.Status__c && null == ar) {
                continue;
            }
            plist.add(new GW_InvoiceBatch.InvoiceBatchItem(ar, batch));
        }
        return plist;
    }
}