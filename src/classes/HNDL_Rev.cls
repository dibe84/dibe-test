public with sharing class HNDL_Rev extends TriggerManager.TriggerHandler {

    // Flow control Static vars
    public static Boolean cascadeDML = false; // must specifically set this to run follow up DML (RS/Metric/Invoice)
    private List<Rev__c> revsToDelete = new List<Rev__c>();
    private List<Rev__c> revsToSync = new List<Rev__c>();
    private Set<Id> revIdsDoNotInvoiceChanged = new Set<Id>();
    private Map<id,Opportunity> mapOpps;
    List<WS_ScheduledCallout__c> wsscToUpsert = new List<WS_ScheduledCallout__c>();
    private List<Rev__c> revsToCheckForBookingPush = new List<Rev__c>();
    private List<Rev__c> revsToCheckForBookingPush_v2 = new List<Rev__c>();

    // 2 properties below should be static, since they are filled in BEFORE, but used in AFTER context
    private static List<Rev__c> childRevsToDelete; // when a master Rev.Item record is deleted, all children (adjustment records) should be deleted

    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        UTIL.cache(soLst);
        UTIL.cacheUncachedRecords( GW_sObject.getParentIds(soLst, 'Product__c') );
        if (hndlEvent == TriggerManager.triggerEventType.BeforeInsert)
        	UTIL.cacheUncachedRecords( GW_sObject.getParentIds(soLst, 'Opportunity__c') );
        // gather related records BEFORE, perform logic AFTER
        if (hndlEvent == TriggerManager.triggerEventType.BeforeDelete) {
            childRevsToDelete 	= [Select Id From Rev__c Where Master__c IN :soLst AND Id NOT IN :soLst];
        }
    }

    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        Map<Id, sObject> oppsMap = (Map<Id, sObject>) UTIL.getCachedMap(GW_sObject.getParentIds( soLst, 'Opportunity__c' ));
        UTIL.cacheUncachedRecords( GW_sObject.getParentIds( oppsMap.values(), 'MemberUnit__c' ) );
        if (UTIL.isRunningTestSetup == false) {
            UTIL_MailTrigger mt = new UTIL_MailTrigger(oldMap, newMap);
        }
    }

    public override void beforeInsert(SObject so) {
        Rev__c rev = (Rev__c)so;
		validateRev( rev , null );
        rev.Description__c = GW_Revenue.getDefaultLineItemDescription(rev);
        GW_Revenue.setStatus(rev); // leave as last method!
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        UTIL_RecordRestriction.checkFieldLocks(so, oldSo);
        Rev__c rev = (Rev__c)so;
        Rev__c oldRev = (Rev__c)oldSo;

		validateRev( rev , oldRev );
        if (rev.Product__c != oldRev.Product__c) rev.Description__c = GW_Revenue.getDefaultLineItemDescription(rev);

        if(rev.Until_Date__c > rev.TerminationDate__c ){
        	UTIL.throwError('The until date can\'t pass the termination date.');
        }
        
        GW_Revenue.setStatus(rev); // leave as last method!
    }

    public override void beforeDelete(SObject so) {
        UTIL_RecordRestriction.checkDeletionLock(so);

        Rev__c rev = (Rev__c)so;
        if (rev.MaxRSStatus__c > 6) {
            rev.addError('You can\'t delete this revenue. For one of its revenue schedules an invoice was already sent to billing.');
        }
    }

    public override void afterInsert(SObject so) {
        Rev__c rev = (Rev__c)so;
        Opportunity parentOpp = (Opportunity) UTIL.getCached(rev.Opportunity__c);
        if(parentOpp != null && parentOpp.MemberUnit__c != null){
            MemberUnit__c mu = (MemberUnit__c) UTIL.getCached(parentOpp.MemberUnit__c);
            if(!mu.EnableTRACT__c)
                revsToSync.add(rev);
        }
        if (rev.NumStatus__c > 1) {
            if (UTIL_WSC_Subscription.isSubscribedToWS(Rev.MemberUnitId__c,'WSC_API_SFECG_v1', 'BookingPush')) {
                revsToCheckForBookingPush.add(rev);
            }
            else if (UTIL_WSC_Subscription.isSubscribedToWS(Rev.MemberUnitId__c,'WSC_API_SFECG_v2', 'BookingPush')) {
                revsToCheckForBookingPush_v2.add(rev);
            }
		}
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        Rev__c rev      = (Rev__c)so;
        Rev__c oldrev   = (Rev__c)oldSo;
        Set<String> checkFields = new Set<String>{
            'QuantityBooked__c', 
            'InvoiceGrouping__c',
            'Billing_Account__c',
            'From_Date__c',
            'Until_Date__c',
            'UnitPrice__c',
            'BillingCalc__c',
            'BillingCategory__c'
        };
        Set<String> checkSubscriptionFields = new Set<String>{
            'From_Date__c',
            'Until_Date__c',
            'UnitPrice__c',
            'BundleSize__c',
            'ContractDiscount__c',
            'Status__c',
            'QuantityBilled__c',
            'TerminationDate__c',
            'TerminationReason__c',
            'SubscriptionEndDate__c',
            'LocalBookingId__c',
            'Product__c',
            'Pricebook__c',
            'Touch__c'
        };

        if (GW_sObject.oneOrMoreFieldsChanged(rev, oldrev, checkFields)) { 
            Opportunity parentOpp = (Opportunity) UTIL.getCached(rev.Opportunity__c);
            if(parentOpp != null && parentOpp.MemberUnit__c != null){
                MemberUnit__c mu = (MemberUnit__c) UTIL.getCached(parentOpp.MemberUnit__c);
                if(!mu.EnableTRACT__c){
                    revsToSync.add(rev);
                }
            } 
        }

        if (rev.NumStatus__c > 1 && GW_sObject.oneOrMoreFieldsChanged(rev, oldrev, checkSubscriptionFields)) {
            if (UTIL_WSC_Subscription.isSubscribedToWS(Rev.MemberUnitId__c,'WSC_API_SFECG_v1', 'BookingPush')) {
                revsToCheckForBookingPush.add(rev);
            }else if (UTIL_WSC_Subscription.isSubscribedToWS(Rev.MemberUnitId__c,'WSC_API_SFECG_v2', 'BookingPush')) {
                revsToCheckForBookingPush_v2.add(rev);
            }
        }
    }

	public override void afterDelete(SObject so) {
		Rev__c rev = (Rev__c)so;
		if(rev.MaxRSStatus__c <= 6) {
			revsToDelete.add(rev);
		}
	}

    public override void andFinally() {
		//UTIL_Log.start();
        Savepoint sp;
        if (revsToSync!=null && !revsToSync.isEmpty()) {
			//UTIL_Log.d('XX revsTosync: ',revsToSync);
            sp = Database.setSavepoint();
            try {
                HNDL_Rev.cascadeDML = false; // reset, to prevent DML cascade if not specifically required
                updateStructure(revsToSync, revIdsDoNotInvoiceChanged);
            } catch(Exception ex) {
                Database.rollback(sp);
                UTIL.throwError('HNDL_Revenue - Error updateStructure. ',ex);
            }
        }

        if (hndlEvent == TriggerManager.triggerEventType.AfterDelete && ((HNDL_Rev.childRevsToDelete != null && HNDL_Rev.childRevsToDelete.size()>0) || revsToDelete.size() > 0)) {
            delete childRevsToDelete;
        }

        if (revsToCheckForBookingPush.size()>0){
        	UTIL_WSC.checkForProcessing('WSC_API_SFECG_v1.BookingPush', getMasterRevs(revsToCheckForBookingPush), wsscToUpsert);
        }

        if (revsToCheckForBookingPush_v2.size() > 0) {
            UTIL_WSC.checkForProcessing('WSC_API_SFECG_v2.BookingPush', getMasterRevs(revsToCheckForBookingPush_v2), wsscToUpsert);
        }
        
        if (wsscToUpsert.size()>0){
            try{
               upsert wsscToUpsert UniqueKey__c;
            }
            catch(Exception ex){
                UTIL.throwError('HNDL_Account - Error inserting WS_ScheduledCallouts',ex);
            }
        }
		//UTIL_Log.end();
    }

    private void updateStructure(List<Rev__c> revsToSync, Set<Id> revIdsDoNotInvoiceChanged) {
        if (revsToSync!=null && !revsToSync.isEmpty() ) {
            GW_RS.syncRSFromRevs(revsToSync, revIdsDoNotInvoiceChanged);
   		}
    }

    private List<Rev__c> getMasterRevs(List<Rev__c> revsToCollectMastersFrom) {

        Map<Id, Rev__c> masterRevMap = new Map<Id, Rev__c>();
        Set<Id> masterRevIds = new Set<Id>();

        for (Rev__c indexRev :  revsToCollectMastersFrom){
            if (indexRev.Type__c == 'Master') {
                masterRevMap.put(indexRev.Id, indexRev);
            }
            else if (indexRev.Type__c == 'Adjusted') {
                masterRevIds.add(indexRev.Master__c);
                UTIL.cache(indexRev);
            }
        }
        masterRevIds.removeAll(masterRevMap.keySet());

        List<Rev__c> masterRevs = (List<Rev__c>) GW_sObject.queryRecords('Rev__c', masterRevIds);
        for (Rev__c r : masterRevs) {
            masterRevMap.put(r.Id, r);
        }

        List<Rev__c> masterRevList = masterRevMap.values();

        UTIL.cache(masterRevList);

        return masterRevList;

    }

	private void validateRev( Rev__c rev , Rev__c oldRev ) {

		if (rev.from_Date__c > rev.Until_Date__c) {
			rev.addError('You cannot create a Revenue Item where the from date is after the until date');
		}

        // Insert / Update from unchecked to checked -> check for reason
        if(rev.DoNotInvoice__c && rev.DoNotInvoiceReason__c == NULL){
			rev.addError('A Reason should be selected in order to stop the invoicing of this item.');
		}

        // Set the checkbox to true if reason is filled
        if(rev.DoNotInvoice__c == FALSE && rev.DoNotInvoiceReason__c != NULL) {
            rev.addError('Do not invoice checkbox has to be checked when reason is filled.');
        }
	}
    // Constructor
    public HNDL_Rev() { super('HNDL_Rev', Rev__c.sObjectType); }

}