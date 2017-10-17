global class BAT_AccountValidationAndEnrichment implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    global Datetime executeStart;

    List<Account> accsInput;

    global BAT_AccountValidationAndEnrichment(List<Account> accs) {
        this.accsInput = accs;
    }

    global List<Account> start(Database.BatchableContext BC) {
        return accsInput;
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        List<Account> accsToUpdate = new List<Account>();

        for (Account acc : scope) {
            Account updAcc = new Account(id=acc.Id);
            updAcc.Touch__c = '';

            AccountValidator.IAccountValidator validator = AccountValidator.getValidator(acc);

            boolean billingCountryCorrectlyPopulated = !String.isEmpty(acc.BillingCountry) && ('BE'.equals(acc.BillingCountryCode) || 'NL'.equals(acc.BillingCountryCode) || 'LU'.equals(acc.BillingCountryCode));

            if (billingCountryCorrectlyPopulated && validator.checkBankAccountNumber() && validator.checkAndSetBankDetails()){
                updAcc.Bank_AccountNumber__c = acc.Bank_AccountNumber__c;
                updAcc.Bank_Name__c = acc.Bank_Name__c;
            }
            else if (!billingCountryCorrectlyPopulated){
                updAcc.Bank_AccountNumber__c = '';
                updAcc.Bank_Name__c = '';
                updAcc.Touch__c  = ' Invalid: BillingCountry['+acc.BillingCountry+'] IBAN['+acc.Bank_AccountNumber__c+'] Bankname['+acc.Bank_Name__c+']';
            }
            else{
                updAcc.Bank_AccountNumber__c = '';
                updAcc.Bank_Name__c = '';
                updAcc.Touch__c  = ' Invalid: IBAN['+acc.Bank_AccountNumber__c+'] Bankname['+acc.Bank_Name__c+']';
            }

            if (validator.checkAndSetCompanyTaxDetails() && billingCountryCorrectlyPopulated){
                updAcc.Company_VAT_No__c = acc.Company_VAT_No__c;
            }
            else if (billingCountryCorrectlyPopulated){
                updAcc.Company_VAT_No__c = '';
                updAcc.Touch__c += ' Invalid: VAT No['+acc.Company_VAT_No__c+']';
            }
            accsToUpdate.add(updAcc);
        }
        try {
            update accsToUpdate;
        } catch(Exception ex) {
            UTIL.throwError('BAT_AccountValidationAndEnrichment - Error updating Accounts with Validation and Enrichment data.',ex);
        }
    }

    global void finish(Database.BatchableContext BC) {
        if( Test.isRunningTest() ) return;
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_AccountValidationAndEnrichment', BC.getJobId());
    }
}