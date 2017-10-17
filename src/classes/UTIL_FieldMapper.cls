public with sharing class UTIL_FieldMapper {
	
    public List<MappedField> fields; 				// used in v1 implementation - will be deprecated
    public List<MappedElement> mappingElements; 	// used in v2 implementation
    public enum ElementType {FIELDTYPE, MAPTYPE, LISTTYPE}
    
    public List<String> mappingErrors;				// used in v1 & v2 implementation

	public UTIL_FieldMapper() {						// Constructor
        fields = new List<MappedField>();
        mappingElements = new List<MappedElement>();
        mappingErrors = new List<String>();
    }
    
    public void add(MappedElement el) {
        if (el != null ) this.mappingElements.add(el);
    }
    
    public Interface MappedElement {
        MappedElement add(MappedElement el);
        Object getValue();
        Boolean hasChildren();
        String getKey();
        ElementType getType();
    }
    
    public class MappedList implements MappedElement {
    	
    	public List<MappedElement> children;
        public String objectName;
        public Boolean allowNullValues = true;
        
        public MappedList(String objectName) {
			this.objectName = objectName;
            this.children = new List<MappedElement>();
        }

        public MappedList( String objectName , Boolean allowNullValues ) {
			this( objectName );
            this.allowNullValues = allowNullValues;
        }

        public ElementType getType() {return ElementType.LISTTYPE;}
        
        public MappedElement add( MappedElement el ){
            if( allowNullValues || el.getValue() != null ){ children.add(el); }  
            return this;
        }
       
        public String getKey() {return objectName; }
        
        public Object getValue() {
            List<Object> valueList;
            
            if (this.hasChildren()) {
                valueList = new List<Object>();

                //for (MappedElement child : this.children ) {
                //    valueList.add( child.getValue() );
                //}
                
                //reverse the order
                for (Integer i = this.children.size()-1; i >= 0; i--  ) {
                    valueList.add( children[i].getValue() );
                }  
            }
            return valueList;
        }
        
        public Boolean hasChildren() { 
            return !children.isEmpty(); 
        }    
    }

	public class MappedField implements MappedElement {
		public String fieldName;
        public Object value;
		public String fieldType;
		public Integer fieldSize;
		public Boolean fieldMandatory;
        public Boolean relevantOnChange;
        
        public MappedField(String fieldName, String stringValue, String fieldType, Integer fieldSize, Boolean fieldmandatory) {
            this(fieldName,(Object)stringValue,fieldType,fieldSize,fieldMandatory,null);
        }
        
        public MappedField(String fieldName, String stringValue, String fieldType, Integer fieldSize, Boolean fieldmandatory, Boolean relevantOnChange) {
            this(fieldName,(Object)stringValue,fieldType,fieldSize,fieldMandatory,relevantOnChange);
        }
        
        public MappedField(String fieldName, Object value, String fieldType, Integer fieldSize, Boolean fieldmandatory, Boolean relevantOnChange) {
            this.fieldName = fieldName;
            this.value = value;
            this.fieldType = fieldType;
            this.fieldSize = fieldSize;
            this.fieldMandatory = fieldMandatory;
            this.relevantOnChange = relevantOnChange;
        }
        
        public MappedElement add(MappedElement el){ return this; }
        public ElementType getType() {return ElementType.FIELDTYPE;}
        public String getKey() { return this.fieldName; }
        
        public Object getValue() { 

            If (this.fieldType.toUpperCase() == 'STRING') {}
            If (this.fieldType.toUpperCase() == 'TEXTAREA') {}
            If (this.fieldType.toUpperCase() == 'CURRENCY' ) {}
            If (this.fieldType.toUpperCase() == 'DOUBLE' ) {}
            If (this.fieldType.toUpperCase() == 'DATETIME') {}
            If (this.fieldType.toUpperCase() == 'DATE') {}
            If (this.fieldType.toUpperCase() == 'BOOLEAN') {}
            If (this.fieldType.toUpperCase() == 'REFERENCE') {}

            return this.value; 
        }
        public Boolean hasChildren() { 
            return false; 
        }
    }
    
    public class MappedObject implements MappedElement{
    	
        public List<MappedElement> children;
        public String objectName;
        public Boolean allowNullValues = true;
        
        public MappedObject(String objectName) {
            this.objectName = objectName;
            this.children = new List<MappedElement>();
        }
        
        public MappedObject( String objectName , Boolean allowNullValues ) {
			this( objectName );
            this.allowNullValues = allowNullValues;
        }
        
        public MappedElement add( MappedElement el ){
            if( allowNullValues || el.getValue() != null ){ children.add(el); }  
            return this;
        }
        
        public ElementType getType() {return ElementType.MAPTYPE;}
        public String getKey() {return objectName; }
        
        public Object getValue() {
            Map<String,Object> valueMap;
            
            if (this.hasChildren()) {
                valueMap = new Map<String,Object>();
                //for (MappedElement child : this.children ) {
                //    valueMap.put( child.getKey(), child.getValue() );
                //}  
                
                //reverse the order
                for (Integer i = this.children.size()-1; i >= 0; i--  ) {
                    valueMap.put(children[i].getKey(), children[i].getValue());
                }  
            }
            return valueMap;
        }
        
        
        public Boolean hasChildren() { 
            return !children.isEmpty(); 
        }
    }
    
    private List<String> checkMappedElement(MappedElement el) {
        List<String> errors = new List<String>();
        if (el instanceof MappedField) {
            String error = checkMappedField((MappedField) el);
            if (error != null) 
                errors.add(error);
            else 
                return null;
        } 
        
        if (el instanceof MappedObject && el.hasChildren() ) {
            MappedObject mo = (MappedObject) el;
            for (MappedElement child : mo.children ) {
                List<String> childErrors = checkMappedElement(child);
            	if ( childErrors != null ) errors.addAll( childErrors ); 
            } 
        }
		/*
        if (el instanceof MappedList && el.hasChildren() ) {
            MappedList ml = (MappedList) el;
            for(MappedElement mel : ml.children){
                MappedObject mo = (MappedObject) mel;
                for (MappedElement child : mo.children ) {
                    List<String> childErrors = checkMappedElement(child);
                    if ( childErrors != null ) errors.addAll( childErrors ); 
                } 
            }
        }
        */
        
        if ( !errors.isEmpty() ) return errors;
        return null;
    }
    
    private String checkMappedField(MappedField mf) {
    	if (mf.fieldMandatory && mf.value == null )
            return mf.fieldName;
        else
            return null;
    }
    
    public Boolean mandatoryFieldsNotNull() {
        
        // v1 implementation
        if ( !fields.isEmpty() ) {
            for (MappedField mf : fields) {
                String error = checkMappedField(mf);
                if (error != null ) mappingErrors.add(error);
            }
        }
        // v2 implementation
        if ( !mappingElements.isEmpty() ) {
            for (MappedElement el : mappingElements) {
                List<String> elErrors = checkMappedElement(el);
            	if ( elErrors != null ) mappingErrors.addAll( elErrors );      
            }
        }
        
        if ( mappingErrors.size() > 0 ) {
            UTIL.log(mappingErrors);
            return false;
        }
        return true;
    }
	
    public String getRelevantFieldComparisonString() {
    	Map<String,Object> outputMap;
        if ( !mappingElements.isEmpty() ) {
            outputMap = new Map<String,Object>();
        	for (MappedElement el : mappingElements) {
            	if (el instanceof MappedObject && el.hasChildren() )  
                    outputMap.put(el.getKey(), el.getValue());   
                if (el instanceof MappedField && ((MappedField) el).relevantOnChange )
                    outputMap.put(el.getKey(), el.getValue());  
                if (el instanceof MappedList && el.hasChildren() )
                    outputMap.put(el.getKey(), el.getValue());
            }  
        }
        return JSON.serialize(outputMap);   
    }
    
    public Map<String,Object> getOutputMap() {
        Map<String,Object> output;
        
        // v1 implementation - will be deprecated
        if ( !fields.isEmpty() ) {
            output = new Map<String,Object>();
            Object tmpValue;
            for (MappedField mf : fields) {
                tmpValue=mf.value;
                if (mf.fieldMandatory && tmpValue==null) throw new UTIL.CustomException('Value of field: '+ mf.fieldName + ' invalid. ('+ tmpValue +')');
                if (tmpValue==null) tmpValue='';
                if (tmpValue instanceof String && ((String)tmpValue).length()>mf.fieldSize ) tmpValue = ((String)tmpValue).substring(0,mf.fieldSize);  
                output.put(mf.fieldName, tmpValue);
            }    
        }
        // v2 implementation
        if ( !mappingElements.isEmpty() ) {
            output = new Map<String,Object>();
        	//for (MappedElement el : mappingElements) {
            //	output.put(el.getKey(), el.getValue());    	      
            //}  
            
            // reverse order to undo JSON serialize reversing...
            for (Integer i = mappingElements.size()-1; i >= 0; i--  ) {
                output.put(mappingElements[i].getKey(), mappingElements[i].getValue());
            }
        }
        
        return output;
    }
}