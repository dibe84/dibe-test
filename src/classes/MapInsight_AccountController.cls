public class MapInsight_AccountController {
    
    public Map<String,Location> presetLocations { get; set; }
    public Id presetObjectSetting { get; set; }
    public Id presetRecordSetting { get; set; }
    public List<Id> presetMetricSetting { get; set; }
    public List<String> presetCountrySetting { get; set; }
    public String presetRegionSetting { get; set; }
    
    private final Account acc;
    
    public MapInsight_AccountController(ApexPages.StandardController controller) {
        if (!Test.isRunningTest()) {
        	controller.addFields(new List<String>{'BillingLatitude', 'BillingLongitude', 'ShippingLatitude', 'ShippingLongitude'});
        }
        this.acc = (Account) controller.getRecord();
        this.presetLocations = new Map<String,Location>();
        if (this.acc.BillingLatitude != null && this.acc.BillingLongitude != null) {
            Location billingLocation = Location.newInstance(this.acc.BillingLatitude, this.acc.BillingLongitude);
            this.presetLocations.put('Billing Address', billingLocation);
        }
        if (this.acc.ShippingLatitude != null && this.acc.ShippingLongitude != null) {
            Location shippingLocation = Location.newInstance(this.acc.ShippingLatitude, this.acc.ShippingLongitude);
            this.presetLocations.put('Shipping Address', shippingLocation);
        }
        
		List<MapInsight_AccountComponentConfiguration__c> configurations = [SELECT Id, Name, Default__c, ObjectSetting__c, RecordFilterSetting__c, MetricSetting__c, CountrySetting__c, RegionSetting__c, AccountCondition__c, UserCondition__c FROM MapInsight_AccountComponentConfiguration__c ORDER BY AccountCondition__c ASC, UserCondition__c ASC];
        MapInsight_AccountComponentConfiguration__c foundConfiguration = null;
        
        // Find default configuration
        for (MapInsight_AccountComponentConfiguration__c config : configurations) {
            if (config.Default__c) {
                foundConfiguration = config;
            }
        }
                
        // Run through *ALL* configurations, execute the two painful queries, if we find a match then break and assume this is it..
        for (MapInsight_AccountComponentConfiguration__c config : configurations) {
            if (config.Default__c == false) {
                Boolean match = true;
                if (config.AccountCondition__c != null) {
                    Id accountId = this.acc.Id;
                    List<Account> accounts = Database.query('SELECT Id FROM Account WHERE Id = :accountId AND (' + config.AccountCondition__c + ') LIMIT 1');
                    if (accounts == null || accounts.size() == 0) {
                        match = false;
                    }
                }
                if (config.UserCondition__c != null && match) {
                    Id userId = UserInfo.getUserId();
                    List<User> users = Database.query('SELECT Id FROM User WHERE Id = :userId AND (' + config.UserCondition__c + ') LIMIT 1');
                    if (users == null || users.size() == 0) {
                        match = false;
                    }
                }
                if (match) {
                    foundConfiguration = config;
                    break;
                }
            }
        }
                                                                                   
        if (foundConfiguration != null) {
            this.presetObjectSetting = foundConfiguration.ObjectSetting__c;
            this.presetRecordSetting  = foundConfiguration.RecordFilterSetting__c;
            List<String> metricSetting = foundConfiguration.MetricSetting__c.split('\\|');
            List<Id> metricSettingIds = new List<Id>();
            for (String s : metricSetting) {
                metricSettingIds.add(Id.valueOf(s));
            }
            
            this.presetMetricSetting  = metricSettingIds;
            List<String> countrySetting = foundConfiguration.CountrySetting__c.split('\\|');
            this.presetCountrySetting  = countrySetting;
            this.presetRegionSetting   = foundConfiguration.RegionSetting__c;
        }
        
        System.debug(LoggingLevel.ERROR, 'Preset locations: ' + this.presetLocations);
    }    
}