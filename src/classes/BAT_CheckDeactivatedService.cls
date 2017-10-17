global class BAT_CheckDeactivatedService implements Database.Batchable<sObject>, UTIL_CustomJob.ICustomJob, Database.Stateful, Database.AllowsCallouts {
    global Datetime executeStart;
    public String queryString;
    public Boolean useForUpdate;

    public Map<String,String> tractCusFieldIds;
    public Map<String,String> tractCusFieldValIds;
    public List<TRACT_Service__c> services = new List<TRACT_Service__c>();
    public Integer currentStep;
    public String contextInvocation;

    public BAT_CheckDeactivatedService() {
        contextInvocation = 'UTIL_CustomJob';
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_CheckDeactivatedService');
        this.queryString = UTIL_CustomJob.getWhereQuery(jobDef);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'TRACT_Service__c'));
        if (this.numRecords>0) readyForRun = true;
        currentStep = 0;
    }
     
    public BAT_CheckDeactivatedService(List<TRACT_Service__c> services, Map<String,String> tractCusFieldIds, Map<String,String> tractCusFieldValIds, Integer currentStep) {
        this.tractCusFieldIds = tractCusFieldIds;
        this.tractCusFieldValIds = tractCusFieldValIds;
        this.services = services;
        this.currentStep = currentStep;
    }
    
    public List<TRACT_Service__c> start(Database.BatchableContext BC) {
        if (!services.isEmpty()) {
            //Refresh list for next step
            services = GW_TractService.getList(new Map<Id, TRACT_Service__c>(services).keySet());
            return services;
        }
        // Process by scheduled job
        return GW_sObject.queryRecords('TRACT_Service__c', this.queryString);
    }

    public void execute(Database.BatchableContext BC, List<TRACT_Service__c> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        try {
            GW_TractService.cacheServicesDetails(scope);
            Opportunity opp = (Opportunity) UTIL.getCached(scope[0].Opportunity__c);
            Account acc = (Account) UTIL.getCached(scope[0].Billing_Account__c);
            if (tractCusFieldIds == null && currentStep == 0) {
                tractCusFieldIds = (Map<String, String>) WSC_Tract.getTractServiceCustomFieldId(opp.Id).content;
            }
            if (currentStep == 1) {
                if (tractCusFieldValIds == null) tractCusFieldValIds = new Map<String, String>(); 
                tractCusFieldValIds.put(scope[0].Id, String.valueOf(WSC_Tract.getFieldValIdFromTractServiceId(acc.Id, scope[0].External_Id__c, GW_TractService.CUS_FIELD_TERMINATION_REASON).content));
            }
            
            if (tractCusFieldIds != null && tractCusFieldValIds != null) {
                GW_TractService.deactivateService(scope[0], tractCusFieldIds.get(GW_TractService.CUS_FIELD_TERMINATION_REASON), tractCusFieldValIds.get(scope[0].Id), currentStep);
            }
        } catch(Exception ex) {
            UTIL.throwError('BAT_CheckDeactivatedService: Error Deactivated Service ', ex);
        }
    }

    public void finish(Database.BatchableContext BC) {
        currentStep++;
        //Go next step
        if (currentStep < GW_TractService.STEPS_DEACTIVATE_SERVICE.size() && !Test.isRunningTest()) {
            GW_TractService.deactivateServices(services, tractCusFieldIds, tractCusFieldValIds, currentStep);
            return;
        }

        // Process by scheduled job
        if (contextInvocation == 'UTIL_CustomJob') {
            UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
            UTIL_CustomJob.markJobFinished('BAT_CheckDeactivatedService', BC.getJobId());
        }
    }

    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    public Boolean readyForRun() { return this.readyForRun; }
    public integer getNumRecords() { return this.numRecords; }
}