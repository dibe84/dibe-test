///////////////////////////////////////////////////////////////////////////
// Class UTIL_RollUpSummary
// Used to create rollup values on parent records.
// Based on: http://www.anthonyvictorio.com/salesforce/roll-up-summary-utility/
// Some small adjustments to enable running from set of Id's instead of list.
///////////////////////////////////////////////////////////////////////////

/* 
UTIL_RollUpSummary.rollUpTrigger accepts:
fieldDefinitions (list<UTIL_RollUpSummary.fieldDefinition>) – The list of field definitions.  
    The fieldDefinition class is comprised of three variables:
    - operation (String) – Can be either SUM, MAX, MIN, or COUNT. When using COUNT, the childField must ALWAYS be ‘ID’.
    - childField (String) – The api name for the child object’s field that contains the values you wish to summarize. Remember, when using the COUNT operation, the value for this variable must ALWAYS be ‘ID’.
    - parentField (String) – The api name for the parent object’s field that where the summarized value of the child object field will be stored.

parentIds (set<Id>)             – The set of records being passed to the utility.
childObject (String)            – The API name for the child object. This object must have either a look-up or master-detail relationship to a parent object.
childParentLookupField (String) – The API name for the child object field that performs a look-up to a parent object where the summary results will be stored.
parentObject (String)           – The API name for the parent object related to the child object. The childParentLookupField variable must be related to the object supplied in this variable.
queryFilter (String)            – An SOQL statement that will be used to filter the child object records. The string must always begin with ‘and’ if it’s being used. 
								  If no filter is needed simply supply an empty text value of ”, never supply a NULL value. Let’s say that based on the above example we only want to get a sum of payments made by check, our code would look like this: 'and Type__c = \'Check\''

Definition: 	... = new UTIL_RollUpSummary.fieldDefinition(operation, childfield, parentfield)
Execute: 		UTIL_RollUpSummary.rollUpTrigger(fieldDefinitions, parentIds, childObject, childParentLookupField, parentObject, queryFilter)

*/
public with sharing class UTIL_RollUpSummary {
     
    //the following class will be used to house the field names and desired operations
    public class fieldDefinition {
        public String operation {get;set;}
        public String childField {get;set;}
        public String parentField {get;set;}
         
        public fieldDefinition (String o, String c, String p) {
            operation = o;
            childField = c;
            parentField = p;
        }
    }
     
    public static Map<String, String> mapFieldType = new Map<String, String>();
    
    public static void rollUpTrigger(list<fieldDefinition> fieldDefinitions,
    set<Id> parentIds, String childObject, String childParentLookupField, 
    String parentObject, String queryFilter) {
        
        if (parentIds == null || parentIds.size()==0) return;
         
        //populate query text strings to be used in child aggregrator and parent value assignment
        String fieldsToAggregate = '';
        String parentFields = '';
         
        for(fieldDefinition d : fieldDefinitions) {
            fieldsToAggregate += d.operation + '(' + d.childField + ') ' + ', ';
            parentFields += d.parentField + ', ';
        }
        
        // for multi currency orgs, aggregated currencies, need to be corrected with coversion value
        // Currency ISO code is stored for the parent records
        // 
        Map<Id,String> parentCurIsoCode = new Map<Id,String>(); 
        List<sObject> parents = Database.query('Select Id, CurrencyIsoCode from ' + parentObject + ' where Id IN : parentIds');
        for (sObject so : parents) {
            parentCurIsoCode.put((Id)so.get('Id'),(String)so.get('CurrencyIsoCode'));
        }
         
        //Using dynamic SOQL with aggregate results to populate parentValueMap
        String aggregateQuery = 'Select ' + fieldsToAggregate + 
        childParentLookupField + ' from ' + childObject + ' where  ' + 
        childParentLookupField + ' IN :parentIds ' + queryFilter + ' ' +
        ' group by ' + childParentLookupField;
         
        //Map will contain one parent record Id per one aggregate object
        map<Id, AggregateResult> parentValueMap = new map <Id, AggregateResult>();
        system.debug('aggregateQuery=='+aggregateQuery); 
        for(AggregateResult q : Database.query(aggregateQuery)){
            parentValueMap.put((Id)q.get(childParentLookupField), q);
        }
         
        //list of parent object records to update
        list<sObject> parentsToUpdate = new list<sObject>();
        list<sObject> parentsToIterate = new list<sObject>();

        for (Id i : parentIds) {
            if (i==null) continue; // filter out any null values
        	sObject so = i.getSObjectType().newSObject();
        	so.Id = i;
        	parentsToIterate.add( so );
        }
        
        //## String parentQuery = 'select ' + parentFields + ' Id ' + ' from ' + parentObject + ' where Id IN :parentIds';
         
        //for each affected parent object, retrieve aggregate results and 
        //for each field definition add aggregate value to parent field
        // ## for(sObject s : Database.query(parentQuery)) {
        for(sObject s : parentsToIterate ) {
             
            Integer row = 0; //row counter reset for every parent record
            for(fieldDefinition d : fieldDefinitions) {
                String field = 'expr' + row.format();
                AggregateResult r = parentValueMap.get(s.Id);
                
                String fieldType = GW_sObject.getFieldType(parentObject, d.parentField);
                
                //r will be null if no records exist 
                //(e.g. last record deleted)
                if(r != null) { 
                	if ( fieldType == 'STRING' || fieldType == 'TEXTAREA' ) {
                		Object value = (r.get(field) == null ) ? null : r.get(field);
                		s.put(d.parentField, String.valueOf(value) );
                    } else if (fieldType == 'CURRENCY') {
                        Decimal value = (r.get(field) == null ) ? 0 : (Decimal)r.get(field);
                        // correct with conversion rate
                        String cur = parentCurIsoCode.get(s.Id);
                        Decimal convRate = GW_CurrencyType.currencyTypeMap.get(cur).ConversionRate;
                        
                        if (convRate==null) convRate=1;
                        s.put(d.parentField, value*convRate );
                    } else {
                		Object value = (r.get(field) == null ) ? null : r.get(field);
                		s.put(d.parentField, value);
                	}
                } else {
                	IF ( fieldType == 'CURRENCY' || fieldType == 'DOUBLE' || fieldType == 'INTEGER' || fieldType == 'DECIMAL' || fieldType == 'LONG' ) {
                		s.put(d.parentField, 0);
                	} ELSE {
                		s.put(d.parentField, null);
                	}
                }
                row += 1; //plus 1 for every field definition after first
            }
            parentsToUpdate.add(s);
        }
         
        //if parent records exist, perform update of all parent records 
        //with a single DML statement
        if(parentsToUpdate.Size() > 0) {
            update parentsToUpdate;
        }
    }

}