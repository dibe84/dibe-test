public class WSC_THBELAU_Subscription {
    
    public static Webservice_Settings__c WS 	= Webservice_Settings__c.getInstance(UTIL.isSandbox()?'THBELAU_SUBSCRIPTION_UAT':'THBELAU_SUBSCRIPTION_PROD');
	private final String ENDPOINT; 
    //Key should already be generated for basic authentication BASE64(BLOB(username:password)
    private static final String WSKEYSTRING  = (!Test.IsRunningTest())?WS.Key__c:'testkey';
    
    private String userId;
    public Integer statusCode {get;set;}
    public String status {get;set;}
    public String error {get;set;}
    public String rawBody {get;set;}
    
    public WSC_THBELAU_Subscription(String userId){
        this.userId = userId;
        ENDPOINT = (!Test.IsRunningTest())?(WS.UseProxy__c?WS.EndpointProxy__c:WS.Endpoint__c)+userId+'/cars/':'testendpoint';
    }
    
    public void call(String method){
        if (!String.isEmpty(userId)){
            UTIL_WSC.basicCallout co = new UTIL_WSC.basicCallout('THBELAU_ActivateSubscription', ENDPOINT, method);
            co.setBasicAuthentication(WSKEYSTRING);
            HttpResponse resp = co.call();
            
            statusCode = resp.getStatusCode();
            rawBody = resp.getBody();
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(rawBody);
            status = (String) body.get('status');
            error = (String) body.get('error');
        }
        else {
            UTIL.throwError('THBELAU Subscription: No userId supplied to service.');
        }
    }

}