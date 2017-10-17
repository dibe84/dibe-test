/**
 * Execute to call DART6BatchDeliverySupport
 */
global class DART6SchReportRequestWatcher implements Schedulable{
    public final static Integer NEXT_EXEC_TIME_IN_SECONDS = 120; // minimum 2 mins
    private String ddsId;
    private String importType;
    /**
     * 
     */
    public DART6SchReportRequestWatcher(String ddsId){
        this.ddsId = ddsId;
    } 
    
     public DART6SchReportRequestWatcher(String ddsId, String importType){
        this.ddsId = ddsId;
        this.importType = importType;
    }
    
    public String createCronExpForNextFireTime(){
        DateTime now = System.now().addSeconds(NEXT_EXEC_TIME_IN_SECONDS);
        return now.second() + ' ' 
            + now.minute() + ' ' 
            + now.hour() + ' '
            + now.day() + ' '
            + now.month() + ' ? ' 
            + now.year();
    }
    
    global void execute(SchedulableContext sc) {
    	try{
	        DART6BatchDeliverySupport batchSupport = new DART6BatchDeliverySupport(ddsId, DART6BatchDeliverySupport.CALL_TYPE_CHECK_REPORT_STATUS, importType);
	        if(sc != null) batchSupport.jobId = sc.getTriggerID();
	        ID batchprocessid = Database.executeBatch(batchSupport);
        }catch(Exception e){
    		DART_Delivery_Support__c dds = DeliveryController.getDeliverySupportRecord(ddsId);
			dds.DART_Status__c = DeliveryController.REPORT_QUERY_FAILED;
			dds.Status__c = DeliveryController.DART_STATUS_FINISHED;
			update dds;
			DARTLogger.getInstance().log(dds.Id,new List<DARTLogger.LogMessage>{new DARTLogger.LogMessage(
								dds.Id , DART6BatchDeliverySupport.CALL_TYPE_CHECK_REPORT_STATUS,
							    'DART6SchReportRequestWatcher.execute', dds.AdServer_Login__r.RecordType.name, e)});
			DeliveryController.startNextAdServer(dds.Sobject__c, dds.Schedule_Type__c, importType);
			if(sc.getTriggerID() != null ) System.abortJob(sc.getTriggerID());
		}
    }
}