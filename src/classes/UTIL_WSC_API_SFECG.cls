/**
 * Created by rvannierop on 2/6/2017.
 */

public class UTIL_WSC_API_SFECG {

    public static final String NO_RESPONSE_MSG = 'No response given!';

    public virtual class ApiRequest extends UTIL_WSC.WSC_Request {
        public virtual override void init(Id contextRecordId) {
            super.init(contextRecordId);
            this.setHeader('Accept','application/json');
            this.setHeader('Accept-Encoding','compress, gzip');
            this.setHeader('Content-Type', 'application/json');
            this.setHeader('Accept-Charset','utf-8');
            this.setHeader('Date', Datetime.now().formatGMT('EEE, d MMM yyyy HH:mm:ss z'));
        }
        public virtual override Boolean readyForCallout() { return TRUE; } // override with entry criteria in specific implementation, when these apply

        public override String getBody() 			{
            Map<String,Object> output = this.mapper.getOutputMap();
            if (output!=null) return JSON.serialize(output);
            return null;
        }
        public override String getFormattedBody() 	{
            Map<String,Object> output = this.mapper.getOutputMap();
            if (output!=null) return JSON.serializePretty(output);
            return null;
        }
    }

    // Generic Result object for all responses to outgoing API calls
    public class ApiResult extends UTIL_WSC.WSC_Result {
        public override Map<String,Object> getResponseData() {
            String errorString = 'Error processing response data. ';
            Map<String, Object> responseData = new Map<String,Object>();
            try {
                if (resp !=null && !String.isBlank(resp.getBody()) )
                    return (Map<String,Object>) JSON.deserializeUntyped(resp.getBody());
                else if (resp == null) {
                    errorString += 'No result. ';
                    responseData.put('ERROR', errorString);
                    responseData.put('BODY', 'null');
                    responseData.put('message', errorMsg);
                    //responseData.put('message', errorString + this.errorMsg);
                    return responseData;
                }
                else {
                    return null;
                }
            } catch (Exception e) {
                errorString += e.getMessage()+' '+e.getTypeName()+ '\n';
                responseData.put('ERROR', e.getMessage());
                responseData.put('BODY', resp.getBody());
                responseData.put('message', errorString);
                return responseData;
            }
        }
        public override String getFormattedBody() {
            Map<String,Object> resp = this.getResponseData();
            if (resp != null) {
                Map<String,Object> reversedMap = new Map<String,Object>();
                List<String> keys = new List<String>(resp.keySet());
                //keys.addAll();
                for (Integer i = keys.size()-1; i >= 0; i--  ) {
                    reversedMap.put(keys[i], resp.get(keys[i]));
                }
                return JSON.serializePretty(reversedMap);
            } else return '<Empty>';

        }
    }// END ApiResult

    public virtual class ApiHandler extends UTIL_WSC.WSC_ResultHandler {
        public virtual override void handle() {
            super.handle();
            if(this.result.success == FALSE) {
                String errorMessage = '';
                Map<String, Object> responseData = this.result.getResponseData();
                if (responseData != null && responseData.containsKey('ERROR')) {
                    errorMessage += (String) responseData.get('ERROR');
                }
                if (responseData != null && responseData.containsKey('message')) {
                    errorMessage += (String) responseData.get('message');
                }

                if(errorMessage.length() > 0) {
                    logError(errorMessage);
                } else {
                    logError(UTIL_WSC_API_SFECG.NO_RESPONSE_MSG);
                }
            }
        }
    }// END ApiHandler
}