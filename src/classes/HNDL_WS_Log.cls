public class HNDL_WS_Log extends TriggerManager.TriggerHandler {
    private List<Account> accsToUpdate = new List<Account>();
    private List<WS_ScheduledCallout__c> wssoToUpdate = new List<WS_ScheduledCallout__c>();

    
    public override void beforeInsert(SObject so) {
        WS_Log__c log = (WS_Log__c)so;
        checkForLookup(log);
        setAccountPushErrorOnAccount(log);
    }
    
    public override void beforeUpdate(SObject oldSo, SObject so) {
        WS_Log__c log = (WS_Log__c)so;
        WS_Log__c oldlog = (WS_Log__c)oldSo;
        checkForLookup(log);
        setAccountPushErrorOnAccount(log);
    }
    
    public override void beforeDelete(SObject so) {}
    public override void afterInsert(SObject so) {
        WS_Log__c log = (WS_Log__c) so;
        checkForSuccesfullCompletion(log);
    }

    public override void andFinally() {
        if (accsToUpdate.size() > 0) {
            try {
				// Below accounts are queried to prevent unable_to_lock_row error during update
				Set<Id> accIdSet = (new Map<Id, Account>(accsToUpdate)).keySet();
				List<Account> lockAccountsList = [SELECT Id FROM Account WHERE Id IN :accIdSet FOR UPDATE];
                Database.saveResult[] res = Database.update(accsToUpdate,FALSE);
                for (Integer i = 0; i< res.size(); i++) {
                    if (!res[i].success) {
                        String errorMsg;
                        for(Database.Error err : res[i].getErrors() ) {
                            errorMsg = 'Error saving the object after processing response:\n';
                            errorMsg += err.getStatusCode() + ': ' + err.getMessage() + '\n';
                            errorMsg += 'Fields: ' + err.getFields() + '\n';
                            errorMsg += 'Object: ' + String.valueOf(accsToUpdate[i]);
                        }
                        UTIL.Log(errorMsg);
                        UTIL.emailExceptionInfoToSlack(errorMsg);
                    }
                }
            } catch (Exception e) {
                UTIL.Log('HNDL_WS_Log - Error updating Accounts' + e);
            }
        }
        if(wssoToUpdate.size() > 0) {
            try {
                update wssoToUpdate;
            }catch (Exception e){
                UTIL.log('HNDL_WS_Log - Error updating WS ScheduledCallout');
            }
        }
    }

//////////////////////////////
// private helper methods
//////////////////////////////

    private void setAccountPushErrorOnAccount(WS_Log__c log) {
        if (! log.CalloutName__c.contains('AccountPush') || null == log.Account__c) {
            return;
        }
		
		String lastupdatedstr = ' (last updated: ' + Datetime.now().format('MM/dd/yyyy HH:mm a (z)') + ')';
        String lastMessage = null != log.Error__c ? log.Error__c.left(1024 - lastupdatedstr.length()) : '';
        if (lastMessage == UTIL_WSC_API_SFECG.NO_RESPONSE_MSG || String.isEmpty(lastMessage)) {
            lastMessage = 'OK';
        }

        lastMessage += lastupdatedstr;
        Account acc = new Account(Id=log.Account__c, LastLocalPlatformSyncMessage__c=lastMessage);
        this.accsToUpdate.add(acc);
    }

    // Make sure correct member is connected to Account
    private void checkForLookup(WS_Log__c log) {
        String parentObject;
        if (log.ParentId__c != null) parentObject = GW_sObject.getobjectNameFromId(log.ParentId__c);
        if (parentObject=='Account') log.Account__c = log.ParentId__c;
        if (parentObject=='Rev__c') log.Rev__c = log.ParentId__c;
        if (parentObject=='Invoice__c') log.Invoice__c = log.ParentId__c;
        if (parentObject=='Opportunity') log.Opportunity__c = log.ParentId__c;
    }

    private void checkForSuccesfullCompletion(WS_Log__c log){
        if(log.Success__c && log.ScheduledCallout__c != null ){
            WS_ScheduledCallout__c wsso = (WS_ScheduledCallout__c) GW_sObject.queryRecord('WS_ScheduledCallout__c', log.ScheduledCallout__c);
            wsso.Last_Call_Successfull__c = log.Success__c;
            wssoToUpdate.add(wsso);
        }
    }



 
    // Constructor
    public HNDL_WS_Log() { super('HNDL_WS_Log', WS_Log__c.sObjectType); } 
}