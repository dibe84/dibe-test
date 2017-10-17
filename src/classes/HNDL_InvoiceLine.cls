public with sharing class HNDL_InvoiceLine extends TriggerManager.TriggerHandler {

    //private Map<Id,Id> rsIdsToUpdate = new Map<Id,Id>();
	//private List<InvoiceLine__c> invLinesToSync = new List<InvoiceLine__c>();
    private Set<Id> parentRevs = new Set<Id>();
    private Set<Id> parentRS = new Set<Id>();
	private Set<Id> parentInvs = new Set<Id>();

    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        UTIL.cacheUncachedRecords( GW_sObject.getParentIds(soLst, 'Invoice__c') ); // cache parent invoices
    }
    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        // take both parents, using new-&oldmap to also get the deletes
        if (oldMap != null) {
            this.parentRevs = GW_sObject.getParentIds(oldMap.values(), 'Rev__c');
            this.parentRS = GW_sObject.getParentIds(oldMap.values(), 'RS__c');
        }
        if (newMap != null) {
            this.parentRevs.addAll( GW_sObject.getParentIds(newMap.values(), 'Rev__c') );
            this.parentRS.addAll(GW_sObject.getParentIds(newMap.values(), 'RS__c'));
        }
    }

    public override void beforeInsert(SObject so) {
        InvoiceLine__c il = (InvoiceLine__c)so;
        checkOneInvoiceParent(il);
        GW_InvoiceLine.setStatus(il); // leave as last method!
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        InvoiceLine__c il = (InvoiceLine__c)so;
        InvoiceLine__c oldil = (InvoiceLine__c)oldSo;
        checkOneInvoiceParent(il);
        UTIL_RecordRestriction.checkFieldLocks(so, oldSo);
        GW_InvoiceLine.setStatus(il); // leave as last method!
    }

    public override void beforeDelete(SObject so) {
        //UTIL_RecordRestriction.checkDeletionLock(so);
        so.addError('InvoiceLines cannot be deleted');
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        InvoiceLine__c il = (InvoiceLine__c)so;
        InvoiceLine__c oldil = (InvoiceLine__c)oldSo;

        //if (il.NumStatus__c <> oldil.NumStatus__c && il.NumStatus__c ==7 && il.RS__c != null){
        //    rsIdsToUpdate.put(il.RS__c, il.id);
        //}
    }

    public override void afterInsert(SObject so) {
        InvoiceLine__c il = (InvoiceLine__c)so;
		//invLinesToSync.add(il);
    }

    /* Deletion prohibited in new logic
    public override void afterDelete(SObject so) {
        InvoiceLine__c il = (InvoiceLine__c)so;
		parentInvs.add(il.Invoice__c);
		if(il.RS__c != null) {
			parentRS.add(il.RS__c);
		}
		if(il.Rev__c != null) {
			parentRevs.add(il.Rev__c);
		}
    }*/


    public override void andFinally(){
        if ( this.parentRevs!=null && !this.parentRevs.isEmpty() ) {
        	GW_InvoiceLine.calcRollupsInvoiceLineToRev(this.parentRevs);
        }
        if ( this.parentRS!=null && !this.parentRS.isEmpty() ) {
        	GW_InvoiceLine.calcRollupsInvoiceLineToRS(this.parentRS);
        }

        // removed in new invoicing logic
        //if(parentInvs != null && !parentInvs.isEmpty()) {
		//	GW_Invoice.checkInvoicesForDeletion(parentInvs);
		//}
    }

    private void checkOneInvoiceParent(InvoiceLine__c il) {
        if (il.Cancelled__c) { return; }
        if (il.Rev__c != null && il.RS__c != null ) il.addError('InvoiceLine cannot be linked both to RS and REV');
        if (il.Rev__c == null && il.RS__c == null ) {
            // Agency discount, to-be-removed when agency/promotion lines are implemented
            if(il.InvoiceLineDescription__c != null && il.UniqueKey__c.startsWith('ID_') == TRUE) {
                return;
            }
            il.addError('InvoiceLine must be linked to either RS or REV');
        }
    }

    // Constructor
    public HNDL_InvoiceLine() { super('HNDL_InvoiceLine', InvoiceLine__c.sObjectType); }
}