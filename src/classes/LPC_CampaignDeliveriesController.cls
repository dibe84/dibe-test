/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: 
 *	- Campaign Deliveries Targeting
 * @references: 
 *	- LPC_CampaignDeliveries lightning component
 * @changeLog:
 *
 */
public class LPC_CampaignDeliveriesController{
    
    /**
     * Perform Delivery Import from DFP
     * @param oppItem, OpportunityLineItem
     * @param ind, Integer
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse performDeliveryImport(OpportunityLineItem oppItem, Integer ind){
    	RemoteResponse responseObj;
    	Id oppId = oppItem.OpportunityId;
    	List<OpportunityLineItem> items = [Select Ad_Id__c, Adserver_ID_Order_ID__c, From_Date__c, until_date__c, PricebookEntry.Product2.Site__r.Country__c, PricebookEntry.Product2.RecordType.Name From OpportunityLineItem Where Id=:oppItem.Id];
    	if (items.isEmpty()) return responseObj;
    	return responseObj;
    }
   
    /**
     * Get Job Status from DFP
     * @param oppItem, OpportunityLineItem
     * @param jobId, ReportJob Id
     * @return ReportJob Status
     */
    @AuraEnabled 
    public static RemoteResponse getJobStatus(OpportunityLineItem oppItem, String jobId){
    	try{
	    	String adServName = oppItem.PricebookEntry.Product2.Site__r.Country__c;
	    	AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6, adServName);
	    	DART6_REPORTSERVICE.REPORTServiceInterfacePort rptService = DeliveryController.buildQueryService(adServName, login.Network_ID__c);
			RemoteResponse response = new RemoteResponse();
            response.content = rptService.getReportJobStatus(long.valueOf(jobId));
            response.statusCode = RemoteResponse.STATUSCODE_OK;
	    	return response;
    	}catch(exception e){
    		return new RemoteResponse(e.getMessage()+ '\n' +e.getStackTraceString(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
    
    /**
     * Get ReportJob Id from DFP
     * @param oppItem, OpportunityLineItem
     * @return ReportJob Id
     */
    @AuraEnabled 
    public static RemoteResponse getReportJobId(OpportunityLineItem oppItem){
    	try{
	    	String adServName = oppItem.PricebookEntry.Product2.Site__r.Country__c;
	    	AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6, adServName);
	    	Dart6_ReportService.ReportJob rptJob  = getReptJob(oppItem);
	    	if(rptJob == null) return new RemoteResponse('No related RevItem related to this OpportunitylineItem - ' + oppItem.Id, RemoteResponse.STATUSCODE_ERROR);
	    	DART6_REPORTSERVICE.REPORTServiceInterfacePort rptService = DeliveryController.buildQueryService(adServName, login.Network_ID__c);
	    	Long jobId  = DeliveryController.runReportRequest(rptService, rptJob);
	    	RemoteResponse response = new RemoteResponse();
            response.content = String.valueOf(jobId);
            response.statusCode = RemoteResponse.STATUSCODE_OK;
	    	return response;
    	}catch(exception e){
    		return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
    
    /**
     * Do Download Delivery from DFP
     * @param oppItem, OpportunityLineItem
     * @param jobId,  ReportJob Id
     * @return RemoteResponse
     */
    @AuraEnabled 
    public static RemoteResponse doDownloadDelivery(OpportunityLineItem oppItem, String jobId){
    	try{
	    	String adServName = oppItem.PricebookEntry.Product2.Site__r.Country__c;
	    	AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6, adServName);
	    	
	    	//get reportservice
	    	DART6_REPORTSERVICE.REPORTServiceInterfacePort rptService = DeliveryController.buildQueryService(adServName, login.Network_ID__c);
	    	
	    	HTTPWrapper.IGenericRequest deliveryRequest = FactoryDARTRequest.getInstance().createDartDeliveryRequest(login,'','', long.valueOf(jobId), rptService);
	        
	        //create parser 
	        DART6Parser.IDartParser deliveryParser;
	
	    	deliveryParser = FactoryParser.getInstance().createDeliveryParser(login.RecordType.Name, DeliveryController.SOBJECT_REVENUE_ITEM);
	        
	        //create connection
	        DARTObject.IDARTConnector deliveryCon = FactoryConnector.getInstance().createConnector(login.RecordType.Name,deliveryRequest, deliveryParser);
	        deliveryCon.connect();    
	        //getDartObjects
	        List<DARTObject.DARTDelivery> listDartObjects = (List<DARTObject.DARTDelivery>)deliveryCon.getDartObjects();
	        
			if(listDartObjects.isEmpty()){
				listDartObjects.add(new DARTObject.DARTDelivery(
						   		new Map<Object,Object>
						   			{
							   			DARTObject.DEL_FIELD_ADDELIVERED => 0,
							   			DARTObject.DEL_FIELD_ADCLICKED_LIFETIME => 0,
							   			DARTObject.DEL_FIELD_ADOSI => 0, 
							   			DARTObject.DEL_FIELD_ADID => 0,
							   			DARTObject.DEL_FIELD_ORDERID => 0,
							   			DARTObject.DEL_FIELD_IMPRESS_DELIVERED => 0,
							   			DARTObject.DEL_FIELD_CLICKS_DELIVERED => 0,
						   				DARTObject.DEL_FIELD_DATE_OR_MONTH => '',
						   				DARTObject.DEL_FIELD_AD_ACTIVE_VIEW_MEASURABLE_IMPRESSIONS => 0,
										DARTObject.DEL_FIELD_AD_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS  => 0,
										DARTObject.DEL_FIELD_AD_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS_RATE => 0
						   			}
					   			));
			}
			
			List<Rev__c> lstRevItem = [Select ExtLineItemId__c, ExtOrderId__c, AD_Clicks__c, AD_Impressions__c, AD_OSI__c, From_Date__c, OrigOpportunityLineItemId__c,  Product__r.Site__r.Country__c From Rev__c Where OrigOpportunityLineItemId__c=: oppItem.Id And Opportunity__c=:oppItem.opportunityId];
	        if(lstRevItem.isEmpty()){
	        	return new RemoteResponse('No related RevItem to this OpportunitylineItem - ' + oppItem.Id, RemoteResponse.STATUSCODE_ERROR);
	        }
	        Rev__c revItem = lstRevItem[0]; 
	        revItem.AD_Impressions__c = listDartObjects[0].getImpressionsDelivered();
	        revItem.AD_Clicks__c = listDartObjects[0].getClicksDelivered();
	        revItem.AD_OSI__c = listDartObjects[0].getAdOSI();
	        revItem.AD_Active_View_Viewable_Impressions__c = listDartObjects[0].getAdActiveViewViewableImpression();
	        revItem.AD_Active_View_Measurable_Impressions__c = listDartObjects[0].getAdActiveViewMeasurableImpression();
	        revItem.AD_Active_View_Viewable_Impressions_Rate__c = listDartObjects[0].getAdActiveViewViewableImpressionRate();
	        revItem.Last_Delivery_import__c = DateTime.Now();
	        update revItem;
	        
	        revItem = [Select id, AD_Impressions__c, AD_Clicks__c, AD_OSI__c, AD_Click_Rate__c, Last_Delivery_import__c, AD_Active_View_Viewable_Impressions__c, AD_Active_View_Measurable_Impressions__c, AD_Active_View_Viewable_Impressions_Rate__c From Rev__c Where Id=: revItem.Id];
	        //
	        RemoteResponse response = new RemoteResponse();
            response.content = revItem;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
	        return response;
	        
    	}catch(exception e){
    		return new RemoteResponse(e.getMessage() + '\n' +e.getStackTraceString(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
    
    /**
     * Get Report Job from DFP
     * @param oppItem, OpportunityLineItem
     * @return ReportJob
     */
    private  static Dart6_ReportService.ReportJob getReptJob(OpportunityLineItem item){
    	
    	List<Rev__c> lstRevItem = [Select ExtLineItemId__c, ExtOrderId__c, AD_Clicks__c, AD_Impressions__c, AD_OSI__c, From_Date__c, Until_Date__c, OrigOpportunityLineItemId__c,  Product__r.Site__r.Country__c From Rev__c Where OrigOpportunityLineItemId__c=: item.Id And Opportunity__c=:item.opportunityId And ExtLineItemId__c <> null And ExtOrderId__c <> null limit 1];
    	if(lstRevItem.isEmpty()) return null;
    	Rev__c rev = lstRevItem.get(0);
    	DateTime dToday = System.now();
    	Dart6_ReportService.Statement statement = new Dart6_ReportService.Statement();
        statement.query = 'WHERE ORDER_ID = ' + rev.ExtOrderId__c+' AND LINE_ITEM_ID = ' + rev.ExtLineItemId__c;
        Dart6_ReportService.ReportQuery reportQuery = new Dart6_ReportService.ReportQuery();
        reportQuery.statement = statement;
        reportQuery.dateRangeType = 'CUSTOM_DATE';
        reportQuery.columns = DeliveryController.queryFieldsDART6.get(DeliveryController.SOBJECT_REVENUE_ITEM);
        reportQuery.dimensions = DeliveryController.dimensionFieldsDART6.get(DeliveryController.SOBJECT_REVENUE_ITEM);
        
        reportQuery.startDate = new Dart6_ReportService.Date_x();
        reportQuery.startDate.year = dToday.year();
        reportQuery.startDate.month = dToday.month();
        reportQuery.startDate.day = dToday.day();
        
        reportQuery.endDate = new Dart6_ReportService.Date_x();
        reportQuery.endDate.year = dToday.year();
        reportQuery.endDate.month = dToday.month();
        reportQuery.endDate.day = dToday.day();
        reportQuery.dimensionAttributes = DeliveryController.dimensionAttributesDART6.get(DeliveryController.SOBJECT_REVENUE_ITEM);   

        Dart6_ReportService.ReportJob reportJob = new Dart6_ReportService.ReportJob();
        reportJob.reportQuery = reportQuery;
        return reportJob;
    }
    
    /**
     * Get Chart Data for all lineItems 
     * @param oppItem, OpportunityLineItem
     * @return RemoteResponse
     */
     @AuraEnabled 
    public static RemoteResponse getLineItemsChart(String oppId){
    	try{
    		RemoteResponse response = new RemoteResponse();
    		Map<String, ChartSerie[]> mapDataSet = new Map<String, ChartSerie[]>();
    		List<Date> metricDate = new List<Date>();
    		List<String> lstRevDelv = new List<String>();
    		List<String> lstRevExp = new List<String>();
    		List<String> lstImprs  = new List<String>();
    		List<String> lstClicks = new List<String>();
    		List<String> lstOsi = new List<String>();
    		List<String> lstClickRate = new List<String>();
    		List<String> lstViewImprs = new List<String>();
    		List<String> lstViewImprsRate = new List<String>();
    		
    		Map<Date, AggregateResult> mapData = new Map<Date, AggregateResult>();
    		for(AggregateResult agr : [Select MetricDate__c matDt, sum(RevenueExpected__c) revExp, sum(RevenueDelivered__c) revDelv, sum(AD_Clicks__c) adClicks, sum(AD_Impressions__c) adImprs, sum(AD_OSI__c) adOsi, sum(AD_Click_Rate__c) adClickRate, sum(AD_Active_View_Viewable_Impressions__c) viewImprs, sum(AD_Active_View_Viewable_Impressions_Rate__c) viewImprsRate  From Metric__c Where Rs__r.Rev__r.Opportunity__c =: oppId Group By MetricDate__c Order By MetricDate__c ASC]){	
				metricDate.add(Date.valueOf(agr.get('matDt')));
				lstRevDelv.add(String.valueOf(agr.get('revDelv')));    
				lstRevExp.add(String.valueOf(agr.get('revExp')));
				lstImprs.add(String.valueOf(agr.get('adImprs')));
				lstClicks.add(String.valueOf(agr.get('adClicks')));
				lstOsi.add(String.valueOf(agr.get('adOsi')));
				lstClickRate.add(String.valueOf(agr.get('adClickRate')));
				lstViewImprs.add(String.valueOf(agr.get('viewImprs')));
				lstViewImprsRate.add(String.valueOf(agr.get('viewImprsRate')));
    		}
    		//DataSet for revenue
    		mapDataSet.put('Revenue', getRevenueChartSeries(lstRevExp,lstRevDelv, null));
    		//Dataset for Delivery
    		mapDataSet.put('Delivery', getDeliveryChartSeries(lstImprs, lstClicks, lstOsi, null));
    		//Dataset Performance
    		mapDataSet.put('Performance', getPerformanceChartSeries(lstClickRate, lstViewImprs, lstViewImprsRate, null));
    		
    		List<Object> contents = new List<Object>();
    		contents.add(metricDate);
    		contents.add(mapDataSet);
    		response.content = contents;  
            response.statusCode = RemoteResponse.STATUSCODE_OK;
    		return response;
    	}catch(exception e){
    		return new RemoteResponse(e.getMessage() + '\n' +e.getStackTraceString(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
    
    /**
     *Chart series of Revenue
     *@param lstRevExp, lstViewImprs, lstRevDelv
     *@return List<ChartSerie> type revneue
     */
    private static List<ChartSerie> getRevenueChartSeries(List<String> lstRevExp, List<String> lstRevDelv, String adName){
		List<ChartSerie> revChartSeries = new List<ChartSerie>();
		revChartSeries.add(new ChartSerie('line', (adName==null?'Revenue Expected':'Revenue Expected (' + adName +')'), lstRevExp, 'y-axis-0'));
		revChartSeries.add(new ChartSerie('line', (adName==null?'Revenue Delivered':'Revenue Delivered (' + adName +')'), lstRevDelv, 'y-axis-0'));
    	return revChartSeries;
    }
    
    /**
     *Chart series of Deliveries
     *@param lstRevExp, lstViewImprs, lstRevDelv
     *@return List<ChartSerie> type Delivery
     */
    private static List<ChartSerie> getDeliveryChartSeries(List<String> lstImprs, List<String> lstClicks, List<String> lstOsi, String adName){
    	List<ChartSerie> delvChartSeries = new List<ChartSerie>();
		delvChartSeries.add(new ChartSerie('line', (adName==null?'Ad Impressions':'Ad Impressions (' + adName +')') , lstImprs, 'y-axis-0'));
		delvChartSeries.add(new ChartSerie('bar', (adName==null?'Ad Clicks':'Ad Clicks (' + adName +')') , lstClicks, 'y-axis-1'));
		delvChartSeries.add(new ChartSerie('line', (adName==null?'Ad OSI':'Ad OSI (' + adName +')') , lstOsi, 'y-axis-0'));
		return delvChartSeries;
    }
    /**
     *@param listClickRate, lstViewImprs, lstViewImprsRate
     *@return List<ChartSerie> type performance
     */
    private static List<ChartSerie> getPerformanceChartSeries(List<String> lstClickRate, List<String> lstViewImprs, List<String> lstViewImprsRate, String adName){
    	List<ChartSerie> perfChartSeries = new List<ChartSerie>(); 
		perfChartSeries.add(new ChartSerie('line', (adName==null?'AD Click Rate (%)':'AD Click Rate (%) (' + adName +')') , lstClickRate, 'y-axis-0'));
		perfChartSeries.add(new ChartSerie('line', (adName==null?'AD Active View Viewable Impressions':'AD Active View Viewable Impressions (' + adName +')') , lstViewImprs, 'y-axis-0'));
		perfChartSeries.add(new ChartSerie('bar', (adName==null?'AD Active View Viewable Impressions Rate':'AD Active View Viewable Impressions Rate (' + adName +')'), lstViewImprsRate, 'y-axis-1'));
		return perfChartSeries;
    	
    }
    
    @AuraEnabled 
    public static RemoteResponse getDataCompareChart(List<String> itemIds){
    	try{
    		Map<String, String> mapItem = getMappingItemName(itemIds);
    		RemoteResponse response = new RemoteResponse();
    		Map<String, List<Metric__c>> mapMetrics = new Map<String, List<Metric__c>>();
    		Map<String, ChartSerie[]> mapDataSet = new Map<String, ChartSerie[]>();
    		Set<Date> metricDate = new Set<Date>();
    		Map<String, List<Date>> mapMetricDate = new Map<String, List<Date>>();
    		List<Metric__c> lstMetrics = [Select Id, MetricDate__c, RevenueExpected__c, RevenueDelivered__c, AD_Clicks__c, AD_Impressions__c, AD_Click_Rate__c,  AD_OSI__c, AD_Active_View_Viewable_Impressions__c, Rs__r.Rev__r.OrigOpportunityLineItemId__c, AD_Active_View_Viewable_Impressions_Rate__c, Rs__r.Opportunity__r.Name From Metric__c Where Rs__r.Rev__r.OrigOpportunityLineItemId__c IN: itemIds Order By MetricDate__c ASC];
    		if(lstMetrics.isEmpty()) return response;
    		for(Metric__c mt : lstMetrics){
    			metricDate.add(mt.MetricDate__c);
    			if(!mapMetrics.containsKey(mt.Rs__r.Rev__r.OrigOpportunityLineItemId__c)) mapMetrics.put(mt.Rs__r.Rev__r.OrigOpportunityLineItemId__c, new List<Metric__c>());
    			mapMetrics.get(mt.Rs__r.Rev__r.OrigOpportunityLineItemId__c).add(mt);
    			if(!mapMetricDate.containsKey(mt.Rs__r.Rev__r.OrigOpportunityLineItemId__c)) mapMetricDate.put(mt.Rs__r.Rev__r.OrigOpportunityLineItemId__c, new List<Date>());
    			mapMetricDate.get(mt.Rs__r.Rev__r.OrigOpportunityLineItemId__c).add(mt.MetricDate__c);
    			
    		}
    		List<Date> lstStrDate = new List<Date>();
    		for(Date dt : metricDate) lstStrDate.add(dt);

    		Date minDate  = lstStrDate.get(0);
    		Date maxDate = lstStrDate[lstStrDate.size()-1];
    		List<ChartSerie> revChartSeries = new List<ChartSerie>();
    		List<ChartSerie> delvChartSeries = new List<ChartSerie>();
    		List<ChartSerie> perfChartSeries = new List<ChartSerie>();
			
    		for(String key : mapMetrics.keySet()){
    			List<String> lstRevExp = new List<String>();
            	List<String> lstRevDelv = new List<String>();
            	List<String> lstImprs  = new List<String>();
	    		List<String> lstClicks = new List<String>();
	    		List<String> lstOsi = new List<String>();
	    		List<String> lstClickRate = new List<String>();
	    		List<String> lstViewImprs = new List<String>();
	    		List<String> lstViewImprsRate = new List<String>();
				
    			for(Metric__c mt : mapMetrics.get(key)){
	    				lstRevExp.add(mt.RevenueExpected__c+'');
	    				lstRevDelv.add(mt.RevenueDelivered__c+'');
	    				lstImprs.add(mt.AD_Impressions__c+'');
						lstClicks.add(mt.AD_Clicks__c+'');
						lstOsi.add(mt.AD_OSI__c+'');
						lstClickRate.add(mt.AD_Click_Rate__c+'');
						lstViewImprs.add(mt.AD_Active_View_Viewable_Impressions__c+'');
						lstViewImprsRate.add(mt.AD_Active_View_Viewable_Impressions_Rate__c+'');
    			}
    			
    			//set 0 value to that not match with matricdate
    			for(Integer i=0 ; i< minDate.daysBetween(mapMetricDate.get(key).get(0)); i++){
    					lstRevExp.add(i,'0');
	    				lstRevDelv.add(i,'0');
	    				lstImprs.add(i,'0');
						lstClicks.add(i,'0');
						lstOsi.add(i,'0');
						lstClickRate.add(i,'0');
						lstViewImprs.add(i,'0');
						lstViewImprsRate.add(i,'0');
    			}
    			
    			for(Integer i=0 ; i< maxDate.daysBetween(mapMetricDate.get(key).get(mapMetricDate.get(key).size()-1)); i++){
    					lstRevExp.add('0');
	    				lstRevDelv.add('0');
	    				lstImprs.add('0');
						lstClicks.add('0');
						lstOsi.add('0');
						lstClickRate.add('0');
						lstViewImprs.add('0');
						lstViewImprsRate.add('0');
    			}
				revChartSeries.addAll(getRevenueChartSeries(lstRevExp,lstRevDelv, mapItem.get(key)));
				delvChartSeries.addAll(getDeliveryChartSeries(lstImprs, lstClicks, lstOsi, mapItem.get(key)));
				perfChartSeries.addAll(getPerformanceChartSeries(lstClickRate, lstViewImprs, lstViewImprsRate, mapItem.get(key)));
    		}
    		mapDataSet.put('Revenue', revChartSeries);
    		mapDataSet.put('Delivery', delvChartSeries);
    		mapDataSet.put('Performance', perfChartSeries);
    		List<Object> lstObj = new List<Object>();
    	    lstObj.add(metricDate);
    	    lstObj.add(mapDataSet);
    	    
            response.content = lstObj;  
            response.statusCode = RemoteResponse.STATUSCODE_OK;
	        return response;
    		
    	}catch(exception e){
    		return new RemoteResponse(e.getMessage() + '\n' +e.getStackTraceString(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
    
    private static Map<String, String> getMappingItemName(List<String> itemIds){
    	Map<String, String> mapItem = new Map<String, String>();
    	for(OpportunityLineItem item : [Select id, 	Ad_Name__c From OpportunityLineItem Where Id IN:itemIds]){
    		mapItem.put(item.Id, item.Ad_Name__c);
    	}
    	return mapItem;
    }
    
    /**
     * Chart wrapper class
     */
    public class ChartSerie{
    	@AuraEnabled
    	public String chartType;
    	@AuraEnabled
    	public String label;
    	@AuraEnabled
    	public String[] chartData;
    	@AuraEnabled
    	public String yAxesGroup;
    	
    	public ChartSerie(String chartType, String label, String[] chartData, String yAxesGroup){
    		this.chartType = chartType;
    		this.label = label;
    		this.chartData = chartData;
    		this.yAxesGroup = yAxesGroup;
    	}
    }
}