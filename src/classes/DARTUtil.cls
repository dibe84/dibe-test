/**
 Utilities
*/
public with sharing class DARTUtil {
     
    final static String DART_DATEFORMAT = 'EEE MMM dd HH:mm z yyyy';
    public final static String DART_DATEFORMAT_QUERY = 'yyyy-MM-dd';
    
    public static String CLIENT_AUTH_URL = 'https://www.google.com/accounts/ClientLogin';
     
    
    public final static String DART5 = 'DART5';
    public final static String DART6 = 'DART6';
    public final static String PRODUCT_PACKAGE = 'Package';
    public final static String AUTHENTICATION_TYPE = 'ClientLogin';
    public final static String URL_INSTANCE = 'https://'+URL.getSalesforceBaseURL().getHost();  
    public final static String EMAIL_SUBJECT = 'Availability Forecast' ;
    public final static String EMAIL_SUBJECT_BOOKING = 'Booking results' ;
    
    public final static String USER_ROLE_SALESPERSON = '1';
    public final static String USER_ROLE_PRIMARY_TRAFICKER = '2';
    
    public final static String TEAM_MEMBER_ROLE = 'Primary Trafficker'; 
    public static final String ENDPOINT_GOOGLE_OAUTH2_TOKEN = 'https://accounts.google.com/o/oauth2/token';
     
    
    /** 
     * @param username
     * @param password
     * @param server param
     * @param method
     * i.e:
     * 'myacc','mypwd','/xmlserver/','POST'
     */
    public static String composeDigestAuthorizationHeader(String paramString1, String paramString2, String paramString3, String paramString4)
    {
        try
        { 
          
          String str1 = 'DART';
          String str2 = computeDigest(System.now().format(DART_DATEFORMAT));//Wed Sep 05 15:37:21 ICT 2012
          String str3 = '00000001';
          String str4 = computeDigest(System.now().format(DART_DATEFORMAT));
          String str5 = 'auth';
          String str6 = computeDigest(paramString1 + ':' + str1 + ':' + paramString2);
          String str7 = computeDigest(paramString4 + ':' + paramString3);
          String str8 = str2 + ':' + str3 + ':' + str4 + ':' + str5 + ':' + str7;
          String str9 = computeDigest(str6 + ':' + str8);
          String strDigest = 'Digest ';
          strDigest+='username="' + paramString1 + '", realm="' + str1 + '", qop="' + str5 + '", ';
          strDigest+='algorithm="MD5", uri="' + paramString3 + '", nonce="' + str2 + '", nc=' + str3 + ', ';
          strDigest+='cnonce="' + str4 + '", response="' + str9 + '"';
          //System.debug('>>>>>>>>>>>>System.now().format(df):'+System.now().format(df));
          //System.debug('>>>>strDigest.toString:'+strDigest);
          return strDigest;
        }
        catch (Exception ex)
        {
            //System.debug('>>>>>>>>>>>>ERRRROR:'+ex);
            throw new ExceptionGroup.DigestException('Could not compose digest authorization.\n'+ex.getStackTraceString());
        } 
        return null;
    }
    /**
     * @param paramString
     * @return string
     */
    private static String computeDigest(String paramString) 
    {
        Blob hash = Crypto.generateDigest('MD5',Blob.valueOf(paramString));
        String hexDigest = EncodingUtil.convertToHex(hash);
        
        return  hexDigest;
    }
    static Map<String, String> mapDart6Token = new Map<String, String>();
    /**
     * @param countryCode: country's code that defined in Adserverlogin, ex:AU, UK, CA, NL,....
     * @return Auth token code
     */
    public static String getRequestToken(String countryCode)
    {       
        if(!mapDart6Token.containsKey(countryCode)){     
            try
            { 
                 String authToken='';
                AdServer_Login__c login = getCredential(DART6, countryCode);
                
                HTTPWrapper.IRequest tokenReq = new DART6Message.DART6TokenRequest(login);
                DART6Message.GenericResponse tokeResponse = new DART6Message.GenericResponse(tokenReq);
                  
                String responseBody = tokeResponse.getResBody();
                 
                 
                if(!(responseBody+'').contains('Auth='))
                {
                    throw new ExceptionGroup.FetchTokenException(responseBody);
                }
                
                authToken = responseBody.substring(responseBody.indexOf('Auth=') + 5).trim();
                
                 mapDart6Token.put(countryCode,authToken);
                 
            }catch(Exception ex)
            {
                throw new ExceptionGroup.FetchTokenException('Could not fetch token for DART6.\n'+ex.getStackTraceString());
            }
            
        }   
        return mapDart6Token.get(countryCode); 
    }
    
    static Map<String,AdServer_Login__c> mapCredential;
    /**
     * Get AdServerLogin by dartversion and country's code
     * @param   dartVersion, ex: DART6
     * @param   countryCode, ex: AU, CA,...
     * @return  list of AdServer_Login__c
     * @see     AdServer_Login__c
     */
    public static AdServer_Login__c getCredential(String dartVersion, String countryCode)
    {
        if(mapCredential==null)
        {
            mapCredential = new Map<String,AdServer_Login__c>();
            for( AdServer_Login__c login: [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c, Refresh_Token__c, Client_Id__c, Client_Secret__c, Timezone__c, ExternalLineDescriptionId__c  FROM AdServer_Login__c WHERE Active__c=true AND isDeleted=false])
            {
                System.debug('-------------------------------->>>login:' + login);
                mapCredential.put(login.RecordType.name+'_'+login.Name,login);//DART Version, Login
            }
            System.debug('\n\n---------> countryCode: ' + countryCode +'---------> dartVersion: '+dartVersion +'---------> mapCredential: ' + mapCredential);
            //if(mapCredential.isEmpty() || !mapCredential.containsKey(dartVersion+'_'+countryCode) && !PRODUCT_PACKAGE.equals(dartVersion))
            if(mapCredential.isEmpty() || !mapCredential.containsKey(dartVersion+'_'+countryCode))
            {
                throw new ExceptionGroup.FetchTokenException('Please make sure that product site was assigned correctly.');
            } 
            
        }
        
        return mapCredential.get(dartVersion+'_'+countryCode);
    }

 /** 
  * @description send email with CC
  * @param addr
  * @param cc
  * @param subject
  * @param displayName
  * @param body
  */
   public static void sendMail(String[] addr, String[] cc, String subject,String displayName,String body){
         
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setToAddresses(addr);
        
        if(cc != null)
        {
            mail.setCcAddresses(cc);
        }

        mail.setSenderDisplayName(displayName);
        
        mail.setSubject(subject);
        
        mail.setBccSender(false);

        mail.setUseSignature(false);

        mail.setHtmlBody(body);
        
        //start sending
        if(!Test.isRunningTest()) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
     /** 
     * @description generated Ids for IN where clause
     * @param   sIds: list of string ids
     * @return  string of ids after generated
     */
    public static String generateIds(Set<String> sIds){
        String ids = '(';
        for(String s: sIds) {
            ids+='\''+s+'\',';
        }
        ids = ids.substring(0,ids.length()-1)+')';
        
        return ids; 
    }
    
    /**
     * @description get list of countries form targetingCountryAssociation
     * @param targetingId
     * @return list of countries
     */
    public static Country__c[] getListCountries(String targetingId)
    {
        
        return [SELECT Name,Country_Code__c,Dart_ID__c FROM Country__c WHERE Id IN (SELECT Country__c FROM TargetingCountryAssociation__c WHERE Targeting__c=:targetingId)];//'a07R0000006nHV5'
    }
    
    /**
     * @description get list of cities form targetingCityAssociation
     * @param targetingId
     * @return list of cities
     */ 
    public static City__c[] getListCities(String targetingId)
    {
        
        return [SELECT Name,State_Region__c,Country__r.Name, Dart_ID__c  FROM City__c  WHERE Id IN (SELECT City__c FROM TargetingCityAssociation__c WHERE Targeting__c=:targetingId)];//'a07R0000006nHV5'
    }
    
    /**
     * @description get list of cities form targetingAreaCodeAssociation
     * @param targetingId
     * @return list of areaCodes
     */ 
    public static AreaCode__c[] getListAreaCodes(String targetingId)
    {
        
        return [SELECT Name, Dart_ID__c  FROM AreaCode__c WHERE Id IN (SELECT AreaCode__c FROM TargetingAreaCodeAssociation__c WHERE Targeting__c=:targetingId)];//'a07R0000006nHV5'
    }
    
    /**
     * @description get list of geography form TargetingGeographyAssociation__c
     * @param targetingId
     * @return list of Geography
     */
    public static Geography__c[] getListGeographies(String targetingId)
    {
        return [Select Name, Country_Code__c, Dart_ID__c, Node_ID__c, Type__c From Geography__c Where ID IN (Select Geography__c From TargetingGeographyAssociation__c Where Targeting__c=:targetingId)];
    }
    
    /**
     * @description get list of cities form TargetingDeviceAssociation__c
     * @param targetingId
     * @return list of Devices
     */ 
    public static Devices__c[] getListDevices(String targetingId)
    {
        return [Select Name, DFP_API_Name__c, Dart_ID__c, Node_ID__c From Devices__c Where ID IN (Select Device__c From TargetingDeviceAssociation__c Where Targeting__c=:targetingId)];
    }
    
    /**
     * @description get list of frequency capping form TargetingFrequencyAssociation__c
     * @param targetingId
     * @return list of FrequencyCappings
     */ 
    public static TargetingFrequencyAssociation__c[] getListFrequencyCappings(String targetingId)
    {
        return [Select Targeting__c, FC_Quantity__c, FC_Period__c, FC_Check_Inventory__c, FC_Ad_served_every__c From TargetingFrequencyAssociation__c Where Targeting__c=:targetingId AND FC_Check_Inventory__c=true];
    }
    
    /**
     * @description get list of cities form TargetingConnectionAssociation__c
     * @param targetingId
     * @return list of connection
     */ 
    public static Connection__c[] getListConnections(String targetingId)
    {
        return [Select Name, DFP_API_Name__c, Dart_ID__c, Node_ID__c From Connection__c Where ID IN (Select Connection__c From TargetingConnectionAssociation__c Where Targeting__c=:targetingId)];
    }
    
    /**
     * @description get list of cities form targetingRegionAssociation
     * @param targetingId
     * @return list of Regions
     */ 
    public static Region__c[] getListRegions(String targetingId)
    {
        return [SELECT Name, Dart_ID__c FROM Region__c WHERE Id IN (SELECT Region__c FROM TargetingRegionAssociation__c WHERE Targeting__c=:targetingId)];
    }
     
    /**Get list of Contents either by targetingId or ProductId
     * @param targetingId
     * @param productId
     * @return list of contents 
     */
     public static Content__c[] getListContents(String targetingId,String productId)
     {
        //1-Oppproduct.Targeting__r. TargetingContentAssociation__r.Content__r. Name 
        Content__c[] contents = getContentsByTargetType(targetingId, New List<String>{'Dart - Site'});//'a07R0000006nHV5'
        //get Content Id from Product
        Set<String> siteConId = new Set<String>();
        for(Product2 p: [SELECT PlacementDB__r.Content_Category_Site__c FROM Product2  WHERE ID=:productId])
        {
            siteConId.add(p.PlacementDB__r.Content_Category_Site__c);
        }
        
        //get Content from related Product and add to the existing list of Contents
        contents.addAll([SELECT Name,DartName__c  FROM Content__c WHERE ID IN:siteConId]); 
        
        return contents;
     }
     
     public static Content__c[] getPredefinedContents(String contId){
        return [SELECT Name, DartName__c, Id, Type__c  FROM Content__c Where Id=:contId];
     }
     
     /**
      * @description get list of content by Type
      * @param targetingId
      * @param cType 
      * @return list of Contents
      */
     public static Content__c[] getContentsByTargetType(String targetingId,List<String> cTypes)
     {
        return Database.query('SELECT Name,DartName__c,Site__r.Name,Site_Content_Category__r.Name, Type__c  FROM Content__c '+ //Name = dartId
       'WHERE (Id IN (SELECT TargetingContent__c FROM TargetingContentAssociation__c '+
       'WHERE Targeting__c=:targetingId) AND Type__c IN :cTypes)');
     }
     
     /**
      * @description methode to get data from new Object PlacementTargeting__c
      * @Create date : 02/04/2014
      * @Create by : Dim sovantheany
      * v1
      */ 
     public static Placement__c[] getPlacementTargeting(String targetingId)
     {
        return Database.query('SELECT Dart_ID__c FROM Placement__c '+
       'WHERE (Id IN (Select Placement__c From PlacementTargetingAssociation__c '+
       'WHERE Targeting__c =:targetingId))');
     }
      
     /**
      * @description get list of device category by name
      * @param name of devices
      * @return list of device category
      */ 
      public static Devices__c[] getListDevicesCategory(List<String> lstDevName)
      {
            return [Select Id, Name, DFP_API_Name__c, Dart_ID__c, Node_ID__c From Devices__c Where Name IN:lstDevName and DFP_API_Name__c='DeviceCategory'];
      }
      
     /** 
      * @description get list of Advertisers
      * @param accId
      * @param agency
      * @return list of Advertiser  
      */
     public static Advertiser__c[] getAdvertiser(String accId, String agency)
     {
        return [Select id, Name, Dart5_Advertiser_Id__c, Dart6_Advertiser_Id__c, AdServer_Login_Name__c From Advertiser__c Where Advertiser__c.Account__c =: accId AND Advertiser__c.Agency__c =: agency];
     }
     
     /** 
      * OpportunityTeamMember  
      * @param oppId
      * @return list of OpportunityTeamMember
      */
     public static OpportunityTeamMember[] getOpportunityTeamMember(String oppId)
     {

         return [Select User.Name, UserId, TeamMemberRole From OpportunityTeamMember WHERE TeamMemberRole =: TEAM_MEMBER_ROLE and opportunityId=:oppId];
        
     }
     
     
    /** 
     * For AvailForecast includeSite
     * @param productId
     * @param cType
     * @return list of contents
     */
     public static Content__c[] getListAvailSites(String productId,Set<String> cType)
     {
         //schema: Product<---AvailableSite--->Content (via available_Site__c)       
         //Need: Product.Available_Site__r.Name (I think Content rather than this)
         //return [SELECT Name FROM Available_Site__c WHERE Product__c=:productId];
         return [SELECT Name,DartName__c,Site_Content_Category__r.Name  FROM Content__c WHERE Id IN 
                (SELECT available_Site__c FROM Available_Site__c WHERE Product__c=:productId) and Type__c IN:cType];
         
     }
     
     final static String TD_STYLE='style="border:solid gray 1pt; padding:3pt 3pt 3pt 3pt"';
     final static String TD_TEMPLATE = '<TD '+ TD_STYLE +'>{0}</TD>';
     /**
      * Generate dynamic table TD
      * @param val : value to put to TD
      * @return string 
      */
     public static String genTD(String val)
     {
        return String.format(TD_TEMPLATE, new String[]{val});
     }
    
     final static String TR_TEMPLATE = '<TR>{0}</TR>';
     /**
      * Generate dynamic table TR
      * @param val : value to put to TD
      * @return string 
      */
     public static String genTR(String val)
     {
        return String.format(TR_TEMPLATE, new String[]{val});
     }
     
     /** 
      * Generate table forecast 
      * @param lst
      * @param string
      */
    public static  String generateTableForecast(List<DARTObject.DARTForecast> lst)
    {
       //final Map<String,String> mapFCPeriod = new Map<String,String>{'0'=>'Minutes','1'=>'Hours','2'=>'Days','3'=>'Weeks',null=>''};
       String trBody = '';//all TRs and TDs
       for(DARTObject.DARTForecast fc : lst)
       {
           //String fcp = (mapFCPeriod.get(fc.getFCPeriod())==null?'':mapFCPeriod.get(fc.getFCPeriod()));
           String strFC =   fc.getFCQty()+ '/' + fc.getFCAdServedEvery()+' ' + fc.getFCPeriodDart6();
           strFC = (('').equals(fc.getFCQty())?fc.getFCAdServedEvery()+' '+ fc.getFCPeriodDart6():strFC); 
                       
           String tds = genTD('<a href='+URL_INSTANCE+'/'+fc.getOppItemID() +'>'+fc.getOppItemID()+'</a>')+ 
                        genTD(fc.getPackage()) + genTD(fc.getProductName()) + 
                        genTD(fc.getLineDesc())+ genTD(strFC) + 
                        genTD(fc.getPeriod())+ genTD(fc.getQuantity()+'') + 
                        genTD(fc.getAvailableUnits()+'')+
                        genTD(fc.getShareOfVoice()+'%') ;
                       
           String trs = genTR(tds);            
           trBody += trs; 
          
       }  

       return trBody ;   
   }
  
   /** 
    * Generate table Compaign 
    * @param lstOrder
    * @return string that contain html(table tr, td tages)
    */
   public static String generateTableCompaigns(List<DARTObject.IDARTObjectOrder> lstOrder)
   {
       String trBody = '';//all TRs and TDs
       
       for(DARTObject.IDARTObjectOrder ord : lstOrder)
       {
           
           String tds = genTD('<a href='+URL_INSTANCE+'/'+ord.getOppID() +'>'+ord.getOppID()+'</a>')+ 
                        genTD(ord.getOppName())+
                        genTD(ord.getAssignAdserver()==null?'':ord.getAssignAdserver()) + 
                        genTD(ord.getDartId()==null?'':ord.getDartId()) + 
                        genTD(ord.getDartId()==null?'':'Update')+
                        genTD('')+
                        genTD(ord.getDartErrMsg()==null?'':ord.getDartErrMsg());
                        
                       
           String trs = genTR(tds);            
           trBody += trs;  
          
       }   

       return trBody ;
   }
   
   /** 
    * Generate table Compaigns Items
    * @param lstAds
    * @return string that contain html(table tr, td tages) 
    */ 
    public static  String generateTableCompaignItems(List<DARTObject.IDARTObjectAds> lstAds)
    {
       String trBody = '';//all TRs and TDs
       for(DARTObject.IDARTObjectAds ads : lstAds)
       {
           DARTObject.IDARTObjectOrder ord = ads.getOrder();
           String tds = genTD('<a href='+URL_INSTANCE+'/'+ads.getOppItemID() +'>'+ads.getOppItemID()+'</a>')+ 
                        genTD(ads.getProductName()) + 
                        genTD(ads.getAssignAdserver()==null?'':ads.getAssignAdserver())+ 
                        genTD(ord==null?'':ord.getDartId())+ 
                        genTD(ads.getDartId()==null?'':ads.getDartId())+
                        //genTD(ads.getDartId()==null?'':'Created')+
                        genTD(ads.getDartId()==null?'':ads.getStatus())+
                        genTD('')+
                        genTD(ads.getDartErrMsg()==null?'':ads.getDartErrMsg());
                       
           String trs = genTR(tds);            
           trBody += trs; 
          
       } 
       return trBody;
    }
  
   
   /** 
    * Generate table forecast error 
    * @param mapError
    * @return string that contain html(table tr, td tages)
    */ 
   public static String generateTableForecastError(Map<String, Exception> mapError)
   {
       String trBody = '';//all TRs and TDs
       for(String st : mapError.keySet())
       {
           String tds = genTD('<a href='+ URL_INSTANCE+'/'+st +'>'+st+'</a>')+ 
                        genTD(mapError.get(st).getMessage());          
           String trs = genTR(tds);            
           trBody += trs;
       }
    
       return trBody;   
   }
   
   
    
    /**Count the current batch apex being excecuted before invoke another batch
     * Only 5 running batch allowed
     * @return number of current batch are in progress in org
     */
    public static Integer countCurrentBatch()
    {
        //Select a.TotalJobItems, a.Status, a.NumberOfErrors, a.MethodName, a.JobType, a.JobItemsProcessed, a.Id, a.CreatedDate, a.CreatedById, a.CompletedDate, a.ApexClass.Name, a.ApexClassId From AsyncApexJob a where Status='Queued'
        return [select count() FROM AsyncApexJob a WHERE Status='Queued'];
    }  
    
    /**
     * String to Double
     * @param string s
     * @return double
     */
    public static Double toDouble(String s)
    {
         
        try{
            return Double.valueOf((s+'').replace(',','.'));
        }catch(Exception ex)
        {
            return 0;
        }
        return 0; // never reach
    }   
    
    /**  
     * STring to Integer
     * @param string s
     * @return integer 
     */
    public static Integer toInteger(String s)
    {
        try{
            return (s==null?0:Integer.valueOf((s+'')));
        }catch(Exception ex)
        {
            return 0;
        }
        return 0;// never reach
    } 
    
    /**  
     * Decimal to Integer
     * @param Decimal d
     * @return integer 
     */
    public static Integer toInteger(Decimal d)
    {
        try{
            return (d==null?0:Integer.valueOf((d+'')));
        }catch(Exception ex)
        {
            return 0;
        }
        return 0;// never reach
    }  
    
    /** 
     * Excract the user friendly message from webserice call out failure 
     * ex:
     * Web service callout failed: WebService returned a SOAP Fault: [RequiredError.REQUIRED @ targeting.inventoryTargeting] faultcode=soap:Server faultactor=
    
     * -> RequiredError.REQUIRED @ targeting.inventoryTargeting
     * @param msg
     * @return string
    */
    public static String extractMessage(String msg)
    {
        Matcher m = Pattern.compile(DART6Message.DART6_WS_ERROR_PATTERN).matcher(msg);
        while (m.find()) {
            return m.group(1);
        }
        //in case...
        return msg; 
    }
    
    /**
     * @param key : browser's name
     * @return DART_Browser_Mapper__c
     */
    public static DART_Browser_Mapper__c getBrowserMapper(String key)
    {
        DART_Browser_Mapper__c brw = DART_Browser_Mapper__c.getInstance(key); 
                
        if(brw==null) throw new ExceptionGroup.DARTException('No Browser Id Mapping defined in Custom Setting.');
        
        return brw;
            
    }
    
    /**
     * @param key : OS's name
     * @return DART_OS_Mapper__c
     */
    public static DART_OS_Mapper__c getOSMapper(String key)
    {
        DART_OS_Mapper__c os = DART_OS_Mapper__c.getInstance(key); 
        if(os==null) throw new ExceptionGroup.DARTException('No Operation System Id Mapping defined in Custom Setting.');
        
        return os;
    }
    
    /**
     * check if value is number
     * @param s
     * @return boolean
     */
    public static boolean isNumber(String s)
    {
        try
        {
            Double.valueOf(s);
            return true;
        }catch(Exception ex)
        {
            return false;
        }   
        
    }
    
    private static final String[] HTML_CHAR  = new String[]{ '<', '>', '"', '\'','&'};
    private static final String[] HTML_CHAR_ENCODED  = new String[]{ '&lt;', '&gt;', '&quot;', '&#39;','&amp;' };
    /**
     * @param s
     * @return string
     */
    public static String encodeHTML(String s)
    {
        if (s== null || s =='')
            return s;

        for (Integer i = 0; i < HTML_CHAR.size(); ++i) {
            s = s.replace(HTML_CHAR[i], HTML_CHAR_ENCODED[i]);
        }
        
        return s;
    }
    /**
     * @description: get googe access token
     * @createdDate: 11-04-2014
     * @param: AdserverLogin__c login
     * @return google access token
     */
    static String access_token;
    public static String getAccessToken(AdServer_Login__c login)
    {
        //get custtom setting
        //String access_token;
        try
        {
            if(access_token == null)
            {
                if(login.Refresh_Token__c==null)
                {
                    throw new ExceptionGroup.DARTException('Refresh Token is not defined in the AdserverLogin. Please login and save via DFPCredential Page.');
                }
                
                String body ='refresh_token=%rtoken%&client_id=%clid%&client_secret=%secret%&grant_type=refresh_token';
                body=body.replace('%rtoken%',login.Refresh_Token__c).replace('%clid%',login.Client_Id__c).replace('%secret%',login.Client_Secret__c);
                
                if(Test.isRunningTest())
                {
                    return 'xxxxxxxxxxxxxxxxxx';
                }
                
                access_token = oauth2Request(body,'access_token'); //pick up the field "access_token" from the response
                System.debug('---------->> access_token:' + access_token);
            }
        }
        catch(Exception ex){throw ex;} 
         
        //return accesstoken
        return access_token;
    }
    
    /**
     * @param body
     * @param requestFieldName
     * @return string
     */
    public static String oauth2Request(String body,String requestFieldName)
    {
        HTTPWrapper.IRequest reqToken = new HTTPWrapper.SimpleRequest(ENDPOINT_GOOGLE_OAUTH2_TOKEN,'POST',body);
            HTTPWrapper.SimpleResponse resToken = new HTTPWrapper.SimpleResponse(reqToken);
            System.debug('>>>>>>>>>>OAuth2: Resbody: '+resToken.getResBody());
            
            //resp is a JSON string
            JSONParser parser = JSON.createParser(resToken.getResBody()); 
            while (parser.nextToken() != null)
            {
                if((parser.getCurrentToken() == JSONToken.FIELD_NAME))
                {
                    String fieldName = parser.getText();
                    parser.nextToken();
                    if(requestFieldName == fieldName) //'access_token' / refresh_token
                    {
                        return parser.getText();
                        
                    }else if(fieldName=='error')
                    {
                        throw new ExceptionGroup.DARTException('Request to DFP returns error: '+parser.getText());
                    }
                  }
              }
        return null;
    }
    
    /**https://help.salesforce.com/articleView?id=000233174&type=1
     * Convert string datetime to userTimezone, Help Reference:
     * Bunhor @17-Mar-17: update this method
     */
    public static DateTime fixTimezoneDateTime(String sourceDateStr, String userTimezone){
        TimeZone extz = TimeZone.getTimeZone(userTimezone);
        
        Integer ex = - extz.getOffset(system.now());
		
		DateTime dfpTime = DateTime.valueOfGmt(sourceDateStr);
		
		DateTime dfpTimeGmt = dfpTime.addMinutes((ex) / (1000 * 60));
		
        return dfpTimeGmt;
    }
    
}