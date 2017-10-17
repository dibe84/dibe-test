public with sharing class PGC_CustomAttributeObjectSearch {
    public List<ResultWrapper> results {get;set;} // search results
    public List<String> fieldList {get;set;} // field list of objects to be included in search query result
    public String searchString {get;set;} // search keyword
	public String objectType {get;set;} // type of object being searched

    public PGC_CustomAttributeObjectSearch() {
      // get the current search string
      searchString = System.currentPageReference().getParameters().get('searchQuery') == null ? '' : System.currentPageReference().getParameters().get('searchQuery');
	  objectType = System.currentPageReference().getParameters().get('objType');
      if(objectType == null || objectType == '' || objectType.length() == 0) {
          objectType = 'Account';
      }
      fieldList = new List<String>{'Id','Name'};
      runSearch();
    }

    // performs the keyword search
    public PageReference search() {
      runSearch();
      return null;
    }

    // prepare the query and issue the search command
    private void runSearch() {
      results = performSearch(searchString);
    }

    // run the search and return the records found.
    private List<ResultWrapper> performSearch(string searchString) {
        String whereClause = 'Name LIKE \'%' + searchString +'%\'';
        whereClause += ' LIMIT 50';

        List<sObject> resultList = GW_sObject.queryRecords(objectType, fieldList, whereClause);
		results = new List<ResultWrapper>();
        for(sObject sobj : resultList) {
            results.add(new ResultWrapper(sobj));
        }

        return results;
    }

    public class ResultWrapper {
        public String name {get;set;}
        public Id objId {get;set;}

        public ResultWrapper(sObject sobj) {
            this.name = (String)sobj.get('Name');
            this.objId = (Id)sobj.get('Id');
        }
    }
}