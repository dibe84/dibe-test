/**
 * @Created: Sochanra(Chr) - 17-11-2015
 * @Desc: Contain biz logic import delivery for metric from custom botton on RevenueItem related list
 * @Change logs:
 *		- Bunhor	@20-Jan-15		https://gaeasys.plan.io/issues/8514	 	update Status if the user close tab or window (AJAX calls cancellDDS webservice), Comment out calling pollReportRequest and pollReportStatus, and modify polling inverals.		
 */ 
global with sharing class DFPManuallyImportDeliveryController {
	
	/**
	 * Update Status if the user close tab or window (AJAX calls cancellDDS webservice)
	 */
	webservice static void cancellDDS() {
		DART_Delivery_Support__c[] lstDDS = [select id from DART_Delivery_Support__c where 	Schedule_Type__c = :DeliveryController.SCH_TYPE_MANUALLYPOLLING and 
																							DART_Status__c = :DeliveryController.REPORT_QUERY_INPROGRESS];
		for (DART_Delivery_Support__c dd : lstDDS) {
			dd.DART_Status__c = DeliveryController.REPORT_QUERY_CANCELLED; 
			dd.Status__c = DeliveryController.DART_STATUS_FINISHED;
		} 
		update lstDDS;
	}
	
	 
	public String parId {get; set;}
    public Boolean isError {get; set;}
    private String recIds;
	private final String KEY_SEP = '_';
	private String query;
	private Map<String, List<String>> mLoginSobjIds = new Map<String, List<String>>();//Country+DartVersion => {sobjId}
    private Map<String, List<String>> mDartVersionCountry = new Map<String, List<String>>();// DartVersion => {Country}
    private Map<String, String> mAdId = new Map<String, String>(); //Id => AdId;
    private Map<String, AdServer_Login__c> mAdLogin = new Map<String, AdServer_Login__c>();//Country+DartVersion => login
    private Map<String, DART_Delivery_Support__c> mDDSupport = new Map<String, DART_Delivery_Support__c>();//Country+DartVersion => DDSupport
    private final String devSupDetail='Import from RevenueItem related list button by '+ UserInfo.getName();
    
	//Check after each polling dartVersion => {countries}
    private Map<String, Set<String>> waitingDartVersionCountry = new Map<String, Set<String>>(); // requested list
    private Map<String, Set<String>> completeDartVersionCountry = new Map<String, Set<String>>();
	
	public DFPManuallyImportDeliveryController(){
        parId = Encodingutil.urlDecode(ApexPages.currentPage().getParameters().get('parId'), 'UTF-8');
        recIds = Encodingutil.urlDecode(ApexPages.currentPage().getParameters().get('recIds'), 'UTF-8');
        query = DeliveryController.mGeneralQuery.get(DeliveryController.SOBJECT_METRIC).replace('%DATECRIT%', '');
        isError = false;
	}
	
	
	/**
    * Mapping all DartVersion, Country, AdId for product
    */
    public PageReference checkProductListServers(){
        try{
        	List<String> revItemIds = recIds != '' ? recIds.split(',') : new List<String>();
            Set<String> dartVersions = new Set<String>();
            Set<String> sCountry = new Set<String>();
            Date minDate;
            Date maxDate;
            // For select metric reports
            	List<Metric__c> lstMetric = !revItemIds.isEmpty() 
                ? [Select Rs__r.Rev__r.ExtLineItemId__c, Rs__r.Rev__r.ExtOrderId__c, AD_Clicks__c, AD_Impressions__c, AD_OSI__c, MetricDate__c, Rs__r.Rev__r.Product__r.Site__r.Country__c, Rs__r.Rev__r.Product__r.RecordType.Name From Metric__c Where Rs__r.Rev__r.Id IN: revItemIds And Rs__r.Rev__r.Product__r.RecordType.Name =: DARTUtil.DART6]
                : [Select Rs__r.Rev__r.ExtLineItemId__c, Rs__r.Rev__r.ExtOrderId__c, AD_Clicks__c, AD_Impressions__c, AD_OSI__c, MetricDate__c, Rs__r.Rev__r.Product__r.Site__r.Country__c, Rs__r.Rev__r.Product__r.RecordType.Name From Metric__c Where Opportunity__c=:parId And Rs__r.Rev__r.Product__r.RecordType.Name =: DARTUtil.DART6];
			if(lstMetric.isEmpty()) return new PageReference('/' + parId);
		        minDate = lstMetric[0].MetricDate__c;
            	maxDate = lstMetric[0].MetricDate__c;
		        for(Metric__c mtr : lstMetric){
		        	minDate = mtr.MetricDate__c < minDate ? mtr.MetricDate__c : minDate;
		        	maxDate = mtr.MetricDate__c > maxDate ? mtr.MetricDate__c : maxDate;
		            sCountry.add(mtr.Rs__r.Rev__r.Product__r.Site__r.Country__c);
		            dartVersions.add(mtr.Rs__r.Rev__r.Product__r.RecordType.Name);
		            //Unique AdId to a country
		            String keyDart = mtr.Rs__r.Rev__r.Product__r.Site__r.Country__c + KEY_SEP + mtr.Rs__r.Rev__r.Product__r.RecordType.Name;
		            if(!mLoginSobjIds.containsKey(keyDart)) mLoginSobjIds.put(keyDart, new List<String>());
		            mLoginSobjIds.get(keyDart).add(mtr.Id);
		            if(mtr.Rs__r.Rev__r.ExtLineItemId__c != null) mAdId.put(mtr.Id, mtr.Rs__r.Rev__r.ExtLineItemId__c);
		            else if(mtr.Rs__r.Rev__r.ExtOrderId__c != null) mAdId.put(mtr.Id, mtr.Rs__r.Rev__r.ExtOrderId__c);
		            //DartVersion used by multiple country
		            if(!mDartVersionCountry.containsKey(mtr.Rs__r.Rev__r.Product__r.RecordType.Name)) mDartVersionCountry.put(mtr.Rs__r.Rev__r.Product__r.RecordType.Name, new List<String>());
		            mDartVersionCountry.get(mtr.Rs__r.Rev__r.Product__r.RecordType.Name).add(mtr.Rs__r.Rev__r.Product__r.Site__r.Country__c);
            }
            //Create support logger
            for(AdServer_Login__c login : [SELECT RecordType.Name, Name, Login_URL__c, User_Name__c, Password__c, Network_ID__c FROM AdServer_Login__c WHERE Name IN: sCountry AND RecordType.Name IN: dartVersions AND Active__c=true AND isDeleted=false ]){
                String keyDart = login.Name + KEY_SEP + login.RecordType.Name;
                if(!mLoginSobjIds.containsKey(keyDart)) continue;
                DART_Delivery_Support__c dds = new DART_Delivery_Support__c(
                    AdServer_Login__c = login.Id, Attempt__c = 0, Retry_Counter__c = 0,
                    Schedule_Type__c = DeliveryController.SCH_TYPE_MANUALLYPOLLING,
                    Sobject__c = DeliveryController.SOBJECT_METRIC,
                    Status__c = DeliveryController.DART_STATUS_NEW,
                    Import_Type__c = devSupDetail,
                    Query_Start_Date__c = minDate,
                    Query_End_Date__c = maxDate
                    );
                mDDSupport.put(keyDart, dds);
                mAdLogin.put(keyDart, login);
            }
            //do request report and poll for other countries and servers
            keepPollingReportRequest = true;
            //pollReportRequest();
        }catch(Exception e){isError = true;ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to import data : ' + e.getMessage()));}//+ '-----' +e.getStackTraceString()
        return null;
    }
    
    //---Step 1 : Poll Request---
    public Boolean keepPollingReportRequest {get; set;}
   /**
    * poll all report requests first, next poll status then update
    */
    public PageReference pollReportRequest(){
        try{
            for(String dartversion : mDartVersionCountry.keySet()){
                for(String country : mDartVersionCountry.get(dartversion)){
                    if(!waitingDartVersionCountry.containsKey(dartversion)) waitingDartVersionCountry.put(dartversion, new Set<String>());
                    //Query and DML is ok to perform here, the logic only perform once
                    if(waitingDartVersionCountry.get(dartversion).contains(country)) continue;
                    waitingDartVersionCountry.get(dartversion).add(country);
                    doRequestReport(country, dartversion);
                    keepPollingReportRequest = true;
                    return null;
                }
            }
            keepPollingReportRequest = false;
            keepPollingStatus = true;
            //pollReportStatus();
        }catch(Exception e){isError = true;ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to import data : ' + e.getMessage()));}
        
        return null;
    }
    
     //---Step 2 : Poll All report Status and update when complete---
    public Boolean keepPollingStatus {get; set;}
    /**
    * Poll status and update when Complete
    */
    public PageReference pollReportStatus(){
        try{
            for(String dartversion : waitingDartVersionCountry.keySet()){
                if(dartversion == DARTUtil.DART5) continue;
                for(String country : waitingDartVersionCountry.get(dartversion)){
                    //Login locating in loop but perform only once, so query or dml won't be an issue
                    if(!completeDartVersionCountry.containsKey(dartversion)) completeDartVersionCountry.put(dartversion, new Set<String>());
                    if(completeDartVersionCountry.get(dartversion).contains(country)) continue;
                    //See status from requested reports
                    String keylogin = country + KEY_SEP + dartversion;
                    //AdServer_Login__c login = mAdLogin.get(keylogin);
                    DART_Delivery_Support__c dds = DeliveryController.getDeliverySupportRecord(mDDSupport.get(keylogin).Id);
                    DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = DeliveryController.buildQueryService(dds);
                    String reportStatus = reportService.getReportJobStatus((long)dds.Job_Id__c);
                    if(reportStatus == DART6_REPORTSERVICE.REPORTJOBSTATUS_COMPLETED){
                        // Import task complete
                        completeDartVersionCountry.get(dartversion).add(country);
                        DeliveryController controller = new DeliveryController(dds);
                        controller.setReportService(reportService);
                        controller.setJobid((long)dds.Job_Id__c);
                        processDeliveryUpdate(controller);
                    }else if(reportStatus == DART6_REPORTSERVICE.REPORTJOBSTATUS_FAILED){
                        // Import task complete
                        completeDartVersionCountry.get(dartversion).add(country);
                        // Throw message and log
                        dds.DART_Status__c = DeliveryController.REPORT_QUERY_FAILED;
                        dds.Status__c = DeliveryController.DART_STATUS_FINISHED;
                        update dds;
                        throw new ExceptionGroup.DARTException('Failed to query report from server');
                    }else{
                        //log progress
                        dds.DART_Status__c = DeliveryController.REPORT_QUERY_INPROGRESS;
                        dds.Status__c = DeliveryController.DART_STATUS_AWAIT;
                        dds.Attempt__c = dds.Attempt__c + 1;
                        update dds;
                        if(dds.Attempt__c > DeliveryController.MAX_ATTAMPT_WAITING && dds.Status__c == DeliveryController.DART_STATUS_AWAIT){
                            // Import task complete
                            completeDartVersionCountry.get(dartversion).add(country);
                            dds.DART_Status__c = DeliveryController.REPORT_QUERY_FAILED;
							dds.Status__c = DeliveryController.DART_STATUS_FINISHED;
							update dds;
                            throw new ExceptionGroup.DARTException('Requesting report takes time too long with more than ' + DeliveryController.MAX_ATTAMPT_WAITING + ' attempts');
                        }
                    }
                    keepPollingStatus = true;
                    return null;
                }
            }
            keepPollingStatus = false;
            return new PageReference('/' + parId);
        }catch(Exception e){isError = true;ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to import data : ' + e.getMessage()));}
        
        return null;
    }
    
    
    
    /**
    * Update process base on Controller
    */
    private void processDeliveryUpdate(DeliveryController controller){
        //Download and do update
        controller.importDelivery('');
        DART_Delivery_Support__c dds = controller.dartDelStatus;
        String keylogin = dds.AdServer_Login__r.Name + KEY_SEP + dds.AdServer_Login__r.RecordType.Name;
        List<String> sobjIds = mLoginSobjIds.get(keylogin);
        BatchDeliveryProcess batchProcess = new BatchDeliveryProcess(null, controller.getListDart(), dds.Id);
        String dQuery = query.replace('%1', dds.AdServer_Login__r.Name).replace('%2', dds.AdServer_Login__r.RecordType.Name) + ' AND Id IN: sobjIds';
        batchProcess.doExecute(Database.query(dQuery));
        //Do log
        batchProcess.dofinish();
        
    }
    
    
   /** 
    * do request on specific country and dartversion
    */
    private void doRequestReport(String country, String dartversion){
        String keylogin = country + KEY_SEP + dartversion;
        if(dartversion == DARTUtil.DART6){
            String adIds = '';
            for(String sobjId : mLoginSobjIds.get(keylogin)){
                if(mAdId.get(sobjId) != null) adIds += mAdId.get(sobjId) + ',' ;
            }
            String reportId = '';
            DART_Delivery_Support__c dds = mDDSupport.get(keylogin);
            if(adIds != ''){
                adIds = adIds.substring(0, adIds.length() - 1);
                AdServer_Login__c login = mAdLogin.get(keylogin);
                DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = DeliveryController.buildQueryService(login.Name , login.Network_ID__c);
                Dart6_ReportService.ReportJob reportJob = DeliveryController.buildReportQuery(dds, 'WHERE LINE_ITEM_ID IN (' + adIds + ')'); //Split to another process: OR ORDER_ID IN (' + adIds + ')
                reportId = String.valueOf(DeliveryController.runReportRequest(reportService, reportJob));
            } 
            dds.Job_Id__c = adIds == '' ? null : Decimal.valueOf(reportId);
            dds.DART_Status__c = adIds == '' ? DeliveryController.REPORT_QUERY_COMPLETED : DeliveryController.REPORT_QUERY_INPROGRESS;
            dds.Status__c = adIds == '' ? DeliveryController.DART_STATUS_FINISHED : DeliveryController.DART_STATUS_AWAIT;
            dds.Attempt__c = adIds == '' ? dds.Attempt__c : dds.Attempt__c + 1;
            upsert dds;
        }
    }
}