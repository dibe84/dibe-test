public class PGC_Subscription {

	// Subscription object 
	public Subscription mainSubscription { get; set; }
	public Rev__c master { get { return mainSubscription.master; } private set; } // is this necessary
	public Rev__c currentRevenue { get; set; } // Placeholder for newly created / being edited revenue item in UI
	public Opportunity opp { get; set; }
	public Account oppAcc { get; set; }
	// Placeholder for conditional rendering
	public String currentMode { get; set; }
	// Placeholder for parameter passing in action functions
	public Id chosenRevId { get; set; }

	public PGC_Subscription(ApexPages.StandardController stdController) {
		// Get source revenue item
		currentRevenue = (Rev__c) UTIL.getCached(stdController.getId());
		// Create main subscription object
		this.mainSubscription = new Subscription(currentRevenue.Id);
		// Get master opportunity
		this.opp = (Opportunity) UTIL.getCached(currentRevenue.Opportunity__c);
		// Get master account
		this.oppAcc = (Account) UTIL.getCached(opp.AccountId);
		// Update the conditional rendering placeholder
		this.currentMode = '';
	}

	public void setDefaultTerminationDate() {
		// Set default termination date
		if(mainSubscription.StartDate > System.today()) {
			currentRevenue.TerminationDate__c = mainSubscription.StartDate;
		} else {
			currentRevenue.TerminationDate__c = System.today();
		}
	}

	public void calculate() {
		UTIL_Log.start();
        currentRevenue.UnitPrice__c = null;
            
        currentRevenue.Predecessor__c = null;
		if (currentRevenue.From_Date__c == null) {
			currentRevenue.From_Date__c = System.today().addDays(1);
		}
		if (currentRevenue.BundleSize__c == null && mainSubscription.master.BundleSize__c != null) {
			currentRevenue.BundleSize__c = mainSubscription.master.BundleSize__c;
		}

		try {
			Integer bundleSize = Integer.valueOf(currentRevenue.adj_BundleSize__c != null ? currentRevenue.adj_BundleSize__c : currentRevenue.BundleSize__c);
			Subscription.validateBundleSize(mainSubscription.revItems[0].Product__c,opp.Pricebook2Id,bundleSize);
			mainSubscription.calculate(currentRevenue);
		} catch(Exception ex) {
			ApexPages.addMessages(ex);
		}
	}

	public void editAdjustment() {
		currentMode = 'Edit';
		currentRevenue = (Rev__c) UTIL.getCached(chosenRevId);
	}

	public void newAdjustment() {
		currentMode = 'New';
		currentRevenue = mainSubscription.createNewAdjustment();
	}

	public void deleteAdjustment() {
		try {
			mainSubscription.deleteAdjustment(chosenRevId);
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'The revenue has been successfully deleted.'));
		}
		catch(Exception ex) {
			ApexPages.addMessages(ex);
		}
		// Reload wrapper  
		mainSubscription = new Subscription(master.Id);
	}

	public void terminateSubscription() {
		try {
			mainSubscription.terminate(currentRevenue.TerminationDate__c, currentRevenue.TerminationReason__c , currentRevenue.PlatformDeactivationDate__c );
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'The subscription is successfully terminated.'));
		} catch(Exception ex) {
			ApexPages.addMessages(ex);
			UTIL_Log.d('XX ex stack trace:',ex.getStackTraceString());
		}
	}

    public void terminateAndDoNotInvoiceSubscription() {
        try {
            mainSubscription.terminate(currentRevenue.TerminationDate__c, currentRevenue.TerminationReason__c, true, currentRevenue.DoNotInvoiceReason__c, currentRevenue.PlatformDeactivationDate__c);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'The subscription is successfully terminated, and no invoices will be send anymore.'));
        } catch(Exception ex) {
            ApexPages.addMessages(ex);
        }
    }

	public void saveAdjustment() {
		try {
			if(currentRevenue.UnitPrice__c == NULL || String.valueOf(currentRevenue.UnitPrice__c) == '') {
				currentRevenue.UnitPrice__c = currentRevenue.CustomListPrice__c;
			}
			Integer bundleSize = Integer.valueOf(currentRevenue.adj_BundleSize__c != null ? currentRevenue.adj_BundleSize__c : currentRevenue.BundleSize__c);
			Subscription.validateBundleSize(mainSubscription.revItems[0].Product__c,opp.Pricebook2Id,bundleSize);
			mainSubscription.saveRev(currentRevenue);
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'The subscription is successfully saved.'));

			// Reload wrapper  
			mainSubscription = new Subscription(master.Id);
			currentRevenue = (Rev__c) UTIL.getCached(master.Id);
			currentMode = '';

		} catch(Exception ex) {
			ApexPages.addMessages(ex);
		}
	}
}