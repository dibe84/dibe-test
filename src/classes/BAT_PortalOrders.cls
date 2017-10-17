global class BAT_PortalOrders implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {

	global Datetime executeStart;
    List<PortalOrder__c> portalOrdersInput;

    global BAT_PortalOrders() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_PortalOrders');
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef, 'PortalOrder__c'));

        if (this.numRecords > 0) readyForRun = true;
    }

    global BAT_PortalOrders(List<PortalOrder__c> portalOrders) {
        this.portalOrdersInput = portalOrders;
    }

    global List<PortalOrder__c> start(Database.BatchableContext BC) {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_PortalOrders');
        if (portalOrdersInput == null){
            List<PortalOrder__c> portalOrders = GW_sObject.queryRecords('PortalOrder__c', UTIL_CustomJob.getWhereQuery(jobDef));
            return portalOrders;
        }
        else{
            return portalOrdersInput;
        }
    }

    global void execute(Database.BatchableContext BC, List<PortalOrder__c> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        Set<Id> parentIds = GW_sObject.getIdSet(scope);
        Map<Id, List<Attachment>> attachmentMap = new Map<Id, List<Attachment>>();
        // Retrieve all attachments
        List<Attachment> attachments = [SELECT Id, Name, ParentId, Body FROM Attachment WHERE ParentId IN :parentIds];
        for (Attachment a : attachments) {
            List<Attachment> mapItem = attachmentMap.get(a.ParentId);
            if (mapItem == null) {
                mapItem = new List<Attachment>();
            }
            mapItem.add(a);
            attachmentMap.put(a.ParentId, mapItem);
        }

        // Loop through orders
        for (PortalOrder__c po : scope) {
            try {
                CommunityConfiguration__c config = CommunityConfiguration__c.getInstance(po.PortalName__c);
                c_Common.IOrderProcessor processor = c_Common.instantiateOrderProcessor(config.OrderProcessor__c);
                c_Common.ResponseObject response = processor.process(po.Id, attachmentMap.get(po.Id));

                if (response.success) {
                    for (String key : response.responseMap.keySet()) {

                        String type = 'String';
                        if (key == 'Account__c' || key == 'Opportunity__c') {
                            type = 'Lookup';
                        }
                        if (type == 'String') {
                            po.put(GW_sObject.getFieldDescribe('PortalOrder__c', key).getSObjectField(), response.responseMap.get(key));
                        } else if (type == 'Lookup') {
                            po.put(GW_sObject.getFieldDescribe('PortalOrder__c', key).getSObjectField(), Id.valueOf(response.responseMap.get(key)));
                        }
                    }
                    po.Status__c = 'Processed';
                } else {
                    throw new UTIL.CustomException('Success was false: ' + response);
                }
            } catch (Exception e) {
                po.Status__c = 'Error';
                po.ErrorDetails__c = e.getMessage() + ' Trace: ' + e.getStacktraceString();
            }
        }

        // Process them straightforward (add custom impl. later)

        // Update statusses

        update scope;
    }

    global void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_PortalOrders', BC.getJobId());
    }

    // interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
}