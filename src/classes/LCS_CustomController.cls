public without sharing class LCS_CustomController {
	
    @AuraEnabled
    public static List<Site_Alert__c> getActiveSiteAlert(String siteName) {
        String whereClause = 'Active__c = true And site__c =\'' + siteName + '\'';
        List<Site_Alert__c> lstResult =  GW_sObject.queryRecords( 'Site_Alert__c' , new List<String>{'id','Alert_Text__c','Alert_Type__c'} , whereClause);
       
        return lstResult;
    }  
    
    @AuraEnabled
    public static Object getAllSiteLinks(String curSitePrefix, String curSuffix, Boolean isInitFooterStructure) {
    	List<Object> res = new List<Object>();
    	res.add(getAllSiteLinks(curSitePrefix,curSuffix));
    	if(isInitFooterStructure) {
    		res.add(getFooterStructure(curSitePrefix,curSuffix));
    	}
    	return res;
    }
    
    @AuraEnabled
    public static Object getArticleViewCount(List<String> lstArticles, String curObject) { 
    	
    	Map<String,String> mapParentIds = new Map<String,String>();
    	List<Object> res = new List<Object>();
    	try{
    		String queryString = 'select id,KnowledgeArticleId,Title  From ' + curObject +'__kav  where Title in: lstArticles And PublishStatus= \'online\'  And Language = \'da\' ';
    		for(SObject obj: Database.query(queryString)){
    			String key = 'Title';
     			mapParentIds.put(obj.get('KnowledgeArticleId')+'',obj.get(key)+'');
	     	}
	     	 Map<String,Decimal> mapResult = new  Map<String,Decimal>();
	     	 Set<String> setParentIds = mapParentIds.keyset();
	     	 String queryView =  'Select id,ViewCount,parentId From ' + curObject +'__ViewStat where parentId in : setParentIds  And Channel = \'Allchannels\'';
	     	for(SObject obj:Database.query(queryView)){
	     		String key = obj.get('parentId')+'';
	     		String validKey = mapParentIds.get(key);
	     		if(validKey != null) {
	     			mapResult.put(validKey,Decimal.valueOf(obj.get('ViewCount')+''));
	     		}
	     	}
    		res.add(mapResult);
    	}catch(Exception e) {
    		res.add('Error'+ e.getMessage());
    	}
        return res;
    }
    
    @AuraEnabled
    public static Object getInitialData(String curObject, String categoryType) { 
    	List<Object> lstResult = new List<Object>();
    	try {
    		//For List most view of Article
    		List<String> lstParentIds = new List<String>();
    		String queryView =  'Select id,parentId From ' + curObject +'__ViewStat where Channel = \'Allchannels\' Order by ViewCount DESC Limit 6';
    		for(SObject obj: Database.query(queryView)){
    			lstParentIds.add(obj.get('parentId')+'');
	     	}
	     	Map<String,String> mapArticleNumber = new Map<String,String>();
	       	String queryParent = 'Select ArticleNumber,Id From ' + curObject +'__ka  where Id in: lstParentIds';
	       	for(SObject obj: Database.query(queryParent)){
	       		mapArticleNumber.put( obj.get('Id')+'',obj.get('ArticleNumber')+'');
	       	}
	     	List<String> lstArticleNumber =  mapArticleNumber.values();
	     	Map<String,SObject> mapArticles = new Map<String,SObject>();
	     	String queryString = 'select id,UrlName,Title,ArticleNumber  From ' + curObject +'__kav  where ArticleNumber in: lstArticleNumber And PublishStatus= \'online\'  And Language = \'da\' ';
	     	for(SObject s: Database.query(queryString)) {
	     		mapArticles.put(s.get('ArticleNumber')+'',s);
	     	}
	     	List<SObject> lstArticles = new List<SObject>();
	     	for(String objId:lstParentIds) {
	     		if( mapArticleNumber.containskey(objId)) {
	     			String articleNumber = mapArticleNumber.get(objId);
	     			if( mapArticles.containskey(articleNumber) ) {
	     				lstArticles.add(mapArticles.get(articleNumber));
	     			}
	     		}
	     	}
	     	lstResult.add(lstArticles);
       		//For view all Article
	        String topLvName = '';
	        for(Schema.DescribeDataCategoryGroupStructureResult result : LCS_UTILS.getListDataCategory(categoryType)){
	            DataCategory [] toplevelCategories = result.getTopCategories(); // Get top categories
	             for (DataCategory topcategory : toplevelCategories) {
	                topLvName =  topcategory.getName();
	            }
	        }
	        lstResult.add(topLvName);
	     	
    	}catch(Exception e) {
    		lstResult.add('Error==='+ e.getMessage());
    	}
    	return lstResult;
    }

    @AuraEnabled
    public static String getDataCategoryLabel(String cateroyType, String categoryName) {
        Map<String,String> mapCategoryAndChild =  new Map<String,String>();
        for(Schema.DescribeDataCategoryGroupStructureResult result : LCS_UTILS.getListDataCategory(cateroyType)){
            DataCategory [] toplevelCategories = result.getTopCategories(); // Get top categories
            for (DataCategory topcategory : toplevelCategories) {
                for (DataCategory lvl2category : topcategory.getChildCategories()) {
                    mapCategoryAndChild.put(lvl2category.getName(), lvl2category.getLabel());
                }
            }
        }
        return mapCategoryAndChild.containskey(categoryName) ? mapCategoryAndChild.get(categoryName) : categoryName;
    }


    @AuraEnabled
    public static Object getCurrentDate(String curName) {
        //read from custom setting
        String devName = curName + LCS_BusinessHoursDetailsController.CALLMEBACK;
        DevSettings__c devSetting = DevSettings__c.getInstance(devName);
        if(devSetting == null) devSetting = new DevSettings__c(Name= devName, value__c='Active');
         
        Map<String,Boolean> mapResult = new Map<String,Boolean>{ 'isBusinessHour'=> true };
        String whereClause = 'isActive = true And Name =\'' + curName + '\'';
        List<BusinessHours> lstResult =  GW_sObject.queryRecords('BusinessHours', new List<String>{'id'}, whereClause);
        if(!lstResult.isEmpty()) {
            String buhId = lstResult.get(0).id;
            Boolean isBusinessHour = BusinessHours.isWithin(buhId, system.now());
            mapResult.put('isBusinessHour', isBusinessHour);
        }
       
        List<Object> res = new List<Object>();
        res.add(mapResult);
        res.add(devSetting);
        return res;
    }   

    
    @AuraEnabled
    public static Object getFieldSet(String objectName, String fieldSetsName, String preSettingName){
    	List<Object> lstResult = new List<Object>();
        List<LCS_UTILS.FieldSetMember> fieldSetsList = LCS_UTILS.getFieldSetMember( objectName, fieldSetsName );
        if(!fieldSetsList.isEmpty()){
            lstResult.add(JSON.serialize(fieldSetsList));    
        } else {
        	lstResult.add(new List<LCS_UTILS.FieldSetMember>());    
        }
        
        DevSettings__c devSetting = DevSettings__c.getInstance(preSettingName);
        String originalChannel = '';
   		if( devSetting!= null  &&  String.isNotBlank(devSetting.Description__c)) {
   			for( Object eachCallLogDetail : (List<Object>)JSON.deserializeUntyped( devSetting.Description__c ) ){
	            Map<String, Object> callLogDetailMap = (Map<String, Object>)eachCallLogDetail;
	            String fieldName = (String)callLogDetailMap.get('name');
	            if (fieldName == 'OriginChannel__c') {
	            	originalChannel = (String)callLogDetailMap.get('value');
	            }
	        }
   		}
   		List<String> lstValCategorys = new List<String>();
        Map<String,List<String>> mapPickList = LCS_UTILS.getDependentOptionsImpl(objectName, 'OriginChannel__c' , 'Category__c');
   		if(mapPickList != null && mapPickList.containskey(originalChannel)) {
   			lstValCategorys = mapPickList.get(originalChannel);
   		}
        lstResult.add(lstValCategorys);
        return lstResult;
    }
    
    @AuraEnabled
    public static Object createCallLog(String callLogDetail, String preSettingName) {
    	
        List<Object> res = new List<Object>();
    	Map<String,String> mapResult = new Map<String,String>{'isSuccess' => 'true'};

        DevSettings__c devSetting = DevSettings__c.getInstance(preSettingName);
        if(devSetting == null || String.isBlank(devSetting.Description__c)){
            return new List<Object>{ 
                new Map<String,String>{'Error' => 'Custom Settings DevSettings__c do not have mapping data for ' + preSettingName, 'isSuccess'=> 'false'} 
            };
        }

        CallLog__c callLog = new CallLog__c(); 
        //init predefined value
        initCallLogSettings(callLog, devSetting.Description__c);
        //init value from user input
        initCallLogSettings(callLog, callLogDetail);
        String fieldVal = callLog.SuppliedPhone__c;
        fieldVal = (fieldVal == null ? '' : fieldVal.trim());
        if(fieldVal.indexOf('+') == -1 || fieldVal.lastIndexOf('+') != 0) {
        	callLog.SuppliedPhone__c = '+' + fieldVal;
        }
		List<RecordType> lstRecords = GW_sObject.queryRecords('RecordType',' SobjectType=\'CallLog__c\' And DeveloperName =\'ECGDK_CS\'');
		if(!lstRecords.isEmpty()) callLog.recordTypeId = lstRecords.get(0).Id;
		
		List<Group> lstOwners = GW_sObject.queryRecords('Group',' Name=\'ECGDK_CS_CallLog\' And Type =\'Queue\'');
		if(!lstOwners.isEmpty()) callLog.OwnerId = lstOwners.get(0).Id;
    	
        try {	
            Contact clContact = getCallLogContact(callLog);
    		callLog.ContactId__c = clContact.Id;
    		insert callLog;
    	} catch(Exception e) {
    		mapResult.put('isSuccess', 'false');
    		mapResult.put('Error', e.getMessage());
    	}
        res.add(mapResult);
        return res;
    }  
    
    private static Map<String,String> getAllSiteLinks(String curSitePrefix, String curSuffix) {
    	Map<String,String> mapLinks = new Map<String,String>();
    	Map<String,DevSettings__c> mapAllSetting = DevSettings__c.getall();
    	try{
    		
    		for(DevSettings__c devSetting: mapAllSetting.values()) {
    			String key = devSetting.Name;
    			if(key.startsWithIgnoreCase(curSitePrefix) && key.endsWithIgnoreCase(curSuffix)) {
    				String linkKeys = key.replace(curSitePrefix+'_','');
    				 mapLinks.put(linkKeys,devSetting.description__c);
    			}	
    		}
    	}catch(Exception e) {
    	  mapLinks.put('Error',e.getMessage());
    	}
        return mapLinks;
    }
    
    private static Map<String,List<Map<String,String>>> getFooterStructure(String curSitePrefix, String curSuffix) {
    	Map<String,List<Map<String,String>>> mapResult = new Map<String,List<Map<String,String>>>();
    	Map<String,DevSettings__c> mapAllSetting = DevSettings__c.getall();
    	try{
    		String currentFooter = curSitePrefix + '_Footer_Structure';
    		if(mapAllSetting.containskey(currentFooter)) {
    			Map<String,List<String>> mapStructures =  (Map<String,List<String>>)JSON.deserialize(mapAllSetting.get(currentFooter).description__c,Map<String,List<String>>.class);
    			for(String key: mapStructures.keyset()) {
    				mapResult.put(key, new List<Map<String,String>>());
    				for(String structure: mapStructures.get(key)) {
    					//subkey = 'ECGDKDBA_Help_link'
    					String subKey = curSitePrefix + '_'+ structure + '_' + curSuffix;
    					if(mapAllSetting.containskey(subKey)) {
    						DevSettings__c devSetting = mapAllSetting.get(subKey);
    						mapResult.get(key).add(new Map<String,String>{'Label'=> devSetting.value__c, 'Url'=> devSetting.description__c});
    					}
    				}
    			}
    		}
    		
    	}catch(Exception e) {
    	 mapResult.put('Error', new List<Map<String,String>>());
    	}
        return mapResult;
    }   
    
    private static void initCallLogSettings(CallLog__c clLog, String clSetting){
        for(Object eachCallLogDetail : (List<Object>)JSON.deserializeUntyped(clSetting)){
            Map<String, Object> callLogDetailMap = (Map<String, Object>)eachCallLogDetail;
            clLog.put((String)callLogDetailMap.get('name'), callLogDetailMap.get('value'));
        }
    }
  
    private static Contact getCallLogContact(CallLog__c cl){
        String whereClause = 'Email  = \'' + cl.SuppliedEmail__c + '\'';
        List<Contact> lstContacts =  GW_sObject.queryRecords( 'Contact' , new List<String>{'id'} , whereClause);
        if(lstContacts.isEmpty()) {
            lstContacts.add(new Contact(Email = cl.SuppliedEmail__c, LastName = cl.SuppliedName__c, FirstName = '_', 
                                        Phone = cl.SuppliedPhone__c, MemberUnitId__c = cl.MemberUnitId__c
                                    ));
            insert lstContacts;
        }
        return lstContacts.get(0);
    }

}