public class UTIL_Email {

    public static Map<String, OrgWideEmailAddress> orgWideEmailAddressCache {
        get {
            if (orgWideEmailAddressCache == null) {
                orgWideEmailAddressCache = new Map<String, OrgWideEmailAddress>();
                List<OrgWideEmailAddress> addresses = (List<OrgWideEmailAddress>) GW_sObject.queryRecords('OrgWideEmailAddress', '');
                for (OrgWideEmailAddress owea : addresses) {
                    orgWideEmailAddressCache.put(owea.Address, owea);
                }
            }
            return orgWideEmailAddressCache;
        }
        private set;
    }

    public static Map<Id, EmailTemplate> emailTemplateCache {
        get {
            if (emailTemplateCache == null) {
                emailTemplateCache = new Map<Id, EmailTemplate>();
                List<EmailTemplate> emailTemplates = (List<EmailTemplate>) GW_sObject.queryRecords('EmailTemplate', '');
                for (EmailTemplate et : emailTemplates) {
                    emailTemplateCache.put(et.Id, et);
                }
            }
            return emailTemplateCache;
        }
        private set;
    }

    public static Map<String,EmailTemplate> emailTemplateNameCache {
        get {
            if (emailTemplateNameCache == null) {
                emailTemplateNameCache = new Map<String,EmailTemplate>();
                for (EmailTemplate et : emailTemplateCache.values()) {
                    emailTemplateNameCache.put(et.Name, et);
                }
            }
            return emailTemplateNameCache;
        }
        private set;
    }

    public static Map<String,EmailTemplate> emailTemplateDeveloperNameCache {
        get {
            if (emailTemplateDeveloperNameCache == null) {
                emailTemplateDeveloperNameCache = new Map<String,EmailTemplate>();
                for (EmailTemplate et : emailTemplateCache.values()) {
                    emailTemplateDeveloperNameCache.put(et.DeveloperName, et);
                }
            }
            return emailTemplateDeveloperNameCache;
        }
        private set;
    }

	@future
    public static void sendSystemAlert(String subject,String body) {
        sendSystemAlertFromFuture(subject, body, null);
    }

	@future
    public static void sendSystemAlert(String subject,String body, String htmlBody) {
        sendSystemAlertFromFuture(subject, body, htmlBody);
    }

    public static void sendSystemAlertFromFuture(String subject,String body, String htmlBody) {
        UTIL.log('Sending Email @future');
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setReplyTo('noreply@salesforce.com');
        mail.setSenderDisplayName('System Alert ECG Salesforce '+ (UTIL.isSandbox()?'Sandbox (' + UTIL.orgIdentifier + ') ':'*** PRODUCTION ***')+ ' Org.');
        mail.setSubject(subject + (UTIL.isSandbox()?' Sandbox (' + UTIL.orgIdentifier + ') ':'*** PRODUCTION ***'));
        mail.setToAddresses(new List<String>{'DL-eCG-Salesforce-CoE@ebay.com'});
		if (htmlBody != null) {
			mail.setHtmlBody(htmlBody);
			mail.setPlainTextBody(body.stripHtmlTags());
		} else {
			mail.setPlainTextBody(body);
		}


        mails.add(mail);
        if (!Test.isRunningTest()) Messaging.sendEmail(mails);
    }

	public static Messaging.SingleEmailMessage buildEmail(String developerName, Id whatId, Id targetObjectId) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		Id templateId = emailTemplateDeveloperNameCache.get(developerName).Id;
		mail.setReplyTo('noreply@salesforce.com');
		mail.setTemplateId(templateId);
		mail.setWhatId(whatId);
		mail.setTargetObjectId(targetObjectId);
		return mail;
	}
	
	public static Messaging.SingleEmailMessage buildEmail(String developerName, Id targetObjectId, Id targetObjectId2, Id whatId, Map<String, String> mergeFields) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		//Force the merge of the template
		EmailTemplate template = emailTemplateDeveloperNameCache.get(developerName);
		Messaging.SingleEmailMessage mergeEmail = UTIL.renderEmail(template, targetObjectId2, whatId);
		
		String htmlBody = mergeEmail.getHTMLBody(); 
		String plainText = mergeEmail.getPlainTextBody();
		String subject = mergeEmail.getSubject(); 
		system.debug('htmlBody<<<<<<<<<<<<<<' + htmlBody);
		system.debug('plainText======= ' + plainText);
		subject = subject.replace('$AccountName$', mergeFields.get('$AccountName$')+'');
		
		for (String field : mergeFields.keySet()) {
			htmlBody = htmlBody.replace(field, mergeFields.get(field));
			plainText = plainText.replace(field, mergeFields.get(field));
		}
		
		mail.setSenderDisplayName(UserInfo.getName());
		mail.setReplyTo('noreply@salesforce.com');
		mail.setTargetObjectId(targetObjectId);
		mail.setSaveAsActivity(false);
		mail.setSubject(subject);
		mail.setHtmlBody(htmlBody);
		mail.setPlainTextBody(plainText);
		return mail;
	}
	
	public static void sendEmails(List<Messaging.SingleEmailMessage> emails) {
        if (!Test.isRunningTest()) Messaging.sendEmail(emails);
	}
	
	
}