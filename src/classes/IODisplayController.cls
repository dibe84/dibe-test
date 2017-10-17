public with sharing class IODisplayController {

    private Opportunity opp;
    public Account acc;
    private String errorMessage = 'Error Message: Unknown';
	private String retryMessage = 'Account is not yet ready! Please go back and try again. Thanks';
    private Boolean showErrorMessage = false;
    public Boolean mandateNeedsToBeAttached;
    public boolean isDiscountSet {set;}

    private List<OpportunityLineItem> olis;

    public MemberUnit__c memberUnit {
        get { return GW_MemberUnit.getMemberUnitById(opp.MemberUnit__c); }
        set;
    }

    public String memberUnitId {
        get {
            if(Test.isRunningTest()) return 'xxxxxx';  //@vitou 28-04-2015
            return memberUnit.MemberUnitId__c; }
        private set;
    }

    public echosign_dev1__SIGN_Agreement__c agreement  {get; set;}

    ApexPages.StandardController standardController = null;
    public IODisplayController(ApexPages.StandardController sc) {
        opp = (Opportunity) sc.getRecord();

        opp = [Select Id, Name, Account.Member__r.MemberId__c, MemberUnit__c, MemberUnitId__c, Billing_Account__c, IOnumber__c,
                PriceBook2Id, Include_SEPA_mandate__c,
                Primary_Contact__c, Primary_Contact__r.FirstName, MandateId__c, Account.OwnerId, Owner.Firstname, Owner.LastName,
                Owner.Phone, StageName, IsWon, IsClosed, CloseDate, Amount, AccountId, Account.Name, Language_Preference__c, RecordTypeId
                from Opportunity where Id = :opp.Id];

        acc = [SELECT Id, Name,
                          Account_Status__c,
                          Member__r.MemberId__c,
                          Bank_AccountNumber__c,
                          Bank_Name__c,
                          Finance_contact__c,
                          Finance_contact__r.Email,
                          Finance_contact__r.Phone,
                          Language_Preference__c,
                          Billing_Preference__c,
                          Mandate__c,
                          Mandate__r.Mandate_Status__c
                FROM Account WHERE Id=:opp.Billing_Account__c ];

        olis = (List<OpportunityLineItem>) GW_sObject.getChildren(opp.Id, 'OpportunityLineItems');

        //@suy sreymol 24-08-2016  #9687-Request Mandate from opportunity (Generate IO)
        mandateNeedsToBeAttached = GW_Opportunity.mandateNeedsToBeAttached(acc, opp.Id);
    }

    public String getErrorMessage()         { return errorMessage; }
    public Boolean getShowErrorMessage()    { return showErrorMessage; }
    public PageReference cancel()           { return new PageReference('/'+opp.Id); }

    private PageReference returnError(String msg) {
        UTIL.log('Error in checks: '+msg);
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,msg));
        showErrorMessage = true;
        return null;
    }

    public PageReference createIO(){

        if (acc.Account_Status__c=='Suspended - Bad Debt')          return returnError( Label.Account_is_suspended_please_contact_Finance);
        if (acc.Finance_contact__c==null)                           return returnError('There is no Finance Contact assigned to the Billing Account.');
        if (acc.Finance_contact__r.Email==null ||
            acc.Finance_contact__r.Phone ==null )                   return returnError('A finance Contact with email and phone number is required.');
        if (acc.Member__c == null)                                  return returnError('A member is required.');
        if (opp.Primary_Contact__c == null)                         return returnError('A primary contact is required.');
        
        // Create Echosign agreement
        agreement = new echosign_dev1__SIGN_Agreement__c();

        String language = (opp != null) ? opp.language_preference__c : '';
        UTIL_Customizer customizer = new UTIL_Customizer(null, memberUnit, opp, language);

        agreement.Name = GW_Agreement.formatName(customizer.getLabel('IOSubject', opp));
        agreement.echosign_dev1__Opportunity__c = opp.id;
        agreement.echosign_dev1__Account__c = opp.Billing_Account__c;
        agreement.MemberUnit__c = memberUnit.Id;
        agreement.Type__c = 'IO';

        agreement.echosign_dev1__Recipient__c = opp.Primary_Contact__c;

        agreement.Billing_Preference__c = acc.Billing_Preference__c;
        agreement.Mandate_id__c = opp.MandateId__c;
        agreement.Bank_AccountNumber__c = acc.Bank_AccountNumber__c;
        agreement.Bank_Name__c = acc.Bank_Name__c ;
        agreement.Bank_Account_Holder_Name__c = acc.Name;

        String accLanguage = (acc != null) ? acc.language_preference__c : '';
        EmailTemplate sendTemplate = customizer.getEmailTemplate('IO');

        if (sendTemplate != null){
            Messaging.SingleEmailMessage mail = UTIL.renderEmail(sendTemplate, opp.Primary_Contact__c, opp.Id);
            agreement.echosign_dev1__Message__c = mail.getPlainTextBody();
        }

        agreement.echosign_dev1__AgreementLocale__c = GW_Agreement.getLocale( acc.Language_Preference__c);
        
        //Only assign data mapping to mandate @suy sreymol 18-08-2016  #9687-Request Mandate from opportunity (Generate IO)
        List<echosign_dev1__SIGN_Data_Mapping__c> dataMapping = (mandateNeedsToBeAttached) ? GW_EchoSignDataMapping.getRecords('Name', new Set<String>{'Mandate_IO'}) : new List<echosign_dev1__SIGN_Data_Mapping__c>();
        agreement.echosign_dev1__Process_Template__c = (dataMapping.isEmpty()) ? null : dataMapping.get(0).Id;

        try{
            insert agreement;                
        }catch(system.DMLException ex){
			showErrorMessage = true;
            String errMsg = StatusCode.UNABLE_TO_LOCK_ROW==ex.getDmlType(0) ? retryMessage : ex.getMessage().replace('First exception on row 0; first error: ','');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,errMsg));
            UTIL.writeLog('ERROR', ex.getMessage() + ' : ' + ex.getStackTraceString(),'IODisplayController');
            return null;
        }
        
        agreement = GW_Agreement.getRecord(agreement.Id);

        if (mandateNeedsToBeAttached) {
            return null;
        } else {
            return attachRequiredPDFs();
        }
    }

    public PageReference attachRequiredPDFs(){
        try{

            GW_Agreement.attachIO(agreement, memberUnit, opp, getIsDiscountSet());
            if (mandateNeedsToBeAttached) {
                GW_Agreement.attachMandate(agreement, memberUnit);
            }

            GW_Agreement.attachTAndC(agreement, memberUnit, opp, acc.Language_Preference__c);
        }
        catch(Exception e){
            throw e;
            //return returnError(e.getMessage());
        }

        PageReference p = new PageReference('/'+agreement.ID); // to open agreement Detail
        p.setRedirect(true);
        return p;
    }

    public boolean getIsDiscountSet(){

        if (olis == null) olis = new List<OpportunityLineItem>();
        for (OpportunityLineItem oli : olis){
            if (oli.SalesPriceNet__c < oli.ListPrice__c){
                return true;
            }
        }
        return false;
    }

}