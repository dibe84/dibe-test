///////////////////////////////////////////////////////////////////////////
// Class UTIL
// Manages non-application generic utils
// Author:  Jochem van den Heuvel
///////////////////////////////////////////////////////////////////////////
public with sharing class UTIL {

///////////////////////////////////////////////////////////////////////////
// Global context properties
/////////////////////////////////////////////////////////////////////////////
    public static Boolean isRunningTestSetup = false;
    private static String lastTracePoint = '';

    private static Pricebook2 stdPriceBook;  // Singleton, remember when first referenced

///////////////////////////////////////////////////////////////////////////
// Record Cache
///////////////////////////////////////////////////////////////////////////

    // TODO implement generic caching solution
    private static Map<Id, sObject> recordCache = new Map<Id, sObject>();

    public static sObject getCached(Id soId) {
        if (soId==null) return null;
        if (recordCache.containsKey(soId)) return recordCache.get(soId);
        else {
            String sObjectType = GW_sObject.getobjectNameFromId(soId);
            UTIL.log('Record: '+soId+' ('+sObjectType+') not in recordCache. Querying.');
            sObject so = GW_sObject.queryRecord(sObjectType, soId);
            if(so!=null) recordCache.put(so.Id, so);
            return so;
        }
    }
    public static void cacheUncachedRecords(Set<Id> soIds) {
        if (soIds == null || soIds.size() == 0) { return; }

        Set<Id> unCachedIds = new Set<Id>();
        for (Id soId : soIds) {
        	if ( !recordCache.containsKey(soId) && soId != null ) {
                unCachedIds.add(soId);
            }
        }
        if (unCachedIds.size() > 0) {
            Map<String,Set<Id>> objTypeIdSet = GW_sObject.splitIdSetByObjectType(unCachedIds);
            for (String sObjectType : objTypeIdSet.keySet() ) {
            	cache( GW_sObject.queryRecords(sObjectType, objTypeIdSet.get(sObjectType) ) );
            }
        }
    }
    public static Map<Id,sObject> getCachedMap(Set<Id> soIds) {
        if (soIds == null || soIds.size() == 0) { return null; }
        Map<Id, sObject> resultMap = new Map<Id,sObject>();

        cacheUncachedRecords(soIds);

        for (Id soId : soIds) {
           resultMap.put(soId,getCached(soId));
        }
        return resultMap;
    }
    public static void cache(List<sObject> soList) {
        if (soList != null) recordCache.putAll(soList);
    }
    public static void cache(Map<Id,sObject> soMap) {
        if (soMap != null) recordCache.putAll(soMap);
    }
    public static void cache(sObject so) {
        if (so != null) recordCache.put(so.Id,so);
    }
    public static void unCache(Set<Id> ids) {
        if ( ids!=null ) for (Id key : ids) { recordCache.remove(key); }
    }
    public static Boolean inCache(Id soId) {
        return recordCache.containsKey(soId);
    }
    public static Map<Id,sObject> getRelatedFromCache(String fieldName, String fieldValue, String objectName) {
        Map<Id,sObject> relatedObjectMap = new Map<Id,sObject>();
        for(SObject so : recordCache.values()) {
            if(so.getSObjectType().getDescribe().getName() != objectName) continue;
            if(GW_sObject.fieldExists(fieldName, so) && ((String)so.get(fieldName)) == fieldValue) {
                relatedObjectMap.put(so.Id,so);
            }
        }
        return relatedObjectMap;
    }

///////////////////////////////////////////////////////////////////////////
// Logging related methods
///////////////////////////////////////////////////////////////////////////
    private static final System.LoggingLevel LOGLEVEL = LoggingLevel.INFO;
    private static final String LOGITEMPREFIX = '\n##### ';
    private static final String LOGITEMPOSTFIX = '\n\n';

    public static void log(string s) 			{ writeLog( LOGITEMPREFIX +s+LOGITEMPOSTFIX);	}
    public static void log(Object obj)  		{ log(''+obj);    }
    public static void logRaw(string s) 		{ writeLog(s);					}
    public static void logClean(Object obj) 	{ writeLog('' +obj); }
    public static void setTracePoint(String s) 	{ lastTracePoint = s;}
   
    // private methods
    private static void writeLog(String s) { system.debug(LOGLEVEL,s);		}

	// Log Governor Limits
    public static void logLimits(String message) {
        string s = '';
        if (message != null) { // optional message from code
        	s += '\n################################################################';
        	s += '\n## MESSAGE: '+ message;
        	s += '\n################################################################';
    	}
        s += '\n################################################################';
        s += '\n## LIMITS';
        s += '\n################################################################';
        s += '\n## Total SOQL Queries used: '+Limits.getQueries().format()          +' of '+Limits.getLimitQueries().format()+' allowed. ';
        s += '\n## Total Callouts used: '+Limits.getCallouts().format()   +' of '+Limits.getLimitCallouts().format()+' allowed. ';
        s += '\n################################################################';

        UTIL.logRaw(s);
    }

    public static void logLimits() {
    	UTIL.logLimits(null);
    }

    public static void logErrors(String message) {

        string s = '';
        if (message != null) { // optional message from code
        	s += '\n################################################################';
        	s += '\n## ERROR: '+ message;
        	s += '\n################################################################';
        	s += '\n';
    	}
        UTIL.logRaw(s);

        TriggerManager.printStackLog();
    	UTIL.logLimits(null);
    }

    public static String limitRow() {
        Integer Q = Limits.getQueries();
        Integer QR = Limits.getQueryRows();
        Integer CPU = Limits.getCpuTime();
        Integer DS = Limits.getDMLStatements();
        Integer DR =Limits.getDMLRows();
        Integer QJ = Limits.getQueueableJobs();
        Integer HS = Limits.getHeapSize();

        Integer lQ = Limits.getLimitQueries();
        Integer lQR = Limits.getLimitQueryRows();
        Integer lCPU = Limits.getLimitCpuTime();
        Integer lDS = Limits.getLimitDMLStatements();
        Integer lDR = Limits.getLimitDMLRows();
        Integer lQJ = Limits.getLimitQueueableJobs();
        Integer lHS = Limits.getLimitHeapSize();

        String pQ = (100*Q/lQ).format();
        String pQR = (100*QR/lQR).format() ;
        String pCPU = (100*CPU/lCPU).format();
        String pDS = (100*DS/lDS).format();
        String pDR = (100*DR/lDR).format();
        String pHS = (100*HS/lHS).format();

        String output = String.format('Q{0} QR{3}% CPU{5}% DS{6}({7}%) DR{9}% HS{10}({11}%) QJ{12} {13}',
                                                                                new List<String>{
                                                                                    Q.format(), pQ,         // 0,1
                                                                                    QR.format(), pQR,       // 2,3
                                                                                    CPU.format(), pCPU,     // 4,5
                                                                                    DS.format(), pDS,       // 6,7
                                                                                    DR.format(), pDR,       // 8,9
                                                                                    HS.format(), pHS,       // 10,11
                                                                                    QJ.format(), lastTracePoint // 12
                                                                                 }); //
        return output;
    }

    public static void throwError( String message, Exception ex) {
        String msg = message;
        if (ex != null) {
            msg += '\n\n - '+ex.getMessage();
            msg += '\n\n - '+ex.getStackTraceString();
        }

        UTIL.logErrors( msg );
        //writeLog('ERROR',msg,'');
        throw new UTIL.CustomException(msg);
    }

    public static void throwError( String message) {
        throwError( message, null);
    }

    public static void writeLog(String level, String msg, String theClass) {
        Log__c l = new Log__c(
            Level__c = level,
            Short_Message__c = msg.substring(0,msg.length() > 255 ? 255 : msg.length()),
            Extended_Message__c = msg,
            Class__c = theClass
        );

        try {
            insert l;
        } catch (Exception e) {
            UTIL.log('Logger exception: ' + e.getMessage());
        }
    }

    public static List<Log__c> customLogsList = new List<Log__c>();

    public static void insertCustomLogs(){
        if(customLogsList.size() > 0){
            insert customLogsList;
        }
    }

    public static void customLog(String level, String msg, String theClass, Id recordId){
        customLog(level, msg, theClass, recordId, true);
    }

    public static void customLog(String level, String msg, String theClass, Id recordId, Boolean stackCustomLog ){
        Log__c customLog = new Log__c();
        customLog.Level__c = level;
        customLog.Short_Message__c = msg.substring(0,msg.length() > 255 ? 255 : msg.length());
        customLog.Extended_Message__c = msg;
        customLog.Limits__c = UTIL.limitRow();
        customLog.Class__c = theClass;
        customLog.RecordId__c = recordId;
        customLog.User__c = Userinfo.getUserId();
        if(stackCustomLog){
            customLogsList.add(customLog);
        }else{
            insert customLog;
        }
    }

    public static CurrencyType corporateCurrency {
    get {
            if (corporateCurrency == null )
                corporateCurrency = [SELECT ISOCode, ConversionRate FROM CurrencyType WHERE IsActive=TRUE and IsCorporate=TRUE];
            return corporateCurrency;
        }
        private set;
    }

    public static Organization currentOrg {
        get {
            if (currentOrg == null )
                currentOrg = [select Id, IsSandbox, InstanceName from Organization];
            return currentOrg;
        }
        private set;
    }

    public static Boolean isSandbox() {
        return currentOrg.IsSandbox;
    }

	public static String orgIdentifier {
		get {
			if (orgIdentifier == null) {
				if (isSandbox()) {
					List<User> users = [SELECT Id, Name, Username FROM User WHERE Name = 'API'];
					if (users.size() == 1) {
						try {
							orgIdentifier = users.get(0).Username.substringAfterLast('.');
						} catch (Exception e) {
							orgIdentifier = 'Unknown sandbox';
						}
					} else {
						orgIdentifier = 'Unknown Sandbox';
					}
				} else {
					return 'prod';
				}
			}
			return orgIdentifier;
		}
	}

	public static String getProductionUsername(String username) {
		String result = username;
		String orgName = orgIdentifier;
		if (orgName == 'prod') {
			return result;
		} else {
			result = result.replace('.' + orgName, '');
			return result;
		}
	}


///////////////////////////////////////////////////////////////////////////
// Custom Configuration related methods (custom setting: Configuration__c required)
//////////////////////////////////////////////////////////////////////////

    public static String getConfig(String configName) {
        Configuration__c conf = Configuration__c.getInstance(configName);
        if (conf == null ) return null;
        return conf.Value__c;
    }

    public static void delConfig(String configName) {
        Configuration__c conf = Configuration__c.getInstance(configName);
        delete conf;
    }

    public static Datetime getConfigLastModified(String configName) {
        Configuration__c conf = Configuration__c.getInstance(configName);
        if (conf == null ) return null;
        return conf.LastModifiedDate;
    }

    public static void upsertConfig(String configName, String configValue) {
        Configuration__c conf = Configuration__c.getInstance(configName);
        if (conf == null )
            putConfig(configName, configValue);
        else {
        	conf.Value__c = configValue;
        	update conf;
        }
    }

    public static void putConfig(String configName, String configValue) {
        Configuration__c conf = new Configuration__c();
        conf.Name = configName;
        conf.Value__c = configValue;
        insert conf;
    }

///////////////////////////////////////////////////////////////////////////
// Custom ECG Labels related methods (custom setting: Custom_ECG_Labels__c required)
//////////////////////////////////////////////////////////////////////////
    public static string getLabel(String labelName, String memberUnitId, String language){

        String labelValue;
        String csName = memberUnitId + '_' + labelName;
        Custom_ECG_Labels__c customLabel;

        try{
        	customLabel = Custom_ECG_Labels__c.getValues(csName);
        }catch(Exception e){
            throw new UTIL.CustomException('Custom label name does not exist: '+ e.getMessage());
        }

        if(customLabel == NULL){
            throw new UTIL.CustomException('Custom label name does not exist: '+csName);
        }

        if(!string.isBlank(language)){
            try{
            	labelValue = string.valueOf(customLabel.get( language + '__c'));
            }catch(Exception e){
                throw new UTIL.CustomException('Language does not exist: '+ e.getMessage());
            }
        }

        if(labelValue == NULL || labelValue == ''){
            labelValue = string.valueOf(customLabel.get( 'Default__c'));
        }

        labelValue = (labelValue != NULL) ? labelValue : '';

        return labelValue;
    }

    public static string getLabel(String labelName, String memberUnitId, String language, sObject sObj){

        String labelText = getLabel(labelName, memberUnitId, language);
        String labelParsedText = UTIL_StringParser.parseAndReplace(labelText, sObj);

        return labelParsedText;
    }

	public static String formatDate(Date d, String format) {
		if(d == null) return null;
		return ((Datetime) d).format(format);
	}

/////////////////////////////////////////////////////////////////////////
//EmailTemplate related methods
//See: http://salesforce.stackexchange.com/questions/13/using-apex-to-assemble-html-letterhead-emails/8745#8745
////////////////////////////////////////////////////////////////////////

    public static Messaging.SingleEmailMessage renderEmail(EmailTemplate sendTemplate, Id whoId, Id whatId){

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        String[] toAddresses = new String[]{'invalid@emailaddr.es'};

        mail.setToAddresses(toAddresses);
        mail.setUseSignature(false);
        mail.setSaveAsActivity(false);
        mail.setSenderDisplayName('MMPT');
        mail.setTargetObjectId(whoId);
        mail.setWhatId(whatId);
        mail.setTemplateId(sendTemplate.Id);

        Savepoint sp = Database.setSavepoint();
        if (!Test.isRunningTest()) Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        Database.rollback(sp);

        return mail;

    }

    public class CustomException extends Exception {}

    ///////////////////////////////////////////////////////////////////////////
    // SLACK HELPER METHODS
    //////////////////////////////////////////////////////////////////////////

    @Future(Callout=true)
	public static void postExceptionInfoToSlack(String msg) {
        if(SlackConfiguration__c.getAll().size() == 0 || SlackConfiguration__c.getAll().get('ExceptionChannel') == NULL) {
            return;
        }

        try {
    		String channelEndpoint = SlackConfiguration__c.getAll().get('ExceptionChannel').ChannelEndpointURL__c;
            String channelName = SlackConfiguration__c.getAll().get('ExceptionChannel').ChannelName__c;

    		// Construct message
    		Map<String,String> payloadJson = new Map<String,String>();
    		payloadJson.put('channel',channelName);
    		payloadJson.put('username','Exception info - ' + (UTIL.isSandbox()?'SANDBOX':'PROD'));
    		payloadJson.put('text',msg);
    		payloadJson.put('icon_emoji',':trumpoo:');

    		Http h = new Http();
    		HttpRequest req = new HttpRequest();
    		req.setEndpoint(channelEndpoint);
    		req.setMethod('POST');
    		req.setBody(JSON.serialize(payloadJson));
    		HttpResponse res = h.send(req);

    		UTIL.Log('XX Slack response: ' + res);
        } catch (Exception ex) {
            UTIL.Log('XX Exception when posting to slack: ' + ex);
        }
	}

	public static void emailExceptionInfoToSlack(String msg) {
        if(SlackConfiguration__c.getAll().size() == 0 || SlackConfiguration__c.getAll().get('ExceptionChannel') == NULL) {
            return;
        }

        try {
    		String channelEmail = SlackConfiguration__c.getAll().get('ExceptionChannel').ChannelEmail__c;
            msg = msg.replaceAll('\n','<br>');
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String displayName = 'Exception info - ' + (UTIL.isSandbox()?'SANDBOX':'PROD');
            mail.setToAddresses(new String[]{channelEmail});
            mail.setUseSignature(false);
            mail.setSaveAsActivity(false);
            mail.setSenderDisplayName(displayName);
            mail.setTargetObjectId(Userinfo.getUserId());
            mail.setHtmlBody(msg);

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});

        } catch (Exception ex) {
            UTIL.Log('XX Exception when sending email to slack: ' + ex);
        }
	}

    ///////////////////////////////////////////////////////////////////////////
    // MISCELLANEOUS HELPER METHODS
    //////////////////////////////////////////////////////////////////////////

    public static Set<String> getIdSetAsStringSet(Set<Id> idSet) {
        Set<String> retSet = new Set<String>();
        for(Id myId : idSet) {
            retSet.add((String)myId);
        }
        return retSet;
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    //getStdPricebookId : as of V31, testmethods can locate std pricebook wo seeAlldata=true
    ////////////////////////////////////////////////////////////////////////////////////////

    public static ID getStdPricebookId() {
        if (Test.isRunningTest()) return Test.getStandardPricebookId();
        return getStdPricebook().id;
    }

    ////////////////////////////
    //getStdPriceBook: Singleton
    ////////////////////////////

    public static Pricebook2 getStdPriceBook() {
        if (stdPriceBook == null)
            stdPriceBook    = [select id, name from Pricebook2 where isStandard = true limit 1];
        return stdPriceBook;
    }
    
    /**
	 * To format decimal to xxx,xxx,x.xx
	 * @param: val decimal value to be formatted 
	 * @param: osep is orginal separator
	 * @param: nsep is new separator
	 * @return a string with correct format
	 */
	public static String format(Decimal val, String osep, String nsep) {
        if(val == null){val = 0;}
        String s, tmp; Integer i = 6;
        s = val.setScale(2).toPlainString().replace(osep, nsep);
        while(s.length() > i)
        {
            tmp = s.substring(0, s.length() - i) + osep + s.substring(s.length() - i);
            s = tmp;
            i += 4;
        }
        return s ;
    }
}