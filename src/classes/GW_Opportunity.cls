public with sharing class GW_Opportunity {

    private static final Schema.sObjectType GW_BASEOBJECT = Opportunity.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'Opportunity';
    private static Map<Id,String> approvalStatus = new Map<Id, String>();
    //When this comes from web form the status is auto-assigned, no need approval
    public static final List<String> MORE_DETAILED_FIELDS = new List<String>{'Owner.ManagerId'};
    public static Boolean selfServiceFlow = false;
    public static Boolean changeStage2ClosedWon = false; // this flag for changing Opp to closed won when OrderTract api completed
    public static Boolean isTractRunningToSinged = false;
    public static Boolean userAsSelfService = (UserInfo.getUserType() == 'Guest');
	
	public static Boolean isAdsales (Opportunity opp) {
		return opp.MemberUnitId__c.endsWithIgnoreCase('AD');
	}
    
    public static void setTractOrderStatus(Opportunity[] opps) {
        GW_Opportunity.changeStage2ClosedWon = true;
        for(Opportunity opp : opps) {
	        Integer numstatus = 4;
	        String status = 'Running';
	        if (opp.CampaignStart__c > System.today()) {
	            status = 'Scheduled';
	            numstatus = 3;
	        } 
	        opp.StageName = status;
	        opp.Status__c = status;
	        opp.NumStatus__c = numstatus;
        }
    }
    
    private static final String ADSALES = 'AdSales';
    private static final String ALL = 'All';
    public static Boolean isFromBooking = false;
    
    public static Boolean isOppAdSales(Opportunity opp) {
        String lineOfBusiness  = opp.LineOfBusiness__c; 
        return (String.isNotEmpty(lineOfBusiness)  &&  lineOfBusiness.containsIgnoreCase(ADSALES));
    }
    
    private static Map<String,Map<Integer, String>> mapOppStage = new Map<String,Map<Integer, String>>{
        ADSALES => new Map<Integer, String>{-1 => 'Lost', 0 => 'Draft', 1 => 'Approved', 2 => 'Signed' },
        ALL => new Map<Integer, String>{-1 => 'Lost', 0 => 'Draft', 1 => 'Approved', 2 => 'Signed', 3 => 'Scheduled', 4 => 'Running', 5 => 'Finished' }
    };
    
    private static Set<String> setAfterSigned = new Set<String>{'Running','Finished', 'Scheduled'};
    
    private static Map<Integer, String> getOppStageStatus(Opportunity opp) {
        String key = isOppAdSales(opp) && !isFromBooking ? ADSALES : ALL;
        if(setAfterSigned.contains(opp.stageName) && key != ALL ) key = ALL;
        return mapOppStage.get(key);
    }
    
    public static String getApprovalStatus(Id oppId, Id accId) {
        if (oppId == null) return null;
        if (accId != null) {
            Account parent = (Account) UTIL.getCached(accId);
            if (parent.SelfService__c && userAsSelfService) return 'Approved';
        } 
        if (!approvalStatus.containsKey(oppId)) {
            UTIL.log('ApprovalStatus not in cache. Querying...');
            List<ProcessInstance> pis = [SELECT Id, TargetObjectId, Status FROM ProcessInstance WHERE TargetObjectId=:oppId ORDER BY LastModifiedDate DESC];
            if ( pis.size() == 0 ){
                approvalStatus.put( oppId , 'Not submitted' );
            } else {
                approvalStatus.put( oppId , pis[0].Status );
            }   
        }
        return approvalStatus.get(oppId);
    }
    
    public static String getApprovalStatus(Id oppId) {
        return getApprovalStatus(oppId, null);
    }
    
    public static void cacheApprovalStatus(Set<Id> oppIds) {
        List<ProcessInstance> pis = [SELECT Id, TargetObjectId, Status FROM ProcessInstance WHERE TargetObjectId IN :oppIds ORDER BY LastModifiedDate ASC];
        for (ProcessInstance pi : pis ) {
            approvalStatus.put(pi.TargetObjectId,pi.Status);
        }
        for(Id oppId : oppIds) {
            if (!approvalStatus.containsKey(oppId)) {
               approvalStatus.put( oppId ,'Not submitted' ); 
            }
        }
    }

    public static Approval.ProcessResult sendForApproval(Id oppId, String comment) {
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setComments(comment);
        request.setObjectId(oppId);
        return Approval.process(request);
    }
    
    public static void cacheRecordDetails(List<Opportunity> opps) {
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : opps) {
            if (opp.Id != null) oppIds.add(opp.Id);
        }
        UTIL.cache(getList(oppIds, MORE_DETAILED_FIELDS));
    }
    
