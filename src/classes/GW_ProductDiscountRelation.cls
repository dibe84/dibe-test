/**
 * Created by rvannierop on 3/30/2017.
 */

public with sharing class GW_ProductDiscountRelation {

    private static final Schema.sObjectType GW_BASEOBJECT = ProductDiscountRelation__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'ProductDiscountRelation__c';

//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static ProductDiscountRelation__c           getRecord(Id id)           { return (ProductDiscountRelation__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,ProductDiscountRelation__c>   getMap(Set<id> ids)        { return new Map<id,ProductDiscountRelation__c>( getList(ids) ); }
    public static List<ProductDiscountRelation__c>     getList(Set<id> ids)       { return (List<ProductDiscountRelation__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of childs(base object) from a list of parent objects
//////////////////////////////////////////////////////////////////////////////////////////////////////

    public static List<ProductDiscountRelation__c> getListFromRelated(Id parentId)        {
        return (List<ProductDiscountRelation__c>) GW_sObject.getChildren(parentId, 'ProductDiscountRelations__r');
    }

    public static List<ProductDiscountRelation__c> getListFromRelated(Set<Id> parentIds)  {
        return (List<ProductDiscountRelation__c>) GW_sObject.getChildren(parentIds, 'ProductDiscountRelations__r');
    }

    public static Set<Id> getIdSetFromRelated(Set<Id> parentIds) {
        return GW_sObject.getChildIds(parentIds, 'ProductDiscountRelations__r');
    }

}