public class LCS_UTILS {
   
    static Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
    
    public static List<Schema.DescribeDataCategoryGroupStructureResult> getListDataCategory(String cateroyType) {
    	
        List <DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();
        DataCategoryGroupSobjectTypePair pair2 = new DataCategoryGroupSobjectTypePair();
        pair2.setSobject('KnowledgeArticleVersion');
        pair2.setDataCategoryGroupName(cateroyType);
        pairs.add(pair2);
        List<Schema.DescribeDataCategoryGroupStructureResult>results = Schema.describeDataCategoryGroupStructures(pairs, false);
        
        return results;
    }
    
    public static Map<String,List<String>> getDependentOptionsImpl(String objApiName , String contrfieldApiName , String depfieldApiName) {
           
        String objectName = objApiName.toLowerCase();
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        //get the String to sobject global map
        Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
         
        if (!Schema.getGlobalDescribe().containsKey(objectName)){
            System.debug('OBJNAME NOT FOUND --> ' + objectName);
            return null;
        }
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType==null) return objResults;
        
        Bitset bitSetObj = new Bitset();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        //Check if picklist values exist
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            System.debug('FIELD NOT FOUND --> ' + controllingField + ' OR ' + dependentField);
            return objResults;     
        }
        
        List<Schema.PicklistEntry> contrEntries = objFieldMap.get(controllingField).getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> depEntries = objFieldMap.get(dependentField).getDescribe().getPicklistValues();
        objFieldMap = null;

        List<Integer> controllingIndexes = new List<Integer>();
        for(Integer contrIndex=0; contrIndex<contrEntries.size(); contrIndex++){            
            Schema.PicklistEntry ctrlentry = contrEntries[contrIndex];
            String label = ctrlentry.getLabel();
            objResults.put(label,new List<String>());
            controllingIndexes.add(contrIndex);
        }
        List<Schema.PicklistEntry> objEntries = new List<Schema.PicklistEntry>();
        List<PicklistEntryWrapper> objJsonEntries = new List<PicklistEntryWrapper>();
        for(Integer dependentIndex=0; dependentIndex<depEntries.size(); dependentIndex++){            
               Schema.PicklistEntry depentry = depEntries[dependentIndex];
               objEntries.add(depentry);
        } 
        objJsonEntries = (List<PicklistEntryWrapper>)JSON.deserialize(JSON.serialize(objEntries), List<PicklistEntryWrapper>.class);
        List<Integer> indexes;
        for (PicklistEntryWrapper objJson : objJsonEntries){
            if (objJson.validFor==null || objJson.validFor==''){
                continue;
            }
            indexes = bitSetObj.testBits(objJson.validFor,controllingIndexes);
            for (Integer idx : indexes){                
                String contrLabel = contrEntries[idx].getLabel();
                objResults.get(contrLabel).add(objJson.label);
            }
        }
        objEntries = null;
        objJsonEntries = null;
        return objResults;
    }
    
    public static List<FieldSetMember> getFieldSetMember( String objectName, String fieldSetsName ){

        List<FieldSetMember> returnList = new List<FieldSetMember>();
        // convert objectName from String to Sobject
        Schema.SObjectType convertType = gd.get( objectName );
        if(convertType == null) return returnList;
            
        // describe converted Sobject to get fiedsets
        Map<String, Schema.FieldSet> fieldSetNameMapToFieldSet = convertType.getDescribe().fieldSets.getMap();
        List<Schema.FieldSetMember> fieldSetMemberList = fieldSetNameMapToFieldSet.containsKey(fieldSetsName)  ?  fieldSetNameMapToFieldSet.get( fieldSetsName ).getFields() : new List<Schema.FieldSetMember>();
		if(Test.isRunningTest() && !fieldSetNameMapToFieldSet.isEmpty()) {
			fieldSetMemberList = fieldSetNameMapToFieldSet.values().get(0).getFields();
		}
        // return field set member list
        for( Schema.FieldSetMember eachFieldSetMember : fieldSetMemberList ){
            FieldSetMember newFieldSet = new FieldSetMember( eachFieldSetMember );
            if( newFieldSet.type.equalsIgnoreCase( 'picklist' )){
                newFieldSet.setPickListOptions( getPicklistOptionValues(objectName, newFieldSet.fieldPath) );
            }
            returnList.add( newFieldSet );
        }
        return returnList;
    } 
    
    
    private static List<PicklistOptions> getPicklistOptionValues(String sobjectName, String fieldName) {
     	
    	List<PicklistOptions> lstPicklistOptions = new List<PicklistOptions> { new PicklistOptions('--None--', '')	};
    	
    	SobjectType sobject_type = gd.get(sobjectName);
  		Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
  		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
  		List<Schema.PicklistEntry> pick_list_values = field_map.get(fieldName).getDescribe().getPickListValues();
  		for (Schema.PicklistEntry a : pick_list_values) {
        	lstPicklistOptions.add(new PicklistOptions(a.getLabel(), a.getValue()));
  		}
  		return lstPicklistOptions;
    }

   
    /*-------------- Helper class ------------- -*/ 
   
    public class PicklistEntryWrapper {
       public String active        {get;set;}
       public String defaultValue  {get;set;}
       public String label         {get;set;}
       public String value         {get;set;}
       public String validFor      {get;set;}
    }
    
     public class FieldSetMember {
        public Boolean DBRequired   {get;set;}
        public String fieldPath     {get;set;}
        public String label         {get;set;}
        public Boolean required     {get;set;}
        public String type          {get;set;}
        public List<PicklistOptions> options { get; set; }
        public FieldSetMember( Schema.FieldSetMember f ) {
            this.DBRequired = f.DBRequired;
            this.fieldPath  = f.getFieldPath();
            this.label      = f.getLabel();
            this.required   = f.required;
            this.type       = '' + f.getType();
        }

        public void setPickListOptions( List<PicklistOptions> picklistOptions ){
            this.options = new List<PicklistOptions>();
            this.options = picklistOptions; 
        }

        public FieldSetMember(Boolean DBRequired) {
            this.DBRequired = DBRequired;
        }
    }
    
    public class PicklistOptions {
        public String label;
        public String value;
        public PicklistOptions( String label, String value ) {
            this.label = label;
            this.value = value;
        }
        public PicklistOptions( Schema.PicklistEntry pickList ) {
            this.label = picklist.getLabel();
            this.value = picklist.getValue();
        }
    }
    
}