///////////////////////////////////////////////////////////////////////////
// Class TRACT_Service__c Gateway  --
//
// Used as a central location to manage interactions with the TRACT_Service__c Object
//
// CopyWrith:  Jochem van den Heuvel
// Email:   jochemvandenheuvel@screenfields.nl
//
///////////////////////////////////////////////////////////////////////////
public with sharing class GW_TractService
{
    private static final Schema.sObjectType GW_BASEOBJECT = TRACT_Service__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'TRACT_Service__c';
    private static final String DEFAULTFIELDSET = 'Default'; // default fieldset for this type
    public static final String CUS_FIELD_TERMINATION_REASON = 'Termination Reason';
    
//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static TRACT_Service__c          getRecord(Id id)                    { return (TRACT_Service__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,TRACT_Service__c>  getMap(Set<id> ids)                 { return new Map<id,TRACT_Service__c>( getList(ids) ); }
    public static List<TRACT_Service__c>    getList(Set<id> ids)                { return (List<TRACT_Service__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }
    public static List<TRACT_Service__c>    getList(Set<Id> ids, List<String> additionalFields) { return (List<TRACT_Service__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids, additionalFields); }
    
    public static List<TRACT_Service__c>    getListForUpdate(Set<id> ids)       { return (List<TRACT_Service__c>) GW_sObject.queryRecordsForUpdate(GW_BASEOBJECTNAME, ids, new List<String>()); }
    public static List<TRACT_Service__c>    getListForUpdate(Set<id> ids, List<String> additionalFields) { return (List<TRACT_Service__c>) GW_sObject.queryRecordsForUpdate(GW_BASEOBJECTNAME, ids, additionalFields); }
    public static List<TRACT_Service__c>    getRecordByOliId(Id id)             { return (List<TRACT_Service__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, 'Opportunity_Line_Item_ID__c=\'' + id + '\''); }
    public static List<TRACT_Service__c>    getRecordByExId(String exid)             { return (List<TRACT_Service__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, 'External_Id__c=\'' + exid + '\''); }
    
//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of parents(base object) from a list of child objects
//////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////////////////////////////////////////
//  Test Factory
//////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////
// Custom logic
//////////////////////////////////////////////////////////////////////////////////////////////////////
    
    public static final List<String> STEPS_DEACTIVATE_SERVICE = new List<String> {
        'TractService_CusFieldId',                  //0
        'TractService_CusFieldValId',               //1
        'WSC_API_SFECG_v2.ServiceDeactivationSpoc', //2
        'WSC_Tract.CustomFieldValuePush',           //3
        'WSC_Tract.DeactivateServiceTract',         //4
        'WSC_Tract.DenyOrderItem',                  //5
        'SyncTract_syncTractService',               //6
        'SyncTract_syncTractRevenueSchedule'        //7
    };
    
    public static void cacheServicesDetails(List<TRACT_Service__c> services) {
        Set<Id> oliIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        for (TRACT_Service__c serv : services) {
            if (!UTIL.inCache(serv.Opportunity_Line_Item_ID__c)) oliIds.add(serv.Opportunity_Line_Item_ID__c);
            if (!UTIL.inCache(serv.Opportunity__c)) oppIds.add(serv.Opportunity__c);
            if (!UTIL.inCache(serv.Billing_Account__c)) accIds.add(serv.Billing_Account__c);
        }
        if (!oliIds.isEmpty()) UTIL.cache(GW_OpportunityLineItem.getList(oliIds));
        if (!oppIds.isEmpty()) UTIL.cache(GW_Opportunity.getList(oppIds));
        if (!accIds.isEmpty()) UTIL.cache(GW_Account.getList(accIds));
    }
    
    public static void deactivateServices(List<TRACT_Service__c> services, Map<String,String> tractCusFieldIds, Map<String,String> tractCusFieldValIds, Integer currentStep) {
        BAT_CheckDeactivatedService checkCheckDeactivatedService = new BAT_CheckDeactivatedService(services, tractCusFieldIds, tractCusFieldValIds, currentStep);
        if (!UTIL.isRunningTestSetup) Database.executeBatch(checkCheckDeactivatedService, Test.isRunningTest() ? 200 : 1);
    }
    
    public static void deactivateService(TRACT_Service__c service, String tractCusFieldId, String tractCusFieldValId, Integer currentStep) {
        OpportunityLineItem oli = (OpportunityLineItem) UTIL.getCached(service.Opportunity_Line_Item_ID__c);
        Opportunity opp = (Opportunity) UTIL.getCached(service.Opportunity__c);
        Account acc = (Account) UTIL.getCached(service.Billing_Account__c);
        
        Integer todoStep = verifyStep(service, currentStep);
        if (todoStep == STEPS_DEACTIVATE_SERVICE.size()) return;

        String methodCall = STEPS_DEACTIVATE_SERVICE[todoStep];
        String recordContextId = opp.Id; 
        UTIL_WSC.WSC_Request req; 
        if (!methodCall.contains('SyncTract_')) req = UTIL_WSC.getWSC_Request(methodCall);
        Boolean makeRequestCalled = false;
        
        if (methodCall.contains('ServiceDeactivationSpoc')) {
            req.mAdditionalParams.put('endDate', service.End_Date__c);
            req.mAdditionalParams.put('proName', oli.ProductName__c);
            req.mAdditionalParams.put('uniqueLocalBookingId', oli.UniqueLocalBookingId__c);
            req.mAdditionalParams.put('terminationReason', service.TerminationReason__c);
            makeRequestCalled = true;
        }
        if (methodCall.contains('CustomFieldValuePush')) {
	        req.mAdditionalParams.put('custFieldValId', tractCusFieldValId);
            req.mAdditionalParams.put('customFieldType', 'service');
            req.mAdditionalParams.put('customFieldId', tractCusFieldId);
            req.mAdditionalParams.put('customFieldName', CUS_FIELD_TERMINATION_REASON);
            req.mAdditionalParams.put('customFieldValue', service.TerminationReason__c);
            req.mAdditionalParams.put('objectId', service.External_Id__c);
            req.mAdditionalParams.put('objectType', 'services');
            makeRequestCalled = true;
        }
        if (methodCall.contains('DeactivateServiceTract')) {
            Integer d = service.End_Date__c.day();
			Integer mo = service.End_Date__c.month();
			Integer yr = service.End_Date__c.year();
			DateTime endDate = DateTime.newInstance(yr, mo, d);
            
            req.mAdditionalParams.put('endDate', endDate.format('yyyy-MM-dd\'T\'hh:mm:ss'));
            req.mAdditionalParams.put('agreementId', service.Current_Agreement_Service_Id__c);
            req.mAdditionalParams.put('memberUnit', opp.MemberUnitId__c);
            req.mAdditionalParams.put('localid', oli.UniqueLocalBookingId__c);
            req.mAdditionalParams.put('serviceId', service.External_Id__c);
            makeRequestCalled = true;
        }
        if (methodCall.contains('DenyOrderItem')) {
            req.mAdditionalParams.put('orderItemId', opp.Tract_OrderId__c);
            req.mAdditionalParams.put('serviceId', service.External_Id__c);
            makeRequestCalled = true;
        }
        if (methodCall.contains('syncTractService')) {
            WSC_Tract.syncTractService(opp);
        }
        if (methodCall.contains('syncTractRevenueSchedule')) {
            WSC_Tract.syncTractRevenueSchedule(opp.Id);
        }
        if (makeRequestCalled) {
            req.init(recordContextId); 
            UTIL_WSC.WSC_Result resp = req.call();
        }
    }
    
    private static Integer verifyStep(TRACT_Service__c service, Integer currentStep) {
        Set<String> deactivatedStatuses = new Set<String>{'deactivated'};
        if (deactivatedStatuses.contains(service.Status__c.toLowerCase()) && service.TractDeactivated__c && service.LocalDeactivated__c) {
            return STEPS_DEACTIVATE_SERVICE.size();
        }
        if (!service.TractDeactivated__c && currentStep == 0) return STEPS_DEACTIVATE_SERVICE.size();
        if (!service.TractDeactivated__c && currentStep == 1) return STEPS_DEACTIVATE_SERVICE.size();
        if (!service.LocalDeactivated__c && currentStep == 2) return currentStep;
        if (!service.TractDeactivated__c && currentStep == 3) return currentStep;
        if (!service.TractDeactivated__c && service.Start_Date__c <= System.today() && currentStep == 4) return currentStep;
        if (!service.TractDeactivated__c && service.Start_Date__c > System.today() && currentStep == 5) return currentStep;
        if (service.TractDeactivated__c && currentStep == 6) return currentStep;
        if (service.TractDeactivated__c && currentStep == 7) return currentStep;

        return STEPS_DEACTIVATE_SERVICE.size();
    }
    
    //Invoke from VF-page would start the sync job
    public static void deactivateServices(List<TRACT_Service__c> services, Date enddate, String deactivateReason) {
        Set<Id> svIds = new Set<Id>();
        for (TRACT_Service__c service : services) {
            svIds.add(service.Id);
        }
        services = getList(svIds);
        //update status to deactivate
        List<TRACT_Service__c> toDeactivateServices = new List<TRACT_Service__c>();
        for (TRACT_Service__c service : services) {
            if (enddate < service.Start_Date__c || (service.TractDeactivated__c && service.LocalDeactivated__c)) continue;
            service.End_Date__c = enddate;
            service.TerminationReason__c = deactivateReason;
            service.Status__c = enddate <= System.today() ? 'DEACTIVATED' : service.Status__c;
            toDeactivateServices.add(service);
        }
        if (!toDeactivateServices.isEmpty()) {
            update toDeactivateServices;
            GW_TractService.deactivateServices(toDeactivateServices, null, null, 0);
        }
    }
}