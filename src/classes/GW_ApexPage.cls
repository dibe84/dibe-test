public with sharing class GW_ApexPage {
    
        public static String getExistingTemplateName(String pagename, String language){
            
            Integer doesPageExist = 0;
            if (!String.isEmpty(language)){
                String pageNameForLanguage = pagename+'_'+language;
                doesPageExist = Database.countQuery('SELECT Count() from ApexPage WHERE Name=\''+pageNameForLanguage+'\'');
                if (doesPageExist!=0){
                    pagename = pageNameForLanguage;
                }
            }
            doesPageExist = Database.countQuery('SELECT Count() from ApexPage WHERE Name=\''+pagename+'\'');
            if (doesPageExist == 0){
               throw new UTIL.CustomException('ApexPage \''+pagename+'\' does not exist.');
            }
            
            return pagename;
        }
        
}