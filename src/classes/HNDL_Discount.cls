/**
 * Created by rvannierop on 2/28/2017.
 */

public class HNDL_Discount extends TriggerManager.TriggerHandler {

    List<WS_ScheduledCallout__c> wsscToUpsert = new List<WS_ScheduledCallout__c>();
    private List<Discount__c> discountsToCheckForRelationsSync = new List<Discount__c>();

    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {

    }

    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {

    }

    public override void beforeInsert(SObject so) {
        Discount__c discount = (Discount__c)so;
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        Discount__c discount = (Discount__c) so;
        Discount__c oldDiscount = (Discount__c) oldSo;
    }

    public override void beforeDelete(SObject so) {}

    public override void afterInsert(SObject so) {
        Discount__c discount = (Discount__c) so;
        if (discount.Tract_NeedsCodeSync__c) {
            discountsToCheckForRelationsSync.add(discount);
        }
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        Discount__c discount = (Discount__c) so;
        Discount__c oldDiscount = (Discount__c) oldSo;
        UTIL.log('AFTER UPDATE');
        if (discount.Tract_NeedsCodeSync__c) {
            UTIL.log('TRACT NEEDS CODE SYNC');
            discountsToCheckForRelationsSync.add(discount);
        }
    }

    public override void afterDelete(SObject so) {}

    public override void andFinally() {
        if (discountsToCheckForRelationsSync.size() > 0) {
            UTIL_WSC.forceProcessing('WSC_Tract.DiscountCodesSync', discountsToCheckForRelationsSync, wsscToUpsert);
        }
        UTIL.log('SIZE WSSCTOUPSERT: ' + wsscToUpsert.size());
        if (wsscToUpsert.size()>0){
            try{
                upsert wsscToUpsert UniqueKey__c;
            }
            catch(Exception ex){
                UTIL.throwError('HNDL_Discount - Error inserting WS_ScheduledCallouts',ex);
            }
        }
    }

    // Constructor
    public HNDL_Discount() { super('HNDL_Discount', Discount__c.sObjectType); }
}