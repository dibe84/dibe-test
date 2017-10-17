global class BAT_SendCampaignMails implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {

	global Datetime executeStart;
    String whereClause;
    List<Campaignmember> membersInput;

    global BAT_SendCampaignMails() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_SendCampaignMails');
        DateTime currentDT = DateTime.now();
        Integer hour = currentDT.hour();
        Integer minute = currentDT.minute();
        String sHour;
        String sMinute;
        if (hour < 10) {
            sHour = '0' + hour;
        } else {
            sHour = '' + hour;
        }
        if (minute < 10) {
            sMinute = '0' + minute ;
        } else {
            sMinute  = '' + minute ;
        }

        String currentTime = sHour + ':' + sMinute;

        this.whereClause = 'Campaign.MailBetweenStart__c < \'' + currentTime + '\' AND Campaign.MailBetweenEnd__c > \'' + currentTime + '\'';
        if (jobDef.setting.WhereClause__c != null) {
            this.whereClause += ' AND ' + jobDef.setting.WhereClause__c;
        }

        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef, 'CampaignMember'));

        if (!Test.isRunningTest()) {
            try {
                Messaging.reserveSingleEmailCapacity(200);
            } catch (Exception e) {
                this.numRecords = 0;
            }
        }
        if (this.numRecords > 0) readyForRun = true;
    }

    global BAT_SendCampaignMails(List<CampaignMember> members) {
        this.membersInput = members;
    }

    global List<CampaignMember> start(Database.BatchableContext BC) {
        if (membersInput == null){
            List<String> fields = new List<String>{'Id','Lead.Id','Contact.Id','Campaign.Id', 'Status', 'Campaign.Name', 'Campaign.EmailTemplateLead__c', 'Campaign.EmailTemplateContact__c', 'Campaign.Sender__c'};
            List<CampaignMember> members = GW_sObject.queryRecords('CampaignMember', fields, this.whereClause);
            return members;
        }
        else{
            return membersInput;
        }
    }

    global void execute(Database.BatchableContext BC, List<CampaignMember> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        // Attempt to reserve capacity; otherwise do nothing
        if (!Test.isRunningTest()) {
            try {
                Messaging.reserveSingleEmailCapacity(200);
            } catch (Exception e) {
                return;
            }
        }

        // Loop through all targets, find all template names so we can build templatename -> template id map
        Set<String> templateNames = new Set<String>();
        Set<String> addresses = new Set<String>();

        for (CampaignMember member : scope) {
            templateNames.add(member.Campaign.EmailTemplateLead__c);
            templateNames.add(member.Campaign.EmailTemplateContact__c);
            addresses .add(member.Campaign.Sender__c);
        }

        Map<String,Id> templateMap = new Map<String,Id>();

        List<EmailTemplate> emailTemplates = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :templateNames];
        for (EmailTemplate et : emailTemplates) {
            templateMap.put(et.DeveloperName,et.Id);
        }

        Map<String,Id> senderEmailMap = new Map<String,Id>();

        List<OrgWideEmailAddress> addressList = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address IN :addresses];

        for (OrgWideEmailAddress owea : addressList) {
            senderEmailMap.put(owea.Address, owea.Id);
        }

        for (CampaignMember member : scope) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            try {
                if (member.Contact.Id != null) {
                    Id templateId = templateMap.get(member.Campaign.EmailTemplateContact__c);
                    mail.setTemplateId(templateId);
                    mail.setOrgWideEmailAddressId(senderEmailMap.get(member.Campaign.Sender__c));
                    mail.setWhatId(member.Campaign.Id);
                    mail.setTargetObjectId(member.Contact.Id);
                } else if (member.Lead.Id != null) {
                    EmailTemplate et = new EmailTemplate();
                    et.Id = templateMap.get(member.Campaign.EmailTemplateLead__c);
                    Messaging.SingleEmailMessage dummyMail = UTIL.renderEmail(et, member.Lead.Id, member.Campaign.Id);
                    mail.setOrgWideEmailAddressId(senderEmailMap.get(member.Campaign.Sender__c));
                    mail.setHtmlBody(dummyMail.getHtmlBody());
                    mail.setPlainTextBody(dummyMail.getPlainTextBody());
                    mail.setSubject(dummyMail.getSubject());
                    mail.setTargetObjectId(member.Lead.Id);
                }

                member.Status = 'Sent';

                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            } catch (Exception e) {
                member.Status = 'Error';
            }
        }

        update scope;
    }

    global void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_SendCampaignMails', BC.getJobId());
    }

    // interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
}