public class UTIL_RecordRestriction {
    public static List<RecordRestrictions__c> restrictions;
    private static Map<String,RecordRestrictions__c> mapRestrictions = new Map<String,RecordRestrictions__c>();
    private static Profile adminProfile {
        get {
            if (adminProfile == null ) adminProfile = GW_User.getProfileById(GW_User.ADMINPROFILEID);
            return adminProfile;
        }
        private set {}
       
    } 
    
    private static final String ANYPROFILE = 'ANY';
    private static final String ANYLOB = 'ANY';
    private static final String LOBFIELD = 'LineOfBusiness__c';
    public static Map<String,Map<String,Map<Integer,List<RestrictionRule>>>> restrictionRuleMap = new Map<String,Map<String,Map<Integer,List<RestrictionRule>>>>(); 
    
    private static List<RecordRestrictions__c> defaultRestrictions = new List<RecordRestrictions__c> {        
        new RecordRestrictions__c(Name='Opportunity key fields restrictions',LineOfBusiness__c='',LockedFields__c='Lost__c,Account,Billing_Account__c,Primary_Contact__c,CloseDate',LockRecord__c=false,Message__c='Key fields cannot be changed after the opportunity was signed.',ObjectName__c='Opportunity',Profiles__c='',Active__c=TRUE,StatusNumbers__c='2,3,4,5' ),
        new RecordRestrictions__c(Name='Opportunity Deletion Restriction',LineOfBusiness__c='',LockedFields__c='',LockRecord__c=true,Message__c='Opportunity cannot be deleted',ObjectName__c='Opportunity',Profiles__c='',Active__c=TRUE,StatusNumbers__c='1,2,3,4,5' ),
		new RecordRestrictions__c(Name='Lock RS when Invoice Sent',LineOfBusiness__c='',LockedFields__c='Invoice__c,From_Date__c,Until_Date__c,Revenue__c,QuantityBilled__c,QuantityDelivered__c,Revenue__c',LockRecord__c=true,Message__c='Invoice has been sent to billing for depending RS.',ObjectName__c='RS__c',Profiles__c='',Active__c=TRUE,StatusNumbers__c='7' ),
        new RecordRestrictions__c(Name='Lock Invoices Sent',LineOfBusiness__c='',LockedFields__c='BillingAccount__c,Cancelled__c,Amount__c,NumLineItems__c,MinInvLineStatus__c,Status__c',LockRecord__c=true,Message__c='Invoice has been sent to billing.',ObjectName__c='Invoice__c',Profiles__c='',Active__c=TRUE,StatusNumbers__c='7' ),
        new RecordRestrictions__c(Name='InvoiceLine restrictions',LineOfBusiness__c='',LockedFields__c='NumStatus__c,UniqueKey__c,FQ_SyncTimestamp__c,FQ_SyncStatus__c,Invoice__c,Amount__c',LockRecord__c=true,Message__c='InvoiceLine has been sent to Billing',ObjectName__c='InvoiceLine__c',Profiles__c='',Active__c=TRUE,StatusNumbers__c='7' )                                            
	}; 
    
    Static {
        restrictions = RecordRestrictions__c.getall().values();
        for (RecordRestrictions__c restr : restrictions) mapRestrictions.put(restr.Name, restr);
        builtRuleMap();
    }
     
    // check for Field Change Locks
    public static void checkFieldLocks(sObject so, sObject oldSo) {
        if (!bypassActive() ) { // only perform if no bypass is active for an admin user
            String objectName = so.getSObjectType().getDescribe().getName();
            if ( !GW_sObject.fieldExists(objectName,'NumStatus__c') ) return;
            
            List<RestrictionRule> matchingRules = getMatchingRules(so, objectName);
            if (matchingRules == null || matchingRules.isEmpty() ) return;
            // check field locks
            if (oldSo != null) {
            	
            	checkLockedFieldsForChanges(so, oldSo, getLockedFields(matchingRules), objectName, getMapFieldRuleMessages(matchingRules));
            }	
        }
    }
    
    // check for Deletion Lock
    public static void checkDeletionLock(sObject so) {
        if (!bypassActive()) { // only perform if no bypass is active for an admin user
            String objectName = so.getSObjectType().getDescribe().getName();
            if ( !GW_sObject.fieldExists(objectName,'NumStatus__c') ) return;
            
            List<RestrictionRule> matchingRules = getMatchingRules(so, objectName);
            if (matchingRules == null || matchingRules.isEmpty() ) return;
            //  check deletion Lock
            for (RestrictionRule rr : matchingRules) {
                if (rr.lockRecord) {
                    String errorMsg = 'Updating '+objectName+' record ['+so.Id+'], is not allowed at this time. ';
                    errorMsg += ' '+rr.message;
                    so.addError(errorMsg);
                }
            }
        }
    }
    
