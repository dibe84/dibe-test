/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: 
 *	- Save Load Template on Targeting 
 * @references: 
 *	- LPC_TargetingTabConfigurator lightning component
 * @changeLog:
 *
 */
public without sharing class LPC_TargetingTemplateSelectorController {
	
    /**
     * Init Template in org
     * @param lineItemId, OpportunityLineItem Id
     * @param siteId, Site Id
     * @return List<DART_KeyValue_2__c>
     */
    @AuraEnabled
    public static RemoteResponse initTemplateN(String siteId) {
    	
		try {
            list<Targeting__c> listExistTemplate = [Select t.Id, t.Description__c, (Select Id From Opportunity_Product_Template__r) From Targeting__c t Where t.RecordType.DeveloperName = 'Template' And t.IsDeleted = false And t.Active__c = true And t.site__c = :siteId];
            //Targeting, Template
            Map<String, LPC_KeyValuesSelectorController.KeyWrp> mapListTemplate = new Map<String, LPC_KeyValuesSelectorController.KeyWrp>();
            List<String> tragetUsedNum = new List<String>();
            LPC_KeyValuesSelectorController.KeyWrp[] keyList = new List<LPC_KeyValuesSelectorController.KeyWrp>();
            for(Targeting__c key : listExistTemplate ){
                Integer usedNum = key.Opportunity_Product_Template__r.size();
                tragetUsedNum.add(usedNum+'-'+key.Id);

                LPC_KeyValuesSelectorController.KeyWrp keyOne = new LPC_KeyValuesSelectorController.KeyWrp(key.Id, key.Description__c, key.Description__c);
                mapListTemplate.put(key.Id, keyOne);
            }

            //List Template order by popular based on number associated to OLI
            tragetUsedNum.sort();
            for(Integer i = tragetUsedNum.size()-1; i>=0;i--){
                keyList.add(mapListTemplate.get(tragetUsedNum.get(i).substringAfter('-')));
            }
		 	
		 	
		 	RemoteResponse response = new RemoteResponse();
            response.content = new Map<String, Object>{
            	'templateList' => keyList
            };
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
		} catch(Exception e) {
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
	
	/**
     * Check Template Name Exist
     * @param templatename, Name
     * @param siteId, Site Id
     * @param isCreateNew, id new
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse checkTemplateNameExist(String templatename, String siteId, Boolean isCreateNew, String lineItemId){
            
        try {
            list<Targeting__c> listExistTemplate = [Select t.RecordType.DeveloperName, t.IsDeleted, t.Id, t.Description__c From Targeting__c t Where t.RecordType.DeveloperName = 'Template' And t.IsDeleted = false And t.Description__c = :templatename And t.site__c = :siteId];
            //Targeting, Template
            String targetingId = '';
            Boolean isExist = false;
            if(listExistTemplate.size() > 0){
                isExist = true;
                targetingId = listExistTemplate.get(0).Id;
            }else if(isCreateNew == true){//if it need to create new record
                //create new targeting template
                Id RecId = Schema.SObjectType.Targeting__c.getRecordTypeInfosByName().get('Template').getRecordTypeId();

                Targeting__c tg = new Targeting__c();
                tg.Description__c = templatename;
                tg.RecordTypeId = RecId;
                tg.site__c = siteId;
                insert tg;
                targetingId = tg.Id;
            }
                
            //update targeting template to line item
            if(lineItemId != null && targetingId!=''){
            	OpportunityLineItem oppLine = [Select Name, Targeting__c, Targeting_Template__c From OpportunityLineItem Where Id =: lineItemId];
        
	            oppLine.Targeting_Template__c = targetingId;
	            update oppLine;
            }
            
            RemoteResponse response = new RemoteResponse();
            response.content = new Map<String, Object>{
                'isExist' => isExist,
                'targetingId' => targetingId
            };
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        } catch(Exception e) {
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
    
    /**
     * Check Targeting Not Empty
     * @param lineItemId, OpportunityLineItem Id
     * @return Boolean
     */
    @AuraEnabled
    public static RemoteResponse checkTargetingNotEmptyData(String lineItemId) {
        try {
            OpportunityLineItem oppLine = [Select Name, Targeting__c, DFP_Time_Wednesday__c, DFP_Time_Tuesday__c, 
                        DFP_Time_Thursday__c, DFP_Time_Sunday__c, DFP_Time_Saturday__c, DFP_Time_Monday__c, 
                        DFP_Time_Friday__c From OpportunityLineItem Where Id =: lineItemId];
            String targetId = oppLine.Targeting__c;
            Boolean isNoEmpty = false;
            Targeting__c abc = new Targeting__c ();
            if(oppLine.DFP_Time_Monday__c != null || oppLine.DFP_Time_Thursday__c != null ||
                oppLine.DFP_Time_Wednesday__c != null || oppLine.DFP_Time_Tuesday__c != null ||
                oppLine.DFP_Time_Friday__c != null || oppLine.DFP_Time_Saturday__c != null || oppLine.DFP_Time_Sunday__c != null ){
                isNoEmpty = true;
            }else{
                if (oppLine.Targeting__c != null) {
                    Targeting__c target = [Select t.Id, t.Description__c, (Select Id From TargetingRegionAssociation__r), 
                        (Select Id From TargetingKeyValueAssociations__r), (Select Id From TargetingGeographyAssociations__r), 
                        (Select Id From TargetingFrequencyAssociations__r), (Select Id From TargetingDeviceAssociations__r), 
                        (Select Id From TargetingContentAssociations__r), (Select Id From TargetingConnectionAssociations__r) 
                        From Targeting__c t 
                        Where t.IsDeleted = false And t.id = :targetId];
                        abc = target;

                    if(target.TargetingKeyValueAssociations__r.size()>0 || 
                        target.TargetingGeographyAssociations__r.size()>0 || 
                        target.TargetingDeviceAssociations__r.size()>0 ||
                        target.TargetingFrequencyAssociations__r.size()>0 ||
                        target.TargetingRegionAssociation__r.size()>0 ||
                        target.TargetingConnectionAssociations__r.size()>0){
                        isNoEmpty = true;
                    }
                }
            }

            RemoteResponse response = new RemoteResponse();
            response.content = new Map<String, Object>{
                'isNoEmpty' => isNoEmpty
            };
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
            
        } catch(Exception e) {
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
        
    }
}