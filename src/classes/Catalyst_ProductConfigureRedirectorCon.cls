/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: 
 *  - Open lightning page in classic mode
 * @references: 
 *  - Catalyst_ProductConfigureRedirector VF page
 * @changeLog:
 *
 */
public class Catalyst_ProductConfigureRedirectorCon {

    public Catalyst_ProductConfigureRedirectorCon(ApexPages.StandardController controller) {

    }
    
    public String getBaseURL() {
        return URL.getSalesforceBaseUrl().toExternalForm(); 
    }
}