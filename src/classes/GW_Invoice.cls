global with sharing class GW_Invoice {

    private static Set<String> doNotUpdate = new Set<String>{'ECGDKAD'};
    private static final Schema.sObjectType GW_BASEOBJECT = Invoice__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'Invoice__c';

    public static DateTime todayDate = System.today();
    private static Map<String,Invoice__c> invoiceUIDmap = new Map<String,Invoice__c>();

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // public query methods
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Invoice__c           getRecord(Id id)           { return (Invoice__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,Invoice__c>   getMap(Set<id> ids)        { return new Map<id,Invoice__c>( getList(ids) ); }
    public static List<Invoice__c>     getList(Set<id> ids)       { return (List<Invoice__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // related methods use to retrieve a list of parents(base object) from a list of child objects
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // RS__c
    public static Map<id,Invoice__c>    getMapFromRelated(List<RS__c> lst)     { return getMap(getIdSetFromRelated(lst)); }
    public static Set<Id>               getIdSetFromRelated(List<RS__c> lst)   { return GW_sObject.getParentIds(lst, 'Invoice__c'); }

    //InvoiceLine__c
    public static Map<id,Invoice__c>    getMapFromRelated(List<InvoiceLine__c> lst)     { return getMap(getIdSetFromRelated(lst)); }
    public static Set<Id>               getIdSetFromRelated(List<InvoiceLine__c> lst)   { return GW_sObject.getParentIds(lst, 'Invoice__c'); }

    public static String processBatch(String memberUnit) {
        
        if(String.isBlank(memberUnit)) return null;
        List<MemberUnit__c> memberUnitList = GW_MemberUnit.getMemberUnitList(memberUnit);
        if(memberUnitList.isEmpty()) return null;
        
        //Return if Member Unit has Tract enabled
        MemberUnit__c mu = memberUnitList[0];
        if(mu.EnableTract__c) return null;
        
        // 1) create & insert new batch object
        InvoiceBatch__c invoicingBatch = GW_InvoiceBatch.createNewBatch(memberUnit);
        
        // 2) create all InvoiceLines from Rev/RS where Invoicing is required for the specific batch (for that MemberUnit)
        String invoiceGenBatchSizeStr = UTIL.getConfig('InvoiceGenBatchSize');
        Integer invoiceGenBatchSize = invoiceGenBatchSizeStr == null ? 50 : Integer.valueOf( invoiceGenBatchSizeStr );
        Id batchJobId = Database.executeBatch( new BAT_GenerateInvoiceBatch(invoicingBatch), invoiceGenBatchSize );
        return invoicingBatch.Id;
    }

    public static Boolean invoiceBatchCanBeCancelled(String invBatchId) {
        return [SELECT Id FROM InvoiceBatch__c
                WHERE BatchId__c = :invBatchId AND Status__c = 'Ready To Send' LIMIT 1].size() == 1;
    }

    public static void cancelInvoicingBatch(String invBatchId, String cancellationReason) {
        if(invBatchId == null) UTIL.throwError('Invoicing Batch ID not defined');
        if (false == invoiceBatchCanBeCancelled(invBatchId)) { UTIL.throwError('This batch cannot be cancelled'); }
        if(cancellationReason == null || cancellationReason == '') UTIL.throwError('CancellationReason is required');
        Id batchJobId = Database.executeBatch( new BAT_CancelInvoiceBatch(invBatchId, cancellationReason), 50 );
    }

    // Create invoicesLines from Rev/RS, simplified
    public static List<InvoiceLine__c> generateInvoiceLines(InvoiceBatch__c batch) {
        List<InvoiceLine__c> ils = new List<InvoiceLine__c>();
        Map<String, List<InvoiceLine__c>> newInvoiceLinesMap; // Map InvoiceUID => List<InvoiceLine__c>
        for(Rev__c rev : getInvoicingReadyRevItems(batch.MemberUnitId__c) ) {
            ils.add(GW_InvoiceLine.createInvoiceLineFromInvoicingItem(rev, batch));
        }
        for(RS__c rs : getInvoicingReadyRS(batch.MemberUnitId__c) ) {
            // create InvoiceLine
            ils.add( GW_InvoiceLine.createInvoiceLineFromInvoicingItem(rs, batch));
        }

        // Generate ID lines
        newInvoiceLinesMap = GW_InvoiceLine.returnMapInvoiceUIDInvoiceLines(ils);

        // loop through all InvUID's to add ID line if required
        for (String invUID : newInvoiceLinesMap.keySet() ) {
            List<InvoiceLine__c> ilsForInvoice = newInvoiceLinesMap.get(invUID);
            InvoiceLine__c defaultLine; // use for ID defaults
            Decimal indirectDiscountTotal = 0;

            for (InvoiceLine__c il : ilsForInvoice) {
                if (il.IndirectDiscountAmount__c != NULL && il.IndirectDiscountAmount__c != 0) indirectDiscountTotal += il.IndirectDiscountAmount__c;
            }
            if (indirectDiscountTotal > 0) {
                defaultLine = ilsForInvoice[0];
                ils.add(GW_InvoiceLine.createInvoiceLineForIndDiscount(indirectDiscountTotal, invUID, 'ID_'+invUID, defaultLine));
            }
        }
        return ils;
    }

    private static void cacheRelatedToRS(List<RS__c> rsList) {
        Set<Id> relatedObjectsIdSet = new Set<Id>();
        Set<Id> revIdSet = new Set<Id>();
        for(RS__c rs : rsList) {
            relatedObjectsIdSet.add(rs.Id);
            relatedObjectsIdSet.add(rs.Rev__c);
            revIdSet.add(rs.Rev__c);
        }
        List<Rev__c> relatedRevItems = (List<Rev__c>) GW_sObject.queryRecords('Rev__c',revIdSet);
        UTIL.cache(relatedRevItems); // cache here otherwise we query twice
        cacheRelatedToRevItems(relatedRevItems);
        UTIL.cacheUncachedRecords(relatedObjectsIdSet);
    }

    private static void cacheRelatedToRevItems(List<Rev__c> revList) {
        Set<Id> relatedObjectsIdSet = new Set<Id>();
        for(Rev__c rev : revList) {
            relatedObjectsIdSet.add(rev.Id);
            relatedObjectsIdSet.add(rev.Opportunity__c);
            relatedObjectsIdSet.add(rev.Product__c);
            relatedObjectsIdSet.add(rev.BillingAccountId__c);
        }
        UTIL.cacheUncachedRecords(relatedObjectsIdSet);
    }
    
    public static Invoice__c createInvoiceForInvoiceLine(InvoiceBatch__c batch, InvoiceLine__c il) {
        if (il==null) UTIL.throwerror('InvoiceLine is null');
        if (batch==null) UTIL.throwerror('Not a valid Invoice Batch');
        if (il.Rev__c == null && il.RS__c == null) UTIL.throwerror('Unlinked Invoiceline');
        
        Rev__c rev;
        RS__c rs;
        Opportunity opp;
        Date startDate, endDate;
        
        if (il.Rev__c == null) {
            rs = (RS__c) UTIL.getCached(il.RS__c);
            rev = (Rev__c) UTIL.getCached(rs.Rev__c);
            startDate = rs.From_Date__c;
            endDate = rs.Until_Date__c;
        } else {
            rev = (Rev__c) UTIL.getCached(il.Rev__c);
            startDate = rev.From_Date__c;
            endDate = rev.Until_Date__c;
        }
        opp = (Opportunity) UTIL.getCached(rev.Opportunity__c);
   
        Invoice__c inv = new Invoice__c();
        inv.InvoiceBatch__c = batch.Id;
        inv.BillingAccount__c = opp.Billing_Account__c;
        inv.CurrencyIsoCode = opp.CurrencyIsoCode;
        inv.UniqueKey__c = il.InvoiceUID__c;
        inv.InvoiceDescription__c = opp.Name;
        inv.StartDate__c = startDate;
        inv.EndDate__c = endDate;
        return inv;    
    }

    private static Invoice__c createInvoiceForUID(InvoiceBatch__c batch, String invoiceUID, Rev__c rev) {
        if (rev==null) UTIL.throwerror('Source object is null');
        Id oppId = (Id) rev.Opportunity__c; 
        if (oppId==null) UTIL.throwerror('Source object not linked to opportunity');
        if (batch==null) UTIL.throwerror('Not a valid Invoice Batch');
        Date startDate = rev.From_Date__c == NULL ? System.today() : rev.From_Date__c;
        Date endDate = rev.Until_Date__c == NULL ? System.today() : rev.Until_Date__c;

        Opportunity opp = (Opportunity) UTIL.getCached(oppId); 

        Invoice__c inv = new Invoice__c();
        inv.InvoiceBatch__c = batch.Id;
       
        inv.BillingAccount__c = opp.Billing_Account__c;
        inv.CurrencyIsoCode = opp.CurrencyIsoCode;
        inv.UniqueKey__c = invoiceUID;
        inv.InvoiceDescription__c = opp.Name;
        inv.StartDate__c = startDate;
        inv.EndDate__c = endDate;
        return inv;
    }
    private static Invoice__c createInvoiceForUID(InvoiceBatch__c batch, String invoiceUID, RS__c rs) {
        if (rs==null) UTIL.throwerror('Source object is null');
        Id oppId = rs.Opportunity__c;
        if (oppId==null) UTIL.throwerror('Source object not linked to opportunity');
        if (batch==null) UTIL.throwerror('Not a valid Invoice Batch');
        Date startDate = rs.From_Date__c == NULL ? System.today() : rs.From_Date__c;
        Date endDate = rs.Until_Date__c == NULL ? System.today() : rs.Until_Date__c;

        Opportunity opp = (Opportunity) UTIL.getCached(rs.Opportunity__c);

        Invoice__c inv = new Invoice__c();
        inv.InvoiceBatch__c = batch.Id;
        //UTIL.log(requestor);
        inv.BillingAccount__c = opp.Billing_Account__c;
        inv.CurrencyIsoCode = opp.CurrencyIsoCode;
        inv.UniqueKey__c = invoiceUID;
        inv.InvoiceDescription__c = opp.Name;
        inv.StartDate__c = startDate;
        inv.EndDate__c = endDate;
        return inv;
    }

    public static Set<Id> getInvoicesPartOfBatchForUpdate(List<String> batchIds) {
        Set<Id> result = new Set<Id>();

        if (batchIds.size() == 0) {
            return result;
        }
        List<Invoice__c> invoices = [ SELECT Id FROM Invoice__c WHERE BillingAccount__r.Member_Id__c NOT IN :doNotUpdate AND InvoiceBatch__r.BatchId__c IN :batchIds FOR UPDATE ];

        for (Invoice__c invoice : invoices) {
            result.add(invoice.Id);
        }
        return result;
    }

    public static Set<Id> getInvoicesPartOfBatchForUpdate(String batchId) {
        Set<Id> result = new Set<Id>();

        if (null == batchId) {
            return result;
        }
        List<Invoice__c> invoices = [ SELECT Id FROM Invoice__c WHERE BillingAccount__r.Member_Id__c NOT IN :doNotUpdate AND InvoiceBatch__r.BatchId__c = :batchId FOR UPDATE ];

        for (Invoice__c invoice : invoices) {
            result.add(invoice.Id);
        }
        return result;
    }

    public static void markForSyncToBilling(Set<Id> invIds) {
        List<Invoice__c> invRequested = GW_Invoice.getList(invIds);
        List<Invoice__c> invToBeUpdated = new List<Invoice__c>();

        for(Invoice__c inv : invRequested) {
            if (inv.NumStatus__c==6 && !inv.FQ_SyncPending__c && !inv.OutOfSync__c)
                invToBeUpdated.add(new Invoice__c(Id=inv.Id,FQ_SyncPending__c=TRUE));
            else {
                UTIL.throwError('All selected invoices should be in sync and "Ready for Invoicing".');
            }
        }

        if(containsCancelledBatches(invToBeUpdated)) {
            UTIL.throwError('Provided invoices are in cancelled batch and cannot be marked for sync to billing');
        }

        if (!invToBeUpdated.isEmpty()) {
            Savepoint sp = Database.setSavepoint();
            try {
                update invToBeUpdated;
            } catch(Exception ex) {
                Database.rollback(sp);
                UTIL.throwError('Unknown error marking Invoices for sync to Billing: ',ex);
            }
        }
    }

    private static Boolean containsCancelledBatches(List<Invoice__c> invList) {
        if(invList == NULL || invList.size() == 0)
            return FALSE;

        Set<String> batchIdSet = new Set<String>();
        for(Invoice__c inv : invList) {
            batchIdSet.add(inv.InvoiceBatch__r.BatchId__c);
        }

        List<InvoiceBatch__c> invBatchLogList = (List<InvoiceBatch__c>) GW_sObject.queryRecords('InvoiceBatch__c','BatchId__c',batchIdSet);
        for(InvoiceBatch__c invLog : invBatchLogList) {
            if(invLog.CancellationReason__c != NULL) {
                return TRUE;
            }
        }
        return FALSE;
    }
        public static List<RS__c> getPGCInvoicingReadyRS( String memberUnitId ) {
        return [Select Id,
                UnitPrice__c,
                Rev__c,
                Revenue__c,
                Rev__r.UPCF__c,
                Rev__r.Product__r.ProductCode,
                Rev__r.Product__r.Product_Type__c,
                Rev__r.Product__r.Product_SubType__c,
                QuantityBilled__c,
                IndirectDiscountAmount__c,
                InvoiceLineDescription__c,
                UniqueKey__c,
                From_Date__c,
                Until_Date__c,
                Opportunity__c, 
                Opportunity__r.Billing_Account__c,
                Opportunity__r.Billing_Account__r.VAT__c,
                Opportunity__r.CurrencyIsoCode, 
                Opportunity__r.Name,
                Opportunity__r.LineOfBusiness__c,
                InvUidCalc__c, 
                RevenueInvoiced__c, 
                InvoicingBalance__c 
                FROM RS__c 
                WHERE InvoicingStatus__c = 'Invoicing Required'
                AND Opportunity__r.MemberUnit__c = :memberUnitId 
               ];
    }
    public static List<Rev__c> getPGCInvoicingReadyRevItems( String memberUnitId ) {
        List<Rev__c> revs = [Select Id, 
                Opportunity__c,
                UnitPrice__c,
                Revenue__c,
                UPCF__c,
                Product__r.ProductCode,
                Product__r.Product_Type__c,
                Product__r.Product_SubType__c,
                Description__c,
                QuantityBilled__c,
                IndirectDiscountAmount__c,
                From_Date__c,
                Until_Date__c,
                Opportunity__r.Billing_Account__c,
                Opportunity__r.Billing_Account__r.VAT__c,
                Opportunity__r.CurrencyIsoCode, 
                Opportunity__r.Name, 
                Opportunity__r.LineOfBusiness__c,
                InvUidCalc__c 
                FROM Rev__c 
                WHERE InvoicingStatus__c = 'Invoicing Required' 
                AND Opportunity__r.MemberUnit__c = :memberUnitId
               ];
        UTIL.cache(revs);
        return revs;
    }
    
    public static List<RS__c> getInvoicingReadyRS(String memberUnitId) {
        String whereClause = 'InvoicingStatus__c = \'Invoicing Required\' AND MemberUnitId__c = \''+memberUnitId+ '\'';
        List<RS__c> rss = GW_sObject.queryRecords('RS__c',whereClause);
        UTIL.cache(rss);
        cacheRelatedToRS(rss);
        return rss;
    }
    public static List<Rev__c> getInvoicingReadyRevItems(String memberUnitId) {
        String whereClause = 'InvoicingStatus__c = \'Invoicing Required\' AND MemberUnitId__c = \''+memberUnitId+ '\'';
        List<Rev__c> revs = GW_sObject.queryRecords('Rev__c',whereClause);
        UTIL.cache(revs);
        cacheRelatedToRevItems(revs);
        return revs;
    }

    // BILLING SYSTEM INVOICE NUMBER
    public static void setBillingSystemInvoiceNumberinLines( Invoice__c oldInv , Invoice__c newInv ) {

        if( oldInv.BillingSystemInvoiceNumber__c != newInv.BillingSystemInvoiceNumber__c ){
            List<InvoiceLine__c> invLines = (List<InvoiceLine__c>) GW_sObject.getChildren( newInv.Id , 'InvoiceLines__r' );
            for( InvoiceLine__c invLine : invLines ){
                invLine.ParentBillingSystemInvoiceNumber__c = newInv.BillingSystemInvoiceNumber__c;
            }
            update invLines;
        }
    }

    // STATUS CALCULATOR

    public static void checkStatusChangeAndUpdate(List<Invoice__c> invoiceList) {
        if(invoiceList == null || invoiceList.isEmpty()) return;

        List<Invoice__c> invListToUpdate = new List<Invoice__c>();
        for (Invoice__c inv : invoiceList) {
            if (GW_Invoice.setStatus(inv) ) { invListToUpdate.add(inv); }
        }

        try {
            update invoiceList;
        } catch(Exception ex) {
            UTIL.throwError('GW_Invoice.checkStatusChangeAndUpdate(): Error updating invoices: ',ex);
        }
    }

    public static Boolean setStatus(Invoice__c inv) {
        StatusCalculator statusCalc = new StatusCalculator(inv);
        return statusCalc.setStatus(inv);
    }

    public class StatusCalculator extends StatusCalculator.AbstractStatusCalculator {
        // constructor
        public StatusCalculator(Invoice__c inv) {
            super(inv, new Map<Integer, String>{-1 => 'Cancelled', 0 => 'Draft', 6 => 'Ready for Invoicing', 7 => 'Sent to Billing', 8 => 'Overdue', 9 => 'Paid'});}

        public override Boolean passCriteria(sObject so, Integer stage) {
            Invoice__c inv = (Invoice__c) so;
            if (stage==-1) return true; //Not Invoiced
            if (stage==0) { if (!inv.Cancelled__c) return true; }// Draft is default 0
            if (stage==6) { if (inv.MinInvLineStatus__c>5 || inv.FQ_InvoiceID__c != NULL) return true; } // Ready for Invoicing 6
            if (stage==7) { if (inv.MinInvLineStatus__c>6 || inv.FQ_InvoiceID__c != NULL) return true; } // sent to Billing
            if (stage==8) { if (inv.FQ_Due_Date__c < system.today() || inv.FQ_InvoiceStatus__c == 'Paid' ) return true; } // Overdue
            if (stage==9) { if (inv.FQ_InvoiceStatus__c == 'Paid') return true; } // Paid
            return false;
        }
    }

    // WEBSERVICES
    webservice static String processInvoices(String selIds){
        return 'Please use the invoicing page instead...';
    }
}