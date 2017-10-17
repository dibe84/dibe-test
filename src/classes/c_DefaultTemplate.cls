public with sharing class c_DefaultTemplate {
    private String page { get; set; }
    public String output { get; set; }

    public c_DefaultTemplate() {
        output = '';
       page = ApexPages.currentPage().getParameters().get('page');     
       //String pageRef = new PageReference('/apex/' + page).getContent().toString();
       String pageRef = test.isRunningTest() ? Blob.valueOf('TEST').toString() : new PageReference('/apex/' + page).getContent().toString();
       output += cleanUp(pageRef);
    }
    
    private String cleanUp(String input) {
        return input.remove('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">');
    }
}