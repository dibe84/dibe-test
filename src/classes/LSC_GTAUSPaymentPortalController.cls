/**
 * CD-2513
 * Build a page that has the components listed in next section
 * 
 * The process will be as follows:
 * 
 * 1. customer has running service
 * 2. invoice is generated from TRACT and emailed to customer
 * 3. invoice contains 'pay now' hyperlink 
 * 4. customer clicks hyperlink and is taken to page displaying his open invoices and known billing details
 * 5. customer adds payment method and clicks 'pay now'
 * 
 * @author : GAEA-SYS TEAM
 * @created date : 27 June 2017
 * 
 */
public with sharing class LSC_GTAUSPaymentPortalController {

	//public String accId;
	public String tractId;
	public Account account { get;set; }
	public String accountJSON { get;set; }

	//////////////////////////////////////////////////////////////////////////////////// Constructor ////////////////////////////////////////////////////////////////////////////////////
	public LSC_GTAUSPaymentPortalController() {
		try {
			//accId = (Apexpages.currentPage().getParameters().get('id') != null)?Apexpages.currentPage().getParameters().get('id'):'';
			tractId = (Apexpages.currentPage().getParameters().get('id') != null)?Apexpages.currentPage().getParameters().get('id'):'';

			account = new Account();
	
			if (String.isNotBlank(tractId)) {
				for (Account acc : [ SELECT Name, Account_Status__c, Tract_AccountId__c, Tract_AccountNumber__c, BillingAddress, Member__r.DefaultMemberUnit__r.CurrencyIsoCode,
                                        (SELECT TotalAmountNetNet__c FROM Opportunities) FROM Account WHERE Tract_AccountId__c=:String.escapeSingleQuotes(tractId) OR Tract_AccountNumber__c=:String.escapeSingleQuotes(tractId) ] ) {
	
					account = acc;
				}
			
			}

			accountJSON = JSON.serialize(account);
			

		} catch (Exception ex) { throw new LSC_GTAUSPaymentPortalControllerException(ex+''); }
	}

	
	//////////////////////////////////////////////////////////////////////////////////// Public Variable ////////////////////////////////////////////////////////////////////////////////////
	/*
	public static Webservice_Settings__c WS {

		get {

			if ( WS == null ) {
				WS = Webservice_Settings__c.getInstance('WSC_Tract'+ '_' + (UTIL.isSandbox() ? 'UAT' : 'PROD'));
			}

			return WS;
		}

		private set;
	}  
	*/

    //////////////////////////////////////////////////////////////////////////////////// Private Variable ////////////////////////////////////////////////////////////////////////////////////
    private static String STATUS_ERROR      = 'error';
    private static String STATUS_SUCCESS    = 'success';

    private static Set<Integer> STATUS_CODE_SUCCESS = new Set<Integer>{200, 201, 0};
    private static Map<String, String> CARDTYPE_MAPPING = new Map<String,String>{
															        'diners_club_carte_blanche' => 'DINERSCLUB',
															        'discover' 					=> 'DISCOVER',
															        'mastercard' 				=> 'MASTERCARD',
															        'amex' 						=> 'AMEX',
															        'visa' 						=> 'VISA'
															    };

	//////////////////////////////////////////////////////////////////////////////////// Aura Method ////////////////////////////////////////////////////////////////////////////////////

	@AuraEnabled
	public static String getInvoices (String accJSON) {
		ResponseResult result = new ResponseResult();

		try{
            if(String.isNotBlank(accJSON)){
            	Account thisAccount = (Account) JSON.deserialize(accJSON, Sobject.class);
            	System.debug('### thisAccount :: ' + thisAccount);

				if(String.isNotBlank(thisAccount.Tract_AccountNumber__c)){
					UTIL_WSC.WSC_Request wsRequest = UTIL_WSC.getWSC_Request('WSC_Tract.GetInvoices');
	        		wsRequest.init(thisAccount.Id);
					UTIL_WSC.WSC_Result response = wsRequest.call();
					
	        		List<Invoice> invoiceList = new List<Invoice>();
	        		if (response.resp == null ) {
						result.setResponeResult(STATUS_ERROR, 'Service not available. Please reload the page.');
						return JSON.serialize(result);
	        		}
	        		
	        		if ( response.resp.getStatusCode() == 200 ) {
	        			system.debug('xxxxxxxxx------'+response.resp.getBody());
						invoiceList = (List<Invoice>) JSON.deserialize(response.resp.getBody(), List<Invoice>.class);
						if(!invoiceList.isEmpty()){
							for(Invoice objInv : invoiceList){
								objInv.accid 				= thisAccount.Id;
								objInv.due_date 			= objInv.due_date != null ? formatDate(objInv.due_date) : '';
								objInv.invoiced_date 		= objInv.occurred_on != null ? formatDate(objInv.occurred_on) : '';
								objInv.paid_date 			= objInv.paid_date != null ? formatDate(objInv.paid_date) : '';
								objInv.check_invoice_status = objInv.status != 'PROCESSING' ? true : false;                  
								objInv.status 				= objInv.status != null ? objInv.status.toLowerCase().capitalize() : '';
								
								//Default Pay Now is TRUE
								objInv.paynow = true;
							}
						}

						result.setResponeResult(STATUS_SUCCESS, JSON.serialize(invoiceList));

					} else {
						result.setResponeResult(STATUS_ERROR, 'Invoice Callout Failed : '+response.resp.getStatus());
					}
					
					
				} else {
					result.setResponeResult(STATUS_ERROR, 'Billing Account does not exist in Tract. Please fill in the Tract Billing Account # and try again.');
				}
			}
        }catch(CalloutException e){
			result.setResponeResult(STATUS_ERROR, 'CalloutException occurred : '+e.getMessage() + '\n'+e.getStackTraceString());
        }catch(JSONException e){
			result.setResponeResult(STATUS_ERROR, 'JSONException occurred : '+e.getMessage() + '\n'+e.getStackTraceString());
        }catch(Exception e){
			result.setResponeResult(STATUS_ERROR, 'Exception occurred : '+e.getMessage() + '\n'+e.getStackTraceString());
        }

        return JSON.serialize(result);
	}

    @AuraEnabled
    public static String getBillingAccount (String accJSON) {

    	System.debug('#### accJSON :: ' + accJSON);

        ResponseResult result = new ResponseResult();
        Map<String, Object> additional_result = new Map<String, Object>();
        result.setResponeResult(STATUS_ERROR, 'Billing Account does not exist in Tract. Please fill in the Tract Billing Account # and try again.');

        try{
            if(String.isNotBlank(accJSON)){

                Account thisAccount = (Account) JSON.deserialize(accJSON, Sobject.class);
                System.debug('### thisAccount :: ' + thisAccount);

                if(String.isNotBlank(thisAccount.Tract_AccountNumber__c)) {

                    UTIL_WSC.WSC_Request wsRequest = UTIL_WSC.getWSC_Request('WSC_Tract.GetBillingAccount');
                    wsRequest.init(thisAccount.Id);
                    UTIL_WSC.WSC_Result response = wsRequest.call();
                    
                    if (response.resp == null ) {
                        result.setResponeResult(STATUS_ERROR, 'Cannot Retreive Billing Account : Service not available. Please reload the page.');
                        return JSON.serialize(result);
                    }
                    
                    System.debug('>>>> response.getStatusCode :: ' + response.resp.getStatusCode());

                    if ( response.resp.getStatusCode() == 200 ) {

                    	system.debug('xxxxxxxxx------'+response.getResponseData());
                        
                        Map<String, Object> responseData = (Map<String, Object>) response.getResponseData().get('results');
                        System.debug('### responseData :: ' + responseData);

                        if (responseData.containsKey('responsible_party')) {

                            Map<String, Object> addresses = (Map<String, Object>) responseData.get('responsible_party');    

                            System.debug('### addresses :: ' + addresses);

                            if (addresses.containsKey('addresses')) {

                                List<Object> lstAddress = (List<Object>) addresses.get('addresses');
                            
                                String billingAddress = '';

                                for (Object address : lstAddress) {
                                    
                                    Map<String, Object> mapAddress = (Map<String, Object>) address;

                                    if (mapAddress.containsKey('purpose') && mapAddress.get('purpose') == 'BILLING') {

                                        String street       = mapAddress.containsKey('line1')?String.valueOf(mapAddress.get('line1')):'';
                                        String city         = mapAddress.containsKey('city')?String.valueOf(mapAddress.get('city')):'';
                                        String state        = mapAddress.containsKey('region_or_state')?String.valueOf(mapAddress.get('region_or_state')):'';
                                        String postalCode   = mapAddress.containsKey('postal_code')?String.valueOf(mapAddress.get('postal_code')):'';
                                        String country      = mapAddress.containsKey('country')?String.valueOf(mapAddress.get('country')):'';

                                        List<String> strAddr = new List<String>();

                                        if (String.isNotBlank(street)) strAddr.add(street);
                                        if (String.isNotBlank(city)) strAddr.add(city);
                                        if (String.isNotBlank(state)) strAddr.add(state);
                                        if (String.isNotBlank(postalCode)) strAddr.add(postalCode);
                                        if (String.isNotBlank(country)) strAddr.add(country);

                                        if (!strAddr.isEmpty()) {

                                            billingAddress = String.join(strAddr, ', ');

                                            result.setResponeResult(STATUS_SUCCESS, billingAddress);
											additional_result.put('billing_address', billingAddress);
                                            
                                        }
                                    }
                                }
                            }

                            if (addresses.containsKey('organization_name')) additional_result.put('organization_name', addresses.get('organization_name'));
                     
                        }

                        System.debug('### currency_code :: ' + responseData.get('currency_code'));

                        if (responseData.containsKey('currency_code')) additional_result.put('currency_code', responseData.get('currency_code'));
                    } 

                    else result.setResponeResult(STATUS_ERROR, 'BillingAccount Callout Failed : '+response.resp.getStatus());
                    
                    
                } 

                else result.setResponeResult(STATUS_ERROR, 'Billing Account does not exist in Tract. Please fill in the Tract Billing Account # and try again.');
                
            }
        }catch(CalloutException e){
            result.setResponeResult(STATUS_ERROR, 'CalloutException occurred : '+e.getMessage() + '\n'+e.getStackTraceString());
        }catch(JSONException e){
            result.setResponeResult(STATUS_ERROR, 'JSONException occurred : '+e.getMessage() + '\n'+e.getStackTraceString());
        }catch(Exception e){
            result.setResponeResult(STATUS_ERROR, 'Exception occurred : '+e.getMessage() + '\n'+e.getStackTraceString());
        }

        result.additional_result = additional_result;
        return JSON.serialize(result);
    }
	
	/**
	 * To create recurring payment method in tract
	 * @param : accJSON
	 * @return : result of recurring payment method creation 
	 */
	@AuraEnabled
	public static RemoteResponse createRecurringPaymentMethod(String accountId, String jsonPaymentDetail) {

		System.debug('### jsonPaymentDetail :: ' + jsonPaymentDetail);

		RemoteResponse response = new RemoteResponse();
		try {
            PaymentDetail pdDTO = (PaymentDetail) JSON.deserializeStrict(jsonPaymentDetail, PaymentDetail.class); System.debug('### pdDTO :: ' + pdDTO);
            Map<String, String> paymentDetailMapper = new Map<String, String>{	
    	        										'card_type' 			=> pdDTO.card_type, 
    												    'expiration_date' 		=> pdDTO.expiration_date, 
    												    'first_name' 			=> pdDTO.first_name, 
    												    'identifier_number' 	=> pdDTO.identifier_number, 
    												    'last_name' 			=> pdDTO.last_name, 
    												    'payment_method_type' 	=> pdDTO.payment_method, 
    												    'verification_number' 	=> pdDTO.verification_number, 
    												    'currency' 				=> pdDTO.payment_currency 
    												};
    		UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.RecurringPaymentCreate');
            req.init(accountId);
    		req.mapper.mappingElements = WSC_Tract.getMapper_RecurringPaymentCreate(paymentDetailMapper);											
            UTIL_WSC.WSC_Result result = req.call();
            
			if(result == null) {
	        	response.statusCode = RemoteResponse.STATUSCODE_ERROR;
	        	response.message = 'Account is not ready.';
	        } else if (result.statusCode == 201) {
	            response.statusCode = RemoteResponse.STATUSCODE_OK;
	            response.message = 'Payment method is created.';  
	        } else {
	            response.statusCode = RemoteResponse.STATUSCODE_ERROR;
	            response.message = result.status + ': ' + result.errorMsg;
	            if(result.getResponseData().get('results') != null) {
	            	Map<String,Object> mapres = (Map<String,Object>) result.getResponseData().get('results');
	            	response.message = String.valueOf(mapres.get('message'));
	            } else if(result.getResponseData().get('catalystError') != null) {
	            	response.message = String.valueOf(result.getResponseData().get('catalystError'));
	            }
	        }
	        
	        return response;
        } catch(Exception e) {
    		return new RemoteResponse(e.getMessage()+ '\n' +e.getStackTraceString(), RemoteResponse.STATUSCODE_ERROR);
    	}
	}
	
	/**
	 * To download inoice as PDF
	 * @param : invoiceId an invoice Id which is going to download 
	 * @return : result of fetch invoice pdf as string
	 */
	@AuraEnabled
	public static String doFetchInvoicePDFFromTract(String invoiceId, String accountId) {
		ResponseResult result = new ResponseResult();
		
		System.debug('#### invoiceId :: ' + invoiceId);

		if (String.isBlank(invoiceId)) {
            result.setResponeResult(STATUS_ERROR, 'Cannot fetch Invoice PDF from this Invoice. Please contact System Administrator.');
			return JSON.serialize(result);
		}

		try {
			UTIL_WSC.WSC_Request wsRequest = UTIL_WSC.getWSC_Request('WSC_Tract.FetchPDFInvoiceFromTract');
			wsRequest.mAdditionalParams.put('tract_invoice_Id', invoiceId);
			wsRequest.init(accountId);
			UTIL_WSC.WSC_Result response = wsRequest.call();
			
			System.debug('#### mAdditionalParams :: ' + wsRequest.mAdditionalParams);


			//get PDF salesforce invoice Id
			String sf_pdf_invoice_Id = String.valueOf(wsRequest.mAdditionalParams.get('sf_invoice_Id'));
			system.debug('sf_pdf_invoice_Id_xxxxxxxxxx ' + sf_pdf_invoice_Id);
			
            if ( String.isNotBlank(sf_pdf_invoice_Id) ) { 
				result.setResponeResult(STATUS_SUCCESS, Site.getPathPrefix() +'/servlet/servlet.FileDownload?file=' + sf_pdf_invoice_Id);
            } else {
				result.setResponeResult(STATUS_ERROR, 'Invoice document not found! Refresh the page and try again.');
			}
		} catch(CalloutException e){
			result.setResponeResult(STATUS_ERROR, 'CalloutException occurred : '+e.getMessage() + '\n'+e.getStackTraceString());
        } catch(JSONException e){
			result.setResponeResult(STATUS_ERROR, 'JSONException occurred : '+e.getMessage() + '\n'+e.getStackTraceString());
        } catch(Exception e){
			result.setResponeResult(STATUS_ERROR, 'Exception occurred : '+e.getMessage() + '\n'+e.getStackTraceString());
        }

        return JSON.serialize(result);
	}
	
	@AuraEnabled
    public static List<String> getExpiredMM () {
        
    	List<String> str = new List<String>{'MM'};

    	for (Integer i=1; i<=12; i++) str.add(String.valueOf(i));

        return str;
    }

    @AuraEnabled
    public static List<String> getExpiredYY () {
        
    	List<String> str = new List<String>{'Year'};

    	Integer currentYear = System.Today().year();

    	for (Integer i=0; i<=9; i++) str.add(String.valueOf(currentYear + i));

        return str;
    }

    @AuraEnabled
    public static Card getInitCard () {

        return new Card();
    }

    @AuraEnabled
    public static String createPaymentMethod(String cardSTR) {
        ResponseResult result = new ResponseResult();
		System.debug('### cardSTR :: ' + cardSTR);
        try {
            Card card = (Card) JSON.deserialize(cardSTR, LSC_GTAUSPaymentPortalController.Card.Class);
            System.debug('### card :: ' + card);

            if (!CARDTYPE_MAPPING.containsKey(card.card_type)) {
                result.setResponeResult(STATUS_ERROR, 'Invalid Card Type. We only support Discover, MasterCard, Diners Club, American Express and Visa.');
                return JSON.serialize(result);
            }

            List<String> lstFullName = Card.name_on_card.split(' ');
            System.debug('### lstFullName :: ' + lstFullName);

            //Prepare Payment Detail
            PaymentDetail pdDTO = new PaymentDetail();

            pdDTO.card_type = CARDTYPE_MAPPING.get(card.card_type);
            pdDTO.expiration_date =  card.expires_mm + '/' + card.expires_yy;
            pdDTO.first_name = lstFullName[0];
            pdDTO.identifier_number = card.card_number; 
            pdDTO.last_name = lstFullName[1];
            pdDTO.verification_number = card.security_code;
            pdDTO.payment_currency = card.payment_currency;

            RemoteResponse rr = createRecurringPaymentMethod(card.account_id, JSON.serialize(pdDTO));
            System.debug('### RemoteResponse :: ' + rr);

            if (STATUS_CODE_SUCCESS.contains(rr.statusCode)) {
                result.setResponeResult(STATUS_SUCCESS, 'success');
            }else {
                result.setResponeResult(STATUS_ERROR, rr.message);
            }
        } catch(Exception ex) {

            System.debug('$$$ ERROR - msg :: ' + ex.getMessage());
            System.debug('$$$ ERROR - statcktrace :: ' + ex.getStackTraceString());
            result.setResponeResult(STATUS_ERROR, ex.getMessage());
        }
    	
    	return JSON.serialize(result);
    }

	//////////////////////////////////////////////////////////////////////////////////// Private Method ////////////////////////////////////////////////////////////////////////////////////

    private static String formatDate(String strDate){
        String formattedDate = '';
        
        if(String.isNotBlank(strDate)){
            formattedDate = '"' + strDate + '"';
            DateTime dt = (datetime)json.deserialize(formattedDate, datetime.class);
            formattedDate = dt.format('dd/MM/yyyy'); //'dd/MM/yyyy HH:mm:ss'
        }
        return formattedDate;
    }

    //////////////////////////////////////////////////////////////////////////////////// DTO Class - Invoice ////////////////////////////////////////////////////////////////////////////////////

    public class Card {

    	@AuraEnabled
    	public String name_on_card {get;set;}
    	@AuraEnabled
    	public String card_number {get;set;}
    	@AuraEnabled
    	public String expires_mm {get;set;}
    	@AuraEnabled
    	public String expires_yy {get;set;}
    	@AuraEnabled
    	public String security_code {get;set;}
        @AuraEnabled
        public String card_type {get;set;}
        @AuraEnabled
        public String account_id {get;set;} //SF Account Id
        @AuraEnabled
        public String payment_currency {get;set;} //Account.Member__r.DefaultMemberUnit__r.CurrencyIsoCode
        @AuraEnabled
        public String payment_type {get;set;}


    	Card () {
    		name_on_card = '';
    		card_number = '';
    		expires_mm = 'MM';
    		expires_yy = 'Year';
    		security_code = '';
            card_type = 'VISA';
            account_id = '';
            payment_currency = '';
            payment_type = 'credit-card';
    	}
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

        public Bill_Cycle bill_cycle {get;set;}

        public Boolean paynow {get;set;}
    }

    public class Bill_Cycle {

    	public String currency_code {get;set;}
    }

    //////////////////////////////////////////////////////////////////////////////////// DTO Class - Invoice ////////////////////////////////////////////////////////////////////////////////////
    
    public class PaymentDetail {
    		//payment_method (default to credit-card)
    		public String payment_method { 
    			get { 
    				return 'credit-card';
    			}
    		}
    		
    		//currency (query from member : should read only)
    		public String payment_currency {get;set;}
    		//card_type (label: Card type)
    		public String card_type {get;set;}
    		//First_name (label: First name)
    		public String first_name {get;set;}
    		//Last_name (label: Last name)
    		public String last_name {get;set;}
    		//identifier_number (label: Card number)
    		public String identifier_number {get;set;}
    		//verification_number (label: CVV)
    		public String verification_number {get;set;}
    		//expiration_date (label: Expiration date) 
    		public String expiration_date {get;set;}
    }
    
    ////////////////////////End of Payment Detail DTO///////////////////////
    
    public class ResponseResult {

    	public String status {get;set;}
        public String result {get;set;}
        public Object additional_result {get;set;}

        public void setResponeResult (String status, String result) {
            this.status = status;
            this.result = result;
        }
    }

    //////////////////////////////////////////////////////////////////////////////////// Custom Exception ////////////////////////////////////////////////////////////////////////////////////
	public class LSC_GTAUSPaymentPortalControllerException extends Exception{}
}