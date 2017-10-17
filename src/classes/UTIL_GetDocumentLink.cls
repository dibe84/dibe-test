global class UTIL_GetDocumentLink {
    global String searchStringIn { get; set; }
    global String returnTypeIn { get; set; }
    global String result { set; }
    global String widthIn { get; set; }
    global String heightIn { get; set; }
    global String altIn { get; set; }
    global String titleIn { get; set; }
    global String tagClassIn { get; set; }
    global String styleIn { get; set; }
    global String borderIn { get; set; }
    
    global String getResult() {
        String result;
        try {
            System.debug('searchString: ' + searchStringIn);
            List<String> parts = searchStringIn.split('/');
            String folderName = null;
            String documentName = null;
            
            System.debug('parts: ' + parts);
            
            if (parts.size() == 2) {
                folderName = parts.get(0);
                documentName = parts.get(1);
            } else if (parts.size() > 2) {
                folderName = parts.get(0);
                parts.remove(0);
                documentName = String.join(parts, '/');
            }
            System.debug('Document : ' + documentName +  ' / ' + folderName);
            if (folderName != null && documentName != null ) {
                Document d = [SELECT Id FROM Document WHERE Name = :documentName AND Folder.DeveloperName = :folderName LIMIT 1];
                if (returnTypeIn == null) {
                    result = System.Url.getSalesforceBaseURL().toExternalForm() + '/servlet/servlet.ImageServer?id=' + d.Id + '&oid=' + UserInfo.getOrganizationId();
                } else if (returnTypeIn == 'img') {
                    result = '<img src="' + System.Url.getSalesforceBaseURL().toExternalForm() + '/servlet/servlet.ImageServer?id=' + d.Id + '&oid=' + UserInfo.getOrganizationId() + '" width="'+widthIn+'"  class="'+tagClassIn+'" height="'+heightIn+'" border="'+borderIn+'" style="'+styleIn+'" title="'+titleIn+'"  alt="'+altIn+'" \\>';
                }        
            }
            System.debug('Result: ' + result);
            return result;
        } catch (Exception e) {
            System.debug('Exception was thrown: ' + e);
            return '';
        }
    }
    
    global UTIL_GetDocumentLink() {
        
    }
}