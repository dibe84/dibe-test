global class BAT_BookingPushTract implements Database.Batchable<sObject>, UTIL_CustomJob.ICustomJob, Database.Stateful, Database.AllowsCallouts {
    global Datetime executeStart;
    public String queryString;
    public Boolean useForUpdate;
    public Opportunity[] listBookingPush = new List<Opportunity>();
    public Opportunity[] listBookingPushNext = new List<Opportunity>();
    public Integer todostep = 0;
    public String contextInvocation;
    public Map<String, String> mapOrderCusFieldId = null;
    public Map<String, String> mapOrderCusFieldValId = null;

    public BAT_BookingPushTract() {
        contextInvocation = 'UTIL_CustomJob';
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_BookingPushTract');
        this.queryString = UTIL_CustomJob.getWhereQuery(jobDef);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'Opportunity'));
        if (this.numRecords>0) readyForRun = true;
        todostep = 0;
    }
     
    public BAT_BookingPushTract(Opportunity[] opps, Integer currentStep) {
        listBookingPushNext = new List<Opportunity>();
        listBookingPush = opps;
        todostep = currentStep;
    }
    
    public List<Opportunity> start(Database.BatchableContext BC) {
        if (!listBookingPush.isEmpty()) {
            //Refresh list for next step
            listBookingPush = GW_Opportunity.getList(new Map<Id, Opportunity>(listBookingPush).keySet());
            return listBookingPush;
        }
        // Process by scheduled job
        return GW_sObject.queryRecords('Opportunity', this.queryString);
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        try {
            listBookingPushNext = GW_Opportunity.sendBookingPush(scope, todostep, mapOrderCusFieldId, mapOrderCusFieldValId);
        } catch(Exception ex) {
            UTIL.throwError('BAT_BookingPushTract: Error Booking Push', ex);
        }
    }

    public void finish(Database.BatchableContext BC) {
        //Init Map custom field for Tract campaign 
        if (mapOrderCusFieldId == null && todostep == 0) mapOrderCusFieldId = GW_Opportunity.getMapOrderCusFieldId(listBookingPushNext[0]);
        
        //Value Id could be new one at step 8
        if (mapOrderCusFieldValId == null && todostep == 8) mapOrderCusFieldValId = GW_Opportunity.getMapOrderCusFieldValId(listBookingPushNext[0]);
            
        todostep++;
        if (todostep < GW_Opportunity.STEPS_BOOKING_PUSH.size() && !listBookingPushNext.isEmpty()) {
            GW_Opportunity.callBookingPush(listBookingPushNext, todostep, contextInvocation, mapOrderCusFieldId, mapOrderCusFieldValId);
            return;
        }

        // Process by scheduled job
        if (contextInvocation == 'UTIL_CustomJob') {
            UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
            UTIL_CustomJob.markJobFinished('BAT_BookingPushTract', BC.getJobId());
        }
    }

    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}