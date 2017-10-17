global with sharing class RAC_ProductConfigurator {

    public RAC_ProductConfigurator(ApexPages.StandardController stdController) {}
    
    @RemoteAction
    public static List<OpportunityLineItem> getOpportunityLineItems(Id oppId) {
        List<OpportunityLineItem> olis = GW_OpportunityLineItem.getListFromRelated(oppId);
        return olis;
    }
    
    @RemoteAction
    public static List<PricebookEntry> getProducts(Id pricebookId) {
        return
        [   SELECT  Id,  Name,  Product2Id,  UnitPrice,  IsActive,  ProductCode, 
            Product2.Name, Product2.Description, Product2.Billing_Category__c, Product2.CPM_Price__c,
            Product2.CPD_Price__c, Product2.CPC_Price__c
            FROM PricebookEntry
            WHERE IsActive=true AND Pricebook2Id=:pricebookId
            LIMIT 10000
        ];

    }

    @RemoteAction
    public static Map<Id,PricebookEntry> getUsedProducts(Id oppId) {
    	List<OpportunityLineItem> olis = [Select Id, PricebookEntryId From OpportunityLineItem WHere OpportunityId =:oppId];
    	Set<Id> pbeIds = new Set<Id>();
    	for (OpportunityLineItem oli : olis) pbeIds.add(oli.PricebookEntryId);
        return new Map<Id,PricebookEntry>(
        [   SELECT  Id,  Name,  Product2Id,  UnitPrice,  IsActive,  ProductCode, 
            Product2.Name, Product2.Description, Product2.Billing_Category__c, Product2.CPM_Price__c,
            Product2.CPD_Price__c, Product2.CPC_Price__c
            FROM PricebookEntry
            WHERE Id IN :pbeIds LIMIT 1000
        ]);

    }

}