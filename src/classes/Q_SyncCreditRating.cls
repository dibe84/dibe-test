/*
 * This job syncs the Credit Rating for a given account
 */
public class Q_SyncCreditRating implements System.Queueable , Database.AllowsCallouts {

    public List<Account> targetAccounts;

    public Q_SyncCreditRating(Set<Id> accIdSet) {
        this.targetAccounts = GW_Account.getListForUpdate(accIdSet);
    }

    public void execute(QueueableContext qc) {
        List<Account> accListToUpdate = new List<Account>();
        
        for(Account targetAccount : targetAccounts) {
            String dunsNumber;
            try {
                // Retrieve the DUNS Number
                List<Account> accs = WSC_DNB_TOOLKIT.lookupDNBCompanies( targetAccount.Name , targetAccount.BillingCountryCode , targetAccount.BillingPostalCode );
                
                // Updates the lookup timestamp
                targetAccount.DNB_LastLookupTimestamp__c = System.now();
        	
                // Retrieves the DUNS Number from the first account found
                if( accs.size() > 0 ){
                    targetAccount.DUNS_Number__c = accs[0].DUNS_Number__c;
                    
                    // Load the credit rating info
                    WSC_DNB_TOOLKIT.loadCreditRatingInfo( targetAccount );
				//Change log: 17-11-2016 - Sochanra: change to use custom object SIC__c 
                    if( targetAccount.Sic != null ){
        			List<SIC__c> lstSic = [SELECT Id, Name, Code__c FROM SIC__c WHERE Code__c = :targetAccount.Sic];        			
        			if (!lstSic.isEmpty()) {
        				targetAccount.SIC__c = lstSic[0].Id;
        				targetAccount.SicDesc = lstSic[0].Name;
        			}
                    }
                    
                } else {
                    targetAccount.DNB_AccountNotFound__c = true;
                }
                
                accListToUpdate.add(targetAccount);
             
            } catch(Exception ex) {
                UTIL.throwError('Q_SyncCreditRating: Error synching account credit rating: ',ex);
            }     
        }
        
        try {
            update accListToUpdate;
        } catch(Exception ex) {
                UTIL.throwError('Q_SyncCreditRating: Error synching account credit rating: ',ex);
        } 
    }
}