    private static List<RestrictionRule> getMatchingRules(sObject so, String objectName) {
    	// getting rules
        String userProfile = !GW_User.userProfileMap.containskey(Userinfo.getProfileId())  ? null: GW_User.userProfileMap.get( Userinfo.getProfileId() ).Name;
        String lineOfBusiness;
        if ( GW_sObject.fieldExists(objectName,'LineOfBusiness__c') ) lineOfBusiness = (String) so.get('LineOfBusiness__c');
        else lineOfBusiness = ANYLOB;
        return getRestrictions(objectName, userProfile, lineOfBusiness, (so.get('NumStatus__c')!=null?((Decimal) so.get('NumStatus__c')).intValue():0));    
    }
    
    private static Map<String,String> getMapFieldRuleMessages(List<RestrictionRule> matchingRules) {
        Map<String,String> mapFieldRuleMessage = new Map<String,String>();
        for (RestrictionRule rr : matchingRules) {
            if (rr.lockedFields != null) {
                for (string field : rr.lockedFields) {
                    mapFieldRuleMessage.put(field,rr.message);
                }
            }
        }
        return mapFieldRuleMessage;  
    } 
    private static Set<String> getLockedFields(List<RestrictionRule> matchingRules) {
        Set<String> setLockedFields = new Set<String>();
        for (RestrictionRule rr : matchingRules) {
            if (rr.lockedFields != null) setLockedFields.addAll(rr.lockedFields); // merge all locked fields from different rules
        } 
        return setLockedFields;
    }
    
    private static void checkLockedFieldsForChanges(sObject so, sObject oldSo, Set<String> setLockedFields, String objectName, Map<String,String> mapFieldRuleMessage) {

        Map<String,Set<String>> violationMessageFieldsMap = new Map<String,Set<String>>();
        Set<String> messageFields; 
        String violationMessage;
        for (String field : setLockedFields) {
            if ( so.get(field) <> oldSo.get(field) ) {
            	violationMessage = mapFieldRuleMessage.get( field );
            	messageFields = violationMessageFieldsMap.get( violationMessage );
            	if( messageFields == null ){
            		messageFields = new Set<String>();
            		violationMessageFieldsMap.put( violationMessage , messageFields ); 
            	} 
            	messageFields.add( field );
            }	
        }
        
        String objRef = ( String ) ( so.get('Name') == null ? so.Id : so.get('Name') );
        
        if( violationMessageFieldsMap.size() > 0 ) {
            
            String errorMsg = 'Cannot save ' + objectName + ', record [' + objRef + '], because of the following restrictions: ';
            String ruleMessages = '';
            for( String message : violationMessageFieldsMap.keyset() ){
            	messageFields = violationMessageFieldsMap.get( message );
                errorMsg += '[' + messageFields + ']: ' + message;
            }
            so.addError(errorMsg, false);
        } 
    }
    
