/**
* Created by rvannierop on 2/21/2017.
*/

global class WSC_Tract {

    public static final String TRACT_ENDPOINT = 'https://ebay-api.tract-staging.com';
    public static final String EP_CREATE_DRAFT_ORDER = TRACT_ENDPOINT + '/billing/2/orders';
    public static final String APINAME = 'WSC_Tract';
    public static Webservice_Settings__c WS = Webservice_Settings__c.getInstance(APINAME + '_' + (UTIL.isSandbox() ? 'UAT' : 'PROD'));
    public static final String RESPONE_SUCCESS = 'success';
    
    private static final String CUS_FIELD_PRO_LINE_ID = 'Product Line ID';
    private static final String CUS_FIELD_SF_OPP_ID = 'SF Opportunity ID';
    private static final String CUS_FIELD_SF_LINE_ITEM_ID = 'SF Opportunity Line Item';
    public static Set<Id> accountsToUpdate = new Set<Id>();
    
    // get Tract api key from Custom Setting
    public static String getApiKey(String wsKeystring, String endpointURLParameters){
        
        if(String.isNotBlank(wsKeystring)) return wsKeystring.removeStart('api-key=');
        if(String.isNotBlank(endpointURLParameters)) return endpointURLParameters.removeStart('api-key=');
        return '';
    }
	
	
    public class CreateReverseInvoice extends GenericRequest {

        Account acc;
        Tract_Invoice__c inv;
        Finance_Request__c fr = null;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('CreateReverseInvoice', APINAME);
            super.init(contextRecordId);
            fr = (Finance_Request__c) this.contextRecord;
            if (fr == null ) {
                fr = GW_FinanceRequest.getRecord(contextRecordId);
            }
            acc = GW_Account.getRecord(fr.Billing_Account__c);
            inv = GW_TractInvoice.getRecord(fr.TRACT_Invoice__c);
            this.mapper.mappingElements = getMapper_ReverseAndReissueBillBatch(fr.Reason__c, inv, false);

            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'invoices/' + inv.External_Id__c + '/reverse-bill-batches';
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );
            UTIL.log('Req body: ' + this.getBody());

            this.setHttpMethod('POST');
        }

        public virtual override Boolean readyForCallout() {
            return (acc.Tract_AccountId__c != null);
        }

    }

    public class CreateReissueBillBatch extends GenericRequest {
        Account acc;
        Tract_Invoice__c inv;
        Finance_Request__c fr = null;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('CreateReissueBillBatch', APINAME);
            super.init(contextRecordId);
            fr = (Finance_Request__c) this.contextRecord;
            if (fr == null ) {
                fr = GW_FinanceRequest.getRecord(contextRecordId);
            }
            acc = GW_Account.getRecord(fr.Billing_Account__c);
            inv = GW_TractInvoice.getRecord(fr.TRACT_Invoice__c);
            this.mapper.mappingElements = getMapper_ReverseAndReissueBillBatch(fr.Reason__c, inv, true);

            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'invoices/' + inv.External_Id__c + '/reissue-bill-batches';
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );
            UTIL.log('Req body: ' + this.getBody());

            this.setHttpMethod('POST');
        }

        public virtual override Boolean readyForCallout() {
            return (acc.Tract_AccountId__c != null);
        }
    }

    private static List<UTIL_Fieldmapper.mappedElement> getMapper_ReverseAndReissueBillBatch(String reason, Tract_Invoice__c inv, Boolean retax) {
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add(new UTIL_Fieldmapper.mappedField('name', inv.Name + ' - ' + String.valueOf(System.now()) , 'String', 80, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('description', reason, 'String', 255, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('use_payment_term', true, 'BOOLEAN', 18, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('invoice_date', String.valueOf(Datetime.now()).replace(' ', 'T'), 'String', 50, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('auto_approve', true, 'BOOLEAN', 18, FALSE, TRUE));
        if (retax) 
            elements.add(new UTIL_Fieldmapper.mappedField('re_tax', true, 'BOOLEAN', 18, FALSE, TRUE));
        return elements;
    }

    public class GetReverseInvoice extends GenericRequest {

        Finance_Request__c fr = null;
        Tract_Invoice__c inv;
        public override void init(Id contextRecordId) {
            
            this.setCalloutDetails('GetReverseInvoice', APINAME);
            super.init(contextRecordId);
            fr = (Finance_Request__c) this.contextRecord;
            inv = GW_TractInvoice.getRecord(fr.TRACT_Invoice__c);
            if (fr == null ) {
                fr = GW_FinanceRequest.getRecord(contextRecordId);
            }

            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'invoices/' + inv.External_Id__c + '/reverse-bill-batches/' + fr.TRACT_Reverse_Invoice_Id__c;
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );
            UTIL.log('Req body: ' + this.getBody());

            this.setHttpMethod('GET');
        }

        public virtual override Boolean readyForCallout() {
            return (fr.TRACT_Reverse_Invoice_Id__c != null);
        }

    }

    public class TaxRatesTable extends GenericRequest {
        Finance_Request__c fr = null;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('TaxRatesTable',APINAME);
            super.init(contextRecordId);
			fr = (Finance_Request__c) this.contextRecord;
            if (fr == null ) {
                fr = GW_FinanceRequest.getRecord(contextRecordId);
            }
            Account billingAccount = [select BillingCountryCode, Language_Preference__c from Account where Id =: fr.Billing_Account__c limit 1];
            String countryCode = billingAccount.BillingCountryCode == null ? billingAccount.Language_Preference__c : billingAccount.BillingCountryCode;
            String customBaseEndpoint = !Test.isRunningTest() ? Webservice_Settings__c.getInstance(APINAME + '_PROD').Endpoint__c.removeEnd('/billing/2/') : 'http://api.salesforce.com/foo/bar';
            String endpoint = customBaseEndpoint +  '/tax/1/tax-tables/1/tax-table-entries?entity_type=BUSINESS&amp;country='+countryCode;
            if ( !Test.isRunningTest() )
                this.setHeader('x-api-key', Webservice_Settings__c.getInstance(APINAME + '_PROD').EndpointURLParameters__c.removeStart('api-key='));
            this.setEndpoint( endpoint );
            UTIL.log('GetTaxRatesTable : ' + endpoint );
            this.setHttpMethod('GET');
            this.mockMap.putAll(WSC_Tract.getMocks_TaxRatesTable());
        }

    }
    
    public static Map<String, Object> getTaxRatesTable(Id frId) {
        UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.TaxRatesTable');
        req.init(frId);
        UTIL_WSC.WSC_Result res = req.call();
        
        String rate = '';
        if (res.statusCode == 200 || res.statusCode == 201) {
            List<Object> objs = (List<Object>) res.getResponseData().get('results');
            
            if(!objs.isEmpty()) {
                for(Object record: objs ) { 

                    if ( UTIL_WSC.getResponseField('country', record) != 'MATCH_ALL' ) {
                        rate = String.valueOf(UTIL_WSC.getResponseField('rate', record));
                        return new Map<String, Object> {'rate' => rate};
                    }
        
                }

            }

        }
        return null;
    }
	
    //Checks if custom field values exits, if yes returns custom field value id 
    public static RemoteResponse getFieldValIdFromTractServiceId(ID accId, String serviceId, String fieldName){
        Map<String, String> mapOrderCusFieldValId = getCustomFieldValueId(accId, serviceId, 'services');
        RemoteResponse response = new RemoteResponse();
        response.content = mapOrderCusFieldValId.containsKey(fieldName) ? mapOrderCusFieldValId.get(fieldName) : '';
        response.statusCode = RemoteResponse.STATUSCODE_OK;
        return response;
    }
    
    public static Map<String, String> getCustomFieldValueId(String contextRecordId, String objectId, String objectType) {
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result resp;
        req = UTIL_WSC.getWSC_Request('WSC_Tract.GetTractCusFieldVal');
        req.mAdditionalParams.put('objectId', objectId);
        req.mAdditionalParams.put('objectType', objectType);
        req.init(contextRecordId); 
        resp = req.call();
        Map<String, String> mapCusFieldValId = new Map<String, String>();
        if (resp.statusCode != UTIL_WSC.HTTP_OK && resp.statusCode != UTIL_WSC.HTTP_CREATED) {
            return mapCusFieldValId;
        }
        List<Object> lstResults = (List<Object>)resp.getResponseData().get('results');
        for (Object resultObj: lstResults) {
            Map<String, Object> mObj = (Map<String, Object>) resultObj;
            if (mObj.containsKey('custom_field')) {
                Map<String, Object> mCusField = (Map<String, Object>) mObj.get('custom_field');
                if (mCusField.containsKey('name') && mObj.containsKey('id')) {
                    mapCusFieldValId.put(String.valueOf(mCusField.get('name')), String.valueOf(mObj.get('id')));
                }
            }
        }
        return mapCusFieldValId;
    }
    
	public class CustomFieldValuePush extends GenericRequest{
        Opportunity opp;

        public override void init(Id contextRecordId){
            this.setCalloutDetails('CustomFieldValuePush',APINAME);
            super.init(contextRecordId);
            opp = GW_Opportunity.getRecord(contextRecordId);
            String objectType = String.valueOf(this.mAdditionalParams.get('objectType'));
            String objectId = String.valueOf(this.mAdditionalParams.get('objectId'));
            String custFieldValId = String.valueOf(this.mAdditionalParams.get('custFieldValId'));
            this.mapper.mappingElements = getMapper_CustomFieldValuePush(this.mAdditionalParams);
            Map<String,Object> output = this.mapper.getOutputMap();
            this.setHandlerClass(APINAME + '.CustomFieldValuePush_Handler');

            String endpoint = '';
            if (String.isBlank(custFieldValId)) {               // Insert
                endpoint = this.baseEndpoint + objectType + '/'+ objectId + '/custom-field-values';
                this.setHttpMethod('POST');
            } else {                                            // Update
                endpoint = this.baseEndpoint + objectType + '/'+ objectId + '/custom-field-values/' + custFieldValId ;
                this.setHttpMethod('PUT');
            }

            if( !String.isBlank( this.endpointURLParameters ) ){
                endpoint += '?' + this.endpointURLParameters;   
            }

            this.setEndpoint( endpoint );   
        }
    }

    public class CustomFieldValuePush_Handler extends ApiHandler {
        public override void handle() {
            super.handle();
            Map<String,Object> response = (Map<String,Object>) result.getResponseData().get('results');
            if (result.statusCode == UTIL_WSC.HTTP_CREATED && response != null && response.containsKey('id') == TRUE) {
                //TODO:..
            }
            else if(this.result.statusCode != UTIL_WSC.HTTP_CREATED) {
                UTIL.logClean('WSC_Tract Unknown error, result: ' + this.result);
                response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract Unknown error');
            }
            else {
                UTIL.logClean('Error getting response from server - no response received.');
                response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract No response received from service.');
            }
        }
    }

    public static List<UTIL_Fieldmapper.mappedElement> getMapper_CustomFieldValuePush(Map<String, Object> mapParams){
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        UTIL_Fieldmapper.MappedObject mapCusFieldValOpli = new UTIL_Fieldmapper.MappedObject('');
        elements.add(new UTIL_Fieldmapper.mappedField('custom_field_value_type', String.valueOf(mapParams.get('customFieldType')), 'String', 50, FALSE, FALSE));
        elements.add(new UTIL_Fieldmapper.mappedField('value', String.valueOf(mapParams.get('customFieldValue')), 'String', 255, FALSE, TRUE));

        UTIL_Fieldmapper.MappedObject mapCusFieldOpli = new UTIL_Fieldmapper.MappedObject('custom_field');
        mapCusFieldOpli.add(new UTIL_Fieldmapper.mappedField('custom_field_type', String.valueOf(mapParams.get('customFieldType')), 'String', 32, FALSE, FALSE));
        mapCusFieldOpli.add(new UTIL_Fieldmapper.mappedField('name', String.valueOf(mapParams.get('customFieldName')), 'String', 255, FALSE, FALSE));
        mapCusFieldOpli.add(new UTIL_Fieldmapper.mappedField('id', String.valueOf(mapParams.get('customFieldId')), 'String', 10, FALSE, FALSE));
        
        elements.add(mapCusFieldOpli);
        return elements;
    }
    
    //////////////////////////////GET INVOICE FROM TRACT///////////////////////////////////////
    public class GetInvoices extends ApiRequest {
        Account acc;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('GetInvoices', APINAME);
            super.init(contextRecordId);
            acc = (Account) this.contextRecord;
            
            //https://ebay-beta-api-gw.tract-staging.com/billing/2/invoices?account_num=GTZ00074&api-key=008d4c89e3f24cb0a58f376f6c875e2b
            String endpoint = 'invoices?account_num='+acc.Tract_AccountNumber__c;//EKA00781
            if( this.baseEndpoint != null ){
                //endpoint = 'https://ebay-api-gw.tract-staging.com/billing/2/' +  endpoint; //to test with dev environment
                endpoint = this.baseEndpoint + endpoint;
            }
            
            this.setEndpoint( endpoint );
            this.setHttpMethod('GET');
        }
        
        public override HttpResponse getMockResponse() { 
            HttpResponse response = new HttpResponse();
            String resBODY = '[{"status":"open","pdf_path":"xxx","paynow":true,"paid_date":"2017-04-01T00:00:00.000+0200","occurred_on":"2017-04-01T00:00:00.000+0200","invoiced_date":"2017-04-01T00:00:00.000+0200","invoice_num":"90000","id":"1111","due_date":"2017-04-01T00:00:00.000+0200","check_invoice_status":null,"bill_cycle":null,"amount_to_pay":221342.0,"amount":98888.0,"accid":"111"}]';
            response.setStatusCode(200);
            response.setBody(resBODY);
            response.setStatus('OK');
            return response; 
        }
    }
    /////////////////// END GETTING INVOICE FROM TRACT//////////////////////

    //////////////////////////////GET INVOICE FROM TRACT///////////////////////////////////////
    public class GetBillingAccount extends ApiRequest {
        Account acc;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('GetBillingAccount', APINAME);
            super.init(contextRecordId);
            acc = (Account) this.contextRecord;
            
            String endpoint = 'billing-accounts';
            //String endpoint = 'https://ebay-api-gw.tract-staging.com/billing/2/billing-accounts/1791?' + WS.EndpointURLParameters__c;//GTZ00004//EKA00781
	        Map<String,Object> params = this.mAdditionalParams;
	        if( params != null && !params.isEmpty() ){
	        	endpoint += '?';
	        	for( String key : params.keyset() ){
	        		endpoint += key + '=' + ( (String) params.get( key ) ) + '&';
	        	}
	        	endpoint = endpoint.substring( 0 , endpoint.length() - 1 );
	        } else {
	            endpoint += '/'+acc.Tract_AccountId__c;	
	        } 

            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + endpoint;
            }

            this.setEndpoint( endpoint );
            UTIL.log('GetBillingAccount__xxxxx : ' + endpoint );
            this.setHttpMethod('GET');
        }

        public override HttpResponse getMockResponse() { 

            HttpResponse response = new HttpResponse();

            String resBODY;
            
            if (UTIL_WSC.testStatusCode == 200) {
                resBODY = '{"id":"1791","account_num":"EKA00781","external_account_num":"0010k000008kWEiAAM","bill_type":"EMAIL","bill_cycle":{"bill_cycle_type":"monthly","status":"ACTIVE","id":"76","name":"EUR-Kleinanzeigen","start_date":"2017-07-01T00:00:00.000+0200","end_date":"2017-08-01T00:00:00.000+0200","auto_bill":false,"currency_code":"EUR","day_of_month":1},"responsible_party":{"party_type":"organization","id":"1785","tax_id_number":"VAT - 1234567","addresses":[{"address_type":"email","purpose":"PRIMARY","email":"test_fake@test.com","id":"11442"},{"address_type":"postal","purpose":"BILLING","country":"POL","city":"Warszaw","line1":"Bielska 29","id":"3059","region_or_state":"Mazowsze","postal_code":"02-394"}],"organization_name":"Test Account","tax_id_validated":false},"recurring_payments":[{"id":"41","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"339","custom_field_values":[],"card_type":"VISA","first_name":"test","last_name":"xxx","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"12/2020"},"valid_from":"2017-07-12T13:44:44.000+0200","auto_payment":false},{"id":"42","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 9424","id":"340","custom_field_values":[],"card_type":"DISCOVER","first_name":"cccc","last_name":"ssss","identifier_number":"First 6: 601100 Last 4: 9424","expiration_date":"02/2024"},"valid_from":"2017-07-12T13:53:09.000+0200","auto_payment":false},{"id":"43","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"341","custom_field_values":[],"card_type":"VISA","first_name":"test","last_name":"wwww","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"03/2020"},"valid_from":"2017-07-12T14:06:53.000+0200","auto_payment":false},{"id":"44","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 4444","id":"342","custom_field_values":[],"card_type":"MASTERCARD","first_name":"test","last_name":"rrrr","identifier_number":"First 6: 555555 Last 4: 4444","expiration_date":"04/2020"},"valid_from":"2017-07-12T14:09:06.000+0200","auto_payment":false},{"id":"45","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"343","custom_field_values":[],"card_type":"VISA","first_name":"ccc","last_name":"xxxx","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"06/2024"},"valid_from":"2017-07-12T14:19:34.000+0200","auto_payment":false},{"id":"46","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1881","id":"344","custom_field_values":[],"card_type":"VISA","first_name":"test","last_name":"ooo","identifier_number":"First 6: 401288 Last 4: 1881","expiration_date":"04/2022"},"valid_from":"2017-07-12T14:21:11.000+0200","auto_payment":false},{"id":"57","payment_method":{"payment_method_type":"sepa-dd-em","nickname":"SEPA DD EM Ending 7890","id":"372","custom_field_values":[],"iban":"DE36444488881234567890","owner_name":"Test","mandate_id":"123456","mandate_signature_date":"2017-06-01T00:00:00+02:00"},"valid_from":"2017-07-13T21:30:51.000+0200","auto_payment":false},{"id":"59","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"2756","custom_field_values":[],"card_type":"VISA","first_name":"anna","last_name":"test","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"02/2020"},"valid_from":"2017-07-17T06:06:47.000+0200","auto_payment":false},{"id":"60","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"2757","custom_field_values":[],"card_type":"VISA","first_name":"anna","last_name":"test","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"02/2020"},"valid_from":"2017-07-17T06:08:47.000+0200","auto_payment":false},{"id":"61","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"2758","custom_field_values":[],"card_type":"VISA","first_name":"test","last_name":"anna","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"02/2019"},"valid_from":"2017-07-17T06:12:51.000+0200","auto_payment":false},{"id":"62","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1881","id":"2759","custom_field_values":[],"card_type":"VISA","first_name":"tetss","last_name":"cdvf","identifier_number":"First 6: 401288 Last 4: 1881","expiration_date":"03/2022"},"valid_from":"2017-07-17T07:11:30.000+0200","auto_payment":false},{"id":"63","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"2760","custom_field_values":[],"card_type":"VISA","first_name":"bbb","last_name":"rrrrsss","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"07/2023"},"valid_from":"2017-07-17T07:46:28.000+0200","auto_payment":false},{"id":"64","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"2761","custom_field_values":[],"card_type":"VISA","first_name":"test","last_name":"xmsi","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"07/2026"},"valid_from":"2017-07-17T07:53:38.000+0200","auto_payment":true}],"billing_account_category":{"description":"eBay Kleinanzeigen GmbH\r\nAlbert-Einstein-Ring 2-6Â ","status":"ACTIVE","id":"15","name":"eBayKleinanzeigen","payment_term":{"name":"Immediate","id":"15","term_days":0,"grace_days":0},"auto_pay_advance_days":0},"auto_payment_authorized":true,"status":"ACTIVE","pending_charges_total":0,"balance":646,"start_date":"2017-01-01T00:00:00.000+0100","custom_field_values":[{"custom_field_value_type":"billing-account","value":"Test Account","id":"13101","custom_field":{"custom_field_type":"billing-account","name":"Attn. of","id":"102"}},{"custom_field_value_type":"billing-account","value":"12345","id":"13102","custom_field":{"custom_field_type":"billing-account","name":"Company registration number","id":"101"}}],"contacts":[],"payment_term":{"name":"Immediate","id":"15"},"tax_exempt":true,"currency_code":"EUR","next_invoice_date":"2017-07-01T00:00:00.000+0200","responsible_account":{"id":"1791","account_num":"EKA00781","external_account_num":"0010k000008kWEiAAM"}}';
            }
            else if (UTIL_WSC.testStatusCode == 404) {
                resBODY = '{"id":"1791","account_num":"EKA00781","external_account_num":"0010k000008kWEiAAM","bill_type":"EMAIL","bill_cycle":{"bill_cycle_type":"monthly","status":"ACTIVE","id":"76","name":"EUR-Kleinanzeigen","start_date":"2017-07-01T00:00:00.000+0200","end_date":"2017-08-01T00:00:00.000+0200","auto_bill":false,"currency_code":"EUR","day_of_month":1},"responsible_party":{"party_type":"organization","id":"1785","tax_id_number":"VAT - 1234567","addresses":[{"address_type":"email","purpose":"PRIMARY","email":"test_fake@test.com","id":"11442"},{"address_type":"postal","purpose":"BILLING","country":"POL","city":"Warszaw","line1":"Bielska 29","id":"3059","region_or_state":"Mazowsze","postal_code":"02-394"}],"organization_name":"Test Account","tax_id_validated":false},"recurring_payments":[{"id":"41","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"339","custom_field_values":[],"card_type":"VISA","first_name":"test","last_name":"xxx","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"12/2020"},"valid_from":"2017-07-12T13:44:44.000+0200","auto_payment":false},{"id":"42","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 9424","id":"340","custom_field_values":[],"card_type":"DISCOVER","first_name":"cccc","last_name":"ssss","identifier_number":"First 6: 601100 Last 4: 9424","expiration_date":"02/2024"},"valid_from":"2017-07-12T13:53:09.000+0200","auto_payment":false},{"id":"43","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"341","custom_field_values":[],"card_type":"VISA","first_name":"test","last_name":"wwww","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"03/2020"},"valid_from":"2017-07-12T14:06:53.000+0200","auto_payment":false},{"id":"44","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 4444","id":"342","custom_field_values":[],"card_type":"MASTERCARD","first_name":"test","last_name":"rrrr","identifier_number":"First 6: 555555 Last 4: 4444","expiration_date":"04/2020"},"valid_from":"2017-07-12T14:09:06.000+0200","auto_payment":false},{"id":"45","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"343","custom_field_values":[],"card_type":"VISA","first_name":"ccc","last_name":"xxxx","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"06/2024"},"valid_from":"2017-07-12T14:19:34.000+0200","auto_payment":false},{"id":"46","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1881","id":"344","custom_field_values":[],"card_type":"VISA","first_name":"test","last_name":"ooo","identifier_number":"First 6: 401288 Last 4: 1881","expiration_date":"04/2022"},"valid_from":"2017-07-12T14:21:11.000+0200","auto_payment":false},{"id":"57","payment_method":{"payment_method_type":"sepa-dd-em","nickname":"SEPA DD EM Ending 7890","id":"372","custom_field_values":[],"iban":"DE36444488881234567890","owner_name":"Test","mandate_id":"123456","mandate_signature_date":"2017-06-01T00:00:00+02:00"},"valid_from":"2017-07-13T21:30:51.000+0200","auto_payment":false},{"id":"59","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"2756","custom_field_values":[],"card_type":"VISA","first_name":"anna","last_name":"test","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"02/2020"},"valid_from":"2017-07-17T06:06:47.000+0200","auto_payment":false},{"id":"60","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"2757","custom_field_values":[],"card_type":"VISA","first_name":"anna","last_name":"test","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"02/2020"},"valid_from":"2017-07-17T06:08:47.000+0200","auto_payment":false},{"id":"61","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"2758","custom_field_values":[],"card_type":"VISA","first_name":"test","last_name":"anna","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"02/2019"},"valid_from":"2017-07-17T06:12:51.000+0200","auto_payment":false},{"id":"62","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1881","id":"2759","custom_field_values":[],"card_type":"VISA","first_name":"tetss","last_name":"cdvf","identifier_number":"First 6: 401288 Last 4: 1881","expiration_date":"03/2022"},"valid_from":"2017-07-17T07:11:30.000+0200","auto_payment":false},{"id":"63","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"2760","custom_field_values":[],"card_type":"VISA","first_name":"bbb","last_name":"rrrrsss","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"07/2023"},"valid_from":"2017-07-17T07:46:28.000+0200","auto_payment":false},{"id":"64","payment_method":{"payment_method_type":"credit-card","nickname":"Credit Card Ending 1111","id":"2761","custom_field_values":[],"card_type":"VISA","first_name":"test","last_name":"xmsi","identifier_number":"First 6: 411111 Last 4: 1111","expiration_date":"07/2026"},"valid_from":"2017-07-17T07:53:38.000+0200","auto_payment":true}],"billing_account_category":{"description":"eBay Kleinanzeigen GmbH\r\nAlbert-Einstein-Ring 2-6Â ","status":"ACTIVE","id":"15","name":"eBayKleinanzeigen","payment_term":{"name":"Immediate","id":"15","term_days":0,"grace_days":0},"auto_pay_advance_days":0},"auto_payment_authorized":true,"status":"ACTIVE","pending_charges_total":0,"balance":646,"start_date":"2017-01-01T00:00:00.000+0100","custom_field_values":[{"custom_field_value_type":"billing-account","value":"Test Account","id":"13101","custom_field":{"custom_field_type":"billing-account","name":"Attn. of","id":"102"}},{"custom_field_value_type":"billing-account","value":"12345","id":"13102","custom_field":{"custom_field_type":"billing-account","name":"Company registration number","id":"101"}}],"contacts":[],"payment_term":{"name":"Immediate","id":"15"},"tax_exempt":true,"currency_code":"EUR","next_invoice_date":"2017-07-01T00:00:00.000+0200","responsible_account":{"id":"1791","account_num":"EKA00781","external_account_num":"0010k000008kWEiAAM"}}';
            }
            else {
                resBODY = null;
            }

            response.setStatusCode(UTIL_WSC.testStatusCode);
            response.setBody(resBODY.replaceAll('\n','').replaceAll('\r',''));
            response.setStatus('OK');
            return response; 
        }
    }
    /////////////////// END GETTING INVOICE FROM TRACT//////////////////////
    
    ///////////////////////////////FETCH PDF INVOICE///////////////////////////////////
    public class FetchPDFInvoiceFromTract extends GenericRequest {
        Account acc;
        
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('FetchPDFInvoiceFromTract', APINAME);
            super.init(contextRecordId);
            acc = (Account) this.contextRecord;
            this.setHandlerClass(APINAME+'.FetchPDFInvoiceFromTract_Handler');
            this.setHeader('Accept', 'application/pdf');
            this.setHeader('Content-Type', 'application/pdf');
            String tract_invoice_Id = String.valueOf(this.mAdditionalParams.get('tract_invoice_Id'));
            
            //https://ebay-beta-api-gw.tract-staging.com/billing/2/invoices/GZ17-00001/downloads?api-key=008d4c89e3f24cb0a58f376f6c875e2b
            String endpoint = 'invoices/' + tract_invoice_Id + '/downloads';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + endpoint; 
            }
            
            this.setEndpoint( endpoint );
            UTIL.log('FetchPDFInvoiceFromTract__xxxxx : ' + endpoint );
            this.setHttpMethod('GET');
        }
        
        public override void createWsLogs() {
            this.uniqueCalloutId = 'FetchPDFInvoiceFromTract'+this.contextRecord.Id + this.mAdditionalParams.get('tract_invoice_Id') + Datetime.now().format('dd-MM-yyyy HH:mm:ss');
            super.createWsLogs();
        }
    }
    
    public class FetchPDFInvoiceFromTract_Handler extends UTIL_WSC.WSC_ResultHandler {
    
        public override void handle() {
            super.handle();
            UTIL.log('FetchPDFInvoiceFromTract_Handler @@@@@ ' + this.result.statusCode);
            
            if (this.result.statusCode == HTTP_OK) {
                
                String invoiceName = (!Test.isRunningTest())?'GTAUS_TRACT_INVOICE':'TEST_INVOICE';
                
                List<Folder> folders = [Select Id From Folder Where DeveloperName = 'SharedDocuments' limit 1];
                List<Document> docs = [select Id from Document Where Name =: invoiceName];
                
                Document doc = new Document();
                doc.Name = invoiceName;
                doc.FolderId = folders[0].Id; //'00l90000001qBRuAAM';
                doc.ContentType = 'application/pdf';
                doc.Type = 'pdf';
                doc.DeveloperName = invoiceName;
                doc.Body = this.result.resp.getBodyAsBlob();
                doc.IsPublic = true;
                doc.Id = (docs.isEmpty()) ? null : docs[0].Id;
                upsert doc;
                
                //set pdf tract invocie Id to use in next step
                this.request.mAdditionalParams.put('sf_invoice_Id', doc.Id);
            }
        }
    }
    /////////////////////////////END FETCH PDF INVOCIE/////////////////////////////
    
    public class InvoiceResend extends GenericRequest {
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('InvoiceResend',APINAME);
            super.init(contextRecordId);
            String endpoint = '';
            if( this.baseEndpoint != null ) {
                endpoint = this.baseEndpoint + 'invoices/' +  mAdditionalParams.get('invoice_id') + '/resend';
            }
            this.setEndpoint( endpoint );
            this.setHttpMethod('POST');
        }
        public virtual override Boolean readyForCallout() { return true; }
    }

    /**
    *Method to create tract account synschrounously
    */
    webservice static String createAccountSync(Id accountId) {
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        req = UTIL_WSC.getWSC_Request('WSC_Tract.BillingAccountCreate');
        req.init(accountId);
        res = req.call();
        if (res.statusCode == 200 || res.statusCode == 201) {
            return RESPONE_SUCCESS;
        } else {
            Map<String, Object> response = (Map<String, Object>) res.getResponseData().get('results');
            if (response == null) return res.errorMsg;
            return response.containsKey('error') ? (String) response.get('error') : response.containsKey('message') ? (String) response.get('message') : String.isBlank(res.status) ? res.errorMsg : res.status;
        }
    }

    public class SentPaymentToTract extends GenericRequest{
        Opportunity opp;
        public override void init(Id contextRecordId){
            this.setCalloutDetails('SentPaymentToTract', APINAME);
            super.init(contextRecordId);
            
            List<String> lstAdditionalFields = new List<String>{'Account.Tract_AccountId__c'};
            opp = (Opportunity) GW_Opportunity.getRecord(contextRecordId, lstAdditionalFields);
            
            this.mapper.mappingElements = getMapper_PaymentToTract(opp);
            this.setHandlerClass(APINAME + '.SentPaymentToTract_Handler');
            
            String endPoint = '';
            if( this.baseEndpoint != null ){ 
                endpoint = this.baseEndpoint + 'billing-accounts/'+ opp.Account.Tract_AccountId__c +'/payments';
            }
            this.setEndpoint( endpoint );
            this.setHttpMethod('POST');
        }
    }
    
    public static List<UTIL_Fieldmapper.mappedElement> getMapper_PaymentToTract(Opportunity opp){
        
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add(new UTIL_Fieldmapper.mappedField('payment_type','payment', 'String', 18, TRUE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('description','Description','String', 18, TRUE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('apply_automatically',true,'Boolean', 18, TRUE, TRUE));
        
        UTIL_Fieldmapper.MappedObject paymentMethod = new UTIL_Fieldmapper.MappedObject('payment_method');
        paymentMethod.add(new UTIL_Fieldmapper.mappedField('payment_method_type','custom', 'String', 32, FALSE, FALSE));
        elements.add(paymentMethod);
        
        elements.add(new UTIL_Fieldmapper.mappedField('amount',opp.Amount,'String', 18, TRUE, TRUE));
    
        return elements;
    }
    
    public class SentPaymentToTract_Handler extends ApiHandler {
        public override void handle() {
            super.handle();
            Map<String,Object> response = (Map<String,Object>) result.getResponseData().get('results');
            if (result.statusCode == UTIL_WSC.HTTP_CREATED) {
                Account acc = new Account(Id = request.contextRecord.Id);
                acc.Tract_Payment_Created__c = true;
                UTIL_WSC.doUpdate(acc);
            }
            else if(this.result.statusCode != UTIL_WSC.HTTP_CREATED) {
                UTIL.logClean('WSC_Tract Unknown error, result: ' + this.result);
                response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract Unknown error');
            }
            else {
                UTIL.logClean('Error getting response from server - no response received.');
                response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract No response received from service.');
            }
        }
    }
    
    public static RemoteResponse getOppFromTractServiceId(ID accId, String serviceId){
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result resp;
        req = UTIL_WSC.getWSC_Request('WSC_Tract.GetTractCusFieldVal');
        req.mAdditionalParams.put('objectId', serviceId);
        req.mAdditionalParams.put('objectType', 'services');
        req.init(accId); 
        resp = req.call();
        if ( resp.statusCode != 201 && resp.statusCode != 200){
            return new RemoteResponse((String.isBlank(resp.status) ? resp.errorMsg : resp.status), RemoteResponse.STATUSCODE_ERROR);
        }
        
        List<Object> lstResults = (List<Object>)resp.getResponseData().get('results');
        String oppId;
        
        for(Object resultObj: lstResults){
            Map<String, Object> mObj = (Map<String, Object>) resultObj;
            
            if(mObj.containsKey('custom_field')){
                Map<String, Object> mCusField = (Map<String, Object>) mObj.get('custom_field');
                
                if(mCusField.containsKey('name') && 
                    String.valueOf(mCusField.get('name')).equalsIgnoreCase('SF Opportunity ID') &&
                    mObj.containsKey('value'))
                {
                    oppId = String.valueOf(mObj.get('value'));
                    break;
                }
            }
        }    
        
        RemoteResponse response = new RemoteResponse();
        response.content = oppId;
        response.statusCode = (oppId != null && oppId != '' && oppId.length() >= 15 ? RemoteResponse.STATUSCODE_OK : RemoteResponse.STATUSCODE_ERROR);
        return response;
    }
    
    public class GetTractCusFieldVal extends GenericRequest{
        
        public override void init(Id contextRecordId){
            String objectId = String.valueOf(this.mAdditionalParams.get('objectId'));
            String objectType = String.valueOf(this.mAdditionalParams.get('objectType'));
            this.setCalloutDetails('GetTractCusFieldVal', APINAME);
            super.init(contextRecordId);
            
            this.setHandlerClass(APINAME + '.GetTractCusFieldVal_Handler');
            
            String endPoint = '';
            if( this.baseEndpoint != null ){ 
                endpoint = this.baseEndpoint +  objectType + '/' + objectId + '/custom-field-values';
            }
            this.setEndpoint( endpoint );
            this.setHttpMethod('GET');
        }
    }
    
    public class GetTractCusFieldVal_Handler extends ApiHandler{
        public override void handle() { 
            super.handle();
            if (result.statusCode == 201 || result.statusCode == 200 ) {
                UTIL.log('result GetTractCusFieldVal_Handler: ' + result );
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
    } 
     public static RemoteResponse getTractCustomFieldIdByName(Id recordId,String fieldName){
       
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result resp;
        req = UTIL_WSC.getWSC_Request('WSC_Tract.GetTractCusFieldIdByName');
        req.mAdditionalParams.put('fieldName', fieldName);
        req.init(recordId); 
        resp = req.call();
        if ( resp.statusCode != 201 && resp.statusCode != 200){
            return new RemoteResponse((String.isBlank(resp.status) ? resp.errorMsg : resp.status), RemoteResponse.STATUSCODE_ERROR);
        }
        
        List<Object> lstResults = (List<Object>)resp.getResponseData().get('results');
        Map<String, Object> mapResult = (Map<String, Object>)lstResults[0];
        String tractCusFieldId = String.valueOf(mapResult.get('id'));
                
        RemoteResponse response = new RemoteResponse();
        response.content = tractCusFieldId;
        response.statusCode = RemoteResponse.STATUSCODE_OK;
        return response;
    }
    
      public class GetTractCusFieldIdByName extends GenericRequest{
        
        public override void init(Id contextRecordId){
            String serviceFieldName = String.valueOf(this.mAdditionalParams.get('fieldName'));
            this.setCalloutDetails('GetTractCusFieldIdByName', APINAME);
            super.init(contextRecordId);
            this.setHandlerClass(APINAME + '.GetTractCusFieldIdByName_Handler');
            
            String endPoint = '';
            if( this.baseEndpoint != null ){ 
                endpoint = this.baseEndpoint + serviceFieldName;
            }
            
            this.setEndpoint( endpoint );
            this.setHttpMethod('GET');
        }
    }
    
    public class GetTractCusFieldIdByName_Handler extends ApiHandler{
        public override void handle() { 
            super.handle();

            Opportunity opp = GW_Opportunity.getRecord(request.contextRecord.Id);
            UTIL.log('result GetTractCusFieldIdByName_Handler: ' + result );
            if (result.statusCode == 201 || result.statusCode == 200 ) {
                
                
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
    }
    
    public static Map<String, String> getTractCusFieldsMapNameId(Id oppid, String caller){
        Map<String, String> mapNameId = new Map<String, String>();
        UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request(caller);
        req.init(oppid); 
        UTIL_WSC.WSC_Result resp = req.call();
        if ( resp.statusCode == 200){
            for(Object obj : (List<Object>)resp.getResponseData().get('results')){
                Map<String, Object> mapResult = (Map<String, Object>)obj;
                mapNameId.put(String.valueOf(mapResult.get('name')), String.valueOf(mapResult.get('id')));
            }
        }
        return mapNameId;
    }
    
    public class GetTractOrderCusFields extends GenericRequest {
        public override void init(Id contextRecordId){
            this.setCalloutDetails('GetTractOrderCusFields', APINAME);
            super.init(contextRecordId);
            this.setHandlerClass(APINAME + '.GetTractServiceCusFieldId_Handler');
            this.setEndpoint( this.baseEndpoint + 'order-custom-fields');
            this.setHttpMethod('GET');
        }
    } 
 
    public static RemoteResponse getTractServiceCustomFieldId(Id oppid){
        Opportunity opp = GW_Opportunity.getRecord(oppid);
        
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result resp;
        req = UTIL_WSC.getWSC_Request('WSC_Tract.GetTractServiceCusFieldId');
        req.init(oppid); 
        resp = req.call();
        if ( resp.statusCode != 201 && resp.statusCode != 200){
            return new RemoteResponse((String.isBlank(resp.status) ? resp.errorMsg : resp.status), RemoteResponse.STATUSCODE_ERROR);
        }
        
        List<Object> lstResults = (List<Object>)resp.getResponseData().get('results');
        
        Map<String, String> mapServiceCusFieldId = new Map<String, String>();
        for(Object obj : lstResults){
            Map<String, Object> mapResult = (Map<String, Object>)obj;
            mapServiceCusFieldId.put(String.valueOf(mapResult.get('name')), String.valueOf(mapResult.get('id')));
        }
                
        RemoteResponse response = new RemoteResponse();
        response.content = mapServiceCusFieldId;
        response.statusCode = RemoteResponse.STATUSCODE_OK;
        return response;
    }
    
    public class GetTractServiceCusFieldId extends GenericRequest{
        Opportunity opp;
        
        public override void init(Id contextRecordId){
            this.setCalloutDetails('GetTractServiceCusFieldId', APINAME);
            super.init(contextRecordId);
            
            opp = GW_Opportunity.getRecord(contextRecordId);
            
            this.setHandlerClass(APINAME + '.GetTractServiceCusFieldId_Handler');
            
            String endPoint = '';
            if( this.baseEndpoint != null ){ 
                endpoint = this.baseEndpoint + 'service-custom-fields';
            }
            this.setEndpoint( endpoint );
            this.setHttpMethod('GET');
        }
    }
    
    public class GetTractServiceCusFieldId_Handler extends ApiHandler{
        public override void handle() { 
            super.handle();

            //Opportunity opp = GW_Opportunity.getRecord(request.contextRecord.Id);
            if (result.statusCode == 201 || result.statusCode == 200 ) {
                
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
    } 
    
    public static RemoteResponse getTractAgreementId(Id oppid){
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result resp;
        req = UTIL_WSC.getWSC_Request('WSC_Tract.GetAgreementId');
        req.init(oppid);
        resp = req.call();

        if ( resp.statusCode != 201 && resp.statusCode != 200){
            return new RemoteResponse((String.isBlank(resp.status) ? resp.errorMsg : resp.status), RemoteResponse.STATUSCODE_ERROR);
        }
        List<String> additionalFields = new List<String>{'MemberUnit__r.CurrencyText__c'};
        Opportunity opp = GW_Opportunity.getRecord(oppid, additionalFields);
        RemoteResponse response = new RemoteResponse();
        response.content = opp;
        response.statusCode = resp.statuscode;
        return response;
    }

    public class GetAgreementId_Handler extends ApiHandler{
        public override void handle() {
            super.handle();
            Opportunity opp = GW_Opportunity.getRecord(request.contextRecord.Id);

            if (result.statusCode == 201 || result.statusCode == 200 ) {

                String agreementId = null;
                List <Object> response = (List<Object>) result.getResponseData().get('results');
                for(Object res : response){
                    Map<String,Object> resp = (Map<String,Object>) res;
                    System.debug(resp.get('end_action'));
                    if(resp.get('end_action') == 'RENEW_AGREEMENT'){
                        agreementId = String.valueOf(resp.get('id'));
                        break;
                    }
                }

                opp.Tract_AgreementId__c = agreementId;
                update opp;
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
    }

    public class GetAgreementId extends GenericRequest{
        Opportunity opp;

        public override void init(Id contextRecordId){
            this.setCalloutDetails('GetAgreementId', APINAME);
            super.init(contextRecordId);
            //opp = (Opportunity) this.contextRecord;

            List<String> additionalFields = new List<String>{'MemberUnit__r.CurrencyText__c'};
            opp = GW_Opportunity.getRecord(contextRecordId, additionalFields);

            this.setHandlerClass(APINAME + '.GetAgreementId_Handler');

            String endPoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'agreements?status=ACTIVE&termination_fee_currency_code=' + opp.MemberUnit__r.CurrencyText__c;
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );

            this.setHttpMethod('GET');
        }
    }
    
    public static Map<String, String> getAgreementIds(String oppid){
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result resp;
        req = UTIL_WSC.getWSC_Request('WSC_Tract.GetAgreements');
        req.init(oppid);
        resp = req.call();

        List <Object> response = (List<Object>) resp.getResponseData().get('results');
        if(response == null ) return new Map<String, String>();
        Map<String, String> mapAgreementIds = new Map<String, String>();
        for(Object obj : response){
            Map<String,Object> objresp = (Map<String,Object>) obj;
            String end_action = (String)objresp.get('end_action');
            Integer agreement_period = (Integer)objresp.get('agreement_period');
            String agreementId = (String) objresp.get('id');
            mapAgreementIds.put(end_action + '_' + agreement_period, agreementId);
        }
        return mapAgreementIds;
    }
    
    public class GetAgreements_Handler extends ApiHandler{
        public override void handle() {
            super.handle();
            if (result.statusCode == 201 || result.statusCode == 200 ) {
                //TODO ?
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
    }
    
    public class GetAgreements extends GenericRequest{
        Opportunity opp;

        public override void init(Id contextRecordId){
            this.setCalloutDetails('GetAgreements', APINAME);
            super.init(contextRecordId);
            //opp = (Opportunity) this.contextRecord;

            List<String> additionalFields = new List<String>{'MemberUnit__r.CurrencyText__c'};
            opp = GW_Opportunity.getRecord(contextRecordId, additionalFields);

            this.setHandlerClass(APINAME + '.GetAgreements_Handler');

            String endPoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'agreements?status=ACTIVE&termination_fee_currency_code=' + opp.MemberUnit__r.CurrencyText__c;
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );

            this.setHttpMethod('GET');
        }
    }
    
    public class UpdateAgreementDetailsTract extends GenericRequest{
        Opportunity opp;

        public override void init(Id contextRecordId){
            this.setCalloutDetails('UpdateAgreementDetailsTract',APINAME);
            super.init(contextRecordId);
            opp = (Opportunity)this.contextRecord;
            this.mapper.mappingElements = getMapper_Agreements_Update(opp);
            Map<String,Object> output = this.mapper.getOutputMap();
            system.debug('In AgreementsUpdate');
            system.debug(JSON.serialize(output));
            this.setHandlerClass(APINAME + '.AgreementUpdate_Handler');

            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'agreement-services/'+opp.TRACT_Adjustment_ServiceId__c;
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );

            this.setHttpMethod('PUT');
        }
    }
    
    public static RemoteResponse getServiceAccountFromTract(Id accid){
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result resp; 
        req = UTIL_WSC.getWSC_Request('WSC_Tract.GetServiceAccFromTract');
        req.init(accid);
        resp = req.call();

        if ( resp.statusCode != 201 && resp.statusCode != 200){
            return new RemoteResponse((String.isBlank(resp.status) ? resp.errorMsg : resp.status), RemoteResponse.STATUSCODE_ERROR);
        }
        
        List<Object> lstObj = (List<Object>)resp.getResponseData().get('results');
        RemoteResponse response = new RemoteResponse();
        response.contents = lstObj;
        response.statusCode = resp.statuscode;
        return response;
    }
    
    //CD-3531 temporary service to display on account after order, not correct relation bwt service at this point
    //Daily Import Job service will handle the relationship of services
    public static void syncTractService(Opportunity opp){

        RemoteResponse srServic                 =   WSC_Tract.getServiceAccountFromTract(opp.AccountId);
        List<TRACT_Service__c> lsTrSrToUpsert   =   new List<TRACT_Service__c>();
        Map<String,Object> trService            =   null;
        TRACT_Service__c sdfTrSv                =   null;
        for( Object objTrSv : srServic.contents){
			
            trService = (Map<String,Object>) objTrSv;
            List<Object>lstServicePrices = (List<Object>) trService.get('service_prices');

            sdfTrSv = new TRACT_Service__c();
            sdfTrSv.Name 								= 	(String) trService.get('id');
            sdfTrSv.External_Id__c                      =   (String) trService.get('id');
            sdfTrSv.Commitment_End_Date__c 				= 	Date.valueOf((String) trService.get('commitment_end_date'));
            sdfTrSv.Quantity__c                         =   (Double) trService.get('quantity');
            sdfTrSv.Start_Date__c                       =   Date.valueOf((String) trService.get('start_date'));
            sdfTrSv.End_Date__c  						= 	Date.valueOf((String)((Map<String,Object>) trService.get('current_agreement_service')).get('end_date')); // addddddd
            sdfTrSv.Amount__c                           =   (Double) trService.get('amount');
            sdfTrSv.Description__c                      =   (String) trService.get('description');
            sdfTrSv.Billing_Account__c                  =   (String) ( (Map<String,Object>) trService.get('billing_account')).get('external_account_num');
            sdfTrSv.Status__c                           =   (String) trService.get('status');
            sdfTrSv.Opportunity__c                      =   WSC_Tract.getCustomFieldValueByName( 'SF Opportunity ID', (List<Object>) trService.get('custom_field_values'));
            sdfTrSv.Opportunity_Line_Item_ID__c         =   WSC_Tract.getCustomFieldValueByName( 'SF Opportunity Line Item', (List<Object>) trService.get('custom_field_values'));
            sdfTrSv.TerminationReason__c         		   =   WSC_Tract.getCustomFieldValueByName( 'Termination Reason', (List<Object>) trService.get('custom_field_values'));
            sdfTrSv.Status_Date__c                      =   trService.containsKey('status_date') ? Date.valueOf((String) trService.get('status_date')) : null;
            sdfTrSv.Renewal_Count__c                    =   (Double) trService.get('renewal_count');
            sdfTrSv.Recurrence__c                    	   =   lstServicePrices.isEmpty() ? null : String.valueOf(((Map<String,Object>) lstServicePrices[0]).get('recurrence_period'));
            sdfTrSv.Current_Agreement_Service_Id__c     =   (String) ( (Map<String,Object>) trService.get('current_agreement_service')).get('id');
			sdfTrSv.CurrencyIsoCode					    =   opp.CurrencyIsoCode;
			
            lsTrSrToUpsert.add( sdfTrSv );
        }
        upsert lsTrSrToUpsert External_Id__c;
		Map<Id, OpportunityLineItem> mapLineItem= new Map<Id, OpportunityLineItem>();
        for(TRACT_Service__c service: lsTrSrToUpsert){
        		
	        	 if(service.Opportunity_Line_Item_ID__c != null){
	             OpportunityLineItem oppLine = new OpportunityLineItem();
	             oppLine.Id = service.Opportunity_Line_Item_ID__c  ;
	             oppLine.Tract_ServiceAgreementId__c = service.Current_Agreement_Service_Id__c;
	             
	             mapLineItem.put(oppLine.Id, oppLine);
	        }
        }
       update mapLineItem.values() ;
    }
        
    public static void syncTractRevenueSchedule(Id oppId){
        
        List<TRACT_Service__c>lstTS = (List<TRACT_Service__c>)GW_sObject.queryRecords('TRACT_Service__c', 'Opportunity__c = \'' + oppId + '\'');
        if(lstTS.isEmpty()) return;
        
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result resp; 
        req = UTIL_WSC.getWSC_Request('WSC_Tract_Reporting.GetRevenueSchedule');
        req.init(lstTS[0].Id);
        resp = req.call();
        UTIL_WSC_Tract.TRACTRevenueScheduleSync tractrs = new UTIL_WSC_Tract.TRACTRevenueScheduleSync();
        tractrs.commitAll();
        
    }

    public static String getCustomFieldValueByName(String cfName, List<Object> csvObjects){

        Map<String,Object> csvMapObj    =   null;
        Map<String,Object> csMapObj     =   null;

        for( Object csvObj : csvObjects){

            csvMapObj   =   ( Map<String,Object> ) csvObj;
            csMapObj    =   ( Map<String,Object> ) csvMapObj.get('custom_field');

            if ( cfName.equalsIgnoreCase((String) csMapObj.get('name')) )
                return (String) csvMapObj.get('value');
        }

        return null;

    }
    
    public class GetServiceAccFromTract extends ApiRequest{
        Account acc;

        public override void init(Id contextRecordId){
            this.setCalloutDetails('GetServiceAccFromTract', APINAME);
            super.init(contextRecordId);

            acc = (Account) this.contextRecord;

            this.setHandlerClass(APINAME + '.GetServiceAccFromTract_Handler');

            String endPoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'services?account_num='+ acc.Tract_AccountNumber__c;
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );

            this.setHttpMethod('GET');
        }
        
        public override HttpResponse getMockResponse() { 
        	OpportunityLineItem oppItem = [Select Id, OpportunityId From OpportunityLineItem limit 1];
	        HttpResponse response = new HttpResponse();
	        String resBODY = '[{"amount":0,"status":"ACTIVE","product":{"name":"PRO Paket Individual (unbegrenzt)","sku":"2999999#SF015","id":"467"},"description":"PRO Paket Individual (unbegrenzt)","quantity":1,"consumePrepaidBalance":false,"id":"10164","start_date":"2017-08-30T08:34:16.000+0200","billing_account":{"id":"16614","account_num":"EKA01928","external_account_num":"' + acc.Id +'","bill_cycle":{"bill_cycle_type":"monthly","id":"76","name":"EUR-Kleinanzeigen"},"responsible_party":{"party_type":"organization","id":"17931","organization_name":"Acc Test 30/08","tax_id_validated":true},"billing_account_category":{"id":"15","name":"eBayKleinanzeigen"},"payment_term":{"name":"Immediate","id":"15"},"responsible_account":{"id":"16614","account_num":"EKA01928","external_account_num":"0010k00000HO8HPAA1"}},"status_date":"2017-08-30T08:34:16.000+0200","service_resources":[],"current_agreement_service":{"agreement":{"name":"EUR - 1 Month - Renew Agreement","id":"36","agreement_period":1,"status":"ACTIVE","termination_flat_charge":0,"prorate_on_cancel":false,"adjustment_category":{"charge_category_type":"adjustment","name":"ADJ-Agreement","priority":4,"status":"ACTIVE","id":"101"},"end_action":"RENEW_AGREEMENT","termination_fee_currency_code":"EUR","valid_from":"2017-06-16T00:00:00.000+0200","agreement_period_type":"MONTH","true_up_charge_types":[],"preserve_service_price":true},"renewed":false,"id":"311726","start_date":"2017-08-30T00:00:00.000+0200","end_date":"2017-09-30T00:00:00.000+0200","end_action":"RENEW_AGREEMENT","next_service_pay_on_purchase":false,"preserve_service_price":true,"next_preserve_service_price":false,"true_up_charge_types":[],"accumulated_charges_amount":0},"service_prices":[{"base_price_type":"service","id":"10659","tapered":false,"currency_code":"EUR","category":{"charge_category_type":"price","name":"PRI-K","id":"126"},"amount":0,"start_date":"2017-08-30T08:34:16.000+0200","bill_in_advance":false,"service_price_ranges":[{"id":"10676"}],"recurrence_period":"MONTH","product_price":{"price_type":"recurring","id":"925"},"estimated_invoice_amount":0,"invoice_quantity":1}],"renewal_count":0,"commitment_end_date":"2017-09-30T00:00:00.000+0200","custom_field_values":[{"custom_field_value_type":"service","value":"' + oppItem.OpportunityId + '","id":"156869","custom_field":{"custom_field_type":"service","name":"SF Opportunity ID","id":"73"}},{"custom_field_value_type":"service","value":"' + oppItem.Id + '","id":"156870","custom_field":{"custom_field_type":"service","name":"SF Opportunity Line Item","id":"107"}}],"addresses":[]}]';
	        response.setStatusCode(200);
	        response.setBody(resBODY);
	        response.setStatus('OK');
	        return response; 
	    }
    }
    public class GetServiceAccFromTract_Handler extends ApiHandler{
        public override void handle() {
            super.handle();

            if (result.statusCode == 201 || result.statusCode == 200 ) {
                System.debug('GetServiceAccFromTract_Handler : ' + result.getResponseData().get('results'));
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
    }
    
    private static Date defineOriginEndDate(Date originEndDate, Date adjustStartDate) {
        Date endDate = originEndDate;
        if (originEndDate > adjustStartDate) endDate = adjustStartDate == System.today() ? adjustStartDate.addDays(1) : adjustStartDate;
        return endDate;
    }
    
    private static OpportunityLineItem getOppLineItemByOppIdFromCache(String fieldName, Id oppId) {
        Map<Id,sObject> oli = UTIL.getRelatedFromCache(fieldName, oppId, 'OpportunityLineItem');
        if (oli.isEmpty()) return new OpportunityLineItem();
        return (OpportunityLineItem) oli.values()[0];
    }
    
    public static List<UTIL_Fieldmapper.mappedElement> getMapper_Agreements_Update(Opportunity opp){
        Opportunity originOpp = GW_Opportunity.getRecord(opp.Original_Opportunity__c);
        if (originOpp == null) originOpp = opp; 
        List<String> additionalFields = new List<String>{'Product2.Tract_ParentId__c',
                                                        'Product2.Name',
                                                        'Product2.Tract_PriceId__c'};
        if (originOpp.Id != null) {
            UTIL.cache(GW_sObject.queryRecords('OpportunityLineItem', ' OpportunityId =\''+ opp.Id +'\' OR OpportunityId =\''+ originOpp.Id +'\'', additionalFields ));
        } else {
            UTIL.cache(GW_sObject.queryRecords('OpportunityLineItem', ' OpportunityId =\''+ opp.id +'\' limit 1', additionalFields ));
        }
		
        OpportunityLineItem originOpLi = getOppLineItemByOppIdFromCache('OpportunityId', opp.Original_Opportunity__c);
        OpportunityLineItem opLi = getOppLineItemByOppIdFromCache('OpportunityId', opp.Id);
        
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        UTIL_Fieldmapper.MappedObject agreementDetail = new UTIL_Fieldmapper.MappedObject('agreement');
        agreementDetail.add(new UTIL_Fieldmapper.mappedField('id',originOpp.Tract_AgreementId__c, 'String', 32, FALSE, FALSE));
        elements.add(agreementDetail);
    
        //elements.add(new UTIL_Fieldmapper.mappedField('start_date','2022-12-31', 'String', 18, TRUE, TRUE));
        String endDate = String.valueOf(defineOriginEndDate(originOpLi.until_Date__c, opLi.from_Date__c));
        elements.add(new UTIL_Fieldmapper.mappedField('end_date', parseDate(endDate), 'String', 18, TRUE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('end_action','CHANGE_SERVICE','String', 18, TRUE, TRUE));
    
        UTIL_Fieldmapper.MappedObject nextAgreementDetail = new UTIL_Fieldmapper.MappedObject('next_agreement');
        nextAgreementDetail.add(new UTIL_Fieldmapper.mappedField('id',opp.Tract_AgreementId__c, 'String', 32, FALSE, FALSE));
        elements.add(nextAgreementDetail);
    
        elements.add(new UTIL_Fieldmapper.mappedField('next_end_action','RENEW_AGREEMENT', 'String', 18, TRUE, TRUE));
    
        UTIL_Fieldmapper.MappedObject nextServicePro = new UTIL_Fieldmapper.MappedObject('next_service_product');
        nextServicePro.add(new UTIL_Fieldmapper.mappedField('id',opLi.Product2.Tract_ParentId__c, 'String', 32, FALSE, FALSE));
        nextServicePro.add(new UTIL_Fieldmapper.mappedField('name',opLi.Product2.Name, 'String', 32, FALSE, FALSE));
        elements.add(nextServicePro);
         
        UTIL_Fieldmapper.MappedObject nextServiceProPrice = new UTIL_Fieldmapper.MappedObject('next_service_product_price');
        nextServiceProPrice.add(new UTIL_Fieldmapper.mappedField('id',opLi.Product2.Tract_PriceId__c, 'String', 32, FALSE, FALSE));
        nextServiceProPrice.add(new UTIL_Fieldmapper.mappedField('price',opLi.TotalPrice, 'String', 32, FALSE, FALSE));
        nextServiceProPrice.add(new UTIL_Fieldmapper.mappedField('price_type','recurring', 'String', 32, FALSE, FALSE));
        elements.add(nextServiceProPrice);
         
    
        //elements.add(new UTIL_Fieldmapper.mappedField('preserve_service_price','false', 'String', 18, TRUE, TRUE));
        //elements.add(new UTIL_Fieldmapper.mappedField('next_preserve_service_price','false', 'String', 18, TRUE, TRUE));
        //elements.add(new UTIL_Fieldmapper.mappedField('omit_minimum_amount','false', 'String', 18, TRUE, TRUE));
        //elements.add(new UTIL_Fieldmapper.mappedField('minimumAmount','false', 'String', 18, TRUE, TRUE));
    
        return elements;
    }
    
    public class AgreementUpdate_Handler extends ApiHandler{
        public override void handle() {
            super.handle();
            Map<String,Object> response2 = (Map<String,Object>) result.getResponseData().get('results');

            if (result.statusCode == 201 || result.statusCode == 200 ) {
                Opportunity opp = GW_Opportunity.getRecord(request.contextRecord.Id);
                Opportunity originOpp = GW_Opportunity.getRecord(opp.Original_Opportunity__c);
                MemberUnit__c mu = GW_MemberUnit.getRecord(opp.MemberUnit__c);
                String oldTract_order = opp.Tract_OrderId__c != null ? String.valueOf(opp.Tract_OrderId__c) : ''; 
                if(opp != null){
                    if(!String.isEmpty(oldTract_order)){
                        deletePrevDraftOrder(opp.id, oldTract_order);
                    }
                    
                    opp.Tract_OrderId__c = originOpp.Tract_OrderId__c;
                    opp.Tract_Order_Number__c = originOpp.Tract_Order_Number__c;
                    opp.Tract_Order_Confirm__c = true;
                    List<Opportunity> opps = new List<Opportunity>{opp};
                    if(mu.MemberUnitId__c == 'EBAYKAD') {
                        GW_Opportunity.setTractOrderStatus(opps);
                    }
                    UTIL_WSC.doUpdate(opps[0]);
                    
                    //OpportunityLineItem originOpLi = getOppLineItemByOppIdFromCache('OpportunityId', opp.Original_Opportunity__c);
                    //OpportunityLineItem opLi = getOppLineItemByOppIdFromCache('OpportunityId', opp.Id);
                    //Adjustment call to local platform
                }
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
    }
    
    public class DeactivateServiceTract extends GenericRequest {
        Opportunity opp;
		
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('DeactivateServiceTract', APINAME);
            super.init(contextRecordId);
            opp = GW_Opportunity.getRecord(contextRecordId);
            String serviceEndDate = String.valueOf(this.mAdditionalParams.get('endDate'));
            String agreementId = String.valueOf(this.mAdditionalParams.get('agreementId'));
            String serviceId = String.valueOf(this.mAdditionalParams.get('serviceId'));
            String memberUnitId = String.valueOf(this.mAdditionalParams.get('memberUnit'));
            String localId = String.valueOf(this.mAdditionalParams.get('localid'));
            
            //this.mapper.mappingElements = getMapper_Service_Deactivate(opp, new Map<String,String>{ 'end_date' => serviceEndDate, 'memberUnit' => memberUnitId, 'localid'=>localId } );
            Map<String, Object> output = this.mapper.getOutputMap();
            system.debug('In DeactivateService');
            system.debug(JSON.serialize(output));
            this.setHandlerClass(APINAME + '.DeactivateService_Handler');

            String endpoint = '';
            if (this.baseEndpoint != null) {
                Date eDate = Date.valueOf(serviceEndDate);
                if(eDate == System.today()) {
                    this.mapper.mappingElements = new List<UTIL_Fieldmapper.MappedElement>{
                        new UTIL_Fieldmapper.mappedField('effective_date', system.now(), 'String', 30, TRUE, TRUE)
                    };
                    endpoint = this.baseEndpoint + 'services/' + serviceId + '/deactivate';
                    this.setHttpMethod('POST');

                } else if (eDate < System.today() && eDate.month() == System.today().month() ) {
                    System.debug('same month service deactivation : ');
                    
                    this.mapper.mappingElements = new List<UTIL_Fieldmapper.MappedElement>();
                    DateTime dt = DateTime.newInstance(eDate.addDays(1), Time.newInstance(0, 0, 0, 0));
                    this.mapper.mappingElements.add(new UTIL_Fieldmapper.mappedField('effective_date', dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''), 'String', 32, TRUE, FALSE));

                    endpoint = this.baseEndpoint + 'services/' + serviceId + '/deactivate';
                    this.setHttpMethod('POST');
                    System.debug(this.getBody());
                } else {
                    this.mapper.mappingElements = getMapper_Service_Deactivate(opp, new Map<String,String>{ 'end_date' => serviceEndDate, 'memberUnit' => memberUnitId, 'localid'=>localId } );
                    endpoint = this.baseEndpoint + 'agreement-services/' + agreementId;
                    this.setHttpMethod('PUT');
                }
            }
            this.setEndpoint(endpoint);
            UTIL.log('Endpoint: ' + endpoint);
        }
    }
    
    private static String parseDate(String endDate) {
        if (endDate == null ) return null;
        String[] myDateOnly = endDate.split(' ');
        String[] strDate = myDateOnly[0].split('-');
        Integer myIntDate = integer.valueOf(strDate[2]);
        Integer myIntMonth = integer.valueOf(strDate[1]);
        Integer myIntYear = integer.valueOf(strDate[0]);
        Date d = Date.newInstance(myIntYear, myIntMonth, myIntDate);

        Datetime conFromDate = Datetime.newInstance(d, System.now().time());
        String fromDateConverted = conFromDate.format('yyyy-MM-dd\'T\'hh:mm:ss');
        
        return fromDateConverted;
    }

    public static List<UTIL_Fieldmapper.mappedElement> getMapper_Service_Deactivate(Opportunity opp, Map<String,String> mapParams) {
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        UTIL_Fieldmapper.MappedObject agreementDetail = new UTIL_Fieldmapper.MappedObject('agreement');
        agreementDetail.add(new UTIL_Fieldmapper.mappedField('id',opp.Tract_AgreementId__c, 'String', 32, FALSE, FALSE));
        elements.add(agreementDetail);
        
        for(String key: mapParams.keySet() ) {
            String val = mapParams.get(key);
            if(String.isNotEmpty(val)) {
                 elements.add(new UTIL_Fieldmapper.mappedField( key,val, 'String', 18, TRUE, TRUE));
            }
        }
        elements.add(new UTIL_Fieldmapper.mappedField('end_action','DEACTIVATE_SERVICE','String', 18, TRUE, TRUE));
        return elements;
    }

    public class DeactivateService_Handler extends ApiHandler{
        public override void handle() {
            super.handle();
            Map<String,Object> response2 = (Map<String,Object>) result.getResponseData().get('results');
            String serviceId = String.valueOf(request.mAdditionalParams.get('serviceId'));
    
            if (result.statusCode == UTIL_WSC.HTTP_OK || result.statusCode == UTIL_WSC.HTTP_CREATED || result.statusCode == UTIL_WSC.HTTP_NOCONTENT) {
                TRACT_Service__c[] lservices = GW_TractService.getRecordByExId(serviceId);
                if (!lservices.isEmpty() && serviceId != null) {
                    lservices[0].TractDeactivated__c = true;
                    UTIL_WSC.doUpdate(lservices[0]);
                }
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
    }
    
    public class DraftOrderCreate extends GenericRequest {
        Opportunity opp;

        public override void init(Id contextRecordId){

            this.setCalloutDetails('DraftOrderCreate',APINAME);
			super.init(contextRecordId);
            this.mapper.mappingElements = getMapper_DraftOrder_Create(contextRecordId);
            
            
 
            String endpoint = '';
            opp = GW_Opportunity.getRecord(contextRecordId);
            Account acc = GW_Account.getRecord( opp.AccountId );
            if( this.baseEndpoint != null ){
	            if( opp.TRACT_Ghost_Account_Id__c == null ){
	            	endpoint = this.baseEndpoint + 'billing-accounts/'+ acc.Tract_AccountId__c +'/orders';
	            } else {
	            	endpoint = this.baseEndpoint + 'billing-accounts/'+ opp.TRACT_Ghost_Account_Id__c +'/orders';
	            }
            }    

            UTIL.log('Endpoint: ' + endpoint );
            this.setEndpoint( endpoint );
            this.setHttpMethod('POST');
            this.setHandlerClass(APINAME + '.DraftOrderCreate_Handler');
        }
    }
    
    public class ProductOperation extends GenericRequest {
        Product2 pro;
        
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('ProductOperation', APINAME);
            super.init(contextRecordId);
            pro = (Product2) this.contextRecord;
            
            this.setHandlerClass(APINAME+'.ProductOperation_Handler');
            
            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'actions?product_id=' + pro.Tract_ParentId__c;
            }
            
            this.setEndpoint( endpoint );
            UTIL.log('ProductOperation_Endpoint: ' + endpoint );
            this.setHttpMethod('GET');
        }
    }
    
    public class ProductOperation_Handler extends UTIL_WSC.WSC_ResultHandler {

        public override void handle() {
            super.handle();
            UTIL.log('STATUS CODE '+this.result.statusCode);
            UTIL.log(this.result);
            if (this.result.statusCode == HTTP_OK) {
                //TODO?
            }
        }
    }
    
    private static UTIL_Fieldmapper.mappedList getMapper_OrderItems(List<OpportunityLineItem> lstLineItems, 
                                                                    Map<String, String> mapServiceCusFieldId,
                                                                    String agreementDeactivateId)
    {
        if( mapServiceCusFieldId == null) mapServiceCusFieldId = new Map<String,String>();
        String tractCusFieldId = mapServiceCusFieldId.containsKey(CUS_FIELD_SF_OPP_ID) ? mapServiceCusFieldId.get(CUS_FIELD_SF_OPP_ID): '';
        String tractProdLineIDCusFieldId = mapServiceCusFieldId.containsKey(CUS_FIELD_PRO_LINE_ID) ? mapServiceCusFieldId.get(CUS_FIELD_PRO_LINE_ID): '';
        String tractLineItemCusFieldId = mapServiceCusFieldId.containsKey(CUS_FIELD_SF_LINE_ITEM_ID) ? mapServiceCusFieldId.get(CUS_FIELD_SF_LINE_ITEM_ID): '';
    
        UTIL_Fieldmapper.mappedList mapReturn = new UTIL_Fieldmapper.mappedList('order_items');
        Map<Id, UTIL_Fieldmapper.MappedObject> mapOrderItemWithoutAddOnPro = new Map<Id, UTIL_Fieldmapper.MappedObject>();
    
        for (OpportunityLineItem opli : lstLineItems ){
            Boolean isTrailPro = opli.Product2.Name != null && opli.Product2.Name.containsIgnoreCase('ProbeMonat');
            
            opli.Tract_ServiceId__c = '' + opli.id + DateTime.now().getTime() ;

            UTIL_Fieldmapper.MappedObject mapObjOLI = new UTIL_Fieldmapper.MappedObject('');
            mapObjOLI.add(new UTIL_Fieldmapper.mappedField('order_item_type', 'product', 'String', 32, FALSE, FALSE));
            if (String.isNotBlank(opli.Description)) {
                mapObjOLI.add(new UTIL_Fieldmapper.mappedField('description', opli.Description, 'String', 255, FALSE, FALSE));
            }
            UTIL_Fieldmapper.mappedObject mapProductDetail = new UTIL_Fieldmapper.mappedObject('product');
            mapProductDetail.add(new UTIL_Fieldmapper.mappedField('object_type', 'product', 'String', 32, FALSE, FALSE)).
                    add(new UTIL_Fieldmapper.mappedField('default_quantity', '1.0', 'String', 32, FALSE, FALSE)).
                    add(new UTIL_Fieldmapper.mappedField('id', opli.product2.Tract_ParentId__c, 'String', 32, FALSE, FALSE)).
                    add(new UTIL_Fieldmapper.mappedField('product_type', opli.product2.Tract_ProductType__c, 'String', 32, FALSE, FALSE));

            mapObjOLI.add(mapProductDetail);
            mapObjOLI.add(new UTIL_Fieldmapper.mappedField('unit_price', String.valueOf(opli.TotalPrice), 'String', 32, FALSE, FALSE));
            mapObjOLI.add(new UTIL_Fieldmapper.mappedField('recurring_price', String.valueOf(opli.TotalPrice), 'String', 32, FALSE, FALSE));
            mapObjOLI.add(new UTIL_Fieldmapper.mappedField('quantity', String.valueOf(opli.Quantity), 'String', 32, FALSE, FALSE));

            //map operation_attributes
            addOperationRunAttr(mapObjOLI, opli);
            
            
            //map order_item_price_ranges 
            UTIL_Fieldmapper.mappedList mapListOrderItemPriceRang = new UTIL_Fieldmapper.mappedList('order_item_price_ranges');
          
            UTIL_Fieldmapper.MappedObject mapOrderItemPriceRang = new UTIL_Fieldmapper.MappedObject('');
            mapOrderItemPriceRang.add(new UTIL_Fieldmapper.mappedField('quantity_begin_range', '0.00', 'String', 32, FALSE, FALSE));
            //mapOrderItemPriceRang.add(new UTIL_Fieldmapper.mappedField('quantity_end_range', String.valueOf(opli.Quantity), 'String', 32, FALSE, FALSE));
            mapOrderItemPriceRang.add(new UTIL_Fieldmapper.mappedField('price', String.valueOf(opli.TotalPrice), 'String', 32, FALSE, FALSE));
            //mapOrderItemPriceRang.add(new UTIL_Fieldmapper.mappedField('level', '1', 'String', 32, FALSE, FALSE));
            mapOrderItemPriceRang.add(new UTIL_Fieldmapper.mappedField('currency_code', opli.Opportunity.MemberUnit__r.CurrencyText__c , 'String', 32, FALSE, FALSE));
            mapListOrderItemPriceRang.add(mapOrderItemPriceRang);
          
            //map product_price
            UTIL_Fieldmapper.MappedObject mapProductPrice = new UTIL_Fieldmapper.MappedObject('product_price');
            mapProductPrice.add(new UTIL_Fieldmapper.mappedField('price_type', 'recurring', 'String', 32, FALSE, FALSE));
            mapProductPrice.add(new UTIL_Fieldmapper.mappedField('id',opli.product2.Tract_PriceId__c, 'String', 32, FALSE, FALSE));
          
            //map order_item_prices
            UTIL_Fieldmapper.mappedList mapListOrderItemPrice = new UTIL_Fieldmapper.mappedList('order_item_prices'); 
            UTIL_Fieldmapper.MappedObject mapOrderItemPrice = new UTIL_Fieldmapper.MappedObject('');
            mapOrderItemPrice.add(new UTIL_Fieldmapper.mappedField('order_item_price_type', 'recurring', 'String', 32, FALSE, FALSE));
            mapOrderItemPrice.add(mapProductPrice);
            mapOrderItemPrice.add(mapListOrderItemPriceRang);
            mapListOrderItemPrice.add(mapOrderItemPrice);
          
            mapObjOLI.add(mapListOrderItemPrice);
       
            //map recurring_product_price
            //UTIL_Fieldmapper.MappedObject mapRecurringProPrice = new UTIL_Fieldmapper.MappedObject('recurring_product_price');
            //mapRecurringProPrice.add(new UTIL_Fieldmapper.mappedField('id', '179', 'String', 32, FALSE, FALSE));
            //mapRecurringProPrice.add(new UTIL_Fieldmapper.mappedField('price_type', 'recurring', 'String', 32, FALSE, FALSE));
            //mapObjOLI.add(mapRecurringProPrice);
            
            //map selected_agreement
            UTIL_Fieldmapper.MappedObject orderItemAgreement = new UTIL_Fieldmapper.MappedObject('order_item_agreement');
            UTIL_Fieldmapper.MappedObject mapSelectedAgreement = new UTIL_Fieldmapper.MappedObject('agreement');
            mapSelectedAgreement.add(new UTIL_Fieldmapper.mappedField('id', (isTrailPro ? agreementDeactivateId: opli.Opportunity.Tract_AgreementId__c), 'String', 32, FALSE, FALSE));
            orderItemAgreement.add(mapSelectedAgreement);
            
            if(isTrailPro || opli.SetEndDate__c) {
                orderItemAgreement.add(new UTIL_Fieldmapper.mappedField('end_action','DEACTIVATE_SERVICE','String', 18, TRUE, TRUE));
            }
            
            Date lastDate;
            if( isTrailPro ) {
                lastDate = opli.until_Date__c;
            } else {
                if (opli.until_Date__c == null) lastDate = System.today().addMonths(2).toStartOfMonth().addDays(-1);
                else lastDate = (opli.From_Date__c == opli.until_Date__c) ? opli.until_Date__c.addDays(1) : opli.until_Date__c;
            }
            Datetime lastDatetime = Datetime.newInstance(lastDate, System.now().time());
            String lastDatetimeFormated = lastDatetime.format('yyyy-MM-dd\'T\''+'23:59:59');
            orderItemAgreement.add(new UTIL_Fieldmapper.mappedField('end_date', lastDatetimeFormated , 'String', 32, FALSE, FALSE));
            mapObjOLI.add(orderItemAgreement);
            
            //map custom_field_values
            UTIL_Fieldmapper.mappedList mapListCusFieldVal = new UTIL_Fieldmapper.mappedList('custom_field_values'); 
            
            //map custom_field SF Opportunity Line Item
            if(String.isNotBlank(tractLineItemCusFieldId)){
                UTIL_Fieldmapper.MappedObject mapCusFieldValOpli = new UTIL_Fieldmapper.MappedObject('');
                mapCusFieldValOpli.add(new UTIL_Fieldmapper.mappedField('custom_field_value_type', 'service', 'String', 32, FALSE, FALSE));
                mapCusFieldValOpli.add(new UTIL_Fieldmapper.mappedField('value', opli.id, 'String', 32, FALSE, TRUE));

                UTIL_Fieldmapper.MappedObject mapCusFieldOpli = new UTIL_Fieldmapper.MappedObject('custom_field');
                mapCusFieldOpli.add(new UTIL_Fieldmapper.mappedField('custom_field_type', 'service', 'String', 32, FALSE, FALSE));
                mapCusFieldOpli.add(new UTIL_Fieldmapper.mappedField('name', 'SF Opportunity Line Item', 'String', 32, FALSE, FALSE));
                mapCusFieldOpli.add(new UTIL_Fieldmapper.mappedField('id', tractLineItemCusFieldId, 'String', 32, FALSE, FALSE));
                
                mapCusFieldValOpli.add(mapCusFieldOpli);
                mapListCusFieldVal.add(mapCusFieldValOpli);
            }
            
            //map custom_field SF Opportunity ID
            if(String.isNotBlank(tractCusFieldId)){
                UTIL_Fieldmapper.MappedObject mapCusField = new UTIL_Fieldmapper.MappedObject('custom_field');
                mapCusField.add(new UTIL_Fieldmapper.mappedField('custom_field_type', 'service', 'String', 32, FALSE, FALSE));
                mapCusField.add(new UTIL_Fieldmapper.mappedField('name', 'SF Opportunity ID', 'String', 32, FALSE, FALSE));
                mapCusField.add(new UTIL_Fieldmapper.mappedField('id', tractCusFieldId, 'String', 32, FALSE, FALSE));
                
                UTIL_Fieldmapper.MappedObject mapCusFieldVal = new UTIL_Fieldmapper.MappedObject('');
                mapCusFieldVal.add(new UTIL_Fieldmapper.mappedField('custom_field_value_type', 'service', 'String', 32, FALSE, FALSE));
                mapCusFieldVal.add(new UTIL_Fieldmapper.mappedField('value', opli.OpportunityId, 'String', 32, FALSE, FALSE));
                
                mapCusFieldVal.add(mapCusField);
                mapListCusFieldVal.add(mapCusFieldVal);
            }
            
            //map custom_field Product Line ID
            if(String.isNotBlank(tractProdLineIDCusFieldId) && String.isNotBlank(opli.Opportunity.SAPProductLine__c) && opli.Opportunity.SAPProductLine__c.contains(':')){
                UTIL_Fieldmapper.MappedObject mapCusFieldValSAP = new UTIL_Fieldmapper.MappedObject('');
                mapCusFieldValSAP.add(new UTIL_Fieldmapper.mappedField('custom_field_value_type', 'service', 'String', 32, FALSE, FALSE));
                mapCusFieldValSAP.add(new UTIL_Fieldmapper.mappedField('value', opli.Opportunity.SAPProductLine__c.split(':')[1], 'String', 32, FALSE, TRUE));

                //SAP Product Line field
                UTIL_Fieldmapper.MappedObject mapCusFieldSAP = new UTIL_Fieldmapper.MappedObject('custom_field');
                mapCusFieldSAP.add(new UTIL_Fieldmapper.mappedField('custom_field_type', 'service', 'String', 32, FALSE, FALSE));
                mapCusFieldSAP.add(new UTIL_Fieldmapper.mappedField('name', 'Product Line ID', 'String', 32, FALSE, FALSE));
                mapCusFieldSAP.add(new UTIL_Fieldmapper.mappedField('id', tractProdLineIDCusFieldId, 'String', 32, FALSE, FALSE));
                mapCusFieldValSAP.add(mapCusFieldSAP);
                mapListCusFieldVal.add(mapCusFieldValSAP);
            }
            
            mapObjOLI.add(mapListCusFieldVal); 
      
            // the service_resource part needs to be added ONLY if product2.Tract_ServiceResourceCategoryId__c
            if (!String.isBlank(opli.Ad_Id__c)) {
                UTIL_Fieldmapper.mappedList mapServiceRes = new UTIL_Fieldmapper.mappedList('service_resources');
                UTIL_Fieldmapper.MappedObject mapServiceDetail = new UTIL_Fieldmapper.MappedObject('');
                String networkId = DARTUtil.getCredential(opli.PricebookEntry.Product2.RecordType.Name, opli.PriceBookEntry.Product2.Site__r.Country__c).Network_Id__c;
                mapServiceDetail.add(new UTIL_Fieldmapper.mappedField('resource_type', 'service', 'String', 32, FALSE, FALSE)).
                        add(new UTIL_Fieldmapper.mappedField('identifier', networkId + '_' + opli.Ad_Id__c, 'String', 32, FALSE, FALSE)).
                        add(new UTIL_Fieldmapper.mappedObject('category').add(new UTIL_Fieldmapper.mappedField('id', opli.product2.Tract_ServiceResourceCategoryId__c, 'Double', 32, FALSE, FALSE)));
                mapServiceRes.add(mapServiceDetail);
                mapObjOLI.add(mapServiceRes);
            }

            mapOrderItemWithoutAddOnPro.put(opli.Id, mapObjOLI);
        }
        list<OpportunityLineItem> lstaddons =  [select id, name, Description__c, UnitPrice, TotalPrice, OpportunityId, Quantity, ParentOpportunityLineItemId__c, Product2.Name, 
                                                    Tract_ServiceId__c, product2.Tract_ParentId__c,product2.Tract_PriceId__c, product2.Tract_ProductType__c, Product2ID, 
                                                    product2.Tract_ProductTags__c, product2.Tract_ServiceResourceCategoryId__c ,Opportunity.MemberUnit__r.CurrencyText__c
                                                from OpportunityLineItem 
                                                where ParentOpportunityLineItemId__c in: mapOrderItemWithoutAddOnPro.keySet() ];
                                                
        Set<String> proNamesOneTime = new Set<String>(); 
        Map<ID, List<OpportunityLineItem>> mapLstAddOns = new Map<ID, List<OpportunityLineItem>>();
        for(OpportunityLineItem opliAddOn: lstaddons){
            String proName = opliAddOn.Product2.Name.toLowerCase().replace('[one-time]', '').trim() + ' recurring%';
            proNamesOneTime.add(proName);
            
            if(!mapLstAddOns.containsKey(opliAddOn.ParentOpportunityLineItemId__c)){
                mapLstAddOns.put(opliAddOn.ParentOpportunityLineItemId__c, new List<OpportunityLineItem>());
            }
            mapLstAddOns.get(opliAddOn.ParentOpportunityLineItemId__c).add(opliAddOn);
        }
        
        
        Map<String, Product2> mapPros = new Map<String, Product2>();
        List<Product2> lstPros = [Select Name, Tract_PriceId__c From Product2 Where Name like :proNamesOneTime  AND IsActive = true];
        for(Product2 pro: lstPros){
            //remove [*] from product name so we can compare for one-time product
            String proName = pro.Name.toLowerCase().replaceAll('\\[.+\\]', '').trim();
            mapPros.put(proName, pro);
        }
        
        for(String opliId : mapOrderItemWithoutAddOnPro.keySet()){
            UTIL_Fieldmapper.MappedObject mapObjOLI = mapOrderItemWithoutAddOnPro.get(opliId);
            
            // check if there any addon's related this oli
            //String whereClause = 'ParentOpportunityLineItemId__c = ' + '\'' + opli.Id + '\'';
            list<OpportunityLineItem> addons =  mapLstAddOns.containsKey(opliId) ? mapLstAddOns.get(opliId) : new List<OpportunityLineItem>();
            if(!addons.isEmpty()){
                mapObjOLI.add(getMapper_AddonsItems(addons, mapPros));
            }
            
            mapReturn.add(mapObjOLI);
        }
        return mapReturn;

    }

    private static UTIL_Fieldmapper.mappedList getMapper_AddonsItems(List<OpportunityLineItem> lstAddonsItems, Map<String, Product2> mapPros) {

        UTIL_Fieldmapper.mappedList mapReturn = new UTIL_Fieldmapper.mappedList('order_items');
        for(OpportunityLineItem oli : lstAddonsItems) {
            
            Boolean isOneTime = oli.Name.endswithignorecase('[ONE-TIME]');
            
            UTIL_Fieldmapper.MappedObject addonsDetail = new UTIL_Fieldmapper.MappedObject('');
            addonsDetail.add(new UTIL_Fieldmapper.mappedField('order_item_type', 'addon', 'String', 32, FALSE, FALSE));
            addonsDetail.add(new UTIL_Fieldmapper.mappedField('quantity', String.valueOf(oli.Quantity), 'String', 32, FALSE, FALSE));
            UTIL_Fieldmapper.mappedObject mapProductDetail = new UTIL_Fieldmapper.mappedObject('product');
            mapProductDetail.add(new UTIL_Fieldmapper.mappedField('object_type', 'product', 'String', 32, FALSE, FALSE)).
                    add(new UTIL_Fieldmapper.mappedField('default_quantity', '1.0', 'String', 32, FALSE, FALSE)).
                    add(new UTIL_Fieldmapper.mappedField('id', oli.product2.Tract_ParentId__c, 'String', 32, FALSE, FALSE)).
                    add(new UTIL_Fieldmapper.mappedField('product_type', oli.product2.Tract_ProductType__c, 'String', 32, FALSE, FALSE));
            
            
            //order_item_prices
            UTIL_Fieldmapper.mappedList mapListOrderItemPrice = new UTIL_Fieldmapper.mappedList('order_item_prices'); 
            String proId4normalAddon = '';
            
            if(isOneTime){
                String keyProName = oli.Product2.Name.toLowerCase().replace('[one-time]', '').trim() + ' recurring';
                if(mapPros.containsKey(keyProName)){
                    proId4normalAddon = mapPros.get(keyProName).Tract_PriceId__c;
                }
            }
            
            //order_item_price_ranges
            UTIL_Fieldmapper.mappedList mapListOrderItemPriceRang = new UTIL_Fieldmapper.mappedList('order_item_price_ranges');
            UTIL_Fieldmapper.MappedObject mapOrderItemPriceRang = new UTIL_Fieldmapper.MappedObject('');
            mapOrderItemPriceRang.add(new UTIL_Fieldmapper.mappedField('quantity_begin_range', '0.00', 'String', 32, FALSE, FALSE));
            mapOrderItemPriceRang.add(new UTIL_Fieldmapper.mappedField('price', (isOneTime ? '0' : String.valueOf(oli.TotalPrice)), 'String', 32, FALSE, FALSE));
            mapOrderItemPriceRang.add(new UTIL_Fieldmapper.mappedField('currency_code', oli.Opportunity.MemberUnit__r.CurrencyText__c , 'String', 32, FALSE, FALSE));
            mapListOrderItemPriceRang.add(mapOrderItemPriceRang);
          
            //product_price
            UTIL_Fieldmapper.MappedObject mapProductPrice = new UTIL_Fieldmapper.MappedObject('product_price');
            mapProductPrice.add(new UTIL_Fieldmapper.mappedField('price_type', 'recurring', 'String', 32, FALSE, FALSE));
            mapProductPrice.add(new UTIL_Fieldmapper.mappedField('id', (isOneTime ? proId4normalAddon : oli.product2.Tract_PriceId__c), 'String', 32, FALSE, FALSE));
         
            
            UTIL_Fieldmapper.MappedObject mapOrderItemPrice = new UTIL_Fieldmapper.MappedObject('');
            mapOrderItemPrice.add(new UTIL_Fieldmapper.mappedField('order_item_price_type', 'recurring', 'String', 32, FALSE, FALSE));
            mapOrderItemPrice.add(mapProductPrice);
            mapOrderItemPrice.add(mapListOrderItemPriceRang);
            mapListOrderItemPrice.add(mapOrderItemPrice);
            
            if(isOneTime){
                //order_item_price_ranges
                UTIL_Fieldmapper.mappedList mapListOneTimeOrderItemPriceRang = new UTIL_Fieldmapper.mappedList('order_item_price_ranges');
                UTIL_Fieldmapper.MappedObject mapOrderItemOneTimePriceRang = new UTIL_Fieldmapper.MappedObject('');
                mapOrderItemOneTimePriceRang.add(new UTIL_Fieldmapper.mappedField('quantity_begin_range', '0.00', 'String', 32, FALSE, FALSE));
                mapOrderItemOneTimePriceRang.add(new UTIL_Fieldmapper.mappedField('price', String.valueOf(oli.TotalPrice), 'String', 32, FALSE, FALSE));
                mapOrderItemOneTimePriceRang.add(new UTIL_Fieldmapper.mappedField('currency_code', oli.Opportunity.MemberUnit__r.CurrencyText__c , 'String', 32, FALSE, FALSE));
                mapListOneTimeOrderItemPriceRang.add(mapOrderItemOneTimePriceRang);
                
                //product_price
                UTIL_Fieldmapper.MappedObject mapOnetimeProductPrice = new UTIL_Fieldmapper.MappedObject('product_price');
                mapOnetimeProductPrice.add(new UTIL_Fieldmapper.mappedField('price_type', 'one-time', 'String', 32, FALSE, FALSE));
                mapOnetimeProductPrice.add(new UTIL_Fieldmapper.mappedField('id',oli.product2.Tract_PriceId__c, 'String', 32, FALSE, FALSE));
                
                UTIL_Fieldmapper.MappedObject mapOnetimeOrderItemPrice = new UTIL_Fieldmapper.MappedObject('');
                mapOnetimeOrderItemPrice.add(new UTIL_Fieldmapper.mappedField('order_item_price_type', 'one-time', 'String', 32, FALSE, FALSE));
                mapOnetimeOrderItemPrice.add(mapOnetimeProductPrice);
                mapOnetimeOrderItemPrice.add(mapListOneTimeOrderItemPriceRang);
                mapListOrderItemPrice.add(mapOnetimeOrderItemPrice);
            }
            
            addonsDetail.add(mapProductDetail);
            addonsDetail.add(mapListOrderItemPrice);
            mapReturn.add(addonsDetail);
        }
        return mapReturn;
    }


    public static List<UTIL_Fieldmapper.mappedElement> getMapper_DraftOrder_Create(Id oppId){
        
        RemoteResponse res = WSC_Tract.getTractServiceCustomFieldId(oppId); 
        Map<String, String> mapServiceCusFieldId = (Map<String, String>) res.content;
        
        Map<String, String> mapAgreementIds = WSC_Tract.getAgreementIds(oppId);
        String agreementDeactivateId = mapAgreementIds.containsKey('DEACTIVATE_SERVICE_1') ? mapAgreementIds.get('DEACTIVATE_SERVICE_1'): '';
        
        //Opportunity opp = (Opportunity) UTIL.getCached(oppId);
        List<String> additionalFieldOpp = new List<String>{'Account.Name'};
        Opportunity opp = GW_Opportunity.getRecord(oppId, additionalFieldOpp);
        
        Map<String, String> mapOrderCusFieldId = WSC_Tract.getTractCusFieldsMapNameId(opp.Id, 'WSC_Tract.GetTractOrderCusFields');
        
        // check if opportunity has opportunitylineitems.HasOpportunityLineItem
        List<OpportunityLineItem> oplLst = [
            SELECT Id, Name, Description__c, UnitPrice, TotalPrice, OpportunityId, From_Date__c, Until_Date__c, Product2.Description, Product2.Name,
                Quantity, Tract_ServiceId__c, Product2.Tract_ParentId__c, Product2.Tract_PriceId__c, Product2.Tract_ProductType__c, 
                Product2.Tract_ProductTags__c, Product2.Tract_ServiceResourceCategoryId__c, Opportunity.Tract_AgreementId__c,
                Opportunity.MemberUnit__r.CurrencyText__c, ParentOpportunityLineItemId__c, 
                Opportunity.SAPProductLine__c, PricebookEntry.Product2.RecordType.Name, PriceBookEntry.Product2.Site__r.Country__c, Description, SetEndDate__c
            FROM OpportunityLineItem 
            WHERE OpportunityId =: oppId AND ParentOpportunityLineItemId__c = null
        ];
        
        // List<AccountMemberUnitAssociation__c> amuaList = GW_AccountMemberUnitAssociation.getAll(accId);
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add(new UTIL_Fieldmapper.mappedField('initial_status',                 'DRAFT', 'String', 32, FALSE, FALSE));
        elements.add(new UTIL_Fieldmapper.mappedField('note',                           'Order Note', 'String', 18, TRUE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('email_receipt',                  'true', 'String', 18, TRUE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('purchase_order_number',          (String.isBlank(opp.P_O_Number__c) ? ' ' : opp.P_O_Number__c),'String', 18, TRUE, TRUE));
        //elements.add(new UTIL_Fieldmapper.mappedField('referral',                       opp.Account.Name, 'String', 18, TRUE, TRUE));
        
        elements.add(getMapper_OrderItems(oplLst, mapServiceCusFieldId, agreementDeactivateId));
        elements.add(getListOrderCustomFieldValues(opp, mapOrderCusFieldId, false));

        return elements;
    }

    public class DraftOrderAdSalesCreate extends GenericRequest {
        Opportunity opp;

        public override void init(Id contextRecordId){

            this.setCalloutDetails('DraftOrderAdSalesCreate',APINAME);
            this.setHeader('Content-Type', 'application/json');

            super.init(contextRecordId);

            opp = GW_Opportunity.getRecord(contextRecordId, new List<String>{'Account.Name', 'Account.Tract_AccountId__c'});
            this.mapper.mappingElements = getMapper_DraftOrderAdSalesCreate(opp);

            String endpoint = '';
            Account acc = GW_Account.getRecord( opp.AccountId );
            if( this.baseEndpoint != null ){
	            if( opp.TRACT_Ghost_Account_Id__c == null ){
	            	endpoint = this.baseEndpoint + 'billing-accounts/'+ acc.Tract_AccountId__c +'/orders';
	            } else {
	            	endpoint = this.baseEndpoint + 'billing-accounts/'+ opp.TRACT_Ghost_Account_Id__c +'/orders';
	            }
            }    

            this.setEndpoint( endpoint );
            this.setHttpMethod('POST');
            this.setHandlerClass(APINAME + '.DraftOrderCreate_Handler');
        }
    }

    public static List<UTIL_Fieldmapper.mappedElement> getMapper_DraftOrderAdSalesCreate(Opportunity opp){
        Map<String, String> mapOrderCusFieldId = WSC_Tract.getTractCusFieldsMapNameId(opp.Id, 'WSC_Tract.GetTractOrderCusFields'); 
        Map<String, String> mapServiceCusFieldId = WSC_Tract.getTractCusFieldsMapNameId(opp.Id, 'WSC_Tract.GetTractServiceCusFieldId');
        
        List<OpportunityLineItem> oplLst = [select id, name, Description__c, UnitPrice, TotalPrice, OpportunityId, from_Date__c, until_Date__c, PriceBookEntry.Product2.Tract_ParentId__c,
                          Quantity, Tract_ServiceId__c, product2.Tract_ParentId__c,product2.Tract_PriceId__c, product2.Tract_ProductType__c, 
                          product2.Tract_ProductTags__c, product2.Tract_ServiceResourceCategoryId__c, Opportunity.Tract_AgreementId__c,
                          Opportunity.MemberUnit__r.CurrencyText__c, ParentOpportunityLineItemId__c, Opportunity.SAPProductLine__c ,
                          Ad_Id__c, PricebookEntry.Product2.RecordType.Name, PriceBookEntry.Product2.Site__r.Country__c, Description,
                          PriceBookEntry.Product2.Tract_Usage_ID__c, PriceBookEntry.Product2.Tract_Usage_Rate_ID__c, ListPriceCorrectionForm__c,
						  Billing_Category__c, ListPriceCorrection__c, ListPrice, TotalAmountNet__c, ListPrice__c
                          from OpportunityLineItem where OpportunityId =: opp.Id ];
        
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add(new UTIL_Fieldmapper.mappedField('initial_status',                 'DRAFT', 'String', 32, FALSE, FALSE));
        elements.add(new UTIL_Fieldmapper.mappedField('note',                           'Order Note', 'String', 18, TRUE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('email_receipt',                  'true', 'String', 18, TRUE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('purchase_order_number',          (String.isBlank(opp.P_O_Number__c) ? ' ' : opp.P_O_Number__c),'String', 18, TRUE, TRUE));
        //elements.add(new UTIL_Fieldmapper.mappedField('referral',                       opp.Account.Name, 'String', 18, TRUE, TRUE));
        elements.add(getMapper_DraftOrderAdSalesItems(oplLst, mapOrderCusFieldId, mapServiceCusFieldId));
        
		//generate custom field value mapper
        UTIL_Fieldmapper.mappedList mapListCusFieldVal = getListOrderCustomFieldValues(opp, mapOrderCusFieldId, true); 
		
        elements.add(mapListCusFieldVal);   
         
        return elements;
    }
    
    private static UTIL_Fieldmapper.mappedObject getMapProductDetail(OpportunityLineItem opli) {
        UTIL_Fieldmapper.mappedObject mapProductDetail = new UTIL_Fieldmapper.mappedObject('product');
        mapProductDetail.add(new UTIL_Fieldmapper.mappedField('object_type', 'product', 'String', 32, FALSE, FALSE)).
                add(new UTIL_Fieldmapper.mappedField('default_quantity', '1.0', 'String', 32, FALSE, FALSE)).
                add(new UTIL_Fieldmapper.mappedField('id', opli.product2.Tract_ParentId__c, 'String', 32, FALSE, FALSE)).
                add(new UTIL_Fieldmapper.mappedField('product_type', opli.product2.Tract_ProductType__c, 'String', 32, FALSE, FALSE));
        return mapProductDetail;
    }
    private static UTIL_Fieldmapper.mappedList getListOrderItemPrice(OpportunityLineItem opli) {
        UTIL_Fieldmapper.mappedList mapListOrderItemPrice = new UTIL_Fieldmapper.mappedList('order_item_prices'); 
        UTIL_Fieldmapper.MappedObject mapOrderItemPrice = new UTIL_Fieldmapper.MappedObject('');
        mapOrderItemPrice.add(new UTIL_Fieldmapper.mappedField('order_item_price_type', 'recurring', 'String', 32, FALSE, FALSE));
        mapOrderItemPrice.add(new UTIL_Fieldmapper.MappedObject('product_price').add(new UTIL_Fieldmapper.mappedField('price_type', 'recurring', 'String', 32, FALSE, FALSE)).
                                                                                 add(new UTIL_Fieldmapper.mappedField('id',opli.product2.Tract_PriceId__c, 'String', 32, FALSE, FALSE)));
        mapOrderItemPrice.add(new UTIL_Fieldmapper.mappedList('order_item_price_ranges').add(new UTIL_Fieldmapper.MappedObject('').add(new UTIL_Fieldmapper.mappedField('quantity_begin_range', '0.00', 'String', 32, FALSE, FALSE)).
                                                                                                                                   add(new UTIL_Fieldmapper.mappedField('price', '0.00', 'String', 32, FALSE, FALSE)).
                                                                                                                                   add(new UTIL_Fieldmapper.mappedField('currency_code', opli.Opportunity.MemberUnit__r.CurrencyText__c , 'String', 32, FALSE, FALSE))));
        if (opli.PriceBookEntry.Product2.Tract_Usage_ID__c != null && opli.PriceBookEntry.Product2.Tract_Usage_Rate_ID__c != null) mapOrderItemPrice.add(getListOrderItemPriceUsageRule(opli));
        mapListOrderItemPrice.add(mapOrderItemPrice);
        return mapListOrderItemPrice;
    }
    
    
    private static UTIL_Fieldmapper.mappedList getListCustomFieldValues(OpportunityLineItem opli, Map<String, String> mapOrderCusFieldId, Map<String, String> mapServiceCusFieldId) {
        UTIL_Fieldmapper.mappedList mapListCusFieldVal = new UTIL_Fieldmapper.mappedList('custom_field_values'); 
        
        UTIL_Fieldmapper.MappedObject mapCusFieldVal = new UTIL_Fieldmapper.MappedObject('');
        mapCusFieldVal.add(new UTIL_Fieldmapper.mappedField('custom_field_value_type', 'service', 'String', 32, FALSE, FALSE));
        mapCusFieldVal.add(new UTIL_Fieldmapper.mappedField('value', opli.OpportunityId, 'String', 32, FALSE, FALSE));
        
            UTIL_Fieldmapper.MappedObject mapCusField = new UTIL_Fieldmapper.MappedObject('custom_field');
            mapCusField.add(new UTIL_Fieldmapper.mappedField('custom_field_type', 'service', 'String', 32, FALSE, FALSE));
            mapCusField.add(new UTIL_Fieldmapper.mappedField('name', 'SF Opportunity ID', 'String', 32, FALSE, FALSE));
            mapCusField.add(new UTIL_Fieldmapper.mappedField('id', mapServiceCusFieldId.get('SF Opportunity ID'), 'String', 32, FALSE, FALSE));
        
        
        mapCusFieldVal.add(mapCusField);
        mapListCusFieldVal.add(mapCusFieldVal);
        
        UTIL_Fieldmapper.MappedObject mapCusFieldValSAP = new UTIL_Fieldmapper.MappedObject('');
        mapCusFieldValSAP.add(new UTIL_Fieldmapper.mappedField('custom_field_value_type', 'service', 'String', 32, FALSE, FALSE));
        String sapProLine = opli.Opportunity.SAPProductLine__c;
        sapProLine = (String.isNotBlank(sapProLine) && sapProLine.contains(':')) ? opli.Opportunity.SAPProductLine__c.split(':')[1] : '';
        mapCusFieldValSAP.add(new UTIL_Fieldmapper.mappedField('value', sapProLine, 'String', 32, FALSE, TRUE));
            //SAP Product Line field
            UTIL_Fieldmapper.MappedObject mapCusFieldSAP = new UTIL_Fieldmapper.MappedObject('custom_field');
            mapCusFieldSAP.add(new UTIL_Fieldmapper.mappedField('custom_field_type', 'service', 'String', 32, FALSE, FALSE));
            mapCusFieldSAP.add(new UTIL_Fieldmapper.mappedField('name', 'Product Line ID', 'String', 32, FALSE, FALSE));
            mapCusFieldSAP.add(new UTIL_Fieldmapper.mappedField('id', mapServiceCusFieldId.get('Product Line ID'), 'String', 32, FALSE, FALSE));
        mapCusFieldValSAP.add(mapCusFieldSAP);
        mapListCusFieldVal.add(mapCusFieldValSAP);
        
        UTIL_Fieldmapper.MappedObject mapCusFieldValOpli = new UTIL_Fieldmapper.MappedObject('');
        mapCusFieldValOpli.add(new UTIL_Fieldmapper.mappedField('custom_field_value_type', 'service', 'String', 32, FALSE, FALSE));
        mapCusFieldValOpli.add(new UTIL_Fieldmapper.mappedField('value', opli.id, 'String', 32, FALSE, TRUE));
            UTIL_Fieldmapper.MappedObject mapCusFieldOpli = new UTIL_Fieldmapper.MappedObject('custom_field');
            mapCusFieldOpli.add(new UTIL_Fieldmapper.mappedField('custom_field_type', 'service', 'String', 32, FALSE, FALSE));
            mapCusFieldOpli.add(new UTIL_Fieldmapper.mappedField('name', 'SF Opportunity Line Item', 'String', 32, FALSE, FALSE));
            mapCusFieldOpli.add(new UTIL_Fieldmapper.mappedField('id', mapServiceCusFieldId.get('SF Opportunity Line Item'), 'String', 32, FALSE, FALSE));
                
        mapCusFieldValOpli.add(mapCusFieldOpli);
        mapListCusFieldVal.add(mapCusFieldValOpli);
                
        
        return mapListCusFieldVal;
    }
    
    // Update: In Progress Approval Date (In Order detial UI) for both Adsales and Subcription
    public class OrderItemStartDateUpdate extends GenericRequest {
        public override void init(Id contextRecordId){
            this.setCalloutDetails('OrderItemStartDateUpdate',APINAME);
            super.init(contextRecordId);
            // Get param
            String orderId = String.valueOf(this.mAdditionalParams.get('opp.Tract_Order_Id'));
            String itemId = String.valueOf(this.mAdditionalParams.get('OrderItem.id'));
            String itemStartDate = String.valueOf(this.mAdditionalParams.get('oli.from_Date'));
            String operRunAttributeId = String.valueOf(this.mAdditionalParams.get('item.operation_run_attribute.id'));
            String operRunAttributeType = String.valueOf(this.mAdditionalParams.get('item.operation_run_attribute.type'));
            // Set request body
            List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
			elements.add(new UTIL_Fieldmapper.mappedField( 'operation_run_attribute_type', operRunAttributeType, 'String', 50, TRUE, TRUE));
			elements.add(new UTIL_Fieldmapper.mappedField( 'auto_approve_date', itemStartDate, 'String', 50, TRUE, TRUE));
            this.mapper.mappingElements = elements;
            
            this.setHeader('Content-Type', 'application/json');
            String endpoint = this.baseEndpoint + 'orders/' + orderId + '/order-items/' + itemId + '/operation-run-attributes/'+operRunAttributeId;
            
            this.setEndpoint( endpoint );
            this.setHttpMethod('PUT');
        }
    }
    
	public class OrderAdSalesUpdate extends GenericRequest {
    		// contextRecordId is opp.id
        public override void init(Id contextRecordId){
            this.setCalloutDetails('OrderAdSalesUpdate',APINAME);
            super.init(contextRecordId);
            
            String serviceId = String.valueOf(this.mAdditionalParams.get('id'));
            String usageRuleId = String.valueOf(this.mAdditionalParams.get('usage_rule/id'));
            String oppItemid = String.valueOf(this.mAdditionalParams.get('oppItemid'));
            
            this.mapper.mappingElements = getMapper_OrderAdSalesUpdate(GW_OpportunityLineItem.getRecord(oppItemid), this.mAdditionalParams);
            this.setHeader('Content-Type', 'application/json');
            String endpoint = this.baseEndpoint + 'services/' + serviceId + '/usage-rules/' + usageRuleId;
            
            this.setEndpoint( endpoint );
            this.setHttpMethod('PUT');
        }
    }
    private static List<UTIL_Fieldmapper.mappedElement> getMapper_OrderAdSalesUpdate(OpportunityLineItem oli, Map<String, Object> mapVal) {
    		Decimal rate = GW_OpportunityLineItem.getAdsaleRate(oli);
    		
    		List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        		elements.add(new UTIL_Fieldmapper.MappedField('usage_rule_type', 'service', 'String', 15, TRUE, TRUE));
        		elements.add(new UTIL_Fieldmapper.MappedField('name',	'CPM Usage', 'String', 15, TRUE, TRUE));
            	elements.add(new UTIL_Fieldmapper.MappedField('id', String.valueOf(mapVal.get('usage_rule/id')), 'String', 20, TRUE, TRUE)); 
            	elements.add(new UTIL_Fieldmapper.MappedField('status', 'ACTIVE', 'String', 10,  TRUE, TRUE));
            	elements.add(new UTIL_Fieldmapper.MappedField('allowance_amount', (oli.Quantity*rate), 'Integer', 10, TRUE, TRUE)); 
            	elements.add(new UTIL_Fieldmapper.MappedField('allowance_uom', 'COUNT', 'String', 10, TRUE, TRUE));
            	elements.add(new UTIL_Fieldmapper.MappedField('rule_order', 1, 'Integer', 5, TRUE, TRUE));
            	elements.add(new UTIL_Fieldmapper.MappedField('prorated_on_order', FALSE, 'BOOLEAN', 10, TRUE, TRUE));
            	elements.add(new UTIL_Fieldmapper.MappedField('prorated_on_cancel', FALSE, 'BOOLEAN', 10, TRUE, TRUE));
            	elements.add(new UTIL_Fieldmapper.MappedField('roll_over_type', 'UNCAPPED', 'String', 15, TRUE, TRUE));
            elements.add(new UTIL_Fieldmapper.MappedField('allowance_type', 'ONE_TIME', 'String', 15, TRUE, TRUE));
            elements.add(new UTIL_Fieldmapper.MappedField('valid_from', '2017-01-01T00:00:00+01:00', 'String', 50, TRUE, TRUE));
            elements.add(new UTIL_Fieldmapper.MappedField('rule_type', 'TAPERED', 'String', 15, TRUE, TRUE));

            	UTIL_Fieldmapper.MappedObject mapUsageRuleItemSec = new UTIL_Fieldmapper.MappedObject('spec');
            	elements.add(mapUsageRuleItemSec);
            		mapUsageRuleItemSec.add(new UTIL_Fieldmapper.MappedField('usage_rule_specification_type', 'match-all', 'String', 15, TRUE, TRUE));

            	UTIL_Fieldmapper.MappedObject mapUsageRuleItemUsageRate = new UTIL_Fieldmapper.MappedObject('usage_rate');
            	elements.add(mapUsageRuleItemUsageRate);
               	mapUsageRuleItemUsageRate.add(new UTIL_Fieldmapper.MappedField('rate_type', 'flat', 'String', 10, TRUE, TRUE));
                	mapUsageRuleItemUsageRate.add(new UTIL_Fieldmapper.MappedField('uom', 'COUNT', 'String',   10, TRUE, TRUE));
                	mapUsageRuleItemUsageRate.add(new UTIL_Fieldmapper.MappedField('rate', rate, 'DOUBLE', 10, TRUE, TRUE));
                	mapUsageRuleItemUsageRate.add(new UTIL_Fieldmapper.MappedField('id', String.valueOf(mapVal.get('usage_rate/id')), 'String', 15, TRUE, TRUE));
                	mapUsageRuleItemUsageRate.add(new UTIL_Fieldmapper.MappedField('valid_from', '2017-01-01T00:00:00+01:00', 'String', 32, TRUE, TRUE));
                	UTIL_Fieldmapper.MappedObject mapChargeCat = new UTIL_Fieldmapper.MappedObject('charge_category');
               	mapUsageRuleItemUsageRate.add(mapChargeCat);
                		mapChargeCat.add(new UTIL_Fieldmapper.MappedField('charge_category_type', 'usage-charge', 'String', 15, TRUE, TRUE));
                 	mapChargeCat.add(new UTIL_Fieldmapper.MappedField('name', 'USE-Kleinanzeigen', 'String', 32, TRUE, TRUE));
                 	mapChargeCat.add(new UTIL_Fieldmapper.MappedField('id', String.valueOf(mapVal.get('usage_rate/charge_category/id')), 'String', 15, TRUE, TRUE));
			    
         	UTIL_Fieldmapper.MappedObject mapOrderItemUsageRule = new UTIL_Fieldmapper.MappedObject('order_item_usage_rule');
          	elements.add(mapOrderItemUsageRule);
           		mapOrderItemUsageRule.add(new UTIL_Fieldmapper.MappedField('usage_rule_type', 'order-item', 'String', 15, TRUE, TRUE));
             	mapOrderItemUsageRule.add(new UTIL_Fieldmapper.MappedField('name', 'CPM Usage', 'String', 15, TRUE, TRUE));
               	mapOrderItemUsageRule.add(new UTIL_Fieldmapper.MappedField('id', String.valueOf(mapVal.get('order_item_usage_rule/id')), 'String', 15, TRUE, TRUE));
    		return elements;
    }
    public class OrderDetails extends GenericRequest {
        public override void init(Id contextRecordId){
            this.setCalloutDetails('OrderDetails',APINAME);
            super.init(contextRecordId);
            Opportunity opp = [select Tract_Order_Number__c from Opportunity where id = :contextRecordId];
            String endpoint = this.baseEndpoint +  'orders?order_num=' + opp.Tract_Order_Number__c;
            this.setEndpoint( endpoint );
            this.setHttpMethod('GET');
        }
        public virtual override void createWsLogs() {}
    }
    
    public static Map<Id, TractObject.OrderItem> getMapOliId2OrderItem(Id oppId) {
    		Map<Id, TractObject.OrderItem> theMap = new Map<Id, TractObject.OrderItem>();
    		
    		UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.OrderDetails');
        req.init(oppId);
        UTIL_WSC.WSC_Result res = req.call();
        
        if (res.statusCode == 200) {
	        	for(Object ord : (List<Object>) res.getResponseData().get('results') ) {
	        		TractObject.Order tractOrder = (TractObject.Order) JSON.deserialize(JSON.serialize(ord), TractObject.Order.class);
	        		for(TractObject.OrderItem oi : tractOrder.order_items) {
	        			String oliId;
	        			for(TractObject.CustomFieldValue cfv : oi.custom_field_values) {
	        				if(cfv.custom_field.name == 'SF Opportunity Line Item') {
	        					oliId = cfv.value;
	        					break;
	        				}
	        			}
	        			if(oliId != null) theMap.put(oliId, oi); // oliId is 18 digits
	        		}
	        	}
        }
        return theMap;
    }
    public class ServiceDetails extends GenericRequest {
        public override void init(Id contextRecordId){
            this.setCalloutDetails('ServiceDetails',APINAME);
            super.init(contextRecordId);
            String endpoint = this.baseEndpoint +  'services/' + this.mAdditionalParams.get('id');
            this.setEndpoint( endpoint );
            this.setHttpMethod('GET');
        }
        public virtual override void createWsLogs() {}
    }
    public static TractObject.Service getMapService(Id oppId, String servId) {
    		UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.ServiceDetails');
    		req.mAdditionalParams.put('id', servId);
        req.init(oppId);
        UTIL_WSC.WSC_Result res = req.call();
        
        if (res.statusCode == 200) {
        		Object ob = (Object) res.getResponseData().get('results');
	        	return (TractObject.Service) JSON.deserialize(JSON.serialize(ob), TractObject.Service.class);
        }
        return null;
    }
    public class UsageRuleGetByService extends GenericRequest {
    		// contextRecordId is opp.id
        public override void init(Id contextRecordId){
            this.setCalloutDetails('UsageRuleGetByService',APINAME);
            super.init(contextRecordId);
            Object serviceId = this.mAdditionalParams.get('id');
            String endpoint = this.baseEndpoint +  'services/' + serviceId + '/usage-rules';
            this.setEndpoint( endpoint );
            this.setHttpMethod('GET');
        }
        public virtual override void createWsLogs() {}
    }
    public static Map<String, Object> getServiceUsageRule(Id oppId, Object serviceId) {
        UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.UsageRuleGetByService');
        req.mAdditionalParams.put('id', serviceId);
        req.init(oppId);
        UTIL_WSC.WSC_Result res = req.call();
        
        Object usageRuleId = '';
        Object usageRateId = '';
        Object chargeCategoryId = '';
        if (res.statusCode == 200) {
            List<Object> objs = (List<Object>) res.getResponseData().get('results');
            if(!objs.isEmpty()) {
                Object serv = objs[0]; 
                usageRuleId = UTIL_WSC.getResponseField('id', serv);
                usageRateId = UTIL_WSC.getResponseField('usage_rate/id', serv);
                chargeCategoryId = UTIL_WSC.getResponseField('usage_rate/charge_category/id', serv);
            }
        }
        return new Map<String, Object> { 'id' => usageRuleId,
        									'usage_rate/id' => usageRateId,
        									'usage_rate/charge_category/id' => chargeCategoryId};
    }
    
    
    /**
     * Generate Custom Field Value mapper (Order)
     * @param:  Opportunity, 
     *          map Order CusFieldId - ID of Custom Field from TRACT
     * @return: list of Custom Field Value mapper
     */
    private static UTIL_Fieldmapper.mappedList getListOrderCustomFieldValues(Opportunity op, map<String, String> mapOrderCusFieldId, Boolean isAdSales) {
        
        UTIL_Fieldmapper.mappedList mapListCusFieldVal = new UTIL_Fieldmapper.mappedList('custom_field_values'); 
        
        // Order: Campaign Value - Contract Amount for expected usage
        UTIL_Fieldmapper.MappedObject mapCusFieldVal = new UTIL_Fieldmapper.MappedObject('');
        mapCusFieldVal.add(new UTIL_Fieldmapper.mappedField('custom_field_value_type', 'order', 'String', 32, FALSE, FALSE));
        mapCusFieldVal.add(new UTIL_Fieldmapper.mappedField('value', (isAdSales ? op.TotalAmountNet__c : op.ExpectedRevenue), 'String', 32, FALSE, FALSE));
        
		UTIL_Fieldmapper.MappedObject mapCusField = new UTIL_Fieldmapper.MappedObject('custom_field');
		mapCusField.add(new UTIL_Fieldmapper.mappedField('custom_field_type', 'order', 'String', 32, FALSE, FALSE));
		mapCusField.add(new UTIL_Fieldmapper.mappedField('name', 'Campaign Value', 'String', 32, FALSE, FALSE));
		mapCusField.add(new UTIL_Fieldmapper.mappedField('id', mapOrderCusFieldId.get('Campaign Value'), 'String', 32, FALSE, FALSE));   
        
        mapCusFieldVal.add(mapCusField); 
               
        // Order: Probability - Field based on opportunity status
        UTIL_Fieldmapper.MappedObject mapCusFieldValProb = new UTIL_Fieldmapper.MappedObject('');
        mapCusFieldValProb.add(new UTIL_Fieldmapper.mappedField('custom_field_value_type', 'order', 'String', 32, FALSE, FALSE));
        mapCusFieldValProb.add(new UTIL_Fieldmapper.mappedField('value', (op.Probability / 100), 'String', 32, FALSE, FALSE));
        
		UTIL_Fieldmapper.MappedObject mapCusFieldProb = new UTIL_Fieldmapper.MappedObject('custom_field');
		mapCusFieldProb.add(new UTIL_Fieldmapper.mappedField('custom_field_type', 'order', 'String', 32, FALSE, FALSE));
		mapCusFieldProb.add(new UTIL_Fieldmapper.mappedField('name', 'Weighting', 'String', 32, FALSE, FALSE));
		mapCusFieldProb.add(new UTIL_Fieldmapper.mappedField('id', mapOrderCusFieldId.get('Weighting'), 'String', 32, FALSE, FALSE));   
        
        mapCusFieldValProb.add(mapCusFieldProb); 
        
        // Order: Campaign name
        UTIL_Fieldmapper.MappedObject mapCusFieldValName = new UTIL_Fieldmapper.MappedObject('');
        mapCusFieldValName.add(new UTIL_Fieldmapper.mappedField('custom_field_value_type', 'order', 'String', 32, FALSE, FALSE));
        mapCusFieldValName.add(new UTIL_Fieldmapper.mappedField('value', op.Name, 'String', 32, FALSE, FALSE));
        
		UTIL_Fieldmapper.MappedObject mapCusFieldName = new UTIL_Fieldmapper.MappedObject('custom_field');
		mapCusFieldName.add(new UTIL_Fieldmapper.mappedField('custom_field_type', 'order', 'String', 32, FALSE, FALSE));
		mapCusFieldName.add(new UTIL_Fieldmapper.mappedField('name', 'Campaign name', 'String', 32, FALSE, FALSE));
		mapCusFieldName.add(new UTIL_Fieldmapper.mappedField('id', mapOrderCusFieldId.get('Campaign name'), 'String', 32, FALSE, FALSE));   
        
        mapCusFieldValName.add(mapCusFieldName);             
        
        mapListCusFieldVal.add(mapCusFieldVal);
        mapListCusFieldVal.add(mapCusFieldValProb);
        mapListCusFieldVal.add(mapCusFieldValName);
        
        return mapListCusFieldVal;    
    }
    
    private static String getLastDTformated() {
        Date lastDate = System.today().addMonths(2).toStartOfMonth().addDays(-1);
        Datetime lastDatetime = Datetime.newInstance(lastDate, System.now().time());
        return lastDatetime.format('yyyy-MM-dd\'T\'hh:mm:ss');
    }
    
    private static UTIL_Fieldmapper.mappedList getMapListServiceResource(OpportunityLineItem opli) {
        UTIL_Fieldmapper.mappedList mapServiceRes = new UTIL_Fieldmapper.mappedList('service_resources');
        UTIL_Fieldmapper.MappedObject mapServiceDetail = new UTIL_Fieldmapper.MappedObject('');
        String networkId = Test.isRunningTest() ? '123' : DARTUtil.getCredential(opli.PricebookEntry.Product2.RecordType.Name, opli.PriceBookEntry.Product2.Site__r.Country__c).Network_Id__c;
        mapServiceDetail.add(new UTIL_Fieldmapper.mappedField('resource_type', 'service', 'String', 32, FALSE, FALSE)).
        add(new UTIL_Fieldmapper.mappedField('identifier', networkId + '_' + opli.Ad_Id__c, 'String', 32, FALSE, FALSE)).
        add(new UTIL_Fieldmapper.mappedObject('category').add(new UTIL_Fieldmapper.mappedField('id', opli.product2.Tract_ServiceResourceCategoryId__c, 'Double', 32, FALSE, FALSE)));
        mapServiceRes.add(mapServiceDetail);
        return mapServiceRes;
    }
    
    private static UTIL_Fieldmapper.mappedList getMapper_DraftOrderAdSalesItems(List<OpportunityLineItem> lstLineItems, Map<String, String> mapOrderCusFieldId, Map<String, String> mapServiceCusFieldId ){
        UTIL_Fieldmapper.mappedList mapReturn = new UTIL_Fieldmapper.mappedList('order_items');
  
        Map<Id, UTIL_Fieldmapper.MappedObject> mapOrderItemWithoutAddOnPro = new Map<Id, UTIL_Fieldmapper.MappedObject>();
        for (OpportunityLineItem opli : lstLineItems ){
            opli.Tract_ServiceId__c = '' + opli.id + DateTime.now().getTime() ;

            UTIL_Fieldmapper.MappedObject mapObjOLI = new UTIL_Fieldmapper.MappedObject('');
            mapObjOLI.add(new UTIL_Fieldmapper.mappedField('order_item_type', 'product', 'String', 32, FALSE, FALSE));
            if (String.isNotBlank(opli.Description)) {
                mapObjOLI.add(new UTIL_Fieldmapper.mappedField('description', opli.Description, 'String', 255, FALSE, FALSE));
            }
            mapObjOLI.add(getMapProductDetail(opli));
            mapObjOLI.add(new UTIL_Fieldmapper.mappedField('unit_price', '0.00', 'String', 32, FALSE, FALSE));
            mapObjOLI.add(new UTIL_Fieldmapper.mappedField('recurring_price', '0.00', 'String', 32, FALSE, FALSE));
            mapObjOLI.add(new UTIL_Fieldmapper.mappedField('quantity', '1', 'String', 32, FALSE, FALSE)); // String.valueOf(opli.Quantity) now testing
            mapObjOLI.add(getListOrderItemPrice(opli));
            mapObjOLI.add(getListCustomFieldValues(opli, mapOrderCusFieldId, mapServiceCusFieldId)); 
            
            if (String.isNotBlank(opli.Ad_Id__c) && String.isNotBlank(opli.product2.Tract_ServiceResourceCategoryId__c)) {
                mapObjOLI.add(getMapListServiceResource(opli));
            }

            UTIL_Fieldmapper.MappedObject orderItemAgreement = new UTIL_Fieldmapper.MappedObject('order_item_agreement');
            orderItemAgreement.add((new UTIL_Fieldmapper.MappedObject('agreement')).add(new UTIL_Fieldmapper.mappedField('id', opli.Opportunity.Tract_AgreementId__c, 'String', 32, FALSE, FALSE)));
            
            Datetime endDatetime = Datetime.newInstance( (opli.from_Date__c == opli.until_Date__c) ? opli.until_Date__c.addDays(1) : opli.until_Date__c , System.now().time() );
            String untilDatetimeFormated = endDatetime.format('yyyy-MM-dd\'T\'' + '23:59:59');
            
            orderItemAgreement.add(new UTIL_Fieldmapper.mappedField('end_date', untilDatetimeFormated , 'String', 32, FALSE, FALSE));

            orderItemAgreement.add(new UTIL_Fieldmapper.mappedField('end_action', 'DEACTIVATE_SERVICE', 'String', 32, FALSE, FALSE));
            mapObjOLI.add(orderItemAgreement);
            addOperationRunAttr(mapObjOLI, opli);
            mapReturn.add(mapObjOLI);
        }  
        return mapReturn;

    }
    
    private static void addOperationRunAttr(UTIL_Fieldmapper.MappedObject mapObjOLI, OpportunityLineItem opli) {
    	if(opli.from_Date__c > System.today()){
                String approvalOperationId = '';
                
                //we can callout in loop since the product will not more than 2 (Tajinder has reported)
                UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.ProductOperation');
                req.init(opli.Product2ID);
                UTIL_WSC.WSC_Result res = req.call();
                if ( res.statusCode == 200 || res.statusCode == 201) {
                    List<Object> lstResponses = (List<Object>)  res.getResponseData().get('results');
                    if(!lstResponses.isEmpty()){
                        Map<String,Object> response = (Map<String,Object>) lstResponses[0];
                        
                        if(response.containsKey('operations')){
                            List<Object> lstOperations = (List<Object>) response.get('operations');
                            for(Object objOperation: lstOperations){
                                Map<String,Object> mOperations = (Map<String,Object>) objOperation;
                                
                                    if( mOperations.containsKey('operation_type')) {
                                		String operType = String.valueOf(mOperations.get('operation_type'));
                                		if(operType.equalsIgnoreCase('product-sale') || operType.equalsIgnoreCase('approval')) approvalOperationId = String.valueOf(mOperations.get('id'));
									}	
                            }
                        }
                    }
                }
                if(approvalOperationId != ''){
                    Datetime conFromDate = Datetime.newInstance(opli.from_Date__c, System.now().time());
                    String fromDateConverted = conFromDate.format('yyyy-MM-dd');
                    
                    UTIL_Fieldmapper.mappedList mapListOperationAttr = new UTIL_Fieldmapper.mappedList('operation_run_attributes');
                    
                    UTIL_Fieldmapper.MappedObject mapOpperation = new UTIL_Fieldmapper.MappedObject('operation');
                    mapOpperation.add(new UTIL_Fieldmapper.mappedField('operation_type', 'approval', 'String', 32, FALSE, FALSE));
                    mapOpperation.add(new UTIL_Fieldmapper.mappedField('id', approvalOperationId, 'String', 32, FALSE, FALSE));
                    
                    UTIL_Fieldmapper.MappedObject mapOpperationAttr = new UTIL_Fieldmapper.MappedObject('');
                    mapOpperationAttr.add(new UTIL_Fieldmapper.mappedField('operation_run_attribute_type', 'product-sale', 'String', 32, FALSE, FALSE));
                    mapOpperationAttr.add(new UTIL_Fieldmapper.mappedField('auto_approve_date', fromDateConverted, 'String', 32, FALSE, FALSE));
                    mapOpperationAttr.add(mapOpperation);
                    
                    mapListOperationAttr.add(mapOpperationAttr);
                    mapObjOLI.add(mapListOperationAttr);
                }
    	}
    }
    
    private static UTIL_Fieldmapper.MappedList getListOrderItemPriceUsageRule(OpportunityLineItem oppLine) {
	    Decimal rate = GW_OpportunityLineItem.getAdsaleRate(oppLine);
        // create list container for Usage Rule Item
        UTIL_Fieldmapper.MappedList mapListOrderItemPriceUsageRule = new UTIL_Fieldmapper.MappedList('usage_rules');
        
            UTIL_Fieldmapper.MappedObject mapUsageRuleItem = new UTIL_Fieldmapper.MappedObject('');
                // map key value to mapUsageRuleItem
                mapUsageRuleItem.add(new UTIL_Fieldmapper.MappedField('usage_rule_type',       'order-item',                                        'String',   15,     TRUE,   TRUE));
                mapUsageRuleItem.add(new UTIL_Fieldmapper.MappedField('name',                  'CPM Usage',                                         'String',   15,     TRUE,   TRUE));
                mapUsageRuleItem.add(new UTIL_Fieldmapper.MappedField('id',                    oppLine.PriceBookEntry.Product2.Tract_Usage_ID__c,   'String',   20,     TRUE,   TRUE)); // dynamic value
                mapUsageRuleItem.add(new UTIL_Fieldmapper.MappedField('status',                'ACTIVE',                                            'String',   10,     TRUE,   TRUE));
				mapUsageRuleItem.add(new UTIL_Fieldmapper.MappedField('allowance_amount',      (oppLine.Quantity * rate).intValue(),         		'Integer',  10,     TRUE,   TRUE)); // dynamic value
                mapUsageRuleItem.add(new UTIL_Fieldmapper.MappedField('allowance_uom',         'COUNT',                                             'String',   10,     TRUE,   TRUE));
                mapUsageRuleItem.add(new UTIL_Fieldmapper.MappedField('rule_order',            1,                                                   'Integer',  5,      TRUE,   TRUE));
                mapUsageRuleItem.add(new UTIL_Fieldmapper.MappedField('prorated_on_order',     FALSE,                                               'BOOLEAN',  10,     TRUE,   TRUE));
                mapUsageRuleItem.add(new UTIL_Fieldmapper.MappedField('prorated_on_cancel',    FALSE,                                               'BOOLEAN',  10,     TRUE,   TRUE));
                mapUsageRuleItem.add(new UTIL_Fieldmapper.MappedField('roll_over_type',        'UNCAPPED',                                          'String',   15,     TRUE,   TRUE));
                mapUsageRuleItem.add(new UTIL_Fieldmapper.MappedField('allowance_type',        'ONE_TIME',                                          'String',   15,     TRUE,   TRUE));
                mapUsageRuleItem.add(new UTIL_Fieldmapper.MappedField('rule_type',             'TAPERED',                                           'String',   15,     TRUE,   TRUE));

                // create object mapping field for key "spec"
                UTIL_Fieldmapper.MappedObject mapUsageRuleItemSec = new UTIL_Fieldmapper.MappedObject('spec');
                    mapUsageRuleItemSec.add(new UTIL_Fieldmapper.MappedField('usage_rule_specification_type', 'match-all', 'String', 15, TRUE, TRUE));

                // create object mapping field for key "usage_rate"
                UTIL_Fieldmapper.MappedObject mapUsageRuleItemUsageRate = new UTIL_Fieldmapper.MappedObject('usage_rate');
                    mapUsageRuleItemUsageRate.add(new UTIL_Fieldmapper.MappedField('rate_type',     'flat',                                                 'String',   10, TRUE,   TRUE));
                    mapUsageRuleItemUsageRate.add(new UTIL_Fieldmapper.MappedField('uom',           'COUNT',                                                'String',   10, TRUE,   TRUE));
                    mapUsageRuleItemUsageRate.add(new UTIL_Fieldmapper.MappedField('rate',          rate,                     					'DOUBLE',   10, TRUE,   TRUE)); // dynamic value
                    mapUsageRuleItemUsageRate.add(new UTIL_Fieldmapper.MappedField('id',            oppLine.PriceBookEntry.Product2.Tract_Usage_Rate_ID__c, 'String',   15, TRUE,   TRUE));
                    mapUsageRuleItemUsageRate.add(new UTIL_Fieldmapper.MappedField('valid_from',    '2017-01-01T00:00:00.000+0100',                         'String',   32, TRUE,   TRUE));

                // create object mapping field for key "product_usage_rule"UTIL_Fieldmapper.MappedObject mapUsageRuleItemProductUsageRule = new UTIL_Fieldmapper.MappedObject('product_usage_rule');
                UTIL_Fieldmapper.MappedObject mapUsageRuleItemProductUsageRule = new UTIL_Fieldmapper.MappedObject('product_usage_rule');
                    mapUsageRuleItemProductUsageRule.add(new UTIL_Fieldmapper.MappedField('usage_rule_type',   'product',                                           'String',   15, TRUE,   TRUE));
                    mapUsageRuleItemProductUsageRule.add(new UTIL_Fieldmapper.MappedField('name',              'CPM Usage',                                         'String',   15, TRUE,   TRUE));
                    mapUsageRuleItemProductUsageRule.add(new UTIL_Fieldmapper.MappedField('id',                oppLine.PriceBookEntry.Product2.Tract_Usage_ID__c,   'String',   15, TRUE,   TRUE)); // dynamic value

                // put child object to mapUsageRuleItem
                mapUsageRuleItem.add(mapUsageRuleItemSec);
                mapUsageRuleItem.add(mapUsageRuleItemUsageRate);
                mapUsageRuleItem.add(mapUsageRuleItemProductUsageRule);

        // add Usage Rule Item to list container
        mapListOrderItemPriceUsageRule.add(mapUsageRuleItem);

        return mapListOrderItemPriceUsageRule;
    }
    
    public class DraftOrderCreate_Handler extends ApiHandler {
        public override void handle() {
            super.handle();
            Map<String,Object> response = (Map<String,Object>) result.getResponseData().get('results');

            if (result.statusCode == UTIL_WSC.HTTP_CREATED && response != null && response.containsKey('id') == TRUE) {
                Opportunity opp = GW_Opportunity.getRecord(request.contextRecord.Id);
                String  orderNum = (String) response.get('order_num');
                Integer tractOrderId = Integer.valueOf(response.get('id'));
                String oldTract_order = opp.Tract_OrderId__c == null ? '': String.valueOf(opp.Tract_OrderId__c); 
                
                if(oldTract_order != ''){
                    deletePrevDraftOrder(opp.id, oldTract_order);
                }
                opp.Tract_OrderId__c = tractOrderId;
                opp.Tract_Order_Number__c = orderNum;
                opp.Tract_Order_Date__c = System.today();
                opp.Tract_Order_Confirm__c = false;
                UTIL_WSC.doUpdate(opp);
                /*Move from here to make a flow when booking success from DFP, trigger OLI AD ID populate
                if(opp.LineOfBusiness__c == 'AdSales' && opp.NumStatus__c >= 2) {
                    Integer adIdCount = [select count() from OpportunityLineItem where OpportunityId = : opp.id and Ad_Id__c = null limit 1];
                    if(adIdCount == 0) {
                        activateAdsalesOrderAfterBookedDFP(opp.id);
                    }
                }*/

            }
            else if(this.result.statusCode != UTIL_WSC.HTTP_CREATED) {
                UTIL.logClean('WSC_Tract Unknown error, result: ' + this.result);
                response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract Unknown error');

            }
            else {
                UTIL.logClean('Error getting response from server - no response received.');
                response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract No response received from service.');
            }
        }
    }
    
    /*
    * Method to delete Draft Order
    * @param orderIds   set of Draft Order Ids
    */
    public static void deletePrevDraftOrder(String oppId, String oldTract_order){
        if(oldTract_order == null || oldTract_order == ''){
            return;
        }
        
        try{
            UTIL_WSC.WSC_Request req;
            UTIL_WSC.WSC_Result res;
            req = UTIL_WSC.getWSC_Request('WSC_Tract.DelPrevDraftOrder');
            req.mAdditionalParams.put('oldTract_order', oldTract_order);
            req.init(oppId);
            res = req.call();
            if ( res.statusCode == 200 || res.statusCode == 201) {
                 //TODO?
            }
        }catch(DMLException dmlex){
            UTIL.log('DelPrevDraftOrder Error: ' + dmlex.getMessage());
        }catch(Exception ex){
            UTIL.log('DelPrevDraftOrder Error: ' + ex.getMessage());
        }
    }
    
    public static void activateAdsalesOrderAfterBookedDFP(String oppId){
        List<WS_ScheduledCallout__c> wsscToUpsertselfService = new List<WS_ScheduledCallout__c>();
        UTIL_WSC.WSC_Request wsRequestActivationOrder = UTIL_WSC.getWSC_Request('WSC_Tract.OrderTract');
        wsRequestActivationOrder.init(oppId);
        WS_ScheduledCallout__c wsScheduledCalloutActivationOrder = wsRequestActivationOrder.getScheduledCallout();
        wsScheduledCalloutActivationOrder.DependsOnScheduledCallout__c = wsScheduledCalloutActivationOrder.Id;
        wsscToUpsertselfService.add(wsScheduledCalloutActivationOrder);
        upsert wsscToUpsertselfService UniqueKey__c;
    }

    public class DelPrevDraftOrder extends ApiRequest {
        Opportunity opp;

        public override void init(Id contextRecordId){
            this.setCalloutDetails('DelPrevDraftOrder',APINAME);
            super.init(contextRecordId);
            this.setHandlerClass(APINAME + '.DelPrevDraftOrder_Handler');
            String oldTract_order = String.valueOf(this.mAdditionalParams.get('oldTract_order'));
            
            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'orders/' + oldTract_order;
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );
            
            this.setHttpMethod('DELETE');
        }
    }
    
    public class DelPrevDraftOrder_Handler extends ApiHandler {
        public override void handle() {
            super.handle();
            Map<String,Object> response = (Map<String,Object>) result.getResponseData().get('results');

            if (result.statusCode == UTIL_WSC.HTTP_NOCONTENT) {
                //DO NOTHING
            }
            else if(this.result.statusCode != UTIL_WSC.HTTP_CREATED) {
                UTIL.logClean('WSC_Tract Unknown error, result: ' + this.result);
                response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract Unknown error');
            }
            else {
                UTIL.logClean('Error getting response from server - no response received.');
                response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract No response received from service.');
            }
        }
    }
    
    /*
    * Method to generate Json Draft Order
    * @param billingAccId   String Billing account Id
    * @param orderItems     String Json order items
    * @return Map of Draft Order
    */
    private static Map<String, Object> generateJsonDraftOrder(Integer billingAccId, List<Map<String, Object>> orderItems){

        Map<String, Object> mBillingAcc = new Map<String, Object>{'object_type' => 'billing-account',
                                                                    'id' => billingAccId};

        return new Map<String, Object>{'object_type' => 'order',
                                        'order_type' => 'sales',
                                        'billing_account' => mBillingAcc,
                                        'order_items' => orderItems};
    }

    /*
    * Method to generate JSON Order Items from OpportunityLineItem
    * @param lstLineItems   list Opportunity Line Item to generate Json
    * @return List of Map Order items mapping with fields in TRACT
    */
    private static List<Map<String, Object>> generateJsonOrderItem(List<OpportunityLineItem> lstLineItems){
        List<Map<String, Object>> lstJson = new List<Map<String, Object>>();

        for(OpportunityLineItem opli: lstLineItems){

            if(  opli.PricebookEntry.Product2ID == null ||
                opli.PricebookEntry.Product2.Tract_ProductId__c == null ||
                opli.PricebookEntry.Product2.Tract_PriceId__c == null ||
                opli.Quantity == null)
            {
                continue;
            }

            Map<String, Object> mProduct = new Map<String, Object>{'object_type' => 'product',
                                                                    'id' => opli.PricebookEntry.Product2.Tract_ParentId__c};

            Map<String, Object> mRecurring = new Map<String, Object>{'price_type' => 'recurring',
                                                                    'id' => opli.PricebookEntry.Product2.Tract_PriceId__c};

            Map<String, Object> mJson = new Map<String, Object>{'object_type' => 'order-item',
                                                                'order_item_type' => 'product',
                                                                'quantity' => opli.Quantity,
                                                                'product' => mProduct,
                                                                'recurring_product_price' => mRecurring};
            lstJson.add(mJson);
        }
        return lstJson;
    }

    private static RemoteResponse getHTTPerrorResponse(HttpResponse resp){
        return new RemoteResponse(resp.getStatus(), RemoteResponse.STATUSCODE_ERROR);
    }

    public class OrderTract extends GenericRequest {
        Opportunity opp;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('OrderTract',APINAME);
            super.init(contextRecordId);
            opp = GW_Opportunity.getRecord(contextRecordId);
            //this.mapper.mappingElements = getMapper_OrderTract(contextRecordId);
            this.setHandlerClass(APINAME + '.OrderTract_Handler');
            
            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'orders/' + opp.Tract_OrderId__c + '/confirm';
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );
   

            this.setHttpMethod('POST');
        }
    }

//    private static List<UTIL_Fieldmapper.mappedElement> getMapper_OrderTract(Id revId){
//        //Opportunity opp = (Opportunity) UTIL.getCached(oppId);
//
//        // check if opportunity has opportunitylineitems.HasOpportunityLineItem
//        //if(opp.HasOpportunityLineItem) List<OpportunityLineItem> oplLst = GW_OpportunityLineItem.getListFromRelated(oppId);
//        // List<AccountMemberUnitAssociation__c> amuaList = GW_AccountMemberUnitAssociation.getAll(accId);
//
//        //PlaceHolder
//        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
//
//        elements.add(new UTIL_Fieldmapper.mappedField('initial_status',                 'DRAFT', 'String', 32, FALSE, FALSE));
//        elements.add(new UTIL_Fieldmapper.mappedField('note',                           'Order Note', 'String', 18, TRUE, TRUE));
//        elements.add(new UTIL_Fieldmapper.mappedField('email_receipt',                  'true', 'String', 18, TRUE, TRUE));
//        elements.add(new UTIL_Fieldmapper.mappedField('purchase_order_number',           'PO Number 1255', 'String', 18, TRUE, TRUE));
//        elements.add(new UTIL_Fieldmapper.mappedField('referral',                        'Johny Cash', 'String', 18, TRUE, TRUE));
//        elements.add((new UTIL_Fieldmapper.mappedList('order_items')).
//                add(new UTIL_Fieldmapper.mappedObject('').
//                        add(new UTIL_Fieldmapper.mappedField('order_item_type',           'product', 'String', 18, TRUE, TRUE)).
//                        add(new UTIL_Fieldmapper.mappedObject('product').
//                                add(new UTIL_Fieldmapper.mappedField('object_type', 'product', 'String', 32, FALSE, FALSE)).
//                                add(new UTIL_Fieldmapper.mappedField('default_quantity', '1.0', 'String', 32, FALSE, FALSE)).
//                                add(new UTIL_Fieldmapper.mappedField('id', '11336', 'String', 32, FALSE, FALSE)).
//                                add(new UTIL_Fieldmapper.mappedField('product_type', 'customer-subscription', 'String', 32, FALSE, FALSE))).
//                        add(new UTIL_Fieldmapper.mappedField('quantity', '1', 'String', 32, FALSE, FALSE)).
//                        add(new UTIL_Fieldmapper.mappedList('order_items').
//                                add(new UTIL_Fieldmapper.mappedObject('').
//                                        add(new UTIL_Fieldmapper.mappedField('order_item_type', 'addon', 'String', 32, FALSE, FALSE)).
//                                        add(new UTIL_Fieldmapper.mappedField('quantity', '1', 'String', 32, FALSE, FALSE)).
//                                        add(new UTIL_Fieldmapper.mappedObject('product').
//                                                add(new UTIL_Fieldmapper.mappedField('object_type', 'product', 'String', 32, FALSE, FALSE)).
//                                                add(new UTIL_Fieldmapper.mappedField('default_quantity', '1.0', 'String', 32, FALSE, FALSE)).
//                                                add(new UTIL_Fieldmapper.mappedField('id', '11338', 'String', 32, FALSE, FALSE)).
//                                                add(new UTIL_Fieldmapper.mappedField('product_type', 'customer-subscription', 'String', 32, FALSE, FALSE))).
//                                        add(new UTIL_Fieldmapper.mappedList('services_resources'))
//                                )
//                        )
//                )
//        );
//
//
//        return elements;
//    }

	public class BillingAccountCreate extends GenericRequest {
	    Account acc;
	    public override void init(Id contextRecordId) {
	        this.setCalloutDetails('BillingAccountCreate',APINAME);
	        super.init(contextRecordId);
	        acc = (Account) this.contextRecord;
	        UTIL.cache(GW_sObject.queryRecords('Account', new Set<Id>{contextRecordId}, new List<String>{'Finance_contact__r.Email'}));
	        
	        Map<String,Object> params = this.mAdditionalParams;
	        if( params != null && params.containsKey( 'agencyAccId' ) ){
	        	this.mapper.mappingElements = getMapper_GhostBillingAccountCreate( contextRecordId , (Id) params.get( 'agencyAccId' ) );
	        	this.setHandlerClass(APINAME + '.GhostBillingAccountCreate_Handler');
	        } else {
	            this.mapper.mappingElements = getMapper_BillingAccountCreate(contextRecordId);
	            this.setHandlerClass(APINAME + '.BillingAccountCreate_Handler');	
	        } 
	
	        String endpoint = '';
	        if( this.baseEndpoint != null ){
	            endpoint = this.baseEndpoint + 'billing-accounts';
	        }
	        this.setEndpoint( endpoint );
	        UTIL.log('Endpoint: ' + endpoint );
	
	        this.setHttpMethod('POST');
	    }
	
	    public virtual override Boolean readyForCallout() {
	    	return true;
	        return (acc.Tract_AccountId__c == null || acc.Tract_AccountId__c == '');
	    }
	
	    public override HttpResponse getMockResponse() { 
	        HttpResponse response = new HttpResponse();
	        String resBODY = '{"results":{"responsible_account":{"external_account_num":"001O000001C8857IAB","account_num":"GTZA00021","id":"1758"},"next_invoice_date":"2017-05-01T05:00:00.000+0000","currency_code":"ZAR","tax_exempt":false,"payment_term":{"id":"16","name":"Net 30"},"contacts":[],"custom_field_values":[],"start_date":"2017-05-26T14:48:13.821+0000","balance":0,"pending_charges_total":0,"status":"ACTIVE","auto_payment_authorized":false,"billing_account_category":{"payment_term":{"grace_days":0,"term_days":30,"id":"16","name":"Net 30"},"name":"Gumtree ZA (Pty) Ltd","id":"16","status":"ACTIVE","description":"Gumtree ZA (Pty) Ltd; Company Code: 0477"},"recurring_payments":[],"responsible_party":{"tax_id_validated":false,"organization_name":"Test Advertiser ZA Adsales","addresses":[{"postal_code":"19053","region_or_state":"","id":"2991","line2":"","line1":"GoethestraBe 97","city":"Schwerin","country":"ZAF","purpose":"SERVICE","address_type":"postal"},{"postal_code":"19053","region_or_state":"","id":"2992","line2":"","line1":"GoethestraBe 97","city":"Schwerin","country":"ZAF","purpose":"BILLING","address_type":"postal"}],"id":"1752","party_type":"organization"},"bill_cycle":{"day_of_month":1,"currency_code":"ZAR","auto_bill":false,"end_date":"2017-06-01T05:00:00.000+0000","start_date":"2017-05-01T05:00:00.000+0000","name":"ZAR-Monthly-Marktplaats","id":"67","status":"ACTIVE","bill_cycle_type":"monthly"},"bill_type":"NONE","external_account_num":"001O000001C8857IAB","account_num":"GTZA00021","id":"1758"}}';
	        response.setStatusCode(404);
	        response.setBody(resBODY);
	        response.setStatus('OK');
	        return response; 
	    }
	}

	public class GhostBillingAccountCreate extends GenericRequest {

	    Account acc;
	    public override void init(Id contextRecordId) {
	        this.setCalloutDetails('BillingAccountCreate',APINAME);
	        super.init(contextRecordId);
	        acc = (Account) this.contextRecord;
	        UTIL.cache(GW_sObject.queryRecords('Account', new Set<Id>{contextRecordId}, new List<String>{'Finance_contact__r.Email'}));
	        
	        Map<String,Object> params = this.mAdditionalParams;
        	this.mapper.mappingElements = getMapper_GhostBillingAccountCreate( contextRecordId , (Id) params.get( 'agencyAccId' ) );
        	this.setHandlerClass(APINAME + '.GhostBillingAccountCreate_Handler');
	
	        String endpoint = '';
	        if( this.baseEndpoint != null ){
	            endpoint = this.baseEndpoint + 'billing-accounts';
	        }
	        this.setEndpoint( endpoint );
	        UTIL.log('Endpoint: ' + endpoint );
	
	        this.setHttpMethod('POST');
	    }
	
	    public override HttpResponse getMockResponse() { 
	        HttpResponse response = new HttpResponse();
	        String resBODY = '{"results":{"responsible_account":{"external_account_num":"001O000001C8857IAB","account_num":"GTZA00021","id":"1758"},"next_invoice_date":"2017-05-01T05:00:00.000+0000","currency_code":"ZAR","tax_exempt":false,"payment_term":{"id":"16","name":"Net 30"},"contacts":[],"custom_field_values":[],"start_date":"2017-05-26T14:48:13.821+0000","balance":0,"pending_charges_total":0,"status":"ACTIVE","auto_payment_authorized":false,"billing_account_category":{"payment_term":{"grace_days":0,"term_days":30,"id":"16","name":"Net 30"},"name":"Gumtree ZA (Pty) Ltd","id":"16","status":"ACTIVE","description":"Gumtree ZA (Pty) Ltd; Company Code: 0477"},"recurring_payments":[],"responsible_party":{"tax_id_validated":false,"organization_name":"Test Advertiser ZA Adsales","addresses":[{"postal_code":"19053","region_or_state":"","id":"2991","line2":"","line1":"GoethestraBe 97","city":"Schwerin","country":"ZAF","purpose":"SERVICE","address_type":"postal"},{"postal_code":"19053","region_or_state":"","id":"2992","line2":"","line1":"GoethestraBe 97","city":"Schwerin","country":"ZAF","purpose":"BILLING","address_type":"postal"}],"id":"1752","party_type":"organization"},"bill_cycle":{"day_of_month":1,"currency_code":"ZAR","auto_bill":false,"end_date":"2017-06-01T05:00:00.000+0000","start_date":"2017-05-01T05:00:00.000+0000","name":"ZAR-Monthly-Marktplaats","id":"67","status":"ACTIVE","bill_cycle_type":"monthly"},"bill_type":"NONE","external_account_num":"001O000001C8857IAB","account_num":"GTZA00021","id":"1758"}}';
	        response.setStatusCode(404);
	        response.setBody(resBODY);
	        response.setStatus('OK');
	        return response; 
	    }
	}

    public class OrderTract_Handler extends ApiHandler {
        public override void handle() {
            super.handle();
            Map<String,Object> response = (Map<String,Object>) result.getResponseData().get('results');

            if(UTIL_WSC.isSuccessStatusCode(result.statusCode)){
                //TODO: ??
                Opportunity opp = GW_Opportunity.getRecord(request.contextRecord.Id);
                MemberUnit__c mu = GW_MemberUnit.getRecord(opp.MemberUnit__c);
				
                String strJson = Json.serializePretty(response.get('order_items'));
                List<Object> listItems = (List<Object>) JSON.deserializeUntyped(strJson);
                if(opp != null){
                    opp.Tract_Order_Confirm__c = true;
					opp.Tract_OrderId__c  =  Integer.valueOf(response.get('id'));
				    opp.Tract_Order_Number__c = (String)response.get('order_num');
                    List<Opportunity> opps = new List<Opportunity>{opp};
                    if(mu.MemberUnitId__c == 'EBAYKAD') {
                        GW_Opportunity.setTractOrderStatus(opps);
                    }
                    UTIL_WSC.doUpdate(opps[0]);
                }
			    List<OpportunityLineItem> lstoli = new List<OpportunityLineItem>();
	            for(Object ord : listItems) {
	          	TractObject.OrderItem tractOrderItem = (TractObject.OrderItem) JSON.deserialize(JSON.serialize(ord), TractObject.OrderItem.class);
	         	for(TractObject.CustomFieldValue tracObjCus : tractOrderItem.custom_field_values) {
	        			if(tracObjCus.custom_field.name == 'SF Opportunity Line Item') {
	        				OpportunityLineItem oli = new OpportunityLineItem();
	        				oli.id = tracObjCus.value ;
	        				oli.Tract_ServiceId__c =  tractOrderItem.service.id;
	        				lstoli.add(oli);
	        			}
	        		}
	        			
                }
                update lstoli;
                if(!GW_User.isGuest(UserInfo.getUserId())) System.enqueueJob(new AsyncGetTractServiceFlow(opp.Id));
            }
            else if(this.result.statusCode != UTIL_WSC.HTTP_CREATED) {
                //TODO:??

            }
            else {
                UTIL.logClean('Error getting response from server - no response received.');
                response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract No response received from service.');
            }
        }
    }

    public class BillingAccountCreate_Handler extends ApiHandler {
    
        public override void handle() {
        
            super.handle();
            Map<String,Object> response = (Map<String,Object>) result.getResponseData().get('results');

            if (result.statusCode == UTIL_WSC.HTTP_CREATED && response != null && response.containsKey('account_num') == TRUE) {
                Account acc = GW_Account.getRecord(request.contextRecord.Id);
                if (acc != null) {
                
                    try {
                    	acc.Tract_AccountId__c = (String) response.get('id'); // TBD: change
                    	acc.Tract_AccountNumber__c = (String) response.get('account_num'); // TBD: change
                    	acc.tract_last_error__c = '';
                    	//acc.Account_Status__c = (String) response.get('status');
                    	if(response.containsKey('responsible_party')){
	                        String strJson = Json.serializePretty(response.get('responsible_party'));
                        	Map<String,Object> valueMap = (Map<String, Object>)JSON.deserializeUntyped(strJson);
                        	if(!valueMap.isEmpty() && valueMap.containsKey('id'))
	                            acc.Tract_ResponsiblePartyId__c = (String)valueMap.get('id');
                    	}
                    	if(response.containsKey('custom_field_values')){
                        	//Placeholder to update account dunning fields based on tract response
                    	}

                	} catch (Exception e) {
    	                UTIL.logClean('Error parsing: ' + e.getMessage() + e.getStackTraceString());
	                }
        	        UTIL.logClean('WSC_Tract create account: ' + acc);
            	    UTIL_WSC.doUpdate(acc);
	        	}
        	}
    		else if(this.result.statusCode != UTIL_WSC.HTTP_CREATED) {

	            Account acc = GW_Account.getRecord(request.contextRecord.Id);
	            if(response != null){
	                system.debug('Contains Key');
	                acc.tract_last_error__c = (String) response.get('error_message'); // TBD: change
	            }else{
	                acc.tract_last_error__c = 'Cannot create Billing Account';
	            }
	
	            UTIL_WSC.doUpdate(acc);
	            UTIL.logClean('WSC_Tract Unknown error, result: ' + this.result);
	            response = new Map<String,Object>();
	            response.put('catalystError', true);
	            response.put('catalystMessage', 'WSC_Tract Unknown error');

	        } 
	        else {
	            UTIL.logClean('Error getting response from server - no response received.');
	            response = new Map<String,Object>();
    	        response.put('catalystError', true);
        	    response.put('catalystMessage', 'WSC_Tract No response received from service.');
	        }
		}
	}

    public class GhostBillingAccountCreate_Handler extends ApiHandler {
    
        public override void handle() {
        
            super.handle();
            Map<String,Object> response = (Map<String,Object>) result.getResponseData().get('results');

            if (result.statusCode == UTIL_WSC.HTTP_CREATED && response != null && response.containsKey('account_num') == TRUE) {
            	String tract_AccountNumber = (String) response.get('account_num'); // TBD: change
            	UTIL.logClean('WSC_Tract create ghost account: ' +  tract_AccountNumber);
        	}
    		else if(this.result.statusCode != UTIL_WSC.HTTP_CREATED) {
	            UTIL.logClean('WSC_Tract Unknown error, result: ' + this.result );
	            response = new Map<String,Object>();
	            response.put('catalystError', true);
	            response.put('catalystMessage', 'WSC_Tract Unknown error');
	        } 
	        else {
	            UTIL.logClean('Error getting response from server - no response received.');
	            response = new Map<String,Object>();
    	        response.put('catalystError', true);
        	    response.put('catalystMessage', 'WSC_Tract No response received from service.');
	        }
		}
	}

    private static List<UTIL_Fieldmapper.mappedElement> getMapper_BillingAccountUpdateAddr(Id accId) {
        Account acc             = (Account) UTIL.getCached(accId);
        
        String contryCode = acc.BillingCountry;
        for(CountryStateISO__c stt : CountryStateISO__c.getAll().values()) {
            if(contryCode.equalsIgnoreCase(stt.FullName__c+'')) {
                contryCode = stt.ThreeLetterCode__c;
                break;
            }
        }
        
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add(new UTIL_Fieldmapper.mappedField('address_type',       'postal', 'String', 10, TRUE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('purpose',            'BILLING', 'String', 10, TRUE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('country',            contryCode, 'String', 32, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('city',               acc.BillingCity, 'String', 100, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('line1',              acc.BillingStreet, 'String', 100, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('id',                 '', 'String', 10, FALSE, TRUE));
        elements.add( new UTIL_Fieldmapper.mappedField('region_or_state',   acc.BillingState, 'String', 100, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('postal_code',        acc.BillingPostalCode, 'String', 32, FALSE, TRUE));
        
        return elements;
    }
    
    public class BillingAccountUpdateAddr extends GenericRequest {
        Account acc;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('BillingAccountUpdateAddr',APINAME);
            super.init(contextRecordId);
            acc = (Account) this.contextRecord;
            this.mapper.mappingElements = getMapper_BillingAccountUpdateAddr(contextRecordId);
            this.setHeader('Content-Type', 'application/json');
            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'organizations/' + acc.Tract_ResponsiblePartyId__c + '/addresses';
            }
            this.setEndpoint( endpoint );
            this.setHttpMethod('POST'); // update
        }
        
        public virtual override Boolean readyForCallout() {
            return (acc.Tract_AccountId__c != null && acc.Tract_ResponsiblePartyId__c != null);
        }
    }
    private static List<UTIL_Fieldmapper.mappedElement> getMapper_ServiceAccountUpdateAddr(Id accId) {
        Account acc             = (Account) UTIL.getCached(accId);
        
        String contryCode = acc.BillingCountry;
        for(CountryStateISO__c stt : CountryStateISO__c.getAll().values()) {
            if(contryCode.equalsIgnoreCase(stt.FullName__c+'')) {
                contryCode = stt.ThreeLetterCode__c;
                break;
            }
        }
        
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add(new UTIL_Fieldmapper.mappedField('address_type',       'postal', 'String', 10, TRUE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('purpose',            'SERVICE', 'String', 10, TRUE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('country',            contryCode, 'String', 32, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('city',               acc.ServiceCity__c, 'String', 100, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('line1',              acc.ServiceStreet__c, 'String', 100, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('id',                 '', 'String', 10, FALSE, TRUE));
        elements.add( new UTIL_Fieldmapper.mappedField('region_or_state',   acc.ServiceState__c, 'String', 100, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('postal_code',        acc.ServicePostalCode__c, 'String', 32, FALSE, TRUE));
        
        return elements;
    }
     
   public class ServiceAccountUpdateAddr extends GenericRequest {
        Account acc;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('ServiceAccountUpdateAddr',APINAME);
            super.init(contextRecordId);
            acc = (Account) this.contextRecord;
            this.mapper.mappingElements = getMapper_ServiceAccountUpdateAddr(contextRecordId);
            this.setHeader('Content-Type', 'application/json');
            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'organizations/' + acc.Tract_ResponsiblePartyId__c + '/addresses';
            }
            this.setEndpoint( endpoint );
            this.setHttpMethod('POST'); // update
        }
        
        public virtual override Boolean readyForCallout() {
            return (acc.Tract_AccountId__c != null && acc.Tract_ResponsiblePartyId__c != null);
        }
    }
    
    private static List<UTIL_Fieldmapper.mappedElement> getMapper_BillingAccountUpdateResponsible(Id accId) {
        Account acc  = (Account) UTIL.getCached(accId);
      
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        if(acc == null) return elements;
        Boolean isTaxValidate = acc.VAT_Check_Status__c != null && (acc.VAT_Check_Status__c.equalsIgnoreCase('TRUE') || acc.VAT_Check_Status__c.equalsIgnoreCase('VALID'));
  		elements.add(new UTIL_Fieldmapper.mappedField('id',                              acc.Tract_ResponsiblePartyId__c, 'String', 255, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('party_type',                     'organization', 'String', 255, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('organization_name',               acc.Name, 'String', 255, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('tax_id_number',                   acc.Company_VAT_No__c, 'String', 255, FALSE, TRUE));
        	elements.add(new UTIL_Fieldmapper.mappedField('tax_id_validated',                isTaxValidate, 'BOOLEAN', 5, FALSE, TRUE));
       
        return elements;
    }
    
    public class BillingAccountUpdateResponsible extends GenericRequest {
        Account acc;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('BillingAccountUpdateResponsible',APINAME);
            super.init(contextRecordId);
            acc = (Account) this.contextRecord;
            this.mapper.mappingElements = getMapper_BillingAccountUpdateResponsible(contextRecordId);
            //this.mockMap.putAll(getMocks_BillingAccountUpdate());

            String endpoint = '';
            if( this.baseEndpoint != null ){
               // endpoint = this.baseEndpoint + 'billing-accounts/' + acc.Tract_AccountId__c;
               endpoint = this.baseEndpoint + 'organizations/' + acc.Tract_ResponsiblePartyId__c ;
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );
            UTIL.log('Req body: ' + this.getBody());

            this.setHttpMethod('PUT');
        }

        public virtual override Boolean readyForCallout() {
            //return (acc.Tract_AccountId__c != null);
            return (acc.Tract_AccountId__c != null && acc.Tract_ResponsiblePartyId__c != null);
        }
    }

    public class BillingAccountGetFromContact extends GenericRequest {
        Contact con;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('BillingAccountGetFromContact', APINAME);
            super.init(contextRecordId);
            Contact[] cons = (List<Contact>) GW_sObject.queryRecords('Contact', new Set<Id> {contextRecordId}, new List<String> {'Account.Tract_AccountId__c'});
            con = cons[0];
            this.mapper.mappingElements = new List<UTIL_Fieldmapper.MappedElement>();
            this.setHandlerClass(APINAME + '.BillingAccountGet_HandlePeopleUpdate');
            this.setEndpoint((WS == null ? '' :  WS.Endpoint__c) + 'billing-accounts/' + con.Account.Tract_AccountId__c);
            this.setHttpMethod('GET');
        }
        public virtual override Boolean readyForCallout() { return con.Account.Tract_AccountId__c != null; }
    }
    
    public class BillingAccountGet_HandlePeopleUpdate extends ApiHandler {
        public override void handle() {
            try { 
                super.handle();
                Map<String,Object> response = (Map<String,Object>) result.getResponseData().get('results');
                if(response.containsKey('results')) response = (Map<String,Object>) response.get('results');
                if (result.statusCode == UTIL_WSC.HTTP_OK && response != null) {
                    Object[] contactObjs = (List<Object>) response.get('contacts');
                    if(!contactObjs.isEmpty()) {
                        Contact con = (Contact) this.request.contextRecord;
                        for(Object conObj : contactObjs) {
                            Map<String,Object> mCon = (Map<String,Object>) conObj;
                            WSC_Tract.PeopleUpdateEmail reqEmail = (WSC_Tract.PeopleUpdateEmail) UTIL_WSC.getWSC_Request('WSC_Tract.PeopleUpdateEmail');
                            reqEmail.peopleId = mCon.get('id') + '';
                            reqEmail.init(con.id);
                            UTIL_WSC.WSC_Result resEmail = reqEmail.call();
                            
                            WSC_Tract.PeopleUpdatePersonalInfo reqInfo = (WSC_Tract.PeopleUpdatePersonalInfo) UTIL_WSC.getWSC_Request('WSC_Tract.PeopleUpdatePersonalInfo');
                            reqInfo.peopleId = mCon.get('id') + '';
                            reqInfo.init(con.id);
                            UTIL_WSC.WSC_Result resInfo = reqInfo.call();

                            WSC_Tract.PeopleUpdatePhone reqPhone = (WSC_Tract.PeopleUpdatePhone) UTIL_WSC.getWSC_Request('WSC_Tract.PeopleUpdatePhone');
                            reqPhone.peopleId = mCon.get('id') + '';
                            reqPhone.init(con.id);
                            UTIL_WSC.WSC_Result resPhone = reqPhone.call();
                            break;
                        }
                    }
                }
            } catch(Exception e) {
                UTIL.logClean('Error HandlePeopleUpdate: ' + e.getMessage() + e.getStackTraceString());
            }
        }
    }
    
    public class PeopleUpdateEmail extends GenericRequest {
        Contact con;
        public String peopleId;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('PeopleUpdateEmail', APINAME);
            super.init(contextRecordId);
            con = (Contact) this.contextRecord;
            
            List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
            elements.add(new UTIL_Fieldmapper.mappedField('address_type',       'email', 'String', 10, TRUE, TRUE));
            elements.add(new UTIL_Fieldmapper.mappedField('purpose',        'PRIMARY', 'String', 10, TRUE, TRUE));
            elements.add(new UTIL_Fieldmapper.mappedField('email',      con.Email, 'String', 255, TRUE, TRUE));
            
            this.mapper.mappingElements = elements;
            this.setHeader('Content-Type', 'application/json; charset=utf8');
            this.setEndpoint((WS == null ? '' :  WS.Endpoint__c) + 'people/' + peopleId + '/addresses');
            this.setHttpMethod('POST');
        }
        public virtual override Boolean readyForCallout() { return String.isNotBlank(peopleId); }
    }

    public class PeopleUpdatePersonalInfo extends GenericRequest {
        Contact con;
        public String peopleId;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('PeopleUpdatePersonalInfo', APINAME);
            super.init(contextRecordId);
            con = (Contact) this.contextRecord;
            this.mapper.mappingElements = getMapper_PeopleUpdatePersonalInfo(con);
            this.setHeader('Content-Type', 'application/json; charset=utf8');
            this.setEndpoint((WS == null ? '' :  WS.Endpoint__c) + 'people/' + peopleId );
            this.setHttpMethod('PUT');
        }
        public virtual override Boolean readyForCallout() { return String.isNotBlank(peopleId); }
    }

    public class PeopleUpdatePhone extends GenericRequest {
        Contact con;
        public String peopleId;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('PeopleUpdatePhone', APINAME);
            super.init(contextRecordId);
            con = (Contact) this.contextRecord;
            String phoneNo = con.Phone.startsWith('+') ? con.Phone.replace('+', '00') : con.Phone;
            List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
            elements.add(new UTIL_Fieldmapper.mappedField('address_type',       'telecom', 'String', 10, TRUE, TRUE));
            elements.add(new UTIL_Fieldmapper.mappedField('purpose',        'MOBILE', 'String', 10, TRUE, TRUE));
            elements.add(new UTIL_Fieldmapper.mappedField('number',      phoneNo, 'String', 255, TRUE, TRUE));
            
            this.mapper.mappingElements = elements;
            this.setHeader('Content-Type', 'application/json; charset=utf8');
            this.setEndpoint((WS == null ? '' :  WS.Endpoint__c) + 'people/' + peopleId + '/addresses');
            this.setHttpMethod('POST');
        }
        public virtual override Boolean readyForCallout() { 
            return String.isNotBlank(peopleId); 
        }
    }

    private static List<UTIL_Fieldmapper.mappedElement> getMapper_PeopleUpdatePersonalInfo(Contact con) {
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add(new UTIL_Fieldmapper.mappedField('party_type',       'person', 'String', 10, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('suffix',          String.isNotBlank(con.Salutation) ? con.Salutation : '', 'String', 10, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('title',           String.isNotBlank(con.Title) ? con.Title : '', 'String', 255, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('first_name',      String.isNotBlank(con.FirstName) ? con.FirstName : '', 'String', 255, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('last_name',       String.isNotBlank(con.LastName) ? con.LastName : '', 'String', 255, FALSE, TRUE));
        elements.add(new UTIL_Fieldmapper.mappedField('middle_name',     String.isNotBlank(con.MiddleName__c) ? con.MiddleName__c : '', 'String', 255, FALSE, TRUE));

        return elements;
    }
    
public class PriceBookSync extends ApiRequest {
    CustomJob__c cj;
    
    public override void init(Id contextRecordId) {
        this.setCalloutDetails('PriceBookSync', APINAME);
        super.init(contextRecordId);
        cj = (CustomJob__c) this.contextRecord;

        this.setHandlerClass(APINAME+'.PriceBookSync_Handler');
        
        String endpoint = '';
       
        if( this.baseEndpoint != null ){
          endpoint = this.baseEndpoint + 'price-lists';
        }
        
        this.setEndpoint( endpoint );
        UTIL.log('PriceBookSync_Endpoint: ' + endpoint );

        this.setHttpMethod('GET');
    }
}

public class PriceBookSync_Handler extends UTIL_WSC.WSC_ResultHandler {

    public override void handle() {
        super.handle();
        UTIL.log('STATUS CODE '+this.result.statusCode);
        UTIL.log(this.result);
        if (this.result.statusCode == HTTP_OK) {

            CustomJob__c cj = (CustomJob__c) this.request.contextRecord;
            Map<String, Object> responseData = this.result.getResponseData();

            List<Object> tractPriceListObjects = (List<Object>) responseData.get('results');
                
            if (tractPriceListObjects != null) {
                UTIL_WSC_Tract.PriceBookSync priceBookSync = new UTIL_WSC_Tract.PriceBookSync(tractPriceListObjects);
                priceBookSync.commitAll();
            }
        }
    }
}

public class ProductSync extends ApiRequest { 
    public override void init(Id contextRecordId) {
        this.setCalloutDetails('ProductSync', APINAME);
        super.init(contextRecordId);
        String pageNum = String.valueOf(this.mAdditionalParams.get('page_number'));
        String price_list_id = String.valueOf(this.mAdditionalParams.get('price_list_id'));
        this.setHandlerClass(APINAME+'.ProductSync_Handler');
        
        String endpoint = '';
        if( this.baseEndpoint != null ){
            endpoint = this.baseEndpoint + 'products?price_list_id=' + price_list_id + '&product_state=AVAILABLE&page_number=' + pageNum;
        }
        
        this.setEndpoint( endpoint );
        UTIL.log('Endpoint: ' + endpoint );
        this.setHttpMethod('GET');
    }
}

public class ProductSync_Handler extends UTIL_WSC.WSC_ResultHandler {

    public override void handle() {
        super.handle();
        UTIL.log('STATUS CODE '+this.result.statusCode);
        UTIL.log(this.result);
        if (this.result.statusCode == HTTP_OK) {
            Map<String, Object> responseData = this.result.getResponseData();
            String currentTractPriceListId = String.valueOf(this.request.mAdditionalParams.get('price_list_id'));
            system.debug('ProductSync_Handler_currentTractPriceListId = '+currentTractPriceListId);

            List<Object> tractProductsObjects = (List<Object>) responseData.get('results');
                
            if (tractProductsObjects != null) {
                UTIL_WSC_Tract.ProductSync productSync = new UTIL_WSC_Tract.ProductSync(currentTractPriceListId, tractProductsObjects);
                productSync.commitAll();
            }
        }
    }
}

public class DiscountResourceSync extends ApiRequest {
    CustomJob__c cj;
    public override void init(Id contextRecordId) {
        this.setCalloutDetails('DiscountResourceSync', APINAME);
        super.init(contextRecordId);
        cj = (CustomJob__c) this.contextRecord;

        this.setHandlerClass(APINAME+'.DiscountResourceSync_Handler');

        // Authorization now is made using an encryption string as a URL parameter  
        //this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsKeystring));

        String endpoint = '';
        if( this.baseEndpoint != null ){
            endpoint = this.baseEndpoint + 'discount-resources';
        }
        this.setEndpoint( endpoint );
        UTIL.log('Endpoint: ' + endpoint );

        this.setHttpMethod('GET');
    }

}

public class DiscountResourceSync_Handler extends UTIL_WSC.WSC_ResultHandler {

    public override void handle() {
        super.handle();
        UTIL.log('STATUS CODE '+this.result.statusCode);
        UTIL.log(this.result);
        if (this.result.statusCode == HTTP_OK) {

            CustomJob__c cj = (CustomJob__c) this.request.contextRecord;
            Map<String, Object> responseData = this.result.getResponseData();

            List<Object> tractDiscountResourceObjects = (List<Object>) responseData.get('results');

            if (tractDiscountResourceObjects != null) {
                UTIL_WSC_Tract.DiscountResourceSync discountResourceSync = new UTIL_WSC_Tract.DiscountResourceSync(tractDiscountResourceObjects);
                discountResourceSync.commitAll();
            }
        }
    }
}

public class ProductRelationsSync extends ApiRequest {
    Product2 masterProduct;
    public override void init(Id contextRecordId) {
        this.setCalloutDetails('ProductRelationsSync', APINAME);
        super.init(contextRecordId);
        masterProduct = (Product2) this.contextRecord;

        this.setHandlerClass(APINAME+'.ProductRelationsSync_Handler');

        // Authorization now is made using an encryption string as a URL parameter  
        //this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsKeystring));

        String endpoint = '';
        if( this.baseEndpoint != null ){
            endpoint = this.baseEndpoint + 'product-relations?product_id=' + masterProduct.Tract_Id__c;
        }
        this.setEndpoint( endpoint );
        UTIL.log('Endpoint: ' + endpoint );

        this.setHttpMethod('GET');
    }

    public override Boolean readyForCallout() {
        return (masterProduct != null &&
                masterProduct.Tract_Id__c != null && !masterProduct.Tract_Id__c.contains(UTIL_WSC_Tract.ID_SEPARATOR) &&
                masterProduct.Tract_NeedsRelationsSync__c
        );
    }
}

public class ProductRelationsSync_Handler extends UTIL_WSC.WSC_ResultHandler {

    public override void handle() {
        super.handle();
        UTIL.log('STATUS CODE '+this.result.statusCode);
        UTIL.log(this.result);
        if (this.result.statusCode == HTTP_OK) {

            Product2 product = (Product2) this.request.contextRecord;
            Map<String, Object> responseData = this.result.getResponseData();

            List<Object> tractProductRelationObjects = (List<Object>) responseData.get('results');

            if (tractProductRelationObjects != null) {
                UTIL_WSC_Tract.syncProductRelations(product, tractProductRelationObjects);
            }
        }
    }
}

    public class ProductDiscountRelationsSync extends ApiRequest {
        Product2 masterProduct;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('ProductDiscountRelationsSync', APINAME);
            super.init(contextRecordId);
            masterProduct = (Product2) this.contextRecord;

            this.setHandlerClass(APINAME+'.ProductDiscountRelationsSync_Handler');

            // Authorization now is made using an encryption string as a URL parameter  
            //this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsKeystring));

            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'discount-codes?product_id=' + masterProduct.Tract_Id__c;
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );

            this.setHttpMethod('GET');
        }

        public override Boolean readyForCallout() {
            return (masterProduct != null &&
                    masterProduct.Tract_Id__c != null && !masterProduct.Tract_Id__c.contains(UTIL_WSC_Tract.ID_SEPARATOR) &&
                    masterProduct.Tract_NeedsDiscountRelationsSync__c);
        }
    }

    public class ProductDiscountRelationsSync_Handler extends UTIL_WSC.WSC_ResultHandler {

        public override void handle() {
            super.handle();
            UTIL.log('STATUS CODE '+this.result.statusCode);
            UTIL.log(this.result);
            if (this.result.statusCode == HTTP_OK) {

                Product2 product = (Product2) this.request.contextRecord;
                Map<String, Object> responseData = this.result.getResponseData();

                List<Object> tractDiscountCodeObjects = (List<Object>) responseData.get('results');

                if (tractDiscountCodeObjects != null) {
                    UTIL_WSC_Tract.syncProductDiscountRelations(product, tractDiscountCodeObjects);
                }
            }
        }
    }




    public class DiscountCodesSync extends ApiRequest {
    Discount__c discount;
    public override void init(Id contextRecordId) {
        this.setCalloutDetails('DiscountCodesSync', APINAME);
        super.init(contextRecordId);
        discount = (Discount__c) this.contextRecord;

        this.setHandlerClass(APINAME+'.DiscountCodesSync_Handler');

        // Authorization now is made using an encryption string as a URL parameter  
        //this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsKeystring));

        String endpoint = '';
        if( this.baseEndpoint != null ){
            endpoint = this.baseEndpoint + 'discount-codes?discount_resource_id=' + discount.Tract_ResourceId__c;
        }
        this.setEndpoint( endpoint );
        UTIL.log('Endpoint: ' + endpoint );

        this.setHttpMethod('GET');
    }

    public override Boolean readyForCallout() {
        Boolean readyForCallout = (discount != null &&
                discount.Tract_ResourceId__c != null &&
                discount.Tract_NeedsCodeSync__c
        );

        UTIL.log('Ready for callout: ' + readyForCallout);

        return readyForCallout;
    }
}

public class DiscountCodesSync_Handler extends UTIL_WSC.WSC_ResultHandler {

    public override void handle() {
        super.handle();
        UTIL.log('STATUS CODE '+this.result.statusCode);
        UTIL.log(this.result);
        if (this.result.statusCode == HTTP_OK) {

            Discount__c discount = (Discount__c) this.request.contextRecord;
            Map<String, Object> responseData = this.result.getResponseData();

            List<Object> tractDiscountCodeObjects = (List<Object>) responseData.get('results');

            if (tractDiscountCodeObjects != null) {
                UTIL_WSC_Tract.syncDiscountCodes(discount, tractDiscountCodeObjects);
            }
        }
    }
}

public class DiscountContentSync extends ApiRequest {
    CustomJob__c cj;
    public override void init(Id contextRecordId) {
        this.setCalloutDetails('DiscountContentSync', APINAME);
        super.init(contextRecordId);
        cj = (CustomJob__c) this.contextRecord;

        this.setHandlerClass(APINAME+'.DiscountContentSync_Handler');

        this.getWsSettings(APINAME, null);

        // Authorization now is made using an encryption string as a URL parameter  
        //this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsKeystring));

        String endpoint = '';
        if( this.baseEndpoint != null ){
            endpoint = this.baseEndpoint + 'discounts';
        }
        this.setEndpoint( endpoint );
        UTIL.log('Endpoint: ' + endpoint );

        this.setHttpMethod('GET');
    }

}

public class DiscountContentSync_Handler extends UTIL_WSC.WSC_ResultHandler {

    public override void handle() {
        super.handle();
        UTIL.log('STATUS CODE '+this.result.statusCode);
        UTIL.log(this.result);
        if (this.result.statusCode == HTTP_OK) {

            CustomJob__c cj = (CustomJob__c) this.request.contextRecord;
            Map<String, Object> responseData = this.result.getResponseData();

            List<Object> tractDiscountObjects = (List<Object>) responseData.get('results');

            if (tractDiscountObjects != null) {
                UTIL_WSC_Tract.DiscountSync discountSync = new UTIL_WSC_Tract.DiscountSync(tractDiscountObjects);
                discountSync.commitAll();
            }
        }
    }
}

public class CreateEmailAddress extends GenericRequest {
        Contact con;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('CreateEmailAddress',APINAME);
            
            Contact[] cons = (List<Contact>) GW_sObject.queryRecords('Contact', new Set<Id> {contextRecordId}, new List<String> {'Account.Tract_ResponsiblePartyId__c','Account.Tract_AccountId__c'});
            UTIL.cache(cons);
            con = cons[0];
            super.init(contextRecordId);
            this.mapper.mappingElements = getMapper_CreateEmailAddress(con);
            this.setHandlerClass(APINAME + '.CreateEmailAddress_Handler');
            this.setHeader('Content-Type', 'application/json');
            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'organizations/' + con.Account.Tract_ResponsiblePartyId__c + '/addresses';
            }
            this.setEndpoint( endpoint );
            this.setHttpMethod('POST');
        }
        
        public virtual override Boolean readyForCallout() {
            return (con.Email != null);
        }
    }

    public class CreateEmailAddress_Handler extends ApiHandler {
        public override void handle() {
            super.handle();
            Map<String,Object> response = (Map<String,Object>) result.getResponseData().get('results');
                
            if (result.statusCode == UTIL_WSC.HTTP_CREATED && response != null && response.containsKey('id') == TRUE) {
                /* Moved to GW_Account.callAccountPush() if this is for selfbooking please update there
                Contact[] cons = (List<Contact>) GW_sObject.queryRecords('Contact', new Set<Id> {request.contextRecord.Id}, new List<String> {'Account.Tract_ResponsiblePartyId__c','Account.Tract_AccountId__c'});
                Contact con = cons[0];
                if (con.Account.Tract_AccountId__c != null) {
                    try {
                        if(!accountsToUpdate.contains(con.AccountId)){
                            accountsToUpdate.add(con.AccountId);
                            WSC_Request wsRequest = getWSC_Request('WSC_Tract.BillingAccountUpdate');
                            wsRequest.init(con.AccountId);
                            if (wsRequest.checkWsSettings()) { // only go ahead if there is a Webservice_Settings__c config setting registered for this Member(Unit)

                                if ( wsRequest.readyForCallout() ) { // this check is a virtual method that can be overrided per specific API or method
                                    UTIL_WSC.bulkHandler.wsscToUpsert.add( wsRequest.getScheduledCallout() );
                                }
                            }
                        }
                    } catch (Exception e) {
                        UTIL.logClean('Error parsing: ' + e.getMessage() + e.getStackTraceString());
                    }
                    UTIL.logClean('WSC_Tract BillingAccountUpdate: ' + con.AccountId);
                }*/
            }
            else if(this.result.statusCode != UTIL_WSC.HTTP_CREATED) {

                UTIL.logClean('WSC_Tract Unknown error, result: ' + this.result);
                response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract Unknown error');

            }
            else {
                UTIL.logClean('Error getting response from server - no response received.');
                response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract No response received from service.');
            }
        }
    }

    private static List<UTIL_Fieldmapper.mappedElement> getMapper_CreateEmailAddress(Contact con) {
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        if(String.isNotBlank(con.Email)){ 
            elements.add(new UTIL_Fieldmapper.mappedField('address_type',       'email', 'String', 10, FALSE, TRUE));
            elements.add(new UTIL_Fieldmapper.mappedField('purpose',        'PRIMARY', 'String', 10, FALSE, TRUE));
            elements.add(new UTIL_Fieldmapper.mappedField('email',      con.Email, 'String', 255, FALSE, TRUE));
        }
        return elements;
    }

    public class BillingAccountUpdate extends GenericRequest {
        Account acc;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('BillingAccountUpdate',APINAME);
            super.init(contextRecordId);
            acc = (Account) this.contextRecord;
            this.mapper.mappingElements = getMapper_BillingAccountUpdateNew(contextRecordId);
            //this.mockMap.putAll(getMocks_BillingAccountUpdate());

            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'billing-accounts/' + acc.Tract_AccountId__c;
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );
            UTIL.log('Req body: ' + this.getBody());

            this.setHttpMethod('PUT');
        }

        public virtual override Boolean readyForCallout() {
            return (acc.Tract_AccountId__c != null);
        }
    }


    private static List<UTIL_Fieldmapper.mappedElement> getMapper_BillingAccountUpdateNew(Id accId) {
        Account acc             = (Account) UTIL.getCached(accId);
        //system.assert(FALSE, 'acc : '+acc);
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        if(acc == null) return elements;
        elements.add(new UTIL_Fieldmapper.mappedField('bill_type',                  'EMAIL', 'String', 50, FALSE, TRUE));
        elements.add((new UTIL_Fieldmapper.mappedObject('responsible_party')).
            add(new UTIL_Fieldmapper.mappedField('object_type',                         'responsible-party', 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('id',                                  acc.Tract_ResponsiblePartyId__c, 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('party_type',                          'organization', 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('organization_name',                   acc.Name, 'String', 255, FALSE, TRUE))
        );
        return elements;
    }
    
    public class BillingAccountAutoPayment extends GenericRequest {
        Account acc;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('BillingAccountAutoPayment', APINAME);
            super.init(contextRecordId);
            acc = (Account) this.contextRecord;
            this.mapper.mappingElements = getMapper_BillingAccountAutoPayment(contextRecordId);

            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'billing-accounts/' + acc.Tract_AccountId__c;
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );
            UTIL.log('Req body: ' + this.getBody());

            this.setHttpMethod('PUT');
        }

        public virtual override Boolean readyForCallout() {
            return (acc.Tract_AccountId__c != null);
        }
    }

    private static List<UTIL_Fieldmapper.mappedElement> getMapper_BillingAccountAutoPayment(Id accId) {
        Account acc             = (Account) UTIL.getCached(accId);
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        if(acc == null) return elements;
        Boolean autoPayment = acc.Billing_Preference__c == 'Direct Debit' ? TRUE : FALSE;
        elements.add(new UTIL_Fieldmapper.mappedField('auto_payment_authorized', autoPayment, 'BOOLEAN', 18, FALSE, TRUE));
        return elements;
    }


public virtual class ApiRequest extends UTIL_WSC.WSC_Request {
    public virtual override void init(Id contextRecordId) {
        super.init(contextRecordId);
        this.setResultClass(APINAME + '.ApiResult');
        this.setHandlerClass(APINAME + '.ApiHandler');
        this.getWsSettings(APINAME,null);
        this.setHeader('Accept','application/json');
        this.setHeader('Content-Type', 'application/json');
        
        //CD-3373 Remove API Key from TRACT Endpoints
        this.setHeader('x-api-key', getApiKey(this.wsKeystring, this.endpointURLParameters));
        // Authorization now is made using an encryption string as a URL parameter  
        //this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsKeystring));
    }
}

public virtual class ApiResult extends UTIL_WSC.WSC_Result {
    public override Map<String,Object> getResponseData() {
        try {
            system.debug('resp==='+resp);
            if (resp !=null && !String.isBlank(resp.getBody()) )
                return new Map<String,Object> {'results' => (Object) JSON.deserializeUntyped(resp.getBody())};
            else {
                return new Map<String,Object> {'results' => null};
            }
        } catch (Exception e) {
            String errorMsg = 'Error processing response data. ' +e.getMessage()+' '+e.getTypeName()+ '\n';
            Map<String, Object> responseData = new Map<String,Object>();
            responseData.put('catalystError', e.getMessage());
            responseData.put('body', resp.getBody());
            responseData.put('catalystMessage', errorMsg);
            return responseData;
        }
    }
    public override String getFormattedBody() {
        this.urlEncode = false;
        Map<String,Object> resp = this.getResponseData();
        if (resp != null) {
            Map<String,Object> reversedMap = new Map<String,Object>();
            List<String> keys = new List<String>(resp.keySet());
            for (Integer i = keys.size()-1; i >= 0; i--  ) {
                reversedMap.put(keys[i], resp.get(keys[i]));
            }

            return JSON.serializePretty(reversedMap);
        } else return '<Empty>';

    }
}
    
public static void checkForOrderTractProcessingselfService(String Id){
        List<WS_ScheduledCallout__c> wsscToUpsertselfService = new List<WS_ScheduledCallout__c>();
        WS_ScheduledCallout__c wsScheduledCallout;
        WS_ScheduledCallout__c wsScheduledCalloutDraftOrder;
        WS_ScheduledCallout__c wsScheduledCalloutActivationOrder;
        WS_ScheduledCallout__c wsScheduledCalloutPayments;
        WS_ScheduledCallout__c wsScheduledCalloutGetAgreement;
        WS_ScheduledCallout__c wsScheduledCalloutBookingPushTract;
        WS_ScheduledCallout__c wsScheduledCalloutTractAccount;

        Opportunity opp = GW_Opportunity.getRecord(Id);
        String wssoAcc = '';
        String wssoAgr = '';

        system.debug('TestByToday');

        Account acc = GW_Account.getRecord(opp.AccountId);

        if(String.isBlank(acc.Tract_AccountId__c)){
            UTIL_WSC.WSC_Request wsRequestAccTract = UTIL_WSC.getWSC_Request('WSC_Tract.BillingAccountCreate');
            wsRequestAccTract.init(acc.id);
            wsScheduledCalloutTractAccount = wsRequestAccTract.getScheduledCallout();
            wsscToUpsertselfService.add(wsScheduledCalloutTractAccount);
            upsert wsscToUpsertselfService UniqueKey__c;
            wssoAcc = wsScheduledCalloutTractAccount.Id;

        }
        //Check if opp has a agreement id
        if(String.isBlank(opp.Tract_AgreementId__c)){
            UTIL_WSC.WSC_Request wsRequestGetAgreement = UTIL_WSC.getWSC_Request('WSC_Tract.GetAgreementId');
            wsRequestGetAgreement.init(opp.id);
            wsScheduledCalloutGetAgreement = wsRequestGetAgreement.getScheduledCallout();
            wsScheduledCalloutGetAgreement.DependsOnScheduledCallout__c =  String.isBlank(wssoAcc) ? null:  wssoAcc;
            wsscToUpsertselfService.add(wsScheduledCalloutGetAgreement);
            upsert wsscToUpsertselfService UniqueKey__c;
            wssoAgr = wsScheduledCalloutGetAgreement.Id;
        }

        //send out the draft order
        UTIL_WSC.WSC_Request wsRequestDraftOrder = UTIL_WSC.getWSC_Request('WSC_Tract.DraftOrderCreate');
        wsRequestDraftOrder.init(opp.id);
        wsScheduledCalloutDraftOrder = wsRequestDraftOrder.getScheduledCallout();
        wsScheduledCalloutDraftOrder.DependsOnScheduledCallout__c = String.isBlank(wssoAgr) ? null : wssoAgr;
        wsscToUpsertselfService.add(wsScheduledCalloutDraftOrder);
        upsert wsscToUpsertselfService UniqueKey__c;

        // Do the activation Call
        UTIL_WSC.WSC_Request wsRequestActivationOrder = UTIL_WSC.getWSC_Request('WSC_Tract.OrderTract');
        wsRequestActivationOrder.init(opp.id);
        wsScheduledCalloutActivationOrder = wsRequestActivationOrder.getScheduledCallout();
        wsScheduledCalloutActivationOrder.DependsOnScheduledCallout__c = wsScheduledCalloutDraftOrder.Id;
        wsscToUpsertselfService.add(wsScheduledCalloutActivationOrder);
        upsert wsscToUpsertselfService UniqueKey__c;
        
        List<AccountMemberUnitAssociation__c> amuaList = GW_AccountMemberUnitAssociation.getAll(acc.Id);

        if ((amuaList[0].MemberUnit__r.Pre_Paid_Billing_Cycle__c) != null){
            //Payments Call
            UTIL_WSC.WSC_Request wsRequestPayments = UTIL_WSC.getWSC_Request('WSC_Tract.SentPaymentToTract');
            wsRequestPayments.init(opp.id);
            wsScheduledCalloutPayments = wsRequestPayments.getScheduledCallout();
            wsScheduledCalloutPayments.DependsOnScheduledCallout__c = wsScheduledCalloutActivationOrder.Id;
            wsscToUpsertselfService.add(wsScheduledCalloutPayments);
            upsert wsscToUpsertselfService UniqueKey__c;
        }
        
//        // Finaly send the call to SPOC :-)
//        UTIL_WSC.WSC_Request wsRequestBookingPushTract = UTIL_WSC.getWSC_Request('WSC_API_SFECG_v2.BookingPushTract');
//        wsRequestBookingPushTract.init(opp.id);
//        wsScheduledCalloutBookingPushTract = wsRequestBookingPushTract.getScheduledCallout();
//        wsScheduledCalloutBookingPushTract.DependsOnScheduledCallout__c = wsScheduledCalloutPayments.Id;
//        wsscToUpsertselfService.add(wsScheduledCalloutBookingPushTract);
//        upsert wsscToUpsertselfService UniqueKey__c;
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
}// END ApiHandler

//
public static List<UTIL_Fieldmapper.mappedElement> getMapper_BillingAccountCreate(Id accId) {
    RemoteResponse res = WSC_Tract.getTractCustomFieldIdByName(accId,'billing-account-custom-fields?name=Company+registration+number'); 
    String comRegNumTractCusFieldId = String.valueOf(res.content);
    // This method currently contains plenty of placeholders and hardcoded values to make requests work
    Account acc = (Account) UTIL.getCached(accId);
	
    List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
    List<AccountMemberUnitAssociation__c> amuaList = GW_AccountMemberUnitAssociation.getAll(accId);
    system.debug('amuaList====='+amuaList);

    String billingCycleId = !amuaList.isEmpty() ? amuaList[0].MemberUnit__r.BillCycleText__c : '';
    String currencyText = !amuaList.isEmpty() ? amuaList[0].MemberUnit__r.CurrencyText__c : '';
    String billCategory = !amuaList.isEmpty() ? amuaList[0].MemberUnit__r.BillingCategoryText__c : '';
    String paymentTerm = !amuaList.isEmpty() ? amuaList[0].MemberUnit__r.PaymentTermText__c : '';
    
    String billingtype = 'monthly';
    MemberUnit__c mu = GW_MemberUnit.getMemberUnitById(acc.Member__c);
    if(acc.SelfService__c == true && ( mu != null && mu.Name.startsWithIgnoreCase('Gumtree ZA'))){
        billingCycleId = amuaList[0].MemberUnit__r.Pre_Paid_Billing_Cycle__c;
        billingtype = 'daily';
    }
    //String billingCycleId = acc.SelfService__c == true ? amuaList[0].MemberUnit__r.Pre_Paid_Billing_Cycle__c:amuaList[0].MemberUnit__r.BillCycleText__c;


    elements.add(new UTIL_Fieldmapper.mappedField('object_type',                    'billing-account', 'String', 32, FALSE, FALSE));
    elements.add(new UTIL_Fieldmapper.mappedField('external_account_num',           String.valueOf(acc.Id), 'String', 18, TRUE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedField('bill_type',                      'EMAIL', 'String', 50, FALSE, TRUE));
    
    elements.add(new UTIL_Fieldmapper.mappedField('currency_code',                 currencyText, 'String', 50, FALSE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedField('next_invoice_date',             '', 'String', 50, FALSE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedField('automatic_recurring_payment',    FALSE, 'BOOLEAN', 18, TRUE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedField('status',                         acc.Account_Status__c, 'String', 50, FALSE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedField('pending_charges_total',          '1000', 'String', 50, FALSE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedField('balance',                        '1000', 'String', 50, FALSE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedField('auto_payment_authorized',        FALSE, 'BOOLEAN', 18, FALSE, TRUE));

    Datetime accStartDate = Datetime.newInstance(acc.CreatedDate.year(), acc.CreatedDate.month(), 1);
    //String accStartDateStr = accStartDate.format('yyyy-MM-dd\'T\'hh:mm:ss');
    String accStartDateStr = accStartDate.format('yyyy-MM-dd\'T\'00:00:00'); // fix for CD-3370
    elements.add(new UTIL_Fieldmapper.mappedField( 'start_date', accStartDateStr, 'String', 50, FALSE, TRUE));

    elements.add(new UTIL_Fieldmapper.mappedField('tax_exempt',                     acc.Tax_Exempt__c, 'BOOLEAN', 5, FALSE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedList('recurring_payments',TRUE));
    elements.add(getAccountCustomFieldValues(acc,comRegNumTractCusFieldId));
    //elements.add(new UTIL_Fieldmapper.mappedList('contacts',TRUE));

    //Fill values from Default Member Unit
    if(amuaList != null && !amuaList.isEmpty()){
        elements.add((new UTIL_Fieldmapper.mappedObject('bill_cycle')).
            add(new UTIL_Fieldmapper.mappedField('bill_cycle_type',                     billingtype, 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('id',                                  billingCycleId, 'String', 255, FALSE, TRUE))

        );
        elements.add((new UTIL_Fieldmapper.mappedObject('billing_account_category')).
            add(new UTIL_Fieldmapper.mappedField('object_type',                         'billing-account-category', 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('id',                                  billCategory, 'String', 255, FALSE, TRUE))
        );

        elements.add((new UTIL_Fieldmapper.mappedObject('payment_term')).
            add(new UTIL_Fieldmapper.mappedField('object_type',                     'payment-term', 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('id',                              paymentTerm, 'String', 255, FALSE, TRUE))
        );
    }

    String billingCountryCode = HNDL_Account.getTractCountryCodes(acc.BillingCountryCode,'3');
    String serviceCountryCode = HNDL_Account.getTractCountryCodes(acc.ServiceCountry__c,'3');
    String serviceStateCode = HNDL_Account.getTractCountryCodes((HNDL_Account.getTractCountryCodes(acc.ServiceCountry__c,'2') + ':'+ acc.ServiceState__c),'2');
    Boolean isTaxValidate = acc.VAT_Check_Status__c != null && (acc.VAT_Check_Status__c.equalsIgnoreCase('TRUE') || acc.VAT_Check_Status__c.equalsIgnoreCase('VALID'));
    elements.add((new UTIL_Fieldmapper.mappedObject('responsible_party')).
        add(new UTIL_Fieldmapper.mappedField('object_type',                         'responsible-party', 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('party_type',                          'organization', 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('organization_name',                   acc.Name, 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('tax_id_number',                   acc.Company_VAT_No__c, 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('tax_id_validated',                   isTaxValidate, 'BOOLEAN', 5, FALSE, TRUE)).
        add((new UTIL_Fieldmapper.mappedList('addresses')).
            add(new UTIL_Fieldmapper.mappedObject('').
                add(new UTIL_Fieldmapper.mappedField('object_type',                 'address', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('address_type',                'postal', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('purpose',                     'BILLING', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('country',                     billingCountryCode, 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('city',                        acc.BillingCity, 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('line1',                       acc.BillingStreet, 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('line2',                       '', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('region_or_state',             acc.BillingStateCode, 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('postal_code',                 acc.BillingPostalCode, 'String', 255, TRUE, TRUE))
            ).
            add(new UTIL_Fieldmapper.mappedObject('').
                add(new UTIL_Fieldmapper.mappedField('object_type',                 'address', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('address_type',                'postal', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('purpose',                     'SERVICE', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('country',                     serviceCountryCode, 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('city',                        acc.ServiceCity__c, 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('line1',                       acc.ServiceStreet__c, 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('line2',                       '', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('region_or_state',             serviceStateCode, 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('postal_code',                 acc.ServicePostalCode__c, 'String', 255, FALSE, TRUE))
            ).
            add(new UTIL_Fieldmapper.mappedObject('').
                add(new UTIL_Fieldmapper.mappedField('address_type',                'email', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('purpose',                     'PRIMARY', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('email',                     	acc.Finance_contact__r.Email, 'String', 255, FALSE, TRUE))
            )
        )
    );

    //For Finance_contact__c
    if(acc.Finance_contact__c != null){
        elements.add(generateFinanceCon4Tract(acc.Finance_contact__c));
    }

    return elements;
}

public static List<UTIL_Fieldmapper.mappedElement> getMapper_GhostBillingAccountCreate( Id accId , Id agencyAccId ) {
	
    RemoteResponse res = WSC_Tract.getTractCustomFieldIdByName(accId,'billing-account-custom-fields?name=Company+registration+number'); 
    String comRegNumTractCusFieldId = String.valueOf(res.content);

    Account acc = (Account) UTIL.getCached(accId);
    Account agencyAcc = (Account) UTIL.getCached(agencyAccId);
	
    List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
    List<AccountMemberUnitAssociation__c> amuaList = GW_AccountMemberUnitAssociation.getAll(accId);

    String billingCycleId = !amuaList.isEmpty() ? amuaList[0].MemberUnit__r.BillCycleText__c : '';
    String currencyText = !amuaList.isEmpty() ? amuaList[0].MemberUnit__r.CurrencyText__c : '';
    String billCategory = !amuaList.isEmpty() ? amuaList[0].MemberUnit__r.BillingCategoryText__c : '';
    
    String billingtype = 'monthly';
    MemberUnit__c mu = GW_MemberUnit.getMemberUnitById(acc.Member__c);
    if(acc.SelfService__c == true && ( mu != null && mu.Name.startsWithIgnoreCase('Gumtree ZA'))){
        billingCycleId = amuaList[0].MemberUnit__r.Pre_Paid_Billing_Cycle__c;
        billingtype = 'daily';
    }

    elements.add(new UTIL_Fieldmapper.mappedField('external_account_num',           String.valueOf( agencyAccId + '_' + accId ), 'String', 37, TRUE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedField('object_type',                    'billing-account', 'String', 32, FALSE, FALSE));
    elements.add(new UTIL_Fieldmapper.mappedField('currency_code',                 currencyText, 'String', 50, FALSE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedField('bill_type',                      'PAPER', 'String', 50, FALSE, TRUE));

    //Fill values from Default Member Unit
    if(amuaList != null && !amuaList.isEmpty()){
        elements.add((new UTIL_Fieldmapper.mappedObject('bill_cycle')).
            add(new UTIL_Fieldmapper.mappedField('bill_cycle_type',                     billingtype, 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('id',                                  billingCycleId, 'String', 255, FALSE, TRUE))

        );
        elements.add((new UTIL_Fieldmapper.mappedObject('billing_account_category')).
            add(new UTIL_Fieldmapper.mappedField('object_type',                         'billing-account-category', 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('id',                                  billCategory, 'String', 255, FALSE, TRUE))
        );
    }

    String billingCountryCode = HNDL_Account.getTractCountryCodes(acc.BillingCountryCode,'3');
    elements.add((new UTIL_Fieldmapper.mappedObject('responsible_party')).
        add(new UTIL_Fieldmapper.mappedField('object_type',                         'responsible-party', 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('party_type',                          'organization', 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('organization_name',                   acc.Name + '_' + agencyAcc.Name , 'String', 255, FALSE, TRUE)).
        add((new UTIL_Fieldmapper.mappedList('addresses')).
            add(new UTIL_Fieldmapper.mappedObject('').
                add(new UTIL_Fieldmapper.mappedField('object_type',                 'address', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('address_type',                'postal', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('purpose',                     'BILLING', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('country',                     billingCountryCode, 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('city',                        acc.BillingCity, 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('line1',                       acc.BillingStreet, 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('line2',                       '', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('region_or_state',             acc.BillingStateCode, 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('postal_code',                 acc.BillingPostalCode, 'String', 255, TRUE, TRUE))
            )
        )
    );

    return elements;
}

private static UTIL_Fieldmapper.mappedList generateFinanceCon4Tract(ID conId){
    Contact financeCon = GW_Contact.getRecord(conId);
    UTIL_Fieldmapper.mappedList element_contact = new UTIL_Fieldmapper.mappedList('contacts');
    //temp fix for Tract phone validation
    String phoneNo = financeCon.Phone.startsWith('+') ? financeCon.Phone.replace('+', '00') : financeCon.Phone;
    
    element_contact.add(new UTIL_Fieldmapper.mappedObject('').
        add(new UTIL_Fieldmapper.mappedField('party_type',      'person', 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('suffix',          financeCon.Salutation, 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('title',           financeCon.Title, 'String', 255, FALSE, TRUE)).
        
        add(new UTIL_Fieldmapper.mappedList('addresses').
            add(new UTIL_Fieldmapper.mappedObject('').
                add(new UTIL_Fieldmapper.mappedField('address_type',    'telecom', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('purpose',         'MOBILE', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('number',          phoneNo, 'String', 255, FALSE, TRUE))
            ).
            add(new UTIL_Fieldmapper.mappedObject('').
                add(new UTIL_Fieldmapper.mappedField('address_type',    'email', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('purpose',         'PRIMARY', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('email',           financeCon.Email, 'String', 255, FALSE, TRUE))
            )
            
        ).
            
        add(new UTIL_Fieldmapper.mappedField('first_name',      financeCon.FirstName, 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('last_name',       financeCon.LastName, 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('middle_name',     financeCon.MiddleName__c, 'String', 255, FALSE, TRUE))
            
    );
    return element_contact;
}

private static UTIL_Fieldmapper.mappedList getAccountCustomFieldValues(Account acc, String comRegisterId) {
     UTIL_Fieldmapper.mappedList mapListCusFieldVal = new UTIL_Fieldmapper.mappedList('custom_field_values'); 
     //map custom_field
    UTIL_Fieldmapper.MappedObject mapCusField = new UTIL_Fieldmapper.MappedObject('custom_field');
    mapCusField.add(new UTIL_Fieldmapper.mappedField('custom_field_type', 'billing-account', 'String', 32, FALSE, FALSE));
    mapCusField.add(new UTIL_Fieldmapper.mappedField('name', 'Company registration number' , 'String', 32, FALSE, FALSE));
    mapCusField.add(new UTIL_Fieldmapper.mappedField('id', comRegisterId, 'String', 32, FALSE, FALSE));
    
    //map custom_field_values
    UTIL_Fieldmapper.MappedObject mapCusFieldVal = new UTIL_Fieldmapper.MappedObject('');
    mapCusFieldVal.add(new UTIL_Fieldmapper.mappedField('custom_field_value_type', 'billing-account', 'String', 32, FALSE, FALSE));
    mapCusFieldVal.add(new UTIL_Fieldmapper.mappedField('value',  acc.Company_Reg_No__c , 'String', 32, FALSE, FALSE));
    mapCusFieldVal.add(mapCusField);
    mapListCusFieldVal.add(mapCusFieldVal);
    
    return mapListCusFieldVal;
 }


private static List<UTIL_Fieldmapper.mappedElement> getMapper_BillingAccountUpdate(Id accId) {
    // This method currently contains plenty of placeholders and hardcoded values to make requests work
    Account acc             = (Account) UTIL.getCached(accId);
    List<AccountMemberUnitAssociation__c> amuaList = GW_AccountMemberUnitAssociation.getAll(accId);
    List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();

    elements.add(new UTIL_Fieldmapper.mappedField('object_type',                    'billing-account', 'String', 32, FALSE, FALSE));
    elements.add(new UTIL_Fieldmapper.mappedField('account_num',                    acc.Tract_AccountNumber__c, 'String', 15, TRUE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedField('id',                             acc.Tract_AccountId__c, 'String', 32, FALSE, FALSE));
    elements.add(new UTIL_Fieldmapper.mappedField('external_account_num',           acc.Id, 'String', 18, TRUE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedField('bill_type',                      'NONE', 'String', 50, FALSE, TRUE));
    elements.add( new UTIL_Fieldmapper.mappedField('currency_code',                 amuaList[0].MemberUnit__r.CurrencyText__c, 'String', 50, FALSE, TRUE));
    elements.add(new UTIL_Fieldmapper.mappedField('automatic_recurring_payment',    FALSE, 'BOOLEAN', 18, TRUE, TRUE));
    //Fill values from Default Member Unit
    if(amuaList != null && !amuaList.isEmpty()){
        elements.add((new UTIL_Fieldmapper.mappedObject('bill_cycle')).
            add(new UTIL_Fieldmapper.mappedField('bill_cycle_type',                 'monthly', 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('id',                              amuaList[0].MemberUnit__r.BillCycleText__c, 'String', 255, FALSE, TRUE))

        );
        /*
        elements.add((new UTIL_Fieldmapper.mappedObject('billing_account_category')).
            add(new UTIL_Fieldmapper.mappedField('object_type',                     'billing-account-category', 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('id',                              amuaList[0].MemberUnit__r.BillingCategoryText__c, 'String', 255, FALSE, TRUE))
        );
*/
        elements.add((new UTIL_Fieldmapper.mappedObject('payment_term')).
            add(new UTIL_Fieldmapper.mappedField('object_type',                     'payment-term', 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('id',                              amuaList[0].MemberUnit__r.PaymentTermText__c, 'String', 255, FALSE, TRUE))
        );
    }

    
    String billingCountryCode = HNDL_Account.getTractCountryCodes(acc.BillingCountryCode,'3');
    String serviceCountryCode = HNDL_Account.getTractCountryCodes(acc.ServiceCountry__c,'3');
    String serviceStateCode = HNDL_Account.getTractCountryCodes((HNDL_Account.getTractCountryCodes(acc.ServiceCountry__c,'2') + ':'+ acc.ServiceState__c),'2');
    elements.add((new UTIL_Fieldmapper.mappedObject('responsible_party')).
        add(new UTIL_Fieldmapper.mappedField('object_type',                         'responsible-party', 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('id',                                  acc.Tract_ResponsiblePartyId__c, 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('party_type',                          'organization', 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('organization_name',                   acc.Name, 'String', 255, FALSE, TRUE)).
        add(new UTIL_Fieldmapper.mappedField('tax_id_number',                   acc.Company_VAT_No__c, 'String', 255, FALSE, TRUE)).
        add((new UTIL_Fieldmapper.mappedList('addresses')).
            add(new UTIL_Fieldmapper.mappedObject('').
                add(new UTIL_Fieldmapper.mappedField('object_type',                 'address', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('address_type',                'postal', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('purpose',                     'BILLING', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('country',                     billingCountryCode, 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('city',                        acc.BillingCity, 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('line1',                       acc.BillingStreet, 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('line2',                       '', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('region_or_state',             acc.BillingStateCode, 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('postal_code',                 acc.BillingPostalCode, 'String', 255, TRUE, TRUE))
            ).
            add(new UTIL_Fieldmapper.mappedObject('').
                add(new UTIL_Fieldmapper.mappedField('object_type',                 'address', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('address_type',                'postal', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('purpose',                     'SERVICE', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('country',                     serviceCountryCode, 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('city',                        acc.ServiceCity__c, 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('line1',                       acc.ServiceStreet__c, 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('line2',                       '', 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('region_or_state',             serviceStateCode, 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('postal_code',                 acc.ServicePostalCode__c, 'String', 255, FALSE, TRUE))
            )
        )
    );
    
    //For Finance_contact__c
    if(acc.Finance_contact__c != null){
        elements.add(generateFinanceCon4Tract(acc.Finance_contact__c));
    }
    
    return elements;
}
    
    
    // ================= Requests ==================
    public class RecurringPaymentGet extends GenericRequest {
        Account acc;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('RecurringPaymentGet', APINAME);
            super.init(contextRecordId);
            acc = (Account) this.contextRecord;
            this.mapper.mappingElements = new List<UTIL_Fieldmapper.MappedElement>();
            //this.setHeader('Authorization', 'Basic ' + (WS == null ? '' : WS.key__c) );
            this.setEndpoint((WS == null ? '' :  WS.Endpoint__c) + 'billing-accounts/' + acc.Tract_AccountId__c + '/recurring-payments');
            this.setHttpMethod('GET');
            this.mockMap.putAll(WSC_Tract.getMocks_RetrieveRecurringPaymentMethods());
        }
        public virtual override Boolean readyForCallout() { return acc.Tract_AccountId__c != null; }
    }

    public class RecurringPaymentCreate extends GenericRequest {
        Account acc;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('RecurringPaymentCreate', APINAME);
            super.init(contextRecordId);
            acc = (Account) this.contextRecord;
            
            //this.setHeader('Authorization', 'Basic ' + (WS == null ? '' : WS.key__c) );
            this.setHeader('Content-Type', 'application/json; charset=utf8');
            this.setEndpoint((WS == null ? '' :  WS.Endpoint__c) + 'billing-accounts/' + acc.Tract_AccountId__c + '/recurring-payments');
            this.setHttpMethod('POST');
            //this.mockMap.putAll(WSC_Tract.getMocks_CreateRecurringPaymentMethods());
        }
        public virtual override Boolean readyForCallout() { return acc.Tract_AccountId__c != null; }
    }
	
	public static RemoteResponse getOrderItemIdByOLIId(String oppid, String oliid){
        if(String.isBlank(oppid) || String.isBlank(oliid)){
            return new RemoteResponse(null,1);
        }
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result resp;
        req = UTIL_WSC.getWSC_Request('WSC_Tract.GetTractOrder');
        req.init(oppid); 
        resp = req.call();
        if ( resp.statusCode != 201 && resp.statusCode != 200){
            return new RemoteResponse((String.isBlank(resp.status) ? resp.errorMsg : resp.status), RemoteResponse.STATUSCODE_ERROR);
        }
        
        List<Object> lstResults = (List<Object>)resp.getResponseData().get('results');
        for(Object objOrder: lstResults){
            Map<String,Object> mpOrder = (Map<String,Object>) objOrder;
            List<Object> lstOrderItems = (List<Object>) mpOrder.get('order_items');
            for(Object objOrderItem: lstOrderItems){
                Map<String,Object> mpOrderItems = (Map<String,Object>) objOrderItem;
                List<Object> lstCustomFieldValues = (List<Object>) mpOrderItems.get('custom_field_values');
                for(Object objCustomFieldValue: lstCustomFieldValues){
                    Map<String,Object> mpCustomFieldValue = (Map<String,Object>) objCustomFieldValue;
                    Map<String,Object> mpCustomField = (Map<String,Object>) mpCustomFieldValue.get('custom_field');
                    if((String)mpCustomField.get('name') == CUS_FIELD_SF_LINE_ITEM_ID && 
                       (String)mpCustomFieldValue.get('value') == oliid){
                        RemoteResponse response = new RemoteResponse();
                        response.content = (String)mpOrderItems.get('id');
                        response.statusCode = RemoteResponse.STATUSCODE_OK;
                        return response;
                    }
                }    
            }
        }
     
        RemoteResponse response = new RemoteResponse();
        response.content = null;
        response.statusCode = RemoteResponse.STATUSCODE_OK;
        return response;
    }

    public class GetTractOrder extends GenericRequest{
        Opportunity opp;
        
        public override void init(Id contextRecordId){
            this.setCalloutDetails('GetTractOrder', APINAME);
            super.init(contextRecordId);
            opp = (Opportunity) this.contextRecord;
            this.setHandlerClass(APINAME + '.GetTractOrder_Handler');
            
            String endPoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'orders?order_num=' + opp.Tract_Order_Number__c;
            }
            this.setEndpoint( endpoint );
            this.setHttpMethod('GET');
        }
    }

    public class GetTractOrder_Handler extends ApiHandler{
        public override void handle() { 
            super.handle();
            List<Object> lstResults = (List<Object>)result.getResponseData().get('results');
            if (result.statusCode == UTIL_WSC.HTTP_OK) {                
                
            }
            else {
                UTIL.logClean('Error getting response from server - no response received.');
                //response = new Map<String,Object>();
                //response.put('catalystError', true);
                //response.put('catalystMessage', 'WSC_Tract No response received from service.');
            }
        }
    }

    public class DenyOrderItem extends GenericRequest {
        Opportunity opp;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('DenyOrderItem',APINAME);
            super.init(contextRecordId);
            this.setHandlerClass(APINAME + '.DenyOrderItem_Handler');
            String orderItemId = String.valueOf(this.mAdditionalParams.get('orderItemId'));
            String endpoint = '';
            if( this.baseEndpoint != null ){
                endpoint = this.baseEndpoint + 'order-items/' + orderItemId + '/deny';
            }
            this.setEndpoint( endpoint );
            UTIL.log('Endpoint: ' + endpoint );
            this.setHttpMethod('POST');
        }
    }

    public class DenyOrderItem_Handler extends ApiHandler{
        public override void handle() { 
            super.handle();
            if (result.statusCode == UTIL_WSC.HTTP_OK || result.statusCode == UTIL_WSC.HTTP_CREATED || result.statusCode == UTIL_WSC.HTTP_NOCONTENT) {
                String serviceId = String.valueOf(request.mAdditionalParams.get('serviceId'));
	            if (result.statusCode == UTIL_WSC.HTTP_OK || result.statusCode == UTIL_WSC.HTTP_CREATED || result.statusCode == UTIL_WSC.HTTP_NOCONTENT) {
                    TRACT_Service__c[] lservices = GW_TractService.getRecordByExId(serviceId);
	                if (!lservices.isEmpty() && serviceId != null) {
	                    lservices[0].TractDeactivated__c = true;
	                    UTIL_WSC.doUpdate(lservices[0]);
	                }
	            }
            }
            else {
                UTIL.logClean('Error getting response from server - no response received.');
                Map<String,Object> response = new Map<String,Object>();
                response.put('catalystError', true);
                response.put('catalystMessage', 'WSC_Tract No response received from service.');
            }
        }
    }
    
    // Generic to avoid re-write the same code
    public virtual class GenericRequest extends WSC_Tract.ApiRequest {
        
        public virtual override Boolean readyForCallout() { return true; }
        public virtual override String getBody() {
                Map<String,Object> output = this.mapper.getOutputMap();
                if (output!=null) { return JSON.serialize(output); }
                 return null;
        }
        public virtual override String getFormattedBody() {
                Map<String,Object> output = this.mapper.getOutputMap();
                if (output!=null) { return JSON.serializePretty(output); }
                return null;
        }
        
       public virtual override void createWsLogs() {
            // Don't create logs for RecurringPaymentGet
            if(this instanceof WSC_Tract.RecurringPaymentGet) {
			} else if(this instanceof WSC_Tract.ProductOperation) {
            } else {
                super.createWsLogs();
            }
        }
        
        public virtual override HttpResponse getMockResponse() {
            HttpResponse res = new HttpResponse();
            string resBODY;
            if(this instanceof WSC_Tract.BillingAccountUpdateAddr) {
                resBODY = '{"results" : {"postal_code" : "123 s1","region_or_state" : "Free State","id" : "4304","line1" : "TST_TractSyncAddr","city" : "c1","country" : "ZAF","purpose" : "BILLING","address_type" : "postal"}}';
                res.setStatusCode(201);
            
            } else if(this instanceof WSC_Tract.BillingAccountGetFromContact) {
                resBODY = '{"results":{"responsible_account":{"external_account_num":"001O000001CIzuxIAD","account_num":"922","id":"2257"},"next_invoice_date":"2017-04-01T05:00:00.000+0000","currency_code":"ZAR","tax_exempt":false,"payment_term":{"id":"4","name":"Immediate"},"contacts":[{"last_name":"testL","first_name":"testF","addresses":[{"id":"4560","email":"bhtest@test.com13","purpose":"PRIMARY","address_type":"email"}],"id":"2410","party_type":"person"}],"custom_field_values":[{"custom_field":{"id":"27","name":"Company registration number","custom_field_type":"billing-account"},"id":"14448","custom_field_value_type":"billing-account"}],"start_date":"2017-06-08T06:16:45.000+0000","balance":0,"pending_charges_total":0,"status":"ACTIVE","auto_payment_authorized":false,"billing_account_category":{"payment_term":{"grace_days":0,"term_days":30,"id":"5","name":"Net 30"},"name":"Gumtree ZA (Pty) Ltd","id":"10","status":"ACTIVE","description":"South Africa: Legal Entity: Gumtree ZA (Pty) Ltd;Company Code: 0477;"},"recurring_payments":[],"responsible_party":{"tax_id_validated":false,"organization_name":"bueng_testbilling2","addresses":[{"postal_code":"2222","region_or_state":"Free State","id":"4555","line1":"test10","city":"c1","country":"ZAF","purpose":"BILLING","address_type":"postal"},{"postal_code":"123 s1","region_or_state":"FS","id":"4275","line2":"","line1":"test1","city":"c1","country":"ZAF","purpose":"SERVICE","address_type":"postal"}],"id":"2404","party_type":"organization"},"bill_cycle":{"day_of_month":1,"currency_code":"ZAR","auto_bill":false,"end_date":"2017-07-01T05:00:00.000+0000","start_date":"2017-06-01T05:00:00.000+0000","name":"ZAR Marktplaats BV Monthly","id":"27","status":"ACTIVE","bill_cycle_type":"monthly"},"bill_type":"NONE","external_account_num":"001O000001CIzuxIAD","account_num":"922","id":"2257"}}';
                res.setStatusCode(200);
            } else if(this instanceof WSC_Tract.PeopleUpdateEmail) {
                resBODY = '{"results" : {"id" : "4561","email" : "bunhor@test.com14","purpose" : "PRIMARY","address_type" : "email"}}';
                res.setStatusCode(201);
            } else if(this instanceof WSC_Tract.RecurringPaymentCreate) {
               
                if (UTIL_WSC.testStatusCode == 404)
                    resBODY = '{"message": "failed to create payment method."}';
                else {
                    resBODY = '{"results" : {"id" : "12","payment_method" : {"payment_method_type" : "credit-card", "nickname" : "Credit Card Ending 1111", "id" : "68","custom_field_values" : [ ],"card_type" : "VISA","first_name" : "test","last_name" : "test","identifier_number" : "First 6: 411111 Last 4: 1111", "verification_number" : "234","expiration_date" : "05/2017"},"valid_from" : "2017-04-13T09:03:49.453+0000","auto_payment" : true}}';
                }
                res.setStatusCode(UTIL_WSC.testStatusCode); 
                
            }else if(this instanceof WSC_Tract.RecurringPaymentGet) {
                resBODY = '{"results": [{"auto_payment": "false","valid_from": "2017-04-11T05:14:07.000+0000","payment_method": {"expiration_date": "2017-04-11T05:14:07.000+0000","identifier_number": "1122","last_name": "xxxxx","first_name": "xxxxxx","card_type": "VISA","custom_field_values": [],"id": "58", "nickname": "Credit Card Ending 1111","payment_method_type": "credit-card"},"id": "5"}]}';
                res.setStatusCode(200);
            }else if(this instanceof WSC_Tract.DraftOrderAdSalesCreate) {
                resBODY = '{"due_now_tax_total":0,"due_now_total":0,"tax_total":0,"sub_total":0,"status":"DRAFT","custom_field_values":[],"total_amount":0,"order_date":"2017-07-07T08:27:35.421+0000","email_receipt":true,"purchase_order_number":" ","billing_account":{"responsible_account":{"external_account_num":"001O000001Dc3YWIAZ","account_num":"EKA01054","id":"15676"},"payment_term":{"id":"15","name":"Immediate"},"billing_account_category":{"name":"eBayKleinanzeigen","id":"15"},"responsible_party":{"tax_id_validated":true,"organization_name":"SanityCheckTractdev2","id":"16122","party_type":"organization"},"bill_cycle":{"name":"EUR-Kleinanzeigen","id":"76","bill_cycle_type":"monthly"},"external_account_num":"001O000001Dc3YWIAZ","account_num":"EKA01054","id":"15676"},"order_items":[{"consume_prepaid_balance":false,"addresses":[],"scheduled_one_time_charges":[],"scheduled_recurring_charges":[],"order_item_agreement":{"agreement_period":1,"next_preserve_service_price":false,"preserve_service_price":true,"end_action":"DEACTIVATE_SERVICE","end_date":"2017-08-30T22:00:00.000+0000","agreement":{"adjustment_category":{"id":"101","name":"ADJ-Agreement","charge_category_type":"adjustment"},"id":"36","name":"EUR - 1 Month - Renew Agreement"}},"operation_run_attributes":[{"auto_approve_date":"2017-07-07T08:27:35.393+0000","email_address":null,"id":"331371","operation":{"id":"244","operation_type":"approval"},"operation_run_attribute_type":"product-sale"}],"requested_effective_date":"2017-07-07T08:27:35.421+0000","service_resources":[],"price_list":{"name":"Default Price List","id":"9"},"awaiting_approval":false,"order_item_prices":[{"prorated_on_order_no_charge":false,"prorated_on_cancel":false,"prorated_on_order":false,"category":{"id":"126","status":"ACTIVE","priority":29,"description":"","name":"PRI-K","charge_category_type":"price"},"currency_code":"EUR","order_item_price_ranges":[{"currency_code":"EUR","quantity_begin_range":0,"id":"29413","level":1,"price":0}],"product_price":{"bill_in_advance":false,"prorated_on_order_no_charge":false,"prorated_on_cancel":false,"prorated_on_order":false,"recurrence_period":"MONTH","recurring_payment_required":false,"price_category":{"id":"126","status":"ACTIVE","priority":29,"description":"","name":"PRI-K","charge_category_type":"price"},"currency_code":"EUR","payment_on_purchase_required":false,"price_ranges":[{"currency_code":"EUR","quantity_begin_range":0,"id":"969","level":1,"price":0}],"allow_scheduled_charges":false,"price_override":true,"from_date":"2016-12-31T23:00:00.000+0000","id":"954","price_type":"recurring"},"amount":0,"tapered":false,"price_override":true,"id":"29789","order_item_price_type":"recurring"}],"prorate_on_order_no_charge":false,"prorate_on_cancel":false,"prorate_on_order":false,"extended_price":0,"status":"DRAFT","order_items":[],"id":"29098","product":{"product_category":{"id":"20","status":"ACTIVE","name":"1016X"},"id":"495","name":"Media Sales - 640x480_Desktop_CPM"},"sequence":1,"quantity":1,"order_item_type":"product"}],"order_num":"243150612","id":"19860","referral":"SanityCheckTractdev2","note":"Order Note","order_type":"sales"}';
                res.setStatusCode(201);
            }else if(this instanceof WSC_Tract.RecurringPaymentGet) {
                resBODY = '{"results": [{"auto_payment": "false","valid_from": "2017-04-11T05:14:07.000+0000","payment_method": {"expiration_date": "2017-04-11T05:14:07.000+0000","identifier_number": "1122","last_name": "xxxxx","first_name": "xxxxxx","card_type": "VISA","custom_field_values": [],"id": "58", "nickname": "Credit Card Ending 1111","payment_method_type": "credit-card"},"id": "5"}]}';
                res.setStatusCode(200);
            } else if (this instanceof WSC_Tract.FetchPDFInvoiceFromTract) {
                
                if (UTIL_WSC.testStatusCode == 404) resBODY = '{"message":"error"}';
                else resBODY = '{"message":"ok"}';
                res.setStatusCode(UTIL_WSC.testStatusCode);
            } else if (this instanceof WSC_Tract.InvoiceResend) {
                resBODY = '';
                res.setStatusCode(204); // 204 is success
            } else if(this instanceof WSC_Tract.GetTractServiceCusFieldId) {
                resBODY = '[{"custom_field_type":"service","name":"Product Line ID","enabled":true,"searchable":true,"id":"72","field_type":"TEXT_FIELD","field_validation_type":"TEXT","actions":[]},{"custom_field_type":"service","name":"SF Opportunity ID","enabled":true,"searchable":true,"id":"73","field_type":"TEXT_FIELD","field_validation_type":"TEXT","actions":[]},{"custom_field_type":"service","name":"SF Opportunity Line Item","enabled":true,"searchable":true,"id":"107","field_type":"TEXT_FIELD","field_validation_type":"TEXT","actions":[]},{"custom_field_type":"service","name":"Campaign Value_dis","enabled":false,"searchable":false,"id":"109","field_type":"TEXT_FIELD","field_validation_type":"TEXT","actions":[]}]';
                res.setStatusCode(200);
            } else if(this instanceof WSC_Tract.GetAgreements) {
                resBODY = '[{"name":"EUR - 1 Month - Renew Agreement","id":"36","agreement_period":1,"status":"ACTIVE","termination_flat_charge":0,"prorate_on_cancel":false,"adjustment_category":{"charge_category_type":"adjustment","name":"ADJ-Agreement","priority":4,"status":"ACTIVE","id":"101"},"end_action":"RENEW_AGREEMENT","termination_fee_currency_code":"EUR","valid_from":"2017-06-16","agreement_period_type":"MONTH","true_up_charge_types":[],"preserve_service_price":true},{"name":"EUR - 1 Month - Deactivate Service","id":"37","agreement_period":1,"status":"ACTIVE","termination_flat_charge":0,"prorate_on_cancel":false,"adjustment_category":{"charge_category_type":"adjustment","name":"ADJ-Agreement","priority":4,"status":"ACTIVE","id":"101"},"end_action":"DEACTIVATE_SERVICE","termination_fee_currency_code":"EUR","valid_from":"2017-06-16","agreement_period_type":"MONTH","true_up_charge_types":[],"preserve_service_price":false}]';
                res.setStatusCode(200);
            } else if(this instanceof WSC_Tract.DeactivateServiceTract) {
                resBODY = '{"accumulated_charges_amount":0,"next_preserve_service_price":false,"preserve_service_price":true,"next_service_pay_on_purchase":false,"end_action":"DEACTIVATE_SERVICE","end_date":"2017-07-18T05:00:00.000+0000","start_date":"2017-07-04T05:00:00.000+0000","id":"22976","renewed":false,"agreement":{"adjustment_category":{"id":"101","name":"ADJ-Agreement","charge_category_type":"adjustment"},"id":"36","name":"EUR - 1 Month - Renew Agreement"}}';
                res.setStatusCode(201);
            }
            
            res.setBody(resBODY);
            if(resBODY != null) return res; 
            
            return null;
        }
        
    }
    
    
    // ================= Mappers ==================
    
    public static List<UTIL_Fieldmapper.mappedElement> getMapper_RecurringPaymentCreate(Map<String, String> mapper) {
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();

        if (mapper.get('payment_method_type') == 'sepa-dd-em') {
			String iban = mapper.get('iban') != null ? mapper.get('iban').replaceAll('[^a-zA-Z0-9]', '') : '';
			if(String.isNotEmpty(iban)) iban = iban.left(2).toUpperCase()+ iban.right(iban.length() -2);
            elements.add(new UTIL_Fieldmapper.mappedField('auto_payment', mapper.get('auto_payment'), 'Boolean', 32, FALSE, FALSE));
            elements.add((new UTIL_Fieldmapper.mappedObject('payment_method')).
                add(new UTIL_Fieldmapper.mappedField('payment_method_type', mapper.get('payment_method_type'), 'String', 20, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('iban', iban, 'String', 32, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('mandate_id', mapper.get('mandate_id'), 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('mandate_signature_date', mapper.get('mandate_signature_date'), 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('owner_name', mapper.get('owner_name'), 'String', 255, TRUE, TRUE))
            );
        } else {
            elements.add(new UTIL_Fieldmapper.mappedField('object_type', 'recurring-payment', 'String', 32, FALSE, FALSE));
            elements.add(new UTIL_Fieldmapper.mappedField('auto_payment', mapper.get('auto_payment'), 'Boolean', 32, FALSE, FALSE));
            elements.add((new UTIL_Fieldmapper.mappedObject('payment_method')).
                add(new UTIL_Fieldmapper.mappedField('card_type',           mapper.get('card_type'), 'String', 20, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('custom_field_values', new String[0], 'String[]', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('expiration_date',     mapper.get('expiration_date'), 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('first_name',          mapper.get('first_name'), 'String', 255, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('identifier_number',   mapper.get('identifier_number'), 'String', 32, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('last_name',           mapper.get('last_name'), 'String', 255, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('payment_method_type', mapper.get('payment_method_type'), 'String', 20, FALSE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('verification_number', mapper.get('verification_number'), 'String', 4, TRUE, TRUE)).
                add(new UTIL_Fieldmapper.mappedField('currency',            mapper.get('currency'), 'String', 4, TRUE, TRUE))
            );
        }
        return elements;
    }
    
    // ====================== MOCKS ======================
    
    private static Map<String, UTIL_WSC.WSC_Mock> getMocks_RetrieveRecurringPaymentMethods() {
        Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();
        mocks.put(UTIL_WSC.TESTMOCK, new UTIL_WSC.WSC_Mock('OK', 200, 
                                                                        '{' +
                                                                            '"results" : [ {' +
                                                                                            '"auto_payment" : false,' +
                                                                                            '"valid_from" : "2017-04-11T05:14:07.000+0000",' +
                                                                                            '"payment_method" : {' +
                                                                                            '"expiration_date" : "12/2020",' +
                                                                                            '"identifier_number" : "First 6: 411111 Last 4: 1111",' +
                                                                                            '"last_name" : "TestBUNHOR",' +
                                                                                            '"first_name" : "TestENG",' +
                                                                                            '"card_type" : "VISA",' +
                                                                                            '"custom_field_values" : [ ],' +
                                                                                            '"id" : "58",' +
                                                                                            '"nickname" : "Credit Card Ending 1111",' +
                                                                                            '"payment_method_type" : "credit-card"' +
                                                                                            '},' +
                                                                                            '"id" : "5"' +
                                                                                        '} ]' +
                                                                        '}' 
                                                                    ));
        return mocks;
    }
    
    private static Map<String, UTIL_WSC.WSC_Mock> getMocks_CreateRecurringPaymentMethods() {
        Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();
        mocks.put(UTIL_WSC.TESTMOCK, new UTIL_WSC.WSC_Mock('OK', 201,
                                                                    '{'+
                                                                      '"id" : "12",'+
                                                                      '"payment_method" : {'+
                                                                        '"payment_method_type" : "credit-card",'+
                                                                        '"nickname" : "Credit Card Ending 1111",'+
                                                                        '"id" : "68",'+
                                                                        '"custom_field_values" : [ ],'+
                                                                        '"card_type" : "VISA",'+
                                                                        '"first_name" : "test",'+
                                                                        '"last_name" : "test",'+
                                                                        '"identifier_number" : "First 6: 411111 Last 4: 1111",'+
                                                                        '"verification_number" : "234",'+
                                                                        '"expiration_date" : "05/2017"'+
                                                                      '},'+
                                                                      '"valid_from" : "2017-04-13T09:03:49.453+0000",'+
                                                                      '"auto_payment" : true'+
                                                                    '}'
                                                                    ));
        return mocks;
    }
    
        private static Map<String, UTIL_WSC.WSC_Mock> getMocks_TractProducts() {
        Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();
        mocks.put(UTIL_WSC.TESTMOCK, new UTIL_WSC.WSC_Mock('OK', 201,
                                                                    '[ {'+
                                                                      '"name" : "Goods - Category Gallery 31 Day",'+
                                                                      '"description" : "Category Gallery 31 Day",'+
                                                                      '"sku" : "zagoods-cg31",'+
                                                                      '"serialized" : false,'+
                                                                      '"taxable" : true,'+
                                                                      '"trial" : false,'+
                                                                      '"id" : "280",'+
                                                                      '"short_description" : "1 Category Gallery 31 Day Feature",'+
                                                                      '"product_type" : "addon",'+
                                                                      '"state" : "AVAILABLE",'+
                                                                      '"requires_agreement" : false,'+
                                                                      '"default_quantity" : 1.00000,'+
                                                                      '"prices" : [ {'+
                                                                        '"price_type" : "recurring",'+
                                                                        '"id" : "356",'+
                                                                        '"from_date" : "2017-01-01T06:00:00.000+0000",'+
                                                                        '"price_override" : true,'+
                                                                        '"allow_scheduled_charges" : false,'+
                                                                        '"price_ranges" : [ {'+
                                                                          '"price" : 964.04,'+
                                                                          '"level" : 1,'+
                                                                          '"id" : "361",'+
                                                                          '"quantity_begin_range" : 0.00,'+
                                                                          '"currency_code" : "ZAR"'+
                                                                        '} ],'+
                                                                        '"payment_on_purchase_required" : false,'+
                                                                        '"currency_code" : "ZAR",'+
                                                                        '"price_category" : {'+
                                                                         '"charge_category_type" : "price",'+
                                                                          '"name" : "PRI-Marktplaats",'+
                                                                          '"priority" : 46,'+
                                                                          '"status" : "ACTIVE",'+
                                                                          '"id" : "78"'+
                                                                        '},'+
                                                                        '"recurring_payment_required" : false,'+
                                                                        '"recurrence_period" : "MONTH",'+
                                                                        '"prorated_on_order" : false,'+
                                                                        '"prorated_on_cancel" : false,'+
                                                                        '"prorated_on_order_no_charge" : false,'+
                                                                        '"bill_in_advance" : true'+
                                                                      '} ],'+
                                                                      '"product_category" : {'+
                                                                       '"name" : "322",'+
                                                                        '"description" : "Goods and Services",'+
                                                                        '"status" : "ACTIVE",'+
                                                                        '"id" : "16"'+
                                                                      '},'+
                                                                      '"min_service_resources" : 0,'+
                                                                      '"max_service_resources" : 10,'+
                                                                      '"service_resource_category" : {'+
                                                                        '"id" : "19",'+
                                                                        '"name" : "GOODS-ZA",'+
                                                                        '"resource_type" : "service",'+
                                                                        '"status" : "ACTIVE",'+
                                                                        '"allow_multiple_services" : false'+
                                                                      '},'+
                                                                      '"trial_override" : false,'+
                                                                      '"product_tags" : [ {'+
                                                                        '"name" : "Goods",'+
                                                                        '"priority" : 24,'+
                                                                        '"id" : "20"'+
                                                                      '} ],'+
                                                                      '"introduction_date" : "2017-01-01T06:00:00.000+0000",'+
                                                                      '"rule_override" : true,'+
                                                                      '"rule_type" : "TAPERED",'+
                                                                      '"rule_mode" : "APPEND",'+
                                                                      '"consume_prepaid_balance" : false'+
                                                                    '}]'
                                                                    ));
        return mocks;
    }
    
    private static Map<String, UTIL_WSC.WSC_Mock> getMocks_TaxRatesTable() {
        Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();
        mocks.put(UTIL_WSC.TESTMOCK, new UTIL_WSC.WSC_Mock('OK', 200, '[ { "id": 1, "country": "MATCH_ALL", "region": "MATCH_ALL", "city": "MATCH_ALL", "zip": "MATCH_ALL", "valid_from": "2016-01-01T05:00:00Z", "type": "Federal", "name": "VAT", "description": "Value Added Tax", "code": "1", "rate": 0.14, "entity_type": "MATCH_ALL", "location_code": "0057 – Gumtree.co.za", "company_code": "0057", "custom01": "A1", "custom02": "225001" }, { "id": 2, "country": "MATCH_ALL", "region": "MATCH_ALL", "city": "MATCH_ALL", "zip": "MATCH_ALL", "valid_from": "2016-01-01T05:00:00Z", "type": "Federal", "name": "VAT", "description": "Value Added Tax", "code": "1", "rate": 0.14, "entity_type": "MATCH_ALL", "location_code": " 0477 – Gumtree.co.za", "company_code": "0057", "custom01": "A1", "custom02": "225001" }, { "id": 3, "country": "DE", "region": "MATCH_ALL", "city": "MATCH_ALL", "zip": "MATCH_ALL", "valid_from": "2016-01-01T05:00:00Z", "type": "Federal", "name": "MwSt", "description": "Mehrwertsteuer", "code": "1", "rate": 0.19, "entity_type": "BUSINESS", "location_code": "0451 - eBay-kleinanzeigen.de", "company_code": "0451", "custom01": "A0", "custom02": "225555" } ]'));
        return mocks;
    }
}