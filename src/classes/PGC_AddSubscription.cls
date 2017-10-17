public with sharing class PGC_AddSubscription {

	public Opportunity opp { get; set; }
	public OpportunityLineItem oli { get; set; }
	public Id oliId {get;set;}
	public PriceBookEntry selectedPBE { get; set; }
	public Boolean isTractEnabled{get; set;}
	public Account acc;

    public static final String NEGATIVE_PRICE_ERR_MSG = 'Net Price can not be negative.';

	private List<PriceBookEntry> pbentries;
	private List<PriceBook2> pbooks;

	public PageReference redirect() {
		oliId = ApexPages.currentPage().getParameters().get('id'); // if existing oli, this should not be NULL
		String noOverride = ApexPages.currentPage().getParameters().get('nooverride');

		if (noOverride == '1' && oliId != null) {
			return new PageReference('/' + oliId + '/e?nooverride=1');
		}
		else {
			return null;
		}
	}

	public PGC_AddSubscription(ApexPages.StandardController stdController) {
		Id oppId = (Id) ApexPages.currentPage().getParameters().get('oppId');
		this.opp = GW_Opportunity.getRecord(oppId, new List<String>{'MemberUnit__r.EnableTRACT__c'});

		// Load
		loadPricebooks();
		loadPBEEntries();

		//Somehow this isn't stored when redirect has been called..
		oliId = ApexPages.currentPage().getParameters().get('id');
		if (oliId != null){
			oli = (OpportunityLineItem) GW_sObject.queryRecord('OpportunityLineItem', oliId);
			setSelectedPBE();
		}
		else{
			UTIl.log('NEW OLI!!');
			// Create placeholder oli
			if(pbentries.size() > 0) {
				oli = GW_OpportunityLineItem.createSObject(opp,pbentries[0],1,pbentries[0].UnitPrice);
			} else {
				oli = new OpportunityLineItem(OpportunityId = this.opp.Id, Quantity = 1.0);
			}
			calculate();
		}
		if (opp.AccountId != null) acc = getAccountById(opp.AccountId);
        isTractEnabled = isTractEnbale();
        if(isTractEnabled)showErrMsg();
	}

	public boolean getOppHasNoProducts() {
		List<OpportunityLineItem> oppLines = GW_sObject.getChildren(new Set<Id> { opp.Id }, 'OpportunityLineItems');
		return oppLines.isEmpty();
	}

	public void setSelectedPBE() {
		selectedPBE = (PricebookEntry) UTIL.getCached(oli.PriceBookEntryId);
	}

	public void calculate() {
		setSelectedPBE();
		Subscription.calculateSubscriptionFields(opp, oli, selectedPBE);
	}

    public void calculateEndDate() {
        PricebookEntry pbe = (PricebookEntry) UTIL.getCached(oli.PriceBookEntryId);
        Subscription.calculateEndDate(oli, pbe);
    }

	public void loadPBEEntries() {
		pbentries = new List<PriceBookEntry> ();
		if(opp.Pricebook2Id != null) {
			pbentries = GW_sObject.queryRecords('PricebookEntry','Pricebook2Id = \'' + opp.Pricebook2Id + '\' AND IsActive = TRUE AND Product2.IsActive = TRUE ORDER BY ListOrder__c ASC');
		}
	}



	public List<SelectOption> getPBEItems() {

		List<SelectOption> options = new List<SelectOption> ();
		for (PricebookEntry pbe : pbentries) {
			options.add(new SelectOption(pbe.Id, pbe.Name));
		}
		return options;
	}

	public List<SelectOption> getPBItems() {

		List<SelectOption> options = new List<SelectOption> ();
		for (Pricebook2 pb : pbooks) {
			options.add(new SelectOption(pb.Id, pb.Name));
		}
		return options;
	}

	private void loadPricebooks() {
		pbooks = GW_sObject.queryRecords('PriceBook2', 'Name LIKE \'%' + opp.MemberUnitId__c + '%\' AND IsActive = TRUE ORDER by ListOrder__c ASC');

		if (opp.Pricebook2Id == null) {
			opp.Pricebook2Id = !pbooks.isEmpty() ? pbooks[0].Id : null;
		}
	}

	public PageReference cancel() {
		return new PageReference('/' + opp.Id);
	}

	public PageReference save() {
        if (oli.SalesPriceNet__c >= 0) {
            try{
                update opp;
                Subscription.placeSubscriptionOrder(oli);
            }
            catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, NEGATIVE_PRICE_ERR_MSG));
            return null;
        }

		//  After Save, navigate to the default view page:
		return(new ApexPages.StandardController(opp)).view();
	}
	public Boolean isTractEnbale () {
        if (acc != null && acc.MemberId__c != null) {
            return acc.Member__r.DefaultMemberUnit__r.EnableTRACT__c;
        } else if (opp != null) {
            return opp.MemberUnit__r.EnableTRACT__c;
        }
        return false;
    }
    private Account getAccountById(String accId) {
        if (String.isEmpty(accId)) return null;
        List<Account> listAccs = [SELECT MemberId__c,Tract_AccountId__c,Member__r.DefaultMemberUnit__r.EnableTRACT__c, Finance_contact__c 
                                  FROM Account WHERE id =:accId];
        return listAccs.size() > 0 ? listAccs.get(0) : null;
    }
    private void showErrMsg(){
    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Account is enabled for tract, please use salespath to add product.'));
    }
}