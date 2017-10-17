/**
 * Created by ronvelzeboer on 15/09/16.
 */

public with sharing class VAL_Global {
    private static Map<Id, Map<String, Map<String, CustomAttribute__c>>> accountCustomAttributeMap = new Map<Id, Map<String, Map<String, CustomAttribute__c>>>();
    private static Map<Id, Set<String>> accountMemberUnits = new Map<Id, Set<String>>();

    public class AccountCustomAttributeValidator implements UTIL_FieldValidator.IDelegatedValidator {
        public AccountCustomAttributeValidator() { }

        // TODO: refactor validate method, split in multiple methods
        public UTIL_FieldValidator.IFieldValidationResult validate(SObject so, FieldValidation__c fv) {
            Account acc = (Account) so;

            if (String.isEmpty(fv.Param__c)) {
                UTIL.throwError('Param field required for field validation rule \'' + fv.Name + '\'. Its value should be: <MEMBERUNITID>.');
            }
            String memberUnitId = fv.Param__c;

            if (! accountMemberUnits.containsKey(acc.Id)) {
                accountMemberUnits.put(acc.Id, new Set<String>());

                List<AccountMemberUnitAssociation__c> associations = GW_AccountMemberUnitAssociation.getAll(acc.Id);
                for (AccountMemberUnitAssociation__c association : associations) {
                    accountMemberUnits.get(acc.Id).add(association.MemberUnit__r.MemberUnitId__c);
                }
            }
            if (!accountMemberUnits.get(acc.Id).contains(memberUnitId)) {
                return null;
            }

            List<String> fieldParts = fv.FieldName__c.split('\\.');

            if (fieldParts.size() <= 1) { // only relationship check, no field check on relationship
                UTIL.throwError('No CustomAttribute__c record Name found in field validation rule. Should be format: CustomAttribute.<Name>');
            }
            String fieldName = fieldParts.get(1);

            if (! accountCustomAttributeMap.containsKey(acc.Id)) {
                List<CustomAttribute__c> attribs = (List<CustomAttribute__c>) GW_sObject.queryRecords('CustomAttribute__c', 'Account__c = \'' + acc.Id + '\'');

                //clear cache, because we only want the CustomAttributes of the current account in cache to keep memory usage to a minimum
                accountCustomAttributeMap = new Map<Id, Map<String, Map<String, CustomAttribute__c>>>();
                accountCustomAttributeMap.put(acc.Id, new Map<String, Map<String, CustomAttribute__c>>());

                if (null != attribs) {
                    for (CustomAttribute__c attr : attribs) {
                        if (!accountCustomAttributeMap.get(acc.Id).containsKey(attr.MemberUnitId__c)) {
                            accountCustomAttributeMap.get(acc.Id).put(attr.MemberUnitId__c, new Map<String, CustomAttribute__c>());
                        }
                        accountCustomAttributeMap.get(acc.Id).get(attr.MemberUnitId__c).put(attr.Name, attr);
                    }
                }
            }
            if (!accountCustomAttributeMap.get(acc.Id).containsKey(memberUnitId) || !accountCustomAttributeMap.get(acc.Id).get(memberUnitId).containsKey(fieldName)) {
                return new UTIL_FieldValidator.IncompleteErrorResult(so, fieldName, fv, null);
            }
            CustomAttribute__c attr = accountCustomAttributeMap.get(acc.Id).get(memberUnitId).get(fieldName);
            String fieldValue = String.valueOf(GW_CustomAttribute.getValue(attr));

            if (String.isEmpty(fieldValue)) {
                return new UTIL_FieldValidator.IncompleteErrorResult(so, fieldName, fv, null);
            }
            if (null != fv.Regex__c && !Pattern.matches(String.valueOf(fv.Regex__c), String.valueOf(fieldValue))) {
                return new UTIL_FieldValidator.InvalidErrorResult(so, fieldName, fv, null);
            }
            return null;
        }
    }
    // Bunhor @08-Mar-17
    public static string checkDfpReuiredFields(OpportunityLineItem item) {
		if (item.Targeting__c == null) {
            return 'Please specify targeting for this product.';
        } 
    	// Ad unit is required
    	sObject[] adUnits = GW_sObject.getChildren(item.Targeting__c, 'TargetingContentAssociations__r');
    	if( adUnits == null || adUnits.isEmpty() ) {
    		return 'Ad unit is required!';
    	}
    	return null;
    }
    
    //@VT 18-05-2017  
    public static map<ID,list<InvoiceLine__c>> mapRVInvoiceLine;
    public static map<ID,list<InvoiceLine__c>> mapRSInvoiceLine;
    public static map<ID,ID> mapOLIRV;
    public static map<ID,list<ID>> mapRVRS;
    
    public class OpportunityLineItemInvoicedValidator implements UTIL_FieldValidator.IDelegatedValidator {
        
        public OpportunityLineItemInvoicedValidator() { }
        
        public UTIL_FieldValidator.IFieldValidationResult validate(SObject so, FieldValidation__c fv) {
            
            if (mapRVInvoiceLine.isEmpty() && mapRSInvoiceLine.isEmpty()) return null;   
            
            Id revID = mapOLIRV.get(so.id);        
            if (revID == null)  return null; 
            
            //IF RevItem of LineItem has invoice -> Error
            if( mapRVInvoiceLine.containsKey(revID) ) {
                return new UTIL_FieldValidator.InvalidErrorResult(so, null, fv, null); 
            }  
            
            //IF RevSchedule of LineItem has invoice -> Error
            for (ID RSId : mapRVRS.get(revID)){
                if ( mapRSInvoiceLine.containsKey(RSId)) {
                    return new UTIL_FieldValidator.InvalidErrorResult(so, null, fv, null);
                }
            }   
            
            return null; 
        }       
    }
    
    public static void InitMapInvoiceLine(List<SObject> soLst){
        
        mapOLIRV = new map<ID,ID>();
        mapRVRS  = new map<ID,list<ID>>();
        mapRVInvoiceLine = new map<ID,list<InvoiceLine__c>>();
        mapRSInvoiceLine = new map<ID,list<InvoiceLine__c>>();     
        
        
        set<ID> setOLIId = new set<ID>();
        for(SObject so : soLst){
            setOLIId.add(so.Id);
        }
        
        //get ALL RevenueItem of LineItem
        list<Rev__c> lstRevItems = (list<Rev__c>) GW_sObject.queryRecords('Rev__c', setOLIId, 'OpportunityLineItemId__c');
        if(lstRevItems.isEmpty()) return;
        
        map<Id,Id> mapRevOLI = new map<Id,Id>();
        for(Rev__c revItem : lstRevItems){
            mapRevOLI.put(revItem.id, revItem.OpportunityLineItemId__c);
            mapOLIRV.put(revItem.OpportunityLineItemId__c, revItem.id);
        }
        
        //get all Revenue Schedule of LineItem
        list<RS__c> lstRS = (list<RS__c>) GW_sObject.queryRecords('RS__c', mapRevOLI.keySet(), 'Rev__c' );
        map<Id,Id> mapRSOLI = new map<Id,Id>();
        for(RS__c rs : lstRS){
            if ( mapRevOLI.containsKey(rs.Rev__c) ) mapRSOLI.put(rs.id, mapRevOLI.get(rs.Rev__c));
            
            if ( mapRVRS.containsKey(rs.Rev__c) ) mapRVRS.get(rs.Rev__c).add(rs.id); 
            else mapRVRS.put(rs.Rev__c, new list<id>{rs.id});
        }
        
        for(InvoiceLine__c invLine : (list<InvoiceLine__c>) GW_sObject.queryRecords('InvoiceLine__c', mapRevOLI.keySet(), 'Rev__c')){
            if( mapRVInvoiceLine.containsKey(invLine.Rev__c) ) mapRVInvoiceLine.get(invLine.Rev__c).add(invLine);
            else mapRVInvoiceLine.put(invLine.Rev__c, new list<InvoiceLine__c>{invLine});
        } 
        
        for(InvoiceLine__c invLine : (list<InvoiceLine__c>) GW_sObject.queryRecords('InvoiceLine__c', mapRSOLI.keySet(), 'RS__c')){
            if( mapRSInvoiceLine.containsKey(invLine.RS__c) ) mapRSInvoiceLine.get(invLine.RS__c).add(invLine);
            else mapRSInvoiceLine.put(invLine.RS__c, new list<InvoiceLine__c>{invLine});
        }   
    }
	
	public static void validatePhoneNumber (sObject sObj, Set<String> phoneFields) {

        if(sObj == null || phoneFields == null) return;

        for (String phoneField : phoneFields) {

            String  fieldVal = (String) (sObj.get(phoneField));
                    fieldVal = (fieldVal == null ? '' : fieldVal.trim());

            if (fieldVal.indexOf('+') == -1 || fieldVal.lastIndexOf('+') != 0) {
                UTIL.throwError(phoneField + ' number should start with \'+\' sign, please update with correct value.');
            } else {
                Pattern isNumbers   =   Pattern.Compile('^[0-9]+$');
                fieldVal            =   fieldVal.substring(1, fieldVal.length());
                Matcher phoneMatch  =   isnumbers.matcher(fieldVal);

                if (!phoneMatch.Matches()) {
                    UTIL.throwError(phoneField + ' number should contain only digits, please update with correct value.');
                } else if (fieldVal.length() < 8) {
                    UTIL.throwError(phoneField + ' number length should be minimum of 8 characters, please update with correct value.');
                }
            }

        }
    }

    public static void checkPhoneNumbers(sObject sObj, sObject oldSobj, Set<String> phoneFields) {

        Set<String> fieldsToValidate = new Set<String>();
        if (oldSobj == null) {
        // execute on insert
            for (String phoneField : phoneFields) {
                if (sObj.get(phoneField) != null)
                    fieldsToValidate.add(phoneField);
            }
        } else {
        // execute on update
            for (String phoneField : phoneFields) {
                if (oldSobj.get(phoneField) != sObj.get(phoneField) && sObj.get(phoneField) != null)
                    fieldsToValidate.add(phoneField);
            }
        }

        try {
            VAL_Global.validatePhoneNumber(sObj,fieldsToValidate);
        } catch(Exception ex) {
            sObj.addError(ex.getMessage());
        }

    }
}