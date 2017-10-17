global class WS_UI {
    webservice static String EBAYKRE_SendFTPEmail(Id accountId) {
        try {
            Account acc = GW_Account.getRecord(accountId);
			if(acc.Type != null && acc.Type.equalsIgnoreCase('pro')) return '';
            EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'EBAYKRE_FTP_Information' LIMIT 1];
            OrgWideEmailAddress owea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'no-reply@reti.ebay-kleinanzeigen.de' LIMIT 1];        
    
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(et.Id);
            mail.setOrgWideEmailAddressId(owea.Id);
            mail.setWhatId(accountId);
            mail.setTargetObjectId(acc.Portal_User__c);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
        return '';
    }
    
    webservice static String signOpportunity(Id oppId){
        try{
          GW_Opportunity.signOpportunity(oppId);
          return 'Opportunity succesfully signed!';
        }
        catch (Exception e){
            return e.getMessage();
        }
    }
   
   webservice static List<String> createCaseFromCallLog(Id callLogId) {
        return  GW_Case.createCaseFromCallLog(callLogId);
    }
}