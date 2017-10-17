public class UTIL_MapInsight {
    public static Map<String,String> convertFusionTableResponseToRegions(Map<String,String> input) {
        // Assume the input we get is a map of type -> value, we always need one 'country' type so we can look up the associated types and in what field we should store the result
        Map<String,String> output = new Map<String,String>();
                
        List<MapInsight_RegionMapping__c> allRegionMappings = [SELECT Country__c, Type__c, FieldSuffix__c, Grouping__c FROM MapInsight_RegionMapping__c WHERE Country__c = :input.get('Country')];
        // If we have no mappings then there is no way to figure out the right mapping for this response
        if (allRegionMappings == null || allRegionMappings.size() == 0) {
            //throw new UTIL.CustomException('No region mapping was found for this country (or country was not found)');
            return output;
        }
        
        Map<String,String> typeToFieldMap = new Map<String,String>();
        Map<String,List<String>> groupingToOrderList = new Map<String,List<String>>();
        Map<String,String> typeToGrouping = new Map<String,String>();

        // First loop we group all region mappings by country
        for (MapInsight_RegionMapping__c rm : allRegionMappings) {
            List<String> orderList = new List<String>();
            List<String> rmTypes = rm.Type__c.split('\\|');
            for (String rmType : rmTypes) {
                orderList.add(rmType);
                typeToFieldMap.put(rmType, rm.FieldSuffix__c);
                typeToGrouping.put(rmType, rm.Grouping__c);
            }
            groupingToOrderList.put(rm.Grouping__c, orderList);
        }
        
        Map<String,Integer> savedGroupingPosition = new Map<String,Integer>();
        // Now loop through all the inputs, figure out what country we are looking at
        for (String inputType : input.keySet()) {
            String inputValue = input.get(inputType);
            String grouping = typeToGrouping.get(inputType);
            List<String> orderList = groupingToOrderList.get(grouping);
            if (orderList.size() == 1) {
            	output.put(typeToFieldMap.get(inputType), inputValue);
            } else {
                Integer position = 0;
                for (String s : orderList) {
                    if (s == inputType) {
                        break;
                    }
                    position++;
                }
                Integer savedPosition = savedGroupingPosition.get(grouping);
                if (savedPosition == null || position < savedPosition) {
                    savedGroupingPosition.put(grouping, position);
                    output.put(typeToFieldMap.get(inputType), inputValue);
                }
            }
        }
        
        return output;
    }	
}