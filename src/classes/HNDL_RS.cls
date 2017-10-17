public with sharing class HNDL_RS extends TriggerManager.TriggerHandler {

    Set<String> fieldTriggerMetricSync = new Set<String>{'From_Date__c','Until_Date__c','BillingCategoryCalculation__c'}; // fields triggering Metrics Sync
    Set<String> fieldTriggerMasterRollup = new Set<String>{'Until_Date__c','NumStatus__c'}; // fields triggering Master Rev Rollup
    Set<String> fieldTriggerRevRecalc = new Set<String>{'From_Date__c','Until_Date__c','BillingCategoryCalculation__c','QuantityBooked__c','QuantityDelivered__c','QuantityBilled__c','MetricsDelivered__c','LastMetricCompleted__c'}; // fields triggering Revenue Calculator
    Set<String> fieldTriggerMetricRevenueSync = new Set<String>{'From_Date__c','QuantityDelivered__c','BillingCategoryCalculation__c','Revenue__c','Touch__c'};
    Set<String> lockedFieldsAfterInvoiced = new Set<String>{'From_Date__c','Until_Date__c','Revenue__c','QuantityBilled__c','QuantityDelivered__c'};
    Map<Id, Rev__c> revsToBeUpdated = new Map<Id, Rev__c>();
    Set<Id> rssForRevAmountRecalc = new Set<Id>();

    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        List<RS__c> rss = (List<RS__c>) soLst;

        UTIL.cacheUncachedRecords( GW_sObject.getParentIds(soLst, 'Rev__c') );
        UTIL.cacheUncachedRecords( GW_sObject.getParentIds(soLst, 'Invoice__c') );
        UTIL.cacheUncachedRecords( GW_sObject.getParentIds(soLst, 'Opportunity__c'));

        if (hndlEvent != TriggerManager.triggerEventType.BeforeInsert) GW_RS.populateRsMetricsMap(rss); // get metrics for Revenue Calculator
    }

    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        List<RS__c> rss = (List<RS__c>) soLst;
        if (hndlEvent != TriggerManager.triggerEventType.AfterUpdate) GW_Revenue.cacheMasterRevs(rss); // cache Master Rev records
    }

    public override void beforeInsert(SObject so) {
        RS__c rs = (RS__c)so;
        rs.SyncMetrics__c = true;
        Rev__c rev = (Rev__c) UTIL.getCached(rs.Rev__c);
        propagateDoNotInvoiceForNewRevenueSchedules(rev, rs);
        GW_RS.setStatus(rs); // leave as last method!
    }

    // test rev calc
    public override void beforeUpdate(SObject oldSo, SObject so) {
        RS__c rs = (RS__c)so;
        RS__c oldrs = (RS__c)oldSo;
        if (GW_sObject.oneOrMoreFieldsChanged(rs, oldrs, fieldTriggerMetricSync)) rs.SyncMetrics__c = TRUE;
        GW_RS.recalcRevenueValues(rs);
        if (GW_sObject.oneOrMoreFieldsChanged(rs, oldrs, lockedFieldsAfterInvoiced) && rs.IsInvoiced__c) rs.addError('Revenue already invoiced, you are not allowed to change the revenue numbers.') ;
        UTIL_RecordRestriction.checkFieldLocks(so, oldSo);
        GW_RS.setStatus(rs); // leave as last method!
    }

    public override void beforeDelete(SObject so) {
        RS__c rs = (RS__c)so;
        if (rs.IsInvoiced__c) rs.addError('Revenue already invoiced, you are not allowed to change the revenue numbers.');
        UTIL_RecordRestriction.checkDeletionLock(so);
    }

    public override void afterInsert(Sobject so) {
        RS__c rs = (RS__c)so;
        checkMasterRollups(rs, null);
        validateRS(rs, null);
    }

	public override void afterDelete(SObject so) {
		RS__c rs = (RS__c)so;
	}

    // test rev calc
    public override void afterUpdate(SObject oldSo, SObject so) {
        RS__c rs = (RS__c)so;
        RS__c oldrs = (RS__c)oldSo;
        validateRS(rs, oldrs);
        if (GW_sObject.oneOrMoreFieldsChanged(rs, oldrs, fieldTriggerMasterRollup)) checkMasterRollups(rs, oldrs);
        if (GW_sObject.oneOrMoreFieldsChanged(rs, oldrs, fieldTriggerMetricRevenueSync)) rssForRevAmountRecalc.add(rs.Id);
    }

    public override void andFinally() {
        Savepoint sp;
        if (!revsToBeUpdated.isEmpty()) {
            try {
                update revsToBeUpdated.values();
            } catch(Exception ex) {
                UTIL.throwError('HNDL_RS - Error updating revs',ex);
            }
        }
        if(!rssForRevAmountRecalc.isEmpty()) {
            try {
                upsert GW_Metric.calculateRevenueDelivered(rssForRevAmountRecalc);
            } catch (Exception ex) {
                UTIL.throwError('Failed to upsert metrics with daily amounts.',ex);
            }
        }
    }

    private void propagateDoNotInvoiceForNewRevenueSchedules(Rev__c rev, RS__c rs) {
        if(rev.DoNotInvoice__c && rev.DoNotInvoiceReason__c != null) {
            rs.DoNotInvoice__c = rev.DoNotInvoice__c;
            rs.DoNotInvoiceReason__c = rev.DoNotInvoiceReason__c;
        }
    }

    private void validateRS(RS__c rs, RS__c oldRs) {
        // Insert / Update from unchecked to checked -> check for reason
        if(rs.DoNotInvoice__c && rs.DoNotInvoiceReason__c == NULL){
			rs.addError('A Reason should be selected in order to stop the invoicing of this item.');
		}

        // Set the checkbox to true if reason is filled
        if(rs.DoNotInvoice__c == FALSE && rs.DoNotInvoiceReason__c != NULL) {
            rs.addError('Do not invoice checkbox has to be checked when reason is filled.');
        }
    }

    private void checkMasterRollups(RS__c rs, RS__c oldrs) {
        Rev__c master = (Rev__c)UTIL.getCached((Id)rs.MasterIdForm__c);
        if ( oldrs != null && rs.NumStatus__c == 7 && (oldrs.NumStatus__c != 7 || master.LastBilledDate__c==null) && (master.LastBilledDate__c==null || master.LastBilledDate__c < rs.Until_Date__c) ) {
        	Rev__c r = revsToBeUpdated.containsKey(master.Id) ? revsToBeUpdated.get(master.Id) : new Rev__c(Id=master.Id);
            r.LastBilledDate__c = rs.Until_Date__c;
            revsToBeUpdated.put(master.Id, r);
        }
        if (master.SubscriptionEndDate__c == null || master.SubscriptionEndDate__c < rs.Until_Date__c) {
            Rev__c r = revsToBeUpdated.containsKey(master.Id) ? revsToBeUpdated.get(master.Id) : new Rev__c(Id=master.Id);
            r.SubscriptionEndDate__c = rs.Until_Date__c;
            revsToBeUpdated.put(master.Id, r);
        }
    }

    // Constructor
    public HNDL_RS() { super('HNDL_RS', RS__c.sObjectType); }

}