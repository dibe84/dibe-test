@isTest
public class TST_MapInsight extends TSTDF_Base {
    
    public TST_MapInsight(TSTDF_Dataset dataset) {
		super(dataset);
    }
	
    public static TST_MapInsight factory = new TST_MapInsight(new TSTDF_Dataset());
    
    public class TSTDF_Dataset extends TSTDF_BaseDataSet {
        public override List<Webservice_Settings__c> constructWebserviceSettings(List<Webservice_Settings__c> wss){
            wss = new List<Webservice_Settings__c>();
        	wss.add(new Webservice_Settings__c(Name='GOOGLE_FUSIONTABLE',Description__c='Google FusionTable Account (koen\'s private)',Endpoint__c='https://www.googleapis.com/fusiontables/v2/query',EndpointProxy__c=null,Key__c='AIzaSyCNVtfRlxschYtohEJskD2ONg-PwsniAc0',UseProxy__c=false,User__c=null));
        	wss.add(new Webservice_Settings__c(Name='GOOGLE_GEOLOCATION',Description__c='Google Geolocation Service',Endpoint__c='https://maps.googleapis.com/maps/api/geocode/json',EndpointProxy__c=null,Key__c='AIzaSyBQJvorfozIzySxMkwr_pDEdjbeLHLHw_U',UseProxy__c=false,User__c=null));
    		return wss;
        }        
    }
    
    public override void queryAdditionalResults() {}
    
	@testSetup static void setup() { 
        UTIL.isRunningTestSetup = true;
        factory.createTestSet();
        UTIL.isRunningTestSetup = false;
                
        MapInsight_Configuration__c config = new MapInsight_Configuration__c();
        config.Name = 'TABLE_ID';
        config.Value__c = '1XtOOt1kuBPIwEyQOZhTtYFwqQczTgxkakxKkz-Jy';
        insert config;
    }
    
    @isTest static void testController() {
        factory.queryResults();
        Test.startTest();
        factory.data.accounts[0].BillingLongitude 	 = 4.8147419;
        factory.data.accounts[0].BillingLatitude 	 = 52.4381545;
        factory.data.accounts[0].BillingMunicipality__c	 = 'Amsterdam';
        factory.data.accounts[0].BillingCountry__c	 = 'Netherlands';
        factory.data.accounts[0].BillingProvince__c 	 = 'Noord Holland';
        
        factory.data.accounts[0].ShippingLongitude 	 = 4.8147419;
        factory.data.accounts[0].ShippingLatitude 	 = 52.4381545;
        factory.data.accounts[0].ShippingMunicipality__c	 = 'Amsterdam';
        factory.data.accounts[0].ShippingCountry__c	 = 'Netherlands';
        factory.data.accounts[0].ShippingProvince__c 	 = 'Noord Holland';
        factory.data.accounts[0].Account_Status__c = 'Active';
        
        update factory.data.accounts[0];
        
        Map<String,List<sObject>> customSettings = MapInsight_Controller.createCustomSettings();
        Map<String,List<MapInsight_Controller.IMapInsightSetting>> settings = MapInsight_Controller.getSettings();
        
        Id objectSettingId = customSettings.get('object').get(0).Id;
        List<Id> recordFilterSettingIds = new List<Id>(); 
        List<Id> metricSettingIds = new List<Id>(); 
        List<String> selectedCountries = new List<String>();
        String selectedGrouping = 'Municipality';

        for (sObject obj : (List<sObject>) customSettings.get('record')) {
            recordFilterSettingIds.add(obj.Id);
            break;
        }
        
        for (sObject obj : (List<sObject>) customSettings.get('metric')) {
            metricSettingIds.add(obj.Id);
        }
        
        selectedCountries.add('Belgium');
        selectedCountries.add('Netherlands');
               
        MapInsight_Controller.MapInsightData data = MapInsight_Controller.getData(objectSettingId, recordFilterSettingIds, metricSettingIds, selectedCountries, selectedGrouping, null, null, null);
        
        recordFilterSettingIds.clear();
        for (sObject obj : (List<sObject>) customSettings.get('record')) {
            if (((String)obj.get('FilterQuery__c') != '') && ((String)obj.get('FilterQuery__c') != null)) {
                recordFilterSettingIds.add(obj.Id);
                break;
            }
        }
        
        MapInsight_Controller.MapInsightData dataWithAlternativeFilter = MapInsight_Controller.getData(objectSettingId, recordFilterSettingIds, metricSettingIds, selectedCountries, selectedGrouping, null, null, null);

        MapInsight_Controller ctrl = new MapInsight_Controller();
        Test.stopTest(); 
    }
    
    @isTest static void testAccountQueueables() {
        factory.queryResults();
		Test.startTest();
        factory.data.accounts[0].BillingStreet       = 'Wibautstraat 224';
        factory.data.accounts[0].BillingPostalCode   = '1097DN';
        factory.data.accounts[0].BillingCity         = 'Amsterdam';
        factory.data.accounts[0].BillingCountry		= 'Netherlands';
        factory.data.accounts[0].BillingCountryCode  = 'NL';
        factory.data.accounts[0].BillingLongitude 	 = 4.8147419;
        factory.data.accounts[0].BillingLatitude 	 = 52.4381545;
        
        factory.data.accounts[0].ShippingStreet       = 'Wibautstraat 224';
        factory.data.accounts[0].ShippingPostalCode   = '1097DN';
        factory.data.accounts[0].ShippingCity         = 'Amsterdam';
        factory.data.accounts[0].ShippingCountry		= 'Netherlands';
        factory.data.accounts[0].ShippingCountryCode  = 'NL';
        factory.data.accounts[0].ShippingLongitude 	 = 4.8147419;
        factory.data.accounts[0].ShippingLatitude 	 = 52.4381545;
        
        update factory.data.accounts[0];
        
       
        System.runAs (factory.data.testUsers.get('adminUser')) { 
			UTIL_CustomJob.createMissingCustomJobs();
            UTIL_CustomJob.startAllCustomJobs();
        }
        Test.stopTest(); 
    }
    
    @isTest static void testAccountController() {
        factory.queryResults();
        Test.startTest();
        factory.data.accounts[0].BillingLongitude 	 = 4.8147419;
        factory.data.accounts[0].BillingLatitude 	 = 52.4381545;
        factory.data.accounts[0].BillingMunicipality__c	 = 'Amsterdam';
        factory.data.accounts[0].BillingCountry__c	 = 'Netherlands';
        factory.data.accounts[0].BillingProvince__c 	 = 'Noord Holland';
        
        factory.data.accounts[0].ShippingLongitude 	 = 4.8147419;
        factory.data.accounts[0].ShippingLatitude 	 = 52.4381545;
        factory.data.accounts[0].ShippingMunicipality__c	 = 'Amsterdam';
        factory.data.accounts[0].ShippingCountry__c	 = 'Netherlands';
        factory.data.accounts[0].ShippingProvince__c 	 = 'Noord Holland';
        factory.data.accounts[0].Account_Status__c = 'Active';
        
        update factory.data.accounts[0];
        
        Map<String,List<sObject>> customSettings = MapInsight_Controller.createCustomSettings();
        Map<String,List<MapInsight_Controller.IMapInsightSetting>> settings = MapInsight_Controller.getSettings();
        
        Test.setCurrentPage(Page.MapInsightAccount);
        ApexPages.StandardController sc = new ApexPages.StandardController(factory.data.accounts[0]);
        
        MapInsight_AccountController accountController = new MapInsight_AccountController(sc);
                
        Test.stopTest(); 
    }
}