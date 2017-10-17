public with sharing class GW_Rule
{
    private static final Schema.sObjectType GW_BASEOBJECT = Rule__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'Rule__c';
    private static final String DEFAULTFIELDSET = 'Default'; // default fieldset for this type

//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Rule__c getRecord(Id id) { return (Rule__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
	public static List<Rule__c> getAll() { return (List<Rule__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ''); }
	public static List<RuleAssociation__c> getAllAssociations() { return (List<RuleAssociation__c>) GW_sObject.queryRecords('RuleAssociation__c', ''); }
}