    public static List<RestrictionRule> getRestrictions(String objectName, String profileName, String lineOfBusiness, Integer statusNum) {
        List<RestrictionRule> matchingRules = new List<RestrictionRule>();
        
        // Retrieve rules for this Object/LoB combi
        if (restrictionRuleMap.get(objectName+'_'+lineOfBusiness) != null ) {
       
            // get rules for specified profile
            if( restrictionRuleMap.get(objectName+'_'+lineOfBusiness).get(profileName) != null &&
              	restrictionRuleMap.get(objectName+'_'+lineOfBusiness).get(profileName).get(statusNum) != null ) 
        			matchingRules.addAll(restrictionRuleMap.get(objectName+'_'+lineOfBusiness).get(profileName).get(statusNum));
        
        	// get rules for valid for all profiles 
        	if( restrictionRuleMap.get(objectName+'_'+lineOfBusiness).get(ANYPROFILE) != null &&
              	restrictionRuleMap.get(objectName+'_'+lineOfBusiness).get(ANYPROFILE).get(statusNum) != null ) 
        			matchingRules.addAll(restrictionRuleMap.get(objectName+'_'+lineOfBusiness).get(ANYPROFILE).get(statusNum));
        }
        
        // Retrieve rules for this Object, active for ANY LoB
        if (restrictionRuleMap.get(objectName+'_'+ANYLOB) != null ) {
       
            // get rules for specified profile
            if( restrictionRuleMap.get(objectName+'_'+ANYLOB).get(profileName) != null &&
              	restrictionRuleMap.get(objectName+'_'+ANYLOB).get(profileName).get(statusNum) != null ) 
        			matchingRules.addAll(restrictionRuleMap.get(objectName+'_'+ANYLOB).get(profileName).get(statusNum));
        
        	// get rules for valid for all profiles 
        	if( restrictionRuleMap.get(objectName+'_'+ANYLOB).get(ANYPROFILE) != null &&
              	restrictionRuleMap.get(objectName+'_'+ANYLOB).get(ANYPROFILE).get(statusNum) != null ) 
        			matchingRules.addAll(restrictionRuleMap.get(objectName+'_'+ANYLOB).get(ANYPROFILE).get(statusNum));
        }
        
        if (matchingRules.size()>0) return matchingRules;
        else return null;
    }
    private static void builtRuleMap() {
        for (RecordRestrictions__c rr : restrictions) {
            if (rr.Active__c) {
                String rr_profiles = String.isBlank(rr.Profiles__c)?ANYPROFILE:rr.Profiles__c; // Set empty Profiles__c field as ANYPROFILES
                String rr_lob = String.isBlank(rr.LineOfBusiness__c)?ANYLOB:rr.LineOfBusiness__c; // Set empty LineOfBusiness__c field as ANYLOB
                
                String objLoB = rr.ObjectName__c+'_'+rr_lob;
                if ( !restrictionRuleMap.containsKey(objLoB) ) restrictionRuleMap.put(objLoB, new Map<String,Map<Integer,List<RestrictionRule>>>() );
                
                List<String> profiles = rr_profiles.split(',');
                
                for (String p : profiles) {
                    if ( !restrictionRuleMap.get(objLoB).containsKey(p)  ) restrictionRuleMap.get(objLoB).put(p, new Map<Integer,List<RestrictionRule>>() );
                    
                    List<String> stringStatusNum = rr.StatusNumbers__c.split(',');
                    List<Integer> statusNums = new List<Integer>();
                    
                    for (String strNum : stringStatusNum ) {
                        Integer statusNum;
                        try {
                            statusNum = integer.valueof( strNum.trim() );   
                        } catch(Exception ex) {
                            UTIL.throwError('Error Building Rulemap. Not a valid statusNumber: '+strNum, ex);
                        }
                        
                        statusNums.add(statusNum);
                    }
                    
                    for (Integer statusNum : statusNums) {
                        if ( !restrictionRuleMap.get(objLoB).get(p).containsKey(statusNum) )  
                            restrictionRuleMap.get(objLoB).get(p).put(statusNum, new List<RestrictionRule>() );
                        
                        restrictionRuleMap.get(objLoB).get(p).get(statusNum).add(new RestrictionRule(rr.ObjectName__c, rr.LineOfBusiness__c,p,statusNum,rr.LockRecord__c,rr.LockedFields__c,rr.Message__c) );
                    }  
                }
            }
        }
    }

    
    public static void createMissingRestrictionRules() {
        List<RecordRestrictions__c> restrictionsToInsert = new List<RecordRestrictions__c>();
        for (RecordRestrictions__c restr : defaultRestrictions ) {
            if (!mapRestrictions.containsKey(restr.Name)) {
                restrictionsToInsert.add(restr);
            }
        }
        if (restrictionsToInsert.size()>0) insert restrictionsToInsert;
    }
    
    // check of bypass (from custom config setting 'AdminRestrictionBypass') is set.
    private static Boolean bypassForAdminActive() {
        Boolean isActive = FALSE;
        Datetime lastMod = UTIL.getConfigLastModified('AdminRestrictionBypass');
        if (lastMod == null) return FALSE;
        Decimal hoursSinceLastMod =  (Decimal) ( Datetime.now().getTime()/1000 - lastMod.getTime()/1000 )/3600; // in hours
        if ( hoursSinceLastMod <= 0.16 && hoursSinceLastMod >= 0) isActive = TRUE; // valid for approx. 10 minutes
        return isActive;
    }
    
    private static Boolean bypassActive() {
        if (Test.IsRunningTest()) {
            return bypassForAdminActive();
        } else if (adminProfile != null && UserInfo.getProfileId() == adminProfile.Id) {
            return bypassForAdminActive();
        } else {
            return false;
        }
    }
    
    public static void requestAdminBypass() {
        Datetime dt = Datetime.now();
        UTIL_Formatter formatter = new UTIL_Formatter();
        formatter.dbDateTime=Datetime.now();        
        String msg = (UserInfo.getUserName()+' requested Bypass '+' @' + formatter.getTimeZoneString() + '(10 mins valid after LastModDate)');
        UTIL.upsertConfig('AdminRestrictionBypass', msg);    
    }
    
    public static void removeAdminBypass() {
        UTIL.delConfig('AdminRestrictionBypass');
    }

    public class RestrictionRule {
        String objectName;
        String lineOfBusiness;
        String profile;
        String message;
        Integer status;
        Boolean lockRecord = false;
        Set<String> lockedFields;
        
        public RestrictionRule(	String objectName, String lineOfBusiness,String profile,Integer status, Boolean lockRecord,String strLockedFields, String message ) {
        	this.objectName = objectName;
            this.lineOfBusiness = lineOfBusiness;
            this.profile = profile;
            this.status = status;
            this.lockRecord = lockRecord;
            this.message = message;
            if(strLockedFields!=null) this.lockedFields = new Set<String>( strLockedFields.split(',') );
        }
    }
}