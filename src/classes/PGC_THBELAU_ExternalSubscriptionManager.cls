public class PGC_THBELAU_ExternalSubscriptionManager {
    
    public Account acc {get;set;}
    
    private final WSC_THBELAU_Subscription WS;

    public PGC_THBELAU_ExternalSubscriptionManager(){
        Id accId = (Id) ApexPages.currentPage().getParameters().get('id');
        this.acc = (Account) GW_sObject.queryRecord('Account', accId);
        WS = new WSC_THBELAU_Subscription(acc.ExternalSubscriptionId__c);
    }
    
    public PageReference activateSubscription(){

        return modifyExternalSubscriptionStatusHandler('PUT');
        
    }
    
    public PageReference deactivateSubscription(){
        
        return modifyExternalSubscriptionStatusHandler('DELETE');
    }
    
    private PageReference modifyExternalSubscriptionStatusHandler(String Method){
               
        if(acc.Member_Id__c == 'THBEL'){
            return THBEL_modifyExternalSubscriptionStatus(Method);
        }
        
        if(acc.Member_Id__c != 'THBEL'){
            return Default_modifyExternalSubscriptionStatus(Method);
        }

        return cancel(); 
    }
    
    private PageReference Default_modifyExternalSubscriptionStatus(String method){
        
            if ( method == 'DELETE'){
                acc.ExternalSubscriptionStatus__c = 'Inactive';
            }
            else if ( method == 'PUT' ){
                acc.ExternalSubscriptionStatus__c = 'Active';
            }
            else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error: Unknown Method '));
                return null;
            }
            
            update acc;
            return (new ApexPages.StandardController(acc)).view();         
    }
    
    private PageReference THBEL_modifyExternalSubscriptionStatus(String method){
        
        try{
            
            WS.call(method);
        
            if ( (WS.statusCode == 200 && WS.status == 'deleted') || ( WS.statusCode == 404 && 'DELETE'.equals(method) ) ){
                acc.ExternalSubscriptionStatus__c = 'Inactive';
            }
            else if (WS.statusCode == 201 && WS.status == 'created' ){
                acc.ExternalSubscriptionStatus__c = 'Active';
            }
            else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error: ('+WS.statusCode+') '+WS.rawBody));
                return null;
            }
            
            update acc;
            return (new ApexPages.StandardController(acc)).view(); 
            
        }
        catch (UTIL.CustomException e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please fill in a ExternalSubscriptionId first!'));
            return null;
        }
        
    }
    
    public PageReference cancel(){
        return (new ApexPages.StandardController(acc)).view();
    }
    
    
}