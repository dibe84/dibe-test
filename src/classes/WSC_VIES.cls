public class WSC_VIES {
	private static final String APINAME = 'WSC_VIES';
	private static final String ENDPOINT = 'http://ec.europa.eu/taxation_customs/vies/services/checkVatService';
	public static Webservice_Settings__c WS = Webservice_Settings__c.getInstance('WSC_VIES'+ '_' + (UTIL.isSandbox() ? 'UAT' : 'PROD'));

	public class Query extends ApiRequest {
		Account acc;
		public override void init(Id contextRecordId) {
			this.setCalloutDetails('Query',APINAME);
			super.init(contextRecordId);
			acc = (Account) this.contextRecord;
			this.mapper.mappingElements = getMapper_Query(contextRecordId);
			this.setResultClass(APINAME+'.ApiResult');
			this.setHandlerClass(APINAME+'.Query_Handler');
			this.mockMap.putAll(getMocks_Query());
			this.setEndpoint(WS == null ? ENDPOINT : WS.Endpoint__c);
			this.setHttpMethod('POST');
		}
		public virtual override Boolean readyForCallout() {
			return true;
		} // override with entry criteria in specific implementation, when these apply
		public override String getBody() 			{
			Map<String,Object> output = this.mapper.getOutputMap();
			String body = null;
			if (output != null) {
				body = '<s11:Envelope xmlns:s11=\'http://schemas.xmlsoap.org/soap/envelope/\'><s11:Body><tns1:checkVat xmlns:tns1=\'urn:ec.europa.eu:taxud:vies:services:checkVat:types\'><tns1:countryCode>{!countryCode}</tns1:countryCode><tns1:vatNumber>{!vatNumber}</tns1:vatNumber></tns1:checkVat></s11:Body></s11:Envelope>';
				body = body.replace('{!countryCode}', (String) output.get('countryCode'));
				body = body.replace('{!vatNumber}', (String) output.get('vatNumber'));
			}
			return body;
		}
		public override String getFormattedBody() 	{
			return this.getBody();
		}
	}

	// Generic request object for all outgoing API calls
	public virtual class ApiRequest extends UTIL_WSC.WSC_Request {
		public virtual override void init(Id contextRecordId) {
			super.init(contextRecordId);
			this.setHeader('Accept','text/xml');
			this.setHeader('Content-Type', 'text/xml');
			this.setHeader('Accept-Charset','utf-8');
			this.setHeader('Date', Datetime.now().formatGMT('EEE, d MMM yyyy HH:mm:ss z'));
			this.getWsSettings(APINAME, null);
		}
	}

	// Generic Result object for all responses to outgoing API calls
	public class ApiResult extends UTIL_WSC.WSC_Result {
		public override Map<String,Object> getResponseData() {
			if (resp != null && !String.isBlank(resp.getBody())) {
				Map<String,Object> result = new Map<String,Object>();
				try {
					DOM.Document dom = new DOM.Document();
					dom.load(resp.getBody());
					DOM.XMLNode rootElement = dom.getRootElement();
					DOM.XMLNode responseElement = rootElement.getChildElement('Body','http://schemas.xmlsoap.org/soap/envelope/').getChildElement('checkVatResponse', 'urn:ec.europa.eu:taxud:vies:services:checkVat:types');
					for (DOM.XMLNode node : responseElement.getChildElements()) {
					    result.put(node.getName(), node.getText());
					}
				} catch (Exception e) {
					result.put('error', true);
					result.put('errorMessage', e.getMessage());
				}
				return result;
			} else {
				return null;
			}
		}
		public override String getFormattedBody() {
			if (resp != null && !String.isBlank(resp.getBody())) {
				return resp.getBody();
			} else {
				return '';
			}
		}
	}

//////////////////////////////////////////////////////////////////////
// Implementation of handler, mapper and mocks - per API method
//////////////////////////////////////////////////////////////////////

	public class Query_Handler extends UTIL_WSC.WSC_ResultHandler {
		public override void handle() {
			super.handle();
			Map<String,Object> response = this.result.getResponseData();
			UTIL.logClean('Response: ' + response);
			if (this.result.statusCode == UTIL_WSC.HTTP_OK && response != null && response.containsKey('valid') == TRUE) {
				Account acc = GW_Account.getRecord(this.request.contextRecord.Id);
				UTIL.logClean('Acc: ' + acc);
				if (acc != null) {
					try {
						acc.VATValidationAddress__c = (String) response.get('address');
						acc.VATValidationCountryCode__c = (String) response.get('countryCode');
						acc.VATValidationName__c = (String) response.get('name');
						acc.VATValidationRequestDate__c = DateTime.now();
						acc.VATValidationStatus__c = ((String) response.get('valid') == 'true') ? 'Valid' : 'Invalid';
						acc.VATValidationVATNumber__c = (String) response.get('vatNumber');
						acc.VATValidationSource__c = 'VIES';
						acc.VAT_Check_Result__c = ((String) response.get('valid') == 'true') ? 1 : 0;
						acc.VAT_Check_Status__c = ((String) response.get('valid') == 'true') ? 'Valid' : 'Invalid';
						
						if( GW_Account.isVATApplicationMandatory( acc ) ){
							acc.Apply_VAT__c = true;
						} else{
						    acc.Apply_VAT__c = ( acc.VAT_Check_Result__c <> 1 );	
						}
						
					} catch (Exception e) {
						UTIL.logClean('Error parsing: ' + e.getMessage() + e.getStackTraceString());
					}
					UTIL.logClean('Updating account: ' + acc);
					UTIL_WSC.doUpdate(acc);
				}
			} else if(this.result.statusCode == UTIL_WSC.HTTP_OK && response.containsKey('valid') == FALSE) {
				UTIL.logClean('Unknown VIES error');
				response = new Map<String,Object>();
				response.put('error', true);
				response.put('errorMessage', 'Unknown VIES error');
				this.result.retryCallout = TRUE;
			}
			else {
				UTIL.logClean('Error getting response from server - no response received.');
				response = new Map<String,Object>();
				response.put('error', true);
				response.put('errorMessage', 'No response received from service.');
				this.result.retryCallout = TRUE;
			}
		}
	}

	// Field mappers
	private static List<UTIL_Fieldmapper.mappedElement> getMapper_Query(Id accId) {
		Account acc 			= (Account) UTIL.getCached(accId);
		String countryCode = (acc.Company_VAT_No__c == null ? null : acc.Company_VAT_No__c.substring(0,2));
		String vatNumber = (acc.Company_VAT_No__c == null ? null : acc.Company_VAT_No__c.substring(2));

		List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
		elements.add( new UTIL_Fieldmapper.mappedField('countryCode', countryCode, 'String', 3, TRUE, TRUE) );
		elements.add( new UTIL_Fieldmapper.mappedField('vatNumber', vatNumber, 'String', 30, TRUE, TRUE) );

		return elements;
	}
	// Mocks
	private static Map<String, UTIL_WSC.WSC_Mock> getMocks_Query() {
		Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();
		mocks.put('callValid',new UTIL_WSC.WSC_Mock('OK',200,'<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><checkVatResponse xmlns="urn:ec.europa.eu:taxud:vies:services:checkVat:types"><countryCode>NL</countryCode><vatNumber>048273430B01</vatNumber><requestDate>2016-05-12+02:00</requestDate><valid>true</valid><name>FARO SOLUTIONS</name><address> LOUIS ARMSTRONGBOULEVARD 000123543ES UTRECHT</address></checkVatResponse></soap:Body></soap:Envelope>'));
		mocks.put('callTimeoutException',null);
		return mocks;
	}
}