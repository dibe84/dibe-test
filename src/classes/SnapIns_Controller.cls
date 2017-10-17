public class SnapIns_Controller {
    
    public String jsonObj { get; set; }
    public String username {get;set;}
    public String photoUrl {get;set;}
    public String sitePrefix {get;set;}
    
    public SnapIns_Controller () {
        
        sitePrefix = ApexPages.currentPage().getParameters().get('siteName');
        sitePrefix =  String.isNotEmpty(sitePrefix) ? sitePrefix.toUpperCase() : sitePrefix;
        Map<String,String> mapCustomSetting = new Map<String,String>();
        for(DevSettings__c devSetting: DevSettings__c.getall().values() ){
            String key = devSetting.Name;
            if ( key.contains(sitePrefix)) {
                mapCustomSetting.put(key, devSetting.value__c);
            }
            
        }
        
        jsonObj = JSON.serialize(mapCustomSetting);
        
    }
    
    public void getUserPhoto(){
        if(username != null){
            List<User> lstUsers = [Select Name, SmallPhotoUrl from User where Name =: username];
            if(!lstUsers.isEmpty()) {
                for(User u: lstUsers){
                    if(u.Name.equalsIgnoreCase(username)){
                        photoUrl = u.SmallPhotoUrl;
                        break;
                    }
                }
            }
        }
    }
}