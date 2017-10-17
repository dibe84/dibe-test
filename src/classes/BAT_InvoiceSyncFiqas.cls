global class BAT_InvoiceSyncFiqas implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {
    global Datetime executeStart;
    String queryString;
    Set<Id> invoicesInput;
    List<InvoiceLine__c> lines;

    global BAT_InvoiceSyncFiqas() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_InvoiceSyncFiqas');
        this.queryString = UTIL_CustomJob.getWhereQuery(jobDef);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'Invoice__c'));
        if (this.numRecords>0) readyForRun = true;
    }

    global List<InvoiceLine__c> start(Database.BatchableContext BC) {
        List<Invoice__c> invoices = GW_sObject.queryRecords('Invoice__c', this.queryString);
        return (List<InvoiceLine__c>) GW_sObject.getChildren(GW_sObject.getIdSet(invoices), 'InvoiceLines__r');
    }

    global void execute(Database.BatchableContext BC, List<InvoiceLine__c> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();

		//Cache all related records including invoices
		GW_InvoiceLine.cacheRelatedRecords(scope);

		//FIQAS Invoices and Lines to update.
		List<InvoiceLine__c> linesToUpdate = new List<InvoiceLine__c>();
        List<Invoice__c> invsToUpdate = new List<Invoice__c>();

		//Collect ids of invoices needed to be created using the invoicing API
		Set<Id> invIdsToCreateUsingInvoiceAPI = new Set<Id>();

        for (InvoiceLine__c il : scope) {
            // do not sync lines that already have been synced.
			//Will be set for both FIQAS lines and Invoice API lines.
			if (il.FQ_SyncStatus__c == 'OK' || il.Previously_Sent_To_Billing__c ) continue;

            if (isCorruptedInvoiceLine(il)) {
                UTIL.log('Skipping CORRUPT invoice line: ' + il);
                continue;
            }

			//Get invoice from cache to ask if it is a FIQAS or Invoice API invoice.
			Invoice__c inv = (Invoice__c) UTIL.getCached(il.Invoice__c);

			if (UTIL_WSC_Subscription.isSubscribedToWS(il.MemberUnitId__c, 'WSC_API_SFECG_v1', 'InvoicePush')){
				invIdsToCreateUsingInvoiceAPI.add(inv.Id);
			}
			else {
				InvoiceLine__c updInvLine = new InvoiceLine__c(id=il.Id,Invoice__c=il.Invoice__c);
	            UTIL_Fieldmapper fm = WSC_Fiqas.getFiqasInvoiceInput(il);

	            if (il.NumStatus__c != 6 || inv.OutOfSync__c) {
	                updInvLine.FQ_SyncStatus__c = 'FAILED';
	                updInvLine.FQ_SyncReason__c = 'Invoice Line not ready for Invoicing';
	                updInvLine.FQ_SyncTimestamp__c = Datetime.now();
	            } else if( fm != null && !fm.mandatoryFieldsNotNull() ) { // some info missing
	                String errorMsg = 'Missing: ';
	                for (String s : fm.mappingErrors) errorMsg += ' \n' + s;
	                updInvLine.FQ_SyncStatus__c = 'FAILED - Missing fields for sync to Billing';
	                updInvLine.FQ_SyncReason__c = errorMsg;
	                updInvLine.FQ_SyncTimestamp__c = Datetime.now();
	            } else {
	                // ready for Sync
	                WSC_Fiqas.FiqasResponse fr = WSC_Fiqas.invoiceLineInsert(il);

	                if (fr != null) {
	                    WSC_Fiqas.FiqasResponseElement fre = fr.getFirstElement();
	                    updInvLine.FQ_SyncStatus__c = fre.status;
	                    updInvLine.FQ_SyncReason__c = fre.reason;
	                    updInvLine.FQ_SyncTimestamp__c = fr.timestamp;
	                }
	            }
	            linesToUpdate.add(updInvLine);
			}
        }

        // gather invoices to reset the sync Mark for FIQAS invoices.
        Set<Id> invIds = GW_sObject.getParentIds(linesToUpdate, 'Invoice__c');

        for (Id invId : invIds) 					   { invsToUpdate.add(new Invoice__c(Id=invId, FQ_SyncPending__c=FALSE) );}
		for (Id invId : invIdsToCreateUsingInvoiceAPI) { invsToUpdate.add(new Invoice__c(Id=invId, FQ_SyncPending__c=FALSE, ScheduledCalloutPending__c=TRUE)); }

        Savepoint sp = Database.setSavepoint();
        try {
            UTIL.log('Fiqas linesToUpdate: '+linesToUpdate);
            UTIL.log('invsToUpdate: '+invsToUpdate);
            update linesToUpdate;
            update invsToUpdate;

			//Schedule invoicing API callouts for API enabled invoices.
			UTIL_WSC.checkForProcessing('WSC_API_SFECG_v1.InvoicePush', invIdsToCreateUsingInvoiceAPI);
        } catch(Exception ex) {
            Database.rollback(sp);
            UTIL.throwError('BAT_InvoiceSyncFiqas - Error updating Invoices/InvoiceLines with Fiqas Status',ex);
        }
    }

    private Boolean isCorruptedInvoiceLine(InvoiceLine__c il) {
        return null == il.Rev__c && null == il.RS__c && (String.isEmpty(il.UniqueKey__c) || !il.UniqueKey__c.startsWith('ID_'));
    }

    global void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_InvoiceSyncFiqas', BC.getJobId());
    }

	// interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
}