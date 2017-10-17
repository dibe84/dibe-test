public class LSC_Helper {
    
    public LSC_Helper() {
        
    }

    public class FieldSetMember {

        public Boolean DBRequired { get;set; }
        public String fieldPath { get;set; }
        public String label { get;set; }
        public Boolean required { get;set; }
        public String type { get; set; }
        public List<PicklistOptions> options { get; set; }

        public FieldSetMember( Schema.FieldSetMember f ) {
            this.DBRequired = f.DBRequired;
            this.fieldPath = f.getFieldPath();
            this.label = f.getLabel();
            this.required = f.required;
            this.type = '' + f.getType();
        }

        public void setPickListOptions( List<PicklistOptions> picklistOptions ){
            this.options = new List<PicklistOptions>();
            this.options = picklistOptions; 
        }

        public FieldSetMember(Boolean DBRequired) {
            this.DBRequired = DBRequired;
        }

    }

    public class PicklistOptions{

        public String label;
        public String value;

        public PicklistOptions( String label, String value ){
            this.label = label;
            this.value = value;
        }

        public PicklistOptions( Schema.PicklistEntry pickList ){
            this.label = picklist.getLabel();
            this.value = picklist.getValue();
        }

    }
	
	static Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
    public static List<FieldSetMember> getFieldSet( String objectName, String fieldSetsName ){

        // convert objectName 
        // from string to Sobject
        Schema.SObjectType convertType = gd.get( objectName );

        // describe converted Sobject to
        // get fiedsets
        Map<String, Schema.FieldSet> fieldSetNameMapToFieldSet = convertType.getDescribe().fieldSets.getMap();
        List<Schema.FieldSetMember> fieldSetMemberList = fieldSetNameMapToFieldSet.get( fieldSetsName ).getFields();

        // return field set member list
        List<FieldSetMember> returnList = new List<FieldSetMember>();

        for( Schema.FieldSetMember eachFieldSetMember : fieldSetMemberList ){
            FieldSetMember newFieldSet = new FieldSetMember( eachFieldSetMember );
            
            if( newFieldSet.type.equalsIgnoreCase( 'picklist' )){
                newFieldSet.setPickListOptions( getPicklistOptionValues(objectName, newFieldSet.fieldPath) );
            }
            
            returnList.add( newFieldSet );
        }

        return returnList;
    } 
    
    public static List<PicklistOptions> getPicklistOptionValues(String sobjectName, String fieldName){
    	
    	if(fieldName == 'Salutation') return new List<PicklistOptions>{
    		new PicklistOptions('--None--', ''),
    		new PicklistOptions('Mr.', 'Mr.'),
    		new PicklistOptions('Ms.', 'Ms.')
    	};
    	
    	List<PicklistOptions> lstPicklistOptions = new List<PicklistOptions>{
    		new PicklistOptions('--None--', '')
    	};
    	
    	SobjectType sobject_type = gd.get(sobjectName);
    	
  		Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
  		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
  		List<Schema.PicklistEntry> pick_list_values = field_map.get(fieldName).getDescribe().getPickListValues();
  		for (Schema.PicklistEntry a : pick_list_values) {
        	lstPicklistOptions.add(new PicklistOptions(a.getLabel(), a.getValue()));
  		}
  		return lstPicklistOptions;
    }
    
}