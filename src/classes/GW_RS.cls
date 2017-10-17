public with sharing class GW_RS {

    private static final Schema.sObjectType GW_BASEOBJECT = RS__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'RS__c';

    public static Map<Id,Map<Id,Metric__c>> rsMetrics = new Map<Id,Map<Id,Metric__c>>(); // RS__c.Id => Map of child metrics

//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods 
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static RS__c           getRecord(Id id)           { return (RS__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,RS__c>   getMap(Set<id> ids)        { return new Map<id,RS__c>( getList(ids) ); }
    public static List<RS__c>     getList(Set<id> ids)       { return (List<RS__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of parents(base object) from a list of child objects
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // Metric
    public static Map<id,RS__c>     getMapFromRelated(List<Metric__c> lst)     { return getMap(getIdSetFromRelated(lst)); }
    public static Set<Id>           getIdSetFromRelated(List<Metric__c> lst)   { return GW_sObject.getParentIds(lst, 'RS__c'); }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of childs(base object) from a list of parent objects
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // Opportunity/Rev__c/Invoice parents
    public static List<RS__c>   getListFromRelated(Id parentId)        { return (List<RS__c>) GW_sObject.getChildren(parentId, 'Revenue_Schedules__r'); }
    public static List<RS__c>   getListFromRelated(Set<Id> parentIds)  { return (List<RS__c>) GW_sObject.getChildren(parentIds, 'Revenue_Schedules__r'); }
    public static Set<Id>       getIdSetFromRelated(Set<Id> parentIds) { return GW_sObject.getChildIds(parentIds, 'Revenue_Schedules__r'); }

///////////////////////////////////////////////////////////////////////////////////////////////////////
// Object Specific logic
///////////////////////////////////////////////////////////////////////////////////////////////////////

    public static void recalcRevenueValues(Set<RS__c> rssSet) {
        List<RS__c> rss = new List<RS__c>(rssSet);
        UTIL.cacheUncachedRecords(GW_sObject.getParentIds(rss, 'Rev__c')); // cache Rev__c objects for use in RevenueCalculator
        //UTIL.cache( GW_Revenue.getMapFromRelated(rss) );
        for (RS__c rs : rss) {
            recalcRevenueValues(rs);
        }

        try {
            upsert rss UniqueKey__c;
        } catch(Exception ex) {
            UTIL.throwError('Error in GW_RS.recalcRevenueValues',ex);
        }
    }

    public static void recalcRevenueValues(List<RS__c> rssList) {
		recalcRevenueValues(new Set<RS__c>(rssList));
    }

    public static void recalcRevenueValues(RS__c rs) {
        if (rs.NumStatus__c < 7) {
           RevenueCalculator.IRevenueCalculator revCalc = RevenueCalculator.getCalculator(rs);
           rs.QuantityDelivered__c = revCalc.calcQuantityDelivered();
           rs.QuantityBilled__c = revCalc.calcQuantityBilled();
           rs.Revenue__c = revCalc.calcRevenue();
           rs.QuantityOverdelivered__c = revCalc.calcQuantityOverdelivered();
           rs.RevenueOverdelivered__c = revCalc.calcRevenueOverdelivered();
        }
    }



    public static List<RS__c> syncRSFromRevs(List<Rev__c> revs) {
       return syncRSFromRevs(revs, new Set<Id>());
    }

    public static List<RS__c> syncRSFromRevs(List<Rev__c> revs, Set<Id> revIdsDoNotInvoiceChanged) {
        if (revIdsDoNotInvoiceChanged == null) throw new UTIL.CustomException('revIdsDoNotInvoiceChanged cannot be null.');
        Map<String, RS__c> rsToUpsert = new Map<String, RS__c>();
        List<RS__c> rsToDelete = new List<RS__c>();
        Set<Id> invoicesToSyncFromDeletedRs = new Set<id>();

        for (Rev__c rev : revs) {
            //Create all RS records as if they can all be recreated
            Boolean propagateDoNotInvoice = revIdsDoNotInvoiceChanged.contains(rev.Id);
            for (RS__c rs : createAllRSFromRev(rev, propagateDoNotInvoice)) {
                rsToUpsert.put(rs.UniqueKey__c,rs);
            }
        }
        
        // if existing Revs are not in upsert list they must be deleted
        for (RS__c rs : getExistingRS(revs) ) {
            if ( !rsToUpsert.containsKey(rs.UniqueKey__c)) {
               if (!rs.IsInvoiced__c) rsToDelete.add(rs);
            } else if (rs.IsInvoiced__c) {
            	rsToUpsert.remove(rs.UniqueKey__c);
            }
        }
        
        // first delete...
        if (rsToDelete.size()>0 ) {
            try {
                delete rsToDelete;
            } catch(Exception ex) {
                UTIL.throwError('Error deleting RSs',ex);
            }  
        }
        
        if (rsToUpsert.values().size()>0 ) {
            try {
                upsert rsToUpsert.values() UniqueKey__c;
            } catch(Exception ex) {
                UTIL.throwError('Error upserting RSs',ex);
            }
            
            try {
                GW_RS.populateRsMetricsMap(rsToUpsert.values() );
                GW_RS.recalcRevenueValues(rsToUpsert.values() );
            } catch(Exception ex) {
                UTIL.throwError('Error Recalculating RSs',ex);
            }       
             
        }
        return rsToUpsert.values();
    }

    private static List<RS__c> createAllRSFromRev(Rev__c rev, Boolean propagateDoNotInvoice) {
        List<RS__c> nwRS = new List<RS__c>();

        for (Date startOfPeriod : GW_Revenue.getMonthStartDates(rev) ) {
            Date endOfPeriod = startOfPeriod.addMonths(1) -1;
            Date startDate = startOfPeriod<rev.From_Date__c ? rev.From_Date__c : startOfPeriod;
            Date endDate = endOfPeriod<rev.Until_Date__c ? endOfPeriod : rev.Until_Date__c;
            nwRS.add( createRSFromRev(rev, startDate, endDate, startOfPeriod, endOfPeriod, propagateDoNotInvoice) );
        }
        
        return nwRS;
    }

    private static RS__c createRSFromRev(Rev__c rev, Date startDate,Date endDate, Date startOfPeriod, Date endOfPeriod, Boolean propagateDoNotInvoice) {
        RS__c rs = new RS__c();
        rs.Rev__c = rev.Id;
        rs.Opportunity__c = rev.Opportunity__c;
        rs.From_Date__c = startDate;
        rs.Until_Date__c = endDate;
        rs.StartOfPeriod__c = startOfPeriod;
        rs.EndOfPeriod__c = endOfPeriod;
        rs.UniqueKey__c = ((Datetime) startOfPeriod).format('yyyyMMdd') + '_' + rev.Id; // changed from using Oli.id => Rev.id, due to multiple Rev items per product...
        rs.CurrencyIsoCode = rev.CurrencyIsoCode;
        if (propagateDoNotInvoice) {
            rs.DoNotInvoice__c = rev.DoNotInvoice__c;
            rs.DoNotInvoiceReason__c = rev.DoNotInvoiceReason__c;
        }
        return rs;
    }

    public static List<Date> getMonthStartDates(Rev__c rev) {
        Date startMonth = rev.from_Date__c.toStartOfMonth();
        Date endMonth = rev.until_Date__c.toStartOfMonth();
        List<Date> monthStartDates = new List<Date>(); 
        
        for (Integer m = 0; m <= startMonth.monthsBetween(endMonth); m++) { 
            monthStartDates.add(startMonth.addMonths(m));
        }

        return monthStartDates;
    }

    public static List<RS__c> getExistingRS(List<Rev__c> revs) {
        return GW_RS.getListFromRelated(GW_sObject.getIdSet(revs));
    }

    public static void populateRsMetricsMap(Set<RS__c> rss) {
        Set<Id> rsIds = new Set<Id>();
        
        for (RS__c rs : rss) {
            if (!rsMetrics.containsKey(rs.Id) ) rsMetrics.put(rs.Id, new Map<Id,Metric__c>() );
            rsIds.add(rs.Id);
        }
        List<Metric__c> metrics = GW_sObject.getChildren(rsIds, 'Metrics__r');
        for (Metric__c met : metrics) {
            rsMetrics.get(met.RS__c).put(met.Id,met);
        }
    }
    
    public static void populateRsMetricsMap(List<RS__c> rss) {
        populateRsMetricsMap(new Set<RS__c>(rss));
    }
    
    // used to cache objects for Invoice creation
    public static void cacheRelatedRecords(List<RS__c> rss) {
        Map<id,Rev__c> revMap = GW_Revenue.getMapFromRelated(rss);
        Map<id,Opportunity> oppMap = GW_Opportunity.getMapFromRelated(revMap.values() );
        Set<Id> billingAccs = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Opportunity opp : oppMap.values() ) {
            if (opp.Billing_Account__c != null) billingAccs.add(opp.Billing_Account__c);
            if (opp.Primary_Contact__c != null) contactIds.add(opp.Primary_Contact__c);
        }
        Map<id,Account> accMap = GW_Account.getMap(billingAccs);
        List<Contact> primContacts = (List<Contact>) GW_sObject.queryRecords('Contact', contactIds);
        Set<Id> productIds = new Set<Id>();
        for (Rev__c rev : revMap.values() ) {
            if (rev.Product__c != null) productIds.add(rev.Product__c);
        }
        List<Product2> prods = (List<Product2>) GW_sObject.queryRecords('Product2', productIds);
        
        UTIL.cache(revMap);
        UTIL.cache(oppMap);
        UTIL.cache(accMap);
        UTIL.cache(primContacts);
        UTIL.cache(prods);
    }
    
    public static void checkStatusChangeAndUpdate(List<RS__c> rss) {
        List<RS__c> rssToUpdate = new List<RS__c>();
        
        if (!rss.isempty() ) {
            for (RS__c rs: rss) { 
                if ( GW_RS.setStatus(rs) ) { rssToUpdate.add(rs); }
            }
            
            try {
                update rssToUpdate;
            } catch(Exception ex) {
                UTIL.throwError('GW_RS.checkStatusChangeAndUpdate(): Error updating RSs: ',ex);
            }
        }
    }
    
    public static Boolean setStatus(RS__c rs) {
        StatusCalculator statusCalc = new StatusCalculator(rs);
        return statusCalc.setStatus(rs); 
    }
    
    public class StatusCalculator extends StatusCalculator.AbstractStatusCalculator {

        public StatusCalculator(RS__c rs) { super(rs, new Map<Integer, String>{-1 => 'Cancelled', 0 => 'Draft', 1 => 'Approved', 2 => 'Signed', 3 => 'Scheduled', 4 => 'Running', 5 => 'Finished'});}
 
        public override Boolean passCriteria(sObject so, Integer stage) {
            RS__c rs = (RS__c) so;
            Rev__c parentRev = (Rev__c) UTIL.getCached(rs.Rev__c);
            if (stage==-1) return true; 											// Cancelled
            if (stage==0) { return true; }											// Draft 
            if (stage==1) { if( parentRev.NumStatus__c>0) return true;}             // Approved
            if (stage==2) { if( parentRev.NumStatus__c>1) return true;}             // Signed
            if (stage==3) { if( parentRev.NumStatus__c>2) return true;}             // Scheduled
            if (stage==4) { if (rs.From_Date__c <= Date.today() ) return true;}     // Running
            if (stage==5) { if (rs.Until_Date__c < Date.today()) return true;}      // Finished
            return false;
        }
    }
}