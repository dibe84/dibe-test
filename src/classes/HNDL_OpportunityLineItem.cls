public with sharing class HNDL_OpportunityLineItem extends TriggerManager.TriggerHandler { 
    // Constructor
    public HNDL_OpportunityLineItem() { super('HNDL_OpportunityLineItem', OpportunityLineItem.sObjectType); } 

    private Set<Id> revOldIdsToDelete;
    private Set<Id> revsToDeleteByOliId;
    private Set<Id> oppIdsToSendRequiringAttentionEmail = new Set<Id>();
    private List<OpportunityLineItem> olisToRevenue = new List<OpportunityLineItem>();
    private Map<Id,Opportunity> bookingPushAdsaleOpps = new Map<Id,Opportunity>();

    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        
        //UTIL.cache( GW_Opportunity.getMapFromRelated((List<OpportunityLineItem>)soLst));
        cacheParentObjects((List<OpportunityLineItem>) soLst);
        
        //@VT 18-05-2017
        if (Trigger.isDelete) {
            VAL_Global.InitMapInvoiceLine(soLst);
        }
    }
    
    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        //UTIL.cache( GW_Opportunity.getMapFromRelated((List<OpportunityLineItem>)soLst));
        revOldIdsToDelete = new Set<Id>();
        revsToDeleteByOliId = new Set<Id>();
        checkForSendRequiringAttentionEmail();
    }
    
    public override void beforeInsert(SObject so) {

        OpportunityLineItem oli = (OpportunityLineItem)so;
        //Opportunity opp = (Opportunity) UTIL.getCached(oli.OpportunityId);
        //MemberUnit__c mu = (MemberUnit__c) UTIL.getCached(opp.MemberUnit__c);

        //if (mu == null || mu.EnableTRACT__c) { //Add null check
            fillEmpty(oli);
            setUniqueDescription(oli);
            checkStartDate(oli);
            GW_OpportunityLineItem.applyPriceModel(oli);
            setApprovalProcessInputFields(oli);
            GW_OpportunityLineItem.setStatus(oli); // leave as last method!
        //}
    }
    
    public override void beforeUpdate(SObject oldSo, SObject so) {
        OpportunityLineItem oli = (OpportunityLineItem)so;
        Opportunity opp = (Opportunity) UTIL.getCached(oli.OpportunityId);
        MemberUnit__c mu = (MemberUnit__c) UTIL.getCached(opp.MemberUnit__c);
        if (mu != null && !mu.EnableTRACT__c) {
            fillEmpty(oli);
            checkStartDate(oli);
            
            UTIL_RecordRestriction.checkFieldLocks(so, oldSo);
        } else {
        		this.validateTractFromDate((OpportunityLineItem) oldSo, oli);
        }
        GW_OpportunityLineItem.applyPriceModel(oli);
        GW_OpportunityLineItem.setStatus(oli); // leave as last method!
    }
    
    public override void beforeDelete(SObject so) {
        OpportunityLineItem oli = (OpportunityLineItem)so;
        UTIL_FieldValidator.checkObject(oli);
        UTIL_RecordRestriction.checkDeletionLock(so);
    }
    
    public override void afterInsert(SObject so) {
        OpportunityLineItem oli = (OpportunityLineItem)so;
        olisToRevenue.add(oli);
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        OpportunityLineItem oli = (OpportunityLineItem)so;
        OpportunityLineItem oldOli = (OpportunityLineItem)oldSo;
        Opportunity opp = (Opportunity) UTIL.getCached(oli.OpportunityId);
        MemberUnit__c mu = (MemberUnit__c) UTIL.getCached(opp.MemberUnit__c);
        
        if (oli.NumStatus__c >= 0){
            olisToRevenue.add(oli);
        }
        
        // only execute when account is Enabled for TRACT and Adsale product
        Set<String> toPushField = new Set<String> {'Ad_Id__c'};
        if (GW_sObject.oneOrMoreFieldsChanged(oli, oldOli, toPushField) && oli.Ad_Id__c != null && mu != null && mu.EnableTRACT__c ){
            bookingPushAdsaleOpps.put(opp.Id, opp);
        }
    }

    public override void afterDelete(SObject so) {
        OpportunityLineItem oli = (OpportunityLineItem)so;
        revsToDeleteByOliId.add(oli.Id);
    }
    
    // public override void beforeDelete(SObject so) {}
    // public override void afterUndelete(SObject so) {}
    
    public override void andFinally() {
        
        if (revsToDeleteByOliId!=null && !revsToDeleteByOliId.isEmpty() ) {
            delete [select Id from Rev__c where OpportunityLineItemId__c IN :revsToDeleteByOliId];
        }

        // handle revenue objects
        if (olisToRevenue!=null && !olisToRevenue.isEmpty() ) {
            UTIL.cache(GW_PriceBookentry.getMapFromRelated(olisToRevenue)); // cache pbe's
            
            Savepoint sp = Database.setSavepoint();
            
            try {
                GW_Revenue.syncRevenues(olisToRevenue);
            } catch(Exception ex) {
                Database.rollback(sp);
                UTIL.throwError('HNDL_OpportunityLineItem - Error syncing Revenues. ',ex);
            }
        }
        
        if (!bookingPushAdsaleOpps.isEmpty()) {
            Set<Id> oppIds = bookingPushAdsaleOpps.keyset();
			for(OpportunityLineItem oli : [select OpportunityId from OpportunityLineItem where OpportunityId in:oppIds and Ad_Id__c = null]) {
				bookingPushAdsaleOpps.remove(oli.OpportunityId);
			}
            if(!bookingPushAdsaleOpps.isEmpty()) GW_Opportunity.callBookingPushQueueable(bookingPushAdsaleOpps.values(), (System.isBatch() ? 'ApexAsyncJob' : 'ApexTrigger'));
        }
    }
    
    private void fillEmpty(OpportunityLineItem oli) {
        Opportunity relOpp = (Opportunity) UTIL.getCached(oli.OpportunityId);
        oli.DefaultLineDescription__c = GW_OpportunityLineItem.getDefaultLineItemDescription( relOpp , oli );
        oli.Ad_Name__c = oli.DefaultLineDescription__c;

        // Discounts from related
        if (relOpp != null ) oli.ContractDiscount__c = relOpp.ContractDiscount__c;
    }
    
    public void setApprovalProcessInputFields(OpportunityLineItem oli){
        PricebookEntry pbe = (PriceBookEntry) UTIL.getCached(oli.PricebookEntryId);
        decimal percentDiscountAmount;
          
        if(pbe.MaxDiscountAmount__c != NULL && pbe.MaxDiscountPercent__c != NULL){
            /// Get lowest value of PricebookEntry.MaxDiscountAmount & PricebookEntry.MaxDiscountPercent to set OLI max discount
            percentDiscountAmount = (oli.ListPrice__c / 100) * pbe.MaxDiscountPercent__c;
            if(percentDiscountAmount > pbe.MaxDiscountAmount__c ){
                oli.MaxDiscountAmount__c = pbe.MaxDiscountAmount__c;
            }else{
                oli.MaxDiscountAmount__c = percentDiscountAmount;
            }
            
        }else if(pbe.MaxDiscountAmount__c != NULL){
            /// Use PricebookEntry.MaxDiscountAmount to set OLI max discount
            oli.MaxDiscountAmount__c = pbe.MaxDiscountAmount__c;
            
        }else if(pbe.MaxDiscountPercent__c != NULL){
            ///Use PricebookEntry.MaxDiscountPercentage to set OLI max discount
            oli.MaxDiscountAmount__c = (oli.ListPrice__c / 100) * pbe.MaxDiscountPercent__c;
        }
        
        oli.Force_Opportunity_Approval__c = pbe.Force_Opportunity_Approval__c;      
    }
    
    private void setUniqueDescription(OpportunityLineItem oli) {
        oli.UniqueLineDescription__c = (oli.OpportunityId +' '+ oli.Description).left(255);
    }
    
    private void checkStartDate(OpportunityLineItem oli) {
        Opportunity opp = (Opportunity) UTIL.getCached(oli.OpportunityId);    
        MemberUnit__c mU = opp != null ? (MemberUnit__c) UTIL.getCached(opp.MemberUnit__c) : null;
        if (mU != null && mU.OppCloseDateEarliestStartDate__c) {
            if (oli.from_Date__c < opp.CloseDate) {
                oli.from_Date__c = opp.CloseDate;
                oppIdsToSendRequiringAttentionEmail.add(opp.Id);
            }
        }
    }
    
    private void cacheParentObjects(List<OpportunityLineItem> olis) {
        if ( olis != null && !olis.isEmpty() ) {
            Map<Id,PricebookEntry> pbeMap;
            Map<Id,Product2> prodmap;
            Set<Id> advMedIds;
            List<Advertising_Medium__c> advMeds;

            Set<Id> opportunityIds = GW_sObject.getParentIds(olis, 'OpportunityId');
            Set<Id> accountIds = new Set<Id>();
            //Cache all parent oportunities
            UTIL.cacheUncachedRecords(opportunityIds);
            Map<Id,sObject> oppRecordMap = UTIL.getCachedMap(opportunityIds);
            if(oppRecordMap != null){
                //Cache all member units on opportunity
                UTIL.cacheUncachedRecords( GW_sObject.getParentIds( oppRecordMap.values(), 'MemberUnit__c' ) ); 
                // Extract Account Ids and cache those too 
                for(Id oppId : oppRecordMap.keySet()) {
                    accountIds.add(((Opportunity)oppRecordMap.get(oppId)).AccountId);
                }
            }
            UTIL.cacheUncachedRecords(accountIds);
            pbeMap =    new Map<Id,PricebookEntry>( (List<PricebookEntry>) (UTIL.getCachedMap( GW_sObject.getParentIds( olis , 'PricebookEntryId') ).values() ) );
            prodmap =   new Map<Id,Product2>( (List<Product2>) (UTIL.getCachedMap( GW_sObject.getParentIds(olis, 'Product2Id') ).values() ) );
            
            if (prodmap !=null && !prodmap.isEmpty() ) {
                advMedIds= GW_sObject.getParentIds(prodmap.values(), 'Advertising_Medium__c');
            }
            if (advMedIds !=null && !advMedIds.isEmpty() ) {
                UTIL.cacheUncachedRecords( advMedIds );
            } 
        } 
    }
    
    private void checkForSendRequiringAttentionEmail() {
        if (oppIdsToSendRequiringAttentionEmail.size() != 0) {
            List<OpportunityLineItem> olis = GW_OpportunityLineItem.getListFromRelated(oppIdsToSendRequiringAttentionEmail);
            Map<Id,Integer> countOfOliPerOpp = new Map<Id,Integer>();
            for (OpportunityLineItem oli : olis) {
                Integer mapItem = countOfOliPerOpp.get(oli.OpportunityId);
                if (mapItem == null) {
                    mapItem = 0;
                }
                mapItem++;
                countOfOliPerOpp.put(oli.OpportunityId, mapItem);
            }
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            for (Id oppId : oppIdsToSendRequiringAttentionEmail) {
                if (countOfOliPerOpp.get(oppId) >= 2) {
                    Opportunity opp = (Opportunity) UTIL.getCached(oppId);
                    mails.add(UTIL_Email.buildEmail('RevenueItemsRequiringAttention', oppId, opp.OwnerId));
                }
            }
            if (mails.size() > 0) {
                UTIL_Email.sendEmails(mails);
            }
        }
    }
    
    private void validateTractFromDate(OpportunityLineItem oldItem, OpportunityLineItem newItem) {
    		if(oldItem.Status__c == 'Running' && oldItem.from_date__c == system.today() && newItem.from_date__c != system.today()) {
    			newItem.addError('Cannot update start date of running service!');
    		}
    }
}