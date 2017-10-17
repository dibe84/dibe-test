// This class contains custom logic used to retrieve metrics for MapInsight
public class MapInsight_CustomCode {
    public interface IMapInsight_CustomCode {
        MapInsight_CustomCodeResult run();
        void setFilterIds(Set<Id> filterIds);
        void setRegionDetails(String regionPrefix, Set<String> validSuffixes, Map<String,String> countryToTargetSuffix, String relationName);
    }
    
    public virtual class MapInsight_CustomCodeBase {
        private Set<Id> filterIds = null;
        private List<String> regionFields = new List<String>();
        private List<String> regionFieldsWithRelation = new List<String>();
        private Map<String,String> countryToTargetSuffix = null;
        private String regionPrefix = null;
        
        public void setFilterIds(Set<Id> filterIds) {
            this.filterIds = filterIds;
        }
        
        public void setRegionDetails(String regionPrefix, Set<String> validSuffixes, Map<String,String> countryToTargetSuffix, String relationName) {
            for (String s : validSuffixes) {
                regionFields.add(regionPrefix + s);
                regionFieldsWithRelation.add(relationName + '.' + regionPrefix + s);
            }
            this.countryToTargetSuffix = countryToTargetSuffix;
            this.regionPrefix = regionPrefix;
        }
    }
    
    public class MapInsight_OpportunitiesWonPercentage extends MapInsight_CustomCodeBase implements IMapInsight_CustomCode {        
        public MapInsight_OpportunitiesWonPercentage() {}
                
        public MapInsight_CustomCodeResult run() {
            MapInsight_CustomCodeResult result = new MapInsight_CustomCodeResult();
            result.recordValues = this.getAccountValues();
            result.regionValues = this.getRegionValues();
            result.description = '% of won opportunities (Stage = Signed)';
            return result;
        }
        
        private Map<Id,Decimal> getAccountValues()  {
            Map<Id,Decimal> result = new Map<Id,Decimal>();
            Map<Id,Integer> countWon = new Map<Id,Integer>();
            Map<Id,Integer> countLost = new Map<Id,Integer>();
            Set<Id> filterIds = this.filterIds;
            
            List<AggregateResult> opportunitiesWonByAccount = Database.query('SELECT AccountId, COUNT(Id) FROM Opportunity WHERE NumStatus__c > 1 AND NumStatus__c < 5 AND AccountId IN :filterIds GROUP BY AccountId');
            List<AggregateResult> opportunitiesLostByAccount = Database.query('SELECT AccountId, COUNT(Id) FROM Opportunity WHERE NumStatus__c = -1 AND AccountId IN :filterIds GROUP By AccountId');

            for (AggregateResult o : opportunitiesWonByAccount) {
            	countWon.put((Id) o.get('AccountId'), (Integer) o.get('expr0'));   
            }
            for (AggregateResult o : opportunitiesLostByAccount) {
            	countLost.put((Id) o.get('AccountId'), (Integer) o.get('expr0'));   
            }
                        
            for (Id accountId : filterIds) {               
                if (countWon.get(accountId) == null && countLost.get(accountId) == null) {
                    result.put(accountId, null);
                }
                if (countWon.get(accountId) != null && countLost.get(accountId) == null) {
                    result.put(accountId, 100);
                }
                if (countWon.get(accountId) == null && countLost.get(accountId) != null) {
                    result.put(accountId, 0);
                }
                if (countWon.get(accountId) != null && countLost.get(accountId) != null) {
                    result.put(accountId, ((Decimal.valueOf(countWon.get(accountId)) / (Decimal.valueOf(countLost.get(accountId)) + Decimal.valueOf(countWon.get(accountId)))) * 100).setScale(2)) ;
                }
            }
            return result;
        }
        
