public class SCH_SyncMandate implements System.Schedulable {
    
    public String agreementId;
    private echosign_dev1__SIGN_Agreement__c originalAgm;
    private echosign_dev1__SIGN_Agreement__c currentAgm;
    private Account billingAccount;
    private Opportunity opp;
    
    private String dmlOp;

    public SCH_SyncMandate( echosign_dev1__SIGN_Agreement__c originalAgm, String dmlOp ) {
    	this.agreementId = originalAgm.Id;
        this.originalAgm = originalAgm; 
        this.dmlOp = dmlOp;
    }

    public void execute(SchedulableContext qc) {

        try {
            loadEntities();
            if ( dmlOp == GW_Agreement.TRANSITION_SIGNING ) processMandateSigning();
            persistEntities();
            
        } catch(Exception ex) {
            UTIL.throwError('SCH_SyncMandate: ',ex);
        }
    }

    private void processMandateSigning(){
        
        if( ('Signed'.equals( currentAgm.echosign_dev1__Status__c ) ) 
            && currentAgm.echosign_dev1__SignatureType__c == 'e-Signature'
                && currentAgm.Bank_AccountNumber__c != null 
                   && originalAgm.echosign_dev1__Data_Mapping_Result__c != currentAgm.echosign_dev1__Data_Mapping_Result__c  
                        && 'Completed'.equalsIgnoreCase(currentAgm.echosign_dev1__Data_Mapping_Result__c) ) {
                
            Account stubAcc = new Account( Id = billingAccount.Id, Bank_AccountNumber__c = currentAgm.Bank_AccountNumber__c, BillingCountryCode = billingAccount.BillingCountryCode );
            AccountValidator.IAccountValidator validator = AccountValidator.getValidator( stubAcc );
            if (validator.checkBankAccountNumber()) {
             
                currentAgm.Mandate_Status__c = 'Success';
                billingAccount.Bank_AccountNumber__c = currentAgm.Bank_AccountNumber__c;
                billingAccount.Mandate__c = currentAgm.Id;

                // create new direct debit payment method in TRACT
                Boolean isSubscribedToTract = UTIL_WSC_Subscription.isSubscribedToTRACT(billingAccount);
                if (isSubscribedToTract && ((currentAgm.Type__c == 'IO' && ( opp != null && opp.Include_SEPA_mandate__c ) ) || currentAgm.Type__c == 'Mandate')) {
                    Q_CreateDirectDebitPaymentMethod ddpJob = new Q_CreateDirectDebitPaymentMethod( billingAccount.Id, currentAgm.Id );
                    System.enqueueJob( ddpJob );
                }
                
            } else {
                currentAgm.Mandate_Status__c = 'Failed';
                
                if ( opp == null ) {
                    sendInvalidIBANMailNotification( billingAccount , null );
                    createTask( billingAccount.Id , billingAccount.OwnerId );
                } else {
                    sendInvalidIBANMailNotification( billingAccount , opp );
                    createTask( opp.Id , opp.OwnerId );
                }
            }
        }       
    }

    private void loadEntities(){
        billingAccount = ( GW_Account.getList( new Set<id> { originalAgm.echosign_dev1__Account__c } , new List<String>{ 'Owner.Name' } ) )[0];
        if ( dmlOp != GW_Agreement.TRANSITION_DELETION ){
            currentAgm = (echosign_dev1__SIGN_Agreement__c) GW_sObject.queryRecordForUpdate( 'echosign_dev1__SIGN_Agreement__c' , originalAgm.Id );
            if ( currentAgm.echosign_dev1__Opportunity__c != null ) {
                opp = ( GW_Opportunity.getList( new Set<id> { currentAgm.echosign_dev1__Opportunity__c } , new List<String>{ 'Owner.Name' } ) )[0];
            }       
        }
    }
    
    private void persistEntities(){
        if ( dmlOp != GW_Agreement.TRANSITION_DELETION ){
            update currentAgm;  
        }
        update billingAccount;
    }

    public void sendInvalidIBANMailNotification( Account bacc , Opportunity opp ) {

        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        String oppURL = (opp == null) ? '' : baseURL+'/' + opp.Id;
        String accountURL = baseURL + '/' + bacc.Id;
        String templateName = (opp == null) ? 'Failed_Mandate_Resend_Account' : 'Failed_Mandate_Resend_Opp';
        String targetObjId = (opp == null) ? bacc.OwnerId : opp.OwnerId;
        String targetObjId2 = (opp == null) ? bacc.Finance_contact__c : opp.Primary_Contact__c;
        String whatId = (opp == null) ? bacc.Id : opp.Id;
        
        Messaging.SingleEmailMessage email = UTIL_Email.buildEmail(templateName, targetObjId, targetObjId2, whatId, new Map<String, String>{'$UserName$'=> ((opp == null) ? bacc.Owner.Name : opp.Owner.Name) , '$AccountLink$' => accountURL, '$OpportunityLink$' => oppURL, '$AccountName$' => bacc.Name+''});
        UTIL_Email.sendEmails( new List<Messaging.SingleEmailMessage>{ email } );
    }
    
    private void createTask(String whatId, String ownerId) {
        insert ( new Task(OwnerId = ownerId, WhatId = whatId, Subject = 'IBAN not Valid. Please resend Mandate', Status = 'Not Started', ActivityDate = Date.today(), ReminderDateTime = System.now(), IsReminderSet = true) );
    }
}