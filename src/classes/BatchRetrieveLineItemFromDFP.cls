/**
 * @created date: 15-06-2015
 * @autor: Chr
 * @desc: Get the following fields from each ad-line in Dfp and store in Oppline in SF
 *      Start Time --> save in externalFromDate__c
 *      End Time --> save in externalEndDate__c
 *      Quantity --> save in externalQuantity__c
 *      Rate type --> save in externalBillngCategory__c
 *      Rate --> save in externalSalesPrice__c
 *  When finish batch save log to Dart_Delivery_Support__c as attachement file
 */

Global virtual class BatchRetrieveLineItemFromDFP implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallOuts{
    
    private String soqlQeury='';
    //Ads Object(including lineItem's fields)
    private DART_Delivery_Support__c dds;
    private String errorMsg='';
    private Integer numScope=0;
    private String messageBody ='';
    private Integer numRecordUpdated=0;
    /**
     * Constructor
     */
    public BatchRetrieveLineItemFromDFP(){
        soqlQeury = 'Select Id, Ad_Id__c, ExternalBillngCategory__c, ExternalEndDate__c, ExternalFromDate__c, ExternalQuantity__c, ExternalSalesPrice__c, PricebookEntry.Product2.Site__r.Name,'+
                    ' PriceBookEntry.Product2.Site__r.Country__c, PricebookEntry.Product2.RecordType.Name ' + 
                    ' From OpportunityLineItem Where Ad_Id__c!=null';
                            
    }
    
    public BatchRetrieveLineItemFromDFP(String adId){
        soqlQeury = 'Select Id, Ad_Id__c, ExternalBillngCategory__c, ExternalEndDate__c, ExternalFromDate__c, ExternalQuantity__c, ExternalSalesPrice__c, PricebookEntry.Product2.Site__r.Name,'+
                    ' PriceBookEntry.Product2.Site__r.Country__c, PricebookEntry.Product2.RecordType.Name ' + 
                    ' From OpportunityLineItem Where Ad_Id__c = \'' + adId + '\'';
                            
    }
    
    /**
     * Start
     * Retrieve all OpportunityLineItems with AdId != null to process
     */
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        //create new Dart_Delivery_Support__c
        List<AdServer_Login__c> lstLogin = [Select Id, Network_ID__c From AdServer_Login__c Where  Active__c=true And isDeleted=false And Network_ID__c <> null];
        dds = new DART_Delivery_Support__c(
                Schedule_Type__c = 'Retrieve LineItem From DFP',
                Sobject__c = 'Opportunity Product',
                Status__c = 'Await',
                DART_Status__c = 'IN_PROGRESS',
                AdServer_Login__c =  (!lstLogin.isEmpty()?lstLogin.get(0).id:null)
                );
        insert dds;
        return Database.getQueryLocator(soqlQeury);
    }
    
    /**
     * Execute batch
     */  
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        numScope++;
        List<DARTObject.IDARTObjectAds> lstAds = new List<DARTObject.IDARTObjectAds>();
        try{
            for(Sobject sobj : scope){
                OpportunityLineItem oppItem = (OpportunityLineItem)sobj; 
                RetrieveLineItemFromDFPController retrieveCon = new RetrieveLineItemFromDFPController(oppItem);
                retrieveCon.retrieveLineItemValueFromDFP();
                List<DARTObject.IDARTObjectAds> lstObjtAds = retrieveCon.getObjectLineItem();
                if(!lstObjtAds.isEmpty()) lstAds.add(lstObjtAds.get(0));
            }
            
            List<OpportunityLineItem> lstItemTobeUpdated = new List<OpportunityLineItem>();
            if(!lstAds.isEmpty()){
                for(DARTObject.IDARTObjectAds objAd : lstAds){
                    OpportunityLineItem oppItem = new OpportunityLineItem(Id=objAd.getOppItemID());
                    oppItem.ExternalBillngCategory__c = objAd.getExternalBillingCategory();
                    oppItem.ExternalEndDate__c = this.getDate(objAd.getExternalEndDate()); 
                    oppItem.ExternalFromDate__c = this.getDate(objAd.getExternalFromDate());
                    oppItem.ExternalQuantity__c = objAd.getExternalQualilty();
                    oppItem.ExternalSalesPrice__c = objAd.getExternalSalePrice();
                    lstItemTobeUpdated.add(oppItem);
                }
            }
            numRecordUpdated += lstItemTobeUpdated.size();
            if(!lstItemTobeUpdated.isEmpty()) update lstItemTobeUpdated;
            //log
            //change from xx value to yy value
            //a0b9000000BCGM2AAP > [ExternalFromDate -> value, ExternalEndDate ->value, ExternalQuantity -> value, ExternalBillingCategory -> value, ExternalSalePrice -> value]
            
            //messageBody += '\n\n ';
            //item.ExternalFromDate__c.format('MM/dd/yyy K:mm a')
            for(OpportunityLineItem item : lstItemTobeUpdated){
                messageBody += '  ' + item.Id +' > [ExternalFromDate -> ' + (item.ExternalFromDate__c == null?'Unlimited':item.ExternalFromDate__c.format()) +', ExternalEndDate -> ' + (item.ExternalEndDate__c==null?'Unlimited':item.ExternalEndDate__c.format()) +
                                    ', ExternalQuantity -> ' + item.ExternalQuantity__c + ', ExternalBillingCategory -> ' + item.ExternalBillngCategory__c +
                                    ', ExternalSalePrice -> ' + item.ExternalSalesPrice__c + ']';
                messageBody += '\n';                   
            } 

        }catch(Exception ex){
            System.debug('-------------->>Error::' + ex.getStackTraceString());
            errorMsg+= 'Scope number:' + numScope +'\n' + 'ERROR:' + ex +'\n' + scope + '\n';
        }
    }
    
    /**
     * Finish batch
     * Update LineItem's fields from DFP to SP 
     *      Start Time --> save in externalFromDate__c
     *      End Time --> save in externalEndDate__c
     *      Quantity --> save in externalQuantity__c
     *      Rate type --> save in externalBillngCategory__c
     *      Rate --> save in externalSalesPrice__c
     * And log updated records to Dart_Delivery_Support__c as attachment 
     */
    global void finish(Database.BatchableContext BC){
        String allMsgBody = 'Updated records size: ' + numRecordUpdated + '\n' + messageBody +'\n'+errorMsg;
        if(numRecordUpdated==0) allMsgBody += 'There is no lineItem to be updated.';
        updateDeliveryStatus(dds, 'COMPLETED', allMsgBody);
        
    }
    
    /** update devivery status & add log to DART_Delivery_Support__c as attachment file */
    private void updateDeliveryStatus(DART_Delivery_Support__c ddsp, String ddStatus, String msgLog){
        ddsp.status__c = 'Finished';
        ddsp.DART_Status__c = ddStatus;
        update ddsp;
        //create attachement
        Attachment att = new Attachment();
        att.ParentId = dds.Id;
        att.Name = 'Logged Updated lineItems from DFP';
        att.Body = Blob.valueOf(msgLog);
        insert att;
        
    }
    
    private Date getDate(DateTime dt) {
    	return Date.newInstance(dt.year(), dt.month(), dt.day());
    }
}