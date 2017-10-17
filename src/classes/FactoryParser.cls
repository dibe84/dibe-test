/**
 * Call to parse DFP object to Apex dartObject
 */

public with sharing class FactoryParser {
	
	private static FactoryParser instance;
	
	private FactoryParser(){}
	
	public static FactoryParser getInstance()
	{
		if(instance==null)
		{
			instance = new FactoryParser();	
		} 
		return instance;
	}	 
	 
	 
	/**
	 * Advertiser Parser 
	 * @param Account
	 * @param Dart Version
	 * @return IDARTParser
	 */ 
	public DART6Parser.IDARTParser createAdvertiserParser(Account acc, String dartVersion)
	{
		if(DARTUtil.DART6.equals(dartVersion))  
		{ 
			return new DART6Parser.DFPResponseToCompanyParser(acc); 
		}
		return null; 
	}
	 
	/** 
	 * Order Parser 
	 * @param AdserverLoing
	 * @param Opportunity
	 * @return IDARTParser
	 */ 
	public DART6Parser.IDARTParser createOrderParser(AdServer_Login__c credential,String dartVersion, Opportunity opp)
	{
		if(DARTUtil.DART6.equals(dartVersion))  
		{ 
			return new DART6Parser.DFPResponseToOrderParser(opp, credential); 
		}
		return null;
	} 
	
	/** 
	 * Person Parser 
	 * @param Dart version
	 * @return IDARTParser
	 */
	public DART6Parser.IDARTParser createSalespersonParser(String dartVersion)
	{
		if(DARTUtil.DART6.equals(dartVersion))
		{
			return new DART6Parser.DFPResponseToSalespersonParser();
		} 
		return null;
	}
	 
	/**
	 * Ads/LineItem Parser
	 * @param AdserverLogin
	 * @param dartVersion
	 * @param OpportunityLineItem
	 * @param mapAdvertiser
	 * @return IDARTParser
	 */
	public DART6Parser.IDARTParser createAdsParser(AdServer_Login__c credential, String dartVersion, OpportunityLineItem item, Map<String, Advertiser__c> mapAdvertiser)
	{
		if(DARTUtil.DART6.equals(dartVersion)) 
		{ 
			return new DART6Parser.DFPResponseToAdsParser(item, credential, mapAdvertiser);
		} 
		return null; 
	} 
	 
	/**
	 * Forecast Parser
	 * @param Dart version
	 * @param OpportunityLineItem
	 * @param IDARTParser 
	 */
	public DART6Parser.IDARTParser createForecastParser(String dartVersion, OpportunityLineItem item)
	{
		if(DARTUtil.DART6.equals(dartVersion))  
		{  
			return new DART6Parser.DFPResponseToForecastParser(item);
		} 
		return null;
	}
	
	/**
	 * Delivery Parser 
	 * @param Dart version
	 * @param Sobject type
	 * @return IDARTParser
	 */
	public DART6Parser.IDARTParser createDeliveryParser(String dartVersion, String sobjType)
	{
		if(DARTUtil.DART6.equals(dartVersion))  
		{  
			return new DART6Parser.Xml6ToDeliveryParser(sobjType);
		} 
		return null;
	}
	
	/**
	 * Get additional fields from DFP parser
	 * @param Dart version
	 * @param OpportunityLineItem
	 * @param IDARTParser
	 */
	 public DART6Parser.IDARTParser createItemAdditionalFiledParser(String dartVersion, OpportunityLineItem item)
	 {
	 	if(DARTUtil.DART6.equals(dartVersion))  
		{  
			return new DART6Parser.DFPResponseAdditionalItemFields(item);
		} 
		return null;
	 }
	 
	 /**
	 * Adx Parser 
	 * @param Dart version
	 * @param Sobject type
	 * @return IDARTParser
	 */
	public DART6Parser.IDARTParser createAdxReportParser(String dartVersion, String sobjType)
	{
		return new DART6Parser.XmlToAdxImportParser(sobjType);
	}
	
}