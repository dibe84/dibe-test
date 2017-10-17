public without sharing class CommunityPortalController {

	public CommunityPortalController() {}

	/*private static string memberUnitId = (Apexpages.currentPage().getParameters().get('memberUnitId') != null)?Apexpages.currentPage().getParameters().get('memberUnitId'):'';
	private static string countryCode;

	public static MemberUnit__c memberUnit {
        get{
            if (memberUnit == null && memberUnitId != null) {
                try {
                    memberUnit = GW_MemberUnit.getMemberUnitList(memberUnitId)[0];
                } catch(Exception ex) {
                    UTIL.throwError('Member Unit ' + memberUnitId + ' is missing ',ex);
                }
            }
            return memberUnit;
        }set;
    }*/

    @AuraEnabled
    public static String getFieldSet( String objectName, String fieldSetsName ){
        List<LSC_Helper.FieldSetMember> fieldSetsList = LSC_Helper.getFieldSet( objectName, fieldSetsName );
        return ( !fieldSetsList.isEmpty() ? JSON.serialize( fieldSetsList ): '');
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

    // create lead
    @AuraEnabled
    public static Map<String, Object> createLead(String leadId, String muId, String member, String leadDetail){

    	Map<String, Object> mResult = new Map<String, Object>{
            'isSuccess' => true,
            'errMsg' => '',
            'leadId' => ''
        };
		try {
	    	Lead newLead = new Lead();
			String memberId = '';
	    	// populate lead
	        for( Object eachLeadDetail : (List<Object>)JSON.deserializeUntyped( leadDetail ) ){
	            Map<String, Object> leadDetailMap = (Map<String, Object>)eachLeadDetail;
	         	
	            newLead.put( (String)leadDetailMap.get('name'), leadDetailMap.get('value') );

	        }

			if( leadId != '' && leadId != null ) newLead.Id = leadId;
            if( member != null ) newLead.Member__c = GW_Member.memberNameMap.get(member).Id;
            if( muId != null ) newLead.MemberUnit__c = GW_MemberUnit.getMemberUnitById(muId).Id;
            newLead.SelfService__c = true;

            //Map<String, Object> foundPossibleDuplicates = CommunityPortalController.findPossibleDuplicates(newLead, 'FirstName,LastName,Company;Email,Status__c');
            //if (Boolean.valueOf(foundPossibleDuplicates.get('isSuccess')) ) return foundPossibleDuplicates;

        	upsert newLead;
        	mResult.put('leadId', newLead.Id);
    	} catch (Exception ex){
    		mResult.put('isSuccess', false);
    		mResult.put('errMsg', ex.getMessage() + '::' + ex.getStackTraceString());
    	}

    	return mResult;

    }

    @AuraEnabled
    public static Map<String, Object> convertLead(String leadId, String accountDetail){
    	Map<String, Object> mResult = new Map<String, Object>{
            'isSuccess' => true,
            'errMsg' => ''
        };

        if (leadId == null){
        	mResult.put('isSuccess', false);
        	mResult.put('errMsg', 'Lead Id cannot be empty');
        }

        try{
        	Lead leadToConvert = GW_Lead.getRecord(Id.valueOf(leadId));
        	for( Object accountData : (List<Object>)JSON.deserializeUntyped( accountDetail ) ){
	            Map<String, Object> accountDetailMap = (Map<String, Object>)accountData;
	           
	            if( ((String)accountDetailMap.get('name')).containsIgnoreCase('phone') )
	            	leadToConvert.put( (String)accountDetailMap.get('name'), '+' + accountDetailMap.get('value') );
	            else
	            	leadToConvert.put( (String)accountDetailMap.get('name'), accountDetailMap.get('value') );
	        }
	        update leadToConvert;


	        if( contactExistsInSF(leadToConvert.Email) && leadToConvert.MemberUnitId__c == 'GTAUS' ) {
	        	mResult.put('isSuccess', false);
	        	mResult.put('errMsg', 'Error: "Sorry, your email is already registered, please call 1300 137 304 to enquire"');
	        	return mResult;
	        }

	        Map<Id, Lead> mapLead = new Map<Id, Lead>();
	        mapLead.put(leadToConvert.Id, leadToConvert);
	        //GW_Account.convertLeadToAccount(mapLead);
	        Database.LeadConvert convertLeadRecord = new Database.LeadConvert();
			convertLeadRecord.setLeadId(leadToConvert.id);
			convertLeadRecord.setDoNotCreateOpportunity(true);
			

			LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
			convertLeadRecord.setConvertedStatus(convertStatus.MasterLabel);

			Database.LeadConvertResult lcr = Database.convertLead(convertLeadRecord);

			CommunityPortalController.addMemberUnitAssociation(lcr.getAccountId(), leadToConvert.MemberUnit__c);

    	}catch (Exception ex) {
    		mResult.put('isSuccess', false);
    		mResult.put('errMsg', ex.getMessage() + '::' + ex.getStackTraceString());
    	}


        return mResult;
    }

    @AuraEnabled
    public static Map<String, Object> updateAccount(String accountId, String accountDetail){
    	Map<String, Object> mResult = new Map<String, Object>{
            'isSuccess' => true,
            'errMsg' => ''
        };

        if (accountId == null){
        	mResult.put('isSuccess', false);
        	mResult.put('errMsg', 'Account Id cannot be empty');
        }

        try{
        	Account account = GW_Account.getRecord(Id.valueOf(accountId));

        	for(Object accountData: (List<Object>)JSON.deserializeUntyped( accountDetail ) ){
	            Map<String, Object> accountDetailMap = (Map<String, Object>)accountData;
	           
	            if( ((String)accountDetailMap.get('name')).containsIgnoreCase('phone') )
	            	account.put( (String)accountDetailMap.get('name'), '+' + accountDetailMap.get('value') );
	            else
	            	account.put( (String)accountDetailMap.get('name'), accountDetailMap.get('value') );
	        }
	        update account;

        }catch(Exception ex){
    		mResult.put('isSuccess', false);
    		mResult.put('errMsg', ex.getMessage() + '::' + ex.getStackTraceString());
        }


        return mResult;
    }


    private static void addMemberUnitAssociation(Id accId, Id muId){
    	Map<Id,List<AccountMemberUnitAssociation__c>> accToAmuaMap = GW_AccountMemberUnitAssociation.getAll(new Set<Id>{ accId });
    	Boolean existingAmua = false;
    	for (AccountMemberUnitAssociation__c amua : accToAmuaMap.get(accId)) {
            if (amua.MemberUnit__c == muId) existingAmua = true;
        }
        if (!existingAmua) {
            AccountMemberUnitAssociation__c accMemberUnitAss = new AccountMemberUnitAssociation__c();
            accMemberUnitAss.Account__c = accId;
            accMemberUnitAss.MemberUnit__c = muId;
            insert accMemberUnitAss;
        }
    }

    private static Boolean contactExistsInSF(String email){
    	if([select count() from Contact where Email =: email] > 0 || [select count() from Account where Email__c =: email] > 0) return true;
    	return false;
    }

    // is this you
    private static Map<String, Object> findPossibleDuplicates(Lead newObject, String compareString ) {
    	Map<String, Object> mResult = new Map<String, Object>{
            'isSuccess' => false,
            'errMsg' => ''
        };

        List<sObject> lstsObject = GW_sObject.queryRecords('Lead', CommunityPortalController.prepareCompareString(compareString, newObject), null, null, null);
        if (lstsObject != null && lstsObject.size() > 0 ) {
        	mResult.put('possibleDuplicate', CommunityPortalController.maskDetails( lstsObject[0] ) );
        	mResult.put('isSuccess', true);
        	return mResult;
		}
    	return mResult;
    }


    private static String prepareCompareString(String compareString, sObject recordObject) {
    	if ( compareString == null || String.isEmpty(compareString) ) return null;

    	List<String> compList1 = compareString.split(';');

		String queryString = '';
		Integer counter = compList1.size();
		while(counter > 0){
		    --counter;
		    String queryString1 = '';
		    for (String record: compList1.get(counter).split(',') ){
		        if (String.isEmpty(queryString1)){
		        	queryString1 = record + ' = \'' + recordObject.get(record) + '\'';
		        } else {        
		            queryString1 += ' and ' + record + ' = \'' + recordObject.get(record) + '\'';
		        }
		    }
		    queryString += '(' + queryString1 +')';
		    if ( counter != 0 ) queryString += ' or ';
		}

    	return String.isEmpty(queryString) ? null : queryString;
    }

    private static Map<String, String> maskDetails(sObject possibleDuplicate) {
    	Map<String, String> result = new Map<String, String>();

    	String firstName = String.valueOf(possibleDuplicate.get('FirstName'));
    	String firstNameMaskIndex = '';
    	for(Integer i = 1; i < firstName.length(); i++) {
    		firstNameMaskIndex += String.valueOf(i) + ',';
    	}


    	result.put('FirstName', CommunityPortalController.maskMe( firstName, firstNameMaskIndex ) );
    	result.put('LastName', CommunityPortalController.maskMe( String.valueOf(possibleDuplicate.get('LastName')), '2,4' ) );

    	return result;
    }

    private static String maskMe(String raw, String charsIndexToMask){

    	try{
	    	List<String> location = charsIndexToMask.split(',');
	    	for (Integer i = 0; i < location.size(); i++){
	    		for(Integer v = 1; v <= raw.length(); v++ ){
	    			if(v == Integer.valueOf(location[i]) ){
		    			if (raw.subString(v, v+1) != '*') {
		    				raw = raw.subString(0, v-1) + '*' + raw.subString(v, raw.length());
		    			}
		    		}

	    		}
	    	}
    		return raw;
		}catch(Exception ex){
			throw ex;
		}

		return null;
    }

    // create opportunity

    // create opportunity line item

    // validate user 

    // send email 

}