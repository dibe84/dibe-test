public with sharing class AddSiteController {
    
    public Site_Alert__c curSiteAlert { get;set; }
    public Boolean isRequestError { get;set; }
    
    public AddSiteController(ApexPages.StandardController controller) {
      
            this.curSiteAlert = (Site_Alert__c)controller.getRecord();
            if(String.isNotEmpty(this.curSiteAlert.id)) {
                List<Site_Alert__c> lstSites = GW_sObject.queryRecords( 'Site_Alert__c',  new List<String>{'id','Site__c'}, new Set<Id>{this.curSiteAlert.id}) ;
                if(!lstSites.isEmpty()) {
                    this.curSiteAlert = lstSites.get(0);
                }else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid Site record id.'));
                }
            } else {
                this.curSiteAlert = new Site_Alert__c();
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid Site record id.'));
            }
       
    }
    
    public List<SelectOption> getItems() {
    	
        List<SelectOption> options = new List<SelectOption>();
        String whereClause = 'status = \'Active\' AND UrlPathPrefix <> null AND siteType= \'ChatterNetwork\' order by Name';
        List<String> lstFields = new List<String>{'id','Name'};
        String objType = 'Site';
        List<Site> lstSites = GW_sObject.queryRecords(objType, lstFields, whereClause);
        for(Site s : lstSites){
            options.add(new SelectOption(s.name, s.name));
        }
        return options;
    }
    
    public void saveSiteAlert() {
    	
        try {
            isRequestError = false;
            update curSiteAlert;
        } catch(Exception  e) {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
           isRequestError = true;
        }
    
    }
    
    
}