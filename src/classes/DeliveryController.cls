/**
 * @update: chr - replace old objects with the new objects
 *      - Revenue_Schedule_daily__c replace by Metric__c
 *      - Replace to use Rev__c instead of Revenue_Schedule__c  
 *      Delivery for total period, run daily, store on Rev__c
 *          + TOTAL_LINE_ITEM_LEVEL_CLICKS(StartDate until NOW) => Rev__c.AD_Clicks__c
 *          + TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS(StartDate until NOW) => Rev__c.AD_Impressions__c
 *          + OSI => Rev__c.AD_OSI__c
 *      Delivery per day, run daily, store on Metric__c
 *          + TOTAL_LINE_ITEM_LEVEL_CLICKS(Metric__c.MetricDate__c) => Metric__c.AD_Clicks__c
 *          + TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS(Metric__c.MetricDate__c) => Metric__c.AD_Impressions__c
 *          + OSI => Metric__c.AD_OSI__c
 *  @update: Bunhor @ 20-Jan-15
 *          + SCH_TYPE_MANUALLYPOLLING
 *          + REPORT_QUERY_CANCELLED
 */

public with sharing class DeliveryController  extends DARTObject.AbstractDARTController{
    public static final Integer DELIVERY_BATCH_SIZE = DevSettings__c.getInstance('DeliveryBatchSize') != null ? Integer.valueOf(DevSettings__c.getInstance('DeliveryBatchSize').Value__c) : 200;
    //RS: 15 DeliverySupport with 2-day-packages.
    public static final Integer DAY_NUM_SPLIT = DevSettings__c.getInstance('DeliveryDaySize') != null ? Integer.valueOf(DevSettings__c.getInstance('DeliveryDaySize').Value__c) : 2;

    public static final String METRIC_API_NAME = 'Metric__c'; 
    public static final String REVENUE_ITEM_API_NAME = 'Rev__c';
    public static final String OPPORTUNITY_PRODUCT_API_NAME = 'OpportunityLineItem';
      
    public static final String SOBJECT_OPPPRODUCT = 'Opportunity Product';
    public static final String SOBJECT_REVENUE_ITEM = 'Revenue Items'; 
    public static final String SOBJECT_METRIC = 'Metrics';
    public static final String DART_STATUS_NEW = 'New';
    public static final String DART_STATUS_AWAIT = 'Await';
    public static final String DART_STATUS_FINISHED = 'Finished'; 
    public static final String SCH_TYPE_DAILY = 'Daily'; 
    public static final String SCH_TYPE_MONTHLY = 'Monthly';
    public static final String SCH_TYPE_MANUALLY = 'Manually';
    public static final String SCH_TYPE_MANUALLYPOLLING = 'Manually - Polling'; //
    public static final String SCH_TYPE_ALL = 'All';
    public static final String REPORT_QUERY_FAILED = 'FAILED';
    public static final String REPORT_QUERY_INPROGRESS = 'IN_PROGRESS';
    public static final String REPORT_QUERY_COMPLETED = 'COMPLETED';
    public static final String REPORT_QUERY_CANCELLED = 'CANCELLED'; //
    public static final String TYPE_MANUALLY_POLLING = 'Polling Import';
    public static final Integer MAX_ATTAMPT_WAITING = 10;
    public static final String REPORT_QUERY_RETRY = 'RETRY';
    public static final Integer MAX_RETRY_IMPORT = 3;
    public static final String QUERY_START_DATE = '%StartDate%';
    public static final String QUERY_END_DATE = '%EndDate%';
    
    public static final String DFP_DELIVERY = 'Dfp';
    public static final String ADX_IMPORT = 'Adx';
     
    AdServer_Login__c login;
    String breakDown, dateRange;
    
    public DART_Delivery_Support__c dartDelStatus {get; set;}
    public String selectedMonth {get;set;}
    public List<SelectOption> lstOptMonths {get; set;}
    public String fromId {get; set;}
    public Boolean productMode {get; set;}
    public Boolean rSMode {get; set;}
    public Boolean rSDMode {get; set;}
    
    /**
     * Start from custom buttons, RS, RSD, and Product
     */ 
    public DeliveryController(){
        fromId = System.currentPageReference().getParameters().get('id');
        dartDelStatus = new DART_Delivery_Support__c();
        dartDelStatus.Sobject__c = System.currentPageReference().getParameters().get('sobjType');
        
        //Display Tab style
        productMode = dartDelStatus.Sobject__c == SOBJECT_OPPPRODUCT;
        rSMode = dartDelStatus.Sobject__c == SOBJECT_REVENUE_ITEM;
        rSDMode = dartDelStatus.Sobject__c == SOBJECT_METRIC;
        
        //Previous Six months
        Date todayDate = System.today();
        lstOptMonths = new List<SelectOption>();
        for(Integer i = 0; i > -6 ; i--){
            Date optionDate = todayDate.addMonths(i);
            String monthStr = BatchDeliveryProcess.MINT_TO_MONTH.get(optionDate.month());
            lstOptMonths.add(new SelectOption(optionDate.month() + '-' + optionDate.year() , monthStr + ' - ' + optionDate.year()));
        }
        selectedMonth = lstOptMonths[0].getValue();
    }
    
    /**
     * Start import process
     */
    public PageReference proceedImport(){
        Date startDate = dartDelStatus.Query_Start_Date__c;
        Date endDate = dartDelStatus.Query_End_Date__c;
        List<String> ldElement = selectedMonth.split('-');
        if(dartDelStatus.Sobject__c == SOBJECT_REVENUE_ITEM){
            Integer yearInt = Integer.valueOf(ldElement[1]);
            Integer monthInt = Integer.valueOf(ldElement[0]);
            startDate = Date.newInstance(yearInt,monthInt,1);
            endDate = Date.newInstance(yearInt,monthInt,Date.daysInMonth(yearInt, monthInt));
        }
        String result='';
        try{
            Integer numPending = [Select count() from DART_Delivery_Support__c 
                WHERE Schedule_Type__c=:SCH_TYPE_MANUALLY 
                AND Sobject__c=:dartDelStatus.Sobject__c
                AND Status__c <> :DeliveryController.DART_STATUS_FINISHED];
            
            //We expected all DDS are 'finished'; so we can run another, or wait until they all finish
            if(numPending>0) result = 'Importing Delivery of '+dartDelStatus.Sobject__c+' is already running.';
            else{
                //start(SCH_TYPE_MANUALLY, dartDelStatus.Sobject__c, startDate, endDate);
                result = 'SUCCESS: Importing Delivery of '+dartDelStatus.Sobject__c+' is now running in background.';
            }
        }catch(Exception ex){result+='ERROR: '+ex;}
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, result));
        return null;
    }
    
    /**
     * Constructor
     * @param AdserverLogin
     * @param breakDown
     * @pram dateRange
     */ 
    public DeliveryController(AdServer_Login__c login,String breakDown,String dateRange)
    {
        this.login = login;
        this.breakDown = breakDown;
        this.dateRange = dateRange;
        dartDelStatus = new DART_Delivery_Support__c();
    }
    
    /**
     * Constructor
     * @param Dart_Delivery_Support__c dds
     */
    public DeliveryController(DART_Delivery_Support__c dds)
    {
        dartDelStatus = dds;
        login = [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c FROM AdServer_Login__c WHERE Id =: dds.AdServer_Login__c limit 1];
    }
    
    private Long jobid;
    
    /**
     * @param jobId
     */
    public void setJobid(Long jobid){
        this.jobid = jobid;
    }
    
    private DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService;
    
    /**
     * @param DFP reportService 
     */
    public void setReportService (DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService){
        this.reportService = reportService;
    }
    
    /** initate the ImportDelivery Process 
     *  - just insert the the relavant DDS from the eligible Logins
     *  - should be called from Scheduler
     *  - manually
     *  @param scheduleType
     *  @param sobj
     */
    public static void start(String scheduleType,String sobj)
    {
        start(scheduleType, sobj, '');
    }
    
    /**
     * Start the process with Date Range define, start date and end date
     */
    public static void start(String scheduleType, String sobj, Date startDate, Date endDate)
    {
        start(scheduleType, sobj, startDate, endDate, '');
        
    }
    
    /** dart6: create a report job at dart server */
    public static void createReportJob(DART_Delivery_Support__c dds, DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService, Dart6_ReportService.ReportJob reportJob, String importType)
    {
        dds.Job_Id__c = runReportRequest(reportService, reportJob);
        dds.DART_Status__c = REPORT_QUERY_INPROGRESS;
        dds.Status__c = DART_STATUS_AWAIT;
        dds.Attempt__c = dds.Attempt__c + 1;
        update dds;
        createSchedulerWatcher(dds.Id, dds.Sobject__c, importType);
    } 
    
    /** createSchedulerWatcher */
    public static void createSchedulerWatcher(String ddsId, String sObj, String importType){
        DART6SchReportRequestWatcher watcher = new DART6SchReportRequestWatcher(ddsId, importType);
        System.schedule('DART6 Delivery RunningReport ' + ddsId + ' at ' + Datetime.now()  , watcher.createCronExpForNextFireTime(), watcher);
    }
    
    /**
     * start to run next AdserverLogin
     * @param string sobject name
     * @param String scheduleType
     */
    public static void startNextAdServer(String sobj, String scheduletype, String importType){
        DART_Delivery_Support__c nextdds ;
        List<DART_Delivery_Support__c> ldds = [Select AdServer_Login__r.Name, AdServer_Login__r.Network_ID__c, AdServer_Login__r.RecordType.name, Sobject__c, Schedule_Type__c, Job_Id__c, DART_Status__c, Status__c, Attempt__c, AdServer_Login__c, Query_Start_Date__c, Query_End_Date__c From DART_Delivery_Support__c Where 
            (Status__c =: DART_STATUS_NEW OR DART_Status__c =: REPORT_QUERY_INPROGRESS) And 
            Sobject__c =: sobj And 
            Schedule_Type__c =: scheduletype 
            order by CreatedDate];
        //Avoid same network progressing the same time which causes LockRow error
        Set<String> progressingNetworks = new Set<String>();
        for (DART_Delivery_Support__c dds : ldds) {
            if (dds.DART_Status__c == REPORT_QUERY_INPROGRESS) {
                progressingNetworks.add(dds.AdServer_Login__r.Name);
            }
            if (nextdds == null && dds.Status__c == DART_STATUS_NEW) {
                nextdds = dds;
            }
        }
        for (DART_Delivery_Support__c dds : ldds) {
            if (nextdds != null && !progressingNetworks.contains(nextdds.AdServer_Login__r.Name)) {
                break;
            }
            if (dds.Status__c == DART_STATUS_NEW) {
                nextdds = dds;
            }
        }
        if (nextdds == null) {
            return;
        }
        DART6BatchDeliverySupport batchSupport = new DART6BatchDeliverySupport(ldds[0].Id, DART6BatchDeliverySupport.CALL_TYPE_REQUEST_REPORT, importType);
        ID batchprocessstartNextAdServerid = Database.executeBatch(batchSupport);
    } 
    
    /** 
     * dart6: check job status 
     * @param DART_Delivery_Support
     * @updated Chr: 13-08-2015 
     *               Version v201505 not use methode getReportJob anymore, we replaced it with getReportJobStatus 
     *               and return as string
     */ 
    public static void checkJobStatus(DART_Delivery_Support__c dds, String importType)
    {
        //dds = getDeliverySupportRecord(dds.Id);
        DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = DeliveryController.buildQueryService(dds);
        //request to get status here: COMPLETED, IN_PROGRESS, FAILED
        String repJobStatus = reportService.getReportJobStatus((long)dds.Job_Id__c);
        // if complete ok -> run controller batch from importDelivery()
        if(repJobStatus == DART6_REPORTSERVICE.REPORTJOBSTATUS_COMPLETED){
            DeliveryController controller = new DeliveryController(dds);
            controller.setReportService(reportService);
            controller.setJobid((long)dds.Job_Id__c);
            controller.importDelivery(importType);
            if(ADX_IMPORT.equals(importType)) AdxImportController.processBatchAdxImport(dds, controller.getListDart());
            else processBatchDelivery(dds, controller.getListDart());
            return;
        }
        // if complete FAILED -> log
        if(repJobStatus == DART6_REPORTSERVICE.REPORTJOBSTATUS_FAILED){
            dds.DART_Status__c = REPORT_QUERY_FAILED;
            dds.Status__c = DART_STATUS_FINISHED;
            update dds;
            throw new ExceptionGroup.DARTException('Failed to query report from server');
            return;
        }
        
        // If attempt more than MAX_ATTAMPT_WAITING, report job is stuck. A new job will be attempted 
        if(dds.Attempt__c > MAX_ATTAMPT_WAITING && dds.Status__c == DART_STATUS_AWAIT){
            retryImport(dds, new DARTLogger.LogMessage(
                                dds.Id ,'Import Process was abandoned',
                                'DeliveryController.checkJobStatus', dds.AdServer_Login__r.RecordType.name,
                                DARTLogger.TYPE_ERROR, dds.Status__c, 'Requesting report takes time too long with more than ' + MAX_ATTAMPT_WAITING + ' attempts' ), importType);
            return;
        }
        
        // if in progress -> run scheduler watcher, attempt++
        dds.DART_Status__c = REPORT_QUERY_INPROGRESS;
        dds.Status__c = DART_STATUS_AWAIT;
        dds.Attempt__c = dds.Attempt__c + 1;
        createSchedulerWatcher(dds.Id, dds.Sobject__c, importType);
        update dds;
     
    }
    
    
    /** dart5: request query: process in batch
     *  dart6: download xml : process in batch
     */
    public void importDelivery(String importType)
    {  
        
        //create request
        HTTPWrapper.IGenericRequest deliveryRequest = FactoryDARTRequest.getInstance().createDartDeliveryRequest(login,breakDown,dateRange, jobid, reportService);
        
        //create parser 
        DART6Parser.IDartParser deliveryParser;
        if(ADX_IMPORT.equals(importType)){
            deliveryParser =  FactoryParser.getInstance().createAdxReportParser(login.RecordType.Name, dartDelStatus.Sobject__c);
        }   
        else{
            deliveryParser = FactoryParser.getInstance().createDeliveryParser(login.RecordType.Name, dartDelStatus.Sobject__c);
        }
        
        //create connection
        DARTObject.IDARTConnector deliveryCon = FactoryConnector.getInstance().createConnector(login.RecordType.Name,deliveryRequest, deliveryParser);
        deliveryCon.connect();    
        invokedMethod = deliveryRequest.getInvokedMethod();
        
        //getDartObjects
        listDartObjects = deliveryCon.getDartObjects();
        
    }
    
    /**
     * @retrun DART_Delivery_Support record by recordId
     * @param recordId
     */
    public static DART_Delivery_Support__c getDeliverySupportRecord(String recId){
         return [Select AdServer_Login__r.Name, AdServer_Login__r.Network_ID__c, AdServer_Login__r.RecordType.name,Status__c, Sobject__c, Schedule_Type__c, Job_Id__c, DART_Status__c, Attempt__c, AdServer_Login__c, Query_Start_Date__c, Query_End_Date__c, Retry_Counter__c From DART_Delivery_Support__c where Id =: recId];
    }
    
    
    /** 
     * Mapping query for each sObject 
     */
    public static Map<String, String> mGeneralQuery = new Map<String, String>{
        SOBJECT_METRIC => 'Select Rs__r.Rev__r.ExtLineItemId__c, Rs__r.Rev__r.ExtOrderId__c, AD_Clicks__c, AD_Impressions__c, AD_OSI__c, MetricDate__c, Rs__r.Rev__r.Product__r.Site__r.Country__c From ' + METRIC_API_NAME + ' Where %DATECRIT% Rs__r.Rev__r.Product__r.Site__r.Country__c =\'%1\' AND Rs__r.Rev__r.Product__r.RecordType.Name =\'%2\'  AND (Rs__r.Rev__r.ExtLineItemId__c <> null OR Rs__r.Rev__r.ExtOrderId__c <> null)',
        SOBJECT_REVENUE_ITEM => 'Select ExtLineItemId__c, ExtOrderId__c, AD_Clicks__c, AD_Impressions__c, AD_OSI__c, From_Date__c, Product__r.Site__r.Country__c From ' + REVENUE_ITEM_API_NAME + ' Where %DATECRIT% Product__r.Site__r.Country__c =\'%1\' AND Product__r.RecordType.Name =\'%2\' AND (ExtLineItemId__c <> null OR ExtOrderId__c <> null)',
        SOBJECT_OPPPRODUCT => 'Select Ad_Id__c, Adserver_ID_Order_ID__c, PricebookEntry.Product2.Site__r.Country__c, PricebookEntry.Product2.RecordType.Name From ' + OPPORTUNITY_PRODUCT_API_NAME + '  Where %DATECRIT% PricebookEntry.Product2.Site__r.Country__c =\'%1\' AND PricebookEntry.Product2.RecordType.Name =\'%2\' AND (Ad_Id__c <> null OR Adserver_ID_Order_ID__c <> null)' // Delivered_AI_LT__c, delivered_Clicks_LT__c, OSI__c, 
    };
    
    /** 
     * Mapping conditions for each sobject
     */
    public static Map<String, String> mQuerySObject = new Map<String, String>{
        SOBJECT_METRIC => mGeneralQuery.get(SOBJECT_METRIC).replace('%DATECRIT%', 'MetricDate__c >= ' + QUERY_START_DATE + ' AND MetricDate__c <= ' + QUERY_END_DATE + ' AND '),
        SOBJECT_REVENUE_ITEM => mGeneralQuery.get(SOBJECT_REVENUE_ITEM).replace('%DATECRIT%', 'From_Date__c <= ' + QUERY_START_DATE + ' AND until_Date__c >= ' + QUERY_END_DATE + ' AND '),
        SOBJECT_OPPPRODUCT => mGeneralQuery.get(SOBJECT_OPPPRODUCT).replace('%DATECRIT%', 'from_Date__c <= ' + QUERY_START_DATE + ' AND until_Date__c >= ' + QUERY_END_DATE + ' AND ')
    };
    
        
    /**
     * Called from 'start' of Main scheduler. and from Batch to continue to next Login 
     */
    public static void doStart(DART_Delivery_Support__c dds, String importType)
    {   
        
        if(DARTUtil.DART6.equals(dds.AdServer_Login__r.RecordType.name)) 
        {
            String addQuery='';
            if(ADX_IMPORT.equals(importType)) addQuery = 'WHERE LINE_ITEM_TYPE = \'AD_EXCHANGE\'';
            DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = buildQueryService(dds);
            Dart6_ReportService.ReportJob reportJob;
            if(ADX_IMPORT.equals(importType)) reportJob = AdxImportController.buildAdxReportQuery(dds, addQuery);
            else reportJob = buildReportQuery(dds, addQuery);
            createReportJob(dds, reportService, reportJob, importType);
        }
    }
    
    /**
     * call to process batch delivery
     * @param DART_Delivery_Support__c
     * @param List of DartObject
     */
    public static void processBatchDelivery(DART_Delivery_Support__c dds, List<DARTObject.IDARTGenericObject> lstDartObject){
        String dsStartDate = DateTime.newInstance(dds.Query_Start_Date__c.year(),dds.Query_Start_Date__c.month(),dds.Query_Start_Date__c.day()).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
        String dsEndDate = DateTime.newInstance(dds.Query_End_Date__c.year(),dds.Query_End_Date__c.month(),dds.Query_End_Date__c.day()).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
        String queryStr = mQuerySObject.get(dds.Sobject__c).replace('%1', dds.AdServer_Login__r.Name).replace('%2', dds.AdServer_Login__r.RecordType.Name);
        queryStr = queryStr.replaceAll(QUERY_START_DATE, dsStartDate).replaceAll(QUERY_END_DATE, dsEndDate);
        queryStr += Test.isRunningTest()? ' Limit 2' : ''; // changed to fix Num Batch Limit error 
        BatchDeliveryProcess batchDelivery = new BatchDeliveryProcess(queryStr, lstDartObject, dds.Id);
        ID batchprocessid = Database.executeBatch(batchDelivery, DELIVERY_BATCH_SIZE);
    }
    
    /** 
     * to build queryService
     * @param DART_Delivery_Support__c
     * @return DART6_REPORTSERVICE.REPORTServiceInterfacePort
     */
    public static DART6_REPORTSERVICE.REPORTServiceInterfacePort buildQueryService(DART_Delivery_Support__c dds){       
        return buildQueryService(dds.AdServer_Login__r.Name, dds.AdServer_Login__r.Network_ID__c);
    } 
    
    /** 
     * @param AdServerLoginName
     * @param NetworkId
     * @return DART6_REPORTSERVICE.REPORTServiceInterfacePort
     */
    public static DART6_REPORTSERVICE.REPORTServiceInterfacePort buildQueryService(String adServName, String netId){
         
         AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6, adServName);
         String authToken = DARTUtil.getAccessToken(login); // new version 201405
         
        
        // Build Service Request Header
        DART6_REPORTSERVICE.SoapRequestHeader header = new DART6_REPORTSERVICE.SoapRequestHeader();
        header.applicationName='ReportService';
        header.networkCode= netId;
        
        Map<String,String> inputHttpHeaders_x = new Map<String, String>();
        inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);
        
        DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService = new DART6_REPORTSERVICE.ReportServiceInterfacePort();
        if(DART6Message.WS.UseProxy__c) reportService.endpoint_x = DART6Message.ENDPOINT_RUNSCOPE_PROXY+'ReportService';
        reportService.RequestHeader = header;
        reportService.inputHttpHeaders_x = inputHttpHeaders_x;
        reportService.timeout_x = 120000;//Extend timeout due to massive download size
        return reportService;
    } 
    
    //Bunhor @07-Sep-16: Move this maps out of method so that it can be reused
    public static Map<String,String[]> queryFieldsDART6 = new Map<String, String[]>{
        SOBJECT_OPPPRODUCT => new String[]{'AD_SERVER_IMPRESSIONS'},
        SOBJECT_METRIC => new String[]{'TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS','TOTAL_LINE_ITEM_LEVEL_CLICKS', 'AD_SERVER_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS', 'AD_SERVER_ACTIVE_VIEW_MEASURABLE_IMPRESSIONS', 'AD_SERVER_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS_RATE'},
        SOBJECT_REVENUE_ITEM => new String[]{'AD_SERVER_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS', 'AD_SERVER_ACTIVE_VIEW_MEASURABLE_IMPRESSIONS', 'AD_SERVER_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS_RATE'} // use attribute LINE_ITEM_LIFETIME_MERGED_IMPRESSIONS','LINE_ITEM_LIFETIME_MERGED_CLICKS 
    };
    public static Map<String,String[]> dimensionFieldsDART6 = new Map<String, String[]>{
            SOBJECT_OPPPRODUCT => new String[]{'ORDER_ID', 'LINE_ITEM_ID'},
            SOBJECT_METRIC => new String[] {'ORDER_ID', 'LINE_ITEM_ID', 'DATE'},
            SOBJECT_REVENUE_ITEM => new String[] {'ORDER_ID', 'LINE_ITEM_ID'}
    };
    
    public static Map<String,String[]> dimensionAttributesDART6 = new Map<String, String[]>{
            SOBJECT_OPPPRODUCT => new String[]{'LINE_ITEM_LIFETIME_IMPRESSIONS', 'LINE_ITEM_LIFETIME_CLICKS', 'LINE_ITEM_DELIVERY_INDICATOR'},
            SOBJECT_METRIC => new String[]{'LINE_ITEM_DELIVERY_INDICATOR'},
            SOBJECT_REVENUE_ITEM => new String[]{'LINE_ITEM_LIFETIME_IMPRESSIONS', 'LINE_ITEM_LIFETIME_CLICKS', 'LINE_ITEM_DELIVERY_INDICATOR'}
    };
    //-------------------------------------------------------
    
    /**
     * Build Query for report service
     * @updated: - chr - 20-10-2014: Changed DFP mapping fields from 
     *             + MERGED_AD_SERVER_CLICKS to TOTAL_LINE_ITEM_LEVEL_CLICKS
     *             + MERGED_AD_SERVER_IMPRESSIONS to TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS
                 - JvdH: MERGED_AD_SERVER_DELIVERY_INDICATOR to AD_SERVER_DELIVERY_INDICATOR 
                 - Chr: Changed to use Lifetime value ('LINE_ITEM_LIFETIME_MERGED_IMPRESSIONS', 'LINE_ITEM_LIFETIME_MERGED_CLICKS') and
                        also remove dimension MONTH_AND_YEAR for Revenue_Item 
     * (Resion: GT-AU never used the old version of DART)
     * - 22-08-2016 Chr: Add three news column on import Rev__c & Metric__c
     */
    public static Dart6_ReportService.ReportJob buildReportQuery(DART_Delivery_Support__c dds, String addQuery){
        
        String sobjType = dds.Sobject__c;
        // Create report query.
        Dart6_ReportService.Statement statement = new Dart6_ReportService.Statement();
        statement.query = addQuery;
        Dart6_ReportService.ReportQuery reportQuery = new Dart6_ReportService.ReportQuery();
        reportQuery.statement = statement;
        reportQuery.dateRangeType = 'CUSTOM_DATE';
        reportQuery.columns = DeliveryController.queryFieldsDART6.get(sobjType);
        reportQuery.dimensions = DeliveryController.dimensionFieldsDART6.get(sobjType);
        
        reportQuery.startDate = new Dart6_ReportService.Date_x();
        reportQuery.startDate.year = dds.Query_Start_Date__c.year();
        reportQuery.startDate.month = dds.Query_Start_Date__c.month();
        reportQuery.startDate.day = dds.Query_Start_Date__c.day();
        
        reportQuery.endDate = new Dart6_ReportService.Date_x();
        reportQuery.endDate.year = dds.Query_End_Date__c.year();
        reportQuery.endDate.month = dds.Query_End_Date__c.month();
        reportQuery.endDate.day = dds.Query_End_Date__c.day();
        reportQuery.dimensionAttributes = DeliveryController.dimensionAttributesDART6.get(sobjType);
        
        System.debug('Dart reportQuery :::::' + reportQuery);
        Dart6_ReportService.ReportJob reportJob = new Dart6_ReportService.ReportJob();
        reportJob.reportQuery = reportQuery;
        return reportJob;
    } 
     
    /**
     * @return runningReportId as String
     */
    public static Long runReportRequest(DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService, Dart6_ReportService.ReportJob reportJob){
        // Run report job.
        reportJob = reportService.runReportJob(reportJob);
        return reportJob.id;
    }
    
    /**
     * Adx Import part
     */
     public static void start(String scheduleType,String sobj, String importType)
    {
        DateTime dToday = System.now();
        DateTime dNextMonth = dToday.addMonths(1);
        DateTime dLastMonth = dToday.addMonths(-1);
        DateTime dYesterday = dToday.addDays(-1);
        DateTime dB4Yesterday = dToday.addDays(-2);
        DateTime dTomorrow = dToday.addDays(1); 
        DateTime dStartThisMonth = DateTime.newInstance(dToday.year(),dToday.month(),1);
        DateTime dStartNextMonth = DateTime.newInstance(dNextMonth.year(),dNextMonth.month(),1);
        DateTime dStartLastMonth = DateTime.newInstance(dLastMonth.year(),dLastMonth.month(),1);
        DateTime startDate;  
        DateTime endDate;
        if(sobj == SOBJECT_METRIC){
            startDate = dB4Yesterday;
            endDate = dYesterday;
        }else if(sobj == SOBJECT_REVENUE_ITEM){
            startDate = dStartThisMonth;
            endDate = dToday;
        }else if(sobj == SOBJECT_OPPPRODUCT){
            startDate = dYesterday;
            endDate = dYesterday;
        }
        
        //#5591 [SFECG] Create custom button to import missing DFP clicks / deliveries into Metrics (#59)
        if(sobj == SOBJECT_METRIC && scheduleType  == SCH_TYPE_ALL ){
             endDate = dYesterday;
             //case current month is january 
             Integer m = dToday.month() == 1 ? 12 : (dToday.month()-1) ;
             Integer y = dToday.month() == 1 ? ( dToday.year()-1 ) : dToday.year() ;
             startDate = DateTime.newInstance( y , m  ,1);
        }
        
        start(scheduleType, sobj, Date.valueOf(startDate), Date.valueOf(endDate), importType);
    }
    
    
    /**
     * Start the process with Date Range define, start date and end date
     */
    public static void start(String scheduleType, String sobj, Date startDate, Date endDate, String importType)
    {
        List<Date> lstStartDate = new List<Date>();
        List<Date> lstEndDate = new List<Date>();
        if( sobj != SOBJECT_REVENUE_ITEM && Math.abs(startDate.daysBetween(endDate)) > DAY_NUM_SPLIT ){
            Date tmpDate = startDate;
            Date tmpDate2 = endDate;
            while(tmpDate < endDate){
                lstStartDate.add(Date.newInstance(tmpDate.year(),tmpDate.month(),tmpDate.day()));
                tmpDate = tmpDate.addDays(DAY_NUM_SPLIT);
                tmpDate2 = tmpDate.addDays(-1);
                lstEndDate.add(Date.newInstance(tmpDate2.year(),tmpDate2.month(),tmpDate2.day()));
            }
            if(tmpDate2 < endDate || startDate == endDate) {
                lstStartDate.add(Date.newInstance(endDate.year(), endDate.month(), endDate.day()));
                lstEndDate.add(Date.newInstance(endDate.year(), endDate.month(), endDate.day()));
            }
        }else{
            lstStartDate.add(startDate);
            lstEndDate.add(endDate);
        }
        
        DART_Delivery_Support__c[] listDDs = new List<DART_Delivery_Support__c>();
        for(AdServer_Login__c login : [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c FROM AdServer_Login__c WHERE  Active__c=true AND isDeleted=false ])
        {
             for(Integer i = 0; i < lstStartDate.size(); i++){
                DART_Delivery_Support__c dds = new DART_Delivery_Support__c(
                    AdServer_Login__c=login.Id,Attempt__c=0,
                    Schedule_Type__c = scheduleType,
                    Sobject__c = sobj,
                    Status__c = DART_STATUS_NEW,
                    Query_Start_Date__c = lstStartDate[i],
                    Query_End_Date__c = lstEndDate[i],
                    Import_Type__c=(ADX_IMPORT.equals(importType)?'Adx Import':'Delivery Import')
                    );
                listDDs.add(dds);
             }
        }
        
        if(!listDDs.isEmpty())
        {
            insert listDDs;
            DART6BatchDeliverySupport batchSupport = new DART6BatchDeliverySupport(listDDs[0].Id, DART6BatchDeliverySupport.CALL_TYPE_REQUEST_REPORT, importType);
            ID batchprocessid = Database.executeBatch(batchSupport);
        }
    } 
    
    /**
    * Retry another job after a time-out failure OR job has been stuck
    */
    public static void retryImport(DART_Delivery_Support__c failedDds, DARTLogger.LogMessage logmsg, String importType){
        if(failedDds.Status__c != DART_STATUS_FINISHED && failedDds.Retry_Counter__c < MAX_RETRY_IMPORT){
            DART_Delivery_Support__c retriedDds = failedDds.clone(false);
            retriedDds.Attempt__c = 0;
            retriedDds.Status__c = DART_STATUS_NEW;
            retriedDds.DART_Status__c = null;
            retriedDds.Job_Id__c = null;
            retriedDds.Retry_Counter__c = failedDds.Retry_Counter__c + 1;
            insert retriedDds;
            failedDds.Retried_DART_Delivery_Support__c = retriedDds.Id;
            failedDds.DART_Status__c = REPORT_QUERY_RETRY;
        }
        failedDds.Status__c = DART_STATUS_FINISHED;
        if(failedDds.DART_Status__c != REPORT_QUERY_RETRY) failedDds.DART_Status__c = REPORT_QUERY_FAILED;
        update failedDds;
        if(logmsg != null) DARTLogger.getInstance().log(failedDds.Id,new List<DARTLogger.LogMessage>{logmsg});
        DeliveryController.startNextAdServer(failedDds.Sobject__c, failedDds.Schedule_Type__c, importType);
    }
    
}