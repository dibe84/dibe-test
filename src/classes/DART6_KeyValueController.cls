/**
 Manage Key id and value Id by the keyvalue association.
 - Seach the value in dfp if exist then return with id
 - Create new free-form value in dfp if not exist
 - Save the newly created value id(s) to DART_KeyValue_2__c
 
 NK: 31/1/2013
    DFP format:
     (
        (key1=val1 OR val2) AND (key2=val1 OR val2 OR val3)
        )
        OR <---- SET,first level. must be 'OR'
        (
        (key1=val1) AND (key2=val1) AND (key3=val1 OR val2)
    )----------------^ --------------^  Second level. Must be AND
        
    ((key1=val1 OR val2) AND (key2=val1 OR val2 OR val3)) OR ((key1=val1) AND (key2=val1) AND (key3=val1 OR val2))
    
    -log: 
     + 08/03/2017:NK: handle prefix/suffix  
    
*/ 
public with sharing class DART6_KeyValueController extends DARTObject.AbstractDARTController{  
    //free-form values to be created (predefined-key id provied)
    String token,networkId;
    Map<String,DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue> mapTobeCreatedValues;
    Map<String,DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue> mapAllKeyValues;
    
    
    Map<String,DART_KeyValue_2__c> mapAllKeyAudSegs;
     
    
    List<List<DARTEvaluator.CustomCriteriaSet>> listEvalCrit;
    
    //store the object that does not have dart6 valueId; so after created freeform value in dfp, save the dartid back to this object for future use
    Map<String,DART_KeyValue_2__c> mapValueObject2BeUpdated = new Map<String,DART_KeyValue_2__c>();
    Map<String,DART_KeyValue_2__c> mapValueObject2BeCreated = new Map<String,DART_KeyValue_2__c>();
    
    Map<String,String> mapDfpId_Key = new Map<String,String>();//dfpkeyId to keyname
    Set<String> setV = new Set<String>(); //all value names
    
    set<String> setAllValueNotFreeform = new set<String>();
    
    //NK:21/03/2013
    public static final String KV_TYPE_AudienceSegment = 'Audience Segment'; //Audience Segment
    
    private DART6_KeyValueController(String token,String networkId)
    {
        this.token = token;
        this.networkId = networkId;
        
        mapTobeCreatedValues = new Map<String,DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue>();
        mapAllKeyValues = new Map<String,DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue>();
        mapAllKeyAudSegs = new Map<String,DART_KeyValue_2__c>();
    }
    
    /** Constructor:
    @param: targetingId : DartKeyValue2 will be selected from targeting association via this id
    @param: siteAuto    : to make this search deliver only one result we need another identifier (KeyValue only in this product)
    @param: dart5Form   : old dart keyvalue form to be converted to dart6
    @param: token       : google token after login
    @param: networkId   : network id to be processed
    */
    public DART6_KeyValueController(String siteAuto, String dart5Form,String token,String networkId)
    {
        this(token,networkId);
        
        try{
            if(String.isEmpty(dart5Form) || dart5Form == 'null')
            {
              listEvalCrit = new List<List<DARTEvaluator.CustomCriteriaSet>>();
              return;
            }
            listEvalCrit =  DARTEvaluator.convertToCritSet( dart5Form ); 
        }catch(Exception ex){throw new ExceptionGroup.DARTKeyValueException('Unsupported or Invalid Keyvalue String format: '+dart5Form);}
        
         // for pure oldform string without targeting Id
        Set<String> setK = new Set<String>();
        for(DARTEvaluator.CustomCriteriaSet[] cslist: listEvalCrit)
        {
            for (DARTEvaluator.CustomCriteriaSet cs : cslist) 
            {
                for(DARTEvaluator.Condition con: cs.getCriterion())
	            {
	                setK.add(con.getParameter());
	                setV.add(fetchInvalidChars(con.getValue()));
	            }
            }
            
        }

        Map<String,DART_KeyValue_2__c> mapK = new Map<String,DART_KeyValue_2__c>(); //for Key only,key: car 
        Map<String,DART_KeyValue_2__c> mapV = new Map<String,DART_KeyValue_2__c>(); //for Value only,key: car_bmw
        Map<String,DART_KeyValue_2__c> mapKeyNotFreeform = new Map<String,DART_KeyValue_2__c>();
        Map<String,DART_KeyValue_2__c> mapKeyFreeform = new Map<String,DART_KeyValue_2__c>();
        setK.add(KV_TYPE_AudienceSegment);
        String soql='Select d.Key__c, d.Dart6_KeyId__c, d.Dart6_ValueId__c, d.Key_ValueType_FreeForm__c, d.Key_Value__c, '+
                    '(Select Key__c, Key_Value_Name__c, Dart6_KeyId__c, Key_Value__c ,Site__c, Dart6_ValueId__c, Node_ID__r.Key_ValueType_FreeForm__c From DART_KeyValues_2__r '+
                    ' Where Key_Value__c IN:setV) '+
                    ' From DART_KeyValue_2__c d Where Key_Value__c IN:setK AND Key_Value__c <>: KV_TYPE_AudienceSegment ';
        
        for(DART_KeyValue_2__c kvff : Database.query(soql+ ' AND Site__c=:siteAuto')){
            
            // Mapping all child of each parent
            for(DART_KeyValue_2__c kvChild : kvff.DART_KeyValues_2__r){
                //simple kv
                String strKeyVal = (kvff.Key__c+'_'+kvChild.Key_Value__c);
                mapV.put(strKeyVal,kvChild);  //k: key_value, value to indentify the which value belong to which key. in case same name value in the different key
                if(kvff.Key_ValueType_FreeForm__c==false){
                    mapKeyNotFreeform.put(kvChild.Key_Value__c, kvff);
                    setAllValueNotFreeform.add(kvChild.Key_Value__c);
                }
                else{
                    mapKeyFreeform.put(kvChild.Key_Value__c, kvff);
                }
            }
            
            mapK.put(kvff.Key__c,kvff); 
            mapDfpId_Key.put(kvff.Dart6_KeyId__c+'',kvff.Key__c); //dfpId -> Keyname
        }
        
         //the the sfid and existing dart Id
        for(DART_KeyValue_2__c kv2 : [Select d.Key__c, d.Dart6_KeyId__c, d.Dart6_ValueId__c, d.Key_ValueType_FreeForm__c, d.Key_Value__c,
                                (Select Key__c, Key_Value_Name__c, Dart6_KeyId__c, Key_Value__c, Dart6_ValueId__c, Node_ID__r.Key_ValueType_FreeForm__c From DART_KeyValues_2__r
                                 Where Key_Value__c IN:setV)
                                 From DART_KeyValue_2__c d Where Key_Value__c IN:setK])
            //WHERE Node_ID__r.Key__c IN:setK AND Key_Value__c IN: setV
            //WHERE Id in (SELECT DARTKeyValue__c From TargetingKeyValueAssociation__c where Targeting__c=:targetingId) //need this?
        {
            //TODO: AudienceSegment ?
            //AudiencdSegment => Node_ID__r.Name
            //Mapping all child of each parent (AudienceSegment)
            for(DART_KeyValue_2__c kvChild : kv2.DART_KeyValues_2__r){
                //TODO: AudienceSegment ?
                //AudiencdSegment => Node_ID__r.Name
                String strKeyVal = (kv2.Key__c+'_'+kvChild.Key_Value__c).trim();
                if(KV_TYPE_AudienceSegment.equals(kv2.Key_Value__c))
                {
                    mapAllKeyAudSegs.put(strKeyVal ,kvChild);
                }
                mapV.put(strKeyVal, kvChild);
            }  
        }

        DARTObject.IValidator kvValidator = new KVValidator(mapK,mapV,mapKeyNotFreeform,setAllValueNotFreeform, mapAllKeyAudSegs); 
        
        //find if value has dart6 id yet - then add to list to create in dfp
        for(DARTEvaluator.CustomCriteriaSet[] cslist: listEvalCrit)
        {
            for(DARTEvaluator.CustomCriteriaSet cs: cslist)
            {
	            for(DARTEvaluator.Condition con: cs.getCriterion())
	            {
	                //for error: may not Possible - just in case
	                kvValidator.checkError(con);
	                String fetchedValue = fetchInvalidChars(con.getValue());
	                if(!KV_TYPE_AudienceSegment.equals(con.getParameter()))
	                { 
	                    //error(s) occure NO NEED to process next step, because this will be thrown after finishing loop
	                    if(kvValidator.isError())continue;
	                    DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue tmp = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue();
	                    tmp.customTargetingKeyId = mapK.get(con.getParameter()).Dart6_KeyId__c.longValue();
	                    tmp.matchType = findMatchType(con.getValue());
	                    tmp.name = fetchedValue;
	                    tmp.displayName = con.getValue();
	                    
	                    String keyToV = con.getParameter() + '_' + fetchedValue;
	                    //no dart6value Id yet, need to create this in dfp
	                    if(mapV.get(keyToV) != null){ 
	                        if(mapV.get(keyToV).Dart6_ValueId__c==null){
	                            setV.add(tmp.name); //for first query
	                            mapTobeCreatedValues.put(tmp.customTargetingKeyId+'_'+tmp.name,tmp); //this will be seding to dfp
	                            
	                            //will save dart6 id back after created in dfp.
	                            //key: DART_KeyValue_2__c.Id, value: DART_KeyValue_2__c
	                            String key = mapDfpId_Key.get(tmp.customTargetingKeyId+'');
	                            mapValueObject2BeUpdated.put(key+'_'+tmp.name, mapV.get(keyToV)); 
	                            
	                        }
	                        else//dart6value id already existed, no need to create in dfp. so keep it in a map for next step use
	                        {
	                            tmp.id = mapV.get(keyToV).Dart6_ValueId__c.longValue();
	                            //key = dart6Id_value: 12345665_v11230
	                            mapAllKeyValues.put(mapK.get(con.getParameter()).Key__c + '_' + fetchedValue,tmp); 
	                        }
	                    }
	                    else  // else create new value in dfp & sf
	                    {
	                        if((mapK.get(con.getParameter())).Key_ValueType_FreeForm__c == true && !mapKeyFreeform.containsKey(fetchedValue))
	                        {
	                            setV.add(tmp.name); //for first query
	                            mapTobeCreatedValues.put(tmp.customTargetingKeyId+'_'+tmp.name,tmp); //this will be seding to dfp
	                            // Create new KeyValue2
	                            DART_KeyValue_2__c kv2 = new DART_KeyValue_2__c(
	                                Node_ID__c = mapK.get(con.getParameter()).Id,
	                                Name = con.getValue(),
	                                Key_Value__c = fetchedValue,
	                                Key_Value_Name__c = con.getValue(),
	                                Active__c = true
	                            );
	                            mapValueObject2BeCreated.put(fetchedValue, kv2);
	                            mapAllKeyValues.put(mapK.get(con.getParameter()).Key__c + '_' + fetchedValue,tmp); 
	                        }
	                    }   
	                }
	            }
            }
        }
        
        if(kvValidator.isError()){throw new ExceptionGroup.DARTKeyValueException('ERROR: '+kvValidator.getListError());}
    }
    
    public static String fetchInvalidChars(String valueSrc) {
        valueSrc = valueSrc.replaceAll('\\~','').replaceAll('\\*','');
        String originVal = valueSrc;
        String dollarSign = '\\$';
        valueSrc = valueSrc.replaceAll(dollarSign, '').replaceAll(' ', '');
        //Price Key
        if (valueSrc.startsWith('<')) {
            valueSrc = valueSrc.replaceFirst('<', '0-');
        } else if (valueSrc.startsWith('>')) {
            valueSrc = valueSrc.replaceFirst('>','') + '-999999999';
        } else {
            valueSrc = originVal; 
        }
        return valueSrc;
    }
    
    public Boolean isNeedToCreate()
    {
        return !mapTobeCreatedValues.isEmpty();
    }
    /** send values to create free form value at dart6 */
    public void searchCreateDFPFreeFormValues()
    {
        
        DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader header = new DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader();
          
        header.applicationName='CustomTargetingService';
        header.networkCode= networkId;
        
        Map<String,String> inputHttpHeaders_x = new Map<String, String>();
        inputHttpHeaders_x.put('Authorization', 'Bearer '+ token); 
        
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort customTagetingService = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort();
        customTagetingService.RequestHeader = header;
        customTagetingService.inputHttpHeaders_x = inputHttpHeaders_x;
        
        try
        {
            //1)- search in dfp, if values already exist in dfp then get those Ids
            DART6_CUSTOMTARGETINGSERVICE.Statement filterStatement = new DART6_CUSTOMTARGETINGSERVICE.Statement();
            filterStatement.query = 'WHERE customTargetingKeyId IN'+DARTUtil.generateIds(mapDfpId_Key.keySet())+
                                    ' AND name IN'+DARTUtil.generateIds(setV);
            
            DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage pageResult = customTagetingService.getCustomTargetingValuesByStatement(filterStatement);
            invokedMethod = 'getCustomTargetingValuesByStatement, ';
            if(pageResult.totalResultSetSize>0){
                //in case value already existed in dfp, but no dfp id in sf
                assignDFPIdsToSF(pageResult.results);  
            }

            //2)- create free form value if not yet existed in dfp
            if(!mapTobeCreatedValues.isEmpty())
            {
                DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue[] values = customTagetingService.createCustomTargetingValues(mapTobeCreatedValues.values());
                invokedMethod += 'createCustomTargetingValues';
                //put all new created value into the main map for KeyValueTargeting construction
                assignDFPIdsToSF(values);
            }
            //mapTobeCreatedValues is obsoleted from here
        }
        catch(System.CalloutException cex){
            throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
        }catch(Exception ex)
        {throw new ExceptionGroup.DARTException('' + ex.getMessage());}
    }
    
    private void assignDFPIdsToSF(DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue[] values)
    {
        for(DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue valRes: values)
        {
            //assign the newly created dfp id of free form value to DART_KeyValue_2__c for future use
            String key = mapDfpId_Key.get(valRes.customTargetingKeyId+'');
            mapAllKeyValues.put(key+'_'+valRes.name, valRes); 
             
            //if same value found in dfp after query, remove them from the list tobecreated to avoid duplicate
            //when calling createCustomTargetingValues
            mapTobeCreatedValues.remove(valRes.customTargetingKeyId+'_'+valRes.name); 
            
            if(mapValueObject2BeCreated.containsKey(valRes.name)){
                mapValueObject2BeCreated.get(valRes.name).Dart6_ValueId__c = valRes.id;
            }
            
            //assign dpf value id to SF if available
            if(!mapValueObject2BeUpdated.containsKey(key+'_'+valRes.name))continue;
            mapValueObject2BeUpdated.get(key+'_'+valRes.name).Dart6_ValueId__c = valRes.id; 
        }
    }
    
    //NK:13/01/2015
    final Map<String,String> MAP_OPERATOR =  new Map<String,String>{'='=>'IS','<>'=>'IS_NOT'};
    
    /**@return a list of CustomCriteriaSet */
    public override List<DARTObject.IDARTGenericObject> getListDart()
    {
        DART6_FORECASTSERVICE.CustomCriteriaSet[] childrenNBig = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();
        DART6_FORECASTSERVICE.CustomCriteriaSet customCriteriaSet = new DART6_FORECASTSERVICE.CustomCriteriaSet();
        customCriteriaSet.logicalOperator = 'OR';// Big - OR - level is always OR
        customCriteriaSet.type_x = 'CustomCriteriaSet';
        customCriteriaSet.children = childrenNBig;
            
        for(DARTEvaluator.CustomCriteriaSet[] cslist: listEvalCrit)
        {
            DART6_FORECASTSERVICE.CustomCriteriaSet[] childrenNSet1 = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();
            DART6_FORECASTSERVICE.CustomCriteriaSet customCriteriaSet1 = new DART6_FORECASTSERVICE.CustomCriteriaSet();
            customCriteriaSet1.logicalOperator = 'AND';// Top level is always AND. dartObjForecast.getKeyWKV();
            customCriteriaSet1.children = childrenNSet1;  //list crit set
            customCriteriaSet1.type_x = 'CustomCriteriaSet';
            
            for (DARTEvaluator.CustomCriteriaSet cs : cslist) {
            
                DART6_FORECASTSERVICE.CustomCriteriaNode[] childrenN = new List<DART6_FORECASTSERVICE.CustomCriteriaNode>();
	            DART6_FORECASTSERVICE.CustomCriteriaSet critSet1 = new DART6_FORECASTSERVICE.CustomCriteriaSet();
	            critSet1.logicalOperator = 'OR';   //Second level is always OR
	            critSet1.type_x = 'CustomCriteriaSet';  //set 1
	            critSet1.children = childrenN; //add to set 1
	            
	            for(DARTEvaluator.Condition con: cs.getCriterion())
	            {
	                String fetchedValue = fetchInvalidChars(con.getValue());
	                if(!KV_TYPE_AudienceSegment.equals(con.getParameter()))
	                {
	                    DART6_FORECASTSERVICE.CustomCriteria crit1a = new DART6_FORECASTSERVICE.CustomCriteria();
	                    DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue val = mapAllKeyValues.get(con.getParameter() + '_' + fetchedValue); 
	                    crit1a.keyId = val.customTargetingKeyId; //70630;
	                    crit1a.valueIds = new Long[]{val.Id}; //new Long[]{Long.ValueOf('43594068070'),Long.valueOf('43594069630')};
	                    //NK:13/01/2015
	                    crit1a.operator = MAP_OPERATOR.get(con.getOperator()); //Enumerations: IS, IS_NOT
	                    
	                    crit1a.type_x = 'CustomCriteria';   //crit 1 of set1
	                    childrenN.add(crit1a);
	                }
	                else{
	                    //childrenAS = new List<DART6_FORECASTSERVICE.AudienceSegmentCriteria>();
	                    DART_KeyValue_2__c audSegKey =  mapAllKeyAudSegs.get(con.getParameter() + '_' + fetchedValue);
	                    DART6_FORECASTSERVICE.AudienceSegmentCriteria ads = new DART6_FORECASTSERVICE.AudienceSegmentCriteria();
	                     
	                    ads.audienceSegmentIds = new Long[]{Long.valueOf(audSegKey.Dart6_ValueId__c+'')};
	                     //NK:13/01/2015
	                    ads.operator = MAP_OPERATOR.get(con.getOperator());
	                     
	                    ads.type_x = 'AudienceSegmentCriteria';  //CustomCriteriaNode
	                    childrenN.add(ads);
	                }
	            }
	            childrenNSet1.add(critSet1);
            }
            childrenNBig.add(customCriteriaSet1);
        }  
        Document doc = new Document();
        doc.FolderId = UserInfo.getUserId();
        doc.Body = Blob.valueOf(JSON.serialize(customCriteriaSet));
        doc.ContentType = 'text/plain';
        doc.Type = 'txt';
        doc.Name = 'Debug CustomCriteriaSet';
        //insert doc;
        listDartObjects = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();
        if (!childrenNBig.isEmpty()) {
            listDartObjects  = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>{customCriteriaSet};
        }
        
        return listDartObjects;
    } 
    
    public void createObjectKeyVal()
    {
        insert mapValueObject2BeCreated.values();
    }
    
    public Boolean isCreateNewKv()
    {
        return !mapValueObject2BeCreated.isEmpty();
    }
    
    public void updateDart6ValueIds()
    {
        update mapValueObject2BeUpdated.values();
    }
    
    //mapMT_Head.get(MT_BROAD)
    public static final String MT_BROAD = 'BROAD';     //~myvalue
    public static final String MT_PREFIX = 'PREFIX';    //myvalue*
    public static final String MT_EXACT = 'EXACT';    //myvalue
    public static final String MT_BROAD_PREFIX = 'BROAD_PREFIX';    ////~myvalue*
    
        
    final static Map<String,String> mapMT_Head0 = new Map<String,String>{MT_BROAD=>'~',MT_PREFIX=>'',MT_EXACT=>'',MT_BROAD_PREFIX=>'~'};
    final static Map<String,String> mapMT_Tail0 = new Map<String,String>{MT_BROAD=>'',MT_PREFIX=>'*',MT_EXACT=>'',MT_BROAD_PREFIX=>'*'};
    
    /** UI Name value with special char ~ or * 
        DFP doese not store that char
        enum matchtype BROAD BROAD_PREFIX PREFIX EXACT
    */  
    public static String toUIName(String valName,String matchType)
    {
        return  (mapMT_Head0.get(matchType)+valName+mapMT_Tail0.get(matchType)); //the rest, use old logic
    }
    
    /* Idnentify the MatchType by the value name */    
    public static String findMatchType(String valName)
    {
        return (valName.startsWith('~') && valName.endsWith('*'))?MT_BROAD_PREFIX:(valName.startsWith('~')?MT_BROAD:valName.endsWith('*')?MT_PREFIX:MT_EXACT);  
    }
    
    public class KVValidator implements DARTObject.IValidator{
        List<String> listErr;
        
        Set<String> listMissingKeys = new Set<String>();  
        Set<String> listMissingValues = new Set<String>();  
        Set<String> listMissingKeyDart6Id = new Set<String>();  
        set<String> listKeyNotFreeform = new Set<String>();
        set<String> listMissingValIdAdtSeg = new set<String>();
        
        Map<String,DART_KeyValue_2__c> mapK;
        Map<String,DART_KeyValue_2__c> mapV;
        Map<String,DART_KeyValue_2__c> mapKeyNotFreeform;
        Set<String>setAllValueNotFreeform;
        Map<String,DART_KeyValue_2__c> mapAllKeyAudSegs;

        public KVValidator(Map<String,DART_KeyValue_2__c> mapK,Map<String,DART_KeyValue_2__c> mapV, Map<String,DART_KeyValue_2__c> mapKeyNotFreeform,Set<String>setAllValueNotFreeform, Map<String,DART_KeyValue_2__c> mapAllKeyAudSegs)
        {
            this.mapK = mapK;
            this.mapV = mapV;
            this.mapKeyNotFreeform = mapKeyNotFreeform;
            this.setAllValueNotFreeform = setAllValueNotFreeform;
            this.mapAllKeyAudSegs = mapAllKeyAudSegs;
  
            listErr = new List<String>();
        }
        public void checkError(Object o)
        {
            DARTEvaluator.Condition con = (DARTEvaluator.Condition)o;
            String fetchedValue = fetchInvalidChars(con.getValue());
            if(mapK.get(con.getParameter()) !=null)
            {
                if(!(setAllValueNotFreeform).contains(fetchedValue) && (mapK.get(con.getParameter())).Key_ValueType_FreeForm__c==false) // 
                {
                    listMissingValues.add(fetchedValue);
                    listKeyNotFreeform.add(con.getParameter());
                }
                
                if(mapK.containsKey(con.getParameter()) && mapK.get(con.getParameter()).Dart6_KeyId__c==null && (!DART6_KeyValueController.KV_TYPE_AudienceSegment.equals(con.getParameter())))
                {
                    listMissingKeyDart6Id.add(con.getParameter());
                }
            }
            
            if(!mapK.containsKey(con.getParameter()) && (!DART6_KeyValueController.KV_TYPE_AudienceSegment.equals(con.getParameter())))
            { 
                listMissingKeys.add(con.getParameter());
            }
            
            if(mapAllKeyAudSegs.containsKey(con.getParameter() + '_' + fetchedValue) && mapAllKeyAudSegs.get(con.getParameter() + '_' + fetchedValue).Dart6_ValueId__c == null)
            {
                listMissingValIdAdtSeg.add(fetchedValue);
            }
        }

        public List<String> getListError()
        {
            if(!listMissingKeys.isEmpty())
            {
                listErr.add('\n\rKey(s) not found in the KeyValue2:'+listMissingKeys);
            }
            if(!listMissingValues.isEmpty())
            {
                listErr.add('\n\rValue(s) not found in KeyValue2:'+listMissingValues+' \n\r And not a free-form value for Key(s):'+listKeyNotFreeform);
            }
            if(!listMissingKeyDart6Id.isEmpty())
            {
                listErr.add('\n\rPredefined DFP Dart6Key Id not found:'+listMissingKeyDart6Id);
            }
            if(!listMissingValIdAdtSeg.isEmpty())
            {
                listErr.add('\n\rPredefined DFP Dart6Value Id not found in Audience Segment:'+listMissingValIdAdtSeg);
            }
            
            return listErr;
        }
        public Boolean isError()
        {
            return (!listMissingKeys.isEmpty() || !listMissingValues.isEmpty() || !listMissingKeyDart6Id.isEmpty() || !listMissingValIdAdtSeg.isEmpty());
        }
    
    }
}