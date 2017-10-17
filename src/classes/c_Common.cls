global class c_Common {
    /* Subscription */
    public class Subscription {
        public String name { get; set; }
        public Id productId { get; set; }
        public Boolean isActive { get; set; }
        public Date startDate { get; set; }
        public Date endDate { get; set; }
    }
    
    public static List<Subscription> getSubscriptionsByContact(Id contactId) {
        List<Subscription> subscriptions = new List<Subscription>();
        Contact c = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId];
        List<Opportunity> allOpportunities = [SELECT Id FROM Opportunity WHERE AccountId = :c.AccountId AND StageName IN('Scheduled','Running')];
        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity o : allOpportunities) {
            opportunityIds.add(o.Id);
        }
        
        List<Rev__c> subscriptionsRevenueItems = [SELECT Id, Status__c, SubscriptionEndDate__c, From_Date__c, Until_Date__c, TerminationDate__c,TerminationReason__c, UnitPrice__c, Type__c, Product__c, IsActive__c, CommittedPeriodInMonths__c, CommittedEndDate__c, ContractPeriodInMonths__c, Product__r.Name FROM Rev__c WHERE Opportunity__c IN :opportunityIds];
        
        for (Rev__c r : subscriptionsRevenueItems) {
            if (r.Status__c == 'Running' || r.Status__c == 'Scheduled') {
                Subscription s = new Subscription();
                s.Name = r.Product__r.Name;
                s.startDate = r.From_Date__c;
                s.endDate = r.Until_Date__c;
                s.productId = r.Product__c;
                s.isActive = true;
                subscriptions.add(s);        
            }
        }
        
        return subscriptions;
    }
    
    public static CommunityConfiguration__c getConfig() {
        if (Test.isRunningTest()) {
            List<Site> lstCommunitySite = [SELECT Id, Name FROM Site WHERE SiteType = 'ChatterNetwork' AND Name = 'eBay_kleinanzeigen'];
            return !lstCommunitySite.isEmpty() ? CommunityConfiguration__c.getInstance(lstCommunitySite[0].Name) : null;
        } else {
            String cleanUrl = URL.getSalesforceBaseUrl().toExternalForm().remove('https://').remove('http://');
            //Domain is now conflicting to ECGDK CS, we need to add PathPrefix filter
            List<Site> sitesByDomain = [SELECT Id, MasterLabel, Name FROM Site WHERE Id IN (SELECT SiteId FROM DomainSite WHERE Domain.Domain = :cleanUrl AND PathPrefix = '/s')];
            if (sitesByDomain.size() == 0) {
                return null;
            }
            Site communitySite = [SELECT Id, Name FROM Site WHERE MasterLabel = :sitesByDomain.get(0).MasterLabel AND SiteType = 'ChatterNetwork'];
            return CommunityConfiguration__c.getInstance(communitySite.Name);
        }
    }
    
    /* Responseobject */
    global class ResponseObject {
        public Boolean success { get; set; }
        public List<String> errorMessages { get; set; }
        public Map<String,String> errorFieldMap { get; set; }
        public Map<String,String> responseMap { get; set; }
        public String stackTrace { get; set; }
    }
    
    public Interface IOrderProcessor {
        ResponseObject validate(String inputJson, Id portalOrderId);
        ResponseObject save(String inputJson, Id portalOrderId);
        ResponseObject process(Id portalOrderId, List<Attachment> attachments);
        ResponseObject submitCase(String inputJson);
    }
    
    public static IOrderProcessor instantiateOrderProcessor(String name) {
        return (IOrderProcessor) (Type.forName(name)).newInstance();   
    }
    
    public static Map<String,String> parseFieldErrorDetails(Exception e, Map<String,String> errorFieldMap) {
        Map<String,String> result = new Map<String,String>();
        if (e.getTypeName() == 'System.DmlException') {
            Integer numFailures = e.getNumDml();
            for (Integer i = 0; i < numFailures; i++) {
                List<String> fieldNames = e.getDmlFieldNames(i);
                for (String s: fieldNames) {
                    result.put(errorFieldMap.get(s),e.getDmlStatusCode(i));
                }
            }
        }
        return result;
    }
}