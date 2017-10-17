/**
 * Created by rvannierop on 2/27/2017.
 */

public class HNDL_Product extends TriggerManager.TriggerHandler {

    List<WS_ScheduledCallout__c> wsscToUpsert = new List<WS_ScheduledCallout__c>();
    private List<Product2> productsToCheckForRelationsSync = new List<Product2>();
    private List<Product2> productsToCheckForDiscountRelationsSync = new List<Product2>();

    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {

    }

    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {

    }

    public override void beforeInsert(SObject so) {
        Product2 product = (Product2)so;
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        Product2 product = (Product2) so;
        Product2 oldProduct = (Product2) oldSo;
    }

    public override void beforeDelete(SObject so) {}

    public override void afterInsert(SObject so) {
        Product2 product = (Product2) so;
        if (product.Tract_NeedsRelationsSync__c) {
            productsToCheckForRelationsSync.add(product);
        }
        if (product.Tract_NeedsDiscountRelationsSync__c) {
            productsToCheckForDiscountRelationsSync.add(product);
        }
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        Product2 product = (Product2) so;
        Product2 oldProduct = (Product2) oldSo;
        if (product.Tract_NeedsRelationsSync__c) {
            productsToCheckForRelationsSync.add(product);
        }
        if (product.Tract_NeedsDiscountRelationsSync__c) {
            productsToCheckForDiscountRelationsSync.add(product);
        }
    }
    public override void afterDelete(SObject so) {}

    public override void andFinally() {
        if (productsToCheckForRelationsSync.size() > 0) {
            UTIL_WSC.forceProcessing('WSC_Tract.ProductRelationsSync', productsToCheckForRelationsSync, wsscToUpsert);
        }
        if (productsToCheckForDiscountRelationsSync.size() > 0) {
            UTIL_WSC.forceProcessing('WSC_Tract.ProductDiscountRelationsSync', productsToCheckForDiscountRelationsSync, wsscToUpsert);
        }
        if (wsscToUpsert.size()>0){
            try{
                upsert wsscToUpsert UniqueKey__c;
            }
            catch(Exception ex){
                UTIL.throwError('HNDL_Product - Error inserting WS_ScheduledCallouts',ex);
            }
        }
    }

    // Constructor
    public HNDL_Product() { super('HNDL_Product', Product2.sObjectType); }
}