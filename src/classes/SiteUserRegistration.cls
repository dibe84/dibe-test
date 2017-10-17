/**
 * @Buss: To handle business logic of sign up user from Force.com/Community site 
 * @author: Gaeasys Dev Team
 * @createddate: 10 Apr 2017
 */
public without sharing class SiteUserRegistration {
    //map member unit with case origin as all case is created by different Force.com/Community site (eBay Branch)
    static Map<String, String> mMemberUnitCaseOrigin = new Map<String, String>{'MP'=>'MPNL ADMARKT SIGNUP'};
    //map member unit with case assignment rule flag because not all case creation is needed to fire the rule 
    static Map<String, Boolean> mMemberUnitCAR = new Map<String, Boolean>{ 'MP' => true };  

    /**
    * @desc: To handle the process of register User
    * @param: contactDetail which hold information from first form
    * @param: accountDetail which hold information from second form
    * @return: a Boolean value of true/false to indicate the result of registration
    */

    @AuraEnabled
    public static Boolean doRegisterUser( String contactDetail, String accountDetail, String existingAccountId ){

        Contact newContact = new Contact();
        Account newAccount = new Account();

        System.debug( 'contactDetail ==> ' + contactDetail );
        System.debug( 'accountDetail ==> ' + accountDetail );

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

        System.debug( 'newContact ==> ' + newContact);
        System.debug( 'newAccount ==> ' + newAccount);

        try{
            newAccount.Account_Status__c = 'Pending Approval';
            System.debug( 'newAccount1 ==> ' + newAccount);
            if( existingAccountId != null ){
                newAccount.Id = existingAccountId;
                upsert newAccount;
            }else {
                insert newAccount;
                insert newContact;
            }

            newContact.AccountId = newAccount.Id;
            newContact.Primary__c = true;
            
            //create related Case
            SiteUserRegistration.createCase(newAccount.Id, null, 'MPNL ADMARKT SIGNUP'); //temporary hard code for case origin
            
            System.debug( 'save Account/Contact successfully...' );
        }catch( DmlException ex ){
            System.debug( 'ERROR: inserting new Account/Contact ==> ' + ex.getMessage() );
            return false;
        }

        return true;
    }

    /**
    * @desc: create a lead record when user complete the first form
    * @param: string of Contact Detail from first form
    * @return: id of lead record, so that we can delete it when user complee the second form
    */
    @AuraEnabled
    public static Id createLead( String contactDetail, String memberId , String memberUnitId ){

        Lead newLead = new Lead();
        Object firstName;

        for( Object eachContactDetail : (List<Object>)JSON.deserializeUntyped( contactDetail ) ){
            Map<String, Object> contactDetailMap = (Map<String, Object>)eachContactDetail;
            if( (String)contactDetailMap.get('name') == 'FirstName' ){
                firstName = contactDetailMap.get('value');
            }
            newLead.put( (String)contactDetailMap.get('name'), contactDetailMap.get('value') );
        }

        newLead.put( 'Company', firstName );
        newLead.Member__c = memberId;
        newLead.MemberUnit__c = memberUnitId;

        System.debug( 'newLead ==> ' + newLead );

        try{
            insert newLead;
        }catch( DmlException ex ){
            System.debug( 'ERROR: unable to save lead record.' + ex.getMessage() );
        }

        return newLead.Id;

    }

    /**
    * @desc: method to delete lead record create by completing the first form
    * @param: leadId used to query created lead record earlier
    * @return: true/false 
    */
    @AuraEnabled
    public static Boolean deleteLead( String leadId ){
        System.debug( 'deleting lead ==> ' + leadId );
        try{
            delete [ SELECT Id FROM Lead WHERE Id = :leadId ];
        }catch( DmlException ex ){
        		System.debug( 'ERROR:: Deleting lead ==> ' + ex.getMessage() );
            return false;
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
		Boolean result = false;
        //TODO: check with MP USER API
        try {
            List<Contact> existedContact = GW_sObject.queryRecords('Contact', ' Email = \''+userEmail+'\'');
            System.debug( 'existedContact ==> ' + existedContact );
            if( !existedContact.isEmpty() ){
                //return JSON.serialize( existedContact );
                //return existedContact[0].Name;
                result = true;
            }
        }catch( QueryException ex ){
            System.debug( 'ERROR:: unable to query existedContact ==> ' + ex.getMessage() );
        }

        return result;
    }

    @AuraEnabled
    public static Account getExistingInfo( String accountFields, String existedUserEmail ){
        Account existedAccount = new Account();
        /*
        String fieldsToQuery = 'SELECT ';
        String whereClause = ' FROM Account WHERE Id = ';

        List<String> accountFieldsList = new List<String>();

        for( Object eachField : (List<Object>)JSON.deserializeUntyped( accountFields ) ){
            Map<String, Object> fieldMap = (Map<String, Object>)eachField;
            accountFieldsList.add( (String)fieldMap.get('name') );
        }

        fieldsToQuery = fieldsToQuery + String.join( accountFieldsList, ',' );
        */
        try{
            /*
            String queryString = '';
            if(!existedContact.isEmpty()){
                queryString = fieldsToQuery + whereClause + '\'' + existedContact[0].AccountId + '\'';
            }

            List<sObject> accountInfo = Database.query( queryString );

            if( accountInfo.size() == 1 ){
                existedAccount = (Account)accountInfo[0];
            }

            System.debug( 'accountInfo ==> ' + existedAccount);
            */
            List<Contact> existedContact = GW_sObject.queryRecords('Contact', ' Email = \''+existedUserEmail+'\'');
            if( !existedContact.isEmpty() ) existedAccount = GW_Account.getRecord(existedContact[0].AccountId);
            
        }catch( QueryException ex ){
            System.debug( 'ERROR:: getting existingContact info ==> ' + ex.getMessage() );
        }

        return existedAccount;
    }

    
    /**
     * @Desc: To handle the hold process of registration site user
     * @param: salutation to address the person who registers 
     * @param: firstName is first name of user
     * @param: lastName is last name of user
     * @param: companyName is company name of user
     * @param: emailaddress is email of the user
     * @param: password is password of the user
     * @param: phoneNumber is mobile phone number of the user
     * @param: street 
     * @param: postalCode
     * @param: city
     * @param: country
     * @param: promotionCode
     * @param: kvkNumber
     * @param: vatNumber
     * @param: memberUnit is Member Unit name
     * @return
     */
    public static void doRegistrationUser(  String salutation, 
                                            String firstName, 
                                            String lastName,
                                            String companyName,
                                            String emailaddress,
                                            String password,
                                            String phoneNumber,
                                            String street,
                                            String postalCode,
                                            String city,
                                            String country,
                                            String promotionCode,
                                            String kvkNumber,
                                            String vatNumber,
                                            String countryCode, 
                                            String userExternalId,
                                            String memberUnit
                                        ) {
                                            
        SiteUserRegistration.createAccount(salutation, firstName, lastName, companyName, emailaddress, password, 
                                            phoneNumber, street, postalCode, city, country, promotionCode, kvkNumber, 
                                            vatNumber, countryCode, userExternalId, memberUnit);
                                            
    }
    
    /**
     * @Desc: 
     * @param: 
     * @param: 
     * @return: 
     */
    public static Account createAccount(String salutation, 
                                            String firstName, 
                                            String lastName,
                                            String companyName,
                                            String emailaddress,
                                            String password,
                                            String phoneNumber,
                                            String street,
                                            String postalCode,
                                            String city,
                                            String country,
                                            String promotionCode,
                                            String kvkNumber,
                                            String vatNumber,
                                            String countryCode,
                                            String userExternalId,
                                            String memberUnit
                                            ) {
        Account newacc = new Account();
        try {
            newacc.Company_VAT_No__c = vatNumber; //check VAT Number --> should not be here as it already has in account trigger
            newacc.BillingCountryCode = countryCode;
            newacc.Email__c = emailaddress;
            newacc.Name = companyName;
                    
            //check promotion code
            if ( !VAL_SiteUser.checkPromotionCode(promotionCode,memberUnit) ) throw new SiteUserRegistrationException('Invalid Promotion Code.');
            insert newacc;
            //create related Case
            SiteUserRegistration.createCase(newacc.Id, null, memberUnit);
        } catch (Exception ex) {
            return null;
        }
        return newacc;
    }
    
    /**
     * @Desc: To check whether input email address is already existed in the org/other integration system. Ex: MP User API
     * @param: email is an email input by customer (can be from Force.com sites/Community site)
     * @param: memberUnit is Member Unit name
     * @return: if email address is found in the org/other integration system > true
     *          Else > false
     */
    public static void createContact() {
    
    }
    
    /**
     * @Desc: To create new Case record and associates to Account/Contact
     * @param: accountId is Account ID
     * @param: contactId is Contact ID
     * @param: memberUnit is Member Unit name
     * @return
     */
    public static void createCase(String accountId, String contactId, String caseOrigin) {
        Case newcase = GW_Case.createCase(
                                            accountId, 
                                            contactId, 
                                            caseOrigin, 
                                            true 
                                        );
        system.debug('newcase==='+newcase);                             
        insert newcase;
    }
    
    public class SiteUserRegistrationException extends Exception{}
}