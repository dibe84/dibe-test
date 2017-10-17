/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: 
 *	- Opportunity Details as Header
 * @references: 
 *	- LPC_PageHeader lightning component
 * @changeLog:
 *
 */
public without sharing class LPC_PageHeaderController {
	
	/**
     * Clear streaming api records that already push notify from storage
     */
    @AuraEnabled
    public static String deleteStreamingApiRecord(){
        try{
          	List<Streaming_Api_Support__c>lstExistRecords = [Select Id From Streaming_Api_Support__c];
          	if(!lstExistRecords.isEmpty()) delete lstExistRecords;
        	return 'Success';  
        }
        catch(Exception e){
            return null;
        }
        
    }   
	
	/**
     * Get EntitySubscription on Opportunity
     * @param oppId, Opportunity Id
     * @return EntitySubscription
     */
    @AuraEnabled
    public static EntitySubscription getEs(String oppId ){
        try{
          	EntitySubscription  es =[select Id from EntitySubscription where ParentId =: oppId];
        	return es;  
        }
        catch(Exception e){
            return null;
        }
        
    }

    @AuraEnabled
    public static List<String> getCurrency(){
        List<String> curOptions = new List<String>();
        Schema.DescribeFieldResult fieldResult = Opportunity.CurrencyIsoCode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f:ple){
            curOptions.add(f.getValue());
        }
        return curOptions;
    }

    @AuraEnabled
    public static String getDefaultCurrency(String accId){
        system.debug('accId' + accId);
        return [select Member__r.DefaultMemberUnit__r.CurrencyText__c from account where id =:accId].Member__r.DefaultMemberUnit__r.currencyText__c;
    }

    @AuraEnabled
    public static String createOpp2(String opp, String accId){

        Opportunity objOpp;

    	try{
	        objOpp = (Opportunity) JSON.deserialize(opp, Opportunity.class);
	        objOpp.AccountId = accId;

            insert objOpp;
            
            return objOpp.Id;
      
        }catch(system.DMLException ex){
        	
            if (StatusCode.UNABLE_TO_LOCK_ROW==ex.getDmlType(0)){
                return 'Warning: UNABLE_TO_LOCK_ROW';
            }  
        }catch(Exception e){
            return 'Error:'+ e.getStackTraceString() + 'error msg : ' + e.getMessage();
        }
      
        return 'success';//String.valueOf(opportunity.Id);
    }

    @AuraEnabled
    public static RemoteResponse checkAgencyForOppCreation( String agencyAccId ){

        RemoteResponse response = new RemoteResponse();
        response.statusCode = RemoteResponse.STATUSCODE_OK;

    	try{
	        // Checks if the Agency Account exists in TRACT. If not, it is then created.
	        Account agencyAcc = GW_Account.getRecord( agencyAccId );
	        if( agencyAcc.Tract_AccountId__c == null ){
	
		        UTIL_WSC.WSC_Request req;
		        UTIL_WSC.WSC_Result res;
		        
		        req = UTIL_WSC.getWSC_Request('WSC_Tract.BillingAccountCreate');
		        req.init( agencyAcc.Id );
		        res = req.call();
		        
		        if ( res.statusCode != 200 && res.statusCode != 201 ) {
		        	response.statusCode = RemoteResponse.STATUSCODE_ERROR;
	    		    response.message = 'Callout error while creating the agency TRACT Account. Status code: ' + res.statusCode;
		        }
	        }
    	} catch( Exception ex ){
    		response.statusCode = RemoteResponse.STATUSCODE_ERROR;
    		response.message = 'Could not process Agency TRACT Account. Error: ' + ex.getMessage(); 
    	}           

        return response;
    }

    @AuraEnabled
    public static RemoteResponse retrieveOppGhostAccount( String accountId , String agencyAccId ){

        RemoteResponse response = new RemoteResponse();
        response.statusCode = RemoteResponse.STATUSCODE_OK;

    	try{
	        Account account = (Account) UTIL.getCached( accountId );
	        Account agencyAcc = (Account) UTIL.getCached( agencyAccId );
    		
	        UTIL_WSC.WSC_Request req;
	        UTIL_WSC.WSC_Result res;
	        
	        req = UTIL_WSC.getWSC_Request('WSC_Tract.GetBillingAccount');
	        req.mAdditionalParams = new Map<String,Object>{ 'external_account_num' => agencyAcc.Id + '_' + account.Id };
	        req.init( accountId );
	        res = req.call();
	        
	        if (res.statusCode == 200 || res.statusCode == 201) {
	        	List<Object> results = (List<Object>) res.getResponseData().get('results');
	        	if( results != null && results.size() > 0 ){
	        		Map<String, Object> result = ( Map<String, Object> ) results[0];
	        		response.contents = new List<String>{ (String) result.get('id') , (String) result.get('account_num') };
	        	}
	        }else {
	        	response.statusCode = RemoteResponse.STATUSCODE_ERROR;
    		    response.message = 'Callout error while querying the TRACT Ghost Account. Status code: ' + res.statusCode;
	        }

    	} catch( Exception ex ){
    		response.statusCode = RemoteResponse.STATUSCODE_ERROR;
    		response.message = 'Could not retrieve the TRACT Ghost Account. Error: ' + ex.getMessage(); 
    	}
    	
    	return response;        
    }

    @AuraEnabled
    public static RemoteResponse createOppGhostAccount( String accountId , String agencyAccId ){

        RemoteResponse response = new RemoteResponse();
        response.statusCode = RemoteResponse.STATUSCODE_OK;

    	try{
	        UTIL_WSC.WSC_Request req;
	        UTIL_WSC.WSC_Result res;
	        
	        req = UTIL_WSC.getWSC_Request('WSC_Tract.GhostBillingAccountCreate');
	        req.mAdditionalParams = new Map<String,Object>{ 'agencyAccId' => agencyAccId };
	        req.init( accountId );
	        res = req.call();
	        if (res.statusCode == 200 || res.statusCode == 201) {
	        	Map<String, Object> resultMap = (Map<String, Object>) res.getResponseData().get('results');
	        	response.contents = new List<String>{ (String) resultMap.get('id') , (String) resultMap.get('account_num') };	        	
	        }else {
	        	response.statusCode = RemoteResponse.STATUSCODE_ERROR;
    		    response.message = 'Callout error while creating the TRACT Ghost Account. Status code: ' + res.statusCode;
	        }
    	
    	} catch( Exception ex ){
    		response.statusCode = RemoteResponse.STATUSCODE_ERROR;
    		response.message = 'Could not create the TRACT Ghost Account. Error: ' + ex.getMessage(); 
    	}        
    	
    	return response;
    }

    @AuraEnabled
    public static List<String> getLeadSource(){
        List<String> ldSrcOptions = new List<String>();
        Schema.DescribeFieldResult fieldResult = Opportunity.LeadSource.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f:ple){
            ldSrcOptions.add(f.getLabel());
        }
		ldSrcOptions.sort();
        return ldSrcOptions;
    }

    @AuraEnabled
    public static List<String> getStageNameList(){
        List<String> stNameOptions = new List<String>();
        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f:ple){
            stNameOptions.add(f.getLabel());
        }
        return stNameOptions;
    }

    @AuraEnabled
    public static List<String> getProductLineValues(){
        List<String> stNameOptions = new List<String>();
        Schema.DescribeFieldResult fieldResult = Opportunity.SAPProductLine__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f:ple){
            stNameOptions.add(f.getLabel());
        }
        
        return stNameOptions;
    }

    @AuraEnabled
    public static List<sObject> getAccDet2(String accId){
    	set<Id> stIds = new set<Id>{accId};
        return GW_sObject.queryRecords('Account', stIds);
    }
    
    /**
     * Follower on Opportunity
     * @param oppId, Opportunity Id
     * @return EntitySubscription
     */
	@AuraEnabled
    public static RemoteResponse followOpp(String oppId){
        try{   
            Id aid = [Select Id from Opportunity where id =: oppId limit 1].id;
            EntitySubscription es = new EntitySubscription();
            es.ParentId = aid;
            es.SubscriberId = Userinfo.getUserId();
            insert es;
            return new RemoteResponse(es);
        }
        catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
    
    /**
     * Update Opportunity Detail
     */
    @AuraEnabled
    public static RemoteResponse updateOpportunityDetail(String oppId, Opportunity opp){
        try{   
            opp.Id = oppId;
            update opp;
            List<String> additionalFields = new List<String>{'Campaign.Name', 'Primary_Contact__r.Name', 'Account.Name','Agency__r.Name','Billing_Account__r.Name','Owner.Name','MemberUnit__r.Name'};
	        opp = GW_Opportunity.getRecord(oppId, additionalFields);
            return new RemoteResponse(opp);
        }
        catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

    /**
     * Create Opportunity
     * @param accId,Account Id
     * @return Opportunity
     */
//    @AuraEnabled
//    public static RemoteResponse createOpportunity(String accId) {
//        try {
//           return new RemoteResponse(new Opportunity());
//        } catch (Exception e) {
//            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
//        }
//
//    }
    /**
     * Leave Opportunity
     * @param oppId, Opportunity Id
     * @return EntitySubscription
     */
    @AuraEnabled
    public static RemoteResponse unFollowOpp(String oppId){
        try{
            Id aid = [Select Id from Opportunity where id =: oppId limit 1].id;
            EntitySubscription deleteObj = [select Id from EntitySubscription where ParentId =: aid];
            delete deleteObj;
            return new RemoteResponse(deleteObj);
        }
        catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
    /**
     * update Opportunity primary contact
     * @param oppId, primary contact id
     * 09/05/2017 GIS-TEAM
     * Task #11287
     */
    @AuraEnabled
    public static void updatePrimaryContact(String oppId, String primaryContactId){
        Opportunity opp = new Opportunity(Id = oppId);
        opp.Primary_Contact__c = primaryContactId;
        update opp;
    }
	
	@AuraEnabled
    public static List<String> getLostReasonValues(){
        List<String> stNameOptions = new List<String>();
        Schema.DescribeFieldResult fieldResult = Opportunity.LostReason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f:ple){
            stNameOptions.add(f.getLabel());
        }
        
        return stNameOptions;
    }
	
	/**
     * to pre populate opportunity primary contact
     * @param accId, Account Id
     * @return RemoteResponse.content is the list of contact
     */
    @AuraEnabled
    public static RemoteResponse getPrimaryContact(String accId){
        try{
            List<Contact> lsc = GW_sObject.queryRecords('Contact', 'AccountId IN: idSet1 And isActive__c = TRUE And Primary__c = TRUE Order By CreatedDate ASC', new Map<String, Set<id>>{'idSet1' => new set<id>{accId}});
            RemoteResponse res = new RemoteResponse();
            res.content = lsc;
            return res;
        }
        catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    		}
    }
}