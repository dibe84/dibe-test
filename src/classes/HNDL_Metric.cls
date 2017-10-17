public with sharing class HNDL_Metric extends TriggerManager.TriggerHandler {

    Map<Id, RS__c> relatedRSMap = new Map<Id,RS__c>();
    List<Metric__c> metricsForDailyAmountUpdate = new List<Metric__c>();

    public static boolean skipRevenueScheduleUpdate = false;

    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        cacheRSs(soLst, oldMap, newMap);
    }

    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        if (!HNDL_Metric.skipRevenueScheduleUpdate){
            cacheRSs(soLst, oldMap, newMap);
        }
    }

    private void cacheRSs(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        Set<Id> rssIdSet = new Set<Id>();
        for(sObject so : soLst) {
            rssIdSet.add(((Metric__c)so).RS__c);
        }
        relatedRSMap = GW_RS.getMap(rssIdSet);
        Set<Id> revIdSet = new Set<Id>();
        for(RS__c rs : relatedRSMap.values()) {
            revIdSet.add(rs.Rev__c);
        }
        UTIL.cache(GW_RS.getListFromRelated(revIdSet));
        UTIL.cache(relatedRSMap);
    }

    public override void beforeInsert(SObject so) {
        Metric__c met = (Metric__c)so;
        checkExternalUID(met);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        Metric__c met = (Metric__c)so;
        Metric__c oldmet = (Metric__c)oldSo;
        if (met.ExternalUID__c == null) checkExternalUID(met);
        UTIL_RecordRestriction.checkFieldLocks(so, oldSo);
    }

    public override void beforeDelete(SObject so) {
        UTIL_RecordRestriction.checkDeletionLock(so);
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        Metric__c met = (Metric__c)so;
        Metric__c oldmet = (Metric__c)oldSo;
    }

    public override void andFinally() {
        // when metrics are updated, recalc revenue
        if (hndlEvent == TriggerManager.triggerEventType.AfterUpdate && relatedRSMap.size() > 0 && !HNDL_Metric.skipRevenueScheduleUpdate) {
            HNDL_Metric.skipRevenueScheduleUpdate = true;
            Set<RS__c> uniqueParents = new Set<RS__c>(relatedRSMap.values());
            GW_RS.populateRsMetricsMap(uniqueParents);
            GW_RS.recalcRevenueValues(uniqueParents);
        }
    }

    // private helper methods
    private void checkExternalUID(Metric__c metric) {
        RS__c parent = relatedRSMap.get(metric.RS__c);
        GW_Metric.setExternalUID(parent, metric);
    }

    // Constructor
    public HNDL_Metric() { super('HNDL_Metric', Metric__c.sObjectType); }
}