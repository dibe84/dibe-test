public with sharing class LCS_BusinessHoursDetailsController {
    
    public String curSite {get;set;}
    
    public static final String CALLMEBACK ='_CallMeBackSetting';
    
    public List<SelectOption> lstActiveSites { get;set; }
    
    public LCS_BusinessHoursDetailsController( ) {
        
        lstActiveSites =  new List<SelectOption>();
        String whereClause = 'status = \'Active\' AND UrlPathPrefix like \'ecgdk%\' AND siteType= \'ChatterNetwork\' order by Name';
        List<String> lstFields = new List<String>{'id','Name'};
        String objType = 'Site';
        List<Site> lstSites = GW_sObject.queryRecords(objType, lstFields, whereClause);
        for(Site s : lstSites){
            lstActiveSites.add(new SelectOption(s.name, s.name));
        }
        
        curSite = lstSites.isEmpty() ? '' : lstSites.get(0).Name;
        initDevSetting();
    }
    
    public DevSettings__c devSetting {get;set;}
    
    public void initDevSetting(){
        String devName = curSite + CALLMEBACK;
        String whereClause = 'Name = \''+ devName+ '\'';
        List<DevSettings__c> lstDevSetting = GW_sObject.queryRecords('DevSettings__c', new List<String>{'id','Name','value__c'}, whereClause); 
        if( !lstDevSetting.isEmpty()) {
            devSetting = lstDevSetting.get(0);
        } else {
            devSetting = new DevSettings__c(value__c='Active', Name  = devName);
        }
    }
    
    public void updateStatus() {
    
        try {
            devSetting.Name = curSite + CALLMEBACK; 
            devSetting.value__c = devSetting.value__c == 'Active' ? 'Inactive' :'Active';
            upsert devSetting;
        
        }catch (Exception e) { ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage() )); }
        
    }
    
}