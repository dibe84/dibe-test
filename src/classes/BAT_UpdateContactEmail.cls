/**
 * @createdDate: 03-10-2017
 * @desc: CD-3702 
 * 	   - The contact email addresses will be updated after the sandbox refresh. This means that upon the sandbox refresh, we will get errors.
 * 	   - The ideal solution would ensure that the email addresses are updated already when the sandbox gets refreshed.
 */
global class BAT_UpdateContactEmail implements Database.Batchable<sObject>, Database.Stateful{
	String whereClause;
	Integer i=0;
	public BAT_UpdateContactEmail(){
        whereClause = '(NOT Email like \'%@example.com\')';
	}
	
	global List<sObject> start(Database.BatchableContext BC){
    	return GW_sObject.queryRecords('Contact', whereClause);
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> scope){  
        UTIL.log('Executing BAT_UpdateContactEmail. Scope: '+scope.size()+' records.');
        List<Contact> contTobeUpdated = new List<Contact>();
		
    	for (Contact cont : scope) {
    		i++;//avoid duplicate email address
            String email = !String.isEmpty(cont.email)?cont.email.split('@')[0]+'@example.com':i+'abc@example.com';
            cont.Email = email;
            contTobeUpdated.add(cont);
    	}
        if (!contTobeUpdated.isEmpty()) {
	    	try {
	    		Database.update(contTobeUpdated, false);
	    	} catch(Exception ex) {
	    		UTIL.throwError('BAT_UpdateContactEmail: Error updating Contacts',ex );
	   		}
	   	}
    }
    
    public void finish(Database.BatchableContext BC) {
    }
    
}