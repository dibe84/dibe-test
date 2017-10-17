public with sharing class PGC_AdjustRevenueDates {
	public List<Rev__c> revs { get; set; }
	public Opportunity opp { get; set; }
	public Id oppId { get; set; }
	public Boolean showMessages { get; set; }
	public List<echosign_dev1__SIGN_Agreement__c> agreements { get; set; }

	public PGC_AdjustRevenueDates() {
		this.load();
		// If we have no Rev's which are invoiced, and the user has custom permission "Adjust Uninvoiced Revenue Dates" then we show him this page.
		Boolean foundSentToBilling = false;
		for (Rev__c rev : this.revs) {
			if (rev.MaxRSStatus__c > 6) { // RS is before sent to billing
				foundSentToBilling = true;
			}
		}

		if (foundSentToBilling == true) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'This Opportunity contains one or more Revenue Items which are already marked as partially "Sent To Billing", this means that unfortunately you will not be able to edit these revenue items any longer.'));
			this.revs = null;
			this.showMessages = true;
			return;
		} else {
			if (GW_User.hasCustomPermission('AdjustUninvoicedRevenueDates') == false) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You do not have permission to edit Revenue Item start and end dates through this page.'));
				this.revs = null;
				this.showMessages = true;
				return;
			} else {

			}
		}
	}

	public PageReference save() {
		try {
			update this.revs;
			GW_RS.syncRSFromRevs(this.revs);
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Changes saved successfully'));
			this.showMessages = true;
		} catch (Exception e) {
			this.showMessages = true;
		}
		this.load();
		return null;
	}

	public void load() {
		this.revs = new List<Rev__c>();
		this.oppId = ApexPages.currentPage().getParameters().get('id');
		this.opp = (Opportunity) UTIL.getCached(this.oppId);
		for (Rev__c rev : GW_Revenue.getListFromRelated(this.oppId)) {
			if (rev.Type__c == 'Master') {
				this.revs.add(rev);
			}
		}
		if (this.revs.size() == 0) {
			this.revs = null;
		}
		this.agreements = GW_sObject.queryRecords('echosign_dev1__SIGN_Agreement__c', 'echosign_dev1__Opportunity__c = \'' + this.oppId + '\'');
	}
}