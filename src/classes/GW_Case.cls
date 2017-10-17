public with sharing class GW_Case {

    private static final Schema.sObjectType GW_BASEOBJECT = Case.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'Case';
    private static final Set<String> ECGDK_CS_ORIGIN_CHANNEL = new Set<String>{'Bilbasen', 'DBA'};

	//////////////////////////////////////////////////////////////////////////////////////////////////////
	// public query methods
	//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Id recordTypeIdECGDKCS {
        get {
            if (recordTypeIdECGDKCS == null) {
                recordTypeIdECGDKCS = ((List<RecordType>)GW_sObject.queryRecords('RecordType',' SobjectType=\'Case\' And Name =\'ECGDKCS\''))[0].Id;
            }
            return recordTypeIdECGDKCS;
        } set;
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Case           getRecord(Id id)           { return (Case) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<Id,Case>   getMap(Set<Id> ids)        { return new Map<Id,Case>( getList(ids) ); }
    public static List<Case>     getList(Set<Id> ids)       { return (List<Case>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }

	public static void validatePhoneNumber(Case cas, Set<String> phoneFields) {
		if(cas == null || phoneFields == null || (cas.OriginChannel__c != null && ECGDK_CS_ORIGIN_CHANNEL.contains(cas.OriginChannel__c))) return;
		for(String phoneField : phoneFields) {
			String fieldVal = (String) (cas.get(phoneField));
			fieldVal = (fieldVal == null ? '' : fieldVal.trim());
			if(fieldVal.indexOf('+') == -1 || fieldVal.lastIndexOf('+') != 0) {
				UTIL.throwError(phoneField + ' number should start with \'+\' sign, please update with correct value.');
			}
		}
	}
//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list related records
//////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////
// helper methods
//////////////////////////////////////////////////////////////////////////////////////////////////////

    public static void initialNewCases(case[] newCases) {
        List<Case> orphanCases = new List<Case>();
        for(case ca : newCases) {
            if (recordTypeIdECGDKCS != ca.RecordTypeId) continue;
            // This is fix for CD-3861. 
    		// It is related to adding + symbol before telephone number 
            String fieldVal = ca.SuppliedPhone;
	        fieldVal = (fieldVal == null ? '' : fieldVal.trim());
	        if(fieldVal.indexOf('+') == -1 || fieldVal.lastIndexOf('+') != 0) {
	        	ca.SuppliedPhone = '+' + fieldVal;
	        }
            if(ca.ContactId == null) {
                orphanCases.add(ca);
            }
        }
        // Set ContactId
        if(!orphanCases.isEmpty()) {
            GW_Case.setContactForOrphanCases(orphanCases);
        }
    }

    // get ECG Member Acc Id CD-2586 15-06-2017
    private static Id getECGMemberAccountId(String caseMemberId) {
        String whereClause = 'Where MemberId__c IN :param1';
        List<Member__c> ecgMemberInit = (List<Member__c>)GW_sObject.queryRecords('Member__c', null, whereClause, new Set<String>{caseMemberId}, null, 'LIMIT 1');
        Id ecgAccId = (!ecgMemberInit.isEmpty())? ecgMemberInit.get(0).Account__c : null;
        return ecgAccId;
    }

    private static void setContactForOrphanCases(case[] orphanCases) {
        Set<String> caseEmails = new Set<String>();
        for(Case ca : orphanCases) {
            caseEmails.add(ca.SuppliedEmail);
        }

        Map<String, Id> mapEmail2ConId = new Map<String, Id>();
        for(Contact con : (List<Contact>) GW_sObject.queryRecords('Contact', 'Email', caseEmails)) {
            mapEmail2ConId.put(con.Email, con.Id);
        }

        Contact[] newContacts = new List<Contact>();
        Id mbAccId;
        for(Case ca : orphanCases) {
            if(!mapEmail2ConId.containsKey(ca.SuppliedEmail) && ca.SuppliedName != null) {
                if(mbAccId == null && ca.MemberId__c != null){
                    mbAccId = getECGMemberAccountId(ca.MemberId__c);
                }
				// This condition will check if phone number is valid or not(fix for #CD-3931 and CD-3887)
                // If phone number is not valid then it will not create cotnact we are not creating contact because 
                // Ph0ne validation is again inforce on contact object and to avoid further failure we are restricting here itself
                if(!isValidPhone(String.ValueOf(ca.SuppliedPhone))) continue;
                
                newContacts.add(new Contact(
                    Email = ca.SuppliedEmail, LastName = ca.SuppliedName, FirstName = '_', 
                    Phone = ca.SuppliedPhone, MemberUnitId__c = ca.MemberUnitId__c, AccountId = mbAccId
                ));
                mapEmail2ConId.put(ca.SuppliedEmail, null);
            }
        }
        if(!newContacts.isEmpty()) {
            insert newContacts;
            for(Contact con : newContacts) {
                mapEmail2ConId.put(con.Email, con.Id);
            }
        }
        for(case ca : orphanCases) {
            ca.ContactId = mapEmail2ConId.get(ca.SuppliedEmail);
        }
    }
    
    public static void linkSelfToLiveChatTranscript(case[] newCases){
        Map<String, Case> mCaseByKey = new Map<String, Case>();
        for(case ca : newCases) {
            if (String.isNotEmpty(ca.KeyToLiveChatTranscript__c)) {
                mCaseByKey.put(ca.KeyToLiveChatTranscript__c, ca);
            }
        }
        List<LiveChatTranscript> lctToLinked = new List<LiveChatTranscript>();
        for(LiveChatTranscript lct : (List<LiveChatTranscript>) GW_sObject.queryRecords('LiveChatTranscript', 'KeyToCase__c', mCaseByKey.keySet())) {
            if (lct.CaseId == null && String.isNotEmpty(lct.KeyToCase__c) && mCaseByKey.containsKey(lct.KeyToCase__c)) {
                lct.CaseId = mCaseByKey.get(lct.KeyToCase__c).Id;
                lctToLinked.add(lct);
            }
        }
        if (!lctToLinked.isEmpty()) {
             update lctToLinked;
        }
    }
    
     /**
     * @Desc: To create new Case and associates to Account/Contact
     * @param: accountId is Account ID
     * @param: contactId is Contact ID
     * @param: origin is case origin
     * @param: fireAR to identify whether case assignment rule need to fire or not
     * @return: a case object
     */
    public static Case createCase(String accountId, String contactId, String origin, Boolean fireAR) {
        //create case
        Case newcase = new Case();
        //newcase.ParentId = newacc.Id;
        newcase.Origin = origin;
        newcase.AccountId = accountId;
        newcase.ContactId = contactId;
        
        //in case assignment rule is required
        if ( fireAR ) {
            //Get active case assignment rule
            AssignmentRule assignmentRule = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true limit 1];
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.assignmentRuleId = assignmentRule.Id;
            //Set assingment rule in DMLOption to fire active case assignment rule on Case creation
            newcase.setOptions(dmo);
        }
        
        return newcase;
    }

    // create case and task for every call log accepted by the agent
    // 28/07/2017 Marina
    public static void createCasesFromCallLogs(List<CallLog__c> soLst, Map<Id, CallLog__c> oldSoMap) {
        Map<Id, Case> casesToInsert = new Map<Id, Case>();
        Map<Id, Task> tasksToInsert = new Map<Id, Task>();

        for (CallLog__c callLog : soLst) {

            CallLog__c oldCallLog = oldSoMap.get(callLog.Id);

            if (callLog.OwnerId.getSObjectType() == User.sObjectType && callLog.CaseId__c == null 
                && callLog.Status__c != oldCallLog.Status__c &&  oldCallLog.Status__c == 'Open' && callLog.Status__c == 'In Progress') {
                
                Case c = createCaseFromCallLog(callLog);
                casesToInsert.put(callLog.Id, c);
                tasksToInsert.put(callLog.Id, createCallLogActivityForCase(c));
            }
        }

        try {
            if (!casesToInsert.isEmpty()) {
                Database.insert(casesToInsert.values());

                List<CallLog__c> callLogsToUpdate = new List<CallLog__c>();
                for (Id clId : casesToInsert.keySet()) {
                    Id caseID = casesToInsert.get(clId).Id;
                    System.debug(caseID);

                    if (caseID != null) {
                        tasksToInsert.get(clId).WhatId = caseID;
                        System.debug(tasksToInsert.get(clId).WhatId);

                        callLogsToUpdate.add(new CallLog__c(Id = clId, Status__c = 'Closed', CaseId__c = caseID));
                    }
                }
                System.debug(tasksToInsert);
                System.debug(callLogsToUpdate);
                Database.insert(tasksToInsert.values());
                Database.update(callLogsToUpdate);
            }

        } catch (Exception e) {
            System.debug('GW_Case.createCasesFromCallLogs : ' + e.getMessage());
        }
    }

     public static List<String>  createCaseFromCallLog(String id) {
        try {
            List<CallLog__c> lstCallRecords = GW_sObject.queryRecords('CallLog__c',' id=\''+ id + '\' '); 
            if (lstCallRecords.isEmpty() && !Test.isRunningTest()) return new List<String>{'Error while processing, please try again.'};
            CallLog__c callLog = lstCallRecords.get(0);
            String result = 'Case is already created for this Call Log.';
            if (callLog.CaseId__c == null) {
                Case c = createCaseFromCallLog(callLog);
                insert c;
                Task t = createCallLogActivityForCase(c);
                insert t;

                callLog.Status__c = 'Closed';
                callLog.CaseId__c = c.Id;
                update callLog;
                result = 'Case has been created successfully!';
            } 
            return new List<String>{ result, callLog.CaseId__c};
            
        } catch (Exception e) {
            return new List<String>{e.getMessage() };
        }
    }

    private static Case createCaseFromCallLog(CallLog__c cl) {
        return GW_Case.createCaseFromCallLog(cl, null);
    }
    
    private static Case createCaseFromCallLog(CallLog__c cl, Id ownerId) {
        Case c = new Case();
        c.CallMeBack__c = true;
        c.ContactId = cl.ContactId__c;
        c.RecordTypeId = recordTypeIdECGDKCS;
        c.Subject = cl.Subject__c;
        c.Priority = cl.Priority__c;
        c.OwnerId = ownerId != null ? ownerId : UserInfo.getUserId();
        c.MemberId__c = cl.MemberId__c;
        c.MemberUnitId__c = cl.MemberUnitId__c;
        c.Description = cl.Description__c;
        c.SuppliedEmail = cl.SuppliedEmail__c;
        c.SuppliedName = cl.SuppliedName__c;
        c.SuppliedPhone = cl.SuppliedPhone__c;
        c.Origin = cl.Origin__c;
        c.OriginChannel__c = cl.OriginChannel__c;
        c.Category__c = cl.Category__c;
        return c;
    }

    private static Task createCallLogActivityForCase(Case cs){
        Task t = new Task();
        t.Subject = 'Call Back';
        t.WhatId = cs.id != null ? cs.id : null;
        t.WhoId = cs.ContactId;
        t.TaskSubtype = 'Call';
        t.Status = 'Completed';
        t.ActivityDate = System.today();
        return t;
    }
    
    //This is fix for CD-3887 
    private static boolean isValidPhone(String phoneNo){
        boolean isValid = false;
        if(String.isEmpty(phoneNo)) return false;
        
        Pattern isNumbers   =   Pattern.Compile('^[0-9]+$');
        phoneNo             =   phoneNo.substring(1, phoneNo.length()).trim();
        Matcher phoneMatch  =   isnumbers.matcher(phoneNo);

        if (phoneMatch.Matches() && phoneNo.length() >= 8) {
            return true;
        } 
        return false;
    }
	
	
}