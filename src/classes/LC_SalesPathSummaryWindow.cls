/**
 * Created by tajisingh on 4/4/2017.
 */
public with sharing class LC_SalesPathSummaryWindow {

    private static final String SUCCESS_STATUS = 'success';
    private static final String DONE_STATUS = 'done';
    private static final String OK_STATUS = 'ok';
    private static final String PENDING_STATUS = 'To do';
    private static final String TRUE_STATUS = 'true';
    private static final String FALSE_STATUS = 'false';
    private static final String RETRY_STATUS = 'retry';
    private static final String RUNNING_STATUS = 'Running';
    private static final String EMPTY_STRING = '';

    private static String getOppApprovedStatus(Opportunity opp) {
        return opp.NumStatus__c >= 1 ? TRUE_STATUS : FALSE_STATUS;
    }

    private static String getContractSignedStatus(Opportunity opp) {
        return opp.NumStatus__c >= 2 ? TRUE_STATUS : FALSE_STATUS;
    }

    private static List < String > getAccSentToLocalPlatformStatus(Opportunity opp) {
        if (String.isBlank(opp.Account.LocalPlatformId__c)) {
            // Check the if job is pending
            String whereClause = 'RecordId__c = ' + '\'' + opp.accountId + '\' ' + 'AND method__c = \'AccountPush\'';
            List < WS_ScheduledCallout__c > wssoLst = (List < WS_ScheduledCallout__c > ) GW_sObject.queryRecords('WS_ScheduledCallout__c', whereClause);
            return wssoLst.isEmpty() ? new List < String > {
                EMPTY_STRING,
                EMPTY_STRING
            } : getStatusFromWSchedule(wssoLst[0]);
        }
        return new List < String > {
            OK_STATUS,
            EMPTY_STRING
        };
    }

    private static List < String > getBookingSentToLocalPlatformStatus(String oppId) {
        String whereClause = 'RecordId__c = ' + '\'' + oppId + '\' ' + 'AND method__c = \'BookingPushTract\'';
        List < WS_ScheduledCallout__c > wssoLst = (List < WS_ScheduledCallout__c > ) GW_sObject.queryRecords('WS_ScheduledCallout__c', whereClause);

        return wssoLst.isEmpty() ? new List < String > {
            EMPTY_STRING,
            EMPTY_STRING
        } : getStatusFromWSchedule(wssoLst[0]);
    }

    private static List < String > getBookingSentToTractStatus(String oppId, String method) {
        String whereClause = 'RecordId__c = ' + '\'' + oppId + '\' ' + 'AND method__c = \'' + method + '\'';
        List < WS_ScheduledCallout__c > wssoLst = (List < WS_ScheduledCallout__c > ) GW_sObject.queryRecords('WS_ScheduledCallout__c', whereClause);

        return wssoLst.isEmpty() ? new List < String > {
            EMPTY_STRING,
            EMPTY_STRING
        } : getStatusFromWSchedule(wssoLst[0]);
    }

    private static List < String > getStatusFromWSchedule(WS_ScheduledCallout__c wsso) {
        List < String > lstResult = new List < String > ();
        Set < String > setForceSynButton = new Set < String > {
            RETRY_STATUS,
            DONE_STATUS
        };
        String status = wsso.status__c;
        status = String.isNotEmpty(status) ? status.toLowerCase() : status;
        lstResult.add(wsso.Pending__c ? PENDING_STATUS : status);
        lstResult.add('');
        if (String.isNotEmpty(status) && setForceSynButton.contains(status)) {
            lstResult = new List < String > ();
            if (!wsso.Last_Call_Successfull__c) {
                List < WS_Log__c > wslogs = [SELECT id, Error__c From WS_Log__c WHERE ScheduledCallout__c =: wsso.Id order by Name DESC Limit 1];
                lstResult.add(RETRY_STATUS);
                lstResult.add(!wslogs.isEmpty() ? wslogs[0].Error__c : EMPTY_STRING);
                return lstResult;
            }
            return new List < String > {
                DONE_STATUS,
                EMPTY_STRING
            };
        }
        return lstResult;
    }


    @auraEnabled
    public static Object getAllItemsStatus(String oppId) {

        List < String > additionalFields = new List < String > {
            'Account.LocalPlatformId__c'
        };
        Opportunity opp = GW_Opportunity.getRecord(oppId, additionalFields);

        Map < String, String > mapResult = new Map < String, String > ();
        List < String > lstResultAccSent = getAccSentToLocalPlatformStatus(opp);
        List < String > lstResultBookLocal = getBookingSentToLocalPlatformStatus(oppId);

        String method = 'OrderTract';
        if (!String.isEmpty(opp.Original_Opportunity__c)) {
            method = 'UpdateAgreementDetailsTract';
        }

        List < String > lstResultBookingTract = getBookingSentToTractStatus(oppId, method);
        mapResult.put('OpportunityApproved', getOppApprovedStatus(opp));
        mapResult.put('ContractSigned', getContractSignedStatus(opp));
        mapResult.put('AccountSentToLocalPlatform', lstResultAccSent[0]);
        mapResult.put('BookingSentToLocalPlatform', lstResultBookLocal[0]);
        mapResult.put('BookingSentToTRACT', lstResultBookingTract[0]);
        mapResult.put('AccountSentToLocalPlatformMsg', lstResultAccSent[1]);
        mapResult.put('BookingSentToLocalPlatformMsg', lstResultBookLocal[1]);
        mapResult.put('BookingSentToTRACTMsg', lstResultBookingTract[1]);

        if (opp.stagename == RUNNING_STATUS) {
            mapResult.put('BookingSentToTRACT', DONE_STATUS);
        }

        List < OpportunityLineItem > lstItems = [Select id, Opportunity.Tract_Order_Confirm__c From OpportunityLineItem where OpportunityId =: oppId And UniqueLocalBookingId__c <> null limit 1];
        if (!lstItems.isEmpty()) {
            mapResult.put('BookingSentToLocalPlatform', DONE_STATUS);
            if (lstItems[0].Opportunity.Tract_Order_Confirm__c) mapResult.put('BookingSentToTRACT', DONE_STATUS);
        }

        List < Object > res = new List < Object > ();
        res.add(mapResult);
        res.add(opp);
        return res;
    }

    private static Map < String, String > mapQueryFields = new Map < String, String > {
        'OppApprovedStatusUpdates' => 'Select Id,NumStatus__c From Opportunity',
        'AccLocalPlatStaUpdates' => 'Select Status__c, Id From WS_Log__c',
        'createWSSchUpdate' => 'Select Id,Status__c From WS_ScheduledCallout__c'
    };

    /**
     * Check if doesn't exist PushTopic it will auto create the PushTopic
     * @param lstTopics is a List of JSON as list of PushTopic
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse checkExistingTopic(List < String > lstTopics) {

        try {
            String whereClause = 'Name In (\'' + String.join(lstTopics, '\',\'') + '\')';
            List < PushTopic > lstExistTopics = GW_sObject.queryRecords('PushTopic', new List < String > {
                'id',
                'NotifyForOperationUpdate',
                'Name'
            }, whereClause);
            Set < String > setExistTopics = new Set < String > ();
            for (PushTopic topic: lstExistTopics) {
                setExistTopics.add(topic.Name);
            }

            List < PushTopic > lstTopicToInsert = new List < PushTopic > ();
            for (String topicName: lstTopics) {
                if (!setExistTopics.contains(topicName) && mapQueryFields.containskey(topicName)) {
                    lstTopicToInsert.add(new PushTopic(Name = topicName, Query = mapQueryFields.get(topicName), ApiVersion = 37.0, NotifyForOperationUpdate = true, NotifyForFields = 'All'));
                }
            }

            if (!lstTopicToInsert.isEmpty()) {
                insert lstTopicToInsert;
            }
            PushTopic pshTops = !lstExistTopics.isEmpty() ? lstExistTopics.get(0) : lstTopicToInsert.get(0);

            RemoteResponse response = new RemoteResponse();
            response.content = pshTops;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        } catch (Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

    @AuraEnabled
    public static RemoteResponse doForceBookingPushTract(ID oppId) {

        UTIL_WSC.WSC_Request wsRequestBookingPushTract = UTIL_WSC.getWSC_Request('WSC_API_SFECG_v2.BookingPushTract');
        wsRequestBookingPushTract.init(oppId);
        WS_ScheduledCallout__c wsScheduledCalloutBookingPushTract = wsRequestBookingPushTract.getScheduledCallout();
        upsert wsScheduledCalloutBookingPushTract UniqueKey__c;

        UTIL_WSC.WSC_Result res;
        res = wsRequestBookingPushTract.call();
        return getResponseResult(res);
    }

    private static RemoteResponse getResponseResult(UTIL_WSC.WSC_Result res) {
        RemoteResponse resp = new RemoteResponse();
        if (res.statusCode == 200 || res.statusCode == 201) {
            resp.message = SUCCESS_STATUS;
        } else {
            Map < String, Object > response = (Map < String, Object > ) res.getResponseData().get('results');
            resp.message = response != null && response.containsKey('error') ? (String) response.get('error') : (response != null && response.containsKey('message') ? (String) response.get('message') : String.isBlank(res.status) ? res.errorMsg : res.status);
        }

        return resp;
    }

    @AuraEnabled
    public static RemoteResponse doForceOrderTract(ID oppId) {

		if (GW_Opportunity.isAdsales([select MemberUnitId__c from Opportunity where id=:oppId])) {
			RemoteResponse resp = new RemoteResponse();
			resp.message = 'Booking to DFP is required for Adsales';
			return resp;
		}
        UTIL_WSC.WSC_Request wsRequestActivationOrder = UTIL_WSC.getWSC_Request('WSC_Tract.OrderTract');
        wsRequestActivationOrder.init(oppId);
        WS_ScheduledCallout__c wsScheduledCalloutActivationOrder = wsRequestActivationOrder.getScheduledCallout();
        upsert wsScheduledCalloutActivationOrder UniqueKey__c;

        UTIL_WSC.WSC_Result res;
        res = wsRequestActivationOrder.call();

        return getResponseResult(res);
    }

    @AuraEnabled
    public static RemoteResponse doUpdateAgreementDetailsTract(ID oppId) {

        UTIL_WSC.WSC_Request wsRequestUpdateAggreDetail = UTIL_WSC.getWSC_Request('WSC_Tract.UpdateAgreementDetailsTract');
        wsRequestUpdateAggreDetail.init(oppId);
        WS_ScheduledCallout__c wsScheduledCalloutUpdateAggreement = wsRequestUpdateAggreDetail.getScheduledCallout();
        upsert wsScheduledCalloutUpdateAggreement UniqueKey__c;

        UTIL_WSC.WSC_Result res;
        res = wsRequestUpdateAggreDetail.call();

        return getResponseResult(res);
    }


    @AuraEnabled
    public static RemoteResponse doForceAccountSentToPlatform(ID accId) {
		if(UTIL_WSC_Subscription.isAccOnlyAdsales(accId)) {
        	RemoteResponse rr = new RemoteResponse();
         	rr.message = SUCCESS_STATUS;  
        	return rr;
        }
        UTIL_WSC.WSC_Request wsRequestAccountPush = UTIL_WSC.getWSC_Request('WSC_API_SFECG_v1.AccountPush');
        wsRequestAccountPush.init(accId);
        WS_ScheduledCallout__c wsScheduledCalloutAccountPush = wsRequestAccountPush.getScheduledCallout();
        upsert wsScheduledCalloutAccountPush UniqueKey__c;

        UTIL_WSC.WSC_Result res;
        res = wsRequestAccountPush.call();

        return getResponseResult(res);
    }

}