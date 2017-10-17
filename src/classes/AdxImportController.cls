/**
 * Ad exchange import to Metric custom object of SF
 */

public with sharing class AdxImportController extends DARTObject.AbstractDARTController{
	
	/** contructor */
	public AdxImportController(){}
	
    /** 
     * Mapping query for each sObject 
     */
    public static Map<String, String> mGeneralQuery = new Map<String, String>{
        DeliveryController.SOBJECT_METRIC => 'Select Rs__r.Rev__r.ExtLineItemId__c, Rs__r.Rev__r.ExtOrderId__c, AD_Clicks__c, AD_Impressions__c, AD_OSI__c, MetricDate__c, Rs__r.Rev__r.Product__r.Site__r.Country__c From ' + DeliveryController.METRIC_API_NAME + ' Where %DATECRIT% Rs__r.Rev__r.Product__r.Site__r.Country__c =\'%1\' AND Rs__r.Rev__r.Product__r.RecordType.Name =\'%2\' AND Opportunity__r.Ad_Client_ID__c=\'%3\''
    };
    
    /** 
     * Mapping conditions for each sobject
     */
    public static Map<String, String> mQuerySObject = new Map<String, String>{
        DeliveryController.SOBJECT_METRIC => mGeneralQuery.get(DeliveryController.SOBJECT_METRIC).replace('%DATECRIT%', 'MetricDate__c >= ' + DeliveryController.QUERY_START_DATE + ' AND MetricDate__c <= ' + DeliveryController.QUERY_END_DATE + ' AND ')
    };

	/**
     * Build Query for report service
     * 
     */
    public static Dart6_ReportService.ReportJob buildAdxReportQuery(DART_Delivery_Support__c dds, String addQuery){
        Map<String,String[]> queryFieldsDART6 = new Map<String, String[]>{
                DeliveryController.SOBJECT_METRIC => new String[]{'AD_EXCHANGE_LINE_ITEM_LEVEL_REVENUE','AD_EXCHANGE_LINE_ITEM_LEVEL_CLICKS', 'AD_EXCHANGE_LINE_ITEM_LEVEL_IMPRESSIONS'} 
        };
        Map<String,String[]> dimensionFieldsDART6 = new Map<String, String[]>{
                DeliveryController.SOBJECT_METRIC => new String[] {'DATE'}
        };
        
        String sobjType = dds.Sobject__c;
        // Create report query.
        Dart6_ReportService.Statement statement = new Dart6_ReportService.Statement();
        statement.query = addQuery;
        Dart6_ReportService.ReportQuery reportQuery = new Dart6_ReportService.ReportQuery();
        reportQuery.statement = statement;
        reportQuery.dateRangeType = 'CUSTOM_DATE';
        reportQuery.columns = queryFieldsDART6.get(sobjType);
        reportQuery.dimensions = dimensionFieldsDART6.get(sobjType);
        
        reportQuery.startDate = new Dart6_ReportService.Date_x();
        reportQuery.startDate.year = dds.Query_Start_Date__c.year();
        reportQuery.startDate.month = dds.Query_Start_Date__c.month();
        reportQuery.startDate.day = dds.Query_Start_Date__c.day();
        
        reportQuery.endDate = new Dart6_ReportService.Date_x();
        reportQuery.endDate.year = dds.Query_End_Date__c.year();
        reportQuery.endDate.month = dds.Query_End_Date__c.month();
        reportQuery.endDate.day = dds.Query_End_Date__c.day();

        System.debug('---------->>reportQuery::::' + reportQuery);
        Dart6_ReportService.ReportJob reportJob = new Dart6_ReportService.ReportJob();
        reportJob.reportQuery = reportQuery;
        return reportJob;
    } 
     

     /**
     * call to process AdxImportBatchProcess
     * @param DART_Delivery_Support__c
     * @param List of DartObject
     */
    public static void processBatchAdxImport(DART_Delivery_Support__c dds, List<DARTObject.IDARTGenericObject> lstDartObject){
        String dsStartDate = DateTime.newInstance(dds.Query_Start_Date__c.year(),dds.Query_Start_Date__c.month(),dds.Query_Start_Date__c.day()).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
        String dsEndDate = DateTime.newInstance(dds.Query_End_Date__c.year(),dds.Query_End_Date__c.month(),dds.Query_End_Date__c.day()).format(DARTUtil.DART_DATEFORMAT_QUERY) ;
        String queryStr = mQuerySObject.get(dds.Sobject__c).replace('%1', dds.AdServer_Login__r.Name).replace('%2', dds.AdServer_Login__r.RecordType.Name).replace('%3', dds.AdServer_Login__r.Network_ID__c+'');
        queryStr = queryStr.replaceAll(DeliveryController.QUERY_START_DATE, dsStartDate).replaceAll(DeliveryController.QUERY_END_DATE, dsEndDate);
        queryStr += Test.isRunningTest()? ' Limit 2' : ''; // changed to fix Num Batch Limit error 
        BatchAdxImportProcess batchAdx = new BatchAdxImportProcess(queryStr, lstDartObject, dds.Id);
        ID batchprocessid = Database.executeBatch(batchAdx);
    }
}