public with sharing class GW_OpportunityLineItem {

    private static final Schema.sObjectType GW_BASEOBJECT = OpportunityLineItem.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'OpportunityLineItem';


//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static OpportunityLineItem           getRecord(Id id)           { return (OpportunityLineItem) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,OpportunityLineItem>   getMap(Set<id> ids)        { return new Map<id,OpportunityLineItem>( getList(ids) ); }
    public static List<OpportunityLineItem>     getList(Set<id> ids)       { return (List<OpportunityLineItem>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of childs(base object) from a list of parent objects
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // Opportunity parent
    public static List<OpportunityLineItem>   getListFromRelated(Id parentId)        { return (List<OpportunityLineItem>) GW_sObject.getChildren(parentId, 'OpportunityLineItems'); }
    public static List<OpportunityLineItem>   getListFromRelated(Set<Id> parentIds)  { return (List<OpportunityLineItem>) GW_sObject.getChildren(parentIds, 'OpportunityLineItems'); }
    public static Set<Id>                     getIdSetFromRelated(Set<Id> parentIds) { return GW_sObject.getChildIds(parentIds, 'OpportunityLineItems'); }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// Price Calculation
//////////////////////////////////////////////////////////////////////////////////////////////////////

    public static void applyPriceModel(OpportunityLineItem oli){
        PriceCalculator.applyPriceModel(oli);
    }

    public static OpportunityLineItem createSObject(Opportunity opp, PricebookEntry pbe, Decimal quantity, Decimal unitPrice) {
        Date startDate = Date.today();
        UTIL.cacheUncachedRecords(new set<ID>{opp.Id,pbe.Id,pbe.Product2Id,opp.AccountId,opp.MemberUnit__c});
        Product2 prod = (Product2) UTIL.getCached(pbe.Product2Id);
        Account relatedAcc = (Account) UTIL.getCached(opp.AccountId);
        pbe.Product2 = prod;
        MemberUnit__c mu = (MemberUnit__c) UTIL.getCached(opp.MemberUnit__c);
        OpportunityLineItem oli;
        Decimal totalPrice;
        if(relatedAcc.AccountDiscount__c != NULL){
           totalPrice = unitPrice*(100-relatedAcc.AccountDiscount__c)/100;
        }else{
          totalPrice = unitPrice;
        }
		Boolean isTrialPro = (String.isNotBlank(prod.Name) && prod.Name.containsIgnoreCase(LPC_ProductConfiguratorController.TRIAL));
        if(mu != null && mu.EnableTRACT__c) { //added null check
            oli = new OpportunityLineItem (
                OpportunityId = opp.Id,
                PricebookEntryId = pbe.Id,
                PricebookEntry = pbe,
                Quantity = quantity,
                from_date__c = startDate,
                until_Date__c = isTrialPro?startDate.addMonths(1).addDays(-1):startDate.addMonths(1),
                TotalPrice = totalPrice,
                AccountDiscount__c = relatedAcc.AccountDiscount__c,
                UPCF__c = 1,
                ListPrice__c = unitPrice,
                SalesPriceNet__c = totalPrice
            );
			PriceCalculator.applyPriceModel(oli);
        }
        else {
            Advertising_Medium__c am = (Advertising_Medium__c) GW_sObject.queryRecord('Advertising_Medium__c', prod.Advertising_Medium__c);
            String firstBillingCatCalc = '';
            String bCat = '';
            String bCalc = '';
            if (prod.Billing_Category__c != null) {
                firstBillingCatCalc = prod.Billing_Category__c.split(';')[0];
                bCat = firstBillingCatCalc.split('_')[0];
                bCalc = firstBillingCatCalc.split('_')[1];
            }

            oli = new OpportunityLineItem (
                OpportunityId = opp.Id,
                PricebookEntryId = pbe.Id,
                PricebookEntry = pbe,
                Quantity = quantity,
                Billing_Category__c = bCat,
                BillingCalc__c = bCalc,
                FC_Quantity__c = am!=null?am.FC_Quantity__c:0,
                FC_Period__c = am!=null?am.FC_Period__c:'',
                FC_Ad_served_every__c = am!=null?am.FC_Ad_served_every__c:null,
                AdKeywords__c = prod.AdServer_Keywords_Key_Values__c,
                //16-09-2016 - GIS team predefined keyvalue should be add to AdKeywords__c only & added two new predefined fields (Predefined_DeviceCategory__c, Predifined_Adunit__c)
                //KeyValueString__c = String.isBlank(prod.AdServer_Keywords_Key_Values__c)?'':prod.AdServer_Keywords_Key_Values__c,
                Predefined_Adunit__c = prod.PredifinedAdunit__c!=null?(prod.PredifinedAdunit__c+'').subString(0, 15):null,
                Predefined_DeviceCategory__c = prod.Device_Category__c,
                Check_Inventory__c = true,
                from_date__c = startDate,
                until_Date__c = startDate.addMonths(1),
                AccountDiscount__c = (relatedAcc.AccountDiscount__c == null ? 0 : relatedAcc.AccountDiscount__c),
                ContractDiscount__c = (opp.ContractDiscount__c == null ? 0 : opp.ContractDiscount__c)
            );

            PriceCalculator.applyPriceModel(oli);

            // TBFIXED JC - MOVE TO PRICE CALCULATOR
            // It's related to LCC pricing calculator, figure out how and why and move to price calculator
            Decimal partnerShare = opp.IndirectDiscount__c == null ? 0 : opp.IndirectDiscount__c;
            Decimal ebayShare = 100 - partnerShare;

            if(oli.CustomListPrice__c != NULL && oli.CustomListPrice__c != 0) {
                oli.SalesPriceNet__c = oli.CustomListPrice__c * (ebayShare / 100);
                oli.UnitPrice = oli.CustomListPrice__c;
            } else {
                oli.SalesPriceNet__c = oli.ListPrice__c * (ebayShare / 100);
                oli.UnitPrice = oli.ListPrice__c;
            }
        }

        return oli;
    }

    /**
     * TODO: W-000129: Creating default targeting for OLI, Targeting__c and its related list (TargetingContentAssociation__c, PlacementTargetingAssociation__c)
     * - Create PlacementTargetingAssociation__c from Product2.Placement__c
     * - Create TargetingContentAssociation__c from Product2.PredifinedAdunit__c and OLI.Rich_Line_Description__c and Available_Site__c (related list of fixed site Product2)
     * AUTHOR: Bunhor
     * CREATEDDATE: 11-Dec-15
     */
    public static List<OpportunityLineItem> configureDFPTargeting(List<OpportunityLineItem> olis) {
        olis = (olis == null) ? new List<OpportunityLineItem>() : olis;

        // Creatting Map mapTargetings, mapOLIs, and mapDartNames with theSameKey
        Map<Integer, Targeting__c> mapTargetings = new Map<Integer, Targeting__c>();
        Map<Integer, OpportunityLineItem> mapOLIs = new Map<Integer, OpportunityLineItem>();
        Map<Integer, Set<String>> mapDartNames = new Map<Integer, Set<String>>();

        // For reselect PricebookEntries
        Set<Id> setPbeId = new Set<Id>();

        Integer theSameKey = 0;
        for (OpportunityLineItem oli : olis) {
        	if (oli.id == null) { // When insert only
        		mapTargetings.put(theSameKey, new Targeting__c(Id = oli.Targeting__c));
        		mapOLIs.put(theSameKey, oli);
        		mapDartNames.put(theSameKey, new Set<String>());
        		// Adding DartName from Rich_Line_Description__c
        		if (oli.Rich_Line_Description__c != null) {
        			for (String dartName : oli.Rich_Line_Description__c.split(',')) {
        				mapDartNames.get(theSameKey).add(dartName.trim());
        			}
        		}
        		theSameKey++;

        		setPbeId.add(oli.PricebookEntryId);
        	}
        }
        // mapPbe reselect concated fields since GW_sObject.queryRecord with additionalFields not working. Ex oli.PricebookEntry.Product2.PredifinedAdunit__r.Active__c
        Map<Id, PricebookEntry> mapPbe = new Map<Id, PricebookEntry>([select id, Product2.Fixed_Site__c, Product2.Id, Product2.PredifinedAdunit__c, Product2.PredifinedAdunit__r.Active__c, Product2.Placement__c from PricebookEntry where Id in : setPbeId]);


        Set<Id> setFixedSiteProductId = new Set<Id>();
        for (PricebookEntry bpe : mapPbe.values()) {
        	if (bpe.Product2.Fixed_Site__c) setFixedSiteProductId.add(bpe.Product2.Id);
        }
        // Getting map Product2Id to DartNames from Available_Site__c, related list of fixed site Product2
        Map<id, Set<String>> mapProId2DartNames = new Map<id, Set<String>>();
        for (Available_Site__c site : [select Product__c, available_Site__r.DartName__c from Available_Site__c where Product__c in :setFixedSiteProductId and available_Site__r.DartName__c != null]) {
        	if (mapProId2DartNames.get(site.Product__c) == null) {
        		mapProId2DartNames.put(site.Product__c, new Set<String>());
        	}
        	mapProId2DartNames.get(site.Product__c).add(site.available_Site__r.DartName__c);
        }

	    // Upsert the Targetings to obtain the Ids
        upsert mapTargetings.values();

        for (Integer sameKey : mapOLIs.keyset()) {
        	OpportunityLineItem oli = mapOLIs.get(sameKey);
        	PricebookEntry pbe = mapPbe.get(oli.PricebookEntryId);

        	// Adding Targeting__c to OLI
        	oli.Targeting__c = mapTargetings.get(sameKey).id;

        	// Continue adding mapDartNames from Available_Sites, related list of fixed site product2
        	if (mapProId2DartNames.get(pbe.Product2.Id) != null) {
        		mapDartNames.get(sameKey).addAll(mapProId2DartNames.get(pbe.Product2.Id));
        	}
        }

        // Getting mapDartName2Content for creating TargetingContentAssociation__c based on DartName__c
        Set<String> setAllDartNames = new Set<String>();
        for (Integer sameKey : mapDartNames.keyset()) {
        	setAllDartNames.addAll(mapDartNames.get(sameKey));
        }
        Map<String, Content__c> mapDartName2Content = new Map<String, Content__c>();
        for (Content__c con : [select id, DartName__c from Content__c where DartName__c in :setAllDartNames and Active__c = true]) {
        	mapDartName2Content.put(con.DartName__c, con);
        }

        // List TargetingContentAssociation__c and PlacementTargetingAssociation__c for insert
        List<TargetingContentAssociation__c> lstContentAsso = new List<TargetingContentAssociation__c>();
        List<PlacementTargetingAssociation__c> lstPlacementAsso = new List<PlacementTargetingAssociation__c>();

        for (Integer sameKey : mapOLIs.keyset()) {
        	OpportunityLineItem oli = mapOLIs.get(sameKey);
        	Targeting__c tg = mapTargetings.get(sameKey);
        	PricebookEntry pbe = mapPbe.get(oli.PricebookEntryId);

        	// Creating TargetingContentAssociation__c from predefined
        	if (pbe.Product2.PredifinedAdunit__c != null && pbe.Product2.PredifinedAdunit__r.Active__c) {
        		TargetingContentAssociation__c contentAsso = new TargetingContentAssociation__c(Targeting__c = tg.Id, TargetingContent__c = pbe.Product2.PredifinedAdunit__c);
        		lstContentAsso.add(contentAsso);
        	}

        	// create PlacementTargetingAssociation__c from predefined
        	if (pbe.Product2.Placement__c != null) {
        		PlacementTargetingAssociation__c plcAsso = new PlacementTargetingAssociation__c(Targeting__c = tg.Id, Placement__c = pbe.Product2.Placement__c);
        		lstPlacementAsso.add(plcAsso);
        	}

        	// Creating TargetingContentAssociation__c from oli.Rich_Line_Description__c and fixed site products' available sites (Dart Name)
    		for (String dartName : mapDartNames.get(sameKey)) {
    			Content__c con = mapDartName2Content.get(dartName);
        		if (con != null && con.Id != pbe.Product2.PredifinedAdunit__c) { // (con.Id != pbe.Product2.PredifinedAdunit__c) >>> never create the same content twice.
        			TargetingContentAssociation__c contentAsso = new TargetingContentAssociation__c(Targeting__c = tg.Id, TargetingContent__c = con.Id);
        			lstContentAsso.add(contentAsso);
        		}
        	}
        }

        insert lstContentAsso;
        insert lstPlacementAsso;

        return olis;
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////
//  Test Factory
//////////////////////////////////////////////////////////////////////////////////////////////////////

    public static OpportunityLineItem insertSObject(Opportunity opp, PricebookEntry pbe, Decimal quantity, Decimal unitPrice) {
        OpportunityLineItem oli = new OpportunityLineItem
            (
                OpportunityId = opp.Id,
                PricebookEntryId = pbe.Id,
                Quantity = quantity,
                SalesPriceNet__c = unitPrice,
                UnitPrice = unitPrice
            );
        insert oli;
        return oli;
    }


// status calculator
    public static Boolean setStatus(OpportunityLineItem oli) {
        // set general status
        StatusCalculator.IStatusCalculator statusCalc = new AdSalesOliStatusCalculator(oli);
        return statusCalc.setStatus(oli);
    }
    public class AdSalesOliStatusCalculator extends StatusCalculator.AbstractStatusCalculator {
        // constructor
        public AdSalesOliStatusCalculator(OpportunityLineItem oli) {
            super(oli, new Map<Integer, String>{-1 => 'Lost', 0 => 'Draft', 1 => 'Approved', 2 => 'Signed', 3 => 'Scheduled', 4 => 'Running', 5 => 'Finished' });
        }

        public override Boolean passCriteria(sObject so, Integer stage) {
            OpportunityLineItem oli = (OpportunityLineItem) so;
            Opportunity parentOpp = (Opportunity) UTIL.getCached(oli.OpportunityId);
            Date tday = Date.today();
            if (stage==-1) return true; //Lost
            if (stage==0){ if ( parentOpp.LostReason__c == null) return true;} // Draft
            if (stage==1) { if( parentOpp.NumStatus__c>0) return true;}     // Approved
            if (stage==2) { if( parentOpp.NumStatus__c>1) return true;}     // Signed
            if (stage==3) { if(
	                (!String.isBlank(parentOpp.Tract_Order_Number__c) && !String.isBlank(oli.UniqueLocalBookingId__c)) || 
	                !String.isBlank(oli.Ad_Id__c) || 
	                parentOpp.ActiveExternalSubscription__c ||
	                (String.isBlank(parentOpp.Tract_Order_Number__c) && parentOpp.NumStatus__c>2)
                ) return true;  }  // Scheduled
            if (stage==4) { if( oli.from_Date__c <= tday) return true; }   // Running
            if (stage==5) { if( oli.until_Date__c < tday || parentOpp.MinRevStatus__c > 4) return true; }    // Finished
            return false;
        }

    }

    public static String getDefaultLineItemDescription( Opportunity opp , OpportunityLineItem oli ) {

        PricebookEntry pbe = (PricebookEntry) UTIL.getCached(oli.PricebookEntryId);
        Product2 prod = (Product2) UTIL.getCached(pbe.Product2Id);

        /*
        *   JIRA Ticket CD-867 - Customizing default line item description
        */
        String description = prod.Name.left(150);
        if (prod.DefaultLineDescription__c != null) {
        	description = UTIL_StringParser.parseAndReplace(prod.DefaultLineDescription__c,oli).left(150);
        	if( opp.MemberId__c == 'ECITA' && oli.BundleSize__c >= 9999 ){
        		Integer lastIndex = description.lastIndexOf( '-' );
       			description = description.substring( 0 , lastIndex + 1 ) + ' annunci illimitati';
            }
        }
        return description;
    }

    public static void checkStatusChangeAndUpdate(List<OpportunityLineItem> olis) {
        List<Opportunity> opps;
        List<OpportunityLineItem> olisToUpdate = new List<OpportunityLineItem>();

        if (!olis.isempty() ) {
            UTIL.cache(olis);
            UTIL.cacheUncachedRecords(GW_sObject.getParentIds(olis, 'OpportunityId'));

            for (OpportunityLineItem oli : olis) {
                if ( GW_OpportunityLineItem.setStatus(oli) ) { olisToUpdate.add(oli); }
            }

            try {
                update olisToUpdate;
            } catch(Exception ex) {
                UTIL.throwError('GW_OpportunityLineItem.checkStatusChangeAndUpdate(): Error updating OLIs: ',ex);
            }
        }
    }

	public static void updateLineItem4Future(Set<ID> oppIds){
    	List<OpportunityLineItem> lstOplis = getListFromRelated(oppIds);
        Integer periods = 0 ;
    	for(OpportunityLineItem opli: lstOplis){
            if (opli.SetEndDate__c) {
                periods             = opli.from_Date__c.daysBetween(opli.until_Date__c);
                opli.until_Date__c  = System.today().addDays(periods);
            } else {
                opli.until_Date__c  = System.today().addMonths(2).toStartOfMonth().addDays(-1);
            }

    		opli.from_Date__c       = System.today();
    	}
    	if(!lstOplis.isEmpty()){
    		update lstOplis;
    	}
    }
	public static Decimal getAdsaleRate(OpportunityLineItem oli) {
		Integer factor = oli.Billing_Category__c == 'CPM' ? 1000 : 1;
		return (oli.ListPrice__c + oli.ListPriceCorrectionForm__c)/factor;
	}

}