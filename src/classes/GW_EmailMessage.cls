///////////////////////////////////////////////////////////////////////////
// Class EmailMessage Gateway  --
//
// Used as a central location to manage interactions with the EmailMessage Object
//
// Author:  Jochem van den Heuvel
// Email:   jochemvandenheuvel@screenfields.nl
//
///////////////////////////////////////////////////////////////////////////
public with sharing class GW_EmailMessage
{
    private static final Schema.sObjectType GW_BASEOBJECT = EmailMessage.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'EmailMessage';
    private static final String GW_CASEOBJECTNAME = 'Case';
    private static final String EMAIL_REF_REGEX = '\\[ ref:(.*):ref \\]';
    private static String EMAIL_RE_FWD_REGEX = '';
    private static List<Case> toDeleteCases = new List<Case>();
	public static Map<Id,Schema.RecordTypeInfo> recordTypeMapById = Schema.SObjectType.Case.getRecordTypeInfosById();
//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static EmailMessage          getRecord(Id id)                    { return (EmailMessage) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,EmailMessage>  getMap(Set<id> ids)                 { return new Map<id,EmailMessage>( getList(ids) ); }
    public static List<EmailMessage>    getList(Set<id> ids)                { return (List<EmailMessage>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }
    public static List<EmailMessage>    getList(Set<Id> ids, List<String> additionalFields) { return (List<EmailMessage>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids, additionalFields); }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of parents(base object) from a list of child objects
//////////////////////////////////////////////////////////////////////////////////////////////////////
    

//////////////////////////////////////////////////////////////////////////////////////////////////////
//  Test Factory
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static List<Case> queryCaseRecords(Set<Id> caseIds) {
        return (List<Case>)GW_sObject.queryRecords(GW_CASEOBJECTNAME, caseIds, null, '');
    }
    
//////////////////////////////////////////////////////////////////////////////////////////////////////
// Custom logic
//////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     * CD-1036
     * Business (b2b) Support Process
     * Reopen the case if the customer send a reply within 10 days
     * Not allow reopening more than two times
     * For more than 10 days reply a new case shall be open
     */
    public static void reOpenCases(List<EmailMessage> lstInboundMsgs) {
        //Emails from form are being added to a reopen case (queue ECG Italy - Leads Kijiji) which is wrong
        String ignoreEmails = UTIL.getConfig('IgnoreCaseReopenEmails');
        ignoreEmails = ignoreEmails == null ? ''  : ignoreEmails;
        Set<String> ignoreEmailList = new Set<String>();
        List<String> skippedEmails = ignoreEmails.split(';');
        for (String ignorEmail : skippedEmails) {
            ignoreEmailList.add(ignorEmail);
        }
        List<EmailMessage> lstMsgs = new List<EmailMessage>();
        for (EmailMessage msg : lstInboundMsgs) {
            if (!ignoreEmailList.contains(msg.FromAddress)) {
                lstMsgs.add(msg);
            }
        }
        Configuration__c con = Configuration__c.getInstance('Email2CaseSubjectPattern');
        if(con != null){
            EMAIL_RE_FWD_REGEX = con.Value__c;
        }
        List<EmailMessage> toCheckByRefCases = reOpenCasesBySubject(lstMsgs);
        
        reOpenCasesByRefKey(toCheckByRefCases);
    }
    
    private static List<EmailMessage> reOpenCasesBySubject(List<EmailMessage> lstMsgs) {
        //Existing emails by Subject+EmailAddress
        Map<String, Case> existingCases = getPreviousCaseBySubject(lstMsgs);
        if(existingCases.isEmpty()) return lstMsgs;
        
        List<EmailMessage> toCheckByRefCases = new List<EmailMessage>();
        Map<String, Case> toRefreshCases = new Map<String, Case>();
        for (EmailMessage msg : lstMsgs) {
            String originSubject = getOriginSubject(msg.Subject);
            String keySubject = originSubject + msg.FromAddress;

            Case cs = (existingCases.containsKey(keySubject))? existingCases.get(keySubject) : null;
            System.debug(LoggingLevel.Info, 'Ex Case: ' + JSON.serialize(cs));

            if (cs != null) {
                if (!containsRefExp(msg.Subject)) {
                    toDeleteCases.add(new Case(Id = msg.ParentId));
                }
                setCaseReopenDetails(cs, msg.TextBody, originSubject);
                toRefreshCases.put(keySubject, cs);
                System.debug(LoggingLevel.Info, 'toUpdateCases: ' + JSON.serialize(toRefreshCases));
            } else {
                toCheckByRefCases.add(msg);
            }
        }
        upsert toRefreshCases.values();
        
        for (EmailMessage msg : lstMsgs) {
            String originSubject = getOriginSubject(msg.Subject);
            String keySubject = originSubject + msg.FromAddress;
            if (toRefreshCases.containsKey(keySubject)) {
                msg.ParentId = toRefreshCases.get(keySubject).Id;
            } 
        }
        return toCheckByRefCases;
    }
    
    private static void reOpenCasesByRefKey(List<EmailMessage> lstMsgs) {
        Set<Id> csIds = new Set<Id>();
        for (EmailMessage msg : lstMsgs) {
            csIds.add(msg.ParentId);
        }
        Map<Id, Case> mCase = GW_Case.getMap(csIds);
        Map<String, Case> toRefreshCases = new Map<String, Case>();
        for (EmailMessage msg : lstMsgs) {
            Case cs = mCase.get(msg.ParentId);
            if (isAcceptReopen(cs)) {
                setCaseReopenDetails(cs, msg.TextBody, cs.Subject);
                toRefreshCases.put(msg.ParentId, cs);
            } else if (cs.isClosed) {
                toRefreshCases.put(msg.ParentId, newCaseFormOrigin(cs, cs.Subject));
            }
        }
        upsert toRefreshCases.values();
        
        for (EmailMessage msg : lstMsgs) {
            if (toRefreshCases.containsKey(msg.ParentId)) {
                msg.ParentId = toRefreshCases.get(msg.ParentId).Id;
            } 
        }
    }
    
    public static void commitParentCases() {
        delete toDeleteCases;
    }
    
    public static Map<String, Case> getPreviousCaseBySubject(List<EmailMessage> lstMsgs) {
        Set<String> sBaseSubject = new Set<String>();
        Set<String> sRecentCreatedCase = new Set<String>();
        for (EmailMessage msg : lstMsgs) {
            String mSubject = getOriginSubject(msg.Subject);
            if(!String.isBlank(mSubject)){
                sBaseSubject.add('%' + mSubject + '%');
                if (msg.parentId != null && !containsRefExp(msg.Subject)) { 
                    sRecentCreatedCase.add(msg.parentId);
                }
            }
        }

        Map<String, Case> mcase = new Map<String, Case>();
        if(sBaseSubject.isEmpty()) return mcase;

        String whereClause = 'WHERE Subject LIKE :param1 AND ID NOT IN :param2';
        List<Case> existingCases = (List<Case>)GW_sObject.queryRecords(GW_CASEOBJECTNAME, null, whereClause, sBaseSubject, sRecentCreatedCase, 'Order By CreatedDate ASC');

        for (Case cs : existingCases) {
            String originSubject = getOriginSubject(cs.Subject);
            String keySubject = originSubject + cs.SuppliedEmail;
            if (isAcceptReopen(cs) || !cs.isClosed) {
                mcase.put(keySubject, cs);
            } else if (cs.isClosed) {
                mcase.put(keySubject, newCaseFormOrigin(cs, originSubject));
            }
        }
        return mcase;
    }
    
    private static Case newCaseFormOrigin(Case cs, String originSubject) {
        Case newCase = cs.clone(false);
        newCase.Subject = originSubject;
        newCase.ReopenedCount__c = 0;
        newCase.Status = 'New';
        return newCase;
    }
    
    private static void setCaseReopenDetails(Case cs, String textBody, String originSubject) {
        //Link correct case
        cs.ReopenedCount__c = cs.ReopenedCount__c == null ? 0 : cs.ReopenedCount__c;
        cs.Subject = originSubject; 
        cs.Description = String.isNotBlank(cs.OriginalDescription__c) ?  textBody +'\n\n'+  cs.OriginalDescription__c :  textBody ;
        //Re-open existing case
        if (cs.isClosed) {
            cs.ReopenedCount__c += 1;
            cs.Status = 'Reopen';
        }
    }
    
    private static Boolean isAcceptReopen(Case cs) {
        Integer reOpenCount = cs.ReopenedCount__c == null ? 0 : (Integer)cs.ReopenedCount__c;
        Boolean canReOpen = false;
		String rtName = '';
        Integer numberDaysDue;
        if (cs.IsClosed) {
            rtName = (recordTypeMapById.get(cs.RecordTypeId) != null) ? recordTypeMapById.get(cs.RecordTypeId).getName() : '';
            DateTime dT = cs.ClosedDate;
            numberDaysDue = Math.abs(Date.newInstance(dT.year(), dT.month(), dT.day()).daysBetween(System.today()));
            canReOpen = (rtName == 'ECGDKCS' || (rtName != 'ECGDKCS' && reOpenCount < 2)) ;
        }
        return (canReOpen && numberDaysDue < 10);
    }
    
    private static String getOriginSubject(String subject) {
        String subj = '';
        if(!String.isBlank(subject)){            
            subj = subject.replaceAll( EMAIL_REF_REGEX , '');
            subj = subj.replaceAll( EMAIL_RE_FWD_REGEX , '').trim();
        }
        System.debug('subject'+subj);
        return subj;
    }
    
    private static Boolean containsRefExp(String subject) {
        if(String.isBlank(subject)){
            return true;
        }
        String subj = subject.replaceAll( EMAIL_REF_REGEX , '');
        return subject != subj;
    }
}