public with sharing class c_ExceptionController {

    public String errorMessage { get; set; }
    public String strackTrace { get; set; }

    public c_ExceptionController() {
       errorMessage = ApexPages.currentPage().getParameters().get('exception');
       strackTrace = ApexPages.currentPage().getParameters().get('stack');
       if (errorMessage == null && strackTrace  == null) {
           errorMessage = Site.getErrorMessage() + '\n' + Site.getErrorDescription().replaceAll('\\[NEWLINE\\]', '\n');
       }
    }
    
 

}