public with sharing class GW_Metric {

    private static final Schema.sObjectType GW_BASEOBJECT = Metric__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'Metric__c'; 

    // caching
    //public static Map<id,Metric__c> recordCache = new Map<id,Metric__c>();

////////////////////////////////////////////////////////////////////////////////////////////////////// 
// public query methods 
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Metric__c           getRecord(Id id)           { return (Metric__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,Metric__c>   getMap(Set<id> ids)        { return new Map<id,Metric__c>( getList(ids) ); }
    public static List<Metric__c>     getList(Set<id> ids)       { return (List<Metric__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }

    public static void syncMetricsFromRSs(List<RS__c> rss) {
        
        Id batchId = database.executeBatch(new BAT_SyncMetricsFromRS( GW_sObject.getIdSet(rss) ), 50); // scope is set at 
    	UTIL.log('Running batch job for Metric Synchronization. Id: '+batchId);
    }

    public static List<Metric__c> createAllMetricsFromRS(RS__c rs) {
    	List<Metric__c> nwMetrics = new List<Metric__c>();
    	Date startDate = rs.from_Date__c;
        Date endDate = rs.until_Date__c;
        List<Date> metricDates = new List<Date>();

        for (Integer d = 0; d <= startDate.daysBetween(endDate); d++) {
            metricDates.add( startDate.addDays(d) );
        }

        for (Date metricDate : metricDates) {
            nwMetrics.add( createMetricFromRS(rs, metricDate) );
        }
        return nwMetrics;
    }

    public static Metric__c createMetricFromRS(RS__c rs, Date metricDate) {
        Metric__c m = new Metric__c();
        m.RS__c = rs.Id;
        m.Opportunity__c = rs.Opportunity__c;
        m.MetricDate__c = metricDate;
        m.UniqueKey__c = ((Datetime) metricDate).format('yyyyMMdd') + '_' + rs.Rev__c;
        GW_Metric.setExternalUID(rs, m);

        m.CurrencyIsoCode = rs.CurrencyIsoCode;
        return m;
    }

    public static void setExternalUID(RS__c parent, Metric__c metric) {
        if (metric.MetricDate__c != null &&  parent !=null && parent.MasterIdForm__c != null)
            metric.ExternalUID__c = ((Datetime) metric.MetricDate__c).format('yyyyMMdd') + '_' + parent.MasterIdForm__c;
    }

    public static List<Metric__c> getExistingMetrics(List<RS__c> rss) {
        return [Select id, UniqueKey__c, ExternalUID__c From Metric__c Where RS__c IN :rss];
    }

    public static List<Metric__c> calculateRevenueDelivered(Set<Id> rsIdSet) {
        if(rsIdSet == null || rsIdSet.size() == 0) {
            return new List<Metric__c>();
        }
        List<Metric__c> metricList = (List<Metric__c>) GW_sObject.queryRecords('Metric__c','RS__c',UTIL.getIdSetAsStringSet(rsIdSet));
        return calculateRevenueDelivered(metricList);
    }

    public static List<Metric__c> calculateRevenueDelivered(List<Metric__c> metricList) {
        if(metricList == null || metricList.size() == 0) {
            return new List<Metric__c>();
        }
        Set<Id> rsIdSet = new Set<Id>();
        for(Metric__c met : metricList) {
            rsIdSet.add(met.RS__c);
        }

        Map<Id, RS__c> rsMap = new Map<Id,RS__c> ((List<RS__c>) UTIL.getCachedMap(rsIdSet).values());
        Map<Id,List<Metric__c>> rsToMetricMap = new Map<Id,List<Metric__c>>();
        for(Metric__c met : metricList) {
            Object res = rsToMetricMap.containsKey(met.RS__c) == TRUE ? rsToMetricMap.get(met.RS__c).add(met) : rsToMetricMap.put(met.RS__c,new List<Metric__c>{met});
        }

        return calculateRevDeliveredForCategories(rsToMetricMap,rsMap);
    }

    private static List<Metric__c> calculateRevDeliveredForCategories(Map<Id,List<Metric__c>> rsToMetricMap, Map<Id,RS__c> rsMap) {
        if(rsToMetricMap == null || rsMap == null || rsToMetricMap.size() == 0 || rsMap.size() == 0) {
            return new List<Metric__c>();
        }

        for(Id rsId : rsToMetricMap.keySet()) {
            List<Metric__c> metList = rsToMetricMap.get(rsId);
            RS__c rss = rsMap.get(rsId);
            if(rss.BillingCategoryCalculation__c == 'CPM_DailyFixed' || rss.BillingCategoryCalculation__c == 'CPM_Delivery') {
                calcRevenueDeliveredCPM(rss,metList);
            }
            if(rss.BillingCategoryCalculation__c == 'CPD_DailyFixed' || rss.BillingCategoryCalculation__c == 'CPD_Delivery') {
                calcRevenueDeliveredCPD(rss,metList);
            }
            if(rss.BillingCategoryCalculation__c == 'CPC_Delivery') {
                calcRevenueDeliveredCPC(rss,metList);
            }
            if(rss.BillingCategoryCalculation__c.contains('Subscription') || rss.BillingCategoryCalculation__c.contains('ServiceFee')) {
                calcRevenueDeliveredSubscription(rss,metList);
            }
        }

        List<Metric__c> allMetricList = new List<Metric__c>();
        for(List<Metric__c> metList : rsToMetricMap.values()) {
            allMetricList.addAll(metList);
        }

        return allMetricList;
    }

    private static void calcRevenueDeliveredSubscription(RS__c rss, List<Metric__c> metricList) {
        if(rss.BillingCategoryCalculation__c == null || rss.BillingCategoryCalculation__c.length() == 0) {
            return;
        }
        for(Metric__c met : metricList) {
            if(rss.Revenue__c > 0 && rss.TotalDays__c > 0) {
                met.RevenueDelivered__c = rss.Revenue__c / rss.TotalDays__c;
            } else {
                met.RevenueDelivered__c = 0;
            }
        }
    }

    private static void calcRevenueDeliveredCPC(RS__c rss, List<Metric__c> metricList) {
        if(rss.BillingCategoryCalculation__c == null || rss.BillingCategoryCalculation__c.length() == 0) {
            return;
        }
        for(Metric__c met : metricList) {
            if(met.AD_Clicks__c > 0 && rss.QuantityDelivered__c > 0 && rss.Revenue__c > 0) {
                met.RevenueDelivered__c = (met.AD_Clicks__c / rss.QuantityDelivered__c) * rss.Revenue__c;
            } else {
                met.RevenueDelivered__c = 0;
            }
        }
    }

    private static void calcRevenueDeliveredCPM(RS__c rss, List<Metric__c> metricList) {
        if(rss.BillingCategoryCalculation__c == null || rss.BillingCategoryCalculation__c.length() == 0) {
            return;
        }
        for(Metric__c met : metricList) {
            if(met.AD_Impressions__c > 0 && rss.QuantityDelivered__c > 0 && rss.Revenue__c > 0) {
                met.RevenueDelivered__c = (met.AD_Impressions__c / rss.QuantityDelivered__c) * rss.Revenue__c;
            } else {
                met.RevenueDelivered__c = 0;
            }
        }
    }

    private static void calcRevenueDeliveredCPD(RS__c rss, List<Metric__c> metricList) {
        if(rss.BillingCategoryCalculation__c == null || rss.BillingCategoryCalculation__c.length() == 0) {
            return;
        }
        for(Metric__c met : metricList) {
            if(met.AD_Impressions__c > 0 && rss.TotalDays__c > 0) {
                met.RevenueDelivered__c = rss.Revenue__c / rss.TotalDays__c;
            } else {
                met.RevenueDelivered__c = 0;
            }
        }
    }
}