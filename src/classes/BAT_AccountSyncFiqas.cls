global class BAT_AccountSyncFiqas implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {
    global Datetime executeStart;

    String queryString;
    List<Account> accsInput;

    global BAT_AccountSyncFiqas() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_AccountSyncFiqas');
        this.queryString = UTIL_CustomJob.getWhereQuery(jobDef);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef, 'Account'));
        if (this.numRecords>0) readyForRun = true;
    }

    global BAT_AccountSyncFiqas(List<Account> accs) {
        this.accsInput = accs;
    }

    global List<Account> start(Database.BatchableContext BC) {
        if (accsInput == null){
        	List<Account> accs = GW_sObject.queryRecords('Account', this.queryString);
        	return accs;
        }
        else{
            return accsInput;
        }
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        List<Account> accsToUpdate = new List<Account>();

        for (Account acc : scope) {
            if (!UTIL_WSC_Subscription.isSubscribedToWS(acc.Member_Id__c, 'WSC_Fiqas', 'SyncAccount')) {
                continue;
            }
            Account updAcc = new Account(id=acc.Id);

            UTIL_Fieldmapper fm = WSC_Fiqas.getFiqasAccountInput(acc);
            if ( fm != null && !fm.mandatoryFieldsNotNull() ) { // some info missing
                String errorMsg = 'Missing: ';
                for (String s : fm.mappingErrors) errorMsg += ' \n'+s;
                updAcc.FQ_SyncStatus__c = 'FAILED - Missing fields for sync to Billing';
                updAcc.FQ_SyncReason__c = errorMsg;
                updAcc.FQ_SyncTimestamp__c = Datetime.now();
                updAcc.FQ_syncAccountDetails__c = false;
            } else {
                // ready for Sync
                WSC_Fiqas.FiqasResponse fr = WSC_Fiqas.customerUpsert(acc);

                if (fr != null) {
                    WSC_Fiqas.FiqasResponseElement fre = fr.getFirstElement();
                    updAcc.FQ_SyncStatus__c = fre.status;
                    updAcc.FQ_SyncReason__c = fre.reason;
                    updAcc.FQ_SyncTimestamp__c = fr.timestamp;
                    updAcc.FQ_syncAccountDetails__c = false;
                    if ('OK'.equals(fre.status)){
                       updAcc.FQ_syncMandateInfo__c = false;
                       updAcc.FQ_syncPaymentMethod__c = false;
                       updAcc.FQ_syncCmrLink__c = false;
                    }
                }
            }
            accsToUpdate.add(updAcc);
            WSC_Fiqas.accIdsSynced.add(acc.Id);
        }

        try {
            update accsToUpdate;
        } catch(Exception ex) {
            UTIL.throwError('BAT_AccountSyncFiqas - Error updating Accounts with Fiqas Status',ex);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_AccountSyncFiqas', BC.getJobId());
    }

	// interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
}