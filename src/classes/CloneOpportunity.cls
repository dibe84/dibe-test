/**
 * @Created: Chr - 01-09-2015 
 * #8068: Custom Clone button required on Opportunity
 * @Des: 
 *  1. opportunities with LineOfBusiness = 'Ad sales' can have DFP ad ids and order ids - these are unique and should not be copied.
 *  2. Metrics should not be copied, and for opps with LineOfBusiness = 'ad sales' 
 *     opportunities neither should revenue items. Expected is that line item trigger will re-create these items when saving the cloned record. 
 *     However opps with LineOfBusiness = ' automotive' the revenue items should also be copied.
 *  3. Agreement records should not be copied.
 *  4. for Ad Sales cloning also the custom targeting should be copied over.
 */
global class CloneOpportunity {
    
    public static final String OPP_LINEOFBUSINESS_ADSALE        = 'AdSales';
    public static final String OPP_LINEOFBUSINESS_AUTOMOTIVE    = 'Automotive';

    webService static Boolean isOppCloningWithProductsAllowed(String oppid){
        List<OpportunityLineItem> olis = GW_OpportunityLineItem.getListFromRelated(oppId);
        if(olis.size() > 0){
            Map<Id,PriceBookEntry> pbesMap  = GW_PriceBookEntry.getMapFromRelated(olis);
            List<PriceBookEntry> lstpbes    =   [SELECT Id 
                                                    FROM PriceBookEntry 
                                                    WHERE Id IN :pbesMap.keyset()  
                                                    AND (IsActive = false OR Product2.isActive = false OR Pricebook2.IsActive = false)
                                                ];
            return lstpbes.isEmpty();
        } 
        return true;
    }

    /* HCS 28-02-2016
    *   Proposed Solution
        Ensure that the custom 'clone' button on opportunity copies creates a copy opportunity including all lineitems for all Ad sales member units
        Ensure that the cloned opportunity.Name field is appended with " Clone".
        Ensure that the 'clone' button on opportunity also copies over the attachments.
        Verify that the cloned opportunity does NOT copy over the opportunity stage. It should default back to 'draft'.
        refactored: 9/4/2017 with CD-3603
    */
    webService static String cloneOpp(String oppid, Boolean areProductsAllowed, Boolean cloneAttachments) {
        try{
            String queryFrom        = 'From Opportunity where Id = \''+ oppid + '\' LIMIT 1';
            List<sObject> sObList   = getSObject('Opportunity', queryFrom);
            Opportunity opp         = (Opportunity) sObList.get(0);
            Opportunity oppClone    = createOppClone(opp);

            // for Clone with Attachments button
            if(cloneAttachments){
                cloneOppAttachments(oppId, oppClone.Id);
            }
            
            if(areProductsAllowed){
                cloneOppProductsProcess(oppid, oppClone.Id);
            } else {
                // In the case products cloning are not allowed, remove the Pricebook
                oppClone.PriceBook2Id = null;
                update oppClone;
            } 
            return oppClone.Id;
        }catch(Exception ex){
            System.debug(' ----->>ERROR::::' + ex.getStackTraceString());
            ex.setMessage('An Error occured. Please contact your Salesforce.com Administrator for help.\n\n' + ex.getMessage());
            return ex.getMessage();
        }
        return '';
    }


    private static Opportunity createOppClone(Opportunity origOpp){

        Opportunity opClone = origOpp.clone(false,true);
        System.debug('\n\n Opportunity clone: ' + opClone + '\n\n');
        
        opClone.OwnerId            = UserInfo.getUserId();
        opClone.ContractStatus__c  = 'Draft';
        opClone.ContractSigned__c  = false;
        opClone.Lost__c            = false;
        opClone.LostReason__c      = null;
        opClone.StageName          = 'Qualification';
        opClone.name               = origOpp.Name + ' Clone';
        opClone.RecordTypeId       = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Preapproved').getRecordTypeId();
        opClone.CloseDate = system.Today();

        insert opClone;
        return opClone;
    }


    private static void cloneOppAttachments(String oppId, String oppClonedId){
        String queryFrom = 'From Attachment where ParentId = \''+ oppId + '\'';
        List<Attachment> lstAtts = getSObject('Attachment', queryFrom);

        if (!lstAtts.isEmpty()) {
            List<Attachment> lstNewAtts = new List<Attachment>();
            for(Attachment att:lstAtts) {
                Attachment attClone = att.clone(false,true);
                attClone.OwnerId    = UserInfo.getUserId();
                attClone.parentId   = oppClonedId;
                lstNewAtts.add(attClone);
            }
            insert lstNewAtts;
        }
    }


    private static void cloneOppProductsProcess(String oppId, String oppCloneId){

        List<OpportunityLineItem> oliCloneList = cloneOppProducts(oppId, oppCloneId);

        Map<Id, Id> oldTar2oldOli = new Map<Id, Id>();
        Map<Id, Id> oldOli2newTar = new Map<Id, Id>();
        
        for (OpportunityLineItem oli : oliCloneList) {
            if (oli.Targeting__c != null) {
                System.debug('\n\nTargetingID: ' + oli.Targeting__c + ' ==> LineItemId: ' + oli.ClonedFromLineItem__c + '\n\n');
                oldTar2oldOli.put(oli.Targeting__c, oli.ClonedFromLineItem__c);
            }
        }

        if (!oldTar2oldOli.isEmpty()) {
            List<Targeting__c> targetingOldList = getProducts_Targeting(oldTar2oldOli.keySet());

            if (!targetingOldList.isEmpty()) {
                List<Targeting__c> targetingNew = cloneProducts_Targeting(targetingOldList);

                if (!targetingNew.isEmpty()) {
                    for (Targeting__c tar_new : targetingNew) {
                        System.debug('\n\nClonedTargeting: ' + tar_new + '\n\n');
                        if (oldTar2oldOli.containsKey(tar_new.ClonedFromTargeting__c)) {
                            oldOli2newTar.put(oldTar2oldOli.get(tar_new.ClonedFromTargeting__c), tar_new.Id);
                        }
                    }
                }

                // set oli targeting
                for (OpportunityLineItem oli: oliCloneList){
                    oli.Targeting__c = oldOli2newTar.get(oldTar2oldOli.get(oli.Targeting__c));
                }

                //clone Device Targeting
                cloneProducts_DeviceTargeting(oldTar2oldOli, oldOli2newTar);
                
                // clone Content Targeting
                cloneProducts_ContentTargeting(oldTar2oldOli, oldOli2newTar);

                //clone Connection Targeting
                cloneProducts_ConnectionTargeting(oldTar2oldOli, oldOli2newTar);

                // clone Geography Targeting
                cloneProducts_GeographyTargeting(oldTar2oldOli, oldOli2newTar);

                //clone Keyvalue targeting
                cloneProducts_KeyvalueTargeting(oldTar2oldOli, oldOli2newTar);
                
                //SOTHEA 24 OCT 2016 #9969 clone placement targeting associations
                cloneProducts_PlacementTargeting(oldTar2oldOli, oldOli2newTar);
            }           
        }
        
        System.debug('oliCloneList ins ----- ' + oliCloneList);
        insert oliCloneList;
    }

    private static List<OpportunityLineItem> cloneOppProducts(String oppId, String oppCloneId){
        String queryFrom                    = 'From OpportunityLineItem where OpportunityId = \''+ oppid + '\'';
        List<OpportunityLineItem> olisList  = getSObject('OpportunityLineItem', queryFrom);

        for (OpportunityLineItem oli : olisList){
            oli.ClonedFromLineItem__c = oli.Id;
        }

        OpportunityLineItem[] oliCloneList = olisList.deepClone(false);

        // clear oli booking fields
        for(OpportunityLineItem oliClone : oliCloneList){
            oliClone.OpportunityId                   = oppCloneId;
            oliClone.TotalPrice                      = null;
            oliClone.UniqueLocalBookingId__c         = null;
            oliClone.Ad_Id__c                        = null;
            oliClone.Adserver_Adv_Advertiser_ID__c   = null;
            oliClone.Adserver_ID_Order_ID__c         = null;
            oliClone.Availability__c                 = null;
            oliClone.Check_Inventory__c              = true;
        }
        return oliCloneList;
    }

    private static List<Targeting__c> getProducts_Targeting(Set<Id> oldTrargetingIds){
        String queryFrom = 'From Targeting__c where Id IN (' + setToString(oldTrargetingIds) + ')';
        List<Targeting__c> tgList = getSObject('Targeting__c', queryFrom);
        return tgList;
    }

    private static List<Targeting__c> cloneProducts_Targeting(List<Targeting__c> prodsTargetsOld){
        List<Targeting__c> targNew = new List<Targeting__c>();
        for (Targeting__c tar : prodsTargetsOld) {
            List<Targeting__c> tarList      = new List<Targeting__c>{tar};
            List<Targeting__c> tarCloneList = tarList.deepClone(false);

            Targeting__c targClone = tarCloneList.get(0);
            targClone.ClonedFromTargeting__c    = tar.Id;
            targClone.OwnerId                   = UserInfo.getUserId();
            targNew.add(targClone);
        }
        insert targNew;
        return targNew;
    }


    private static void cloneProducts_DeviceTargeting(Map<Id, Id> oldProdsTargMap, Map<Id, Id> newProdsTargMap){

        String queryFrom    = 'From TargetingDeviceAssociation__c where Targeting__c IN ('+ setToString(oldProdsTargMap.keySet()) + ')';
        List<sObject> Slist = getSObject('TargetingDeviceAssociation__c', queryFrom);
        
        List<TargetingDeviceAssociation__c> tarDeviceIns = new List<TargetingDeviceAssociation__c>();
        if(!Slist.isEmpty()) {
            tarDeviceIns = Slist.deepClone(false);
            for (TargetingDeviceAssociation__c targeting : tarDeviceIns){
                targeting.Targeting__c      = newProdsTargMap.get(oldProdsTargMap.get(targeting.Targeting__c));
                targeting.TargetDevice__c   = targeting.Targeting__c + '' + targeting.Device__c;
                System.debug('\n\nClonedTargetingDeviceAssociation: ' + targeting + '\n\n');
            }
        }

        if (!tarDeviceIns.isEmpty()) {
            insert tarDeviceIns;
        }
    }

    private static void cloneProducts_ContentTargeting(Map<Id, Id> oldProdsTargMap, Map<Id, Id> newProdsTargMap){
        String queryFrom    = 'From TargetingContentAssociation__c where Targeting__c IN ('+ setToString(oldProdsTargMap.keySet()) + ')';
        List<sObject> Slist = getSObject('TargetingContentAssociation__c', queryFrom);

        List<TargetingContentAssociation__c> tarContentIns = new List<TargetingContentAssociation__c>();
        if(!Slist.isEmpty()) {
            tarContentIns = Slist.deepClone(false);
            for (TargetingContentAssociation__c targeting : tarContentIns){
                targeting.Targeting__c          = newProdsTargMap.get(oldProdsTargMap.get(targeting.Targeting__c));
                targeting.Target_Content_Key__c = targeting.Targeting__c + '' + targeting.TargetingContent__c;
                System.debug('\n\nClonedTargetingContentAssociation: ----- ' + targeting + '\n\n');
            }
        }

        if (!tarContentIns.isEmpty()) {
            insert tarContentIns;
        }
    }

    private static void cloneProducts_ConnectionTargeting(Map<Id, Id> oldProdsTargMap, Map<Id, Id> newProdsTargMap){
        String queryFrom    = 'From TargetingConnectionAssociation__c where Targeting__c IN ('+ setToString(oldProdsTargMap.keySet()) + ')';
        List<sObject> Slist = getSObject('TargetingConnectionAssociation__c', queryFrom);
        
        List<TargetingConnectionAssociation__c> tarConnectionIns = new List<TargetingConnectionAssociation__c>();
        if (!Slist.isEmpty()) {
            tarConnectionIns = Slist.deepClone(false);
            for (TargetingConnectionAssociation__c targeting : tarConnectionIns){
                targeting.Targeting__c          = newProdsTargMap.get(oldProdsTargMap.get(targeting.Targeting__c));
                targeting.TargetConnection__c = targeting.Targeting__c + '' + targeting.Connection__c;
                System.debug('\n\nClonedTargetingConnectionAssociation: ---- ' + targeting + '\n\n');
            }
        }

        if (!tarConnectionIns.isEmpty()) {
            insert tarConnectionIns;
        }
    }


    private static void cloneProducts_GeographyTargeting(Map<Id, Id> oldProdsTargMap, Map<Id, Id> newProdsTargMap){
        String queryFrom    = 'From TargetingGeographyAssociation__c where Targeting__c IN ('+ setToString(oldProdsTargMap.keySet()) + ')';
        List<sObject> Slist = getSObject('TargetingGeographyAssociation__c', queryFrom);
        
        List<TargetingGeographyAssociation__c> tarGeographyIns = new List<TargetingGeographyAssociation__c>();
        if (!Slist.isEmpty()) {
            tarGeographyIns = Slist.deepClone(false);

            for (TargetingGeographyAssociation__c targeting : tarGeographyIns){
                targeting.Targeting__c          = newProdsTargMap.get(oldProdsTargMap.get(targeting.Targeting__c));
                targeting.TargetGeography__c    = targeting.Targeting__c + '' + targeting.Geography__c;
                System.debug('\n\nClonedTargetingGeographyAssociation: ---- ' + targeting + '\n\n');
            }
        }

        if (!tarGeographyIns.isEmpty()) {
            insert tarGeographyIns;
        }
    }

    private static void cloneProducts_KeyvalueTargeting(Map<Id, Id> oldProdsTargMap, Map<Id, Id> newProdsTargMap){
        String queryFrom    = 'From TargetingKeyValueAssociation__c where Targeting__c IN ('+ setToString(oldProdsTargMap.keySet()) + ')';
        List<sObject> Slist = getSObject('TargetingKeyValueAssociation__c', queryFrom);
        
        List<TargetingKeyValueAssociation__c> tarKeyIns = new List<TargetingKeyValueAssociation__c>();        
        if(!Slist.isEmpty()){
            tarKeyIns = Slist.deepClone(false);

            for (TargetingKeyValueAssociation__c targeting : tarKeyIns){
                targeting.Targeting__c          = newProdsTargMap.get(oldProdsTargMap.get(targeting.Targeting__c));
                targeting.targetkeyvalue__c     = targeting.Targeting__c + '' + targeting.DART_KeyValue__c;
                System.debug('\n\nClonedTargetingKeyValueAssociation: ---- ' + targeting + '\n\n');
            }
        }

        if (!tarKeyIns.isEmpty()) {
            insert tarKeyIns;
        }
    }

    private static void cloneProducts_PlacementTargeting(Map<Id, Id> oldProdsTargMap, Map<Id, Id> newProdsTargMap){
        String queryFrom    = 'From PlacementTargetingAssociation__c where Targeting__c IN ('+ setToString(oldProdsTargMap.keySet()) + ')';
        List<sObject> Slist = getSObject('PlacementTargetingAssociation__c', queryFrom);

        List<PlacementTargetingAssociation__c> listPlacementTarAsso = new List<PlacementTargetingAssociation__c>(); //SOTHEA 24 OCT 2016 #9969 
        if(!Slist.isEmpty()){
            listPlacementTarAsso = Slist.deepClone(false);
            for (PlacementTargetingAssociation__c plcTar : listPlacementTarAsso){
                plcTar.Name         = null;
                plcTar.Targeting__c = newProdsTargMap.get(oldProdsTargMap.get(plcTar.Targeting__c));
                plcTar.Placement__c = plcTar.Placement__c;
                System.debug('\n\nClonedPlacementTargetingAssociation: ---- ' + plcTar + '\n\n');
            }
        }

        if (!listPlacementTarAsso.isEmpty()) {
            insert listPlacementTarAsso;
        }
    }

    
    /**
     * Get list of sObjects
     * @param sObjectName, qeueryFrom
     * @return List<sObject>
     */
    public static List<sObject> getSObject(String sObjectName, String queryFrom) {
        
        Schema.DescribeSObjectResult r;

        // Get the sObject describe result for the Opportunity object
        if (sObjectName == 'Opportunity') {
            r = Opportunity.sObjectType.getDescribe();
        }else if (sObjectName == 'OpportunityLineItem') {
            r = OpportunityLineItem.sObjectType.getDescribe();
        }else if (sObjectName == 'Targeting__c') {
            r = Targeting__c.sObjectType.getDescribe();
        }else if (sObjectName == 'TargetingContentAssociation__c') {
            r = TargetingContentAssociation__c.sObjectType.getDescribe();
        }else if (sObjectName == 'TargetingDeviceAssociation__c') {
            r = TargetingDeviceAssociation__c.sObjectType.getDescribe();
        }else if (sObjectName == 'TargetingKeyValueAssociation__c') {
            r = TargetingKeyValueAssociation__c.sObjectType.getDescribe();
        }else if (sObjectName == 'TargetingGeographyAssociation__c') {
            r = TargetingGeographyAssociation__c.sObjectType.getDescribe();
        }else if (sObjectName == 'TargetingConnectionAssociation__c') {
            r = TargetingConnectionAssociation__c.sObjectType.getDescribe();
        }
        //SOTHEA 24 OCT 2016 #9969
        else if (sObjectName == 'PlacementTargetingAssociation__c') { 
            r = PlacementTargetingAssociation__c.sObjectType.getDescribe();
        }else if(sObjectName == 'Attachment') {
            r = Attachment.sObjectType.getDescribe();
        }

        //Generate a Map of the fields
        Map<String, Schema.SObjectField> sObjFieldsMap = r.fields.getMap();
        List<String> objFields  = new List<String>(sObjFieldsMap.keySet());
        
        String query = 'Select ' + String.join(objFields, ', ');

        //Append the FROM and WHERE clause, using LIMIT 1 as an example
        query += ' ' + queryFrom;
        //Execute SOQL
        System.debug('\n\n SOQL ---: ' + query + '\n\n');

        List<sObject> soList = Database.query(query);
        return soList;
    }
    
    private static String setToString(Set<Id> idSet) {
        String idString = '';
        for (Id i : idSet) {
            if (idString != '') idString += ',';
            idString += '\'' + String.valueOf(i) + '\'';
        }
        return idString;
    }
    
}
