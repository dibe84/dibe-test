public with sharing class ETC_GTAUSLeadAutoResponse {
    public String uId {get;set;}
	public string approvedComment {
		get{return getApproveComment();}
		set;
	}
	
	public String currentDomain {get;set;}
	public String signatureLogoId {get;set;}
	public String headerLogoId {get;set;}
	
    public ETC_GTAUSLeadAutoResponse(){
    	currentDomain = String.valueOf(System.URL.getSalesforceBaseURL().toExternalForm());
    	signatureLogoId = getDocumentIdByName('GT_Australia_Email_Template_Signature_Logo');
    	headerLogoId = getDocumentIdByName('GT_Australia_Email_Template_Header_Logo');
    }
    public String getApproveComment(){
    		String ac = '';
    		if(uId != null){
    			String wc = ' ActorId = \'' + uId +'\' ORDER BY SystemModStamp DESC LIMIT 1 ';
    			List<ProcessInstanceStep> pis = (List<ProcessInstanceStep>) GW_sObject.queryRecords('ProcessInstanceStep', wc);
    			if(pis != null && pis.size() > 0) approvedComment = pis.get(0).Comments;
    		}
    		return ac;
    }
    public String getDocumentIdByName(String dName){
    	List<Document> doc = new List<Document>();
    	doc = [Select Id From Document where DeveloperName =:dName limit 1];
    	return (doc == null || doc.isEmpty())? '':doc.get(0).Id;
    }
}