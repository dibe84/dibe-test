global with sharing class c_URLRewriter implements Site.UrlRewriter {

    private class URLRewriteException extends Exception {}

    global PageReference mapRequestUrl(PageReference inputUrl){
        if (inputUrl.getUrl().contains('c_Exception')) {
            return null;
        }        
        try {
            String cleanUrl = URL.getSalesforceBaseUrl().toExternalForm().remove('https://').remove('http://');
            //Domain is now conflicting to ECGDK CS, we need to add PathPrefix filter
            List<Site> sitesByDomain = [SELECT Id, MasterLabel, Name FROM Site WHERE Id IN (SELECT SiteId FROM DomainSite WHERE Domain.Domain = :cleanUrl AND PathPrefix = '/s')];
            Site communitySite = [SELECT Id, Name FROM Site WHERE MasterLabel = :sitesByDomain.get(0).MasterLabel AND SiteType = 'ChatterNetwork'];

            CommunityConfiguration__c config = CommunityConfiguration__c.getInstance(communitySite.Name);
            String rewriteFunction;
            if (config.URLRewriteFunction__c == null) {
                rewriteFunction = 'c_URLRewriter.URLRewrite_Default';
            } else {
                rewriteFunction = 'c_URLRewriter.' + config.URLRewriteFunction__c;
            }
            
            Type t = Type.forName(rewriteFunction);
            URLRewriteImplementation rewriter = (URLRewriteImplementation) t.newInstance();
            rewriter.setConfig(config);
            return rewriter.mapRequestUrl(inputUrl);
        } catch (Exception e) {
            return new PageReference('/c_Exception?exception=A' + e.getMessage() + '&stack=' +e.getStackTraceString());
        }        
    }
    
    global List<PageReference> generateUrlFor(List<PageReference> inputUrls){
        Type t = Type.forName('URLRewrite_Default');
        URLRewriteImplementation rewriter = (URLRewriteImplementation) t.newInstance();
        return rewriter.generateUrlFor(inputUrls);
    }
    
    private interface URLRewriteInterface {
        PageReference mapRequestUrl(PageReference inputUrl);
        void setConfig (CommunityConfiguration__c config);
        List<PageReference> generateUrlFor(List<PageReference> inputUrls);
    }
    
    public virtual class URLRewriteImplementation {
        CommunityConfiguration__c config = null;
        
        virtual public PageReference mapRequestUrl(PageReference inputUrl) {
            String url = inputUrl.getUrl().removeStart('/').removeEnd('/');
            
            String foundPage = this.pageMap().get(url);
            
            if (foundPage == null) {
                return null;
            } else {        
                return new PageReference(foundPage);
            }
        }
        
        virtual public List<PageReference> generateUrlFor(List<PageReference> inputUrls){
            return null;
        }
        
        virtual public void setConfig(CommunityConfiguration__c config) {
            this.config = config;
        }
        
        virtual public Map<String,String> pageMap() {
            return new Map<String,String>{
                '' => '/' + config.Template__c + '?page='+config.HomePage__c,
                'order' => '/' + config.Template__c + '?page='+config.OrderPage__c,
                'overview' => '/' + config.Template__c + '?page='+config.OverviewPage__c,
                'profile' => '/' + config.Template__c + '?page='+config.ProfilePage__c,
                'contact' => '/' + config.Template__c + '?page='+config.ContactPage__c
            };        
        }
    }
    
    public class URLRewrite_Default extends URLRewriteImplementation implements URLRewriteInterface {}
    
}