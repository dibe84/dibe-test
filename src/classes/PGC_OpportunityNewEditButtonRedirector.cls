/**
 * The controller of page: OpportunityNewEditButtonRedirector
 * 1. New Opportunity:
 *    + If clicked from Account page: 
 *      - IF memberUnit.tractEnabled THEN go to salespath to create a new opportunity for the account (same behaviour that the sales_path button has right now on account)
 *      - ELSE go to the standard opportunity-creation page (passing URL parameter of account to prepopulate the value as per standard behaviour) 
 *    + If clicked from Opportunity list view:
 *       - IF current user memberUnit.tractEnabled THEN user must select an account. (Note: we will list only account for this member unit that is enable tract) THEN go to salespath to create a new opportunity
 *       - ELSE go to the standard opportunity-creation page.
 * 2. Edit Opportunity:
 *    + If clicked from Opportunity or Account page:
 *      - IF memberUnit.tractEnabled THEN go to salespath page to edit the existing opportunity (same behaviour that the sales_path button has right now on opportunity)
 *      - ELSE go to the standard opportunity-edition page
 * @BUSINESS: - CD-2287 New Opportunity button - Redirect
 *            - CD-2312 New Opportunity button - Redirect part 2
 * @AUTHOR: SOTHEA HORN
 * @CREATED: 22 APRIL 2017
 */
