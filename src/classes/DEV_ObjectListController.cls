global with sharing class DEV_ObjectListController { 
	private static Map<String, Schema.SObjectType> globalDescMap = Schema.getGlobalDescribe() ;
	public List<s_Object> s_Objects {get; set;}
	
	public DEV_ObjectListController() {
		s_Objects = new List<s_Object>();
		for (Schema.SObjectType objType : globalDescMap.Values() ) {
			s_Object so = new s_Object(	objType.getDescribe().getName(), objType.getDescribe().getKeyPrefix() );
			if ( objType.getDescribe().isCustom() ) so.isCustom = true;
			else so.isCustom = false;
			s_Objects.add(so);
		}
		s_Objects.sort();
	}

	global class s_Object implements Comparable {
		public String objectName {get; private set;}
		public String objectPrefix {get; private set;}
		public Boolean isCustom {get; private set;}
		
		public s_Object(String objName, string prefix) {
			this.objectName = objName;
			this.objectPrefix = prefix;
		}
		
		// Implement the compareTo() method
	    global Integer compareTo(Object compareTo) {
	    	s_Object compareToObj = (s_Object)compareTo;
	        if (objectName == compareToObj.objectName) return 0;
	        if (objectName > compareToObj.objectName) return 1;
	        return -1;        
	    }
	}
}