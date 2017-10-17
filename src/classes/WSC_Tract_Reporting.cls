/**
* Created by jeze on 5/1/2017. 
*/

global class WSC_Tract_Reporting {
    
    public static final String APINAME = 'WSC_Tract_Reporting';
    public static final String RESPONSE_SUCCESS = 'success';
    public static Webservice_Settings__c WS = Webservice_Settings__c.getInstance(APINAME + '_' + (UTIL.isSandbox() ? 'UAT' : 'PROD'));
    
    private static String importingServiceURL = UTIL.getConfig('Tract_Service_Import_URL');
    private static String importingServicePARAMS = UTIL.getConfig('Tract_Service_Import_PARAMS');
    private static String importingInvoiceURL = UTIL.getConfig('Tract_Invoice_Import_URL');
    private static String importingInvoicePARAMS = UTIL.getConfig('Tract_Invoice_Import_PARAMS'); 
    
    private static String importingInvoiceItemURL = UTIL.getConfig('Tract_Invoice_Item_Import_URL'); 
    private static String importingInvoiceItemPARAMS = UTIL.getConfig('Tract_Invoice_Item_Import_PARAMS');
    
    private static String importingRevenueScheduleURL = UTIL.getConfig('Tract_Forecast_Revenue_Import');
    private static String importingRevenueSchedulePARAMS = UTIL.getConfig('Tract_Forecast_Revenue_Import_PARAMS');
    
    private static Map<String, Datetime> mParamDate = new Map<String, Datetime>{
            'NEXT_7_DAYS'           =>  System.today().addDays(8),
            'NEXT_14_DAYS'          =>  System.today().addDays(15),
            'NEXT_2_MONTHS'         =>  System.today().addMonths(3).toStartOfMonth(),
            'NEXT_MONTH'            =>  System.today().addMonths(2).toStartOfMonth(),
            'TODAY'                 =>  System.today().addDays(1),
            'LAST_7_DAYS'           =>  System.today().addDays(-7),
            'LAST_14_DAYS'          =>  System.today().addDays(-14),
            'LAST_21_DAYS'          =>  System.today().addDays(-21),
            'LAST_42_DAYS'          =>  System.today().addDays(-42),
            'LAST_49_DAYS'          =>  System.today().addDays(-49),
            'LAST_MONTH'            =>  System.today().addMonths(-1).toStartOfMonth(),
            'LAST_2_MONTHS'         =>  System.today().addMonths(-2).toStartOfMonth(),
            'LAST_3_MONTHS'         =>  System.today().addMonths(-3).toStartOfMonth()
    };
    
   private static String getReplaceDateParam(String param){
            if(String.isBlank(param)) UTIL.throwError('Configuration '+param+' is required.');
            for(String key : mParamDate.keySet()){
                param = param.replaceAll(key, String.valueOf(mParamDate.get(key).format('yyyy-MM-dd')));
            }
            return param;
    }
    
    //////////////////////// TRACT Services ////////////////////////////
    public class GetServices extends ApiRequest {
        
        public override void init(Id contextRecordId){
            this.setCalloutDetails('GetServices', APINAME);
            super.init(contextRecordId);
            this.setResultClass(APINAME + '.ApiResult');
            this.setHandlerClass(APINAME + '.GetServices_Handler');
            
            List<Opportunity>opps = (List<Opportunity>)GW_sObject.queryRecords('Opportunity', new Set<Id>{contextRecordId}, new List<String>{'Billing_Account__r.Tract_AccountId__c', '(Select External_Id__c From Services__r)'});
            Opportunity opp = opps[0];
            
            Datetime campaigntart = opp.CampaignStart__c;
            Datetime campaignEnd = opp.CampaignEnd__c;
           
            String endPoint = '';
            Util.log('GetServices-baseEndpoint----> ' + this.baseEndpoint);
            if( this.baseEndpoint != null ){
                if(String.isBlank(importingServiceURL)) UTIL.throwError('Configuration Tract_Service_Import_URL is required');
                endpoint = this.baseEndpoint + importingServiceURL;
                
                if( !String.isBlank( this.endpointURLParameters ) ){
                    endpoint += this.endpointURLParameters; 
                }
                
                endpoint += '&'+ getReplaceDateParam(importingServicePARAMS);
				
				endpoint = endpoint.replace('TRACT_ACCOUNT_ID', opp.Billing_Account__r.Tract_AccountId__c);
				if(!opp.Services__r.isEmpty()) endpoint = endpoint.replace('TRACT_SERVICE_ID', opp.Services__r[0].External_Id__c);
				else endpoint = endpoint.replace('&P_SERVICE_ID=TRACT_SERVICE_ID', '');
                
                endpoint = endpoint.replace('CAMPAIGN_START_DATE', campaigntart.format('yyyy-MM-dd')).replace('CAMPAIGN_END_DATE', campaignEnd.format('yyyy-MM-dd'));
            }
            
            this.setEndpoint( endpoint );
            UTIL.log('GetServices-baseEndpoint----> ' + endpoint );
            this.setHttpMethod('GET');
        }
        
        public override String getBody() {
            Map<String,Object> output = this.mapper.getOutputMap();
            if (output!=null) {
                return JSON.serialize(output);
            }
            return null;
        }

        public override String getFormattedBody() {
            Map<String,Object> output = this.mapper.getOutputMap();
            if (output!=null) {
                return JSON.serializePretty(output);
            }
            return null;
        }
    }

    public class GetServices_Handler extends ApiHandler{
        public override void handle() {
            super.handle();

            if( result.StatusCode == 201 || result.statusCode == 200 ){
                List<List<String>> parsedCSV = (List<List<String>>) result.getResponseData().get('results');
                UTIL_WSC_Tract.TRACTServiceSync service = new UTIL_WSC_Tract.TRACTServiceSync(parsedCSV);
                service.commitAll();
            }
            else if(this.result.statusCode != UTIL_WSC.HTTP_CREATED) {
                UTIL.logClean('WSC_Tract Unknown error, result: ' + this.result);
                Map<String,Object> response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract Unknown error');
            }
            else {
                UTIL.logClean('Error getting response from server - no response received.');
                Map<String,Object> response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract No response received from service.');
            }

        }
    } //End Service
	
    //////////////////////// TRACT Invoices /////////////////////////// 
    public static Map<Id, Map<String, TRACT_Invoice__c>> mapAccountTractInvoices = new Map<Id, Map<String, TRACT_Invoice__c>>();
    
    public static void commitAllInvoices(Set<Id> contextRecordIds, Map<Id, String> mCurrencyCode) {
        List<TRACT_Invoice__c> commitList = new List<TRACT_Invoice__c>();
        UTIL.log('commitAllInvoices + mapAccountTractInvoices---- ' + mapAccountTractInvoices);
        for (Id contextRecordId : contextRecordIds) {
            if (!mapAccountTractInvoices.containsKey(contextRecordId)) continue;
            for (TRACT_Invoice__c invoiceRec : mapAccountTractInvoices.get(contextRecordId).values()) {
                invoiceRec.CurrencyIsoCode = mCurrencyCode.get(contextRecordId);
                commitList.add(invoiceRec);
            }
        }
        upsert commitList External_Id__c;
        delete [Select Id From TRACT_Invoice__c Where Billing_Account__c IN: contextRecordIds And Id NOT IN: commitList];
        mapAccountTractInvoices = new Map<Id, Map<String, TRACT_Invoice__c>>();
    }
    
    public class GetInvoices extends ApiRequest {
        public override void init(Id contextRecordId){
            this.setCalloutDetails('GetInvoices', APINAME);
            super.init(contextRecordId);
            
            Account acc = (Account) this.contextRecord;
            this.setResultClass(APINAME + '.ApiResult');
            this.setHandlerClass(APINAME + '.GetInvoices_Handler');
            String endPoint = '';
            if( this.baseEndpoint != null ){
                if(String.isBlank(importingInvoiceURL)) UTIL.throwError('Configuration "Tract_Invoice_Import_URL" is required');
                endpoint = this.baseEndpoint + importingInvoiceURL;
                if( !String.isBlank( this.endpointURLParameters ) ){
                    endpoint += this.endpointURLParameters; 
                }
            }
            
            if(String.isNotBlank(importingInvoicePARAMS)){
                importingInvoicePARAMS = importingInvoicePARAMS.replaceAll('CONTEXT_RECORD_ID', acc.Tract_AccountId__c);
                endpoint += '&' + getReplaceDateParam(importingInvoicePARAMS);
            }
            
            this.setEndpoint(endpoint);
            UTIL.log('GetInvoice_Endpoint__: ' + endpoint );
            this.setHttpMethod('GET');
        }
        
        public override String getBody() {
            Map<String,Object> output = this.mapper.getOutputMap();
            if (output!=null) {
                return JSON.serialize(output);
            }
            return null;
        }

        public override String getFormattedBody() {
            Map<String,Object> output = this.mapper.getOutputMap();
            if (output!=null) {
                return JSON.serializePretty(output);
            }
            return null;
        }
        
        public override void createWsLogs() {
            this.uniqueCalloutId = 'Get_Invoice_Report_'+this.contextRecord.Id + Datetime.now().format('dd-MM-yyyy HH:mm:ss');
            super.createWsLogs();
        }
    }

    public class GetInvoices_Handler extends ApiHandler{
        public override void handle() {
            super.handle();
            Account acc = (Account) this.request.contextRecord;
            
            UTIL.log('GetInvoices_Handler : ' + this.result);
            if( result.StatusCode == 201 || result.statusCode == 200 ) {
                List<List<String>> parsedCSV = (List<List<String>>) result.getResponseData().get('results');
                UTIL_WSC_Tract.TRACTInvoiceSync tractInvoice = new UTIL_WSC_Tract.TRACTInvoiceSync(parsedCSV);
                for (TRACT_Invoice__c invoice : tractInvoice.mapTractInvoices.values()) {
                    if (!mapAccountTractInvoices.containsKey(invoice.Billing_Account__c)) {
                        mapAccountTractInvoices.put(invoice.Billing_Account__c, new Map<String, TRACT_Invoice__c>());
                    }
                    mapAccountTractInvoices.get(invoice.Billing_Account__c).put(invoice.External_Id__c, invoice);
                }

            } else if (this.result.statusCode != UTIL_WSC.HTTP_CREATED) {
                UTIL.logClean('WSC_Tract_Reporting Unknown error, result: ' + this.result);
                Map<String,Object> response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract_Reporting Unknown error');
            } else {
                UTIL.logClean('Error getting response from server - no response received.');
                Map<String,Object> response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract_Reporting No response received from service.');
            }
        }
    }

    //////////////////////// TRACT InvoiceItems ////////////////////////////
    
    public static Map<String, TRACT_Invoice_Item__c> mapAccountTractInvoiceItems = new Map<String, TRACT_Invoice_Item__c>();
    
    public static void commitAllInvoiceItems() {
        //Populate set Line Item Id
		Set<String> setLineItemIds = new Set<String>();
		for ( TRACT_Invoice_Item__c invline : mapAccountTractInvoiceItems.values() ) setLineItemIds.add(invline.Opportunity_Line_Item_ID__c);
		
		//Get Product Id from Opportunity Product
		Map<Id, OpportunityLineItem> mLineItem = new Map<Id, OpportunityLineItem>([Select Id, PricebookEntry.Product2Id From OpportunityLineItem Where Id IN: setLineItemIds]);
		
		//Link TRACT_Invoice_Item__c to Product2
		for ( TRACT_Invoice_Item__c invline : mapAccountTractInvoiceItems.values() ) {
			OpportunityLineItem oppLine = mLineItem.get(invline.Opportunity_Line_Item_ID__c);
			if ( oppLine == null ) continue;
			invline.Product_Name__c = oppLine.PricebookEntry.Product2Id;
		}
    	
        upsert mapAccountTractInvoiceItems.values() External_Id__c;
        mapAccountTractInvoiceItems = new Map<String, TRACT_Invoice_Item__c>();
    }
    
    public class GetInvoiceItems extends ApiRequest {
        public override void init(Id contextRecordId){
            this.setCalloutDetails('GetInvoiceItems', APINAME);
            super.init(contextRecordId);
            
            this.setResultClass(APINAME + '.ApiResult');
            this.setHandlerClass(APINAME + '.InvoiceItems_Handler');
            
            List<OpportunityLineItem>lstLineItems = (List<OpportunityLineItem>)GW_sObject.queryRecords('OpportunityLineItem', new Set<Id>{contextRecordId}, new List<String>{'Opportunity.Billing_Account__r.Tract_AccountId__c'});
            
            String endPoint = '';
            if( this.baseEndpoint != null ){
                if(String.isBlank(importingInvoiceItemURL)) UTIL.throwError('Configuration "Tract_Invoice_Item_Import_URL" is required');
                endpoint = this.baseEndpoint + importingInvoiceItemURL;
                
                if( !String.isBlank( this.endpointURLParameters ) ){
                    endpoint += this.endpointURLParameters; 
                }
            }
            
            if(String.isNotBlank(importingInvoiceItemPARAMS)){
                if(!lstLineItems.isEmpty() && lstLineItems[0].Opportunity.Billing_Account__r.Tract_AccountId__c != null) importingInvoiceItemPARAMS = importingInvoiceItemPARAMS.replace('TRACT_ACCOUNT_ID', lstLineItems[0].Opportunity.Billing_Account__r.Tract_AccountId__c);
                importingInvoiceItemPARAMS = importingInvoiceItemPARAMS.replace('CONTEXT_RECORD_ID', contextRecordId);
                endpoint += '&' + getReplaceDateParam(importingInvoiceItemPARAMS);
            }
            
            this.setEndpoint( endpoint );
            UTIL.log('GetItems_Endpoint__: ' + endpoint );
            
            this.setHttpMethod('GET');
        }
        
        public override String getBody() {
            Map<String,Object> output = this.mapper.getOutputMap();
            if (output!=null) {
                return JSON.serialize(output);
            }
            return null;
        }

        public override String getFormattedBody() {
            Map<String,Object> output = this.mapper.getOutputMap();
            if (output!=null) {
                return JSON.serializePretty(output);
            }
            return null;
        }
    }

    public class InvoiceItems_Handler extends ApiHandler{ 
        public override void handle() {
            super.handle();
            
            UTIL.log('InvoiceItems_Handler : ' + this.result);
            if( result.StatusCode == 201 || result.statusCode == 200 ) {
                List<List<String>> parsedCSV = (List<List<String>>) result.getResponseData().get('results');
                
                UTIL_WSC_Tract.TRACTInvoiceItemSync tractInvoiceItem = new UTIL_WSC_Tract.TRACTInvoiceItemSync(parsedCSV);
                
                for (TRACT_Invoice__c inv : [Select Id, CurrencyIsoCode, Currency_Code__c, External_Id__c From TRACT_Invoice__c Where External_Id__c IN: tractInvoiceItem.mInvvsInvoiceItem.keySet()]) {
                    if (!tractInvoiceItem.mInvvsInvoiceItem.containsKey(inv.External_Id__c)) continue;
                    for (TRACT_Invoice_Item__c invItem : tractInvoiceItem.mInvvsInvoiceItem.get(inv.External_Id__c)) {
                        
                        //Tmp solution in sf, these values should be given by the Tract Reporting Service
                        invItem.CurrencyIsoCode = inv.CurrencyIsoCode != null ? inv.CurrencyIsoCode : inv.Currency_Code__c;
                        invItem.Quantity__c = invItem.Quantity__c == 0 ? 1 : invItem.Quantity__c;
                        invItem.End_Date__c = invItem.End_Date__c == invItem.End_Date__c.toStartOfMonth() ? invItem.End_Date__c.addDays(-1) : invItem.End_Date__c;
                        
                        invItem.TRACT_Invoice__c = inv.Id;
                        mapAccountTractInvoiceItems.put(invItem.External_Id__c, invItem);
                    }
                }
            } else if (this.result.statusCode != UTIL_WSC.HTTP_CREATED) {
                UTIL.logClean('WSC_Tract_Reporting.InvoiceItems_Handler Unknown error, result: ' + this.result);
                Map<String,Object> response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract_Reporting.InvoiceItems_Handler Unknown error');
            } else {
                UTIL.logClean('Error getting response from server - no response received.');
                Map<String,Object> response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract_Reporting.InvoiceItems_Handler No response received from service.');
            }
        }
    }
    
    //////////////////////// TRACT RevenueSchedule ////////////////////////////
    public class GetRevenueSchedule extends ApiRequest {
        
        public override void init(Id contextRecordId){
            this.setCalloutDetails('GetRevenueSchedule', APINAME);
            super.init(contextRecordId);
            
            TRACT_Service__c ts = (TRACT_Service__c) this.contextRecord;
            
            List<TRACT_Service__c>lstTS = (List<TRACT_Service__c>)GW_sObject.queryRecords('TRACT_Service__c', new Set<Id>{ts.Id}, new List<String>{'Billing_Account__r.Tract_AccountId__c'});
            
            this.setResultClass(APINAME + '.ApiResult');
            this.setHandlerClass(APINAME + '.RevenueSchedule_Handler');

            String endPoint = '';
            if( this.baseEndpoint != null ){
                    if(String.isBlank(importingRevenueScheduleURL)) UTIL.throwError('Configuration Tract_Forecast_Revenue_Import is required.');
                    endpoint = this.baseEndpoint + importingRevenueScheduleURL;
                    
                    if( !String.isBlank( this.endpointURLParameters ) ){
                    endpoint += this.endpointURLParameters; 
                }
            }
            
            if(!lstTS.isEmpty()) endpoint += '&' + importingRevenueSchedulePARAMS.replace('TRACT_ACCOUNT_ID', lstTS[0].Billing_Account__r.Tract_AccountId__c).replace('TRACT_SERVICE_ID', ts.External_Id__c);
            
            this.setEndpoint( endpoint );
            UTIL.log('GetRevenue_Endpoint__: ' + endpoint );
            
            this.setHttpMethod('GET');
        }
        public override String getBody() {
            Map<String,Object> output = this.mapper.getOutputMap();
            if (output!=null) {
                return JSON.serialize(output);
            }
            return null;
        }

        public override String getFormattedBody() {
            Map<String,Object> output = this.mapper.getOutputMap();
            if (output!=null) {
                return JSON.serializePretty(output);
            }
            return null;
        }

        public override HttpResponse getMockResponse() { 
            HttpResponse response = new HttpResponse();
            String resBODY = 'Tract Account Id,Tract Account Number,SF Account ID,Product Name,Tract Order Id,Tract Order Number,Order Item Id,Amount,Delivery Indicator,Campaign Value,Month,Year,Actual Revenue,Expected Revenue,Forecast Revenue,Type,Order Status,Agreement End Action,Agreement End Date,Approval Date'+
                                '\n566,GTZ00001,,Autos - GAIT - Select 150 Ad Package,2604,210061316,5693,"18,035.00",,,8,2017,0.00,"18,035.00","18,035.00",Subscription,DRAFT,,31-07-2018,,'+
                                '\n566,GTZ00001,,Autos - GAIT - Select 150 Ad ';
            response.setStatusCode(200);
            response.setBody(resBODY);
            response.setStatus('OK');
            return response; 
        }
    }

    public class RevenueSchedule_Handler extends ApiHandler{
        public override void handle() {
            super.handle();
            
            UTIL.log('RevenueSchedule_Handler : ' + this.result);
            if( result.StatusCode == 201 || result.statusCode == 200 ) {
                List<List<String>> parsedCSV = (List<List<String>>) result.getResponseData().get('results');
                UTIL_WSC_Tract.TRACTRevenueScheduleSync tractrs = new UTIL_WSC_Tract.TRACTRevenueScheduleSync(parsedCSV);
                //tractrs.commitAll();
            } else if (this.result.statusCode != UTIL_WSC.HTTP_CREATED) {
                UTIL.logClean('WSC_Tract_Reporting:RevenueSchedule_Handler Unknown error, result: ' + this.result);
                Map<String,Object> response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract_Reporting:RevenueSchedule_Handler Unknown error');
            } else {
                UTIL.logClean('Error getting response from server - no response received.');
                Map<String,Object> response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract_Reporting:RevenueSchedule_Handler No response received from service.');
            }
        }
    }

    public virtual class ApiRequest extends UTIL_WSC.WSC_Request {
        public virtual override void init(Id contextRecordId) {
            super.init(contextRecordId);
            this.setHeader('Content-Type', 'text/csv');
            this.getWsSettings(APINAME,null);
            this.setHeader('Authorization', 'Basic ' + this.wsKeystring);
        }
        
        public virtual override void createWsLogs() {
            super.createWsLogs();
        }
    }

    public virtual class ApiResult extends UTIL_WSC.WSC_Result {
        public override String getFormattedBody(){ return null; }

        public override Map<String,Object> getResponseData(){
            try {
                system.debug('RESPONSE_BODY : '+resp.getBody());
                return new Map<String, List<List<String>>>{'results' => UTIL_WSC_Tract.parseCSV(resp.getBody(), false)  };
            } catch (Exception e) {
                String errorMsg = 'Error processing response data. ' +e.getMessage()+' '+e.getTypeName()+ '\n';
                Map<String, Object> responseData = new Map<String,Object>();
                responseData.put('catalystError', e.getMessage());
                responseData.put('body', resp.getBody());
                responseData.put('catalystMessage', errorMsg);
                return responseData;
            }
        }

    }

    public virtual class ApiHandler extends UTIL_WSC.WSC_ResultHandler {
        public virtual override void handle() {
            super.handle();
            if(this.result.success == FALSE) {
                String errorMessage = '';
                Map<String, Object> responseData = (this.result.getResponseData() != null) ? this.result.getResponseData() : new Map<String, Object>();
                if (responseData.containsKey('catalystError')) {
                    errorMessage += (String) responseData.get('ERROR');
                }
                if (responseData.containsKey('catalystMessage')) {
                    errorMessage += (String) responseData.get('message');
                }

                if(errorMessage.length() > 0) {
                    logError(errorMessage);
                } else {
                    logError('No response.');
                }
            }
        }
    }
    // END ApiHandler
}