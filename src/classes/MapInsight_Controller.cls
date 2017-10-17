global with sharing class MapInsight_Controller {
    
    public class MapInsightException extends Exception {}
        
    public Map<String,String> configuration { get; set; }
    public Map<String,Location> presetLocations { get; set; }
    public Id presetObjectSetting { get; set; }
    public Id presetRecordSetting { get; set; }
    public List<Id> presetMetricSetting { get; set; }
    public List<String> presetCountrySetting { get; set; }
    public String presetRegionSetting { get; set; }
    
    public MapInsight_Controller() {
        configuration = new Map<String,String>();
		List<MapInsight_Configuration__c> configSettings = [SELECT Name, Value__c FROM MapInsight_Configuration__c];
        for (MapInsight_Configuration__c mic : configSettings) {
            configuration.put(mic.Name, mic.Value__c);
        }
        // We require the following configuration variables to be set, otherwise no cigar:
        List<String> requiredSettings = new List<String>{'TABLE_ID'};
        for (String s : requiredSettings) {
            if (configuration.get(s) == null) {
                util.throwError('Missing configuration variable: ' + s);
            }
        }
    }
    
    @RemoteAction
    global static Map<String,List<IMapInsightSetting>> getSettings() {
        Map<String,List<IMapInsightSetting>> result = new Map<String,List<IMapInsightSetting>>();
        // This will retrieve all 4 filter-types and their potential values and provide a path for the dependencies between them
        
        // Object options
        List<MapInsight_Object__c> objectSettings = GW_sObject.queryRecords('MapInsight_Object__c', '');
        UTIL.cache(objectSettings);
        
        List<MapInsightObjectSetting> objectOptions = new List<MapInsightObjectSetting>();
        for (MapInsight_Object__c objectSetting : objectSettings) {
            MapInsightObjectSetting option = new MapInsightObjectSetting(objectSetting.Id);
            if (objectSetting.Default__c) {
                option.isDefault = true;
            }
            objectOptions.add(option);
        }
        result.put('Object', objectOptions);

        // Record filter options
        List<MapInsight_RecordFilter__c> recordFilterSettings = GW_sObject.queryRecords('MapInsight_RecordFilter__c', '');
        UTIL.cache(recordFilterSettings);
        
        List<MapInsightRecordFilterSetting> recordFilterOptions = new List<MapInsightRecordFilterSetting>();
        for (MapInsight_RecordFilter__c recordFilterSetting : recordFilterSettings) {
            MapInsightRecordFilterSetting option = new MapInsightRecordFilterSetting(recordFilterSetting.Id);
            if (recordFilterSetting.Default__c) {
                option.isDefault = true;
            }
            recordFilterOptions.add(option);
        }
        result.put('Record', recordFilterOptions);

        // Metric options
        List<MapInsight_Metric__c> metricSettings = GW_sObject.queryRecords('MapInsight_Metric__c', '');
        UTIL.cache(metricSettings);

        List<MapInsightMetricSetting> metricOptions = new List<MapInsightMetricSetting>();
        for (MapInsight_Metric__c metricSetting : metricSettings) {
            MapInsightMetricSetting option = new MapInsightMetricSetting(metricSetting.Id);
            if (metricSetting.Default__c) {
                option.isDefault = true;
            }
            metricOptions.add(option);
        }
        result.put('Metric', metricOptions);
        
        // Region and country options
        List<MapInsight_RegionMapping__c> regionSettings = GW_sObject.queryRecords('MapInsight_RegionMapping__c', '');
        UTIL.cache(regionSettings);

        Set<String> groupings = new Set<String>();
        Set<String> countries = new Set<String>();
        Map<String,List<String>> groupingValidForCountry = new Map<String,List<String>>();
        
        for (MapInsight_RegionMapping__c regionSetting : regionSettings) {
        	countries.add(regionSetting.Country__c);
            groupings.add(regionSetting.Grouping__c);
            List<String> mapItem = groupingValidForCountry.get(regionSetting.Grouping__c);
            if (mapItem == null) {
                mapItem = new List<String>();
            }
            mapItem.add(regionSetting.Country__c);
            groupingValidForCountry.put(regionSetting.Grouping__c, mapItem);
        }
        
        List<MapInsightGroupingSetting> groupingOptions = new List<MapInsightGroupingSetting>();
        for (String grouping : groupings) {
            groupingOptions.add(new MapInsightGroupingSetting(grouping));
        }
        result.put('Grouping', groupingOptions); 
        
        List<MapInsightCountrySetting> countryOptions = new List<MapInsightCountrySetting>();
        for (String country : countries) {
            countryOptions.add(new MapInsightCountrySetting(country));
        }
        result.put('Country', countryOptions);
        
        // Set dependencies
        for (MapInsightGroupingSetting groupingSetting : (List<MapInsightGroupingSetting>) result.get('Grouping')) {
            groupingSetting.validFor = groupingValidForCountry.get(groupingSetting.filterName);
        }
                      
        return result;
    }
    
	@RemoteAction
    global static MapInsightData getData(Id objectSettingId, List<Id> recordFilterSettingIds, List<Id> metricSettingIds, List<String> selectedCountries, String selectedGrouping, Decimal aroundLatitude, Decimal aroundLongitude, Integer range) {
        Boolean queryObjects = true;
        Boolean queryObjectMetrics = true;
        
        if (metricSettingIds == null) {
            return null;
        }
        
        if (metricSettingIds.size() > 10) {
            throw new MapInsightException('You cannot select more than 10 metrics');
        }
        
        MapInsightData result = new MapInsightData();
        
        MapInsightObjectSetting objectSetting = new MapInsightObjectSetting(objectSettingId);
        
        List<MapInsightRecordFilterSetting> recordFilterSettings = new List<MapInsightRecordFilterSetting>();
        for (Id recordFilterSettingId : recordFilterSettingIds) {
            recordFilterSettings.add(new MapInsightRecordFilterSetting(recordFilterSettingId));
        }
        
        List<MapInsightMetricSetting> metricSettings = new List<MapInsightMetricSetting>();
            if (metricSettingIds != null) {
            for (Id metricSettingId : metricSettingIds) {
                metricSettings.add(new MapInsightMetricSetting(metricSettingId));
            }
        }
                
        // Retrieve the objects we are interested in, this is a combination of the 'Object' from the object setting and one or more recordfilters (used with && for now)
        String whereClause = '';
        List<String> recordFilterStrings = new List<String>();
        for (MapInsightRecordFilterSetting recordFilterSetting : recordFilterSettings) {
            if (recordFilterSetting.concreteObj.FilterQuery__c != null && recordFilterSetting.concreteObj.FilterQuery__c != '') {
                recordFilterStrings.add(recordFilterSetting.concreteObj.FilterQuery__c);                
            }
        }
        recordFilterStrings.add(objectSetting.concreteObj.LatitudeField__c + ' != null');
        recordFilterStrings.add(objectSetting.concreteObj.LongitudeField__c + ' != null');
        recordFilterStrings.add(objectSetting.concreteObj.RegionFieldPrefix__c + 'Country__c != null');
        
        if (aroundLongitude != null && aroundLatitude != null && range != null) {
       		recordFilterStrings.add('DISTANCE(BillingAddress, GEOLOCATION('+aroundLatitude+','+aroundLongitude+'), \'km\') < '+range+'');
        }
        
        if (recordFilterStrings.size() > 0) {
        	whereClause += String.join(recordFilterStrings, ' AND ');
        }
        

        
		String objectCountQuery = 'SELECT COUNT(Id) FROM ' + objectSetting.concreteObj.Object__c;
        if (whereClause != '') {
            objectCountQuery += ' WHERE ' + whereclause;
        }
        AggregateResult objectCountResult = Database.query(objectCountQuery);
        Integer objectCount = (Integer) objectCountResult.get('expr0');
        List<sObject> foundRecords;
        
        if (objectCount > 2500) {
            queryObjectMetrics = false;            
        }
        if (objectCount > 10000) {
            queryObjects = false;
        }
        
        if (queryObjects) {
        	foundRecords = GW_sObject.queryRecords(objectSetting.concreteObj.Object__c, whereClause);
        } else {
            foundRecords = new List<sObject>();
        }
        
        // Now lets create some markers..
        result.markers = new List<MapInsightMarker>();
        for (sObject obj : foundRecords) {
            MapInsightMarker marker = new MapInsightMarker(obj.Id, (String) obj.get('Name'), (Decimal) obj.get(objectSetting.concreteObj.LatitudeField__c), (Decimal) obj.get(objectSetting.concreteObj.LongitudeField__c));
            if (marker.longitude != null && marker.latitude != null) {
            	result.markers.add(marker);
            }
        }
        
        // Determine what type of regions we will be showing
        result.visibleRegionTypes = new List<String>();
        Set<String> validSuffixes = new Set<String>();
        Map<String,String> countryToTargetSuffix = new Map<String,String>();
        
        List<MapInsight_RegionMapping__c> regionMappings = [SELECT Id, Name, Country__c, Grouping__c, Type__c, FieldSuffix__c FROM MapInsight_RegionMapping__c WHERE Country__c IN :selectedCountries AND Grouping__c = :selectedGrouping];
        for (MapInsight_RegionMapping__c regionMapping : regionMappings) {
            if (regionMapping.Type__c.contains('|')) {
                for (String t : regionMapping.Type__c.split('\\|')) {
                    result.visibleRegionTypes.add(t);
                }
            } else {
                result.visibleRegionTypes.add(regionMapping.Type__c);
            }
            validSuffixes.add(regionMapping.FieldSuffix__c);
            countryToTargetSuffix.put(regionMapping.Country__c, regionMapping.FieldSuffix__c);
        }
       
        
        // So now we need to retrieve all metrics on two levels;
        // - The objects we are dealing with
        // - Per region (that we have objects for)
        // Ideally this is done using just 2 queries..
        
        Set<Id> filterIds = new Set<Id>();
        for (sObject obj : foundRecords) {
            filterIds.add(obj.Id);
        }
        
        Map<Id,List<MapInsightMetric>> recordToMetricMap = new Map<Id,List<MapInsightMetric>>();
        Map<String,List<MapInsightMetric>> regionToMetricMap = new Map<String,List<MapInsightMetric>>();
        
        // We always the country region as well, using this we can determine what suffix to ultimately apply... this is kind of a hack, should probably figure out a better solution
        validSuffixes.add('Country__c');
        
        for (MapInsightMetricSetting metricSetting : metricSettings) {
            if (metricSetting.concreteObj.Type__c == 'SOQL') {
            	// Individual
                if (queryObjects) {
                    if (metricSetting.concreteObj.TargetObject__c == metricSetting.concreteObj.FilterObject__c && metricSetting.concreteObj.TargetField__c.contains('COUNT')) {
                        
                    } else {
                        List<AggregateResult> markerQueryResult = Database.query(buildMetricQuery(metricSetting.concreteObj.FilterField__c, 
                                                                                                  metricSetting.concreteObj.FilterObject__c, 
                                                                                                  metricSetting.concreteObj.TargetField__c, 
                                                                                                  metricSetting.concreteObj.TargetFilter__c, 
                                                                                                  metricSetting.concreteObj.TargetObject__c,
                                                                                                  '', 
                                                                                                  null,
                                                                                                  ':filterIds')
                                                                                );
                        
                        for (AggregateResult ar : markerQueryResult) {
                            Id recordId = (Id) ar.get('Id');
                            
                            MapInsightMetric metric = new MapInsightMetric();
                            metric.description = metricSetting.concreteObj.Name;
                            metric.value = forceStringConversion(ar.get('expr0'));   
                            
                            List<MapInsightMetric> mapItem = recordToMetricMap.get(recordId);
                            if (mapItem == null) {
                                mapItem = new List<MapInsightMetric>();
                            }                    
                            mapItem.add(metric);
                            
                            recordToMetricMap.put(recordId, mapItem);
                        }
                    }
                }
                
                System.debug('querying region: ' + metricSetting.concreteObj);
                
                // Regions
                String filterString;
                if (filterIds.size() > 0) {
                    filterString = ':filterIds';
                } else {
                    if (metricSetting.concreteObj.FilterField__c != null) {
                        if (metricSetting.concreteObj.FilterField__c.contains('.')) {
                            throw new MapInsightException('Cannot execute nested metric: "' + metricSetting.concreteObj.Name + '" for this many records');
                        }
                    }
                    filterString = '(SELECT Id FROM ' + objectSetting.concreteObj.Object__c;
                    if (whereClause != '') {
                        filterString += ' WHERE ' + whereClause + ' )';
                    } else {
                        filterString += ')';
                    }
                }
                
                
                List<AggregateResult> regionQueryResult = Database.query(buildMetricQuery(metricSetting.concreteObj.FilterField__c, 
                                                                                          metricSetting.concreteObj.FilterObject__c, 
                                                                                          metricSetting.concreteObj.TargetField__c, 
                                                                                          metricSetting.concreteObj.TargetFilter__c, 
                                                                                          metricSetting.concreteObj.TargetObject__c,
                                                                         				  (metricSetting.concreteObj.FilterField__c == null ? '' :  metricSetting.concreteObj.FilterField__c + '.') + objectSetting.concreteObj.RegionFieldPrefix__c, 
                                                                                          validSuffixes,
                                                                                          filterString)
                                                                        ); 
                
                for (AggregateResult ar : regionQueryResult) {
                    String regionName;
                    String countryName = (String) ar.get(objectSetting.concreteObj.RegionFieldPrefix__c + 'Country__c');
                    for (String s : validSuffixes) {
                        try {
                            regionName = (String) ar.get(objectSetting.concreteObj.RegionFieldPrefix__c + '' + s);
                        } catch (Exception e) {}
                        if (regionName != null && regionName != '') {
                            if (countryToTargetSuffix.get(countryName) == s) {
                                break;
                            }
                        }
                    }
                    
                    MapInsightMetric metric = new MapInsightMetric();
                    metric.description = metricSetting.concreteObj.Name;
                    metric.value = forceStringConversion(ar.get('expr0'));   
                    
                    List<MapInsightMetric> mapItem = regionToMetricMap.get(regionName);
                    if (mapItem == null) {
                        mapItem = new List<MapInsightMetric>();
                    }                    
                    mapItem.add(metric);
                    
                    regionToMetricMap.put(regionName, mapItem);
                }
            } else if (metricSetting.concreteObj.Type__c == 'CustomCode') {
                // Execute custom method logic here..
                Type t = Type.forName('MapInsight_CustomCode.' + metricSetting.concreteObj.CustomMethod__c);
				MapInsight_CustomCode.IMapInsight_CustomCode customCode = (MapInsight_CustomCode.IMapInsight_CustomCode) t.newInstance();
                customCode.setFilterIds(filterIds);
                System.debug(LoggingLevel.ERROR, 'vs: ' + validSuffixes + ' cts ' + countryToTargetSuffix);
                customCode.setRegionDetails(objectSetting.concreteObj.RegionFieldPrefix__c, validSuffixes, countryToTargetSuffix, metricSetting.concreteObj.FilterObject__c);
                MapInsight_CustomCode.MapInsight_CustomCodeResult customCodeResult = customCode.run();
                for (Id recordId : customCodeResult.recordValues.keySet()) {
                    MapInsightMetric metric = new MapInsightMetric();
                    metric.description = customCodeResult.description;
                    metric.value = forceStringConversion(customCodeResult.recordValues.get(recordId));   
                    
                    List<MapInsightMetric> mapItem = recordToMetricMap.get(recordId);
                    if (mapItem == null) {
                        mapItem = new List<MapInsightMetric>();
                    }                    
                    mapItem.add(metric);
                    
                    recordToMetricMap.put(recordId, mapItem);
                }
                
                for (String regionName : customCodeResult.regionValues.keySet()) {
                    MapInsightMetric metric = new MapInsightMetric();
                    metric.description = customCodeResult.description;
                    metric.value = forceStringConversion(customCodeResult.regionValues.get(regionName));   
                    
                    List<MapInsightMetric> mapItem = regionToMetricMap.get(regionName);
                    if (mapItem == null) {
                        mapItem = new List<MapInsightMetric>();
                    }                    
                    mapItem.add(metric);
                    
                    regionToMetricMap.put(regionName, mapItem);
                }
            }
        }
        
        for (MapInsightMarker marker: result.markers) {
            marker.metrics = recordToMetricMap.get(marker.objectId);
        }
        
        result.regions = new List<MapInsightRegion>();
        for (String regionName : regionToMetricMap.keySet()) {
            MapInsightRegion region = new MapInsightRegion();
            region.regionName = regionName;
           	region.metrics = regionToMetricMap.get(regionName);
            result.regions.add(region);
        }     
         
        return result;
    }
    
    /* Setup */
    
    public static Map<String,List<sObject>> createCustomSettings() {
        delete MapInsight_Configuration__c.getall().values();
        delete MapInsight_Object__c.getall().values();
        delete MapInsight_RecordFilter__c.getall().values();
        delete MapInsight_Metric__c.getall().values();
        delete MapInsight_RegionMapping__c.getall().values();
        delete MapInsight_AccountComponentConfiguration__c.getall().values();
        
        List<MapInsight_Configuration__c> configurationCS = new List<MapInsight_Configuration__c>{        
        	new MapInsight_Configuration__c(Name='TABLE_ID', Value__c='1XtOOt1kuBPIwEyQOZhTtYFwqQczTgxkakxKkz-Jy')
        };
        
        List<MapInsight_Object__c> objectCS = new List<MapInsight_Object__c>{        
        	new MapInsight_Object__c(Name='Account by Billing Address', Default__c=true, LatitudeField__c='BillingLatitude',LongitudeField__c='BillingLongitude',Object__c='Account',RegionFieldPrefix__c='Billing'),
            new MapInsight_Object__c(Name='Account by Shipping Address', Default__c=false, LatitudeField__c='ShippingLatitude',LongitudeField__c='ShippingLongitude',Object__c='Account',RegionFieldPrefix__c='Shipping')
        };
            
        List<MapInsight_RecordFilter__c> recordCS = new List<MapInsight_RecordFilter__c>{        
        	new MapInsight_RecordFilter__c(Name='All Accounts', Default__c=true, FilterQuery__c=null,Object__c='Account'),
            new MapInsight_RecordFilter__c(Name='Active Accounts', Default__c=false, FilterQuery__c='Account_Status__c = \'Active\'',Object__c='Account'),
            new MapInsight_RecordFilter__c(Name='Acc with out for signature opps', Default__c=false, FilterQuery__c='Id IN (SELECT AccountId FROM Opportunity WHERE ContractStatus__c = \'Out for Signature\')',Object__c='Account'),
            new MapInsight_RecordFilter__c(Name='Acc with at least 1 Signed Opp', Default__c=false, FilterQuery__c='Id IN (SELECT AccountId FROM Opportunity WHERE ContractStatus__c = \'Signed\')',Object__c='Account')
        };
            
        List<MapInsight_Metric__c> metricCS = new List<MapInsight_Metric__c>{       
            new MapInsight_Metric__c(Name='Bundle size contract', CustomMethod__c=null, Default__c=true, FilterField__c='Opportunity__r.Account', FilterObject__c='Account', TargetField__c='SUM(BundleSize__c)', TargetFilter__c='NumStatus__c = 4', TargetObject__c='Rev__c', Type__c='SOQL'),
            new MapInsight_Metric__c(Name='Number of Accounts', CustomMethod__c=null, Default__c=true, FilterField__c=null, FilterObject__c='Account', TargetField__c='COUNT(Id)', TargetFilter__c=null, TargetObject__c='Account', Type__c='SOQL'),
            new MapInsight_Metric__c(Name='Opportunites with Out for Signature', CustomMethod__c=null, Default__c=false, FilterField__c='Account', FilterObject__c='Account', TargetField__c='COUNT(Id)', TargetFilter__c='ContractStatus__c = \'Out for Signature\'', TargetObject__c='Opportunity', Type__c='SOQL'),
            new MapInsight_Metric__c(Name='Opportunites won %', CustomMethod__c='MapInsight_OpportunitiesWonPercentage', Default__c=false, FilterField__c=null, FilterObject__c='Account', TargetField__c=null, TargetFilter__c=null, TargetObject__c=null, Type__c='CustomCode'),
            new MapInsight_Metric__c(Name='Opportunities with signed agreement', CustomMethod__c=null, Default__c=false, FilterField__c='Account', FilterObject__c='Account', TargetField__c='COUNT(Id)', TargetFilter__c='ContractStatus__c = \'Signed\'', TargetObject__c='Opportunity', Type__c='SOQL'),
            //new MapInsight_Metric__c(Name='Subscription Revenue 2015', CustomMethod__c=null, Default__c=false, FilterField__c='Opportunity__r.Account', FilterObject__c='Account', TargetField__c='SUM(Revenue__c)', TargetFilter__c='CALENDAR_YEAR(From_Date__c) = 2015', TargetObject__c='RS__c', Type__c='SOQL'),
            //new MapInsight_Metric__c(Name='Subscription Revenue 2016', CustomMethod__c=null, Default__c=false, FilterField__c='Opportunity__r.Account', FilterObject__c='Account', TargetField__c='SUM(Revenue__c)', TargetFilter__c='CALENDAR_YEAR(From_Date__c) = 2016', TargetObject__c='RS__c', Type__c='SOQL'),
            //new MapInsight_Metric__c(Name='Subscription Revenue per month', CustomMethod__c=null, Default__c=false, FilterField__c='Opportunity__r.Account', FilterObject__c='Account', TargetField__c='SUM(UnitPrice__c)', TargetFilter__c='BillingCategory__c = \'Subscription\' AND BillingCalc__c = \'MonthlyProRata\'', TargetObject__c='Rev__c', Type__c='SOQL'),
            //new MapInsight_Metric__c(Name='Subscription Revenue per year', CustomMethod__c='MapInsight_SubscriptionRevenuePerYear', Default__c=false, FilterField__c=null, FilterObject__c='Account', TargetField__c=null, TargetFilter__c=null, TargetObject__c=null, Type__c='CustomCode')        
        	new MapInsight_Metric__c(Name='Monthly Revenue', CustomMethod__c=null, Default__c=false, FilterField__c='Opportunity__r.Account', FilterObject__c='Account', TargetField__c='SUM(UnitPrice__c)', TargetFilter__c='NumStatus__c = 4', TargetObject__c='Rev__c', Type__c='SOQL'),      
			new MapInsight_Metric__c(Name='Yearly Revenue', CustomMethod__c='MapInsight_SubscriptionRevenuePerYear', Default__c=false, FilterField__c=null, FilterObject__c='Account', TargetField__c=null, TargetFilter__c=null, TargetObject__c=null, Type__c='CustomCode')   
        };
        
        List<MapInsight_RegionMapping__c> regionCS = new List<MapInsight_RegionMapping__c>{
            new MapInsight_RegionMapping__c(Name='BE - Arrondissement',Country__c='Belgium',FieldSuffix__c='SubRegion__c',Grouping__c='Sub Region',Type__c='Arrondissement'),
            new MapInsight_RegionMapping__c(Name='BE - Country',Country__c='Belgium',FieldSuffix__c='Country__c',Grouping__c='Country',Type__c='Country'),
            new MapInsight_RegionMapping__c(Name='BE - Gemeente',Country__c='Belgium',FieldSuffix__c='Municipality__c',Grouping__c='Municipality',Type__c='Gemeente|Commune'),
            new MapInsight_RegionMapping__c(Name='BE - Gewest',Country__c='Belgium',FieldSuffix__c='Region__c',Grouping__c='Region',Type__c='Gewest|Région'),
            new MapInsight_RegionMapping__c(Name='BE - Provincie',Country__c='Belgium',FieldSuffix__c='Province__c',Grouping__c='Province',Type__c='Provincie|Hoofdstedelijk Gewest'),
        	new MapInsight_RegionMapping__c(Name='NL - Country',Country__c='Netherlands',FieldSuffix__c='Country__c',Grouping__c='Country',Type__c='Country'),
            new MapInsight_RegionMapping__c(Name='NL - Gemeente',Country__c='Netherlands',FieldSuffix__c='Municipality__c',Grouping__c='Municipality',Type__c='Gemeente'),
            new MapInsight_RegionMapping__c(Name='NL - Provincie',Country__c='Netherlands',FieldSuffix__c='Province__c',Grouping__c='Province',Type__c='Provincie')
         };
                        
        insert configurationCS;
        insert objectCS;
        insert recordCS;
        insert metricCS;
        insert regionCS;
        
        List<MapInsight_AccountComponentConfiguration__c> accountComponentConfigCS = new List<MapInsight_AccountComponentConfiguration__c>{
            new MapInsight_AccountComponentConfiguration__c(Name='Default',AccountCondition__c='',CountrySetting__c='Belgium|Netherlands',Default__c=true,MetricSetting__c=String.valueOf(metricCS.get(0).Id),ObjectSetting__c=String.valueOf(objectCS.get(0).Id),RecordFilterSetting__c=String.valueOf(recordCS.get(0).Id),RegionSetting__c='Municipality',UserCondition__c=null),
            new MapInsight_AccountComponentConfiguration__c(Name='THBEL Accounts',AccountCondition__c='Member_Id__c = \'THBEL\'',CountrySetting__c='Belgium',Default__c=false,MetricSetting__c=String.valueOf(metricCS.get(0).Id),ObjectSetting__c=String.valueOf(objectCS.get(0).Id),RecordFilterSetting__c=String.valueOf(recordCS.get(0).Id),RegionSetting__c='Municipality',UserCondition__c=null)
        };
            
        if (Test.isRunningTest()) {
        	accountComponentConfigCS.add(new MapInsight_AccountComponentConfiguration__c(Name='Accounts with username test', AccountCondition__c=null,CountrySetting__c='Belgium',Default__c=false,MetricSetting__c=String.valueOf(metricCS.get(0).Id),ObjectSetting__c=String.valueOf(objectCS.get(0).Id),RecordFilterSetting__c=String.valueOf(recordCS.get(0).Id),RegionSetting__c='Municipality',UserCondition__c='Name = \'Test\''));
        }
            
        insert accountComponentConfigCS;
        
        Map<String,List<sObject>> insertedSettings = new Map<String,List<sObject>>();
        insertedSettings.put('configuration', configurationCS);
        insertedSettings.put('object', objectCS);
        insertedSettings.put('record', recordCS);
        insertedSettings.put('metric', metricCS);
        insertedSettings.put('region', regionCS);
        insertedSettings.put('accountComponent', accountComponentConfigCS);
        
        return insertedSettings;
         
    }
    
    /* Private methods */
    
    private static String buildMetricQuery(String filterField, String filterObject, String targetField, String targetFilter, String targetObject, String groupBy, Set<String> validSuffixes, String filterBy) {
        String query = '';
        query += 'SELECT ';
        if (groupBy != null && groupBy != '') {
            for (String s : validSuffixes) {
                query += groupBy + s + ', ';
            }            
        } else {
            if (filterField == null && filterObject == targetObject) {
            	query += 'Id, ';
        	} else {
            	query += filterField + '.Id, ';
            }
        }
        query += targetField;
        query += ' FROM ' + targetObject;
        query += ' WHERE ';
        if (filterField == null && filterObject == targetObject) {
        	query += 'Id';
        } else {
            query += filterField + '.Id';
        }
        query += ' IN ' + filterBy;
        if (targetFilter != null && targetFilter != '') {
            query += ' AND ' + targetFilter;
        }
        
        if (groupBy != null && groupBy != '') {
            query += ' GROUP BY ';
            List<String> groupList = new List<String>();
            for (String s : validSuffixes) {
                groupList.add(groupBy + s);
            }
            query += String.join(groupList, ', ');
        } else {
            if (filterField == null && filterObject == targetObject) {
            	query += ' GROUP BY Id';
            } else {
                query += ' GROUP BY ' + filterField + '.Id ';
            }
        }
        
        System.debug('constructed query: ' + query);
        
        return query;
    }
    
    private static String forceStringConversion (Object o) {
        // This forces conversion of any types to a string
        try {
            return (String) o;
        } catch (Exception e) {}
        
        try {
            return String.valueOf((Decimal) o);
        } catch (Exception e) {}
        return '';
    }
    
    /* Data classes */
       
    global interface IMapInsightSetting {
		void init();
    }
    
    public virtual class MapInsightBaseSetting {
        public Id filterId { get; set; }
        public String filterName { get; set; }
        public Boolean isDefault { get; set; }
        public sObject settingsObj { get; set; }
        
        public MapInsightBaseSetting() {

        }
        
        public void init() {
            this.filterId = this.settingsObj.Id;
            this.filterName = (String) this.settingsObj.get('Name');
            this.afterInit();
        }
        
        public virtual void afterInit() {}
            
        
    }
    
    public class MapInsightObjectSetting extends MapInsightBaseSetting implements IMapInsightSetting  {
        private MapInsight_Object__c concreteObj;
        
        public MapInsightObjectSetting(Id objectSettingId) {
            this.concreteObj = (MapInsight_Object__c) UTIL.getCached(objectSettingId);
            this.settingsObj = this.concreteObj;
            this.init();
        }
        
        public override void afterInit() {}
        
    }
    
    public class MapInsightRecordFilterSetting extends MapInsightBaseSetting implements IMapInsightSetting  {
        
        private MapInsight_RecordFilter__c concreteObj;
        
        public MapInsightRecordFilterSetting(Id recordFilterSettingId) {
            this.concreteObj = (MapInsight_RecordFilter__c) UTIL.getCached(recordFilterSettingId);
            this.settingsObj = this.concreteObj;
            this.init();
        }
    }
    
    public class MapInsightMetricSetting extends MapInsightBaseSetting implements IMapInsightSetting  {
        
        private MapInsight_Metric__c concreteObj;
        
        public MapInsightMetricSetting(Id metricSettingId) {
            this.concreteObj = (MapInsight_Metric__c) UTIL.getCached(metricSettingId);
            this.settingsObj = this.concreteObj;
            this.init();
        }
    }
    
    public class MapInsightCountrySetting implements IMapInsightSetting  {
        public String filterName { get; set; }
        
        public void init() {}
        
        public MapInsightCountrySetting(String country) {
			this.filterName = country;
        }        
    }
    
    public class MapInsightGroupingSetting implements IMapInsightSetting  {
        public String filterName { get; set;}
        public List<String> validFor { get; set; }
        
        public void init() {}
        
        public MapInsightGroupingSetting(String groupingName) {
            this.filterName = groupingName;
        }        
    }
        
    global class MapInsightData {
        public List<MapInsightMarker> markers { get; set; }
        public List<MapInsightRegion> regions { get; set; }
        public List<String> visibleRegionTypes { get; set; }
    }
    
    public class MapInsightMarker {
        public Decimal longitude { get; set; }
        public Decimal latitude { get; set; }
        public Id objectId { get; set; }
        public String objectName { get; set; }
        public List<MapInsightMetric> metrics { get; set; }
        
        public MapInsightMarker(Id objectId, String objectName, Decimal latitude, Decimal longitude) {
            this.objectName = objectName;
            this.objectId = objectId;
            this.latitude = latitude;
            this.longitude = longitude;
        }
    }
    
    public class MapInsightRegion {
        public String regionName { get; set; }
        public List<MapInsightMetric> metrics { get; set; }
        
    }
    
    public class MapInsightMetric {
        public String description { get; set; }
        public String value { get; set; }
    }
}