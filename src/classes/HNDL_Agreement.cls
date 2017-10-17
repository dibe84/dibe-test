public with sharing class HNDL_Agreement extends TriggerManager.TriggerHandler {

    private static Boolean alreadyProcessedOppProduct = false;
    
    set<id> opportunityIds = new set<id>();
    
    private List<SCH_SyncMandate> syncMandateJobs = new List<SCH_SyncMandate>(); 

    private static Map<String, Integer> statusRank = new Map<String, Integer> { 'Cancelled' => 10, 'Draft' => 20, 'Out for Signature' => 30, 'Signed' => 40 };

    private static Map<String, String> agreementStatusMap = new Map<String, String> {
        'Draft' => 'Draft', 'Pre-Send' => 'Draft', 'Created' => 'Draft', 'Out for Signature' => 'Out for Signature',
        'Waiting for Counter-Signature' => 'Out for Signature', 'Send in Progress' => 'Out for Signature', 'Waiting for Counter-Signature' => 'Out for Signature',
        'Out for Approval' => 'Out for Signature', 'Approved' => 'Out for Signature', 'Cancelled / Declined' => 'Cancelled', 'Expired' => 'Cancelled', 'Signed' => 'Signed'
    };

    // Constructor
    public HNDL_Agreement() { super('HNDL_Agreement', echosign_dev1__SIGN_Agreement__c.sObjectType); }

    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        Map<Id,echosign_dev1__SIGN_Agreement__c> moldagm = (Map<Id,echosign_dev1__SIGN_Agreement__c>)oldMap;
        Map<Id,echosign_dev1__SIGN_Agreement__c> mnewagm = (Map<Id,echosign_dev1__SIGN_Agreement__c>)newMap;
        
        List<String> cachedOppsFields = new List<String>{'Billing_Account__r.Name', 'Owner.Name', 'Owner.LastName', 'Owner.FirstName', 'Owner.Email'};
        cachedOppsFields.add( '( SELECT CreatedDate, StageName FROM OpportunityHistories ORDER BY CreatedDate DESC )' ); 
        addOpportunityToCache( (List<echosign_dev1__SIGN_Agreement__c>) soLst, cachedOppsFields );
        
        if (!Trigger.isDelete) {
            setAgreementsDeadline( soLst );
        }
    }
    
    public override void beforeUpdate(SObject oldSo, SObject so) {
        
        echosign_dev1__SIGN_Agreement__c newAgm = (echosign_dev1__SIGN_Agreement__c)so;
        echosign_dev1__SIGN_Agreement__c oldAgm = (echosign_dev1__SIGN_Agreement__c)oldSo;

        String transition = GW_Agreement.getTransition( newAgm.echosign_dev1__Status__c , oldAgm.echosign_dev1__Status__c );
        if( transition == GW_Agreement.TRANSITION_SIGNING ) newAgm.echosign_dev1__DateSigned__c = System.now();

        if( transition != null && GW_Agreement.isMandateRequired( newAgm ) ){
            if( transition == GW_Agreement.TRANSITION_SIGNING && newAgm.echosign_dev1__SignatureType__c == 'e-Signature' ){
            	syncMandateJobs.add( new SCH_SyncMandate ( newAgm , GW_Agreement.TRANSITION_SIGNING ) );
            } else {
            	syncMandateJobs.add( new SCH_SyncMandate ( newAgm , transition ) );
            }
        }
    }

    public override void afterInsert(SObject so) {

        echosign_dev1__SIGN_Agreement__c agm = (echosign_dev1__SIGN_Agreement__c)so;

        if(agm.echosign_dev1__Opportunity__c != null){
            opportunityIds.add(agm.echosign_dev1__Opportunity__c);
        }
        
        if( GW_Agreement.isMandateRequired( agm ) ){
            syncMandateJobs.add( new SCH_SyncMandate ( agm , GW_Agreement.TRANSITION_CREATION ) );
        }
    }

    public override void afterUpdate(SObject oldSo, SObject so) {

        echosign_dev1__SIGN_Agreement__c newAgm = (echosign_dev1__SIGN_Agreement__c)so;
        echosign_dev1__SIGN_Agreement__c oldagm = (echosign_dev1__SIGN_Agreement__c)oldSo;

        Opportunity opp;
        if( newAgm.echosign_dev1__Opportunity__c != null ){
            opp = (Opportunity) UTIL.getCached( newagm.echosign_dev1__Opportunity__c );
            opportunityIds.add( newAgm.echosign_dev1__Opportunity__c );
        }
    }

    public override void afterDelete(SObject so) {

        echosign_dev1__SIGN_Agreement__c agm = (echosign_dev1__SIGN_Agreement__c)so;

        if( agm.echosign_dev1__Opportunity__c != null ){
            opportunityIds.add( agm.echosign_dev1__Opportunity__c );
        }

        if( GW_Agreement.isMandateRequired( agm ) ){
            syncMandateJobs.add( new SCH_SyncMandate ( agm , GW_Agreement.TRANSITION_DELETION ) );
        }
    }

    public override void andFinally() {

        if ( syncMandateJobs.size() > 0 ){
            enqueueSyncMandateJobs();
        }

        if (OpportunityIds.size() > 0) {
            if ( !alreadyProcessedOppProduct ) {
                alreadyProcessedOppProduct = true; 
                try {
                    setOpportunityAgreementStatus(OpportunityIds);
                } catch(Exception ex) {
                    UTIL.throwError('HNDL_Agreement - Error setting the Opportunity Contract Status.',ex);
                }
            }
        }
    }

    private void setOpportunityAgreementStatus(set<id> opportunityIds){
        Map<Id, list<echosign_dev1__SIGN_Agreement__c>> childAgreements = GW_sObject.getChildrenMap(OpportunityIDs, 'echosign_dev1__R00N70000001hM2REAU__r', NULL);
        Set<Id> oppIds = childAgreements.keySet();
        List<Opportunity> updateOppList = new List<Opportunity> ();

        for (id currentOppId: oppIds) {
            Opportunity opp = new Opportunity(id = currentOppId);

            List<echosign_dev1__SIGN_Agreement__c> oppAgreementLinesAll = childAgreements.get(currentOppId);
            List<echosign_dev1__SIGN_Agreement__c> oppAgreementLinesIO = new List<echosign_dev1__SIGN_Agreement__c>();

            ///only keep IO agreements
            if (oppAgreementLinesAll != null) {
                for (echosign_dev1__SIGN_Agreement__c agr : oppAgreementLinesAll) {
                    if (agr.type__c == 'IO') {
                        oppAgreementLinesIO.add(agr);
                    }
                }
            }

            List<String> agreementValues = new List<String>();
            List<Datetime> signedDateValues = new List<Datetime>();

            if (oppAgreementLinesIO !=  null) {
                for (echosign_dev1__SIGN_Agreement__c agreementLine : oppAgreementLinesIO) {
                    if (agreementLine.echosign_dev1__Status__c == 'Signed') {
                        Datetime dateTimeSigned = datetime.now();
                        if (agreementLine.echosign_dev1__DateSigned__c != null) {
                            dateTimeSigned = agreementLine.echosign_dev1__DateSigned__c;
                        }
                        signedDateValues.add(dateTimeSigned);
                    }
                    agreementValues.add(agreementStatusMap.get(agreementLine.echosign_dev1__Status__c));
                }
                for (string Value : agreementValues) {
                    if (String.isEmpty(opp.ContractStatus__c) || statusValueIsRankedHigherThanCurrent(Value, opp.ContractStatus__c)) {
                        opp.ContractStatus__c = Value;
                    }
                }
            } else {
                opp.ContractStatus__c = 'Draft';
            }

            ///Set date of first signed agreement as close date of opportunity
            if (opp.ContractStatus__c == 'Signed' && !signedDateValues.isEmpty()) {
                signedDateValues.sort();
                DateTime dT = signedDateValues.get(0);
                opp.CloseDate = date.newinstance(dT.year(), dT.month(), dT.day());
            }
            updateOppList.add(opp);
        }

        update(updateOppList);
        //Causing SQL 101 when signed, alreadyProcessedOppProduct to fix the issue
        List<OpportunityLineItem> relatedOlis = GW_OpportunityLineItem.getListFromRelated(GW_sObject.getIdSet(updateOppList));
        update relatedOlis;
    }

    private Boolean statusValueIsRankedHigherThanCurrent(String status, String currentStatus) {
        if (!statusRank.containsKey(status) || !statusRank.containsKey(currentStatus)) {
            UTIL.throwError('HNDL_Agreement - Could not determine ranking for unknown agreement status. (status: "' + status + '", currentStatus: "' + currentStatus + '")');
        }
        return statusRank.get(status) > statusRank.get(currentStatus);
    }

    private void addOpportunityToCache(List<echosign_dev1__SIGN_Agreement__c> agms, List<String> additionalFields) {
        Set<Id> setOpps = new Set<Id>();
        for (echosign_dev1__SIGN_Agreement__c newagm : agms) {
            if (newagm.echosign_dev1__Opportunity__c != null && newagm.Type__c == 'IO') {
                setOpps.add(newagm.echosign_dev1__Opportunity__c);
            }
        }
        UTIL.cache(GW_Opportunity.getList(setOpps, additionalFields));
    }
    
    private void setAgreementsDeadline( List<echosign_dev1__SIGN_Agreement__c> agreements ){
        
        Opportunity opp;
        OpportunityHistory oppHist;
        
        String maxSigningDaysStr = UTIL.getConfig('AggExpirationMaxSigningDays');
        Integer maxSigningDays = maxSigningDaysStr == null ? 60 : Integer.valueOf( maxSigningDaysStr ); 

        Set<String> finalStati = new Set<String>{'Cancelled / Declined','Expired','Signed'};
        
        for( echosign_dev1__SIGN_Agreement__c agm : agreements ){
            
            if( !finalStati.contains( agm.echosign_dev1__Status__c ) ){

                if( agm.echosign_dev1__Opportunity__c != null && agm.type__c == 'IO' ){
                    
                    opp = ( Opportunity ) Util.getCached( agm.echosign_dev1__Opportunity__c );
                    if( opp.OpportunityHistories.size() > 0 ){
                        oppHist = opp.OpportunityHistories[0];
                        agm.echosign_dev1__Signing_Deadline__c = oppHist.CreatedDate.addDays( maxSigningDays ).date();
                    }
                }
            }   
        }
    }

    private void enqueueSyncMandateJobs(){
    	String sch = UTIL_CustomJob.createCronExpForFutureXSeconds( 10 );
        for( SCH_SyncMandate mandateSyncSch : syncMandateJobs ){
        	System.schedule('Agreement Mandate Sync - ' + mandateSyncSch.agreementId + ' - ' + System.now().getTime() , sch , mandateSyncSch );
        }    
    }
}