public without sharing class  PGC_AccountCustomAttributes {
	public Account acct {set;get;}
    public List<CustomAttribute__c> customAttributes {set;get;}
    public Map<Id,Object> valueMap { get; set; }
    public Map<Id,CustomAttributeDefinition__c> customAttributeDefinitionMap { get; set; }
    
    
    public PGC_AccountCustomAttributes(ApexPages.StandardController stdController){
        this.acct = GW_Account.getRecord(stdController.getRecord().Id);
        this.customAttributes = GW_CustomAttribute.getListFromRelated(this.acct.Id);
        this.valueMap = new Map<Id,Object>();
        Set<Id> definitionIds = new Set<Id>();
        for (CustomAttribute__c attr : this.customAttributes) {
            Object val = GW_CustomAttribute.getValue(attr);
            if (val == null) {
                val = '';
            }
            this.valueMap.put(attr.Id, val);
            definitionIds.add(attr.CustomAttributeDefinition__c);            
        }
        
        this.customAttributeDefinitionMap = new Map<Id,CustomAttributeDefinition__c>([SELECT Id, Name, Label__c FROM CustomAttributeDefinition__c WHERE id IN :definitionIds]);
    }
    
////////////////////////////////////////////////////////
// Execution of validation and update of Account
///////////////////////////////////////////////////////    
    
    public void save() {
        for (CustomAttribute__c attr : this.customAttributes) {
            GW_CustomAttribute.setValue(attr, this.valueMap.get(attr.Id));
        }
        UTIL.logErrors('Attributes: ' + this.customAttributes);
        UTIL.logErrors('ValueMap: ' + this.valueMap);
        saveAttributes();
    }
    
    public void saveAttributes() {
        try {
            UTIL.logErrors('Updating things');
            update customAttributes;
            update acct;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Changes are succesfully saved!'));
        } catch (System.DmlException ex) {
            if (ex.getDmlType(0) != StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION ){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'An unexpected error occured, please contact your Administrator: '+ex.getMessage()));
            }
        }
    }    
}