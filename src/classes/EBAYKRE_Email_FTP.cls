global without sharing class EBAYKRE_Email_FTP {
    global String ftpUsername { get; set; }
    global String ftpPassword { get; set; }
    global Id incAccountId { get; set; }
    
    global Map<String,String> getResult() {
        if (incAccountId == null) {
            UTIL.throwError('This e-mail template cannot be used without first selecting an account.');
        }
        Map<String,String> result = new Map<String,String>();
        result.put('ftpUsername', 'x');
        result.put('ftpPassword', 'y');
        try {
            List<CustomAttribute__c> customAttributeList = [SELECT Id, Name, StringValue__c FROM CustomAttribute__c WHERE Account__c = :incAccountId];
            UTIL.logErrors('cust attr list: ' + customAttributeList);
            for (CustomAttribute__c attr : customAttributeList) {
                if (attr.Name == 'ftpUsername' || attr.Name == 'ftpPassword') {
                    result.put(attr.Name, attr.StringValue__c);
                }
            }            
        } catch (Exception e) {}
        return result;
    }
    
    public EBAYKRE_Email_FTP() {

    }
}