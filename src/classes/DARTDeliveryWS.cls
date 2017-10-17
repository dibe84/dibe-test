/**
 * This webservice call from button in homepage component
 * Import Delivery report
 */
global with sharing class DARTDeliveryWS {


	/** Import Opportunity Product (yesterday/today)*/
	webservice static String processImportDelivery()
	{
		String result = doImport(DeliveryController.SCH_TYPE_MANUALLY, DeliveryController.SOBJECT_OPPPRODUCT);
		return result;
	}
	
	/** Import Metric (yesterday/today) */
	webservice static String processImportDeliveryRS_Daily()
	{
		String result = doImport(DeliveryController.SCH_TYPE_MANUALLY, DeliveryController.SOBJECT_METRIC);
		return result;
	}
	
	/** Import Metric ( all impressions & clicks for current and previous month) */
	webservice static String processImportDeliveryRS_All()
	{
		String result = doImport(DeliveryController.SCH_TYPE_ALL, DeliveryController.SOBJECT_METRIC);
		return result;
	}
	
	/** Import Revenue Item (Month to Date) */
	webservice static String processImportDeliveryRS_Monthly()
	{
		String result = doImport(DeliveryController.SCH_TYPE_MANUALLY, DeliveryController.SOBJECT_REVENUE_ITEM);
		return result;
	}
	
	/** Import Adx to Metric Object */
	webservice static String processImportAdxMetric()
	{
		String result = doImport(DeliveryController.SCH_TYPE_MANUALLY, DeliveryController.SOBJECT_METRIC, DeliveryController.ADX_IMPORT);
		return result;
	}
	
	/** Import Adx Metric ( all impressions & clicks for current and previous month) */
	webservice static String processAdxImportMetrics_All()
	{
		String result = doImport(DeliveryController.SCH_TYPE_ALL, DeliveryController.SOBJECT_METRIC, DeliveryController.ADX_IMPORT);
		return result;
	}
	
	private static String doImport(String schType,String sobjType)
	{		
		return doImport(schType, sobjType, '');
	}
	
	private static String doImport(String schType,String sobjType, String importType)
	{
		String result='';
		String strImp = (DeliveryController.ADX_IMPORT.equals(importType)?'Adx':'Delivery');
		try
		{ 
			
			Integer numPending = [Select count() from DART_Delivery_Support__c 
				WHERE Schedule_Type__c=:schType 
				AND Sobject__c=:sobjType
				AND Status__c <> :DeliveryController.DART_STATUS_FINISHED];
			
			//We expected all DDS are 'finished'; so we can run another, or wait until they all finish
			if(numPending>0)
			{	  
				return 'Importing '+strImp+' of '+sobjType+' is already running.';
			}
			DeliveryController.start(schType, sobjType, importType);
			
			result = 'SUCCESS: Importing '+strImp+' of '+sobjType+' is now running in background.';
			
		}catch(Exception ex){result+='ERROR: '+ex;}
		
		return result;
	}
	
	// Test methode
	static testMethod void testWS()
	{
		TestDataGenerator dataGen = new TestDataGenerator();
		dataGen.createCredential();
		
		
		Test.startTest();
		String result = processImportDelivery();
		System.assertEquals(result,'SUCCESS: Importing Delivery of Opportunity Product is now running in background.');
		
		processImportDeliveryRS_Daily();
		processImportDeliveryRS_All();
		processImportDeliveryRS_Monthly();
		
		//Adx for Adx
		processImportAdxMetric();
		processAdxImportMetrics_All();
		
		Test.stopTest();
	}
	
}