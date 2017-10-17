public with sharing class PGC_GenerateMandate {


    private Account acc;

    public MemberUnit__c memberUnit {
        get { return GW_MemberUnit.getMemberUnitById(memberUnitId); }
        private set;
    }

    public String memberUnitId {get; set;}

    private List<MemberUnit__c> memberUnits = new List<MemberUnit__c>();

    public echosign_dev1__SIGN_Agreement__c agreement  {get; set;}

    private String errorMessage = 'Error Message: Unknown';
    private Boolean showErrorMessage = false;

    private UTIL_Customizer customizer;
    private String language;

    public PGC_GenerateMandate(ApexPages.StandardController sc) {
        acc = (Account) sc.getRecord();
        acc = GW_Account.getRecord(acc.Id);
        Member__c member = GW_Member.memberCache.get(acc.Member__c);
        memberUnitId = (member != null) ? member.DefaultMemberUnit__c : null;
        memberUnits = GW_MemberUnit.getListFromRelated(acc.Member__c);
        agreement = null;
        language = (acc != null) ? acc.Language_Preference__c : '';
    }

    public List<SelectOption> getMemberUnitItems() {
        List<SelectOption> options = new List<SelectOption>();
        for (MemberUnit__c mu : memberUnits){
            options.add(new SelectOption(mu.Id, mu.Name));
        }
        return options;

    }

    public PageReference load(){

        if (acc.Account_Status__c=='Suspended - Bad Debt')      return returnError( Label.Account_is_suspended_please_contact_Finance);
        if (acc.Finance_contact__c==null)                       return returnError('There is no Finance Contact assigned to the Billing Account.');
        if (acc.Member__c == null)                              return returnError('A member is required.');
        if (!'Direct Debit'.equals(acc.Billing_Preference__c))  return returnError('Mandate is not applicable for payment method: '+acc.Billing_Preference__c); // 
        if (GW_Account.hasPendingMandate(acc.Id))               return returnError('You have an agreement which is still in progress. Please cancel the agreement to proceed or send reminder to your customer.');

        return null;
    }

    public PageReference createMandate(){
        
        if (memberUnit == null) return returnError('A member unit is required.');
        
        customizer = new UTIL_Customizer(null, memberUnit, null, language);

        agreement = new echosign_dev1__SIGN_Agreement__c();

        agreement.Name = GW_Agreement.formatName(customizer.getLabel('MandateSubject', acc));
        agreement.echosign_dev1__Account__c = acc.Id;
        agreement.MemberUnit__c = memberUnitId;
        agreement.Type__c = 'Mandate';
        
        //To set mapping data for agreement once it is singed. suy sreymol-11/08/2016-#9633 CD-607 - Echosign changes: iban, vat, upgrade version
        List<echosign_dev1__SIGN_Data_Mapping__c> dataMapping = GW_EchoSignDataMapping.getRecords('Name', new Set<String>{'Mandate_IO'});
        agreement.echosign_dev1__Process_Template__c = (ApexPages.currentPage().getParameters().get('isMandate') == 'true') ? ( dataMapping.isEmpty() ? null : dataMapping.get(0).Id) : null;

        agreement.echosign_dev1__Recipient__c = acc.Finance_contact__c;

        agreement.Billing_Preference__c = acc.Billing_Preference__c;
        agreement.Bank_AccountNumber__c = acc.Bank_Accountnumber__c;
        agreement.Bank_Name__c = acc.Bank_Name__c;
        agreement.Bank_Account_Holder_Name__c = acc.Name;

        //Check if MemberUnit has a Mandate EmailTemplate specified

        //if yes use version of Account its Language Preference or general one when missing.
        EmailTemplate sendTemplate = customizer.getEmailTemplate('Mandate');

        if (sendTemplate != null){
            Messaging.SingleEmailMessage mail = UTIL.renderEmail(sendTemplate, agreement.echosign_dev1__Recipient__c, acc.Id);
            agreement.echosign_dev1__Message__c = mail.getPlainTextBody();
        }

        agreement.echosign_dev1__AgreementLocale__c = GW_Agreement.getLocale( acc.Language_Preference__c);


        insert agreement;
        agreement = GW_Agreement.getRecord(agreement.Id);
        agreement.Mandate_id__c = acc.AccountExtId__c+'-'+agreement.AgreementNumber__c;
        update agreement;

        return null;
    }

    public Pagereference attachMandatePdf(){
        // render Mandate and store as attachment

        GW_Agreement.attachMandate(agreement, memberUnit);

        PageReference p = new PageReference('/'+agreement.ID); // to open agreement Detail
        p.setRedirect(true);
        return p;
    }

    private PageReference returnError(String msg) {
        UTIL.log('Error in checks: '+msg);
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,msg));
        errorMessage = msg;
        showErrorMessage = true;
        return null;
    }

    public String getErrorMessage()         { return errorMessage; }
    public Boolean getShowErrorMessage()    { return showErrorMessage; }
    public PageReference cancel()           { return new PageReference('/'+acc.Id); }
}