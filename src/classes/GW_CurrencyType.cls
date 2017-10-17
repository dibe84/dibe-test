public class GW_CurrencyType {

    // cached currencyType map
	public static Map<String, CurrencyType> currencyTypeMap { // IsoCode => CurrencyType
        get {
        	if (currencyTypeMap == null) {
        		currencyTypeMap = new Map<String, CurrencyType>();
        		List<CurrencyType> curs = [	Select  id, IsoCode, LastModifiedDate, DecimalPlaces, ConversionRate From CurrencyType where isActive=true LIMIT 1000];
        		for (CurrencyType cur : curs) {
        			currencyTypeMap.put(cur.IsoCode, cur);
        		}
        	}
            return currencyTypeMap;
        }
        private set;
    }
    
}