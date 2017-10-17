virtual public with sharing class c_BaseController {
    
    public CommunityConfiguration__c config { get; set; }
    public User currentUser { get; set; }
    public Contact currentContact { get; set; }
    public Account currentAccount { get; set; }
    public Boolean isValidLogin { get; set; }
    
    public c_BaseController() {
        this.initialize();
    }
    
    virtual void initialize() {
        this.config = this.fillConfig();
        this.populateCommonObjects();
    }
    
    private CommunityConfiguration__c fillConfig() {
        return getConfig();
    }
    
    private void populateCommonObjects() {
        // We assume the 'ContactID' on User is filled..
        this.currentUser = [SELECT Id, ContactId, Username, Email FROM User WHERE Id = :UserInfo.getUserId()];
        this.currentContact = (Contact) GW_sObject.queryRecord('Contact', this.currentUser.ContactId);
        this.currentAccount = (Account) GW_sObject.queryRecord('Account', this.currentContact.AccountId);
        this.isValidLogin = (this.currentContact == null || this.currentAccount == null ? false : true);
    }
    
    public static CommunityConfiguration__c getConfig() {        
        return c_Common.getConfig();
    }
    
    public void debug(Object o) {
        String s = ('' + o).replaceAll('\n', '[NEWLINE]');
        throw new CommunityException(s);
    }
    
    public void debugJSON(Object o) {
        String s = ('' + JSON.serializePretty(o)).replaceAll('\n', '[NEWLINE]');
        throw new CommunityException(s);
    }
    
    public class CommunityException extends Exception {}
}