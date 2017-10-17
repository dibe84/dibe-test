/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: 
 *  - Open lightning page in classic mode
 * @references: 
 *  - LPC_ProductConfigureRedirector VF page
 * @changeLog:
 *
 */
public class LPC_ProductConfigureRedirectorController {

    public LPC_ProductConfigureRedirectorController(ApexPages.StandardController controller) {

    }
    
    public String getBaseURL() {
        return URL.getSalesforceBaseUrl().toExternalForm(); 
    }
}