public with sharing class PGC_FreespeePopup {
	
	public Account curAcc { get; set; }
	public Boolean isEnable { get; set; }
	public String err { get; set; }
	public String trackedNumber {  get; set; }
	public String redirectURL { get; set; }
	
    public PGC_FreespeePopup(ApexPages.StandardController ctrl){
        curAcc = GW_Account.getRecord(ctrl.getRecord().Id);
        isEnable = curAcc.Member_Id__c == 'ECITA';
        redirectURL = System.URL.getSalesforceBaseURL().toExternalForm() + '/' + curAcc.id;
    }
    
    public PageReference doCreate() {
    	err = WSC_Freespee.trackThisAccountPhone(curAcc.id);
    	trackedNumber = [select CallTrackingPhoneNumber__c from Account where id = :curAcc.id].CallTrackingPhoneNumber__c;
    	return null;
    }
    
    public PageReference doDelete() {
    	err = WSC_Freespee.unTrackThisAccountPhone(curAcc.id);
    	return null;
    }
}