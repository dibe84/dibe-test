/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description:
 *  - Key Value on Targeting
 * @references:
 *  - LPC_KeyValueSelector lightning component
 * @changeLog:
 *
 */
public without sharing class LPC_KeyValuesSelectorController {
    public final static String DEFAULT_CONJUN_OUT_SET = ' - OR - ';
    public final static String DEFAULT_CONJUN_IN_SET = ' AND ';
    public final static String DEFAULT_CONJUN_IN_VALUE = ' OR ';

    /**
     * Get Key list available on product
     * @param lineItemId, OpportunityLineItem Id
     * @return List<DART_KeyValue_2__c>
     */
	@AuraEnabled
    public static RemoteResponse initKeyN(String lineItemId){
    	Id oppLineId = lineItemId;
    	if (Schema.OpportunityLineItem.SObjectType != oppLineId.getSobjectType()) {
    		return new RemoteResponse('Only OpportunityLine Item can apply the key values targetting. This record is a basket.', RemoteResponse.STATUSCODE_ERROR);
    	}

    	OpportunityLineItem oppLine = [Select Name, Targeting__c, AdKeywords__c, Product2Id From OpportunityLineItem Where Id =: lineItemId];
		String proId = oppLine.Product2Id;
		String targetId = oppLine.Targeting__c;
		if (oppLine.Targeting__c == null) {
			Targeting__c tg = new Targeting__c(Description__c = oppLine.Name + ' Targeting');
			insert tg;
			targetId = tg.Id;
			oppLine.Targeting__c =  tg.Id;
			update oppLine;
		}

		try {
			//Available keys on product
			KeyWrp[] keyList = new List<KeyWrp>();
		 	List<Product2> lstPrd2  =[Select site__c,Available_Key_Values__c From Product2 where Available_Key_Values__c<> null and Id =: proId];
			if(lstPrd2.isEmpty()){
				return new RemoteResponse('No Available key value assign for this product - ' + proId, RemoteResponse.STATUSCODE_ERROR);
			}
			Product2 curProduct = lstPrd2.get(0);
			List<String> lstAvailableKey = curProduct.Available_Key_Values__c.split(';');
			for(DART_KeyValue_2__c key : [Select Key_Value__c,Id,Key_Value_Name__c, Key_ValueType_FreeForm__c, Site__c From DART_KeyValue_2__c where Site__c =: curProduct.Site__c And Node_ID__c = null And Name IN: lstAvailableKey And Key__c <> null order by Name] ){
		 		KeyWrp keyOne = new KeyWrp(key.Id, key.Key_Value__c, key.Key_Value_Name__c, key.Key_ValueType_FreeForm__c, key.Site__c);
		 		keyList.add(keyOne);
		 	}

		 	//Existing keyvalues on opportunityLineItem
		 	List<KeyValueSetWrp> keyValueSetWrpList = initExistingKeyValueSetList(targetId);


		 	RemoteResponse response = new RemoteResponse();
            response.content = new Map<String, Object>{
            	'keyList' => keyList,
            	'keyValueSetWrpList' => keyValueSetWrpList,
            	'predefinedKeyValue' => oppLine.AdKeywords__c
            };
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
		} catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
	}

	/**
     * Get Value list available on key
     * @param nodeId, DART_KeyValue_2__c Id
     * @return List<DART_KeyValue_2__c>
     */
	@AuraEnabled
	public static RemoteResponse initValueN(String nodeId, String valueSearch) {
	    String valueSearchQuery = '%' + String.escapeSingleQuotes(valueSearch) + '%';
		ValueWrp[] valueList = new List<ValueWrp>();
		try {
			for(DART_KeyValue_2__c val : [Select Dart6_ValueId__c, Key_Value__c,Id,Key_Value_Name__c, Value_Display_Name__c From DART_KeyValue_2__c where Node_ID__c =: nodeId And Key_Value_Name__c like: valueSearchQuery And Key_Value__c <> Null limit 500]){
		 		ValueWrp valueOne = new ValueWrp(val.Id, String.valueOf(val.Dart6_ValueId__c), val.Key_Value_Name__c, val.Value_Display_Name__c );
		 		valueList.add(valueOne);
		 	}
		 	RemoteResponse response = new RemoteResponse();
            response.content = valueList;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            response.message = valueSearch;

            return response;
		} catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }

	}

	/**
     * Get Key Value template list on Targeting__c
     * @param targetId, Targeting__c Id
     * @return List<KeyValueSetWrp>
     */
	@AuraEnabled
    public static RemoteResponse loadKeyValueTemplate(String targetId){
    	try {
		 	List<KeyValueSetWrp> keyValueSetWrpList = initExistingKeyValueSetList(targetId);


		 	RemoteResponse response = new RemoteResponse();
            response.content = new Map<String, Object>{
            	'keyValueSetWrpList' => keyValueSetWrpList
            };
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
		} catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

	/**
     * Get Key Value list on Targeting__c
     * @param targetId, Targeting__c Id
     * @return List<KeyValueSetWrp>
     */
	private static List<KeyValueSetWrp> initExistingKeyValueSetList(String targetId) {
		Map<Integer, KeyValueWrp[]> mKeyValueWrp = new Map<Integer, KeyValueWrp[]>();
		Map<Id, ValueWrp[]> mValueWrp = new Map<Id, ValueWrp[]>();
		TargetingKeyValueAssociation__c[] tarKeyValueAssList = [ Select
										DART_KeyValue__c, Operator__c, TargetKeyValue__c, KeysetOrder__c,
										DART_KeyValue__r.Key_Value__c, DART_KeyValue__r.Node_ID__c, DART_KeyValue__r.Dart6_ValueId__c,
										DART_KeyValue__r.Key_Value_Name__c,
										DART_KeyValue__r.Key_ValueType_FreeForm__c,
										DART_KeyValue__r.Site__c,
										DART_KeyValue__r.Value_Display_Name__c
										From TargetingKeyValueAssociation__c
										Where Targeting__c = :targetId order by KeysetOrder__c];

		//This is a value
		for(TargetingKeyValueAssociation__c tarKeyValueAss : tarKeyValueAssList) {
			if (tarKeyValueAss.DART_KeyValue__r.Node_ID__c != null) {
				if (!mValueWrp.containsKey(tarKeyValueAss.DART_KeyValue__r.Node_ID__c)) {
					mValueWrp.put(tarKeyValueAss.DART_KeyValue__r.Node_ID__c, new List<ValueWrp>());
				}
				ValueWrp vWrp = new ValueWrp(tarKeyValueAss.DART_KeyValue__c, String.valueOf(tarKeyValueAss.DART_KeyValue__r.Dart6_ValueId__c), tarKeyValueAss.DART_KeyValue__r.Key_Value_Name__c, tarKeyValueAss.DART_KeyValue__r.Value_Display_Name__c);
				vWrp.index = mValueWrp.get(tarKeyValueAss.DART_KeyValue__r.Node_ID__c).size();
				mValueWrp.get(tarKeyValueAss.DART_KeyValue__r.Node_ID__c).add(vWrp);
			}
		}

		//This is a key
		Integer keysetOrderIndex = 0;
		for(TargetingKeyValueAssociation__c tarKeyValueAss : tarKeyValueAssList) {
			if (tarKeyValueAss.KeysetOrder__c != null && tarKeyValueAss.DART_KeyValue__r.Node_ID__c == null) {
				Integer keysetOrder = Integer.valueOf(tarKeyValueAss.KeysetOrder__c);
				if (!mKeyValueWrp.containsKey(keysetOrder)) {
					mKeyValueWrp.put(keysetOrder, new List<KeyValueWrp>());
					keysetOrderIndex = keysetOrder;
				}
				KeyValueWrp kvWrp = new KeyValueWrp();
				kvWrp.index = mKeyValueWrp.get(keysetOrder).size();
				kvWrp.keyone = new KeyWrp(tarKeyValueAss.DART_KeyValue__c, tarKeyValueAss.DART_KeyValue__r.Key_Value__c, tarKeyValueAss.DART_KeyValue__r.Key_Value_Name__c, tarKeyValueAss.DART_KeyValue__r.Key_ValueType_FreeForm__c, tarKeyValueAss.DART_KeyValue__r.Site__c);
				kvWrp.opperator = tarKeyValueAss.Operator__c;
				kvWrp.valueN = mValueWrp.get(tarKeyValueAss.DART_KeyValue__c);
				mKeyValueWrp.get(keysetOrder).add(kvWrp);
			}
		}

		//List key value set
		List<KeyValueSetWrp> keyValueSetWrpList = new List<KeyValueSetWrp>();
		for (Integer i = 0; i <= keysetOrderIndex; i++) {
			KeyValueSetWrp kvSetWrp = new KeyValueSetWrp();
			kvSetWrp.index = i;
			kvSetWrp.valueListSel = new List<ValueWrp>();
			kvSetWrp.keyOneSel = new KeyWrp(null, '', '', false, null);
			kvSetWrp.keyValueN = mKeyValueWrp.get(i);
			keyValueSetWrpList.add(kvSetWrp);
		}
		return keyValueSetWrpList;
	}

	/**
     * Build KeyValue String from defined list
     * @param keyValueSetLst, KeyValueSetWrp List
     * @return String
     */
	private static String buildKeyValueString(List<KeyValueSetWrp> keyValueSetLst) {
		String keyValueSetString = '';
		for (KeyValueSetWrp kvSetWrp : keyValueSetLst) {
			String keyValueString = '';
			if (kvSetWrp.keyValueN == null) continue;
			for (KeyValueWrp kvWrp : kvSetWrp.keyValueN) {
				String valuesString = '';
				for (ValueWrp vWrp : kvWrp.valueN) {
					valuesString += '(' + kvWrp.keyone.keyName + getOperatorSign(kvWrp.opperator) + vWrp.valueLabel + ')' + DEFAULT_CONJUN_IN_VALUE;
				}
				if (kvWrp.valueN.size() > 0 ) {
					valuesString = valuesString.removeEnd(DEFAULT_CONJUN_IN_VALUE);
					if (kvWrp.valueN.size() > 1) {
						valuesString = '(' + valuesString + ')';
					}
				}
				keyValueString += valuesString + DEFAULT_CONJUN_IN_SET;
			}
			if (kvSetWrp.keyValueN.size() > 0 ) {
				keyValueString = keyvalueString.removeEnd(DEFAULT_CONJUN_IN_SET);
				if (kvSetWrp.keyValueN.size() > 1) {
					keyValueString = '(' + keyValueString + ')';
				}
				keyValueSetString += keyValueString + DEFAULT_CONJUN_OUT_SET;
			}
		}
		if (keyValueSetLst.size() > 0 ) {
			keyValueSetString = keyValueSetString.removeEnd(DEFAULT_CONJUN_OUT_SET);
		}
		return keyValueSetString;
	}

	/**
     * Get Operator Sign
     * @param operator, Operator String
     * @return String
     */
	private static String getOperatorSign(String operator) {
		return operator == 'is' ? '=' : '<>';
	}

	/**
     * Save KeyValue Data
     * @param lineItemId, OpportunityLineItem Id
     * @param keyValueSetList, Json List
     * @return String
     */
	@AuraEnabled
	public static RemoteResponse saveKeyValue(String lineItemId, String keyValueSetList) {
		try {
			OpportunityLineItem oppLine = [Select Name, Targeting__c  From OpportunityLineItem Where Id =: lineItemId];
			String targetId = oppLine.Targeting__c;
			if (oppLine.Targeting__c == null) {
				Targeting__c tg = new Targeting__c(Description__c = oppLine.Name + ' Targeting');
				insert tg;
				targetId = tg.Id;
				oppLine.Targeting__c =  tg.Id;
			}

			List<KeyValueSetWrp> keyValueSetLst = saveKeyValueTargeting(targetId, keyValueSetList);
			oppLine.KeyValueString__c = buildKeyValueString(keyValueSetLst);
			update oppLine;

			RemoteResponse response = new RemoteResponse();
            response.content = keyValueSetLst;
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
		} catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
	}

	/**
     * Save KeyValue Template
     * @param targetId, Targeting__c Id
     * @param keyValueSetList, Json List
     * @return List<KeyValueSetWrp>
     */
	@AuraEnabled
	public static RemoteResponse saveKeyValueTemplate(String targetId, String keyValueSetList) {
		try {
			List<KeyValueSetWrp> keyValueSetLst = saveKeyValueTargeting(targetId, keyValueSetList);

			RemoteResponse response = new RemoteResponse();
            response.content = keyValueSetLst;
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
		} catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
	}

	/**
     * Save KeyValue Targeting
     * @param targetId, Targeting__c Id
     * @param keyValueSetList, Json List
     * @return List<KeyValueSetWrp>
     */
	private static List<KeyValueSetWrp> saveKeyValueTargeting(String targetId, String keyValueSetList){
		List<KeyValueSetWrp> keyValueSetLst = (List<KeyValueSetWrp>) JSON.deserialize(keyValueSetList, List<KeyValueSetWrp>.class);

		List<TargetingKeyValueAssociation__c> tarKeyValueAssList = new List<TargetingKeyValueAssociation__c>();
		Set<String> toKeepAss = new Set<String>();
		Integer keysetOrder = 0;
		Map<String, String> mapOperator = new Map<String, String>();
		List<DART_KeyValue_2__c> lstkvTobeCreated = new List<DART_KeyValue_2__c>();
		//create new free-form value
		for (KeyValueSetWrp kvSetWrp : keyValueSetLst) {
			if (kvSetWrp.keyValueN == null) continue;
			for (KeyValueWrp kvWrp : kvSetWrp.keyValueN) {
				for (ValueWrp vWrp : kvWrp.valueN) {
					if(vWrp.valueId == ''){
						DART_KeyValue_2__c kv = new DART_KeyValue_2__c(Active__c = true, Name = vWrp.valueLabel, Key_Value_Name__c = vWrp.valueLabel, Key_Value__c = DART6_KeyValueController.fetchInvalidChars(vWrp.valueLabel), Node_ID__c = kvWrp.keyone.keyId, Site__c = kvWrp.keyone.siteId);
						lstkvTobeCreated.add(kv);
						mapOperator.put(kvWrp.keyone.keyId+'_'+vWrp.valueLabel, kvWrp.opperator);
					}
				}
			}
		}
		if(!lstkvTobeCreated.isEmpty()) insert lstkvTobeCreated;
		//create association for new value
		for(DART_KeyValue_2__c kv : lstkvTobeCreated){
			String valAssField = targetId + kv.Id;
			toKeepAss.add(valAssField);
			tarKeyValueAssList.add(new TargetingKeyValueAssociation__c(Targeting__c = targetId ,DART_KeyValue__c = kv.Id , Operator__c = mapOperator.get(kv.Node_ID__c+'_'+kv.Key_Value_Name__c), targetkeyvalue__c = valAssField));
		}
		Set<String> setKeyVal = new Set<String>();
		for (KeyValueSetWrp kvSetWrp : keyValueSetLst) {
			if (kvSetWrp.keyValueN == null) continue;
			for (KeyValueWrp kvWrp : kvSetWrp.keyValueN) {
				String keyAssField = targetId + kvWrp.keyone.keyId;
				if(!setKeyVal.contains(keyAssField)){
					setKeyVal.add(keyAssField);
					toKeepAss.add(keyAssField);
					//New Key Association
					tarKeyValueAssList.add(
						new TargetingKeyValueAssociation__c (
							Targeting__c = targetId,
							DART_KeyValue__c = kvWrp.keyone.keyId,
							Operator__c = kvWrp.opperator,
							TargetKeyValue__c = keyAssField,
							KeysetOrder__c =  keysetOrder
					));
				}
				//New Value Association
				for (ValueWrp vWrp : kvWrp.valueN) {
					if(vWrp.valueId != ''){
						String valAssField = targetId + vWrp.valueId;
						toKeepAss.add(valAssField);
						tarKeyValueAssList.add(new TargetingKeyValueAssociation__c(Targeting__c = targetId ,DART_KeyValue__c = vWrp.valueId , Operator__c = kvWrp.opperator, targetkeyvalue__c = valAssField));
					}
				}
			}
			keysetOrder++;
		}
		upsert tarKeyValueAssList targetkeyvalue__c;

		delete [Select Id From TargetingKeyValueAssociation__c Where Targeting__c= :targetId And targetkeyvalue__c Not In :toKeepAss ];

		return keyValueSetLst;
	}

	/**
     * KeyValueSet Wrapper Class
     */
    public class KeyValueSetWrp {
    	//DEFAULT_CONJUN_IN_SET
    	@AuraEnabled
    	public Integer index;
    	//List checked Values of a selected key
    	@AuraEnabled
    	public ValueWrp[] valueListSel;
    	//Selected Key
    	@AuraEnabled
    	public KeyWrp keyOneSel;
    	@AuraEnabled
    	public KeyValueWrp[] keyValueN;
    }

    /**
     * KeyValue Wrapper Class
     */
    public class KeyValueWrp {
    	@AuraEnabled
    	public Integer index;
    	@AuraEnabled
    	public KeyWrp keyone;
    	@AuraEnabled
    	public String opperator;
    	//DEFAULT_CONJUN_IN_VALUE
    	@AuraEnabled
    	public ValueWrp[] valueN;

    }

    /**
     * Value Wrapper Class
     */
    public class ValueWrp {
    	@AuraEnabled
    	public Integer index;
    	@AuraEnabled
    	public String valueId;
    	@AuraEnabled
    	public String valueName; 
    	@AuraEnabled
    	public String valueLabel;
    	@AuraEnabled
        public String valueDisplayLabel;
    	@AuraEnabled
    	public Boolean isChecked = false;
    	@AuraEnabled
    	public Boolean isVisible = true;

    	public ValueWrp(String idSobj, String name, String label) {
    		valueId = idSobj;
    		valueName = name;
    		valueLabel = label;
    	}
    	
    	public ValueWrp(String idSobj, String name, String label, String DisplayLabel) {
            valueId = idSobj;
            valueName = name;
            valueLabel = label;
            valueDisplayLabel = String.isBlank(DisplayLabel) ? label : DisplayLabel + ' ( ' + label + ' )';
        }
    }

    /**
     * Key Wrapper Class
     */
    public class KeyWrp {
    	@AuraEnabled
    	public String keyId;
    	@AuraEnabled
    	public String keyName;
    	@AuraEnabled
    	public String keyLabel;
    	@AuraEnabled
    	public boolean isFreeForm;
    	@AuraEnabled
    	public String siteId;


    	public KeyWrp(String idSobj, String name, String label) {
    		keyName = name;
    		keyLabel = label;
    		keyId = idSobj;
    	}

    	public KeyWrp(String idSobj, String name, String label, boolean isFf, String sid) {
    		keyName = name;
    		keyLabel = label;
    		keyId = idSobj;
    		isFreeForm = isFf;
    		siteId = sid;
    	}
    }
}