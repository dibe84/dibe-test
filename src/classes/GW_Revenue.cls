public with sharing class GW_Revenue {

	private static final Schema.sObjectType GW_BASEOBJECT = Rev__c.sObjectType;
	private static final String GW_BASEOBJECTNAME = 'Rev__c';

	//////////////////////////////////////////////////////////////////////////////////////////////////////
	// public query methods 
	//////////////////////////////////////////////////////////////////////////////////////////////////////
	public static Rev__c getRecord(Id id) { return(Rev__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
	public static Map<id, Rev__c> getMap(Set<id> ids) { return new Map<id, Rev__c> (getList(ids)); }
	public static List<Rev__c> getList(Set<id> ids) { return(List<Rev__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }

	//////////////////////////////////////////////////////////////////////////////////////////////////////
	// related methods use to retrieve a list of parents(base object) from a list of child objects
	//////////////////////////////////////////////////////////////////////////////////////////////////////
	// RS__c
	public static Map<id, Rev__c> getMapFromRelated(List<RS__c> lst) { return getMap(getIdSetFromRelated(lst)); }
	public static Set<Id> getIdSetFromRelated(List<RS__c> lst) { return GW_sObject.getParentIds(lst, 'Rev__c'); }

	// Opportunity parent
	public static List<Rev__c> getListFromRelated(Id parentId) { return(List<Rev__c>) GW_sObject.getChildren(parentId, 'Revenue_Items__r'); }
	public static List<Rev__c> getListFromRelated(Set<Id> parentIds) { return(List<Rev__c>) GW_sObject.getChildren(parentIds, 'Revenue_Items__r'); }
	public static Set<Id> getIdSetFromRelated(Set<Id> parentIds) { return GW_sObject.getChildIds(parentIds, 'Revenue_Items__r'); }

	public static List<Rev__c> getRelatedMasterRevs(Set<Id> parentIds) {
		List<Rev__c> allRevs = (List<Rev__c>) GW_sObject.getChildren(parentIds, 'Revenue_Items__r');
		List<Rev__c> masterRevs = new List<Rev__c> ();

		for (Rev__c r : allRevs) {
			if (r.Master__c == null) masterRevs.add(r);
		}
		return masterRevs;
	}

	public static void deleteRevsOfOpportunity(Set<Id> oppIds) {
		try {
			delete[SELECT Id FROM Rev__c WHERE Opportunity__c IN : oppIds];
		} catch(Exception ex) {
			UTIL.throwError('Error deleting Revenues of Opportunity', ex);
		}
	}

	public static void syncRevenues(List<OpportunityLineItem> olis) {
		Set<Id> parentOppIds = GW_Opportunity.getIdSetFromRelated(olis);
		Map<Id, sObject> oppsMap = (Map<Id, sObject>) UTIL.getCachedMap(parentOppIds);
		List<Rev__c> existingRevs = getListFromRelated(GW_Opportunity.getIdSetFromRelated(olis));
		Map<String, Boolean> mapSyncRevFromOli = new Map<String, Boolean> ();
		for (Rev__c rev : existingRevs) {
			mapSyncRevFromOli.put(rev.OpportunityLineItemId__c, !rev.SyncFromOliLock__c);
		}
		List<Rev__c> revenuesToUpsert = new List<Rev__c> ();
		Set<Id> deleteRevsLinkedToOppIds = new Set<Id> ();

		for (OpportunityLineItem oli : olis) {
			if (oli.NumStatus__c >= 0) {
				Opportunity opp = (Opportunity) UTIL.getCached(oli.OpportunityId);
				MemberUnit__c mu = opp.MemberUnit__c == null ? new MemberUnit__c() : (MemberUnit__c) UTIL.getCached(opp.MemberUnit__c);
				if (!mu.EnableTRACT__c && (!mapSyncRevFromOli.containsKey((String) oli.Id) || mapSyncRevFromOli.get((String) oli.Id))) {
					revenuesToUpsert.add(createRevFromOli(oli));
				}
			} else {
				deleteRevsLinkedToOppIds.add(oli.OpportunityId);
			}
		}
		if (!revenuesToUpsert.isEmpty()) {
			try {
				HNDL_Rev.cascadeDML = true;
				upsert revenuesToUpsert OpportunityLineItemId__c;
			} catch(Exception ex) {
				UTIL.throwError('Error syncing Revenues', ex);
			}
		}
		if (!deleteRevsLinkedToOppIds.isEmpty()) {
			deleteRevsOfOpportunity(deleteRevsLinkedToOppIds);
		}
	}

	public static void applyPriceModel(Rev__c rev) {
		PriceCalculator.applyPriceModel(rev);
	}
    
    // set Rev end date and lookups
    public static Boolean checkMyNeighbours(Rev__c rev, Rev__c pred, Rev__c suc) { // Rev will adapt its enddate to its successor and set lookups
        Boolean oneOrMoreEffectiveFieldsChanged = false;
        
        if (suc == null && rev.successor__c != null ) {
            rev.successor__c = null;
            oneOrMoreEffectiveFieldsChanged = true;
        }
        if (pred == null && rev.Predecessor__c != null) {
            rev.Predecessor__c = null;
            oneOrMoreEffectiveFieldsChanged = true;
        }
        
        if (suc != null && rev.Until_Date__c != suc.From_Date__c -1) {
            rev.Until_Date__c = suc.From_Date__c -1;
            oneOrMoreEffectiveFieldsChanged = true;
        }
        if (suc != null && rev.successor__c != suc.Id) {
            rev.successor__c = suc.Id;
            oneOrMoreEffectiveFieldsChanged = true;
        }
        if (pred != null && rev.predecessor__c != pred.Id) {
            rev.predecessor__c = pred.Id;
            oneOrMoreEffectiveFieldsChanged = true;
        }
        return oneOrMoreEffectiveFieldsChanged;
    }

    // sets effective/adjusted fields
	public static Boolean calcEffectiveFields(Rev__c rev, Rev__c predecessor) { // returns TRUE if one or more effective fields have changed
		List<String> overrideFields = new List<String> {'ContractDiscount__c', 'BundleSize__c', 'Pricebook__c', 'Product__c', 'BillingCalc__c', 'BillingCategory__c' };
		Boolean oneOrMoreEffectiveFieldsChanged = false;
		for (String field : overrideFields) {
			// 1st, for each overridable field: If Adj_ is set, it overrules the 'effective' field (field with no prefix). 
			// If not set, predecessor should determine the value. 
			// When there is no predecessor, adj_ should be in sync with 'effective' field
			UTIL.log('get _adj field from rev: '+rev.get('adj_' + field));
			if (rev.get('adj_' + field) != null) {
				UTIL.log('adjustedDiffersFromEffective(rev, field): '+adjustedDiffersFromEffective(rev, field));
				if (adjustedDiffersFromEffective(rev, field)) {
					rev.put(field, rev.get('adj_' + field));
					oneOrMoreEffectiveFieldsChanged = true;
				}
			} else {
				if (predecessor != null) {
					if ( adjustedDiffersFromEffective(rev, field) || rev.get(field) == null) {
						rev.put(field, predecessor.get(field));
						oneOrMoreEffectiveFieldsChanged = true;
					}
				} else {
					if ( rev.get(field) != null ) {
						if (adjustedDiffersFromEffective(rev, field) )
                            rev.put('adj_' + field, rev.get(field)); // when there is no predecessor, but there is an 'effective' field set, adj_ should copy this
                        	oneOrMoreEffectiveFieldsChanged = true;
					}
				}
			}
		}
		return oneOrMoreEffectiveFieldsChanged; // this stuff is going to be useful for trigger handler, it indicates whether the update is needed for predecessors as well 
	}

	private static Boolean adjustedDiffersFromEffective(Rev__c rev, String field) {
		return(rev.get(field) != rev.get('adj_' + field));
	}

	public static String getDefaultLineItemDescription(Rev__c rev) {
		Product2 prod = (Product2) UTIL.getCached(rev.Product__c);
		if (prod==null) return null;
        if (prod.DefaultLineDescription__c == null) {
			return prod.Name.left(150);
		} else {
			return UTIL_StringParser.parseAndReplace(prod.DefaultLineDescription__c, rev).left(150);
		}
	}

	private static Rev__c createRevFromOli(OpportunityLineItem oli) {
		if (oli == null) throw new UTIL.CustomException('Opp.line is null');
		if (oli.PricebookEntryId == null) throw new UTIL.CustomException('GW_Revenue - createRevFromOli - oli.PricebookEntryId is null...');
		Opportunity opp = (Opportunity) UTIL.getCached(oli.OpportunityId);
		Account oppAcc = (Account) UTIL.getCached(opp.AccountId);
		PricebookEntry pbe = (PricebookEntry) UTIL.getCached(oli.PriceBookEntryId);
		Product2 prod = (Product2) UTIL.getCached(pbe.Product2Id);
		Rev__c rev = new Rev__c();

		rev.OpportunityLineItemId__c = oli.Id;
		rev.Opportunity__c = oli.OpportunityId;
		rev.Product__c = pbe.Product2Id;
		rev.PriceBook__c = pbe.Pricebook2Id;
		rev.from_Date__c = oli.from_Date__c;
		rev.until_Date__c = oli.until_Date__c; // default copies from oli
		rev.BillingCategory__c = oli.Billing_Category__c;
		rev.BillingCalc__c = oli.BillingCalc__c;
		rev.Billing_Account__c = opp.Billing_Account__c;
		rev.InvoiceGrouping__c = opp.InvoiceGrouping__c;
		rev.UnitPrice__c = oli.SalesPriceNet__c;
		rev.ListPrice__c = oli.ListPrice__c;
		rev.CustomListPrice__c = oli.CustomListPrice__c;
		rev.CurrencyIsoCode = oli.CurrencyIsoCode;
		rev.QuantityBooked__c = oli.Quantity;
		rev.UPCF__c = oli.UPCF__c;
		rev.Description__c = oli.DefaultLineDescription__c;
		rev.OliDescription__c = oli.OliDescription__c;
		rev.ExtLineItemId__c = oli.Ad_Id__c;
		rev.ExtOrderId__c = oli.Adserver_ID_Order_ID__c;
		rev.IndirectDiscountAmount__c = oli.IndirectDiscountAmount__c;
		rev.LineOfBusiness__c = oli.LineOfBusiness__c;
        rev.UniqueLocalBookingId__c = oli.UniqueLocalBookingId__c;

		// Discounts
		rev.ContractDiscount__c = opp.ContractDiscount__c != null ? opp.ContractDiscount__c : 0;
		// 'terms' for subscriptions
		rev.AutoExtend__c = prod.AutoExtend__c;
		rev.ScheduleAheadTerm__c = prod.ScheduleAheadTerm__c != null ? prod.ScheduleAheadTerm__c : 12;
		rev.BundleSize__c = oli.BundleSize__c != null ? oli.BundleSize__c.intvalue() : 0;
		rev.ContractPeriodInMonths__c = prod.ContractPeriodInMonths__c;
		rev.CommittedPeriodInMonths__c = prod.CommittedPeriodInMonths__c;

		if (rev.CommittedPeriodInMonths__c != null)
		rev.CommittedEndDate__c = rev.From_Date__c.addMonths(rev.CommittedPeriodInMonths__c.intValue()) - 1;
		if (rev.ContractPeriodInMonths__c != null)
		rev.InitialEndDate__c = rev.From_Date__c.addMonths(rev.ContractPeriodInMonths__c.intValue()) - 1;
		if (rev.Until_Date__c == null && rev.InitialEndDate__c != null)
		rev.Until_Date__c = rev.InitialEndDate__c;

		GW_Revenue.applyPriceModel(rev);
		return rev;
	}

	public static List<Date> getMonthStartDates(Rev__c rev) {
		Date startMonth = (rev.from_Date__c != null ? rev.from_Date__c.toStartOfMonth() : null);
		Date endMonth = (rev.until_Date__c != null ? rev.until_Date__c.toStartOfMonth() : null);
		List<Date> monthStartDates = new List<Date> ();
		if (startMonth == null || endMonth == null) return new List<Date> ();
		for (Integer m = 0; m <= startMonth.monthsBetween(endMonth); m++) {
			monthStartDates.add(startMonth.addMonths(m));
		}
		return monthStartDates;
	}

	public static List<Rev__c> getRevenueItemChain(Id masterId) {
		Set<Id> revIds = new Set<Id> ();
		revIds.add(masterId);
		Rev__c master = [Select Id, (Select Id From Adjusted_Revenue_Items__r) From Rev__c Where Id = :masterId] [0];
		for (Rev__c rev : master.Adjusted_Revenue_Items__r) revIds.add(rev.id);
		//UTIL.cacheUncachedRecords(revIds);
        //return UTIL.getCachedMap(revIds).values();
        List<Rev__c> revs = GW_sObject.queryRecords('Rev__c', revIds);
        UTIL.cache(revs);
        return revs;
	}
    
    public static void recalcAndUpdateRevChain(Id revId) {
    	Subscription sub = new Subscription(revId);
        
		List<Rev__c> revsToUpdate = sub.recalcRevChain();
        Savepoint sp = Database.setSavepoint();
        try {
            HNDL_Rev.cascadeDML = true;
			update revsToUpdate; 
        } catch(Exception ex) {
            Database.rollback(sp);
            UTIL.log(ex.getMessage());
            throw new UTIL.CustomException('Error updating Rev.Item(s): '+ex.getMessage() );
        }
    }
    
	public static void cacheMasterRevs(List<RS__c> rss) {
		Set<Id> masterRevIds = new Set<Id> ();
		for (RS__c rs : rss) {
			if (rs.MasterIdForm__c != null) masterRevIds.add((Id) rs.MasterIdForm__c);
		}
		UTIL.cache(GW_Revenue.getList(masterRevIds));
	}


	public static void checkStatusChangeAndUpdate(List<Rev__c> revs) {
		List<Rev__c> revsToUpdate = new List<Rev__c> ();

		if (!revs.isempty()) {
			for (Rev__c rev : revs) {
				if (GW_Revenue.setStatus(rev)) { revsToUpdate.add(rev); }
			}

			try {
				update revsToUpdate;
			} catch(Exception ex) {
				UTIL.throwError('GW_Revenue.checkStatusChangeAndUpdate(): Error updating revs: ', ex);
			}
		}
	}
	// status calculator 
	public static Boolean setStatus(Rev__c rev) {

		StatusCalculator.IStatusCalculator statusCalc = new RevStatusCalculator(rev);
		Boolean statusChanged = statusCalc.setStatus(rev);

		return statusChanged; // return TRUE if status changed
	}

	public class RevStatusCalculator extends StatusCalculator.AbstractStatusCalculator {
		// constructor
		public RevStatusCalculator(Rev__c rev) {
			super(rev, new Map<Integer, String> { 0 => 'Draft', 1 => 'Approved', 2 => 'Signed', 3 => 'Scheduled', 4 => 'Running', 5 => 'Finished' });
		}

	    public override Boolean passCriteria(sObject so, Integer stage) {

	        Rev__c rev = (Rev__c) so;
	        Opportunity parentOpp = (Opportunity) UTIL.getCached(rev.Opportunity__c);
	    
	        if (stage == 0) { return true; } // Draft
	        if (stage == 1) { if (parentOpp.NumStatus__c > 0) return true; } // Approved
	        if (stage == 2) { if (parentOpp.NumStatus__c > 1) return true; } // Signed
	        if (stage == 3) { 
	            if (rev.LocalBookingId__c != null) return true; 
	            else if (parentOpp.NumStatus__c > 1) {
	               return true; 
	            }
	        } // Scheduled
	        if (stage == 4) { if (rev.From_Date__c <= Date.today()) return true; } //  Running
	        if (stage == 5) { if (rev.Until_Date__c < Date.today()) return true; } //  Finished
	        return false;
	    }
	}

}