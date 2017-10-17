/**
 * Factory to create DFP request
 */
public with sharing class FactoryDARTRequest {
	
	private static FactoryDARTRequest instance;
	
	private FactoryDARTRequest(){}
	
	public static FactoryDARTRequest getInstance()
	{
		if(instance==null)
		{
			instance = new FactoryDARTRequest();
		}
		
		return instance;
	}
	
	/** 
	 * Company/Advertiser Request
	 * @param AdserverLogin
	 * @param OpportunityLineItem
	 * @param Account
	 * @return IGenericRequest
	 */
	public HTTPWrapper.IGenericRequest createDARTSubmitAdvertiserRequest(AdServer_Login__c credential, OpportunityLineItem item, Account acc)
	{
		if(DARTUtil.DART6.equals(credential.RecordType.Name))// new version
		{ 
			return new DART6Message.DFPCompanyRequest(acc, item);
		} 
		 
		return null;
	}
	
	
	/**
	 * Oreder Request
	 * @param AdserverLogin
	 * @param Opportunity
	 * @param OpportunityLineItem
	 * @param mapDartUser
	 * @param mapAdvertiser
	 * @return IGenericRequest
	 */
	public HTTPWrapper.IGenericRequest createDARTSubmitOrderRequest(AdServer_Login__c credential, Opportunity opp, OpportunityLineItem item, Map<String, DARTObject.DARTPerson> mapDartUser,  Map<String, Advertiser__c> mapAdvertiser)
	{
		if(DARTUtil.DART6.equals(credential.RecordType.Name))// new version
		{ 
			return new DART6Message.DFPOrderRequest(opp, item, mapDartUser, mapAdvertiser);
		} 
		 
		return null;
	}
	
	/**
	 * Ads/LineItem Request
	 * @param AdserverLogin
	 * @param OpportunityLineItem
	 * @param dartOrder
	 * @return IGenericRequest
	 */
	public HTTPWrapper.IGenericRequest createDARTSubmitAdsRequest(AdServer_Login__c credential, OpportunityLineItem item, DARTObject.IDARTObjectOrder dartOrder)
	{  
		if(DARTUtil.DART6.equals(credential.RecordType.Name))// new version
		{ 
			return new DART6Message.DFPAdsRequest(item, dartOrder);
		}
		
		return null;     
		
		//return new DARTMessage.DARTSubmitAdsRequest(listDartAds);
	}
	
	/**
	 * Salesperson/DartUser Request
	 * @param userRoleId
	 * @param AdserverLogin
	 * @param OpportunityLineItem
	 * @param Opportunity
	 * @return DART6Message.DFPSalespersonRequest
	 */
	public HTTPWrapper.IGenericRequest createDartSubmitSalePersonRequest(String userRoleId, AdServer_Login__c credential, OpportunityLineItem item, Opportunity opp)
	{
		
		if(DARTUtil.DART6.equals(credential.RecordType.Name))// new version
		{ 
			return new DART6Message.DFPSalespersonRequest(item, opp);
		}
		   
		return null; 
		
		//return new DARTMessage.DARTSalePersonListRequest();
	}
	
	/**
	 * Forecast Request
	 * @param AdserverLogin
	 * @param OpportunityLineItem
	 * @return DART6Message.DFPForecastRequest
	 */
	
	public HTTPWrapper.IGenericRequest createDartForecastRequest(AdServer_Login__c credential,OpportunityLineItem item)
	{
		
		if(DARTUtil.DART6.equals(credential.RecordType.Name))
		{
			return new DART6Message.DFPForecastRequest(item); 
		} 
		
		return null;
	}
	
	/** 
	 * Request to get Advertiser(DFP)
	 * @param AdserverLogin
	 * @param OpportunityLineItem
	 * @param Account
	 * @return DART6Message.DFPGetAdvertiserRequest
	 */
	
	public HTTPWrapper.IGenericRequest createDartGetAdvertiserRequest(AdServer_Login__c credential, OpportunityLineItem item, Account acc)
	{
		if(DARTUtil.DART6.equals(credential.RecordType.Name))
		{
			return new DART6Message.DFPGetAdvertiserRequest(item, acc);
		}
		return null;
	}
	
	/**
	 * Delivery Request
	 * @param AdserverLogin
	 * @param breakDown
	 * @param jobId
	 * @param Dfp reportService 
	 * @return DART6Message.DeliveryRequest
	 */
	public HTTPWrapper.IGenericRequest createDartDeliveryRequest(AdServer_Login__c credential,String breakDown,String dateRange,
				Long jobid, DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService)
	{
		if(DARTUtil.DART6.equals(credential.RecordType.Name))
		{
			return new DART6Message.DeliveryRequest(credential, jobid, reportService); 
		} 
		
		return null;
	}
	
	/**
	 * Get order request 
	 * @param AdserverLogin
	 * @param Opportunity
	 * @param OpportunityLineItem
	 * @return DART6Message.DFPGetOrderRequest
	 */
	public HTTPWrapper.IGenericRequest createGetOrderRequest(AdServer_Login__c credential, Opportunity opp, OpportunityLineItem item)
	{
		if(DARTUtil.DART6.equals(credential.RecordType.Name))
		{
			return new DART6Message.DFPGetOrderRequest(opp, item);
		}
		return null;
	}
	
	/**
	 * Get order request
	 * @param AdserverLogin
	 * @param OpportunityLineItem
	 * @param dartOrder
	 * @return DART6Message.DFPGetLineItemRequest
	 */
	public HTTPWrapper.IGenericRequest createGetLineItemRequest(AdServer_Login__c credential, OpportunityLineItem item, DARTObject.IDARTObjectOrder dartOrder)
	{
		if(DARTUtil.DART6.equals(credential.RecordType.Name))
		{
			return new DART6Message.DFPGetLineItemRequest(item, dartOrder);
		}
		return null;
	}
	
	/**
	 */
	 public HTTPWrapper.IGenericRequest createGetLineItemRequestByAdIds(AdServer_Login__c credential, OpportunityLineItem item){
	 	if(DARTUtil.DART6.equals(credential.RecordType.Name)){
			return new DART6Message.DFPGetLineItemRequestById(item);
		}
		return null;
	 	
	 }
	 
	 /**
	 * AdxReport Request
	 * @param AdserverLogin
	 * @param breakDown
	 * @param jobId
	 * @param Dfp reportService 
	 * @return DART6Message.DeliveryRequest
	 */
	public HTTPWrapper.IGenericRequest createAdxReportRequest(AdServer_Login__c credential,String breakDown,String dateRange,
				Long jobid, DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService)
	{
			return null;//new DART6Message.DeliveryRequest(credential, jobid, reportService); 
	}
			
}