public with sharing class GW_TractInvoice {

	private static final Schema.sObjectType GW_BASEOBJECT = Tract_Invoice__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'Tract_Invoice__c';

    public static Tract_Invoice__c           getRecord(Id id)           { return (Tract_Invoice__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<Id,Tract_Invoice__c>   getMap(Set<Id> ids)        { return new Map<Id,Tract_Invoice__c>( getList(ids) ); }
    public static List<Tract_Invoice__c>     getList(Set<Id> ids)       { return (List<Tract_Invoice__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }

}