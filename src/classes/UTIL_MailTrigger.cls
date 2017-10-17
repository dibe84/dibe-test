public class UTIL_MailTrigger {
    public static Map<String, MailTrigger__c> mailTriggerCache {
        get {
            if (mailTriggerCache == null) {
                mailTriggerCache = new Map<String, MailTrigger__c>();
                List<MailTrigger__c> mailTriggers = (List<MailTrigger__c>) GW_sObject.queryRecords('MailTrigger__c', '');
                for (MailTrigger__c mt : mailTriggers) {
                    mailTriggerCache.put(mt.Id, mt);
                }
            }
            return mailTriggerCache;
        }
        private set;
    }
    
    public static List<MailTrigger__c> getMailTriggerByObjectName(String objectName) {
        List<MailTrigger__c> result = new List<MailTrigger__c>();
        for (MailTrigger__c mt : mailTriggerCache.values()) {
            if (mt.Object__c == objectName) {
                result.add(mt);
            }
        }
        return result;
    }
    
    
    public UTIL_MailTrigger(Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        // This will not run for input directly done by community users as they cannot see 'WhoId' on Task, maybe more?
        if (UserInfo.getProfileId() != GW_User.getProfileIdByName('Customer Community User')) {
            try {
            //UTIL.logErrors('MailTrigger start');
            String sObjName;
            sObject so;
            if (oldMap != null) so = oldMap.values().get(0);
            if (so != null) sObjName = so.getSObjectType().getDescribe().getName();
            List<MailTrigger__c> mailTriggers = getMailTriggerByObjectName(sObjname);
            Map<Id,Map<Id,Set<MailTrigger__c>>> recordToContactToEmailTemplatesToSend = new Map<Id,Map<Id,Set<MailTrigger__c>>>();
            
            //UTIL.logErrors('MailTrigger triggers: ' + mailTriggers);
            
            Set<Id> contactIds = new Set<Id>();
            Set<Id> sObjectIds = newMap.keySet();
            Set<String> fromAddresses = new Set<String>();
            List<String> emailTemplateNames = new List<String>();
    
            Map<MailTrigger__c, List<Id>> hitIds = new Map<MailTrigger__c, List<Id>>();
            for (MailTrigger__c mt : mailTriggers) {
                List<Id> mapItem = hitIds.get(mt);
                if (mapItem == null) {
                    mapItem = new List<Id>();
                }
                for (Id sObjectId : newMap.keySet()) {
                    if (UTIL_MailTrigger.fieldEquals(newMap.get(sObjectId), mt.ConditionField__c, mt.ConditionValue__c)) {
                        if (UTIL_MailTrigger.checkBlocked(newMap.get(sObjectId), mt.BlockingField__c) == false) {
                            if (UTIL_MailTrigger.hasFieldChangedFromOldToNew(oldMap.get(sObjectid), newMap.get(sObjectId), mt.Field__c, mt.OldValue__c, mt.NewValue__c)) {
                                mapItem.add(sObjectId);
                                // First lets see if this would hit any triggers, if not we remove it from the map...
                                Id contactId = UTIL_MailTrigger.getContactId(newMap.get(sObjectId), mt.ContactIDField__c);
                                if (contactId != null) {
                                    contactIds.add(contactId);
                                }
                     		}
                     	}
                    }
                    
                }
                emailTemplateNames.add(mt.EmailTemplate__c);
                fromAddresses.add(mt.FromAddress__c);
                hitIds.put(mt, mapItem);
            }
                
            Set<Id> actualsObjectIds = new Set<Id>();                
            for (MailTrigger__c mt : hitIds.keySet()) {
            	actualsObjectIds.addAll(hitIds.get(mt));
            }
                
            if (actualsObjectIds.size() == 0) {
            	return;
            }
            
            //UTIL.logErrors('MailTrigger emailTemplateNames: ' + emailTemplateNames);
            
            Map<String,Id> senderEmailMap = new Map<String,Id>();
                        
            Map<String,String> emailTemplateNameToDeveloperName = new Map<String,String>();
            Map<String,String> emailTemplateDeveloperNameToName = new Map<String,String>();
            Map<String, Id> emailTemplateNameToIdMap = new Map<String, Id>();
            for (EmailTemplate et : UTIL_Email.emailTemplateCache.values()) {
                emailTemplateNameToIdMap.put(et.DeveloperName, et.Id);
                emailTemplateNameToDeveloperName.put(et.Name, et.DeveloperName);
                emailTemplateDeveloperNameToName.put(et.DeveloperName, et.name);
            }
            
            Map<Id, Task> existingTaskMap = new Map<Id, Task>([SELECT Id, WhoId, WhatId FROM Task WHERE WhoId IN :contactIds AND WhatId IN :actualsObjectIds]);
            
            //UTIL.logErrors('MailTrigger existingTaskmap: ' + existingTaskMap);
            
            List<Contact> contactsWithEmailStatuses = [SELECT Name, (SELECT Id, EmailTemplateName, TimesOpened, TaskId FROM EmailStatuses WHERE TaskId IN :existingTaskMap.keyset()) FROM Contact WHERE Id IN :contactIds];
            Map<Id, Map<Id,Set<String>>> sentEmailTemplatesMap = new Map<Id, Map<Id,Set<String>>>(); // Contact Id to Map<Record Id, Set<EmailTemplateName>>
            
            //UTIL.logErrors('MailTrigger contactsWithEmailStatuses: ' + contactsWithEmailStatuses);
    
            for (Contact c : contactsWithEmailStatuses) {            
                if (c.EmailStatuses != null) {
                    Map<Id,Set<String>> recordToTemplateMap = sentEmailTemplatesMap.get(c.Id);
                    if (recordToTemplateMap == null) {
                        recordToTemplateMap = new Map<Id,Set<String>>();
                    }
                    for (EmailStatus es : c.EmailStatuses) {
                        Task t = existingTaskmap.get(es.TaskId);
                        if (t != null) {
                            Id recordId = t.WhatId;
                            Set<String> sentEmailTemplates = recordToTemplateMap.get(recordId);
                            if (sentEmailTemplates == null) {
                                sentEmailTemplates = new Set<String>();
                            }
                            sentEmailTemplates.add(es.EmailTemplateName);                    
                            recordToTemplateMap.put(recordId, sentEmailTemplates);
                            sentEmailTemplatesMap.put(c.Id, recordToTemplateMap);
                        }
                    }
                }
            }
            
            //UTIL.logErrors('MailTrigger sentEmailTemplatesMap: ' + sentEmailTemplatesMap);
            
            //UTIL.logErrors('MailTrigger recordToContactToEmailTemplatesToSend: ' + recordToContactToEmailTemplatesToSend);
           
            for (MailTrigger__c mt : mailTriggers) {
                for (Id sObjectId : actualsObjectIds) {
                    if (UTIL_MailTrigger.fieldEquals(newMap.get(sObjectId), mt.ConditionField__c, mt.ConditionValue__c)) {
                        //UTIL.logErrors('MailTrigger fieldEquals is true');
                        if (UTIL_MailTrigger.checkBlocked(newMap.get(sObjectId), mt.BlockingField__c) == false) {
                            if (UTIL_MailTrigger.hasFieldChangedFromOldToNew(oldMap.get(sObjectid), newMap.get(sObjectId), mt.Field__c, mt.OldValue__c, mt.NewValue__c)) {
                                //UTIL.logErrors('MailTrigger fieldChangedFromOldToNew is true');
                                Id contactId = UTIL_MailTrigger.getContactId(newMap.get(sObjectId), mt.ContactIDField__c);
                                Map<Id,Set<String>> sentEmailTemplatesForContact = sentEmailTemplatesMap.get(contactId);
                                if (sentEmailTemplatesForContact == null) {
                                    sentEmailTemplatesForContact = new Map<Id,Set<String>>();
                                }
                                //UTIL.logErrors('MailTrigger sentEmailTemplatesForContact is not null: ' + sentEmailTemplatesForContact);
                                Set<String> sentEmailTemplates = sentEmailTemplatesForContact.get(sObjectId);
                                if (sentEmailTemplates == null) {
                                    sentEmailTemplates = new Set<String>();
                                }
                                //UTIL.logErrors('MailTrigger sentEmailTemplates is not null: ' + sentEmailTemplates);
                                if (!sentEmailTemplates.contains(emailTemplateDeveloperNameToName.get(mt.EmailTemplate__c))) {
                                    UTIL.logErrors('MailTrigger sentEmailTemplates does not contain EmailTemplate');
                                    Map<Id,Set<MailTrigger__c>> contactToEmailTemplatesToSend = recordToContactToEmailTemplatesToSend.get(sObjectId);
                                    if (contactToEmailTemplatesToSend == null) {
                                        contactToEmailTemplatesToSend = new Map<Id,Set<MailTrigger__c>>();
                                    }
                                    Set<MailTrigger__c> emailTemplatesToSend = contactToEmailTemplatesToSend.get(contactId);
                                    if (emailTemplatesToSend == null) {
                                        emailTemplatesToSend = new Set<MailTrigger__c>();
                                    }
                                    emailTemplatesToSend.add(mt);
                                    sentEmailTemplates.add(mt.EmailTemplate__c);
                                    //UTIL.logErrors('MailTrigger adding mt: ' + mt);
                                    contactToEmailTemplatesToSend.put(contactId, emailTemplatesToSend);
                                    recordToContactToEmailTemplatesToSend.put(sObjectid, contactToEmailTemplatesToSend);
                                    sentEmailTemplatesForContact.put(sObjectId, sentEmailTemplates);
                                    sentEmailTemplatesMap.put(contactId, sentEmailTemplatesForContact);
                                }
                            }
                        }
                    }
                }
            }
            
            List<Messaging.SingleEmailMessage> mailsToSend = new List<Messaging.SingleEmailMessage>();
            for (Id sObjectId : recordToContactToEmailTemplatesToSend.keySet()) {
                for (Id contactId : recordToContactToEmailTemplatesToSend.get(sObjectId).keySet()) {
                    for (MailTrigger__c mt : recordToContactToEmailTemplatesToSend.get(sObjectId).get(contactId)) {
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        Id templateId = emailTemplateNameToIdMap.get(mt.EmailTemplate__c);
                        mail.setTemplateId(templateId);
                        mail.setOrgWideEmailAddressId(UTIL_Email.orgWideEmailAddressCache.get(mt.FromAddress__c).Id);
                        mail.setWhatId(sObjectId);
                        mail.setTargetObjectId(contactId);
                        mailsToSend.add(mail);
                    }
                }
            }
            
            Messaging.sendEmail(mailsToSend);
            
            //UTIL.logErrors('MailTrigger end');
                
            } catch (Exception e) {
                //UTIL.logErrors('MailTrigger Exception Thrown: ' + e.getMessage() + e.getStacktraceString());
            }
            
        } else {
            UTIL.log('MailTrigger skiiped because of community profile');
        }
    }
    
    private static Boolean hasFieldChangedFromOldToNew(sObject oldSo, sObject newSo, String field, String oldValue, String newValue) {
        String sObjName = newSo.getSObjectType().getDescribe().getName();
        if (!GW_sObject.fieldExists(sObjName, field)) {
            throw new UTIL.CustomException('Invalid field specified: ['+sObjName+'.'+field+']');
        } else {
            String fieldValue = (String.valueOf(newSo.get(field)) == '') ? null : String.valueOf(newSo.get(field));
            String oldFieldValue = (String.valueOf(oldSo.get(field)) == '') ? null : String.valueOf(oldSo.get(field));
            if (oldFieldValue == oldValue) {
                if (fieldValue == newValue) {
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        }
        return false;
    }

    private static Boolean fieldEquals(sObject so, String field, String value) {
        //UTIL.logErrors('MailTrigger running fieldEquals: ' + field + ' = ' + value);
        String fieldValue = (String.valueOf(so.get(field)) == '') ? null : String.valueOf(so.get(field));
        if (fieldValue == value) {
            //UTIL.logErrors('MailTrigger fieldEquals true');
            return true;
        } else {
            //UTIL.logErrors('MailTrigger fieldEquals false ' +value + ' != ' + fieldvalue);
            return false;
        }
    }
    
    private static Id getContactId(sObject so, String field) {
        String fieldValue = (String.valueOf(so.get(field)) == '') ? null : String.valueOf(so.get(field));
        if (fieldValue != '' && fieldValue != null) {
            return Id.valueOf(fieldValue);
        } else {
            return null;
        }
    }
    
    private static Boolean checkBlocked(sObject newSo, String field) {
        if (field == null) {
            return false;
        } else {
            String sObjName = newSo.getSObjectType().getDescribe().getName();
            if (!GW_sObject.fieldExists(sObjName, field)) {
                throw new UTIL.CustomException('Invalid field specified: ['+sObjName+'.'+field+']');
            } else {
                Boolean value = (Boolean) newSo.get(field);
                return value;
            }
        }
    }
    
}