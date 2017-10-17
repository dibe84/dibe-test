public without sharing class LSC_SiteUserController {
    
    private static final String INVALID_MEMBER_UNIT_ID = 'Invalid member unit id.';
    private static final String DEFAULT_ROLE = 'Finance Contact';
    private static final String ACTIVE_STATUS = 'Active';
    private static final String PENDING_APPROVAL = 'Pending Approval';
    private static final String MPNLAM_STATUS = 'MPNLAM';
    
    // constructor
    public LSC_SiteUserController() {
        
    }

    /**
    * @desc: To handle the process of register User
    * @param: contactDetail which hold information from first form
    * @param: accountDetail which hold information from second form
    * @return: a Boolean value of true/false to indicate the result of registration
    */

    @AuraEnabled
    public static Map<String, Object> doRegisterUser( String contactDetail, String accountDetail, String existedUserEmail, String memberId, String paymentType, String paymentCurrency ){
		
        Boolean isMPNLAM = (memberId == MPNLAM_STATUS);
        Contact newContact = new Contact();
        Account newAccount = new Account();

        Map<String, Object>mResult = new Map<String, Object>();

        for( Object eachContactDetail : (List<Object>)JSON.deserializeUntyped( contactDetail ) ){
            Map<String, Object> contactDetailMap = (Map<String, Object>)eachContactDetail;
            newContact.put( (String)contactDetailMap.get('name'), contactDetailMap.get('value') );
        }
        
        for( Object eachAccountDetail : (List<Object>)JSON.deserializeUntyped( accountDetail ) ){
            Map<String, Object> accountDetailMap = (Map<String, Object>)eachAccountDetail;
            if( (String)accountDetailMap.get('name') == 'Password' ||
                (String)accountDetailMap.get('name') == 'Re-Enter-Password'
            ){
                continue;
            }
            newAccount.put( (String)accountDetailMap.get('name'), accountDetailMap.get('value') );
        }

        try{
            if( existedUserEmail != null ){
                List<Contact> existedContact = GW_sObject.queryRecords('Contact', ' Email = \''+existedUserEmail+'\'');
                newAccount.Id = existedContact[0].AccountId;
                
                update newAccount;
               
            }else {
               
                List<MemberUnit__c> lstMemberUnits = [Select Id, Member__c From MemberUnit__c Where MemberUnitId__c =: memberId];
                if(lstMemberUnits.isEmpty()) {
                    mResult.put('error',  INVALID_MEMBER_UNIT_ID);
                    mResult.put('isSuccess', false);
                    return mResult;
                }
                
                MemberUnit__c memberUnit = lstMemberUnits.get(0);
                newAccount.Member__c = memberUnit.Member__c;
                newAccount.Account_Status__c = isMPNLAM ? PENDING_APPROVAL : ACTIVE_STATUS;
                newAccount.SelfService__c = true;

                //Add RecordType into new Account
                Id accRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Advertiser').getRecordTypeId();
                if (String.isNotBlank(accRT)) newAccount.RecordTypeId = accRT;

                insert newAccount;
                
                AccountMemberUnitAssociation__c accMemberUnitAss = new AccountMemberUnitAssociation__c();
                accMemberUnitAss.Account__c = newAccount.Id;
                accMemberUnitAss.MemberUnit__c = memberUnit.Id;
                insert accMemberUnitAss;
                
                newContact.Role__c = DEFAULT_ROLE;
                newContact.AccountId = newAccount.Id;
                newContact.Primary__c = true; 
                newContact.HasOptedOutOfEmail = false;  
                insert newContact;
                
                //We don't need default MemberUnit
                delete [Select Id From AccountMemberUnitAssociation__c Where Account__c =: newAccount.Id AND ID <>: accMemberUnitAss.Id];
            }
           
            if (isMPNLAM ) { //create related Case
                SiteUserRegistration.createCase(newAccount.Id, null, 'MPNL ADMARKT SIGNUP'); //temporary hard code for case origin
            }
            
            System.debug( 'save Account/Contact successfully...' );
            mResult.put('isSuccess', true);
            mResult.put('accId', newAccount.Id);
            mResult.put('conId', newContact.Id);

        }catch( DmlException ex ){
            System.debug( 'ERROR: inserting new Account/Contact ==> ' + ex.getMessage() );
            mResult.put('error',  ex.getDmlMessage(0));
            mResult.put('isSuccess', false);
        }

        return mResult;
    }

    /**
    * @desc: create a lead record when user complete the first form
    * @param: string of Contact Detail from first form
    * @return: id of lead record, so that we can delete it when user complee the second form
    */
    @AuraEnabled
    public static Map<String, Object> createLead( String contactDetail, String memberId , String memberUnitId, String leadType){
        
        Map<String, Object>mResult = new Map<String, Object>();
        Lead newLead = new Lead();
        Object firstName;

        for( Object eachContactDetail : (List<Object>)JSON.deserializeUntyped( contactDetail ) ){
            Map<String, Object> contactDetailMap = (Map<String, Object>)eachContactDetail;
            if( (String)contactDetailMap.get('name') == 'FirstName' ){
                firstName = contactDetailMap.get('value');
            }
            newLead.put( (String)contactDetailMap.get('name'), contactDetailMap.get('value') );
        }
         List<MemberUnit__c> lstMemberUnits = [Select Id, Member__c From MemberUnit__c Where MemberUnitId__c =: memberUnitId];
         if(lstMemberUnits.isEmpty()) {
             mResult.put('error',  INVALID_MEMBER_UNIT_ID);
             mResult.put('isSuccess', false);
             return mResult;
          }
                
        MemberUnit__c memberUnit = lstMemberUnits.get(0);
        newLead.put( 'Company', firstName );
        newLead.Member__c = memberUnit.Member__c;
        newLead.MemberUnit__c = memberUnit.Id;
        newLead.Type__c = leadType;

        try{
            insert newLead;
            mResult.put('isSuccess', true);
            mResult.put('leadId', newLead.Id);
        }catch( DmlException ex ){
            System.debug( 'ERROR: unable to save lead record.' + ex.getMessage() );
             mResult.put('error',  ex.getDMLMessage(0));
             mResult.put('isSuccess', false);
        }
        return mResult;

    }

    /**
    * @desc: method to delete lead record create by completing the first form
    * @param: leadId used to query created lead record earlier
    * @return: true/false 
    */
    @AuraEnabled
    public static Boolean deleteLead( String leadId ){
        try{
            delete [ SELECT Id FROM Lead WHERE Id = :leadId ];
            return true;
        }catch( DmlException ex ){
            return false;
            System.debug( 'ERROR:: Deleting lead ==> ' + ex.getMessage() );
        }

        return true;
    }

    /**
    * @desc: method to check existing user via record contact 
    * @param: user email address
    * @return: true/false
    */
    @AuraEnabled
    public static Boolean checkExistingUser( String userEmail ){
        //TODO: check with MP USER API
        try {
            List<Contact> existedContact = GW_sObject.queryRecords('Contact', ' Email = \''+userEmail+'\'');
            List<Lead> existedLead = GW_sObject.queryRecords('Lead', ' Email = \''+userEmail+'\'');
            
            if ( !existedContact.isEmpty()) {
                return true;
            }
            if ( !existedLead.isEmpty()) {
                return true;
            }
            return false;
        }catch( QueryException ex ){
            System.debug( 'ERROR:: unable to query existedContact ==> ' + ex.getMessage() );
            return false;
        }
        return false;
    }

    @AuraEnabled
    public static Account getExistingInfo( String accountFields, String existedUserEmail ){
        Account existedAccount = new Account();
        try{
            List<Contact> existedContact = GW_sObject.queryRecords('Contact', ' Email = \''+existedUserEmail+'\'');
            if( !existedContact.isEmpty() ) existedAccount = GW_Account.getRecord(existedContact[0].AccountId);
            
            return existedAccount;
            
        }catch( QueryException ex ){
            System.debug( 'ERROR:: getting existingContact info ==> ' + ex.getMessage() );
            return existedAccount;
        }

        return existedAccount;

    }
    @AuraEnabled
    public static RemoteResponse queryMemberUnit(String memberunit){
        try{
            List<String> additionalFields = new List<String>{
                'Member__r.Name',
                'Member__r.Id'
            };
            
            List<MemberUnit__c> lstMemberUnit = GW_sObject.queryRecords('MemberUnit__c', 'MemberUnitId__c = \'' + memberunit +'\' LIMIT 1', additionalFields);
            
            RemoteResponse response = new RemoteResponse();
            response.content = lstMemberUnit.isEmpty()?null:lstMemberUnit.get(0);
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            
            return response;
        }
        catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
}