///////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods 
///////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Opportunity           getRecord(Id id)            { return (Opportunity) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Opportunity           getRecord(Id id, List<String> additionalFields)    {return (Opportunity) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id, additionalFields); }
    public static Map<id,Opportunity>   getMap(Set<id> ids)         { return new Map<id,Opportunity>( getList(ids) ); }
    public static List<Opportunity>     getList(Set<id> ids)        { return (List<Opportunity>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }
    public static List<Opportunity>     getList(String whereClause) { return (List<Opportunity>) GW_sObject.queryRecords('Opportunity', whereClause);}
    public static List<Opportunity>     getList(String whereClause, List<String> additionalFields) {return (List<Opportunity>) GW_sObject.queryRecords('Opportunity', whereClause, additionalFields);}
    public static List<Opportunity>     getList(Set<id> ids, List<String> additionalFields) {return (List<Opportunity>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids, additionalFields);}
//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of parents(base object) from a list of child objects
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // Account parent
    public static List<Opportunity>   getListFromRelated(Id parentId)        { return (List<Opportunity>) GW_sObject.getChildren(parentId, 'Opportunities'); }
    public static List<Opportunity>   getListFromRelated(Set<Id> parentIds)  { return (List<Opportunity>) GW_sObject.getChildren(parentIds, 'Opportunities'); }
    public static Set<Id>             getIdSetFromRelated(Set<Id> parentIds) { return GW_sObject.getChildIds(parentIds, 'Opportunities'); }
    
    // Rev__c
    public static Map<id,Opportunity>   getMapFromRelated(List<Rev__c> lst)     { return getMap(getIdSetFromRelated(lst)); }
    public static Set<Id>               getIdSetFromRelated(List<Rev__c> lst)   { return GW_sObject.getParentIds(lst, 'Opportunity__c'); }
    
    // OpportunityLineItem
    public static Map<id,Opportunity>   getMapFromRelated(List<OpportunityLineItem> lst)   { return getMap(getIdSetFromRelated(lst)); }
    public static Set<Id>               getIdSetFromRelated(List<OpportunityLineItem> lst) { return GW_sObject.getParentIds(lst, 'OpportunityId'); }
    
    // RS
    public static Map<id,Opportunity>   getMapFromRelated(List<RS__c> lst)   { return getMap(getIdSetFromRelated(lst)); }
    public static Set<Id>               getIdSetFromRelated(List<RS__c> lst) { return GW_sObject.getParentIds(lst, 'Opportunity__c'); }
    
//////////////////////////////////////////////////////////////////////////////////////////////////////
//  Test Factory
//////////////////////////////////////////////////////////////////////////////////////////////////////
    
    public static void signOpportunity(Id oppId){
        Opportunity opp = getRecord(oppId);
        opp.ContractStatus__c = 'Signed';
        
        update opp;
    }
    
    public static Opportunity createSObject() {
        Opportunity opp = new Opportunity();  
        opp.name = 'Test Opp';
        opp.CloseDate = Date.today()+90;
        opp.StageName = GW_sObject.getFirstPickListValue('Opportunity','StageName');
        opp.CurrencyIsoCode = UTIL.corporateCurrency.IsoCode;
        return opp;
    }
    public static Opportunity createSObject(Account parentAcc) {
        Opportunity opp = createSObject(); 
        opp.AccountId = parentAcc.Id;
        return opp;
    }
    public static Opportunity createSObject(Pricebook2 pb, Account parentAcc) {
        Opportunity opp = createSObject(parentAcc); 
        opp.Pricebook2Id = pb.Id;
        return opp;
    }
    public static Opportunity insertSObject() {
        Opportunity opp = createSObject();
        insert opp;
        return opp;
    }
    public static Opportunity insertSObject(Account parentAcc) {
        Opportunity opp = createSObject(parentAcc); 
        
        insert opp;
        return opp;
    }
    public static Opportunity insertSObject(Account parentAcc, Contact primaryContact) {
        Opportunity opp = createSObject(parentAcc); 
        opp.Primary_Contact__c=primaryContact.Id;
        
        insert opp;
        return opp;
    }

    public static void applyOppsChangesToRevenues( Map<Id, Opportunity> oppsUpdateRevBillingDetails , 
                                                   Map<Id, Opportunity> oppsUpdateRevDiscount ){
    	
        OpportunityLineItem discountOli;
        Map<Id,OpportunityLineItem> olisWithDiscountChange = new Map<Id,OpportunityLineItem>();
        List<OpportunityLineItem> olisToCheckStatus;
        
        // Loads the revenue items for all changed opps
        List<Rev__c> revsToUpdate = GW_Revenue.getListFromRelated( oppsUpdateRevBillingDetails.keySet() );
        
        // Loads opportunity line items for opps that had their Agency field changed
        if( !oppsUpdateRevDiscount.isEmpty() ){
            olisToCheckStatus = GW_OpportunityLineItem.getListFromRelated( oppsUpdateRevDiscount.keySet() );
            olisWithDiscountChange = new Map<Id,OpportunityLineItem>( olisToCheckStatus ); 	
        }
        
        // Changes the revenue items with the updated values
        Boolean cascadeDML = false;
        for (Rev__c rev : revsToUpdate) {
            rev.Billing_Account__c = oppsUpdateRevBillingDetails.get(rev.Opportunity__c).Billing_Account__c;
            rev.InvoiceGrouping__c = oppsUpdateRevBillingDetails.get(rev.Opportunity__c).InvoiceGrouping__c;
            discountOli = olisWithDiscountChange.get( rev.OpportunityLineItemId__c ); 
            if( discountOli != null ){
            	rev.IndirectDiscountAmount__c = discountOli.IndirectDiscountAmount__c;
            	cascadeDML = true; 
            }
        }

        try {
            HNDL_Rev.cascadeDML = cascadeDML;
        	update revsToUpdate;
        } catch (Exception ex) {
            UTIL.throwError('HNDL_Opportunity - Error syncing Revenues. ',ex);
        }
    }

    public static void checkStatusChangeAndUpdate(List<Opportunity> opps) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        if (!opps.isempty() ) {
            for (Opportunity opp: opps) { 
                if ( GW_Opportunity.setStatus(opp) ) { oppsToUpdate.add(opp); }
            }
            
            try {
                update oppsToUpdate;
            } catch(Exception ex) {
                UTIL.throwError('GW_Opportunity.checkStatusChangeAndUpdate(): Error updating Opps: ',ex);
            }
        }
    }

    public static Map<String, Integer> createExceptionSummaryMap( String selMemberUnitId ) {
        Map<String, Integer> exceptionMap = new Map<String, Integer>();

        List<AggregateResult> oppArl = [ SELECT COUNT(Id) numItems, MemberUnit__r.Member__r.MemberId__c, MemberUnit__r.LineOfBusiness__c 
                                         FROM Opportunity 
                                         WHERE DiscoveredExceptions__c <> '' 
                                         AND MemberUnit__c = :selMemberUnitId 
                                         GROUP BY MemberUnit__r.Member__r.MemberId__c, MemberUnit__r.LineOfBusiness__c ];

        for (AggregateResult ar : oppArl) {
            if (null == ar.get('MemberId__c')) {
                continue;
            }
            String memberUnitId = (String) ar.get('MemberId__c') + (String) ar.get('LineOfBusiness__c');
            exceptionMap.put(memberUnitId, (Integer) ar.get('numItems'));
        }
        return exceptionMap;
    }
	
	// Workaround for CD-3123: Salesforce probability is set incorrectly for running TRACT opps
    public static void checkProbabilityRunning(Opportunity oldOpp, Opportunity opp) {
        if (oldOpp.StageName != 'Running' && opp.StageName == 'Running') {
            opp.Probability = 100;
        }
    }
	
	// status calculator 
    public static Boolean setStatus(Opportunity opp) {
        
        //if (!isTractRunningToSinged) isTractRunningToSinged = !String.isBlank(opp.Tract_Order_Number__c) && opp.NumStatus__c == 4;
        if (selfServiceFlow || changeStage2ClosedWon || isTractRunningToSinged) return true;
        
        //Decimal oldNumStatus = opp.NumStatus__c;
        // set approval status
        if (opp.ApprovalStatus__c != 'Previously Approved') opp.ApprovalStatus__c = getApprovalStatus(opp.Id, opp.AccountId);

        // set general status {'Draft','Ready for Invoicing','Sent to Billing'}
        Map<Integer,String> mapStageStatus = getOppStageStatus(opp);
        StatusCalculator.IStatusCalculator statusCalc = new AdSalesOppStatusCalculator(opp, mapStageStatus);
        Boolean statusChanged = statusCalc.setStatus(opp);
        if (opp.Status__c != 'Draft' && (statusChanged || opp.StageName == null || opp.StageName != opp.Status__c)) {
            opp.StageName = opp.Status__c;
        }
        return statusChanged; // return TRUE if status changed
    }

    public static String determineOpportunityTypeBy(Account acc) {

        String confValue = UTIL.getConfig('OppTypeMaxCampaignEndDateInMonths');
        if (null == confValue || confValue.length() == 0) {
            confValue = '6';
        }
        return acc.ActiveOppsNumber__c > 0 || acc.MaxOpportunityCampaignEndDate__c >= System.today().addMonths(Integer.valueOf(confValue) * -1)
            ? 'Existing Business'
            : 'New Business';
    }
    
    /**
     *@Desc: To check whether Mandate should attached to Agreement when generating I/O or not. if related billing account is not associated to a Mandate or IBAN of Mandate is invalid, mandate should be attached to agreement.
     *@param: acc is a realted billing account of Opportunity
     *@param: oppId is an Id of Opportunity
     *@return: a boolean 
     * 			- TRUE --> if related billing account is not associated to a Mandate or IBAN of Mandate is invalid
     *			- FALSE --> when billing account is associated with a Mandate which has a valid IBAN 
     */ 
    public static Boolean mandateNeedsToBeAttached(Account acc, Id oppId) {
    	echosign_dev1__SIGN_Agreement__c mandate = (echosign_dev1__SIGN_Agreement__c) Util.getCached( acc.Mandate__c );
        Opportunity opp = (Opportunity) Util.getCached( oppId );
        Boolean isSubscribedToTract = UTIL_WSC_Subscription.isSubscribedToTRACT(acc);
        if (isSubscribedToTract) {
            return opp.Include_SEPA_mandate__c;
        } else {
            return ( ('Direct Debit'.equalsIgnoreCase(acc.Billing_Preference__c) && ( acc.Mandate__c == null || 'Failed'.equalsIgnoreCase(mandate.Mandate_Status__c))) );
        }
    }
    
    public class AdSalesOppStatusCalculator extends StatusCalculator.AbstractStatusCalculator { 
        // constructor
        public AdSalesOppStatusCalculator(Opportunity opp, Map<Integer, String> statusMap) {
            super(opp, statusMap);
        }

        public override Boolean passCriteria(sObject so, Integer stage) {
            Opportunity opp = (Opportunity) so;
            if (stage==-1) return true; // Lost
            if (stage==0) { if( opp.LostReason__c == null) return true; } // Draft
            if (stage==1) { if( (opp.ApprovalStatus__c==null?false:opp.ApprovalStatus__c.contains('Approved'))) return true;} // Approved
            if (stage==2) { if( opp.ContractStatus__c=='Signed') return true;} // Signed
            if (stage==3) { if( opp.MaxRevStatus__c>2 || opp.MaxOliStatus__c>2 || changeStage2ClosedWon) return true; } // Scheduled
            if (stage==4) { if( opp.MaxRevStatus__c>3 || opp.MaxOliStatus__c>3 || changeStage2ClosedWon) return true; } // Running
            if (stage==5) { if( opp.MinRevStatus__c>4 || opp.MinOliStatus__c>4) return true; } // Finished
            return false;
        }

    }
    
    /**
     * @createdDate: 08-12-2016
     * @createdBy: Sochanra
     * @desc: get mapping account & related contacts
     */
    public static Map<String, List<Contact>> getActivePrimaryContacts(Set<Id> accIds){
     	Map<String, List<Contact>> mapAcc = new Map<String, List<Contact>>();
     	for(Contact c : (List<Contact>)GW_sObject.queryRecords('Contact', 'AccountId IN: idSet1 And isActive__c = TRUE And Primary__c = TRUE', new Map<String, Set<id>>{'idSet1' => accIds})){
            if (c.AccountId != null) {
                if(!mapAcc.containsKey(c.AccountId)) mapAcc.put(c.AccountId, new List<Contact>());
     			mapAcc.get(c.AccountId).add(c);
            }
     	}
     	return mapAcc;
    }
    
    /**
     * Campaign Weighting Push, order should have Campaign Name, Campaign Value, and Weighting same as SFDC Opportunity
     * Booking flow immediately opportunity is signed
     */
    public static final List<String> STEPS_BOOKING_PUSH = new List<String> {
        'WSC_API_SFECG_v1.AccountPush',         //0
        'WSC_Tract.BillingAccountCreate',       //1
        'WSC_Tract.GetAgreementId',             //2
        'WSC_Tract.DraftOrderCreate',           //3
        'WSC_Tract.DraftOrderAdSalesCreate',    //4
        'WSC_Tract.OrderTract',                 //5
        'WSC_Tract.SentPaymentToTract',         //6
        'WSC_Tract.UpdateAgreementDetailsTract',//7
        'WSC_API_SFECG_v2.BookingPushTract',    //8
        'TractOrder_CFCampaignNamePush',        //9
        'TractOrder_CFCampaignValuePush',       //10
        'TractOrder_CFWeightingPush'            //11
    };
    
    public static Map<String, String> getMapOrderCusFieldId(Opportunity opp) {
        return WSC_Tract.getTractCusFieldsMapNameId(opp.Id, 'WSC_Tract.GetTractOrderCusFields');
    }
    
    public static Map<String, String> getMapOrderCusFieldValId(Opportunity opp) {
        return WSC_Tract.getCustomFieldValueId(opp.Id, String.valueOf(opp.Tract_OrderId__c), 'orders');
    }
    
    public static void callBookingPush(Opportunity[] opps, Integer currentStep, String contextInvocation, Map<String, String> mapOrderCusFieldId, Map<String, String> mapOrderCusFieldValId) {
        //Existing Batch like "BAT_BookingPushTract" is working on this flow 
        if (contextInvocation == 'ApexAsyncJob' || GW_Opportunity.userAsSelfService) return;
        BAT_BookingPushTract bookingPushTract = new BAT_BookingPushTract(opps, currentStep);
        bookingPushTract.contextInvocation = contextInvocation;
        bookingPushTract.mapOrderCusFieldId = mapOrderCusFieldId;
        bookingPushTract.mapOrderCusFieldValId = mapOrderCusFieldValId;
        if (!UTIL.isRunningTestSetup) Database.executeBatch(bookingPushTract, Test.isRunningTest() ? 200 : 1);
    }
    
    public static void callBookingPushQueueable(Opportunity[] opps, String contextInvocation) {
        if (GW_Opportunity.userAsSelfService) return;
        AsyncBookingPushTract que = new AsyncBookingPushTract(opps, contextInvocation);
        if (!UTIL.isRunningTestSetup) System.enqueueJob(que);
    }
    
    // Not support many opportunities, 1 max opportunity
    public static Opportunity[] sendBookingPush(Opportunity[] opps, Integer currentStep, Map<String, String> mapOrderCusFieldId, Map<String, String> mapOrderCusFieldValId) {
        List<Opportunity> nextList = new List<Opportunity>();
        for (Opportunity opp : opps) {
            //Ensure all item has been rechecked
            nextList.add(opp);
            
	        Integer todoStep = verifyStep(opp, currentStep);
	        if (todoStep == STEPS_BOOKING_PUSH.size()) continue;
	        String methodCall = STEPS_BOOKING_PUSH[todoStep];
	        String recordContextId = opp.Id; 
	        if (methodCall.contains('AccountPush') || methodCall.contains('BillingAccountCreate')) {
	            recordContextId = opp.Billing_Account__c;
	        }
	        
	        UTIL_WSC.WSC_Request req;
	        if (!methodCall.contains('TractOrder_CF')) req = UTIL_WSC.getWSC_Request(methodCall);
	        if (methodCall.contains('DelPrevDraftOrder')) { 
	            req.mAdditionalParams.put('oldTract_order', opp.Tract_OrderId__c);
	        }
	        if (methodCall.contains('CFCampaignNamePush')) {
	            req = UTIL_WSC.getWSC_Request('WSC_Tract.CustomFieldValuePush');
                req.mAdditionalParams.put('customFieldType', 'order');
                req.mAdditionalParams.put('customFieldId', mapOrderCusFieldId.get('Campaign name'));
                req.mAdditionalParams.put('custFieldValId', mapOrderCusFieldValId.get('Campaign name'));
                req.mAdditionalParams.put('customFieldName', 'Campaign name');
                req.mAdditionalParams.put('customFieldValue', opp.Name);
                req.mAdditionalParams.put('objectType', 'orders');
                req.mAdditionalParams.put('objectId', opp.Tract_OrderId__c);
	        }
	        if (methodCall.contains('CFCampaignValuePush')) {
                req = UTIL_WSC.getWSC_Request('WSC_Tract.CustomFieldValuePush');
                req.mAdditionalParams.put('customFieldType', 'order');
                req.mAdditionalParams.put('customFieldId', mapOrderCusFieldId.get('Campaign Value'));
                req.mAdditionalParams.put('custFieldValId', mapOrderCusFieldValId.get('Campaign Value'));
                req.mAdditionalParams.put('customFieldName', 'Campaign Value');
                req.mAdditionalParams.put('customFieldValue', opp.ExpectedRevenue);
                req.mAdditionalParams.put('objectType', 'orders');
                req.mAdditionalParams.put('objectId', opp.Tract_OrderId__c);
            }
            if (methodCall.contains('CFWeightingPush')) {
                req = UTIL_WSC.getWSC_Request('WSC_Tract.CustomFieldValuePush');
                req.mAdditionalParams.put('customFieldType', 'order');
                req.mAdditionalParams.put('customFieldId', mapOrderCusFieldId.get('Weighting'));
                req.mAdditionalParams.put('custFieldValId', mapOrderCusFieldValId.get('Weighting'));
                req.mAdditionalParams.put('customFieldName', 'Weighting');
                req.mAdditionalParams.put('customFieldValue', (opp.Probability / 100));
                req.mAdditionalParams.put('objectType', 'orders');
                req.mAdditionalParams.put('objectId', opp.Tract_OrderId__c);
            }

	        req.init(recordContextId); 
	        UTIL_WSC.WSC_Result resp = req.call();
        }
        return nextList;
    }
    
    private static Integer verifyStep(Opportunity opp, Integer currentStep) {
        //Initialize request information
        Account acc = GW_Account.getRecord(opp.accountId);
        //Account is not ready to sell 
        if (!GW_Account.isReadyForLocalPlatformPush(acc)) return STEPS_BOOKING_PUSH.size();
        OpportunityLineItem opLi = GW_OpportunityLineItem.getListFromRelated( opp.Id )[0];
        MemberUnit__c mu = GW_MemberUnit.getRecord(opp.MemberUnit__c);
        Boolean isTractEnabled = UTIL_WSC_Subscription.isSubscribedToTRACT(acc);
        Boolean isEBayKAdsale = 'EBAYK'.equalsIgnoreCase(acc.MemberId__c) && UTIL_WSC_Subscription.isAccOnlyAdsales(acc.id);
        
        if (!isEBayKAdsale && String.isEmpty(acc.UniquePlatformId__c) && currentStep == 0) return currentStep;
        if (isTractEnabled) {
            // Tract General
            if (String.isEmpty(acc.Tract_AccountId__c) && currentStep == 1) return currentStep;
	        if (String.isEmpty(opp.Tract_AgreementId__c) && currentStep == 2) return currentStep;
	        // New Business
	        if (opp.Original_Opportunity__c == null ) {
	            if (opp.Tract_Order_Date__c <  System.today() && !isEBayKAdsale && currentStep == 3) return currentStep;
	            if (isEBayKAdsale && opLi.Ad_Id__c != null && currentStep == 4) return currentStep;
	            if (((isEBayKAdsale && opLi.Ad_Id__c != null) || !isEBayKAdsale) && 
	               !opp.Tract_Order_Confirm__c && currentStep == 5) return currentStep;
		        if (mu.Pre_Paid_Billing_Cycle__c != null && !acc.Tract_Payment_Created__c && currentStep == 6) return currentStep;
	        }
	        //Existing Business
	        if (opp.Original_Opportunity__c != null ) {
	            if (!opp.Tract_Order_Confirm__c && currentStep == 7) return currentStep;
	        }
	        if (!isEBayKAdsale && !String.isEmpty(acc.LocalPlatformId__c) && String.isEmpty(opLi.UniqueLocalBookingId__c) && currentStep == 8) return currentStep;
	        if (opp.Tract_Order_Confirm__c && currentStep == 9) return currentStep;
	        if (opp.Tract_Order_Confirm__c && currentStep == 10) return currentStep;
	        if (opp.Tract_Order_Confirm__c && currentStep == 11) return currentStep;
        }
        return STEPS_BOOKING_PUSH.size();
    }
}