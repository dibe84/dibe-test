public with sharing class PGC_DeactivateServicesController {
	public TRACT_Service__c tractService {get;set;}
	public Boolean isRefreshed {get;set;}
	
	public PGC_DeactivateServicesController() {
		tractService = new TRACT_Service__c();
		isRefreshed = false;
	}
	
   public PageReference deactivateServices() {
   		try {
	   		String tserviceIdsStr = ApexPages.currentPage().getParameters().get('Ids');
	   		if ( String.isBlank(tserviceIdsStr) ) return null;
	   		
	   		List<String> tserviceIds = tserviceIdsStr.split(';');
	   		Set<Id> setIds = new Set<Id>();
	   		for (String tserviceId : tserviceIds ) setIds.add(tserviceId);
	   		List<TRACT_Service__c> services2deactivate = GW_TractService.getList(setIds);
	   		
	   		//do deativate service(s)
	   		GW_TractService.deactivateServices(services2deactivate, tractService.End_Date__c, tractService.TerminationReason__c);
	   		isRefreshed = true;
   		} catch (Exception ex) {
   			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, EX+''));
   			return null;
   		}
   		
   		return null;
   }
}