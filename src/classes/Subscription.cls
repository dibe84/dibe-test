public class Subscription {

    //SUBSCRIPTION SALES METHODS
    public static OpportunityLineItem createSubscriptionOLI(Opportunity opp, PricebookEntry pbe) {
        OpportunityLineItem oli = GW_OpportunityLineItem.createSObject(opp, pbe, 1, pbe.UnitPrice);
        calculateSubscriptionFields(opp, oli, pbe);
        return oli;
    }

    public static void calculateSubscriptionFields(Opportunity opp, OpportunityLineItem oli, PricebookEntry pbe) {
       
        system.debug('>>>>>>>>>>>>>>>>');
        system.debug(pbe);

        Product2 prod = (Product2) UTIL.getCached(pbe.Product2Id);
        oli.SalesPriceNet__c = null;
        oli.BillingCalc__c = PriceCalculator.getBillingCalculation(prod);
        oli.Billing_Category__c = PriceCalculator.getBillingCategory(prod);
        oli.ContractDiscount__c = opp.ContractDiscount__c;
        if(oli.from_Date__c != null) {
            GW_OpportunityLineItem.applyPriceModel(oli);
        }
        calculateEndDate(oli, pbe);
    }

    public static void calculateEndDate(OpportunityLineItem oli, PricebookEntry pbe) {
        Product2 prod = (Product2) UTIL.getCached(pbe.Product2Id);
		if (oli.from_Date__c != null) {
            Integer contractPeriod = (prod.ContractPeriodInMonths__c == null ? 1 : (Integer)prod.ContractPeriodInMonths__c);
			oli.until_Date__c = oli.from_Date__c.addMonths(contractPeriod)-1;
		}
    }

    public static void placeSubscriptionOrder(OpportunityLineItem oli) {
        if ((oli.from_Date__c == null || oli.BundleSize__c == null || oli.PricebookEntryId == null) && oli.PriceCalculator__c == 'IterativeTiered') {
			throw new UTIL.CustomException('\'Price Book Entry\', \'BundleSize\' and \'From (Date)\' are required.');
		}
		if ((oli.from_Date__c == null || oli.PricebookEntryId == null) && oli.PriceCalculator__c == 'UnlimitedFixed') {
			throw new UTIL.CustomException('\'Price Book Entry\' and \'From (Date)\' are required.');
		}

        PricebookEntry pbe = (PricebookEntry) UTIL.getCached(oli.PriceBookEntryId);
        Subscription.validateBundleSize(pbe.Product2Id,pbe.Pricebook2Id,Integer.valueOf(oli.BundleSize__c));

        if (![Select Id From ProcessInstance WHERE TargetObjectId = :oli.OpportunityId AND Status = 'Pending'].isEmpty()) {
            throw new UTIL.customException('It is not allowed to change the opportunity product while pending for approval. First \'Recal Approval Request\' if you do want to make a change. (See Approval History section)');
        }

		try {
			oli.UnitPrice = oli.SalesPriceNet__c;
			upsert(oli);
		} catch(System.DMLException e) {
			throw new DMLException('An error occurred while recording the subscription. Please, check the catalyst logs for more info.' + e.getMessage() + e.getStackTraceString());
		}
    }

    //END SUBSCRIPTION SALES METHODS

    public Rev__c master;
    //To be able to check product properties for allowed adjustment behaviour.
    public Product2 masterProd;
    public Opportunity opp;
    public OpportunityLineItem oli;
    public Date startDate { get { return this.master.From_Date__c;} }
    public Date subscriptionEndDate;
    public Set<Date> untilDates {
        get { return getUntilDateSet(); }
        private set;
    }
    public List<Rev__c> revItems {
        get { return sortRevsByFromDate(revChainByDate.values()); }
        private set;
    }

    private Set<Date> getUntilDateSet() {
        Set<Date> uDates = new Set<Date>();
        for (Rev__c r : revItems) {
            if (r.Until_Date__c != null) {
                uDates.add(r.Until_Date__c);
            }
        }
        return uDates;
    }

    private List<Rev__c> sortRevsByFromDate(List<Rev__c> revItems) {
        Map<Date,Rev__c> mapRevsByDate = new Map<Date,Rev__c>();
        List<Rev__c> output = new List<Rev__c>();
        for (Rev__c rev : revItems) {
            mapRevsByDate.put(rev.From_Date__c,rev);
        }
        List<Date> dates = new List<Date>(mapRevsByDate.keySet());
        dates.sort();
        for (Date d : dates) {
            output.add(mapRevsByDate.get(d));
        }
        return output;
    }
    private Map<Date,Rev__c> revChainByDate = new Map<Date,Rev__c>();
    
    // constructor - Create Subscription from existing subscription/RI
    public Subscription(Id revId) {
        Rev__c reqRev = (Rev__c) UTIL.getCached(revId); //GW_Revenue.getRecord(revId);
        if (reqRev == null) UTIL.throwError('Not a valid Revenue Item');
        if (reqRev.Type__c != 'Master' && reqRev.Master__c == null) UTIL.throwError('Revenue item invalid');
        // init master rev
        if (reqRev.Type__c == 'Master') 
            this.master = reqRev;
        else 
            this.master = (Rev__c) UTIL.getCached(reqRev.Master__c); //GW_Revenue.getRecord(reqRev.Master__c);

        this.masterProd = (Product2) UTIL.getCached(this.master.Product__c);
		refreshRevMap();
        this.subscriptionEndDate = revItems[revItems.size()-1].Until_Date__c;
    }

//////////////////////////////////////////////
//   methods called from UI
//////////////////////////////////////////////

    public boolean getIsAdjustable() {
        return this.masterProd.DoNotAdjustSubscriptions__c;
    }

    public Rev__c createNewAdjustment() {
        Rev__c rev = new Rev__c();
        rev.Master__c = this.master.Id;
        rev.Type__c = 'Adjustment';
		rev.QuantityBooked__c = this.master.QuantityBooked__c;
        return rev;
    }

	public static void validateBundleSize(Id productId, Id pricebookId, Integer bundleSize) {
		PricebookEntry currentPbe = GW_PriceBookEntry.getPbeFromCache(productId,pricebookId);
		if (currentPbe == null) {
			throw new UTIL.CustomException('There is no pricebook entry matching provided product & pricebook ids.');
		}
		// Validate minimum bundle size
		if (bundleSize < currentPbe.minBundleSize__c) {
			throw new UTIL.CustomException('Minimum bundle size for this product is: ' + currentPbe.minBundleSize__c + '. Please update the subscription.');
		}
		// Validate maximum bundle size
		if (bundleSize > currentPbe.maxBundleSize__c) {
			throw new UTIL.CustomException('Maximum bundle size for this product is: ' + currentPbe.maxBundleSize__c + '. Please update the subscription.');
		}
	}

    public void calculate(Rev__c rev) {
        Rev__c predecessor = rev.Predecessor__c!=null?(Rev__c)UTIL.getCached(rev.Predecessor__c):getActiveRevAtDate(rev.From_Date__c);
        // do general checks
        if ( rev.From_Date__c == null ) 						throw new UTIL.CustomException('Adjustment Date not specified');
        if ( rev.From_Date__c <= master.LastBilledDate__c )  	throw new UTIL.CustomException('Subscription has been billed until: '+master.LastBilledDate__c+' You can only adjust after this date.');
        // if ( rev.BundleSize__c == null && rev.adj_BundleSize__c == null)	throw new UTIL.CustomException('Invalid bundleSize selected'); // tbfixed
        
        if (rev.Id == null) initNewAdjustedRev(rev, predecessor);

        GW_Revenue.calcEffectiveFields(rev, predecessor);
        GW_Revenue.applyPriceModel(rev);
    }
    
    public void saveRev(Rev__c rev) {
    	if (rev.Id != null) {
			updateRev(rev);
		}
        else insertRev(rev);
    }
    
    public void deleteAdjustment(Id revId) {
    	Rev__c reqRevToDel = GW_Revenue.getRecord(revId);
        Rev__c successor; // the successor of the deleted Rev, will now become successor of the predecessor
        
        //only adjustment rev items can be deleted
        if (reqRevToDel.Type__c == 'Master') throw new UTIL.CustomException('Master Revenue Item cannot be deleted.');
        if (reqRevToDel.predecessor__c == null) throw new UTIL.CustomException('Data corrupt, adjustment record has no predecessor');
        if ( reqRevToDel.From_Date__c <= master.LastBilledDate__c ) 
            throw new UTIL.CustomException('Subscription has been billed until: '+master.LastBilledDate__c+' You cannot delete this Adjustment record.');
        
        Rev__c predecessor = GW_Revenue.getRecord(reqRevToDel.predecessor__c);
 
        if (reqRevToDel.successor__c != null) {
            successor = GW_Revenue.getRecord(reqRevToDel.successor__c);
            successor.Predecessor__c = predecessor.Id;
			predecessor.successor__c = successor.Id;
        } else {
            predecessor.successor__c = null;
        }
        
        predecessor.Until_Date__c = reqRevToDel.Until_Date__c;
        
        Savepoint sp = Database.setSavepoint();
        try {
            delete reqRevToDel;
            HNDL_Rev.cascadeDML = true;
            update predecessor;
            if (successor != null){ update successor; }
            refreshRevMap(); 
        } catch(Exception ex) {
            Database.rollback(sp);
            UTIL.log(ex.getMessage());
            throw new UTIL.CustomException('Error deleting Rev.Item: '+ex.getMessage() );
        }  
    }

    public void terminate(Date terminationDate, String reason ) {
        terminate(terminationDate, reason, false, null, null);
    }

    public void terminate(Date terminationDate, String reason, Date platformDeactivationDate ) {
        terminate(terminationDate, reason, false, null, platformDeactivationDate );
    }
  
	public void terminate(Date terminationDate, String reason, boolean setDoNotInvoiceTrue, String doNotInvoiceReason, Date platformDeactivationDate){
        // checks
        if (terminationDate == null ){
            throw new UTIL.CustomException('Termination date not specified');
        }
        if (terminationDate <= master.LastBilledDate__c){
            throw new UTIL.CustomException('Subscription has been billed until: '+master.LastBilledDate__c+' You can only terminate after this date.');
        }
        //if ( (master.SubscriptionEndDate__c != null && terminationDate > master.SubscriptionEndDate__c) ){
        //    throw new UTIL.CustomException('Subscription runs until: '+master.SubscriptionEndDate__c+' You can only terminate before this date.');
        //}
        if ((terminationDate > this.subscriptionEndDate)){
            throw new UTIL.CustomException('Subscription runs until: '+this.subscriptionEndDate+' You can only terminate before this date.');
        }
		if(terminationDate < master.From_Date__c){
			throw new UTIL.CustomException('Termination date cannot be earlier than: '+master.From_Date__c+'. You can only terminate at or after this date.');
		}

        // deprecated with CD-3365
        /*if (master.BillingCalc__c == 'MultiMonth' && !untilDates.contains(terminationDate)) {
            throw new UTIL.CustomException('MultiMonth subscriptions cannot be terminated halfway as they are invoiced upfront, ' +
                                            'please fill in the until date of the revenue item to terminate it at the end of the contract term instead.');
        }*/
        if (setDoNotInvoiceTrue && doNotInvoiceReason == null) {
            throw new UTIL.CustomException('Please specify a reason for not wanting to invoice anymore for this subscription.');
        }

        /* 
        * CD-787 - Removal of this limitation
        */
        //if(terminationDate < System.today()) {
        //    throw new UTIL.CustomException('Termination date cannot be earlier than today!');
        // }
        
        List<Rev__c> futureRevsToBeDeleted = new List<Rev__c>();
        Map<Id,Rev__c> revsToBeUpdated = new Map<Id,Rev__c>();
        Rev__c activeRev = getActiveRevAtDate(terminationDate); // will become last rev
        
        for (Rev__c rev : revItems) {
            if (rev.From_Date__c > terminationDate) {
                futureRevsToBeDeleted.add(rev);
            }
            else {
		        rev.TerminationDate__c = terminationDate;
		        rev.TerminationReason__c = reason;
            	rev.PlatformDeactivationDate__c = platformDeactivationDate;
                if (setDoNotInvoiceTrue) {
	                rev.DoNotInvoice__c = true;
	                rev.DoNotInvoiceReason__c = doNotInvoiceReason;
                }    
                revsToBeUpdated.put(rev.Id, rev);
            }
        }
    
        if (activeRev.Id == master.Id) { // master remains as only rev
            master.Until_Date__c = terminationDate;
        	master.successor__c = null;
        } else { // revActiveAtCancelationDate is different from master
            activeRev.Until_Date__c = terminationDate;
        	activeRev.successor__c = null;
            revsToBeUpdated.put(activeRev.Id, activeRev);
        }
        master.TerminationDate__c = terminationDate;
        master.TerminationReason__c = reason;
        master.PlatformDeactivationDate__c = platformDeactivationDate;
        master.SubscriptionEndDate__c = terminationDate;
        master.AutoExtend__c = FALSE;

        if (setDoNotInvoiceTrue) {

            activeRev.DoNotInvoice__c = true;
            activeRev.DoNotInvoiceReason__c = doNotInvoiceReason;

            master.DoNotInvoice__c = true;
            master.DoNotInvoiceReason__c = doNotInvoiceReason;

        }
        
        revsToBeUpdated.put(master.Id, master);
        
        Savepoint sp = Database.setSavepoint();
        try {
            if (futureRevsToBeDeleted.size()>0 ) delete futureRevsToBeDeleted;
            HNDL_Rev.cascadeDML = true;
            update revsToBeUpdated.values();
            refreshRevMap();
            GW_Account.suspendAccountOnSubscTermination( master.Opportunity__c );
        } catch(Exception ex) {
            Database.rollback(sp);
            UTIL.log(ex.getMessage());
            throw new UTIL.CustomException('Error cancelling Rev.Item: '+ex.getMessage() );
        }        
    }
    
    public List<Rev__c> recalcRevChain() { // returns changed records
		Map<Id,Rev__c> revsToBeUpdated = new Map<Id,Rev__c>();
        Rev__c rev,predecessor,successor;
        Date predOldEndDate;
        for (Integer i = 0; i < revItems.size(); i++ ) { // looping from earliest to latest rev, first one should be Master
            Date myEnddate; // start enddate for this rev 
            Boolean updRev = false;
            predecessor = successor = null;
            rev = revItems[i];
            myEnddate = rev.Until_Date__c;
            
            if (i == 0) { // Handle Master
                if (rev.Type__c != 'Master') throw new UTIL.CustomException('First record should be Master');  
            } else { // Handle Adjustments
                if (rev.Type__c != 'Adjusted') throw new UTIL.CustomException('Follow Records should be type "Adjusted"!');
                predecessor = revItems[i-1];
            }
            if (i < (revItems.size()-1) ) successor = revItems[i+1];

            if ( GW_Revenue.checkMyNeighbours(rev, predecessor, successor) )	updRev = true;        
            if (rev.Until_Date__c == null) rev.Until_Date__c = predOldEndDate; // Use predecessors initial end-date     
            if ( GW_Revenue.calcEffectiveFields(rev, predecessor) ) {
            	GW_Revenue.applyPriceModel(rev);
                updRev = true;
            }
            
            if (updRev) revsToBeUpdated.put(rev.Id,rev);
            predOldEndDate = myEnddate;
        }  
                
        return revsToBeUpdated.values();
    }

    
//////////////////////////////////////////////   
//   Private members
//////////////////////////////////////////////    
    
    private void updateRev(Rev__c rev) {
    	this.calculate(rev);
        //update rev;
        
        //this.calculate(rev);
        //Rev__c predecessor = (Rev__c) UTIL.getCached(rev.Predecessor__c);
        //Rev__c successor;
        //if (predecessor.successor__c != null) successor = (Rev__c) UTIL.getCached(predecessor.successor__c);
        
        Savepoint sp = Database.setSavepoint();
        List<Rev__c> revsToBeUpdated = new List<Rev__c>();
        try {
            update rev;
			GW_Revenue.recalcAndUpdateRevChain(rev.Id);
        } catch(Exception ex) {
            Database.rollback(sp);
            UTIL.log(ex.getMessage());
            throw new UTIL.CustomException('Error updating Rev.Item: '+ex.getMessage() );
        }     
        refreshRevMap();
    }
    
    private void insertRev(Rev__c rev) {
        this.calculate(rev);
        //Rev__c predecessor = (Rev__c) UTIL.getCached(rev.Predecessor__c);
        //Rev__c successor;
        //if (predecessor.successor__c != null) successor = (Rev__c) UTIL.getCached(predecessor.successor__c);
        
        Savepoint sp = Database.setSavepoint();
        List<Rev__c> revsToBeUpdated = new List<Rev__c>();
        try {
            insert rev;
            UTIL.log('Freshly inserted: '+rev);
			GW_Revenue.recalcAndUpdateRevChain(rev.Id);
        } catch(Exception ex) {
            Database.rollback(sp);
            UTIL.log(ex.getMessage());
            throw new UTIL.CustomException('Error updating Rev.Item: '+ex.getMessage() );
        }     
        refreshRevMap(); 
    }
    
    private void initNewAdjustedRev(Rev__c rev, Rev__c predecessor) {
        Rev__c successor; 		// the successor of the active Rev, will now succeed the new adjustment rev
        // checks for new rev
        if (revChainByDate.containsKey(rev.From_Date__c)) 	throw new UTIL.CustomException('There is already an adjustment on this date, please delete this if you would like to change it.');
   		if (predecessor == null) 							throw new UTIL.CustomException('No predecessor found');
      	
        // set successor if any
        if (predecessor.successor__c != null) successor = GW_Revenue.getRecord(predecessor.successor__c);
                
		// Set defaults for new Adjustment Rev
		rev.Type__c = 'Adjusted';
		rev.Opportunity__c = predecessor.Opportunity__c;
        rev.CurrencyIsoCode = predecessor.CurrencyIsoCode;
        rev.OliDescription__c = predecessor.OliDescription__c;
		rev.InvoiceGrouping__c = predecessor.InvoiceGrouping__c;
        //rev.OpportunityLineItemId__c = null; // should be on master only 
        //rev.ExtLineItemId__c = null; // should be on master only 
        //rev.UniqueLocalBookingId__c = null; // should be on master only 
        rev.Master__c = predecessor.Master__c!=null?predecessor.Master__c:predecessor.id;
        rev.Predecessor__c = predecessor.Id;
        if(successor != null) {
            rev.Until_Date__c = successor.From_Date__c-1;
            rev.successor__c = successor.Id;
        } else {
            rev.Until_Date__c = predecessor.Until_Date__c;
        }
    }
    private void refreshRevMap() {
        List<Rev__c> revs = GW_Revenue.getRevenueItemChain(this.master.Id);
        //this.master = GW_Revenue.getRecord(this.master.Id);
        //this.revChainByDate = new map<Date,Rev__c>{master.From_Date__c => master};
            
        for (Rev__c rev : revs) {
            // if (revChainByDate.containsKey(rev.From_Date__c) ) UTIL.throwError('Revenue item From_Date already exists for this subscription');
			// if (rev.From_Date__c <= this.master.From_Date__c ) UTIL.throwError('Revenue item From_Date cannot be before subscription start');            
			this.revChainByDate.put(rev.From_Date__c, rev);            
        }
    }

    public Rev__c getRevenueItemByFromDate(Date fromDate) {
        if(fromDate == null) throw new UTIL.CustomException('No date supplied for getRevenueItemByFromDate');
        if(this.revChainByDate == null) throw new UTIL.CustomException('revChainByDate is empty, use refreshRevMap method first.');
        return this.revChainByDate.get(fromDate);
    }

    private Rev__c getActiveRevAtDate(Date reqDate) {
        for (Rev__c rev : this.revItems) {
        	if(rev.From_Date__c <= reqDate && rev.Until_Date__c >= reqDate) return rev;   
        }
        return null;
    }

}