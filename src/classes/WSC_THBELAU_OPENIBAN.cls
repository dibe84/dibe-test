public class WSC_THBELAU_OPENIBAN {
    
    public static Webservice_Settings__c WS 	= Webservice_Settings__c.getInstance('THBELAU_OPENIBAN_PROD');
	public static final String ENDPOINT = (!Test.IsRunningTest())?(WS.UseProxy__c?WS.EndpointProxy__c:WS.Endpoint__c) :'testendpoint';
    
    public OpenIBANResponse BankAccountDetailsGet(String IBAN){
        
        IBAN = (IBAN == null) ? '' : EncodingUtil.urlEncode(IBAN, 'UTF-8');
        
        UTIL_WSC.basicCallout co = new UTIL_WSC.basicCallout('THBELAU_OPENIBAN'+ENDPOINT+IBAN, ENDPOINT+IBAN+'?getBIC=true', 'GET');
        
        co.reqType = UTIL_WSC.reqType.URLENCODED;
        co.mockResponseBody = getSuccesMock();
        
        HttpResponse resp = co.call();
        
        UTIL.log('OPENIBAN Call->'+ENDPOINT+IBAN);
        return parseResponse(resp);
        
    }
    
    private OpenIBANResponse parseResponse(HttpResponse resp){
        
        OpenIBANResponse response = new OpenIBANResponse();
        
        response.statusCode = resp.getStatusCode();
        response.rawBody = resp.getBody();
            
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.rawBody);
        
        response.isValid = (boolean) body.get('valid');
        
        response.messages = new List<String>(); 
        
        List<Object> messageObjects = (List<Object>) body.get('messages');
        for (Object o : messageObjects){
            response.messages.add((String) o);
        }
            

        response.IBAN = (String) body.get('iban');
        
        Map<String,Object> bank = (Map<String,Object>) body.get('bankData');
        
       	
        response.bankName = (String) bank.get('name');
        response.bankCity = (String) bank.get('city');
        response.BIC = (String) bank.get('bic');
        
        return response;
    }
    
    private static String getSuccesMock() {
        return '{ "valid": true, "messages": [], "iban": "NL67ABNA0628492812", "bankData": { "bankCode": "ABNA", "name": "ABN AMRO BANK N.V", "bic": "ABNANL2A" }, "checkResults": {} }';
    }
    
    public class OpenIBANResponse {
        public Integer statusCode;
        
        public boolean isValid;
        public List<String> messages;
        
        public String IBAN;
        public String bankName;
        public String bankCity;
        public String BIC;
        
        public String rawBody;
        
    }
}