public with sharing class PGC_OpportunityNewEditButtonRedirector {
    
    private static final String PARAM_ID = 'id';
    public static final String PARAM_EDITMODE = 'editMode';
    private static final String PARAM_RETURL = 'retURL';
    public static final String PARAM_ACCID = 'accid';
    private static final String PARAM_NOOVERRIDE = 'nooverride';
    private static final String PARAM_SELACCID = 'selAccId';
    
    private static final String PARAM_FCONTACT = 'CF00N9000000DXYms';
    private static final String PARAM_FCONTACT_LKID = 'CF00N9000000DXYms_lkid';
    private static final String OPP_STANDARD_EDIT_URL = '/006/e';
    private static final String OPP_LISTVIEW_URL = '/006';
    
    public Boolean isEditMode{get;set;}
    public Boolean isError{get;set;}
    public String errMsg{get;set;}
    public Account[] listAccsOptions{get; set;}
    public Boolean isChooseAcc{get; set;}
    public String searchStr{get; set;}
    public String selectedAccId{get;set;}
    
    public Account acc;
    public Opportunity opp;
    public Boolean fromListView;
    
    private Map<String, Account> mapAllAccs;
    private Member__c member;
    
    
    //Contructor
    public PGC_OpportunityNewEditButtonRedirector(ApexPages.StandardController stdController) {
        this.isError = false;
        this.isEditMode = true;
        this.fromListView = false;
        this.isChooseAcc = false;
        listAccsOptions = new list<Account>();
        
        String accountId = ApexPages.currentPage().getParameters().get(PARAM_ACCID);
        String oppId = stdController.getId();
        if (String.isEmpty(accountId) && String.isEmpty(oppId)) {
            fromListView = true;
            this.isEditMode = false;
        }
        String sEditMode = ApexPages.currentPage().getParameters().get(PARAM_EDITMODE);
        if (sEditMode != null) {
            isEditMode = Boolean.valueOf(sEditMode);
        } 
        if (isEditMode) {
            this.opp = (Opportunity) stdController.getRecord();
            accountId = opp.AccountId;
        }
        acc = getAccountById(accountId);
        member = GW_Member.getMember(UserInfo.getUserId());
    }
    
    /**
     * Redirect to create "New opportunity"/"Edit opportunity"
     * @RETURN  PageReference
     * @AUTHOR  SOTHEA HORN
     * @CREATED 22 APRIL 2017
     */
    public PageReference redirect() {
        if (isEditMode) {
            return editOpportunity();
        } else if (fromListView && isTractEnbale()) {
            return showAccountSelection();
        } else {
            return createNewOpportunity();
        }
    }
    
    
    /**
     * Go back to current page, eg. Account detail page or opportunity list view
     * @RETURN  PageReference
     * @AUTHOR  SOTHEA HORN
     * @CREATED 22 APRIL 2017
     */
    public PageReference goToCurrentPage() {
        PageReference cp = new PageReference(getBackToURL());
        return cp;
    }
    
    /**
     * Go to create new opportunity
     * @AUTHOR  SOTHEA HORN
     * @CREATED 01 MAY 2017
     */
    public PageReference doNext(){
        List<Account> accs = GW_Account.getList(new Set<ID>{selectedAccId}, new List<String>{'Finance_contact__r.Name','Member__r.DefaultMemberUnit__r.EnableTRACT__c'});
        if (!accs.isEmpty()){
            acc = accs[0];
            return createNewOpportunity();
        }
        return null;
    }
    
    /**
     * All result search accounts from input 
     * @AUTHOR  SOTHEA HORN
     * @CREATED 01 MAY 2017
     */
    public PageReference searchAccount(){
        listAccsOptions = filterAccounts();
        return null;
    }
    
    public PageReference setSelectedAccId(){
        selectedAccId = Apexpages.currentPage().getParameters().get(PARAM_SELACCID);  
        return null;
    }
    
    /**
     * Get standard opportunity creation/editon retURL
     * @RETURN  String
     * @AUTHOR  SOTHEA HORN
     * @CREATED 22 APRIL 2017
     */
    private String getStandardPageRedirectURL(){
        String retUrl = ApexPages.currentPage().getParameters().get(PARAM_RETURL);
        if (String.isEmpty(retUrl) && acc != null) {
            retUrl = acc.Id;
        }
        return retUrl;
    }
    
    /**
     * Get standard opportunity creation/editon page
     * @RETURN  PageReference
     * @AUTHOR  SOTHEA HORN
     * @CREATED 22 APRIL 2017
     */
    public PageReference goToStandardEditPage() {
        PageReference sdp = new PageReference(OPP_STANDARD_EDIT_URL);
        sdp.getParameters().put(PARAM_NOOVERRIDE, '1');
        sdp.getParameters().put(PARAM_RETURL, getStandardPageRedirectURL());
        if (acc != null) {
            sdp.getParameters().put(PARAM_ACCID, acc.Id);
			if(acc.Finance_contact__c != null){
				sdp.getParameters().put(PARAM_FCONTACT, acc.Finance_contact__r.Name);
				sdp.getParameters().put(PARAM_FCONTACT_LKID, acc.Finance_contact__c);
			}
		}
        if (isEditMode && opp != null) sdp.getParameters().put(PARAM_ID, opp.Id);
        return sdp;
    }
    
    /**
     * Go to sales path to create/edit an Opportunity
     * @param   objId   Account Id or Opportunity Id
     * @RETURN  PageReference
     * @AUTHOR  SOTHEA HORN
     * @CREATED 22 APRIL 2017
     */
    public PageReference goToSalesPath(String objId) {
        PageReference sp = Page.LC_SalesPathRedirector;
        sp.getParameters().put((isEditMode ? PARAM_ID : PARAM_ACCID), objId);
        sp.setRedirect(true);
        return sp;
    }
    
    /**
     * Go to Opportunity-edition page:
     * - IF opp.memberUnit.tractEnabled THEN go to salespath page to edit the existing opportunity 
     *  (same behaviour that the sales_path button has right now on opportunity)
     * - ELSE go to the standard opportunity-edition page
     * @param   objId   Account Id or Opportunity Id
     * @RETURN  PageReference
     * @AUTHOR  SOTHEA HORN
     * @CREATED 23 APRIL 2017
     */
    private PageReference editOpportunity(){
        if (opp != null && isTractEnbale()) {
            return goToSalesPath(opp.Id);
        } else {
            return goToStandardEditPage();
        }
    }
    
    public Boolean isTractEnbale () {
        if (fromListView) {
            if (acc != null) {
                return acc.Member__r.DefaultMemberUnit__r.EnableTRACT__c;
            } 
            if (opp != null) {
	            return opp.MemberUnit__r.EnableTRACT__c;
	        }
            return member.DefaultMemberUnit__r.EnableTRACT__c;
        } else if (acc != null) {
            return acc.Member__r.DefaultMemberUnit__r.EnableTRACT__c;
        } else if (opp != null) {
            return opp.MemberUnit__r.EnableTRACT__c;
        }
        return false;
    }
    
    /**
     * Go to Opportunity-creation page:
     * - IF account.member.memberUnit.tractEnabled THEN go to salespath to create a new opportunity for the account 
     *   (same behaviour that the sales_path button has right now on account)
     * - ELSE go to the standard opportunity-creation page (passing URL parameter of account to prepopulate the value as per standard behaviour)
     * @param   objId   Account Id or Opportunity Id
     * @RETURN  PageReference
     * @AUTHOR  SOTHEA HORN
     * @CREATED 23 APRIL 2017
     */
    private PageReference createNewOpportunity(){
        if (acc != null && isTractEnbale()){
			if(acc.Account_Status__c != 'Active' && acc.Account_Status__c != 'Pending'){
        		errMsg = 'Cannot create bookings for account with status ' + acc.Account_Status__c;
        		isError = true;
        		return null;
        	}
			
            if(acc.Tract_AccountId__c != null && acc.Tract_AccountId__c != ''){
                return goToSalesPath(acc.Id);
            } else { //send request to Tract to create an account and go to sales path if account create successfully in TRACT
                createTractAccount(acc.Id);
                if (!isError) return goToSalesPath(acc.Id);
                return null;
            }
        } else {
            return goToStandardEditPage();
        }
    }
    
    private PageReference showAccountSelection(){
        mapAllAccs = loadAvailableAccounts();
        listAccsOptions = mapAllAccs.values().deepClone(true, true, true);
        isChooseAcc = true;
        return null;
    }
    
    /**
     * Sending a request to create an Account in TRACT
     * @param   accId   a salesforce Account Id
     * @AUTHOR  SOTHEA HORN
     * @CREATED 23 APRIL 2017
     */
    private void createTractAccount(String accId) {
        isError = false;
        errMsg = '';
        Account acc = getAccountById(accId);
        if (!acc.MandatoryDetailsFilled__c) {
            isError = true;
            errMsg = 'Account is not ready to sell';
        }
        /*
        String rsMsg = WSC_Tract.createAccountSync(accId);
        if (rsMsg.toLowerCase().startsWith(WSC_Tract.RESPONE_SUCCESS)) {
            isError = false;
        } else {
            isError = true;
            errMsg = rsMsg;
        }*/
    }
    
    private Account getAccountById(String accId) {
        if (String.isEmpty(accId)) return null;
        List<Account> listAccs = [SELECT MandatoryDetailsFilled__c, Tract_AccountId__c, Finance_contact__r.Name, Member__r.DefaultMemberUnit__r.EnableTRACT__c, Finance_contact__c, Account_Status__c 
                                  FROM Account WHERE id =:accId];
        return listAccs.size() > 0 ? listAccs.get(0) : null;
    }
    
    /**
     * Get some accounts has member as user login
     * @AUTHOR  SOTHEA HORN
     * @CREATED 01 MAY 2017
     */
    private Map<String, Account> loadAvailableAccounts(){
        Map<String, Account> mapAccs = new Map<String, Account>( [SELECT id, Name, Finance_contact__r.Name, Member__r.DefaultMemberUnit__r.EnableTRACT__c, Tract_AccountId__c 
                              FROM Account WHERE  Member__c =: member.Id AND Member__r.DefaultMemberUnit__r.EnableTRACT__c = true limit 50]);
        return mapAccs;     
    }
    
    /**
     * Get result search all accounts from input
     * @AUTHOR  SOTHEA HORN
     * @CREATED 01 MAY 2017
     */
    private List<Account> filterAccounts(){
        String strSearch = '%' + searchStr + '%';
        Account[] results = [SELECT id, Name, Finance_contact__r.Name, Member__r.DefaultMemberUnit__r.EnableTRACT__c, Tract_AccountId__c 
                              FROM Account WHERE  Member__c =: member.Id AND Member__r.DefaultMemberUnit__r.EnableTRACT__c = true AND
                              Name like : strSearch limit 50];
        return results;
    }
    
    private String getBackToURL() {
        if (fromListView) {
            return OPP_LISTVIEW_URL;
        } else if (acc != null) {
            return '/' + acc.Id;
        }
        return '';
    }
}