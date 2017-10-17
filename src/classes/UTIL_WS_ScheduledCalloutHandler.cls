/**
 * Created by rvannierop on 2/21/2017.
 */

public class UTIL_WS_ScheduledCalloutHandler {

    ////////////////////////////////////////////
    //Only use these methods from async context!
    ////////////////////////////////////////////
    public static void execute(List<WS_ScheduledCallout__c> scope, List<WS_ScheduledCallout__c> wsscsToUpdate, List<WS_ScheduledCallout__c> wsscsToDelete) {
        // Prioritize objects in queue
        scope = UTIL_WSC.sortAccordingToPriority(scope);
        for (WS_ScheduledCallout__c wssc : scope) {
            UTIL_WSC.WSC_Request req;
            UTIL_WSC.WSC_Result res;
            //WS_Log__c log;
            try {
                req = UTIL_WSC.getWSC_Request(wssc.API__c+'.'+wssc.Method__c); // instantiate request object
                req.init(wssc.RecordId__c); 		// init with context record
                res = req.call(); 					// try call and get result
                //log = req.log;
            } catch(Exception e) {
                UTIL.log('UTIL_WS_ScheduledCalloutHandler execute() - Error initializing UTIL_WSC request: '+e.getMessage());
                UTIL.log('stack: '+e.getStackTraceString() );
                if (req.isContextRecordDeleted == true) {
                    wsscsToDelete.add(wssc);
                    continue;
                }
            }
            if (wssc.Id == null) {
                upsert wssc UniqueKey__c;
            }
            //log.ScheduledCallout__c = wssc.Id; // link created log to the ScheduledCallout object
            // handle ScheduledCallout object changes
            wssc.LastAttempt__c = Datetime.now();
            
            if (wssc.Attempts__c == null) {
                wssc.Attempts__c = 0;
            }
            wssc.Attempts__c = wssc.Attempts__c + 1;
            if (res == null) {
                wssc.Status__c = 'ResIsNull';
            } else {
                if (res.retryCallout) {
                    wssc.Status__c = 'Retry';
                } else {
                    wssc.Status__c = 'Done';
                }

            }
            wsscsToUpdate.add(wssc);
        }
    }
}