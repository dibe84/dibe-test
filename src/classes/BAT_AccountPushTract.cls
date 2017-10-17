global class BAT_AccountPushTract implements Database.Batchable<sObject>, UTIL_CustomJob.ICustomJob, Database.Stateful, Database.AllowsCallouts {
    global Datetime executeStart;
    public String queryString;
    public Boolean useForUpdate;
    public Account[] listPush = new List<Account>();
    public Map<Id, Account> oldTriggerMap = new Map<Id, Account>();
    public Account[] listPushNext = new List<Account>();
    public Integer todostep = 0;
    public String contextInvocation;
    
    public BAT_AccountPushTract() {
        contextInvocation = 'UTIL_CustomJob';
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_AccountPushTract');
        this.queryString = UTIL_CustomJob.getWhereQuery(jobDef);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'Account'));
        if (this.numRecords>0) readyForRun = true;
        todostep = 0;
    }
     
    public BAT_AccountPushTract(Account[] accs, Map<Id, Account> oldMap, Integer currentStep) {
        listPushNext = new List<Account>();
        listPush = accs;
        oldTriggerMap = oldMap;
        todostep = currentStep;
    }
    
    public List<Account> start(Database.BatchableContext BC) {
        if (!listPush.isEmpty()) {
            //Refresh list for next step
            listPush = GW_Account.getList(new Map<Id, Account>(listPush).keySet());
            return listPush;
        }
        // Process by scheduled job
        return GW_sObject.queryRecords('Account', this.queryString);
    }

    public void execute(Database.BatchableContext BC, List<Account> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        try {
            listPushNext = GW_Account.sendAccountPush(scope, oldTriggerMap, todostep);
        } catch(Exception ex) {
            UTIL.throwError('BAT_AccountPushTract: Error Booking Push', ex);
        }
    }

    public void finish(Database.BatchableContext BC) {
        todostep++;
        if (todostep < GW_Account.STEPS_ACCOUNT_PUSH.size() && !listPushNext.isEmpty()) {
            GW_Account.callAccountPush(listPushNext, oldTriggerMap, todostep, contextInvocation);
            return;
        } 
        // Process by scheduled job
        if (contextInvocation == 'UTIL_CustomJob') {
	        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
	        UTIL_CustomJob.markJobFinished('BAT_AccountPushTract', BC.getJobId());
        }
    }

    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}