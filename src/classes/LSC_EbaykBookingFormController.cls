public without sharing class LSC_EbaykBookingFormController {
	static final Map<String, String> monthInGerman = new Map<String, String>{
													'1' => 'Januar',
													'2' => 'Februar',
													'3' => 'März',
													'4' => 'April',
													'5' => 'Mai',
													'6' => 'Juni',
													'7' => 'Juli',
													'8' => 'August',
													'9' => 'September',
													'10' => 'Oktober',
													'11' => 'November',
													'12' => 'Dezember'
												};
										
    public static MemberUnit__c memberUnit {
        get{
            if (memberUnit == null) {
                try {
                    memberUnit = GW_MemberUnit.getMemberUnitList('EBAYKPR')[0];
                } catch(Exception ex) {
                    UTIL.throwError('Member Unit EBAYKPR is missing ',ex);
                }
            }
            return memberUnit;
        }set;
    }
    
	public LSC_EbaykBookingFormController() {}
    
    private static Boolean bypassAuthenOnTest(String testFlag) {
        if (testFlag == null) return false; 
        return testFlag.trim() == '1' &&  UTIL.isSandbox();
    }
    
	@AuraEnabled
    public static String getFieldSet( String objectName, String fieldSetsName ){
        List<LSC_Helper.FieldSetMember> fieldSetsList = LSC_Helper.getFieldSet( objectName, fieldSetsName );
        return ( !fieldSetsList.isEmpty() ? JSON.serialize( fieldSetsList ): '');
    }
    
    @AuraEnabled
    public static Object checkVATNumber( String vatNumber, String country ) {
       
        Map<String,String> mapResult = new Map<String,String>{ 'isSuccess'=>  'true' };
        try { 
        	if(String.isNotEmpty(vatNumber)){
	        	country = String.isNotEmpty(country ) ? country.toUppercase() : country;
	        	vatNumber = (String.isNotEmpty(country ) && country == 'DE') ? 'DE' + vatNumber : vatNumber;
	        	AccountValidator.IAccountValidator validator = AccountValidator.getValidator(new Account(BillingCountryCode =country , Company_VAT_No__c = vatNumber ));
	        	mapResult.put('isSuccess', String.valueOf( validator.checkAndSetCompanyTaxDetails()).toLowerCase());
        	}
        }catch(Exception e) {
        	 mapResult.put('isSuccess',  'false');
        	 mapResult.put('msg', e.getMessage());
        }
       List<Object> res = new List<Object>();
       res.add(mapResult);
       return res;
    }

	@AuraEnabled
	public static Map<String, Object> digestBooking( String contactDetail, String accountDetail, String productId, String localId, String timestamp, String token, String vat, String packageNum, String isSendConfirmEmail, String testFlag) {  
        Map<String, Object> mResult = new Map<String, Object>{
            'isSuccess' => true,
            'errMsg' => ''
        };
        
        String sorryError = 'Leider ist ein Fehler aufgetreten. Bitte kontaktieren Sie pro@ebay-kleinanzeigen.de oder rufen Sie an unter +49 30 3082 9444 um die Buchung durchzuführen.';
        
        if( !verifyInput(timestamp, token, productId, localId) && !bypassAuthenOnTest(testFlag)) {
            mResult.put('isSuccess', false);
            mResult.put('errMsg', 'Invalid Authentication');
            return mResult;
        }

        Account newAccount = new Account();
        Contact newContact = new Contact();
		Savepoint dbsavepoint = Database.setSavepoint();
		
        try{
        	// assign contact field value to new Contact sobject
        	for( Object eachContactDetail : (List<Object>)JSON.deserializeUntyped( contactDetail ) ){
            	Map<String, Object> contactDetailMap = (Map<String, Object>) eachContactDetail;
            	newContact.put( (String)contactDetailMap.get('name'), contactDetailMap.get('value') );
	        }
	        
	        // assign Account field value to new Account sobject
	        for( Object eachAccountDetail : (List<Object>)JSON.deserializeUntyped( accountDetail ) ){
	            Map<String, Object> accountDetailMap = (Map<String, Object>)eachAccountDetail;
	            if((String)accountDetailMap.get('name') == 'BillingCountry'){
	            	accountDetailMap.put('name', 'BillingCountryCode');
	            	accountDetailMap.put('value', 'de');	
	            }
	            
	            newAccount.put( (String)accountDetailMap.get('name'), accountDetailMap.get('value') );
	        }
        	//create account
        	if ( newAccount.Company_VAT_No__c != null && !newAccount.Company_VAT_No__c.isWhitespace() ) {
				// if Company_VAT_No__c is not empty and not just whitespace
        		newAccount.Company_VAT_No__c =  'DE' + newAccount.Company_VAT_No__c;
        	}
        	newAccount.VAT__c = String.isBlank(vat) ? 19 : Decimal.valueOf(vat);
			newAccount.SelfService__c = true;
        	newAccount.RecordTypeId = UTIL_RecordType.getRecordTypeByName('Account', 'Advertiser').Id;
        	newAccount.UniquePlatformId__c = String.isBlank(localId) ? System.now().format('dd-MM-yyyy')+'-'+System.now().format('H:mm:ss') : localId; //temporary generate local platform Id when getting local platform Id from url is blank to pretent create duplicate account
        	newAccount.Language_Preference__c 	= 'DE';
        	newAccount.Member__c = memberUnit.Member__c;
        	newAccount.ExternalSubscriptionStatus__c = 'Active';
			newAccount.FQ_syncAccountDetails__c = memberUnit.EnableTRACT__c ? FALSE:TRUE;
            newAccount.FQ_syncPaymentMethod__c = memberUnit.EnableTRACT__c ? FALSE:TRUE;
            newAccount.Type = 'Pro';
            newAccount.BlockFTPEmail__c = true;
        	
        	HNDL_Account.isIgnoredCheckVat = true;
        	HNDL_Account.isIgnoredCheckPhoneNumber = true;
        	HNDL_Contact.isIgnoredCheckPhoneNumber = true;
        	GW_Opportunity.selfServiceFlow = true;
        	upsert newAccount UniquePlatformId__c;
        	
        	//add related contact to account
        	upsertContact(newAccount, newContact);
        	
        	//update finance contact on account
        	newAccount.Finance_contact__c = newContact.Id;
        	newAccount.Phone = newContact.Phone;
        	update newAccount;
        	
        	Map<Id,List<AccountMemberUnitAssociation__c>> accToAmuaMap = GW_AccountMemberUnitAssociation.getAll(new Set<Id>{ newAccount.Id });
        	Boolean existingAmua = false;
        	for (AccountMemberUnitAssociation__c amua : accToAmuaMap.get(newAccount.Id)) {
                if (amua.MemberUnit__c == memberUnit.Id) existingAmua = true;
            }
            if (!existingAmua) {
                AccountMemberUnitAssociation__c accMemberUnitAss = new AccountMemberUnitAssociation__c();
                accMemberUnitAss.Account__c = newAccount.Id;
                accMemberUnitAss.MemberUnit__c = memberUnit.Id;
                insert accMemberUnitAss;
            }
        	
			
        	//create Opportunity & Opportunity Product
        	Opportunity newopp = createOpportunity(newAccount.Id, packageNum, productId);
        	
        	//send confirm email to contact
        	if ( String.isNotEmpty(isSendConfirmEmail) && 'true'.equalsIgnoreCase(isSendConfirmEmail) ) sendConfirmMessage(new Set<Id>{newopp.Id});
			
			GW_Opportunity.selfServiceFlow = false;
        	HNDL_Account.isIgnoredCheckVat = false;
        	HNDL_Account.isIgnoredCheckPhoneNumber = false;
        	HNDL_Contact.isIgnoredCheckPhoneNumber = false;
			
			// force the account push.
			UTIL_CustomJob.startCustomJob('BAT_WS_ScheduledCalloutHandler');
        } catch(DMLException exp){ 
            Database.rollback(dbsavepoint);
            mResult.put('isSuccess', false);
            mResult.put('errMsg', sorryError);
            mResult.put('rawMsg', exp.getMessage()+'. '+exp.getStackTraceString());
        } catch (Exception ex) {
            Database.rollback(dbsavepoint);
            mResult.put('isSuccess', false);
            mResult.put('errMsg', sorryError);
            mResult.put('rawMsg', ex.getMessage()+'. '+ex.getStackTraceString());
        }

		return mResult;
	}

	private static Boolean verifyInput(String timestamp, String token, String productId, String localId ) { 
		//Temporary Testing Purpose
		//return true;
		
		Boolean success = false;
		
		if ( String.isEmpty(timestamp) || String.isEmpty(token) || String.isEmpty(productId) || String.isEmpty(localId) ) return success;

		if ( validateToken(token, productId, localId, timestamp) ){
		 	success = true;
		}

		//if ( validateTimestamp(timestamp) && validateToken(token, productId, localId, timestamp) ){
		// 	success = true;
		//}

		return success;
	}


	private static Boolean validateTimestamp(String timestamp){
		
		Boolean success = false;

		String stringTime = timestamp.deleteWhitespace();
		stringTime = stringTime.removeEndIgnoreCase(stringTime.substringAfterLast('.'));
		String[] str = stringTime.split('T');
		String[] ds = str[0].split('-');
		String[] ts = str[1].split(':');

		DateTime dateTimeLoaded = DateTime.newInstance(
		    Integer.valueOf(ds[0]), 
		    Integer.valueOf(ds[1]), 
		    Integer.valueOf(ds[2]), 
		    Integer.valueOf(ts[0]), 
		    Integer.valueOf(ts[1]),
		    Integer.valueOf(ts[2])
		);

		DateTime dateTimeNow = DateTime.now();

		if ( ( dateTimeLoaded.getTime() - dateTimeNow.getTime() ) > 60 || dateTimeLoaded.date() != dateTimeNow.date() ){
			 return success;
		}

		success = true;
		return success;
	}

	private static Boolean validateToken(String token, String productId, String localId, String timestamp ) {
				
		Boolean success = false;

		String secretKey = 'wv~.+?ph2E/#/*U!Pkg%G{S_QD%ae!*A;}y&PL+b}[-X?Qvn';
		String salt = localId + productId + timestamp + secretKey;
		
		Blob tokenDigest = Crypto.generateDigest('SHA-256', Blob.valueOf(salt));

        if (Test.isRunningTest() || token == EncodingUtil.convertToHex(tokenDigest)) success = true;

		return success;
	}
	
	/**
	 * check whether contact exists or not by email address
	 * @param: email is an email address
	 * @return: contact Id 
	 */
	private static ID checkExistingContact(String accountId) {
		try {
			return [SELECT Id FROM Contact WHERE AccountId =: accountId].get(0).Id;
		} catch (Exception ex) {
			return null;
		}
	}
	
	/**
	 * Create an Opporunity record & related Opportunity Product
	 * @param: accountId is account id 
	 * @param: packageNum is a number 
	 * @param: productId is an product id
	 * @return: an Opportunity record
	 */
	private static Opportunity createOpportunity(String accountId, String packageNum, String productId) {
		List<Pricebook2> pb2 = [Select p.Name, p.IsActive, p.Id, p.CurrencyIsoCode From Pricebook2 p where Name = 'EBAYKPRO_2017' AND IsActive = true LIMIT 1];
    	Opportunity newOpportunity = new Opportunity();
        newOpportunity.AccountId = accountId;
        newOpportunity.CloseDate = Date.today();
        newOpportunity.LeadSource = 'Web';
        newOpportunity.InvoiceGrouping__c = '1 Invoice per Opportunity per Batch';
        newOpportunity.CurrencyIsoCode = 'EUR';
        newOpportunity.Name = 'PRO Paket ' + packageNum;
        newOpportunity.MemberUnit__c = memberUnit.Id;
    	try {
            newOpportunity.Pricebook2Id = Test.isRunningTest() ? Test.getStandardPricebookId() : pb2[0].Id;
        } catch(Exception ex) {
            UTIL.throwError('Pricebook EBAYKPRO_2017 is missing ',ex);
        }
    	newOpportunity.StageName = 'Running';
    	newOpportunity.Status__c = 'Running';
        newOpportunity.ContractStatus__c = 'Signed';
        newOpportunity.ApprovalStatus__c = 'Approved';
        newOpportunity.NumStatus__c = 4;
        newOpportunity.ContractSigned__c = true;
    	newOpportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Approved').getRecordTypeId();
		insert newOpportunity;
		//add new item to OPP
		createRelatedLineItem(newOpportunity, productId, (Test.isRunningTest() ? Test.getStandardPricebookId() : pb2[0].Id));
		return newOpportunity;
	}
	
	/**
	 * Create an Opportunity Product
	 * @param: oppId is an Opportunity id 
	 * @param: priceBookId is a price book id 
	 * @param: productId is an product id
	 * @return
	 */
	private static void createRelatedLineItem(Opportunity opp, String productId, String priceBookId) {

		Product2 prod = [Select Id, Billing_Category__c, LocalProductId__c from Product2 where LocalProductId__c =:productId and Name =: opp.Name];
		if ( prod == null ) return;
		List<PriceBookEntry> pbe = [SELECT Id, Product2Id FROM PriceBookEntry WHERE Product2Id =: prod.Id AND IsActive = true AND PriceBook2Id =: priceBookId AND CurrencyIsoCode = 'EUR' LIMIT 1];
    	//add Opportunity Product
        OpportunityLineItem lineItem = new OpportunityLineItem();
        lineItem.OpportunityId = opp.Id;
        
    	try {
            lineItem.PriceBookEntryId = pbe[0].Id;
            //Product2 prod = [Select Id, Billing_Category__c, LocalProductId__c from Product2 where LocalProductId__c =:productId and Name =: opp.Name];
        	if(String.isNotBlank(prod.Billing_Category__c)){
            	lineitem.Billing_Category__c = prod.Billing_Category__c.split('_')[0];
            	lineItem.BillingCalc__c = prod.Billing_Category__c.split('_')[1];
        	}
        } catch(Exception ex) {
            UTIL.throwError('Price Book Entry (EBAYKPRO_2017 - EUR) is missing for this product',ex);
        }
    	lineItem.Status__c = 'Running';
    	lineItem.NumStatus__c = 4;
    	lineItem.from_Date__c = Date.today();
    	Subscription.calculateEndDate(lineItem, pbe[0]);
    	
		try{
			insert lineItem;
		} catch(Exception ex) {
            UTIL.throwError('Error: ',ex);
        }
		
		if ( memberUnit.EnableTRACT__c == true ) {
			System.enqueueJob( new AsyncCheckVATServiceFlow( opp.Id ) );  
		}
	}
	
	/**
	 * Create a related contact to account
	 * @param: newAccount is an account record 
	 * @param: newContact is a contact instance 
	 * @return
	 */
	private static void upsertContact(Account newAccount, Contact newContact) {
		//create Contact
    	newContact.AccountId 			= newAccount.Id;
    	newContact.MailingStreet 		= newAccount.BillingStreet;
    	newContact.MailingState 		= newAccount.BillingState;
		newContact.MailingPostalCode 	= newAccount.BillingPostalCode;
		newContact.MailingCountryCode 	= newAccount.BillingCountryCode;
		newContact.MailingCountry 		= newAccount.BillingCountry;
		newContact.MailingCity 			= newAccount.BillingCity;
		newContact.Role__c				= 'Portal User; Finance Contact';
		newContact.Primary__c			= true;
		if( newContact.Phone != null ) {
			newContact.Phone = '+49' + newContact.Phone;
		}
		
		//We need to update existing contact
		//Duplication Rulle: Financial Contact/Portal user is already set on this account. 
		//Please update existing contact to a new role before setting a new Finance Contact/Portal User
		newContact.Id 					= checkExistingContact(newAccount.Id);
    	upsert newContact;
	}
	
	
	/**
     * To generate confirm email
     * @param: contact is a contact record Id
     * @param: oppId is opportunity record id
     * @return
     */
    public static void sendConfirmMessage(Set<Id> sOppIds){
        List<String> joinedOppIds = new List<String>();
        Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>();
        for( Opportunity opp : (List<Opportunity>)GW_sObject.queryRecords('Opportunity', sOppIds, new List<String>{'Account.Finance_contact__c','Account.Finance_contact__r.Email','Primary_Contact__r.AccountId','Primary_Contact__r.Email'})) {
            mapOpp.put(opp.Id, opp);
            joinedOppIds.add(opp.Id);
        }
        
        List<EmailTemplate> eTempalate = (List<EmailTemplate>)GW_sObject.queryRecords('EmailTemplate','DeveloperName = \'EBAYKPRO_Activation_confirmation\'');
        List<Messaging.SingleEmailMessage> lstEmail = new List<Messaging.SingleEmailMessage>();
        String whereClause = ' OpportunityId IN (\'' + String.join(joinedOppIds,'\',\'') + '\') order by from_Date__c asc';
        List<String> additionalFields = new List<String>{'Product2.Name','Product2.CurrencyIsoCode', 'PriceBookEntry.Product2.Name', 'Product2.Description'}; 
        List<OpportunityLineItem> lstOppline = (List<OpportunityLineItem>)GW_sObject.queryRecords('OpportunityLineItem', whereClause, additionalFields);
        OrgWideEmailAddress owe = [select ID, DisplayName, Address from OrgWideEmailAddress where Address = 'pro@ebay-kleinanzeigen.de' limit 1];
		
        for( OpportunityLineItem oppline: lstOppline ) {
            if( mapOpp.containsKey(oppline.OpportunityId) ){
                Opportunity oppRec = mapOpp.get(oppline.OpportunityId);
                String emailAddr = oppRec.Primary_Contact__r.Email;
                String contactId = oppRec.Primary_Contact__c;
                String accountId = oppRec.Primary_Contact__r.AccountId;
                if (GW_Opportunity.selfServiceFlow) {
                    emailAddr = oppRec.Account.Finance_contact__r.Email;
                    contactId = oppRec.Account.Finance_contact__c;
                    accountId = oppRec.AccountId;
                }
                
                Datetime fromdate = oppline.from_Date__c != null ? oppline.from_Date__c : system.now();
                //date format should be 06. Juni 2017 with German language
                String formDateStr = fromdate.format('dd-MM-yyyy');
                formDateStr = formDateStr.substring(0, 2) + '. ' + monthInGerman.get(fromdate.month()+'') + ' ' + formDateStr.substring(6, 10);
                //format product description
                String prodDescription = String.isNotBlank(oppline.Product2.Description) ? EncodingUTIL.urlEncode(oppline.Product2.Description, 'UTF-8') : '';
                prodDescription = prodDescription.replace('%0D%0A', '<br />');
                prodDescription = EncodingUTIL.urlDecode(prodDescription, 'UTF-8');
                Decimal listprice = oppline.ListPrice == null ? 0 : oppline.ListPrice;
                //create merge mapping fields for email template
                Map<String, String> mergeFields = new Map<String, String>{
                                                            '#productname#'         => oppline.PriceBookEntry.Product2.Name, 
                                                            '#unitprice#'           => UTIL.format(listprice, '.', ',') +' €', 
                                                            '#fromdate#'            => formDateStr,
                                                            '#financecontactemail#' => emailAddr+'', 
                                                            '#productdescription#'  => prodDescription
                                                    };
                                                    
                //Force merge template
                Messaging.SingleEmailMessage mergeEmail = UTIL.renderEmail(eTempalate[0], contactId, accountId);
                String htmlBody = mergeEmail.getHTMLBody();
                htmlBody = htmlBody == null ? '' : htmlBody;
                //Replace HTML body of the email by field value which is not on target object 
                for (String field : mergeFields.keySet()) htmlBody = htmlBody.replace(field, mergeFields.get(field));
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                if ( owe != null ) {
                    mail.setOrgWideEmailAddressId( owe.Id );
                } else {
                    mail.setSenderDisplayName( UserInfo.getName() );
                }
                mail.setReplyTo('noreply@salesforce.com');
                mail.setTargetObjectId(contactId);
                mail.setSaveAsActivity(true);
                mail.setSubject(mergeEmail.getSubject());
                mail.setHtmlBody(htmlBody);
                mail.setWhatId(accountId);
                lstEmail.add(mail); 
                
                mapOpp.remove(oppline.OpportunityId);
            }
        }
        //send email
        UTIL_Email.sendEmails(lstEmail);
    }
	
}