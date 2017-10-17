global class BAT_SyncFinanceRequestFromTRACT implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {

    private String queryString;
    private String whereClause;
    global Datetime executeStart;

    global BAT_SyncFinanceRequestFromTRACT() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_SyncFinanceRequestFromTRACT');
        this.queryString = UTIL_CustomJob.getWhereQuery(jobDef);
        this.numRecords = Database.countQuery( UTIL_CustomJob.getCountQuery( jobDef , 'Finance_Request__c') );
        if (this.numRecords>0) readyForRun = true;
    }

    global List<Finance_Request__c> start(Database.BatchableContext BC) {
        return GW_sObject.queryRecords('Finance_Request__c', this.queryString);
    }

    global void execute(Database.BatchableContext BC, List<Finance_Request__c> scope) {
        
        System.debug('Starting the Sync of Finance Requests');
        
        if(this.executeStart == null) this.executeStart = Datetime.now();

        List<Finance_Request__c> updateReqs = new List<Finance_Request__c>(); 

        try {
            
            for( Finance_Request__c finReq : scope ){

                System.debug('RECORD ' + finReq.Id );
                
                if( finReq.TRACT_Reverse_Invoice_Id__c == null ){
                
                    System.debug('Callling the Create Reverse Invoice method in the TRACT API...');
                    String reverseInvoiceId = createTRACTReverseInvoice( finReq );
                    if( reverseInvoiceId != null ){
                        finReq.TRACT_Reverse_Invoice_Id__c = reverseInvoiceId;
                        updateReqs.add( finReq ); 
                    }
                    
                } else if( finReq.isReverseInvoiceProcessed__c ) {

                    System.debug('Callling the Create Bill Batch Reissue method in the TRACT API...');
                    String reissueBillBatchId = createTRACTReissueBillBatch( finReq );
                    if( reissueBillBatchId != null ){
                        finReq.TRACT_Reissue_Bill_Batch_Id__c = reissueBillBatchId;
                        updateReqs.add( finReq );
                    }
                    
                } else {
                    
                    System.debug('Callling the Get Reverse Invoice method in the TRACT API to check if the reverse invoice was processed.');
                    if( isReverseInvoiceReady( finReq ) ){
                        finReq.isReverseInvoiceProcessed__c = true;                     
                        updateReqs.add( finReq );   
                    }
                }   
            }
            
            if( updateReqs.size() > 0 ){
                update updateReqs;
            }

        } catch(Exception ex) {
            UTIL.throwError('BAT_SyncFinanceRequestFromTRACT - Error...',ex);
        }
    }

    private String createTRACTReverseInvoice( Finance_Request__c finReq ){
        
        String reverseInvoiceId = null;
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        req = UTIL_WSC.getWSC_Request('WSC_Tract.CreateReverseInvoice');
        req.init( finReq.Id );
        res = req.call();
        
        if (res.statusCode == 200 || res.statusCode == 201) {
            Map<String, Object> reverseInvoice = ( Map<String, Object> ) res.getResponseData().get('results');
            System.debug( reverseInvoice );
            if( reverseInvoice != null ){
                reverseInvoiceId = (String) reverseInvoice.get('id');
            }
        } else{
            UTIL.log('Callout error while querying the TRACT Ghost Account. Status code: ' + res.statusCode);
        }
        
        return reverseInvoiceId;
    }
    
    private Boolean isReverseInvoiceReady( Finance_Request__c finReq ){
        
        Boolean isReady = false;
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        req = UTIL_WSC.getWSC_Request('WSC_Tract.GetReverseInvoice');
        req.init( finReq.Id );
        res = req.call();
        
        if (res.statusCode == 200 || res.statusCode == 201) {
            Map<String, Object> reverseInvoice = (Map<String, Object>) res.getResponseData().get('results');
            if( reverseInvoice != null ){
                List<Object> batchRuns = ( List<Object> )reverseInvoice.get('bill_batch_runs');
                if( batchRuns.size() > 0 ){
                    Map<String,Object> batchRun = (Map<String,Object>) batchRuns.get(0);
                    String step = (String) batchRun.get('step');
                    String stepStatus = (String) batchRun.get('step_status');
                    isReady = 'APPROVAL'.equals( step ) && 'COMPLETED'.equals( stepStatus );
                }
            }
        }
        
        return isReady;
    }

    private String createTRACTReissueBillBatch( Finance_Request__c finReq ){
        
        String reverseInvoiceId = null;
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        req = UTIL_WSC.getWSC_Request('WSC_Tract.CreateReissueBillBatch');
        req.init( finReq.Id );
        res = req.call();
        
        if (res.statusCode == 200 || res.statusCode == 201) {
            Map<String, Object> reverseInvoice = ( Map<String, Object> ) res.getResponseData().get('results');
            if( reverseInvoice != null ){
                reverseInvoiceId = (String) reverseInvoice.get('id');
            }
        } else{
            UTIL.log('Callout error while querying the TRACT Ghost Account. Status code: ' + res.statusCode);
        }
        
        return reverseInvoiceId;
    }

    global void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_SyncFinanceRequestFromTRACT', BC.getJobId());
    }
    
    // interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
}