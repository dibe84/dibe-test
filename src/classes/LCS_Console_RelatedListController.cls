public with sharing class LCS_Console_RelatedListController {

	public static final String RL_WRONG_OBJECT 	= 'Related List is not supported for this object tab';
	public static final String RL_NO_CONTACT 	= 'This record does not have related contact for the related list';
	
	public String objectId {get;set{
		initRelatedList(value);
	}}

	public Case relCase {get;set;}
	private void initRelatedList(Id objId){
		
		String objName = String.valueOf(objId.getsobjecttype());

		String parentContactId; 
		if(parentObjMap.containsKey(objName)){
			parentContactId = parentObjMap.get(objName);
		}else{
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, RL_WRONG_OBJECT));
    		return;
		}
		
		String queryString = 'Select ' + parentContactId + ' From ' + String.escapeSingleQuotes(objName) + ' Where Id = :objId';
		sObject rec = Database.query(queryString).get(0);
		String parentVal = String.valueOf(rec.get(parentContactId));
		System.debug('parentVal --- ' + parentVal);
		System.debug('rec --- ' + rec);

		if(parentVal == null || (Test.isRunningTest() && TST_LCS_Console_RelatedListController.noContactError)){
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, RL_NO_CONTACT));
    		return;
		}
		relCase = new Case(ContactId = parentVal);
	}

	private Map<String, String> parentObjMap = new Map<String, String>{
		'Case' 					=> 'ContactId',
		'CallLog__c'			=> 'ContactId__c',
		'LiveChatTranscript' 	=> 'ContactId'
		/*'SocialPost' 			=> 'WhoId'*/
	};

}