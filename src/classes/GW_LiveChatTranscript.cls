public with sharing class GW_LiveChatTranscript {

    private static final Schema.sObjectType GW_BASEOBJECT = LiveChatTranscript.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'LiveChatTranscript';
   

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // public query methods
    //////////////////////////////////////////////////////////////////////////////////////////////////////
   
//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    

//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list related records
//////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////////
// helper methods
//////////////////////////////////////////////////////////////////////////////////////////////////////

   
    
    
    public static void initialCaseId(List<LiveChatTranscript> lstTranscripts){
    	
        Map<String, LiveChatTranscript> mTranscriptByKey = new Map<String, LiveChatTranscript>();
        for(LiveChatTranscript transcript : lstTranscripts) {
            if (String.isNotEmpty(transcript.KeyToCase__c) && transcript.CaseId == null) {
                mTranscriptByKey.put(transcript.KeyToCase__c, transcript);
            }
        }
        List<LiveChatTranscript> lctToLinked = new List<LiveChatTranscript>();
        for(Case ca : (List<Case>) GW_sObject.queryRecords('Case', 'KeyToLiveChatTranscript__c', mTranscriptByKey.keySet())) {
        	String key = ca.KeyToLiveChatTranscript__c;
            if ( mTranscriptByKey.containsKey(key) && mTranscriptByKey.get(key).CaseId == null) {
               mTranscriptByKey.get(key).CaseId = ca.id;
            }
        }
       
    }
  
  
}