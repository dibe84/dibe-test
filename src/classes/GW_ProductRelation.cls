/**
 * Created by rvannierop on 2/27/2017.
 */

public class GW_ProductRelation {

    private static final Schema.sObjectType GW_BASEOBJECT = ProductRelation__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'ProductRelation__c';

//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static ProductRelation__c           getRecord(Id id)           { return (ProductRelation__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,ProductRelation__c>   getMap(Set<id> ids)        { return new Map<id,ProductRelation__c>( getList(ids) ); }
    public static List<ProductRelation__c>     getList(Set<id> ids)       { return (List<ProductRelation__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of childs(base object) from a list of parent objects
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // Opportunity/Rev__c/Invoice parents
    public static List<ProductRelation__c>   getListFromRelated(Id parentId)        { return (List<ProductRelation__c>) GW_sObject.getChildren(parentId, 'ProductRelations__r'); }
    public static List<ProductRelation__c>   getListFromRelated(Set<Id> parentIds)  { return (List<ProductRelation__c>) GW_sObject.getChildren(parentIds, 'ProductRelations__r'); }
    public static Set<Id>       getIdSetFromRelated(Set<Id> parentIds) { return GW_sObject.getChildIds(parentIds, 'ProductRelations__r'); }

///////////////////////////////////////////////////////////////////////////////////////////////////////
// Object Specific logic
///////////////////////////////////////////////////////////////////////////////////////////////////////


}