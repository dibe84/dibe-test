/**
 * Class TriggerManager
 * Used to instantiate and execute Trigger Handlers associated with sObjects.
 * Initially based on: Trigger Pattern by Tony Scott
 */
public with sharing class TriggerManager {

    private static System.LoggingLevel logLevel = LoggingLevel.INFO;
    private static Boolean showTriggerDebug = UTIL.getConfig('TriggerDebugging')=='TRUE'?TRUE:FALSE;
    private static Boolean showStackLog = UTIL.getConfig('TriggerStackLog')=='FALSE'?FALSE:TRUE;
	public static Boolean isSuspended = false;

    public enum triggerEventType { AfterDelete, AfterInsert, AfterUndelete, AfterUpdate, BeforeDelete, BeforeInsert, BeforeUpdate }

    public static Integer triggerStackIndex = 0;
    public static Integer triggerStackDepth = 0;
    public static String triggerStackLog = '##### TRIGGERHANDLER LOG ###############\n';
    public static Map<Integer, TriggerManager.TriggerHandler> triggerStack = new Map<Integer, TriggerManager.TriggerHandler>();

    private static TriggerManager.ITriggerHandler getHandler(Type t) {
        if (t == null) return null;
        // Instantiate the type
        Object o = t.newInstance();

        // if its not an instance of ITrigger return null
        if (!(o instanceOf TriggerManager.ITriggerHandler)) return null;

        return (TriggerManager.ITriggerHandler)o;
    }

    // Public static method to create and execute a trigger handler
    public static void createHandler(Type handlerType) {
		if (TriggerManager.isSuspended) {
			if (UTIL.isSandbox() || (!UTIL.isSandbox() && Test.isRunningTest())) {
				return;
			}
		}
        if(isTriggerHandlerDisabledForType(handlerType) == TRUE)
            return;

        TriggerManager.ITriggerHandler handler = getHandler(handlerType);
        if (handler == null) throw new TriggerException('Not a valid Trigger Handler: ' + handlerType);
        execute(handler);
    }

    // controls the execution of the handler. Arguments: ITriggerHandler handler (Trigger Handler to execute)
    private static void execute(TriggerManager.ITriggerHandler handler) {

        handler.start();
        if (Trigger.isBefore) {
            if (Trigger.isDelete) {
                handler.bulkBefore(Trigger.Old, Trigger.oldMap, Trigger.newMap); // gather data required into sets/maps, prior execution of the BEFORE trigger
			} else {
                handler.bulkBefore(Trigger.New, Trigger.oldMap, Trigger.newMap);
			}

            if (Trigger.isDelete) {
                for (SObject so : Trigger.old) {
                    handler.beforeDelete(so);   // iterate records before deletion
                }
			} else if (Trigger.isInsert) {
                for (SObject so : Trigger.new) {
                    handler.beforeInsert(so);    // iterate records before insertion
                }
			} else if (Trigger.isUpdate) {
                for (SObject so : Trigger.old) {
                    handler.beforeUpdate(so, Trigger.newMap.get(so.Id));   // iterate records before update
                }
			}
        } else {
            if (Trigger.isDelete) {
                handler.bulkAfter(Trigger.Old, Trigger.oldMap, Trigger.newMap); // gather data required into sets/maps, prior execution of the AFTER trigger
			} else {
                handler.bulkAfter(Trigger.New, Trigger.oldMap, Trigger.newMap);
			}

            if (Trigger.isDelete)
                for (SObject so : Trigger.old) {
                    handler.afterDelete(so);    // iterate records after deletion
                }
            else if (Trigger.isInsert)
                for (SObject so : Trigger.new) {
                    handler.afterInsert(so);    // iterate records after insertion
                }
            else if (Trigger.isUpdate)
                for (SObject so : Trigger.old) {
                    handler.afterUpdate(so, Trigger.newMap.get(so.Id));    // iterate records after update
                    if ( UTIL.inCache(so.Id) ) UTIL.cache(Trigger.newMap.get(so.Id));
                }
            else if (Trigger.isUndelete)
                for (SObject so : Trigger.new) {
                    handler.afterUndelete(so);    // iterate records after undelete
                }
        }
        handler.andFinally(); // Perform any post processing. Eg. DML operations on other objects.

        handler.stop();
    }

    // Virtual class ITriggerHandler, 'TriggerHandler' implements this interface, all sObject handlers extend the TriggerHandler class
    public interface ITriggerHandler {
        void start();
        void bulkBefore(List<sObject> lst, Map<Id, sObject> oldMap, Map<Id, sObject> newMap);
        void bulkAfter(List<sObject> lst, Map<Id, sObject> oldMap, Map<Id, sObject> newMap);
        void beforeInsert(SObject so);
        void beforeUpdate(SObject oldSo, SObject so);
        void beforeDelete(SObject so);
        void afterInsert(SObject so);
        void afterUpdate(SObject oldSo, SObject so);
        void afterDelete(SObject so);
        void afterUndelete(SObject so);
        void andFinally();
        void stop();
    }

    public virtual class TriggerHandler implements ITriggerHandler {

        public String instanceName;
        public TriggerManager.triggerEventType hndlEvent;
        public Schema.sObjectType recType;
        public Integer stackIndex;
        public Integer stackDepth;
        public Integer numRecords;
        public Datetime timestampStart;

        public TriggerHandler(String instance_Name, Schema.sObjectType soType) {
            this.instanceName = instance_Name;
            this.recType = soType;
            initLogs();
        }

        private void initLogs() {
            if (Trigger.isExecuting) {
                this.numRecords = trigger.new != null ? trigger.new.size() : trigger.old.size();
                if      (Trigger.isInsert && Trigger.isBefore)  hndlEvent = triggerEventType.BeforeInsert;
                else if (Trigger.isInsert && Trigger.isAfter)   hndlEvent = triggerEventType.AfterInsert;
                else if (Trigger.isUpdate && Trigger.isBefore)  hndlEvent = triggerEventType.BeforeUpdate;
                else if (Trigger.isUpdate && Trigger.isAfter)   hndlEvent = triggerEventType.AfterUpdate;
                else if (Trigger.isDelete && Trigger.isBefore)  hndlEvent = triggerEventType.BeforeDelete;
                else if (Trigger.isDelete && Trigger.isAfter)   hndlEvent = triggerEventType.AfterDelete;
                else if (Trigger.isundelete)                    hndlEvent = triggerEventType.AfterUndelete;

                if (showTriggerDebug) UTIL.log( instanceName + ': trigger event: ' + hndlEvent.Name() + ' # records: ' + this.numRecords );
                if (showTriggerDebug && Trigger.new != null)         UTIL.log('Trigger.new: ' + Trigger.new );
                if (showTriggerDebug && Trigger.newMap != null )     UTIL.log('Trigger.newMap ' + Trigger.newMap );
                if (showTriggerDebug && Trigger.old != null)         UTIL.log('Trigger.old: ' + Trigger.old );
                if (showTriggerDebug && Trigger.oldMap != null )     UTIL.log('Trigger.oldMap ' + Trigger.oldMap );
            } else {
                // used for testing purposes
                hndlEvent = triggerEventType.BeforeInsert;
            }
        }

        public void start() {
            pushStack(this);
        }
        public void stop() {
            popStack(this);
        }

        // virtual method templates
        public virtual void bulkBefore(List<sObject> lst, Map<Id, sObject> oldMap, Map<Id, sObject> newMap) {
            if (showTriggerDebug) UTIL.log('Entered bulkBefore');
        }
        public virtual void bulkAfter(List<sObject> lst, Map<Id, sObject> oldMap, Map<Id, sObject> newMap)    {
            if (showTriggerDebug) UTIL.log('Entered bulkAfter');
        }
        public virtual void beforeInsert(SObject so)                                                        {
            if (showTriggerDebug) UTIL.log('No trigger logic implemented for event: ' + hndlEvent.Name() + '. Inserting sObject: ' + so);
        }
        public virtual void beforeUpdate(SObject oldSo, SObject so)                                         {
            if (showTriggerDebug) UTIL.log('No trigger logic implemented for event: ' + hndlEvent.Name() + '. Updating sObject: ' + so);
        }
        public virtual void beforeDelete(SObject so)                                                        {
            if (showTriggerDebug) UTIL.log('No trigger logic implemented for event: ' + hndlEvent.Name() + '. Deleting sObject: ' + so);
        }
        public virtual void afterInsert(SObject so)                                                         {
            if (showTriggerDebug) UTIL.log('No trigger logic implemented for event: ' + hndlEvent.Name() + '. Inserted sObject: ' + so);
        }
        public virtual void afterUpdate(SObject oldSo, SObject so)                                          {
            if (showTriggerDebug) UTIL.log('No trigger logic implemented for event: ' + hndlEvent.Name() + '. Updated sObject: ' + so);
        }
        public virtual void afterDelete(SObject so)                                                         {
            if (showTriggerDebug) UTIL.log('No trigger logic implemented for event: ' + hndlEvent.Name() + '. Deleted sObject: ' + so);
        }
        public virtual void afterUndelete(SObject so)                                                       {
            if (showTriggerDebug) UTIL.log('No trigger logic implemented for event: ' + hndlEvent.Name() + '. Undeleted sObject: ' + so);
        }
        public virtual void andFinally() {}
    }

    public class TriggerException extends Exception {}

    public static void pushStack(TriggerManager.TriggerHandler handler) {
        handler.stackIndex = triggerStackIndex++;
        if (handler.hndlEvent.name().startswith('Before')) triggerStackDepth++;
        TriggerStack.put(handler.stackIndex, handler);
        handler.stackDepth = triggerStack.size();
        toStackLog(handler, '>>');
    }

    public static void popStack(TriggerManager.TriggerHandler handler) {
        triggerStack.remove(handler.stackIndex);
        toStackLog(handler, '<<');
        if (handler.hndlEvent.name().startswith('After')) {
            triggerStackDepth--;
            if (showStackLog) printStackLog();
        }
    }

    public static void printStackLog() {
        UTIL.log(triggerStackLog);
    }

    public static void toStackLog(TriggerManager.TriggerHandler handler, String action) {
        String logmsg = '';
        for (Integer d = 0; d<triggerStackDepth-1; d++) logmsg += '|_____';
        logmsg += handler.stackIndex +'_'+handler.instanceName + ' ['+ action + handler.hndlEvent.name()+']   #' + handler.numRecords +' Rec ' +  UTIL.limitRow() +'\n';
        triggerStackLog += logmsg;
    }

    // BYPASS
    // check of bypass (from custom config setting 'DisabledTriggerHandlers') is set for given handler
    private static Boolean isTriggerHandlerDisabledForType(Type handlerType) {
        Datetime lastMod = UTIL.getConfigLastModified('DisabledTriggerHandlers'); // last modified
        if (lastMod == null) return FALSE;

        Decimal hoursSinceLastMod = (Decimal) ( Datetime.now().getTime()/1000 - lastMod.getTime()/1000 )/3600; // in hours
        if(hoursSinceLastMod >= 8) {
            return FALSE; // 8h timeout for trigger handler inactivity
        }
        String disabledTriggerHandlers = UTIL.getConfig('DisabledTriggerHandlers');
        if(disabledTriggerHandlers == null || disabledTriggerHandlers == '') {
            return FALSE;
        }
        Set<String> disabledTHSet = new Set<String>(disabledTriggerHandlers.split(';'));
        for(String disabledTH : disabledTHSet) {
            if(handlerType.getName() == disabledTH && (UserInfo.getProfileId().contains(GW_User.ADMINPROFILEID) == TRUE)) {
                UTIL.log('TRIGGER HANDLER DISABLED FOR: ' + handlerType.getName() + '. BY: ' + UserInfo.getUserName());
                return TRUE;
            }
        }
        return FALSE;
    }
}