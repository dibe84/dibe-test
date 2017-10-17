public without sharing class ForceDotComMailCampaignToCase {
    public String targetId { get; set; }
    public String campaignId { get; set; }
    public String prefilledName { get; set; }
    public String prefilledEmail { get; set; }
    public String prefilledPhone { get; set; }
    public String showPage { get; set; }
    
    public class ForceDotComMailCampaignToCaseException extends Exception {}
    
    public ForceDotComMailCampaignToCase() {
        Blob aesKey = EncodingUtil.convertFromHex('8a6a961d6a0867d55affc5a896c6e30f6b7fbe6b7421fc4498776b2cd89e9342'); // AES256 key..
        String encryptedTargetId = ApexPages.currentPage().getParameters().get('id');
        String action = ApexPages.currentPage().getParameters().get('action');
        
        if (action == null) {
            showPage = 'default';
        } else if (action == 'unsubscribe') {
            showPage = 'unsubscribe';
        }
               
        if (encryptedTargetId != null) {
            try {
                Blob decryptedData = Crypto.decryptWithManagedIV('AES256', aesKey, EncodingUtil.convertFromHex(encryptedTargetId));
                targetId = decryptedData.toString();
                // We currently accept leads (00Q), contacts (003) and campaignmembers (00v), determine what type we have at hand...
                if (targetId.substring(0,3) == '00Q') {
                    Lead targetLead = [SELECT Id, LastName, FirstName, Email, HasOptedOutOfEmail, Phone FROM Lead WHERE Id = :targetId];
                    prefilledName = targetLead.FirstName + ' ' + targetLead.LastName;
                    prefilledEmail = targetLead.Email;
                    prefilledPhone = targetLead.Phone;                  
                } else if (targetId.substring(0,3) == '003') {
                    Contact targetContact = [SELECT Id, LastName, FirstName, Email, HasOptedOutOfEmail, Phone FROM Contact WHERE Id = :targetId];
                    prefilledName = targetContact.FirstName + ' ' + targetContact.LastName;
                    prefilledEmail = targetContact.Email;
                    prefilledPhone = targetContact.Phone;
                } else if (targetId.substring(0,3) == '00v') {
                    CampaignMember targetCampaignMember = [SELECT Contact.Phone, Lead.Phone, ContactId, Contact.FirstName, Contact.LastName, Contact.Email, LeadId, Lead.FirstName, Lead.LastName, Lead.Email, Status, Campaign.Id, Contact.HasOptedOutOfEmail, Lead.HasOptedOutOfEmail FROM CampaignMember WHERE Id = :targetId];
                    if (targetCampaignMember.ContactId != null) {
                        prefilledName = targetCampaignMember.Contact.FirstName + ' ' + targetCampaignMember.Contact.LastName;
                        prefilledEmail = targetCampaignMember.Contact.Email;
                        prefilledPhone = targetCampaignMember.Contact.Phone;
                    } else if (targetCampaignMember.LeadId != null) {
                        prefilledName = targetCampaignMember.Lead.FirstName + ' ' + targetCampaignMember.Lead.LastName;
                        prefilledEmail = targetCampaignMember.Lead.Email;
                        prefilledPhone = targetCampaignMember.Lead.Phone;
                    }
                    campaignId = targetCampaignMember.Campaign.Id;
                } else {
                    throw new ForceDotComMailCampaignToCaseException('Cant do anything with this ID');
                }
            } catch (Exception e) {
                throw new ForceDotComMailCampaignToCaseException('Failed decrypting');
            }
        } else {
            throw new ForceDotComMailCampaignToCaseException('No ID was passed');
        }
    }
    
    @RemoteAction
    public static String saveHit(Id campaignMemberId) {
        CampaignMember targetCampaignMember = [SELECT ContactId, Contact.FirstName, Contact.LastName, Contact.Email, LeadId, Lead.FirstName, Lead.LastName, Lead.Email, Status FROM CampaignMember WHERE Id = :campaignMemberId];
        targetCampaignMember.Status = 'Opened Landing Page';
        update targetCampaignMember;
        return '';
    }
    
    @RemoteAction
    public static String unsubscribe(Id campaignMemberId) {
        CampaignMember targetCampaignMember = [SELECT ContactId, Contact.FirstName, Contact.LastName, Contact.Email, LeadId, Lead.FirstName, Lead.LastName, Lead.Email, Status FROM CampaignMember WHERE Id = :campaignMemberId];
        if (targetCampaignMember.ContactId != null) {
            Contact c = [SELECT Id, HasOptedOutOfEmail FROM Contact WHERE Id = :targetCampaignmember.ContactId];
            c.HasOptedOutOfEmail = true;
            update c;
        } else if (targetCampaignMember.LeadId != null) {
            Lead l = [SELECT Id, HasOptedOutOfEmail FROM Lead WHERE Id = :targetCampaignmember.LeadId];
            l.HasOptedOutOfEmail = true;
            update l;
        }
        return '';
    }
    
    @RemoteAction
    public static String saveResponse(String email, String name, String company, String phone, String hours, String targetId, Id campaignId) {
        String targetType = null;
        if (targetId.substring(0,3) == '00Q') {
            targetType = 'Lead';
        } else if (targetId.substring(0,3) == '003') {
            targetType = 'Contact';
        } else if (targetId.substring(0,3) == '00v') {
            CampaignMember targetCampaignMember = [SELECT ContactId, Contact.FirstName, Contact.LastName, Contact.Email, LeadId, Lead.FirstName, Lead.LastName, Lead.Email FROM CampaignMember WHERE Id = :targetId];
            if (targetCampaignMember.ContactId != null) {
                targetType = 'Contact';
                targetId = targetCampaignMember.ContactId;
            } else if (targetCampaignMember.LeadId != null) {
                targetType = 'Lead';
                targetId = targetCampaignMember.LeadId;
            }
            targetCampaignMember.Status = 'Responded';
            update targetCampaignMember;
        }
        
    
    
        Case c = new Case();
        
        if (!Test.isRunningTest()) {
            AssignmentRule AR = new AssignmentRule();
            AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
    
            //Creating the DMLOptions for "Assign using active assignment rules" checkbox
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId = AR.id;
            c.setOptions(dmlOpts);
        }
        
        if (campaignId != null) {
            Campaign camp = [SELECT Id, CaseOrigin__c, CasePriority__c, CaseReason__c, CaseSubject__c, CaseType__c FROM Campaign WHERE Id = :campaignId];
            c.Origin = camp.CaseOrigin__c == null ? 'ECITAAU: Campaign Response' : camp.CaseOrigin__c;
            c.Priority = camp.CasePriority__c == null ? 'LOW' : camp.CasePriority__c;
            c.Reason = camp.CaseReason__c == null ? 'Campaign Response' : camp.CaseReason__c;
            c.Subject = camp.CaseSubject__c == null ? 'Campaign Response' : camp.CaseSubject__c;
            c.Type = camp.CaseType__c == null ? '' : camp.CaseType__c;
        } else {
            c.Origin = 'ECITAAU: Campaign Response';            
            c.Priority = 'Low';
            c.Reason = 'Campaign Response';
            c.Subject = 'Campaign Response';
            c.Type = '';
        }
        
        c.OwnerId = [SELECT Id FROM User WHERE IsActive = true AND Name = 'API' LIMIT 1].Id;
        
        if (Test.isRunningTest()) {
            c.OwnerId = UserInfo.getUserId();
        }
        
        c.Status = 'New';
        c.Description = 'Entered information:\nName: ' + name + ' \n Company: ' + company + ' \n Email: ' + email + ' \n Phone: ' + phone + ' \n Contact hours: ' + hours + '\n';
        
        
        if (targetType == 'Contact') {
            Contact retrievedContact = [SELECT Id, FirstName, LastName, Account.Id, Account.Name FROM Contact WHERE Id = :targetId];
            c.AccountId = retrievedContact.Account.Id;
            c.ContactId = retrievedContact.Id;
        } else if (targetType == 'Lead') {
            c.Lead__c = targetId;
        }
                
        c.RecordTypeId = UTIL_RecordType.getRecordTypeByName('Case','Customer').Id;

        insert c;

        
        return '';
    }   
}