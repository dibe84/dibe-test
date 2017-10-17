global class BAT_AccountMadateStatus implements Database.Batchable<sObject>, UTIL_CustomJob.ICustomJob{
	// interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }

    global Datetime executeStart;

    String queryString;
    List<echosign_dev1__SIGN_Agreement__c> lstAgreementsInput;

    global BAT_AccountMadateStatus() {
        readyForRun = true;
    }

    global BAT_AccountMadateStatus(List<echosign_dev1__SIGN_Agreement__c> agreements) {
        this.lstAgreementsInput = agreements;
    }

    global List<echosign_dev1__SIGN_Agreement__c> start(Database.BatchableContext BC) {
        if (lstAgreementsInput == null){
        	List<echosign_dev1__SIGN_Agreement__c> lstAgreements = GW_sObject.queryRecords('echosign_dev1__SIGN_Agreement__c', 'echosign_dev1__Account__c != null ' + 
        																														' AND echosign_dev1__Account__r.Billing_Preference__c = \'Direct Debit\' ' +
														        																' AND (echosign_dev1__Opportunity__c = null OR echosign_dev1__Opportunity__r.StageName != \'Signed\') ' +
														        																' AND echosign_dev1__Status__c = \'Signed\' ');
        	
        	return lstAgreements;
        }
        else{
            return lstAgreementsInput;
        }
    }

    global void execute(Database.BatchableContext BC, List<echosign_dev1__SIGN_Agreement__c> scope) {
    	List<echosign_dev1__SIGN_Data_Mapping__c> dataMapping = GW_EchoSignDataMapping.getRecords('Name', new Set<String>{'Mandate_IO'});
    	
    	//If there are no data mapping, nothing to do
    	if(dataMapping.isEmpty()) return;
    	
        if(this.executeStart == null) this.executeStart = Datetime.now();
        
		Set<ID> accIds = new Set<ID>();
		for (echosign_dev1__SIGN_Agreement__c agreement : scope) {
			accIds.add(agreement.echosign_dev1__Account__c);
		}

		Map<id, Account> mAccounts = new Map<id, Account>();
		List<Account> lstAccs = GW_sObject.queryRecords('Account', accIds);
		for(Account acc : lstAccs){
			mAccounts.put(acc.id, acc);
		}
		
        for (echosign_dev1__SIGN_Agreement__c agreement : scope) {
        	Account acc = mAccounts.get(agreement.echosign_dev1__Account__c);
        	AccountValidator.IAccountValidator validator = AccountValidator.getValidator(acc);
        	
        	agreement.Mandate_Status__c = validator.checkBankAccountNumber() ? 'Success': 'Failed';
			agreement.echosign_dev1__Process_Template__c = agreement.echosign_dev1__Process_Template__c == null ? dataMapping[0].id : agreement.echosign_dev1__Process_Template__c;
        }

        try {
            update scope;
        } catch(Exception ex) {
            UTIL.throwError('BAT_AccountMadateStatus - Error updating Agreement ',ex);
        }
    }

    global void finish(Database.BatchableContext BC) {}

}