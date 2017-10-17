global class LCS_DefaultCaseEmailTemplate implements QuickAction.QuickActionDefaultsHandler {
    
    // Empty constructor
    global LCS_DefaultCaseEmailTemplate() { }
    
    global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
            
        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = null;
        // Check if the quick action is the standard Case Feed send email action
        for(QuickAction.QuickActionDefaults defAction: defaults) {
            if (defAction instanceof QuickAction.SendEmailQuickActionDefaults && 
                defAction.getTargetSObject().getSObjectType() ==  EmailMessage.sObjectType && 
                defAction.getActionName().equals('Case.Email') && 
                defAction.getActionType().equals('Email')) {
                   sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults)defAction;
                   break;
            }
        }

        if (sendEmailDefaults != null) {
            String whereClause = 'Id = \''+ sendEmailDefaults.getContextId()+ '\' And OriginChannel__c != null '; 
            List<Case> lstCases = GW_sObject.queryRecords('Case', new List<String>{'id','OriginChannel__c', 'UseMacroEmailDefaults__c'}, whereClause); 
            if(!lstCases.isEmpty()) {
            	Case emCase = lstCases.get(0);
                String orginalChannel = emCase.OriginChannel__c;

                /*  Refers to CD-3189 - conflict as macro and default email template use same standard email action
                    A running email MACRO sets UseMacroEmailDefaults__c to true 
                    - Set it back to false
                    - Do not apply default email template logic - use macro text instead
                */
                Boolean isCaseMacroRunning = emCase.UseMacroEmailDefaults__c;
                if(isCaseMacroRunning){  
                    emCase.UseMacroEmailDefaults__c = false;
                    update emCase;
                    return;
                }
				
				orginalChannel = orginalChannel.toUpperCase();

            	if(orginalChannel.contains('@') && orginalChannel.contains('.')) {  //If orginalChannel is in email format not 'DBA/Bilbasen'
                    orginalChannel = orginalChannel.substring(orginalChannel.indexOf('@')+1, orginalChannel.indexOf('.'));
                }
            	String templateName = 'ECGDK_CS_' + orginalChannel;
            	whereClause = 'Name = \''+ templateName+ '\'';
		        List<EmailTemplate> lstEmails = GW_sObject.queryRecords('EmailTemplate',new List<String>{'id'}, whereClause );
		        if (!lstEmails.isEmpty()) {
		        	//set default template
		         	sendEmailDefaults.setTemplateId(lstEmails.get(0).id);
		        }
		        
		        String defaultEmailName = 'ECGDK_CS_DEFAULT_EMAIL_' + emCase.OriginChannel__c;
		        DevSettings__c devSetting = DevSettings__c.getInstance(defaultEmailName);
		        if( devSetting != null ) {
		        	 EmailMessage emailMessage = (EmailMessage)sendEmailDefaults.getTargetSObject();    
		             emailMessage.fromAddress = (devSetting.value__c);//set default email depending or OriginChannel__c
		        }
            }
        }
    }
}