        private Map<String,Decimal> getRegionValues()  {
            Map<String,Decimal> result = new Map<String,Decimal>();
            Map<String,Integer> countWon = new Map<String,Integer>();
            Map<String,Integer> countLost = new Map<String,Integer>();
            Set<Id> filterIds = this.filterIds;
            String regionFieldsWithRelation = String.join(this.regionFieldsWithRelation, ', ');
            String countryField = this.regionFields.get(this.regionFields.size() - 1);
            Set<String> regionNames = new Set<String>();
            
            List<AggregateResult> opportunitiesWonByAccount = Database.query('SELECT ' + regionFieldsWithRelation + ', COUNT(Id) FROM Opportunity WHERE NumStatus__c > 1 AND NumStatus__c < 5  AND AccountId IN :filterIds GROUP BY ' + regionFieldsWithRelation);
            List<AggregateResult> opportunitiesLostByAccount = Database.query('SELECT ' + regionFieldsWithRelation + ', COUNT(Id) FROM Opportunity WHERE NumStatus__c = -1 AND AccountId IN :filterIds GROUP BY ' + regionFieldsWithRelation);
	
            // Won
            for (AggregateResult ar : opportunitiesWonByAccount) {
                String countryName = (String) ar.get(countryField);
                String targetField = this.regionPrefix + this.countryToTargetSuffix.get(countryName);
                countWon.put((String) ar.get(targetField), (Integer) ar.get('expr0'));
                regionNames.add((String) ar.get(targetField));
            }
            
            for (AggregateResult ar : opportunitiesLostByAccount) {
                String countryName = (String) ar.get(countryField);
                String targetField = this.regionPrefix + this.countryToTargetSuffix.get(countryName);
                countLost.put((String) ar.get(targetField), (Integer) ar.get('expr0'));
                regionNames.add((String) ar.get(targetField));
            }
                                    
            for (String regionName : regionNames) {               
                if (countWon.get(regionName) == null && countLost.get(regionName) == null) {
                    result.put(regionName, null);
                }
                if (countWon.get(regionName) != null && countLost.get(regionName) == null) {
                    result.put(regionName, 100);
                }
                if (countWon.get(regionName) == null && countLost.get(regionName) != null) {
                    result.put(regionName, 0);
                }
                if (countWon.get(regionName) != null && countLost.get(regionName) != null) {
                    result.put(regionName, ((Decimal.valueOf(countWon.get(regionName)) / (Decimal.valueOf(countLost.get(regionName)) + Decimal.valueOf(countWon.get(regionName)))) * 100).setScale(2));
                }
            }
            
            return result;
        }
    }
    
    public class MapInsight_SubscriptionRevenuePerYear extends MapInsight_CustomCodeBase implements IMapInsight_CustomCode {        
        public MapInsight_SubscriptionRevenuePerYear() {}
                
        public MapInsight_CustomCodeResult run() {
            MapInsight_CustomCodeResult result = new MapInsight_CustomCodeResult();
            result.recordValues = this.getAccountValues();
            result.regionValues = this.getRegionValues();
            result.description = 'Subscription Revenue per Year';
            return result;
        }
        
        private Map<Id,Decimal> getAccountValues()  {
            Map<Id,Decimal> result = new Map<Id,Decimal>();
            Map<Id,Decimal> revenuePerYear = new Map<Id,Decimal>();
            Set<Id> filterIds = this.filterIds;

            List<AggregateResult> revenuePerAccount = Database.query('SELECT Opportunity__r.Account.Id, SUM(UnitPrice__c) FROM Rev__c WHERE Opportunity__r.Account.Id IN :filterIds AND NumStatus__c = 4 GROUP BY Opportunity__r.Account.Id');

            for (AggregateResult o : revenuePerAccount) {
            	result.put((Id) o.get('Id'), ((Decimal) o.get('expr0')) * 12);   
            }
            
            return result;
        }
        
        private Map<String,Decimal> getRegionValues()  {
            Map<String,Decimal> result = new Map<String,Decimal>();
            Set<Id> filterIds = this.filterIds;
            
            List<String> prefixedRegionFieldsWithRelation = new List<String>();
            for (String s : this.regionFieldsWithRelation) {
                prefixedRegionFieldsWithRelation.add('Opportunity__r.' + s);
            }
            String regionFieldsWithRelation = String.join(prefixedRegionFieldsWithRelation, ', ');
            String countryField = this.regionFields.get(this.regionFields.size() - 1);
            Set<String> regionNames = new Set<String>();
                       
            List<AggregateResult> revenuePerRegion = Database.query('SELECT ' + regionFieldsWithRelation + ', SUM(UnitPrice__c) FROM Rev__c WHERE Opportunity__r.Account.Id IN :filterIds GROUP BY ' + regionFieldsWithRelation);

            for (AggregateResult ar : revenuePerRegion) {
                String countryName = (String) ar.get(countryField);
                String targetField = this.regionPrefix + this.countryToTargetSuffix.get(countryName);
                System.debug(LoggingLevel.ERROR, 'countryField' + countryField + ' regionFields ' + this.regionFields + ' countryName: ' + countryName + ' targetField ' + targetField + ' cts ' + this.countryToTargetSuffix + ' rpx ' + this.regionPrefix);
                result.put((String) ar.get(targetField), ((Decimal) ar.get('expr0')) * 12);
            }
                        
            return result;
        }
    }
    
    public class MapInsight_CustomCodeResult {
        public Map<Id, Decimal> recordValues { get; set; }
        public Map<String, Decimal> regionValues { get; set; }
        public String description { get; set; }
    }
}