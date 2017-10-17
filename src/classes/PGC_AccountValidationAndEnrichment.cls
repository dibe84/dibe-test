public class PGC_AccountValidationAndEnrichment {
	
    public Account acct {set;get;}
    public Member__c mb {set;get;}
    public echosign_dev1__SIGN_Agreement__c md {set;get;}
    
    public PGC_AccountValidationAndEnrichment(ApexPages.StandardController stdController){
        this.acct = GW_Account.getRecord(stdController.getRecord().Id);
        this.mb = GW_Member.memberCache.get(acct.Member__c); 
        if(acct.Mandate__c != NULL){
        	this.md = GW_Agreement.getRecord(acct.Mandate__c);
        }
    }
    
////////////////////////////////////////////////////////
// Execution of validation and update of Account
///////////////////////////////////////////////////////    
    
    public void validateAndSave() {
        saveAccount(checkAndSetVATNumber() && checkAndSetBankAccountFields());
        acct = GW_Account.getRecord(acct.Id);
    }
    
    public void saveAccount(Boolean isValid){
        if (isValid){
            try{
            	update acct;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Changes are succesfully saved!'));
            }
            catch(System.DmlException ex){
                if (ex.getDmlType(0) != StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION ){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'An unexpected error occured, please contact your Administrator: '+ex.getMessage()));
                }
            }
        }
        else {
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Changes are not saved.')); 
        }
    }
    
    public List<SelectOption> getActivePaymentMethods(){
        List<SelectOption> options = new List<SelectOption>();
        String paymentMethodString = this.mb.ActivePaymentMethods__c != null ? this.mb.ActivePaymentMethods__c : '';
        List<String> paymentMethods = paymentMethodString.split(';',0);
        for (String paymentMethod : paymentMethods ){
            if (!String.isBlank(paymentMethod)){
                options.add(new SelectOption(paymentMethod, paymentMethod));
            }
        }
        if (options.size() == 0 && acct.Billing_Preference__c != null) options.add(new SelectOption(acct.Billing_Preference__c, acct.Billing_Preference__c));
       
        return options;
    }
    
    public void rerender(){
        
    }
    
    public boolean getBankDetailsActive(){
        return 'Direct Debit'.equals(acct.Billing_Preference__c);
    }
    
    public string getMandateStatus{
        Get{
            if(acct.Billing_Preference__c != 'Direct Debit'){
                return 'OK';
            }
            
            if(acct.Mandate__c != null){
                try{
                    echosign_dev1__SIGN_Agreement__c agreement = GW_Agreement.getRecord(acct.Mandate__c);
                    if(acct.Bank_AccountNumber__c == agreement.Bank_AccountNumber__c){
                        return 'OK';
                    }
                }catch(exception e){
                    return 'Not Signed';
                }
            }  
            
            return 'Not Signed';
        }
    }
       
    
    private boolean checkAndSetBankAccountFields() {
 
        if(!String.isEmpty(acct.Bank_AccountNumber__c) && acct.Bank_AccountNumber__c != null){
            AccountValidator.IAccountValidator validator = AccountValidator.getValidator(acct);
            
            boolean checkedAndSet;
            try{
                checkedAndSet = validator.checkAndSetBankDetails();
            } catch (UTIL.CustomException e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING,'IBAN isn\'t validated, Because of an unavailable IBAN service.'));
                return true;
            }


            if (checkedAndSet){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'The new IBAN is valid.'));
            }
            else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The new IBAN is not valid.'));
                return false;
            }
        } else if (!'Direct Debit'.equals(acct.Billing_Preference__c)) {
            acct.Bank_AccountNumber__c = '';
            acct.Bank_Name__c = '';
        } else if (acct.Bank_AccountNumber__c == null || String.isEmpty(acct.Bank_AccountNumber__c)) {
            /* CD-129, input of JSturm - disallow saving of payment type DD if IBAN is null */
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'It is not possible to select Direct Debit while not entering an IBAN.'));
            return false;
        }
        return true;
    }
    
    private boolean checkAndSetVATNumber(){

        if (!String.isEmpty(acct.Company_VAT_No__c)){
            
             try {
                 AccountValidator.IAccountValidator validator = AccountValidator.getValidator(acct);
                     
                if (validator.checkAndSetCompanyTaxDetails()) {
                     ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'The new Company VAT No. is valid.'));   
                }
                else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The New Company VAT No. is not valid.'));
                    return false;
                }
             }
            catch(AccountValidator.AccountValidatorException e) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The Billing Country is required.'));
                return false;
            }
        }
        return true;
    }   
   
}