/**
 * Start Import Jobs From UI
 * @CreatedDate: 17/April/2017
 * @Description: Manually fix data in the past. Import DFP Delivery for: OLI, Rev, and Metric with date range selection
 */
public with sharing class PGC_DFPImportByDateRange {
    // Page variables
    public Date startDate { get; set; }
    public Date endDate { get; set; } 
    public String sObjectType { get; set; }
    public String importType { get; set;}
    
    public List<SelectOption> getsObjectTypeOptions() {
        return new List<SelectOption>{
            new SelectOption(DeliveryController.SOBJECT_OPPPRODUCT, DeliveryController.SOBJECT_OPPPRODUCT),
            new SelectOption(DeliveryController.SOBJECT_REVENUE_ITEM, DeliveryController.SOBJECT_REVENUE_ITEM),
            new SelectOption(DeliveryController.SOBJECT_METRIC, DeliveryController.SOBJECT_METRIC)
        };
    }
    
    public List<SelectOption> getimportTypeOptions() {
        return new List<SelectOption>{
            new SelectOption(DeliveryController.DFP_DELIVERY, 'DoubleClick for publishers'),
            new SelectOption(DeliveryController.ADX_IMPORT, 'Google ad exchange')
        };
    }
    
    /**
     * Default controller: initialize start and end date
     */
    public PGC_DFPImportByDateRange() {
        sObjectType = DeliveryController.SOBJECT_METRIC;
        startDate = system.today().addDays(-1);
        endDate = system.today();
    }
    
    /**
     * Button method to start schedules and batches
     */
    public PageReference doSchImport() {
         
        // endDate can not be greater then today
        if ( endDate > system.today() ) { endDate = system.today(); }
        
        // validate the start and end date
        if(startDate > endDate || startDate > system.today()) {
            addPageMessage(ApexPages.Severity.ERROR, 'Date range is invalid');  
            return null;
        }
        
        doImport(DeliveryController.SCH_TYPE_MANUALLY);  
        return null;
    }
    
    /**
     * - Checking if it is already running
     * - Adding Apex page messages when sucesses or fails
     */
    private void doImport(String schType) { 
        try {  
            Integer numPending = [  select count() 
                                    from DART_Delivery_Support__c 
                                    where Schedule_Type__c  =   :schType 
                                        and Sobject__c      =   :sObjectType
                                        and Status__c       <>  :DeliveryController.DART_STATUS_FINISHED];
            
            //We expected all DDS are 'finished'; so we can run another, or wait until they all finish
            if (numPending > 0) {   
                addPageMessage(ApexPages.Severity.WARNING, 'Importing Delivery of '+sObjectType+' is already running.');  
                return;
            }
            DeliveryController.start(schType, sObjectType, startDate, endDate, importType); 
            addPageMessage(ApexPages.Severity.INFO, 'SUCCESS: Importing Delivery of ' + sObjectType + ' is now running in background.'); 
        } catch(Exception ex) {
            addPageMessage( ApexPages.Severity.ERROR, ('ERROR: ' + ex) );  
        }  
    }
    
    /**
     * Adding Apex page message 
     */
    private void addPageMessage (ApexPages.Severity severity, String message) {
        ApexPages.Message successMessage = new ApexPages.Message( severity, message );
        ApexPages.addMessage(successMessage);
    }   
    
    
    /** 
     * Tract Import Jobs
     */
    public void doTractServiceImport() { 
        try {  
            UTIL_CustomJob.startCustomJob('BAT_ServiceImportFromTract'); 
            addPageMessage(ApexPages.Severity.INFO, 'SUCCESS: Importing Service is now running in background.');
        } catch(Exception ex) {
            addPageMessage( ApexPages.Severity.ERROR, ('ERROR: ' + ex) );  
        }  
    }
    
    public void doTractInvoicesImport() { 
        try {  
            UTIL_CustomJob.startCustomJob('BAT_InvoicesImportFromTRACT'); 
            addPageMessage(ApexPages.Severity.INFO, 'SUCCESS: Importing Invoices is now running in background.');
        } catch(Exception ex) {
            addPageMessage( ApexPages.Severity.ERROR, ('ERROR: ' + ex) );  
        }  
    }
    
    public void doTractInvoiceItemsImport() { 
        try {  
            UTIL_CustomJob.startCustomJob('BAT_InvoiceItemsImportFromTRACT');
            addPageMessage(ApexPages.Severity.INFO, 'SUCCESS: Importing Invoice Items is now running in background.'); 
        } catch(Exception ex) {
            addPageMessage( ApexPages.Severity.ERROR, ('ERROR: ' + ex) );  
        }  
    }
    
    public void doTractRevenueForecastImport() { 
        try {  
            UTIL_CustomJob.startCustomJob('BAT_RevenueScheduleImportFromTRACT'); 
            addPageMessage(ApexPages.Severity.INFO, 'SUCCESS: Importing Revenue Forecast is now running in background.');
        } catch(Exception ex) {
            addPageMessage( ApexPages.Severity.ERROR, ('ERROR: ' + ex) );  
        }  
    }
    
    public String getServiceConfig(){
        return UTIL.getConfig('TractImportServiceJobURL');
    }
    
    public String getInvoiceConfig(){
        return UTIL.getConfig('TractImportInvoiceJobURL');
    }
    
    public String getInvoiceItemConfig(){
        return UTIL.getConfig('TractImportInvoiceItemJobURL');
    }
    
    public String getRevenueForecastConfig(){
        return UTIL.getConfig('TractImportRevenueForecastJobURL');
    }
}