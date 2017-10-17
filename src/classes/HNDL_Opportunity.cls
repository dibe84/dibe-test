public with sharing class HNDL_Opportunity extends TriggerManager.TriggerHandler {

    private Map<Id, Opportunity> oppsUpdateRevBillingDetails = new Map<Id, Opportunity>();
    private Map<Id, Opportunity> oppsUpdateRevDiscount = new Map<Id, Opportunity>();
    private Map<Id, Opportunity> oppsDeleteRevs = new Map<Id, Opportunity>();
    private Map<Id, Opportunity> oppsUpdateLostStatus = new Map<Id, Opportunity>();
    private set<Id> setOppIds2SendConfirmationRunning = new set<Id>();
    private Map<String, Map<String, Decimal>> memberUnitToStageProbMap = new Map<String, Map<String, Decimal>>();
    private List<OpportunityContactRole> lstOppContRoles = new List<OpportunityContactRole>();
    
    private List<Opportunity> bookingPushOpps = new List<Opportunity>();
    private List<Opportunity> lostOpps = new List<Opportunity>();
    private Map<Id, Account> accMapForCreditCheck = new Map<Id,Account>();
    private Map<String, List<Contact>> mapContacts = new Map<String, List<Contact>>();

    private List<WS_ScheduledCallout__c> wsscToUpsert = new List<WS_ScheduledCallout__c>();
    private List<Rev__c> revsToCheckForBookingPush_v2 = new List<Rev__c>();

    private Set<Id> oppsWithAgreementToSend = new Set<Id>();
    private Map<String,Schema.RecordTypeInfo> accRecordTypeMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
	private Set<Id> oppUpdateLineItem4Furture = new Set<ID>();
	
	public static Boolean isQ_SyncJobUpdate = false; // use for bypass validation on update Opp stageName to finish
	
    public override void bulkBefore(List<SObject> soLst, Map<Id, sObject> oldMap, Map<Id, sObject> newMap) {
        addAccountsToCache((List<Opportunity>) soLst);  // add Parent and Billing Accounts to cache
        GW_Opportunity.cacheRecordDetails((List<Opportunity>) soLst);
        if (hndlEvent != TriggerManager.triggerEventType.BeforeInsert) {
            GW_Opportunity.cacheApprovalStatus(GW_sObject.getIdSet(soLst));
        }
        fillMemberUnitProbabilityMap((List<Opportunity>) soLst);
        
        //get parent account Id
        if (Trigger.isInsert){
	        Set<Id> parentAccIds = GW_sObject.getParentIds(soLst, 'AccountId');
	        if(parentAccIds != null){
	        	mapContacts = GW_Opportunity.getActivePrimaryContacts(parentAccIds);
	        }
        }
    }
	
	public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        if (UTIL.isRunningTestSetup == false) {
            UTIL_MailTrigger mt = new UTIL_MailTrigger(oldMap, newMap);
        }
    }

    public override void beforeInsert(SObject so) {
        Opportunity opp = (Opportunity) so;
        Account parent = (Account) UTIL.getCached(opp.AccountId);
        
        setMemberUnit( opp , parent ); 
        setDefaultIndirect( opp , parent );
        setBillingAccount(opp);
	    setDefaultContractDiscount(opp);
        setInvoiceGrouping(opp, null);
        setOpportunityType(opp);
        setProductLine(opp, parent);
        setPrimaryContact(opp);
        setCampaignEndDateToRollup(opp);

        checkContractSignedTicked(opp);
		//prefix Account Name to opportunity on opp creation
		if(parent<>NULL){
			prefixAccNameToOpp(opp,parent);
		}
        if (GW_Opportunity.setStatus(opp)) opp.SyncChildStatus__c = TRUE; // leave as last method!
        if (opp.NumStatus__c == 0) setCustomProbability(opp);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        Opportunity opp = (Opportunity) so;
        Opportunity oldopp = (Opportunity) oldSo;
        Account parent = (Account) UTIL.getCached(opp.AccountId);
		
		setCampaignEndDateToRollup(opp);
        setMemberUnit( opp , parent ); // leave as first method, since certain logic depends on MemberUnit config
        setBillingAccount(opp);
        setInvoiceGrouping(opp, oldopp);
        setProductLine(opp, parent);
        checkForLostReason(opp, oldOpp);
        if( !Test.isRunningTest()) checkForManualStageChange(opp, oldOpp);
        //Check is userAsSelfService
        if (GW_Opportunity.userAsSelfService) {
        		if ( parent != null ){
	            GW_Opportunity.selfServiceFlow = parent.SelfService__c;
	        } else {
	            GW_Opportunity.selfServiceFlow = GW_Account.getRecord(opp.AccountId).SelfService__c;
	        }
        }
        checkForContractSignedChange(opp, oldOpp);
        setApprovers(opp);

        UTIL_RecordRestriction.checkFieldLocks(so, oldSo);
        //Update Opp Stage even if it is Enable Tract
        if (GW_Opportunity.setStatus(opp)) opp.SyncChildStatus__c = TRUE; // leave as last method!
        if (opp.NumStatus__c == 0) setCustomProbability(opp);
		GW_Opportunity.checkProbabilityRunning(oldopp, opp);
    }
    
	// This method will help to add prefix of account name to opportunity name
    private void prefixAccNameToOpp(Opportunity opp,Account acc){
        MemberUnit__c mU = (MemberUnit__c) UTIL.getCached(opp.MemberUnit__c);
    	if(mU<>NULL  && mU.LineOfBusiness__c!='AD'){
    		String oppName = acc.Name+'_'+opp.Name; 
    		if(oppName.length() >= 120){
    			opp.Name= oppName.abbreviate(110);
    		} else {
    			opp.Name=oppName;
    		}	 
    	}		
    }
	
    private void setCampaignEndDateToRollup(Opportunity opp){
    	opp.CampaignEndDateToRollup__c = opp.CampaignEnd__c;
    }

    private void checkContractSignedTicked(Opportunity opp) {
        
        if (GW_Opportunity.selfServiceFlow) return;
        
        if (opp.ContractSigned__c) {
            opp.addError('You cannot tick the \'Contract Signed\' checkbox on Opportunity creation!');
        }
    }

    private void checkForContractSignedChange(Opportunity opp, Opportunity oldOpp) {
        if (GW_Opportunity.selfServiceFlow) return;
        
        Set<String> checkFields = new Set<String> { 'ContractSigned__c' };
        if (oldOpp.ContractSigned__c == TRUE && GW_sObject.oneOrMoreFieldsChanged(opp, oldOpp, checkFields)) {
            opp.addError(' You cannot uncheck the Contract Signed checkbox!');
            return;
        }

        if (oldOpp.NumStatus__c != 1 && GW_sObject.oneOrMoreFieldsChanged(opp, oldOpp, checkFields)) {
            opp.addError(' You can only set Contract Status for approved Opportunities!');
            return;
        }

        if (opp.ContractSigned__c == TRUE) {
            opp.ContractStatus__c = 'Signed';
            //activationEmailForCustomersEBAYKPR(opp);
        }
    }
	
	/*
    private void activationEmailForCustomersEBAYKPR(Opportunity signedOpp) {
        if(signedOpp.MemberUnitId__c == 'EBAYKPR' && signedOpp.Primary_Contact__c != null){
            List<Contact> oppPrimContact = [Select Id, AccountId, Email From Contact Where Id = :signedOpp.Primary_Contact__c Limit 1];
            LSC_EbaykBookingFormController.sendConfirmMessage(oppPrimContact.get(0), signedOpp.Id);
        }
    }
	*/
    private void checkForManualStageChange(Opportunity opp, Opportunity oldOpp) {
        
        if (GW_Opportunity.selfServiceFlow || GW_Opportunity.changeStage2ClosedWon) return;
        
        Set<String> checkFields = new Set<String> { 'StageName' };
        if (oldOpp.NumStatus__c != 0 && GW_sObject.oneOrMoreFieldsChanged(opp, oldOpp, checkFields) && !isQ_SyncJobUpdate) { // NumStatus__c == 0 -> 'Draft'
            opp.addError(' You cannot modify Opportunity stage after Draft!');
        }
    }

    private void checkForLostReason(Opportunity opp, Opportunity oldOpp) {
        if (oldOpp.LostReason__c != null && opp.LostReason__c == null) {
            opp.addError(' You cannot change Lost Reason on opportunity!');
        }
        if (oldOpp.LostReason__c != null && opp.LostReason__c != null && (opp.LostReason__c != oldOpp.LostReason__c)) {
            opp.addError(' You cannot change Lost Reason on opportunity!');
        }
        if (oldOpp.LostReason__c == null && opp.LostReason__c != null && oldOpp.NumStatus__c >= 3) {
            opp.addError(' You cannot set Opportunity to Lost from stage: ' + oldOpp.StageName);
        }
        if (oldOpp.LostReason__c == null && opp.LostReason__c != null && oldOpp.NumStatus__c < 3) {
            lostOpps.add(opp);
        }
    }

    public override void beforeDelete(SObject so) {
        UTIL_RecordRestriction.checkDeletionLock(so);
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        
        Opportunity opp = (Opportunity)so;
        Opportunity oldOpp = (Opportunity)oldSo;
        MemberUnit__c mU = (MemberUnit__c) UTIL.getCached(opp.MemberUnit__c);
        Set<String> checkFields = new Set<String>{'StageName', 'InvoiceGrouping__c','Billing_Account__c','Agency__c', 'ApprovalStatus__c'};
        Set<String> lostField = new Set<String>{'LostReason__c'};
        Set<String> contractStatusField = new Set<String> {'ContractStatus__c'};

        Set<String> changedFields = GW_sObject.getChangedFields(opp, oldOpp, checkFields );
        if( !changedFields.isEmpty() ){
            if( changedFields.contains('Agency__c') ){
                oppsUpdateRevDiscount.put(opp.Id, opp);
            } 

            if( changedFields.contains('ApprovalStatus__c') && opp.ApprovalStatus__c != null && opp.ApprovalStatus__c.equalsIgnoreCase('Approved') ) {
                oppsWithAgreementToSend.add( opp.Id );
            }
            
            //send confirm email when opportunity reach stageName = running, only for EBAYKPR, EBAYKRE has its existing email trigger
            if( changedFields.contains('StageName') && 'EBAYKPR' == opp.MemberUnitId__c){
               if(opp.StageName.equalsIgnoreCase('Running')){
                   setOppIds2SendConfirmationRunning.add(opp.Id);
               }
            }

            oppsUpdateRevBillingDetails.put(opp.Id, opp);
        }
        
        if (GW_sObject.oneOrMoreFieldsChanged(opp, oldOpp, lostField)){
            oppsUpdateLostStatus.put(opp.Id, opp);
            if (opp.Status__c == 'Lost') {
               oppsDeleteRevs.put(opp.Id, opp);
            }
        }
        Account accForCreditCheck = GW_Account.checkCreditStatus(oldOpp, opp);
        if(accForCreditCheck != null) accMapForCreditCheck.put(accForCreditCheck.Id,accForCreditCheck);

		// Logic for before update before opp goes to signed.
		//check with formula field if it's a future order and with Oli_Campaign_Start__c if any start date is in the past and opp ecg name == 'EBAYK'. if so 
		//update the oli with description field."Trial" start date to today and end date t0 today + 1 month -1 day. 
		if(opp.StageName != oldOpp.StageName && 
			opp.StageName == 'Signed' && 
			opp.MemberId__c == 'EBAYK' &&
			opp.Oli_Campaign_Start__c < System.today() && 
			!GW_Opportunity.isAdsales(opp) )
		{
			oppUpdateLineItem4Furture.add(opp.Id);
		}
		
		// only execute when account is Enabled for TRACT
        if (GW_sObject.oneOrMoreFieldsChanged(opp, oldOpp, contractStatusField) && opp.ContractStatus__c == 'Signed' && mu != null && mu.EnableTRACT__c ){
            bookingPushOpps.add(opp);
            //checkForTractProcessing(opp, wsscToUpsert);
        }
    }

    public override void afterInsert(SObject so) {
        Opportunity opp = (Opportunity) so;
        if (opp.AccountClosed__c) opp.addError('Account is closed for new business.');
    }

    public override void andFinally() {

        if (!lostOpps.isEmpty()) {
            customLostRestriction(lostOpps);
        }
        
        if (!oppsUpdateRevBillingDetails.isEmpty()) {
	        GW_OpportunityWithoutSharing.applyOppsChangesToRevenues( oppsUpdateRevBillingDetails , 
	                                                   oppsUpdateRevDiscount );
        }
        
        if (!oppsUpdateLostStatus.isEmpty()) {
            List<OpportunityLineItem> olisToCheckStatus = GW_OpportunityLineItem.getListFromRelated(oppsUpdateLostStatus.keySet());
            if (!olisToCheckStatus.isEmpty()) GW_OpportunityLineItem.checkStatusChangeAndUpdate(olisToCheckStatus);
        }

        if (!oppsDeleteRevs.isEmpty()) {
            List<Rev__c> revsToDelete = GW_Revenue.getRelatedMasterRevs(oppsDeleteRevs.keySet());
            delete revsToDelete;
        }
        
        if (!accMapForCreditCheck.isEmpty()) {
            System.enqueueJob(new Q_SyncCreditRating(accMapForCreditCheck.keySet())); 
        }
        
        if (!lstOppContRoles.isEmpty()) insert lstOppContRoles;

        if (!oppsWithAgreementToSend.isEmpty()) sendOrderAgreement( oppsWithAgreementToSend );
		
		if (!oppUpdateLineItem4Furture.isEmpty()) GW_OpportunityLineItem.updateLineItem4Future(oppUpdateLineItem4Furture);
        
        if (!setOppIds2SendConfirmationRunning.isEmpty()) LSC_EbaykBookingFormController.sendConfirmMessage( setOppIds2SendConfirmationRunning );
        
        if (!bookingPushOpps.isEmpty()) GW_Opportunity.callBookingPushQueueable(bookingPushOpps, (System.isBatch() ? 'ApexAsyncJob' : 'ApexTrigger'));
    }

