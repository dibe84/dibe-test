/**
 * Created by rvannierop on 2/21/2017.
 * @change log
 *		GIS - DEV - 09/May/2017
 */

global class BAT_ProductImportFromTRACT implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, UTIL_CustomJob.ICustomJob {
    String whereClause;
    CustomJob__c cjob;
    
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
    global Datetime executeStart;
    
    Set<String> setPriceListIds = new Set<String>();
    String pageNum = '1';
    String currentPriceListId;
    Boolean isNextExecution = false;
    
    global BAT_ProductImportFromTRACT() {
        whereClause = 'Name = \'BAT_ProductImportFromTRACT\' AND Active__c = true';
        
        List<PriceBook2> priceBooks = GW_sObject.queryRecords('PriceBook2', 'Tract_Id__c <> NULL AND IsActive = TRUE');
        for (PriceBook2 pb : priceBooks) {
        	setPriceListIds.add(pb.Tract_Id__c);
        	//break;
        }
        readyForRun = true;
    }
    
    global BAT_ProductImportFromTRACT(Set<String> setPriceListIds, String currentPriceListId, String pageNum) {
        this.setPriceListIds = setPriceListIds;
        this.currentPriceListId = currentPriceListId;    
        this.pageNum = pageNum;
    }
    
    global List<CustomJob__c> start(Database.BatchableContext BC) { 
        return GW_sObject.queryRecords('CustomJob__c', whereClause);
    }
    
    global void execute(Database.BatchableContext BC, List<CustomJob__c> scope) {
        cjob = scope[0];
        
        if ( currentPriceListId == null ) {
        	for (String nextPriceListId : setPriceListIds) {
        		currentPriceListId = nextPriceListId;
        		//break;
        	}
        }
        
        try {
	        UTIL_WSC.WSC_Request wsRequest = UTIL_WSC.getWSC_Request('WSC_Tract.ProductSync');
	        wsRequest.mAdditionalParams.put('page_number', pageNum+'');
	        wsRequest.mAdditionalParams.put('price_list_id', currentPriceListId); 
	        wsRequest.init(scope[0].Id);
	        UTIL_WSC.WSC_Result resp = wsRequest.call();
	        List<Object> tractProductsObjects = (List<Object>) resp.getResponseData().get('results');
	        if ( tractProductsObjects.isEmpty() ) {
	        	setPriceListIds.remove(currentPriceListId);
	        	pageNum = '0';
	        	currentPriceListId = null;
	        }
	        
	        isNextExecution = ( !setPriceListIds.isEmpty() ) ? true : false;
        } catch (Exception ex) {
        	if(!Test.isRunningTest()) UTIL.throwError('BAT_ProductImportFromTRACT - Error ',ex);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        Integer nexPage = Integer.valueOf(pageNum)+1;
        if(Test.isRunningTest()) return;
        if (isNextExecution) Database.executeBatch(new BAT_ProductImportFromTRACT(setPriceListIds, currentPriceListId, nexPage+''));
    }
}