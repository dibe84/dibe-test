public with sharing class WSC_GeoLocation {    
    public static Webservice_Settings__c WS_GEOLOCATION 	= Webservice_Settings__c.getInstance('GOOGLE_GEOLOCATION');
	private static final String GEOLOCATION_ENDPOINT     	= (!Test.IsRunningTest())?(WS_GEOLOCATION.UseProxy__c?WS_GEOLOCATION.EndpointProxy__c:WS_GEOLOCATION.Endpoint__c):'testendpoint';
    
    public static Webservice_Settings__c WS_FUSIONTABLE 	= Webservice_Settings__c.getInstance('GOOGLE_FUSIONTABLE');
	private static final String FUSIONTABLE_ENDPOINT     	= (!Test.IsRunningTest())?(WS_FUSIONTABLE.UseProxy__c?WS_FUSIONTABLE.EndpointProxy__c:WS_FUSIONTABLE.Endpoint__c):'testendpoint';

    
    public static Location retrieveCoordinatesForAddress(String searchAddress) {
        Location resultCoordinates = null;
        String url = GEOLOCATION_ENDPOINT + '?address=' + EncodingUtil.urlEncode(searchAddress,'UTF-8').replaceAll('\\+', '%20') + (WS_GEOLOCATION.Key__c != null ? '&key=' + WS_GEOLOCATION.Key__c : '');
        UTIL_WSC.basicCallout co = new UTIL_WSC.basicCallout('retrieveCoordinatesForAddress', url, 'GET');
        co.mockResponseBody = '{"results":[{"address_components":[{"long_name":"224","short_name":"224","types":["street_number"]},{"long_name":"Wibautstraat","short_name":"Wibautstraat","types":["route"]},{"long_name":"Amsterdam-Oost","short_name":"Amsterdam-Oost","types":["sublocality_level_1","sublocality","political"]},{"long_name":"Amsterdam","short_name":"Amsterdam","types":["locality","political"]},{"long_name":"Amsterdam","short_name":"Amsterdam","types":["administrative_area_level_2","political"]},{"long_name":"Noord-Holland","short_name":"NH","types":["administrative_area_level_1","political"]},{"long_name":"Netherlands","short_name":"NL","types":["country","political"]},{"long_name":"1097 DN","short_name":"1097 DN","types":["postal_code"]}],"formatted_address":"Wibautstraat 224, 1097 DN Amsterdam, Netherlands","geometry":{"bounds":{"northeast":{"lat":52.3493366,"lng":4.9178088},"southwest":{"lat":52.34824529999999,"lng":4.9164007}},"location":{"lat":52.348791,"lng":4.9171048},"location_type":"ROOFTOP","viewport":{"northeast":{"lat":52.3501399302915,"lng":4.918453730291502},"southwest":{"lat":52.3474419697085,"lng":4.915755769708498}}},"place_id":"ChIJXdBW74EJxkcRd8akS4MNF_U","types":["premise"]}],"status":"OK"}';
		HttpResponse resp = co.call();
        if (resp.getStatusCode() != 200) {
            throw new UTIL.CustomException('Error retrieving coordinates; called ' + url + ' got status code: ' + resp.getStatusCode() + ' body: ' + resp.getBody());
        } else {
            try { 
                Map<String,Object> jsonMap = (Map<String,Object>) JSON.deserializeUntyped(resp.getBody());
                List<Object> jsonResults = (List<Object>) jsonMap.get('results');
                Map<String,Object> resultMap = (Map<String,Object>) jsonResults.get(0);
                Decimal latitude = (Decimal) ((Map<String,Object>)((Map<String,Object>) resultMap.get('geometry')).get('location')).get('lat');
                Decimal longitude = (Decimal) ((Map<String,Object>)((Map<String,Object>) resultMap.get('geometry')).get('location')).get('lng');
                resultCoordinates = Location.newInstance(latitude, longitude);           
                return resultCoordinates;
            } catch (Exception e) {
                throw new UTIL.CustomException('Error parsing coordinates; called ' + url + ' got status code: ' + resp.getStatusCode() + ' body: ' + resp.getBody());
            }
        }
        return resultCoordinates;
    }
    
    public static Map<String,String> retrieveRegionsForCoordinates(Decimal latitude, Decimal longitude) {
        Map<String,String> resultMap = null;
        String query = 'SELECT \'name\', \'description\' FROM ' + MapInsight_Configuration__c.getInstance('TABLE_ID').Value__c + ' WHERE ST_INTERSECTS(\'geometry\', CIRCLE(LATLNG(' + latitude.toPlainString() + ',' + longitude.toPlainString() + '),0.5));';
        String url = FUSIONTABLE_ENDPOINT + '?sql=' + EncodingUtil.urlEncode(query,'UTF-8').replaceAll('\\+', '%20') + (WS_FUSIONTABLE.Key__c != null ? '&key=' + WS_FUSIONTABLE.Key__c : '');
        UTIL_WSC.basicCallout co = new UTIL_WSC.basicCallout('retrieveCoordinatesForAddress', url, 'GET');
        co.mockResponseBody = '{"kind":"fusiontables#sqlresponse","columns":["name","description"],"rows":[["Netherlands","Country"],["Noord-Holland","Provincie"],["Amsterdam","Gemeente"]]}';
		HttpResponse resp = co.call();
        if (resp.getStatusCode() != 200) {
            throw new UTIL.CustomException('Error retrieving regions; called ' + url + ' got status code: ' + resp.getStatusCode() + ' body: ' + resp.getBody());
        } else {
            try {
                resultMap = new Map<String,String>();
                Map<String,Object> jsonMap = (Map<String,Object>) JSON.deserializeUntyped(resp.getBody());
                List<Object> rows = (List<Object>) jsonMap.get('rows');
                for (Object o : rows) {
                    List<Object> resultArray = (List<Object>) o;
                    String resultValue = (String) resultArray.get(0);
                    String resultType = (String) resultArray.get(1);
                    resultMap.put(resultType, resultValue);
                }
            } catch (Exception e) {
                throw new UTIL.CustomException('Error parsing regions; called ' + url + ' got status code: ' + resp.getStatusCode() + ' body: ' + resp.getBody());
            }
        }
        return resultMap;
    }
}