//////////////////////////////////////////////////////////////////////////////////////////////////

    private void setBillingAccount(Opportunity opp) {
        MemberUnit__c mU = (MemberUnit__c) UTIL.getCached(opp.MemberUnit__c);
        if (mU != null && mU.UseIndirectPartnerAsBillingAccount__c && opp.Agency__c != null) {
            opp.Billing_Account__c = opp.Agency__c;
        }
        if (opp.Billing_Account__c == null) opp.Billing_Account__c = opp.Accountid;
    }

    //Autopopulate the MemberUnit on Opportunity based on the role of the owner.
    private void setMemberUnit( Opportunity opp , Account parent ) {
    	if (GW_Account.isGuestUser == true) return;
        //MemberUnit__c not filled in:
        if (opp.MemberUnit__c == null) {
            //Try to retrieve the right MemberUnit by mapping the role of the user directly to it.
            MemberUnit__c mU = (MemberUnit__c) GW_MemberUnit.getMemberUnit(opp.OwnerId);
            UTIL.cache(mu);
            //When the role of the user does not specify which memberUnit to use
            //Get the default on the member of the parent account
            if (mU == null) {
                Member__c member = GW_Member.memberCache.get( parent.Member__c );
                if (member != null) {
                   mU = GW_MemberUnit.getMemberUnitById( member.DefaultMemberUnit__c );
                }
            }
            if (mU != null) {
                opp.MemberUnit__c = mU.Id;
                if(mU.EnableTRACT__c && mU.Tract_DefaultPricebook__c != null)
                    opp.Pricebook2Id = mU.Tract_DefaultPricebook__c;
            }
            //Note: MemberUnit__c theoreticly can still be null.
        }
        else{
            MemberUnit__c mU = GW_MemberUnit.memberUnitCache.get(opp.MemberUnit__c);
            if(mU != null){
                if(mU.EnableTRACT__c){
                    if(mU.Tract_DefaultPricebook__c != null)
                        opp.Pricebook2Id = mU.Tract_DefaultPricebook__c;
                    else
                        opp.addError('Error setting pricebook on opportunity. Please select default pricebook on member unit '+mU.Name);    
                }
            }
        }
    }
    
    private void setDefaultIndirect(Opportunity opp , Account parent ) {
        if (parent.DefaultIndirect__c != null) opp.Agency__c = parent.DefaultIndirect__c;
    }

	private void setDefaultContractDiscount(Opportunity opp) { 
		Account acc = (Account) UTIL.getCached(opp.AccountId);
		opp.ContractDiscount__c = acc.AccountDiscount__c;
	}

    private void setInvoiceGrouping(Opportunity opp, Opportunity oldOpp) {
        Account billingAcc = (Account) UTIL.getCached(opp.Billing_Account__c);
        // when Billing Account has changed, copy Invoice Grouping from there
        if (oldOpp != null && opp.Billing_Account__c != oldOpp.Billing_Account__c)
            opp.InvoiceGrouping__c = billingAcc.InvoiceGrouping__c;
        // if Invoice Grouping is empty, copy default from BillingAccount
        if (opp.InvoiceGrouping__c == null && billingAcc != null)
            opp.InvoiceGrouping__c = billingAcc.InvoiceGrouping__c;    
    }

    private void setOpportunityType(Opportunity opp) {
    	if(opp.AccountId == null) return;
        Account acc = (Account) UTIL.getCached(opp.AccountId);

        opp.Type = GW_Opportunity.determineOpportunityTypeBy(acc);
    }
    
    private void addAccountsToCache(List<Opportunity> opps) {
        Set<Id> accIds = new Set<Id>();
        for (Opportunity opp : opps) {
            accIds.add(opp.AccountId);
            if (opp.Billing_Account__c != null) accIds.add(opp.Billing_Account__c);
        }
        Util.cache(GW_sObject.queryRecords('Account', accIds, new List<String>{'RecordType.Name'}));
    }
    
    private void customLostRestriction(List<Opportunity> lostOpps){
        Set<Id> lostOppsIds = (new Map<Id, Opportunity>(lostOpps)).keySet();
        
        Map<String, Set<Id>> lostOppsMap = new map<String, Set<Id>>();
        lostOppsMap.put('idSet1', lostOppsIds);
        
        List<rs__c> relevantRevs = (List<rs__c>) GW_sObject.queryRecords('rs__c', 'Opportunity__c IN: idSet1', lostOppsMap);
        
        Map<Id, List<rs__c>> oppRsMap = new Map<Id, list<rs__c>>();
        
        for (Opportunity opp : lostOpps) {
            List<rs__c> rsList = new List<rs__c>();
            
            for (rs__c rs: relevantRevs) {
                if (opp.id == rs.opportunity__c) {
                    rsList.add(rs);
                }
            }
            oppRsMap.put(opp.id, rsList);
        }
        for (Opportunity opp : lostOpps) {
            List<rs__c> rsList = new List<rs__c>(oppRsMap.get(opp.id));

            for (rs__c rs : rsList) {
                if (rs.NumStatus__c >= 7) {
                    opp.addError('This opportunity can\'t be set to lost, because invoices have been billed already.');
                }
            }
        }
    }

    private void setCustomProbability(Opportunity opp) {
        if (memberUnitToStageProbMap == null || memberUnitToStageProbMap.size() == 0) return;

        String probMapKey;
        if (memberUnitToStageProbMap.containsKey(opp.MemberUnitId__c)) {
            probMapKey = opp.MemberUnitId__c;

        } else if (memberUnitToStageProbMap.containsKey('default')) {
            probMapKey = 'default';
        }
        if (null != probMapKey && memberUnitToStageProbMap.get(probMapKey).containsKey(opp.StageName)) {
            opp.Probability = memberUnitToStageProbMap.get(probMapKey).get(opp.StageName);
        }
    }

    private void fillMemberUnitProbabilityMap(List<Opportunity> oppList) {
        if (oppList == null || oppList.size() == 0) { return; }
        Map<String, OpportunityStageProbability__c> oppStageConfigMap = OpportunityStageProbability__c.getAll();
        memberUnitToStageProbMap = new Map<String, Map<String,Decimal>>();

        try {
            for (OpportunityStageProbability__c conf : oppStageConfigMap.values()) {
                Map<String, Decimal> stageToProbMap = (memberUnitToStageProbMap.containsKey(conf.MemberUnit__c) == TRUE ? memberUnitToStageProbMap.get(conf.MemberUnit__c) : new Map<String,Decimal>());
                stageToProbMap.put(conf.StageName__c, conf.Probability__c);
                memberUnitToStageProbMap.put(conf.MemberUnit__c, stageToProbMap);
            }
        } catch (Exception e) {
            UTIL.Log('Fatal error while getting opportunity probability config, check custom settings!' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
    
    private void setApprovers(Opportunity opp) {
        Opportunity detailedOpp = (Opportunity)UTIL.getCached(opp.Id);
        Id managerId = detailedOpp.Owner.ManagerId;
    	if (opp.MemberUnit__c != null)  {
    		MemberUnit__c mU = (MemberUnit__c) UTIL.getCached(opp.MemberUnit__c);
            opp.Approval_Line_Manager__c = mU.Approval_Line_Manager__c != null ? mU.Approval_Line_Manager__c : managerId;
	        opp.Approval_Senior_Manager__c = mU.Approval_Senior_Manager__c != null ? mU.Approval_Senior_Manager__c : managerId;
	        opp.Approval_Head_of_Business__c = mU.Approval_Head_of_Business__c != null ? mU.Approval_Head_of_Business__c : managerId;
    	}
    }

    // Constructor
    public HNDL_Opportunity() { super('HNDL_Opportunity', Opportunity.sObjectType); }
    
    /**
     *@createdDate: 29-11-2016
     *@createdBy: Sochanra
     *@desc: populate contact from account to be primary contact field on opportunity 
     */
     private void setPrimaryContact(Opportunity opp){
     	if(opp.AccountId == null || opp.Primary_Contact__c != null) return;
     	//get relate contact of account
     	List<Contact> lstConts = mapContacts.get(opp.AccountId);
     	if( lstConts == null || lstConts.isEmpty()) return;
     	opp.Primary_Contact__c = lstConts.get(0).Id;
     }

     private void setProductLine(Opportunity opp, Account parent){
        if (opp.MemberUnit__c != null){
            MemberUnit__c mU = (MemberUnit__c) UTIL.getCached(opp.MemberUnit__c);
            if(mu == null) return;
            if(String.isNotBlank(opp.SAPProductLine__c) || parent.RecordType.Name == null 
               || !accRecordTypeMapByName.containsKey(parent.RecordType.Name) || mU.LineOfBusiness__c != 'AD') return;
            String recordTypeName = accRecordTypeMapByName.get(parent.RecordType.Name).getName();
            if(recordTypeName == 'Advertiser')
                opp.SAPProductLine__c = 'For Advertising - Other Opps:10162';
            else if(recordTypeName == 'Agency')
                opp.SAPProductLine__c = 'For Agency (External) Opps:10163';
            
        }
    }

    /**
    *@createdDate: 04-04-2017
    *@createdBy: Tajinder Singh
    *@desc:When an Account is enabled for Tract opportunity creation is driven by the SalesPath.
    *When an opportunity is signed off the account needs to created in Local Platform as well
    *it's opportunity bookings.
    *There is dependency on the booking creation. Account needs to be created succesfully
    *in local platform before creation of the bookings. This dependency is only for the local
    *platform as Tract account creation was already at the beginning of the sales path.
    
    CD-3601 : Switch to BAT_BookingPushTract.cls
    private void checkForTractProcessing(Opportunity opp,List<WS_ScheduledCallout__c> wsscToUpsert){
        Account acc = GW_Account.getRecord(opp.accountId);
        Boolean isEBayKAdsale = 'EBAYK'.equalsIgnoreCase(acc.MemberId__c) && UTIL_WSC_Subscription.isAccOnlyAdsales(acc.id);
        if(String.isBlank(acc.LocalPlatformId__c) && !isEBayKAdsale) {
	        UTIL_WSC.WSC_Request wsRequest = UTIL_WSC.getWSC_Request('WSC_API_SFECG_v1.AccountPush');
	        wsRequest.init(opp.accountId);
	        wsscToUpsert.add(wsRequest.getScheduledCallout());
	        upsert wsscToUpsert UniqueKey__c;
        }
        checkForBookingPushProcessing(wsscToUpsert,opp);
    }

    private void checkForBookingPushProcessing(List<WS_ScheduledCallout__c> wsScheduledCalloutBillingAcc,Opportunity opp){
        if(!(opp.name.startsWithIgnoreCase('selfService'))) {
            checkForBookingPushTractProcessing(opp, wsscToUpsert, wsScheduledCalloutBillingAcc);
        }
        checkForOrderTractProcessing(opp,wsscToUpsert);
        UTIL.log('In CheckForBookingPushProcessing');
        upsert wsscToUpsert UniqueKey__c;
    }

    private void checkForBookingPushTractProcessing(Opportunity opp,List<WS_ScheduledCallout__c> wsscToUpsert,List<WS_ScheduledCallout__c> wsScheduledCalloutBillingAcc) {
        if(opp.ContractStatus__c == 'Signed' && opp.LineOfBusiness__c!='AdSales') {
			WS_ScheduledCallout__c wsScheduledCallout;
			UTIL_WSC.WSC_Request wsRequest = UTIL_WSC.getWSC_Request('WSC_API_SFECG_v2.BookingPushTract');
			//List<OpportunityLineItem> opls = GW_OpportunityLineItem.getListFromRelated(opp.Id);

			//if(opls.isEmpty()) {
			 //   UTIL.throwError('Opportunity ' + opp.Name + ' does not contain any Opportunity Line Items');
			//}else {
				//for(OpportunityLineItem opl : opls) {
					wsRequest.init(opp.id);
					wsScheduledCallout = wsRequest.getScheduledCallout();
					wsScheduledCallout.DependsOnScheduledCallout__c = wsScheduledCalloutBillingAcc.isEmpty() ? null:wsScheduledCalloutBillingAcc[0].Id ;
					wsscToUpsert.add(wsScheduledCallout);
			   // }
			//}
		}
    }

    private void checkForOrderTractProcessing(Opportunity opp,List<WS_ScheduledCallout__c> wsscToUpsert) {
        WS_ScheduledCallout__c wsScheduledCallout;
        WS_ScheduledCallout__c wsScheduledCalloutDraftOrder;
        WS_ScheduledCallout__c wsScheduledCalloutActivationOrder;
        WS_ScheduledCallout__c wsScheduledCalloutPayments;
        WS_ScheduledCallout__c wsScheduledCalloutGetAgreement;
        WS_ScheduledCallout__c wsScheduledCalloutBookingPushTract;
        WS_ScheduledCallout__c wsScheduledCalloutTractAccount;


        //in case its a adjustment opportunity check "original opportunity" field. call WSC_Tract.UpdateAgreementDetailsTract 
        //else existing logic.
        if(opp.Original_Opportunity__c == null){
            if(opp.Name.startsWithIgnoreCase('selfService_')){
                Account acc = GW_Account.getRecord(opp.AccountId);
                String wssoAccId = '';
                String wssoAgreId = '';

                if(String.isBlank(acc.Tract_AccountId__c)){
                    UTIL_WSC.WSC_Request wsRequestAccTract = UTIL_WSC.getWSC_Request('WSC_Tract.BillingAccountCreate');
                    wsRequestAccTract.init(acc.id);
                    wsScheduledCalloutTractAccount = wsRequestAccTract.getScheduledCallout();
                    wsscToUpsert.add(wsScheduledCalloutTractAccount);
                    upsert wsscToUpsert UniqueKey__c;
                     wssoAccId = wsScheduledCalloutTractAccount.Id;

                }
                //Check if opp has a agreement id
                if(String.isBlank(opp.Tract_AgreementId__c)){
                    UTIL_WSC.WSC_Request wsRequestGetAgreement = UTIL_WSC.getWSC_Request('WSC_Tract.GetAgreementId');
                    wsRequestGetAgreement.init(opp.id);
                    wsScheduledCalloutGetAgreement = wsRequestGetAgreement.getScheduledCallout();
                    wsScheduledCalloutGetAgreement.DependsOnScheduledCallout__c = String.isBlank(wssoAccId) ? null:wssoAccId;
                    wsscToUpsert.add(wsScheduledCalloutGetAgreement);
                    upsert wsscToUpsert UniqueKey__c;
                    wssoAgreId = wsScheduledCalloutGetAgreement.Id;
                }

                //send out the draft order
                UTIL_WSC.WSC_Request wsRequestDraftOrder = UTIL_WSC.getWSC_Request('WSC_Tract.DraftOrderCreate');
                wsRequestDraftOrder.init(opp.id);
                wsScheduledCalloutDraftOrder = wsRequestDraftOrder.getScheduledCallout();
                wsScheduledCalloutDraftOrder.DependsOnScheduledCallout__c = String.isBlank(wssoAgreId) ? null:wssoAgreId;
                wsscToUpsert.add(wsScheduledCalloutDraftOrder);
                upsert wsscToUpsert UniqueKey__c;

                // Do the activation Call
                UTIL_WSC.WSC_Request wsRequestActivationOrder = UTIL_WSC.getWSC_Request('WSC_Tract.OrderTract');
                wsRequestActivationOrder.init(opp.id);
                wsScheduledCalloutActivationOrder = wsRequestActivationOrder.getScheduledCallout();
                wsScheduledCalloutActivationOrder.DependsOnScheduledCallout__c = wsScheduledCalloutDraftOrder.Id;
                wsscToUpsert.add(wsScheduledCalloutActivationOrder);
                upsert wsscToUpsert UniqueKey__c;

                //Payments Call
                UTIL_WSC.WSC_Request wsRequestPayments = UTIL_WSC.getWSC_Request('WSC_Tract.SentPaymentToTract');
                wsRequestPayments.init(opp.id);
                wsScheduledCalloutPayments = wsRequestPayments.getScheduledCallout();
                wsScheduledCalloutPayments.DependsOnScheduledCallout__c = wsScheduledCalloutActivationOrder.Id;
                wsscToUpsert.add(wsScheduledCalloutPayments);
                upsert wsscToUpsert UniqueKey__c;

				if(opp.ContractStatus__c == 'Signed' && opp.LineOfBusiness__c!='AdSales') {
					// Finaly send the call to SPOC :-)
					UTIL_WSC.WSC_Request wsRequestBookingPushTract = UTIL_WSC.getWSC_Request('WSC_API_SFECG_v2.BookingPushTract');
					wsRequestBookingPushTract.init(opp.id);
					wsScheduledCalloutBookingPushTract = wsRequestBookingPushTract.getScheduledCallout();
					wsScheduledCalloutBookingPushTract.DependsOnScheduledCallout__c = wsScheduledCalloutPayments.Id;
					wsscToUpsert.add(wsScheduledCalloutBookingPushTract);
					upsert wsscToUpsert UniqueKey__c;
				}
            }else{
            	if( !oppUpdateLineItem4Furture.contains(opp.id) ) {
	                UTIL_WSC.WSC_Request wsRequest = UTIL_WSC.getWSC_Request('WSC_Tract.OrderTract');
	                wsRequest.init(opp.id);
	                wsScheduledCallout = wsRequest.getScheduledCallout();
	                wsscToUpsert.add(wsScheduledCallout);
	                upsert wsscToUpsert UniqueKey__c;
            	}
            }
        }else{
            
            doUpdateAgreementDetailsTract(opp.Id);
            //UTIL_WSC.WSC_Request wsRequest = UTIL_WSC.getWSC_Request('WSC_Tract.UpdateAgreementDetailsTract');
            //wsRequest.init(opp.id);
            //wsScheduledCallout = wsRequest.getScheduledCallout();
            //wsscToUpsert.add(wsScheduledCallout);
            //upsert wsscToUpsert UniqueKey__c;
            
            //UTIL_WSC.WSC_Request wsRequestBookingPushTract = UTIL_WSC.getWSC_Request('WSC_API_SFECG_v2.BookingPushTract');
            //wsRequestBookingPushTract.init(opp.id);
            //wsScheduledCalloutBookingPushTract = wsRequestBookingPushTract.getScheduledCallout();
            //wsscToUpsert.add(wsScheduledCalloutBookingPushTract);
            //upsert wsscToUpsert UniqueKey__c;
        }
    }
    
    private static void doUpdateAgreementDetailsTract(String Id){
        WS_ScheduledCallout__c wsScheduledCallout;
        List<WS_ScheduledCallout__c> wsscToUpsert = new List<WS_ScheduledCallout__c>();
        UTIL_WSC.WSC_Request wsRequest = UTIL_WSC.getWSC_Request('WSC_Tract.UpdateAgreementDetailsTract');
        wsRequest.init(id);
        wsScheduledCallout = wsRequest.getScheduledCallout();
        wsscToUpsert.add(wsScheduledCallout);
        upsert wsscToUpsert UniqueKey__c;     
    }
    
//    private void sendPaymentToTract(Opportunity opp, List<WS_ScheduledCallout__c> wsScheduleCalloutOrdreTract){
//      WS_ScheduledCallout__c wsScheduledCallout;
//      UTIL_WSC.WSC_Request wsRequest = UTIL_WSC.getWSC_Request('WSC_Tract.SentPaymentToTract');
//      wsRequest.init(opp.id);
//      wsScheduledCallout = wsRequest.getScheduledCallout();
//      wsScheduledCallout.DependsOnScheduledCallout__c = wsScheduleCalloutOrdreTract.isEmpty() ? null : wsScheduleCalloutOrdreTract[0].Id;
//      wsscToUpsert.add(wsScheduledCallout);
//    }*/

    private void sendOrderAgreement( Set<Id> oppsWithAgreementToSend ){
        for (echosign_dev1__SIGN_Agreement__c record: [ select Id, echosign_dev1__Opportunity__c from echosign_dev1__SIGN_Agreement__c where echosign_dev1__Opportunity__c in: oppsWithAgreementToSend ])
            GW_Agreement.sendAgreement( record.Id );
    }
    
    private void setOpportunityName(Opportunity opp){
     	MemberUnit__c mU = (MemberUnit__c) UTIL.getCached(opp.MemberUnit__c);
     	if(mU != null && mU.LineOfBusiness__c != 'AD') {
     		Account acc = (Account) UTIL.getCached(opp.AccountId);
     		opp.Name = acc.Name + ' - ' + opp.Name;
        }
    }
    
}