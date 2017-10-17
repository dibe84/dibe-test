/**
 * An apex page controller that exposes the site login functionality
 */
global with sharing class c_Login {

    global c_Login () {}
    
    // Code we will invoke on page load.
    global PageReference forwardToAuthPage() {
      String startUrl = System.currentPageReference().getParameters().get('startURL');
      String displayType = System.currentPageReference().getParameters().get('display');
        return Network.forwardToAuthPage(startUrl, displayType);
    }
}