public with sharing class GW_PriceBookEntry {

    private static final Schema.sObjectType GW_BASEOBJECT = PriceBookEntry.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'PriceBookEntry';
    
    private static Map<String,PricebookEntry> pbeMap = new Map<String,PricebookEntry>(); // map <"<product2Id_Pricebook2Id>", PricebookEntry>
    
    public static PriceBookEntry getPbeFromCache(Id productId, Id pricebookId) {
        PriceBookEntry pbe;
        String pbeKey = productId + '_' + pricebookId;
        if (pbeMap.containsKey(pbeKey)) pbe = pbeMap.get(pbeKey);
        else {
        	pbe = (PricebookEntry) GW_sObject.queryRecords('PricebookEntry', 'Product2Id =\'' + productId + '\' AND Pricebook2Id =\'' + pricebookId + '\'') [0];    
            pbeMap.put(pbeKey,pbe);
        }
		return pbe;
    }

    public static void putPbesInCache(List<PricebookEntry> pbes) {
        for (PricebookEntry pbe : pbes) {
            String pbeKey = pbe.Product2Id + '_' + pbe.Pricebook2Id;
            pbeMap.put(pbeKey,pbe);
        }
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods 
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static PriceBookEntry           getRecord(Id id)           { return (PriceBookEntry) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,PriceBookEntry>   getMap(Set<id> ids)        { return new Map<id,PriceBookEntry>( getList(ids) ); }
    public static List<PriceBookEntry>     getList(Set<id> ids)       { return (List<PriceBookEntry>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }
	public static List<PriceBookEntry>	   getList(Set<Id> Ids, List<String> additionalFields) 	{ return (List<PriceBookEntry>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, Ids, additionalFields);}
//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of parents(base object) from a list of child objects
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // OpportunityLineItem
    public static Map<id,PriceBookEntry>  	getMapFromRelated(List<OpportunityLineItem> lst)    { return getMap(getIdSetFromRelated(lst)); }
    public static Set<Id>          			getIdSetFromRelated(List<OpportunityLineItem> lst)  { return GW_sObject.getParentIds(lst, 'PriceBookEntryId'); }

    // Pricebook parent
    public static List<PriceBookEntry>   getListFromRelated(Id parentId)        { return (List<PriceBookEntry>) GW_sObject.getChildren(parentId, 'PricebookEntries'); }
    public static List<PriceBookEntry>   getListFromRelated(Set<Id> parentIds)  { return (List<PriceBookEntry>) GW_sObject.getChildren(parentIds, 'PricebookEntries'); }
    public static Set<Id>             	 getIdSetFromRelated(Set<Id> parentIds) { return GW_sObject.getChildIds(parentIds, 'PricebookEntries'); } 

}