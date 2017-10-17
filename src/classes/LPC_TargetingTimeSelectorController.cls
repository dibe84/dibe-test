/**
 *	Class do SF database transaction call from lightning components TargetingTimeSelector
 *	@author : CPN
 *	@date : 07/Sep/2016
 *	@description : Task #9389 - CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements 
 * 	@references: 
 *	- LPC_TargetingTimeSelector lightning component
 * 	@changeLog:
 *
 */
public with sharing class LPC_TargetingTimeSelectorController {
    
    /**
     * Availables opportunities line item for selection
     * @param oppLineId, opportunityLineItem Id
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse getTargetingTimeSelector(String oppLineId){
        try{
            List<OpportunityLineItem> lstOpp = [
                                                    Select DFP_Time_Monday__c, 
                                                        DFP_Time_Tuesday__c, 
                                                        DFP_Time_Wednesday__c, 
                                                        DFP_Time_Thursday__c, 
                                                        DFP_Time_Friday__c, 
                                                        DFP_Time_Saturday__c , 
                                                        DFP_Time_Sunday__c
                                                        From OpportunityLineItem Where Id =: oppLineId
                                                ]; 
            RemoteResponse response = new RemoteResponse();
            response.content = lstOpp.size() > 0?lstOpp.get(0):null;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
    
    /**
     * Availables update opportunity line item record
     * @param oppLineId, opportunity Id
     * @param itemSelector
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse saveTargetingTimeSelector(String oppLineId, String timeSelector){
    	try{
    		Map<String, Object> mpTimeSelector = (Map<String, Object>)JSON.deserializeUntyped(timeSelector);
    		OpportunityLineItem oli = new OpportunityLineItem(id = oppLineId);
    		oli.DFP_Time_Monday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Monday__c'));
    		oli.DFP_Time_Tuesday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Tuesday__c'));
    		oli.DFP_Time_Wednesday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Wednesday__c'));
    		oli.DFP_Time_Thursday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Thursday__c'));
    		oli.DFP_Time_Friday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Friday__c'));
    		oli.DFP_Time_Saturday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Saturday__c'));
    		oli.DFP_Time_Sunday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Sunday__c'));
    		
    		update oli;
    		
	        RemoteResponse response = new RemoteResponse();
            response.content = 'Time selector has been save successfully.';
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
    	}catch(Exception e){
    		return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
    
	/**
     * Availables targeting for selection
     * @param targetId, Targeting__c Id
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse getTargetingTimeSelectorTemplate(String targetId){
        try{
            List<Targeting__c> lstOppTime = [
                                                Select DFP_Time_Monday__c, 
                                                    DFP_Time_Tuesday__c, 
                                                    DFP_Time_Wednesday__c, 
                                                    DFP_Time_Thursday__c, 
                                                    DFP_Time_Friday__c, 
                                                    DFP_Time_Saturday__c , 
                                                    DFP_Time_Sunday__c
                                                    From Targeting__c Where Id =: targetId
                                            ]; 
            RemoteResponse response = new RemoteResponse();
            response.content = lstOppTime.size() > 0?lstOppTime.get(0):null;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
    
    /**
     * Availables update targeting record
     * @param targetId, targeting Id
     * @param timeSelector
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse saveTargetingTimeSelectorTemplate(String targetId, String timeSelector){
        try{
            Map<String, Object> mpTimeSelector = (Map<String, Object>)JSON.deserializeUntyped(timeSelector);
            Targeting__c tar = new Targeting__c(id = targetId);
            tar.DFP_Time_Monday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Monday__c'));
            tar.DFP_Time_Tuesday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Tuesday__c'));
            tar.DFP_Time_Wednesday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Wednesday__c'));
            tar.DFP_Time_Thursday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Thursday__c'));
            tar.DFP_Time_Friday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Friday__c'));
            tar.DFP_Time_Saturday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Saturday__c'));
            tar.DFP_Time_Sunday__c = String.valueOf(mpTimeSelector.get('DFP_Time_Sunday__c'));
            
            update tar;
            
            RemoteResponse response = new RemoteResponse();
            response.content = 'Time selector template has been save successfully.';
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
}