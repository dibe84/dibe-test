virtual global without sharing class c_BaseOrderController extends c_BaseController implements c_Common.IOrderProcessor {
    // Variables
    public Map<PortalProductGrouping__c, List<PortalProduct__c>> availablePortalProductGroupings { get; set; }
    public Map<Id,PortalProductPrice> portalProductToPrice { get; set; }
    public List<c_Common.Subscription> currentSubscriptions { get; set; }
    public PortalProduct__c activeSubscriptionProduct { get; set; }
    public String portalProductMap { get {
        Map<Id, PortalProduct__c> result = new Map<Id, PortalProduct__c>();
        for (List<PortalProduct__c> products : this.availablePortalProductGroupings.values()) {
            for (PortalProduct__c product : products) {
                result.put(product.Id, product);
            }
        }
        return JSON.serialize(result);        
    } }    
    public String pricingMap { get {
        return JSON.serialize(this.portalProductToPrice );        
    } }   
     
    public String currencyMapJSON { get {        
        return JSON.serialize(currencyMap);
    } }
    
    public Map<String,String> currencyMap { get {
        return new Map<String,String>{'EUR' => '€', 'USD' => '$'};
    } }
    
    public Boolean hasActiveOrder { get; set; }
    public Boolean activeOrderIsPortalOrder { get; set; }
    
    public class PortalProductPrice {
        public Id portalProductId { get; set; }
        private PortalProduct__c portalProduct { get; set; }
        public PriceBookEntry pbe { get; set; }
        public String currencyCode { get; set; }
        public Decimal listPrice { get {
            return this.pbe.Fixed_PricePerMonth__c;
        } set; }
        public Decimal salesPriceNet { get {
            return PriceCalculator.calculateSalesPriceNet(this.listPrice, pbe.DefaultAdjustmentFixed__c, pbe.DefaultAdjustmentPercentage__c);
        } set; }
        public Boolean isDiscounted { get {
            return this.listPrice != this.salesPriceNet;
        } set; }
        
        public PortalProductPrice(Id portalProductId, PriceBookEntry pbe) {
            this.portalProduct = (PortalProduct__c) UTIL.getCached(portalProductId);
            this.pbe = pbe;
            if (this.pbe == null) {
                this.pbe = [SELECT Id, Fixed_PricePerMonth__c, UnitPrice, DefaultAdjustmentFixed__c, DefaultAdjustmentPercentage__c, CurrencyIsoCode FROM PricebookEntry WHERE Pricebook2Id = :this.portalProduct.PriceBook__c AND Product2id = :this.portalProduct.Product__c LIMIT 1];
            }
            this.currencyCode = this.pbe.CurrencyIsoCode;
        }
    }
        
    // Constructor    
    public c_BaseOrderController () {
        super();
        if (!this.isValidLogin) { 
        	UTIL.throwError('You are currently logged in as user which is not valid for this portal.');
        }
        this.availablePortalProductGroupings = this.fillAvailablePortalProductGroupings();
        this.portalProductToPrice = this.fillPortalProductToPrice();
        this.hasActiveOrder = this.fillHasActiveOrder();
        this.currentSubscriptions = c_Common.getSubscriptionsByContact(currentContact.Id);
        this.activeSubscriptionProduct = this.fillActiveSubscriptionProduct();
    }
    
    // Public RemoteActions
    @RemoteAction
    global static c_Common.ResponseObject save(String inputJson, Id portalOrderId) {
        try {            
            c_Common.IOrderProcessor processor = c_Common.instantiateOrderProcessor(c_Common.getConfig().OrderProcessor__c);
            return processor.save(inputJson, null);
        } catch (Exception e) {
            return handleException(e);
        }
    }
    
    @RemoteAction
    global static c_Common.ResponseObject process(Id portalOrderId, List<Attachment> attachments) {
       return null;
    }
    
    @RemoteAction
    global static c_Common.ResponseObject validate(String inputJson, Id portalOrderId) {
        try {
            c_Common.IOrderProcessor processor = c_Common.instantiateOrderProcessor(c_Common.getConfig().OrderProcessor__c);
            return processor.validate(inputJson, null);
        } catch (Exception e) {
            return handleException(e);
        }
    }
    
    @RemoteAction
    global static c_Common.ResponseObject submitCase(String inputJson) {
        try {
            c_Common.IOrderProcessor processor = c_Common.instantiateOrderProcessor(c_Common.getConfig().OrderProcessor__c);
            return processor.submitCase(inputJson);
        } catch (Exception e) {
            return handleException(e);
        }
    }
    
    private static c_Common.ResponseObject handleException(Exception e) {
        c_Common.ResponseObject response = new c_Common.ResponseObject();
        response.success = false;
        response.errorMessages = new List<String>{e.getMessage()};
        response.stackTrace = e.getStacktraceString();
        response.errorFieldMap = new Map<String,String>();
        return response;
    }
    
    private static Map<String,String> parseErrorDetails(Exception e, Map<String,String> errorFieldMap) {
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
    
    // Private methods
    private Map<PortalProductGrouping__c, List<PortalProduct__c>> fillAvailablePortalProductGroupings()  {
        Map<PortalProductGrouping__c, List<PortalProduct__c>> result = new Map<PortalProductGrouping__c, List<PortalProduct__c>>();
        
        // Retrieve products
        String whereClause = 'PortalName__c = \'' + config.Name + '\'';
        List<PortalProductGrouping__c> groupings = (List<PortalProductGrouping__c>) GW_sObject.queryRecords('PortalProductGrouping__c', whereClause);
        Map<Id, List<PortalProduct__c>> children = (Map<Id, List<PortalProduct__c>>) GW_sObject.getChildrenMap(GW_sObject.getIdSet(groupings), 'PortalProducts__r', new Set<String>{'Product__r.Billing_Category__c'}, 'SortOrder__c ASC'); // @TODO: update GW_sObject
        for (PortalProductGrouping__c grouping : groupings) {
            result.put(grouping, children.get(grouping.Id));
        }
        
        return result;
    }
    
    private Map<Id,PortalProductPrice> fillPortalProductToPrice() {
        Map<Id,PortalProductPrice> result = new Map<Id,PortalProductPrice>();
        
        // Determine prices
        Set<Id> productIds = new Set<Id>();
        for (List<PortalProduct__c> products : this.availablePortalProductGroupings.values()) {
            for (PortalProduct__c product : products) {
                productIds.add(product.Product__c);
            }
        }
        
        List<PricebookEntry> pricebookEntries = [SELECT Id, CurrencyIsoCode, Product2Id, UnitPrice, Pricebook2Id, Fixed_PricePerMonth__c, DefaultAdjustmentFixed__c, DefaultAdjustmentPercentage__c FROM PricebookEntry WHERE Product2Id IN :productIds];
        
        Map<Id,Map<Id,PricebookEntry>> pricebookEntryMap = new Map<Id,Map<Id,PricebookEntry>>(); // Pricebook2Id To Map<Product2Id,PricebookEntry>
        for (PricebookEntry pbe : pricebookEntries) {
            Map<Id,PricebookEntry> m = pricebookEntryMap.get(pbe.Pricebook2Id);
            if (m == null) {
                m = new Map<Id,PricebookEntry>();
            }
            m.put(pbe.Product2Id, pbe);
            pricebookEntryMap.put(pbe.Pricebook2Id,m);
        }
        
        for (List<PortalProduct__c> products : this.availablePortalProductGroupings.values()) {
            for (PortalProduct__c product : products) {
                result.put(product.Id, new PortalProductPrice(product.Id, pricebookEntryMap.get(product.Pricebook__c).get(product.Product__c)));
            }
        }
        
        return result;
    }    
        
    private Boolean fillHasActiveOrder() {
        List<PortalOrder__c> activeOrders = (List<PortalOrder__c>) GW_sObject.queryRecords('PortalOrder__c', 'Contact__c = \'' + currentContact.Id + '\' AND (Status__c IN (\'In progress\', \'Ready to process\') OR OpportunityRunning__c = false)');
        List<Case> pendingOrderCases = (List<Case>) GW_sObject.queryRecords('Case', 'AccountId = \'' + currentAccount.Id + '\' AND ClosedDate = null AND Origin = \''+config.CaseOrigin__c + '\'');
        //UTIL.throwError('Cases: ' + pendingOrderCases);
        if (activeOrders.size() > 0 || pendingOrderCases.size() > 0) {
            if (pendingOrderCases.size() > 0) {
                this.activeOrderIsPortalOrder = false;
            } else {
                this.activeOrderIsPortalOrder = true;
            }
            return true;
        } else {
            return false;
        }
    }
    
    private PortalProduct__c fillActiveSubscriptionProduct() {
        for (c_Common.Subscription sub : currentSubscriptions) {
            if (sub.isActive) {
                List<PortalProduct__c> portalproducts = (List<PortalProduct__c>) GW_sObject.queryRecords('PortalProduct__c', 'Product__c = \'' + sub.productId + '\' AND PortalProductGrouping__r.PortalName__c = \'' + this.config.Name + '\'');
                if (portalProducts.size() > 0) {
                    return portalProducts.get(0);
                }
            }
        }
        return null;
    }
}