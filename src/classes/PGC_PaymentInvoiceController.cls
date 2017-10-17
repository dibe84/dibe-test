public class PGC_PaymentInvoiceController {
    
    public Account thisAccount {get;set;}
    public Id currentAccId {get;set;}
    public String serviceIdSelected {get;set;}
    public String agreementIdSelected {get;set;}
    public String cloneServiceStatus {get;set;}
    public String deActiveServiceStatus {get;set;}
    public String deActivateServSpocStatus {get;set;}
    public String oppId2Deactivate {get;set;}
    public List<Service> lstServices {get;set;}
    public String invId {get;set;}
	public String windowUrl {get;set;}
	public static Boolean queryTract = TRUE;
 	Map<String, Service> mapService = new Map<String, Service>();
	public Boolean isPollerMode {get;set;}
 	private Integer MAX_POLLER_REQUEST = 5;
 	private Integer currentPoller = 0;
	
    public String terminationReason {get;set;}
    public String CUS_FIELD_TerminationReason = 'Termination Reason';
    public String selectedServiceStatus {get;set;}
    public String oliId2Deactivate {get;set;}
    public static Webservice_Settings__c WS = Webservice_Settings__c.getInstance('WSC_Tract'+ '_' + (UTIL.isSandbox() ? 'UAT' : 'PROD'));
    public PGC_PaymentInvoiceController(){
    	isPollerMode = false;
        cloneServiceStatus = '';
        deActiveServiceStatus = '';
        deActivateServSpocStatus = '';
        lstServices = new List<Service>();
        currentAccId = ApexPages.currentPage().getParameters().get('id');
	selectedServiceStatus = '';
        if(WS != null && String.isNotBlank(WS.Endpoint__c) && String.isNotBlank(WS.EndpointURLParameters__c)){
            if(currentAccId != null){
                thisAccount = [SELECT Id, Name, Tract_AccountId__c, Tract_AccountNumber__c FROM Account WHERE Id =:currentAccId];
            }
            else{
                addMessage('No Billing Account found!!!');
                return;
            }
        }
        else{
            addMessage('Unable to find TRACT Callout details. Please ask your Administrator to setup the web service callout to TRACT settings');
            return;
        } 
        
    }
    
    public List<Payment> getPayments(){
        try{
            List<Payment> paymentList = new List<Payment>();
            if(String.isNotBlank(thisAccount.Tract_AccountId__c)){
                String strEndpoint = WS.Endpoint__c + 'billing-accounts/' + thisAccount.Tract_AccountId__c + '/payments';
                HttpResponse res = queryTract(strEndpoint,'GET',null,null,'application/json',null);
                if(res.getStatusCode() == 200){
                    paymentList = (List<Payment>)JSON.deserialize(res.getBody(), List<Payment>.class);
                    if(!paymentList.isEmpty()){
                        for(Payment objPay : paymentList){
                            objPay.accid = currentAccId;
                            objPay.payment_method_type = objPay.payment_method != null ? objPay.payment_method.payment_method_type : '';
                            objPay.status = objPay.status != null ? objPay.status.toLowerCase().capitalize() : '';
                            objPay.occurred_on = objPay.occurred_on != null ? formatDate(objPay.occurred_on) : ''; 
                            objPay.invoices_paid = objPay.invoices_paid;
                        }
                    }
                }
                else{
                    addMessage('Payment Callout Failed : '+res.getStatus());
                }
            }
            else{
                addMessage('Billing Account does not exist in Tract. Please fill in the Tract Billing Account # and try again.');
            }
            return paymentList;
        }catch(CalloutException e){
            addMessage('Exception occurred : '+e.getMessage());
            return new List<Payment>();
        }catch(JSONException e){
            addMessage('Exception occurred : '+e.getMessage());
            return new List<Payment>();
        }catch(Exception e){
            addMessage('Exception occurred : '+e.getMessage());
            return new List<Payment>();
        }      
    }
    
    public void addMessage(String msg){
        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, msg));
    }

    public List<Invoice> getInvoices(){
        try{
            List<Invoice> invoiceList = new List<Invoice>();
            if(queryTract){
				if(String.isNotBlank(thisAccount.Tract_AccountNumber__c)){
					String strEndpoint = WS.Endpoint__c + 'invoices';
					strEndpoint = setParams(strEndpoint,'account_num', thisAccount.Tract_AccountNumber__c);
					System.debug('strEndpoint : '+strEndpoint);
					HttpResponse res = queryTract(strEndpoint,'GET',null,null,'application/json',null);
					
					if(res.getStatusCode() == 200){
						invoiceList = (List<Invoice>)JSON.deserialize(res.getBody(), List<Invoice>.class);
						if(!invoiceList.isEmpty()){
							for(Invoice objInv : invoiceList){
								objInv.accid = currentAccId;
								objInv.due_date = objInv.due_date != null ? formatDate(objInv.due_date) : '';
								objInv.invoiced_date = objInv.occurred_on != null ? formatDate(objInv.occurred_on) : '';
								objInv.paid_date = objInv.paid_date != null ? formatDate(objInv.paid_date) : '';
								objInv.check_invoice_status = objInv.status != 'PROCESSING' ? true : false;                  
								objInv.status = objInv.status != null ? objInv.status.toLowerCase().capitalize() : '';
								
							}
						}
					}
					else{
						addMessage('Invoice Callout Failed : '+res.getStatus());
					}
				}
				else{
					 addMessage('Billing Account does not exist in Tract. Please fill in the Tract Billing Account # and try again.');
				}
			}
			queryTract = FALSE;
            return invoiceList;
        }catch(CalloutException e){
            addMessage('Exception occurred : '+e.getMessage());
            return new List<Invoice>();
        }catch(JSONException e){
            addMessage('Exception occurred : '+e.getMessage());
            return new List<Invoice>();
        }catch(Exception e){
            addMessage('Exception occurred : '+e.getMessage());
            return new List<Invoice>();
        }
    }
	
	public void deleteAttachment(){
        if(String.isNotBlank(invId)){
            String invoiceName = '%invoice.pdf%';
            List<Attachment> attachmentList = new List<Attachment>();
            for(Attachment attc : [select name,id,ParentId from Attachment where Name LIKE :invoiceName AND ParentId =: thisAccount.Id]){
                attachmentList.add(attc);
            }
            if(!attachmentList.isEmpty()) delete attachmentList;
        }
    }
    
    public void fetchInvoicePdf(){
        System.debug('invId : '+invId);
        if(String.isNotBlank(invId)){
            String strEndpoint = WS.Endpoint__c + 'invoices/' + invId + '/downloads';
            System.debug('strEndpoint :'+strEndpoint);
            HttpResponse res = queryTract(strEndpoint,'GET',null,null,'application/pdf',null);
            if(res.getStatusCode() == 200){
                Attachment outputFile = new Attachment();
                outputFile.parentId = thisAccount.Id;
                outputFile.name = 'invoice.pdf';
                outputFile.Body = res.getBodyAsBlob();
                insert outputFile;
                windowUrl = '/servlet/servlet.FileDownload?file=' + outputFile.Id;
            }
            else{
                windowUrl = String.valueOf(res.getStatusCode());
            }
        }
    }

  /*  public List<Service> getServices(){
    	List<Service> serviceList = new List<Service>();
        try{
            if(String.isNotBlank(thisAccount.Tract_AccountNumber__c)){
                String strEndpoint = WS.Endpoint__c + 'services';
                strEndpoint = setParams(strEndpoint,'account_num', thisAccount.Tract_AccountNumber__c);
                if(String.isNotBlank(WS.EndpointURLParameters__c))
                    strEndpoint += '&' + WS.EndpointURLParameters__c;
                HttpResponse res = queryTract(strEndpoint,'GET',null,null,'application/json',null);
                if(res.getStatusCode() == 200){
                    serviceList = (List<Service>)JSON.deserialize(res.getBody(), List<Service>.class);
                    if(!serviceList.isEmpty()){
                        for(Service objInv : serviceList){
                            if(objInv.product != null)
                                objInv.productName = objInv.product.name;
                            objInv.start_date = objInv.start_date != null ? formatDate(objInv.start_date) : '';
                            objInv.status_date = objInv.status_date != null ? formatDate(objInv.status_date) : '';
                        }
                    }
                }
                else{
                    addMessage('Service Callout Failed : '+res.getBody());
                }
            }
            else{
                 addMessage('Billing Account does not exist in Tract. Please fill in the Tract Billing Account # and try again.');
            }
        }catch(CalloutException e){
            addMessage('Exception occurred : '+e.getMessage());
        }catch(JSONException e){
            addMessage('Exception occurred : '+e.getMessage());
        }catch(Exception e){
            addMessage('Exception occurred : '+e.getMessage());
        }
        return serviceList;
    }
    */
	
    public void doGetTractService(){
	    	isPollerMode = false;
	    	if(currentPoller >= MAX_POLLER_REQUEST) return;
	    	if (lstServices == null || lstServices.isEmpty()){
	    		lstServices = new List<Service>();
	    		
	    		try{
		    		if(String.isNotBlank(thisAccount.Tract_AccountNumber__c)){
	                String strEndpoint = WS.Endpoint__c + 'services';
	                strEndpoint = setParams(strEndpoint,'account_num', thisAccount.Tract_AccountNumber__c);
	                HttpResponse res = queryTract(strEndpoint,'GET',null,null,'application/json',null);
	                
	                if(res.getStatusCode() == 200){
		                	System.debug('>>>>>>>>>>>>>>>>res.getBody():'+ res.getBody());
	                    lstServices = (List<Service>)JSON.deserialize(res.getBody(), List<Service>.class);
	                    System.debug('>>>>>>>>>>>>>>>>serviceList'+ lstServices);
	                    
	                    if( !lstServices.isEmpty() ) {
		                    	//get Line item to use from_date if status not Active
		                    	Set<ID> lineItemIds = new Set<ID>();
		                    	Map<ID, OpportunityLineItem> mapLineItem = new Map<ID, OpportunityLineItem>();
		                    	
		                    	for(Service objInv : lstServices) {
		                    		mapService.put(objInv.id, objInv);
		                    		if(objInv.custom_field_values == null || objInv.custom_field_values.isEmpty()) continue;
			                    		
		                    		for(CustomFieldValues cus: objInv.custom_field_values){
		                    			if(cus.custom_field == null || cus.custom_field.name == null || !cus.custom_field.name.equalsIgnoreCase('SF Opportunity Line Item')) continue;
		                    			lineItemIds.add(cus.value);
		                    		}
			             	}
			                    	
			                mapLineItem = GW_OpportunityLineItem.getMap(lineItemIds);
		                    	
	                        for (Service objInv : lstServices) {
								objInv.productName = (objInv.product != null) ? objInv.product.name : '';
								objInv.start_date = objInv.start_date != null ? formatDate(objInv.start_date) : '';
								objInv.status_date = objInv.status_date != null ? formatDate(objInv.status_date) : '';
								objInv.isDeactivated = objInv.status.equalsIgnoreCase('DEACTIVATED');
								objInv.commitment_end_date = objInv.commitment_end_date == null ? '' : formatDate(objInv.commitment_end_date);
								
								//if an service is active but it is deactivated in the future date, display current agreement service end date. Else, display end date
								Boolean isDeactivateInFutureDate = ( 'ACTIVE'.equalsIgnoreCase(objInv.status) && 'DEACTIVATE_SERVICE'.equalsIgnoreCase(objInv.current_agreement_service.end_action) );
	                            String strEndDate = isDeactivateInFutureDate ? objInv.current_agreement_service.end_date : objInv.end_date;
								Datetime end_date = convertStr2Date(strEndDate);
					   			objInv.end_date = ( end_date == null ) ? '' : end_date.format('dd/MM/yyyy HH:mm:ss');
		                            
	                            	if(objInv.custom_field_values == null || objInv.custom_field_values.isEmpty()) continue;
	                    			for(ServiceResource sr : objInv.service_resources){
	                    				if(sr.identifier == null) continue;
	                    				String adId = (sr.identifier).split('_')[1]; //7233_4410916952 networkid_adid
	                    				objInv.ad_id = adId;
		                    		}
		                    		
		                    		for(CustomFieldValues cus: objInv.custom_field_values){
		                    			if (cus.custom_field == null || cus.custom_field.name == null) continue;
										if (cus.custom_field.name.equalsIgnoreCase('Termination Reason')) objInv.strTerminationReason = cus.value;
										if (cus.custom_field.name.equalsIgnoreCase('SF Opportunity ID')) objInv.oppid = cus.value;
	                    				if (cus.custom_field.name.equalsIgnoreCase('SF Opportunity Line Item')) {
	                    					objInv.oliid = cus.value;
	                    					OpportunityLineItem item = mapLineItem.get(cus.value);
	                    					if(item != null) {
	                    						if(!objInv.status.equalsIgnoreCase('ACTIVE')) { //use from_date if status not Active
				                    				Datetime dt = null;
					                    			if(item.from_Date__c != null){
					                    				Date fromDate = item.from_Date__c;
					                    				dt = datetime.newInstance(fromDate.year(), fromDate.month(), fromDate.day());
					                    			}
					                    			objInv.start_date = dt != null ? dt.format('dd/MM/yyyy') : '';
		                    					}
	                    					}
		                    			}
		                        }
		                        
		                    }
		                } else {
		                    addMessage('Service Callout Failed ('+ currentPoller +'): ' +res.getBody());
		                    isPollerMode = true;
		                    currentPoller++;
		                }
		            }
		            else{
		                 addMessage('Billing Account does not exist in Tract. Please fill in the Tract Billing Account # and try again.');
		            }
		    		}
	    		}catch(CalloutException e){
	            addMessage('Exception occurred : '+e.getMessage());
	        }catch(JSONException e){
	            addMessage('Exception occurred : '+e.getMessage());
	        }catch(Exception e){
	            addMessage('Exception occurred : '+e.getMessage());
	        }
	    }
    }
    
    public void cloneOpp(){
        deActiveServiceStatus = '';
        //TO DO: get Opportunity to clone from service id
        if(serviceIdSelected == null || serviceIdSelected == ''){
            cloneServiceStatus = 'Invalid Service Id!';
            return;
        }
        
        if(agreementIdSelected == null || agreementIdSelected == ''){
        	cloneServiceStatus = 'Agreement Service ID is required!';
            return;
        }
        
        RemoteResponse res = WSC_Tract.getOppFromTractServiceId(currentAccId, serviceIdSelected);
        if(res.statusCode == RemoteResponse.STATUSCODE_ERROR){
            cloneServiceStatus = res.message;
            return;
        }
        
        try{
            Id oppId = Id.valueOf(String.valueOf(res.content));
        
            List<Opportunity> lstRelatedOpp = GW_Opportunity.getList(new Set<ID>{oppId});
            if(lstRelatedOpp.isEmpty()){
                cloneServiceStatus = 'There are no Opportunity to clone.';
                return;
            }
         
            Opportunity originalOpp = lstRelatedOpp[0];
            Opportunity clonedOpp = originalOpp.clone(false, true);
            clonedOpp.Name = clonedOpp.Name + ' [Adjustment]';
            clonedOpp.Original_Opportunity__c = originalOpp.Id;
            clonedOpp.TRACT_Adjustment_ServiceId__c = agreementIdSelected;
            clonedOpp.ContractSigned__c = false;
			clonedOpp.ContractStatus__c = '';
			clonedOpp.StageName = 'Qualification';
            clonedOpp.recordtypeId = UTIL_RecordType.getRecordTypeByName('Opportunity','Preapproved').Id;
            clonedOpp.Tract_AgreementId__c = '';
            clonedOpp.Tract_OrderId__c = null;
            clonedOpp.Tract_Order_Number__c = '';
			clonedOpp.ownerId = UserInfo.getUserId();
            System.debug('>>>>>>>>>>>>pricebook' + clonedOpp.Pricebook2Id);
            System.debug('>>>>>>>>>>>>clonedOpp' + clonedOpp);
            insert clonedOpp;
            
            //clone line item
            List<OpportunityLineItem> lstOriginalOpli = GW_OpportunityLineItem.getListFromRelated(originalOpp.Id);
            List<OpportunityLineItem> lstClonedOpli = new List<OpportunityLineItem>();
            for(OpportunityLineItem originalLineItem: lstOriginalOpli){
                OpportunityLineItem clonedLineItem = originalLineItem.clone(false, true);
                clonedLineItem.OpportunityId = clonedOpp.id;
                clonedLineItem.unitPrice = clonedLineItem.TotalPrice == null || clonedLineItem.TotalPrice <0 ? clonedLineItem.UnitPrice: null;
                clonedLineItem.Tract_ServiceId__c = '';
				clonedLineItem.UniqueLocalBookingId__c = '';
                lstClonedOpli.add(clonedLineItem);
            }
            if(!lstClonedOpli.isEmpty()){
                insert lstClonedOpli;
            }
            cloneServiceStatus = clonedOpp.id;
        }catch(Exception ex){
            cloneServiceStatus = ex.getMessage();
        }
        return;
    }
    
    @testVisible private String getCurrentAgreementServcieId(List<Object> lstObjs){
        String curAgreeServId;
        Map<String, Object> mObj = (Map<String, Object>) lstObjs[0];
        if(mObj.containsKey('current_agreement_service') ){
            Map<String, Object> mapCurAgreeServ = (Map<String, Object>) mObj.get('current_agreement_service');
            
            if(mapCurAgreeServ.containsKey('id')){
                curAgreeServId = String.valueOf(mapCurAgreeServ.get('id'));
            }
        }
        
        return curAgreeServId;
    }
    
    public HttpResponse queryTract(String strEndpoint, String strMethod, String authorizationHeader, String authKey, String contentType, String strBody){
        HttpRequest req = new HttpRequest();
        req.setMethod(strMethod);
        req.setTimeout(120000);
        req.setEndpoint(strEndpoint);
        req.setHeader('Content-Type', contentType); 
        req.setHeader('x-api-key', WSC_Tract.getApiKey(WS.User__c, WS.EndpointURLParameters__c));
        if(String.isNotBlank(authorizationHeader) && String.isNotBlank(authKey))
            req.setHeader(authKey, authorizationHeader);
        if(strMethod != 'GET')
          req.setBody(strBody);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res;
    }
    
    public void doServiceDeactivationSpoc(){
    	cloneServiceStatus = '';
    	deActiveServiceStatus = '';
    	deActivateServSpocStatus = '';
    	try{
    		Service svc = mapService.get(serviceIdSelected);
    		String localBookingId;
			boolean isAdsale = false;
    		if(svc != null && svc.oliid != null) {
    			for(OpportunityLineItem i : [select UniqueLocalBookingId__c, Opportunity.MemberUnit__r.LineOfBusiness__c from OpportunityLineItem where id =:svc.oliid]) {
    				localBookingId = i.UniqueLocalBookingId__c;
					isAdsale = i.Opportunity.MemberUnit__r.LineOfBusiness__c == 'AD';
    			}
    		}
    		if(String.isBlank(localBookingId)) {
    			deActivateServSpocStatus = 'Succesfully deactivated in Tract'+ (isAdsale ? '.' : ', Failed in local platform as no local Id specified.');
    			return;
			}
    			
	    	String endDate = ApexPages.currentPage().getParameters().get('endDate');
	    	String proName = ApexPages.currentPage().getParameters().get('proName');
	    	
	    	UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_API_SFECG_v2.ServiceDeactivationSpoc');
	        UTIL_WSC.WSC_Result res;
	        req.mAdditionalParams.put('endDate', endDate);
	        req.mAdditionalParams.put('proName', proName);
	        req.mAdditionalParams.put('uniqueLocalBookingId', localBookingId);
	        req.mAdditionalParams.put('terminationReason', terminationReason);
	        req.init(oppId2Deactivate);
	        res = req.call();
	        if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
	            deActivateServSpocStatus = 'success';
	        } else {
	        	Map<String, Object> response = res.getResponseData() != null && res.getResponseData().containsKey('results')? (Map<String, Object>) res.getResponseData().get('results') : null;
	            deActivateServSpocStatus = response == null ? res.errorMsg : response.containsKey('error') ? (String) response.get('error') : response.containsKey('message') ? (String) response.get('message') : String.isBlank(res.status) ? res.errorMsg : res.status;
	        }
    	}catch(Exception ex){
    		deActivateServSpocStatus = ex.getMessage();
    	}
    }
    
    public String deactivateService(Opportunity opp, Map<String,String> mapParams) {
	//Get the custom field id
        RemoteResponse remRes = WSC_Tract.getTractServiceCustomFieldId(opp.Id); 
        Map<String, String> mapServiceCusFieldId = (Map<String, String>) remRes.content;
        String tractCusFieldId = mapServiceCusFieldId.containsKey(CUS_FIELD_TerminationReason) ? mapServiceCusFieldId.get(CUS_FIELD_TerminationReason): '';
        
        //Check if custom field value already exists
        RemoteResponse remFieldVal = WSC_Tract.getFieldValIdFromTractServiceId(opp.AccountId, mapParams.get('serviceId'), CUS_FIELD_TerminationReason); 
        String strCusFieldValId = String.valueOf(remFieldVal.content);

        if(selectedServiceStatus.equalsIgnoreCase('PENDING')){
            //Deny Order Item for Pending Service
            //Get ORder Item Id
            RemoteResponse remOrderItemId = WSC_Tract.getOrderItemIdByOLIId(String.valueOf(opp.Id), String.valueOf(oliId2Deactivate)) ;
            String orderItemId = (String) remOrderItemId.content;
            if(String.isNotBlank(orderItemId)){
                UTIL_WSC.WSC_Request reqDeny;
                UTIL_WSC.WSC_Result resDeny;
                reqDeny= UTIL_WSC.getWSC_Request('WSC_Tract.DenyOrderItem');
                reqDeny.mAdditionalParams.put('orderItemId', orderItemId);
                reqDeny.init(opp.id);
                resDeny= reqDeny.call();
                if (resDeny.statusCode == 200 || resDeny.statusCode == 201 || resDeny.statusCode == 204){
                    deActiveServiceStatus = 'success';
                } 
                else{
                    deActiveServiceStatus = resDeny.status;
                }
            }
            else{
                deActiveServiceStatus = 'Order item is required to cancel pending service.';
            }
        }
        else{
            //Service Deactivation for Active Service
            UTIL_WSC.WSC_Request req;
            UTIL_WSC.WSC_Result res;
            req = UTIL_WSC.getWSC_Request('WSC_Tract.DeactivateServiceTract');
            for(String key: mapParams.keyset()) {
                req.mAdditionalParams.put(key, mapParams.get(key));
            }
            req.init(opp.id);
            res = req.call();
            if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
                deActiveServiceStatus = 'success';
            }
            else {
                Map<String, Object> response = res.getResponseData() != null && res.getResponseData().containsKey('results')? (Map<String, Object>) res.getResponseData().get('results') : null;
                deActiveServiceStatus = response == null ? res.errorMsg : response.containsKey('error') ? (String) response.get('error') : response.containsKey('message') ? (String) response.get('message') : String.isBlank(res.status) ? res.errorMsg : res.status;
            }
        }   
        if(deActiveServiceStatus == 'success'){
            //POST Termination Reason
            if(String.isNotBlank(tractCusFieldId) && String.isNotBlank(terminationReason)){
            
                if(remFieldVal.statusCode == RemoteResponse.STATUSCODE_OK){
                    UTIL_WSC.WSC_Request reqUpdateVal;
                    UTIL_WSC.WSC_Result resUpdateVal;
                    reqUpdateVal= UTIL_WSC.getWSC_Request('WSC_Tract.CustomFieldValuePush');
                    reqUpdateVal.mAdditionalParams.put('custFieldValId', strCusFieldValId);
                    reqUpdateVal.mAdditionalParams.put('customFieldType', 'service');
                    reqUpdateVal.mAdditionalParams.put('customFieldId', tractCusFieldId);
                    reqUpdateVal.mAdditionalParams.put('customFieldName', CUS_FIELD_TerminationReason);
                    reqUpdateVal.mAdditionalParams.put('customFieldValue', terminationReason);
                    reqUpdateVal.mAdditionalParams.put('objectType', 'services');
                    reqUpdateVal.mAdditionalParams.put('objectId', mapParams.get('serviceId'));
                    reqUpdateVal.init(opp.id);
                    resUpdateVal= reqUpdateVal.call();
                    // CD-3531 resync TractService for Termination Reason update
                    if(resUpdateVal.statusCode == UTIL_WSC.HTTP_OK || resUpdateVal.statusCode == UTIL_WSC.HTTP_CREATED) System.enqueueJob(new AsyncGetTractServiceFlow(opp.Id));
                }
            }
        } 
        return deActiveServiceStatus;
    }

    //refresh page callout, to avoid uncommitted work pending
    public PageReference doRefreshService(){
    	lstServices = new List<Service>();
    	doGetTractService();
    	return null;
    }
     
    public void deactivateServiceAction(){
    	cloneServiceStatus = '';
    	deActiveServiceStatus = '';
    	
    	String endDate = ApexPages.currentPage().getParameters().get('endDate');
    	//get from param because sometime it doesn't assign 
    	agreementIdSelected = agreementIdSelected == null ? ApexPages.currentPage().getParameters().get('agreementId') : agreementIdSelected;
    	oppId2Deactivate = oppId2Deactivate == null ? ApexPages.currentPage().getParameters().get('oppid') : oppId2Deactivate;
    	if(agreementIdSelected == null || agreementIdSelected == ''){
            deActiveServiceStatus = 'Service cannot be deactivated missing Tract service agreement id';
            return;
        }
		
		Service svc = mapService.get(serviceIdSelected);
		String localBookingId;
		boolean isAdsale = false;
		if(svc != null && svc.oliid != null) {
			for(OpportunityLineItem i : [select UniqueLocalBookingId__c, Opportunity.MemberUnit__r.LineOfBusiness__c from OpportunityLineItem where id =:svc.oliid]) {
				localBookingId = i.UniqueLocalBookingId__c;
				isAdsale = i.Opportunity.MemberUnit__r.LineOfBusiness__c == 'AD';
			}
		}
		if(String.isBlank(localBookingId) && !isAdsale) {
			deActiveServiceStatus = 'Service cannot be deactivated missing Local Booking ID';
			return;
		}
        
        Date eDate = Date.valueOf(endDate);
        System.debug(eDate);
        if (eDate < System.today() && eDate.month() != System.today().month() ) {
            deActiveServiceStatus = 'Service cannot be deactivated. Deactivation date must be within this month or in the future.';
            return;
        }

        try{
            List<Opportunity> lstRelatedOpp = GW_Opportunity.getList(new Set<ID>{oppId2Deactivate});
            if(lstRelatedOpp.isEmpty()){
                deActiveServiceStatus = 'No Opportunity Found.';
                addMessage('Exception occurred : '+ deActiveServiceStatus);
                return;
            }
            
            Opportunity opp = lstRelatedOpp[0];
            Map<String,String> mapParams = new Map<String,String>{
            	'endDate' => endDate,
            	'agreementId' => agreementIdSelected,
            	'memberUnit' => opp.MemberUnitId__c,
            	'localid' => opp.LocalPlatformId__c,
				'serviceId' => svc.id
            };

            deActiveServiceStatus = deactivateService(opp, mapParams); 
            if(deActiveServiceStatus != '' && deActiveServiceStatus != 'success'){
                 addMessage('Exception occurred : '+ deActiveServiceStatus);
            }
        }catch(Exception ex){
            deActiveServiceStatus = ex.getMessage();
        }
    }
    
    public String formatDate(String strDate){
        String formattedDate = '';
        
        if(String.isNotBlank(strDate)){
            formattedDate = '"' + strDate + '"';
            DateTime dt = (datetime)json.deserialize(formattedDate, datetime.class);
            formattedDate = dt.format('dd/MM/yyyy HH:mm:ss');
        }
        return formattedDate;
    }
	
	public DateTime convertStr2Date(String strDate){
        if( String.isBlank(strDate) ) return null;
        
        String formattedDate = '"' + strDate + '"';
        return (Datetime) json.deserialize(formattedDate, Datetime.class);
    }
    
    public String setParams(String strEndpoint, String paramName, String paramValue){
        if(String.isNotBlank(strEndpoint) && String.isNotBlank(paramName) && String.isNotBlank(paramName)){
            if(strEndpoint.contains('?'))
                strEndpoint += '&' + paramName + '=' + paramValue;
            else
                strEndpoint += '?' + paramName + '=' + paramValue;
        }
        return strEndpoint;
    }
    
    public class PaymentMethod{
        
        public String payment_method_type {get;set;}
        public String id {get;set;}
    }
    
    public class Payment{
        
        public Double amount {get;set;} 
        public String description {get;set;}         
        public String authorization {get;set;} 
        public String id {get;set;} 
        public PaymentMethod payment_method {get;set;} 
        public String occurred_on {get;set;} 
        public Boolean use_recurring_payment {get;set;}
        public String invoices_paid {get;set;}
        public String status {get;set;}
        public String accid {get;set;}
        public String payment_method_type {get;set;}         
    }
    
    public class Invoice{
        public String accid {get;set;}
        public Double amount {get;set;} 
        public String status {get;set;} 
        public String id {get;set;} 
        public String invoice_num {get;set;}
        public String occurred_on {get;set;} 
        public String due_date {get;set;} 
        public Double amount_to_pay {get;set;} 
        public String pdf_path {get;set;} 
        public String paid_date {get;set;} 
        public Boolean check_invoice_status {get;set;}
        public String invoiced_date {get;set;}    
    }

    public class Service{
    	public String oliid {get;set;}
    	public String oppid {get;set;}
    	public String commitment_end_date {get;set;}
        public String status {get;set;}
        public Product product {get;set;}
        public String productName {get;set;}
        public String quantity {get;set;} 
        public String status_date {get;set;} 
        public String end_date {get;set;} 
        public String start_date {get;set;}
        public String id {get;set;}
        public CurAgreementServ current_agreement_service {get;set;}
        public Boolean isDeactivated {get;set;}
        public CustomFieldValues[] custom_field_values {get;set;}
		public String strTerminationReason {get;set;}
		public ServiceResource[] service_resources{get;set;}
		public String ad_id{get;set;}
    }

    public class Product{
        public String name {get;set;}
    }
    
    public class CurAgreementServ{
    	public String id {get;set;}
    	public String end_date {get;set;}
    	public String end_action {get;set;}
		public CurAgreement agreement {get;set;}
    }
    
	public class CurAgreement {
    	public String status {get;set;}
    }
	
    public class CustomFieldValues{
    	public String value {get;set;}
    	public CustomField custom_field {get;set;}
    }
    
    public class CustomField{
    	public String name {get;set;}
    }
    
    public class ServiceResource{
    	public String identifier{get;set;}
    }

    public class DeactivationReason {
        public String id {get;set;}
        public String name {get;set;}
        public String description {get;set;}
        public String status {get;set;}
    }
}
