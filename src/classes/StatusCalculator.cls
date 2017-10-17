public class StatusCalculator {

	// interface
	public interface IStatusCalculator{
		//void init(sObject so, List<String> status);
        Boolean setStatus(sObject so);
	}

	// factory
	// 
	// 

    /* JvdH: This factory might be usefull in later stages when we need different stage-flows per object
	// Returns calculator specified by ObjectType, assumes calculator to be present in StatusCalculator class (extending StatusCalculator.AbstractStatusCalculator)
	public static IStatusCalculator getCalculator(sObject so, Schema.sObjectType objType, List<String> statusList) {
		if (so == null || objType == null)
            throw new StatusCalculatorException('Cannot calculate status.');
        String soName = objType.getDescribe().getName();
        soName = soName.replace('__', '_'); // class names cannot contain double underscore... 

		String calcType = 'StatusCalculator.'+soName+ '_StatusCalculator';
		Type t = Type.forName(calcType);
		if (t == null) throw new StatusCalculatorException('Status Calculator can not be instantiated: '+calcType);
        
        IStatusCalculator isc = (IStatusCalculator) t.newInstance();
        isc.init(so, statusList);
        return isc;
	}
	*/
    
    public class Status implements Comparable {
            
            Integer index;
            String  name;
            
        	Status predecessor;
        
            public Status(Integer index, String name){
                this.index = index;
                this.name = name;
            }
        
       		public void setPredecessor(Status predecessor){
            	this.predecessor = predecessor;
        	}
            
            public Integer compareTo(Object compareTo){
                Status compStatus = (Status) compareTo;
                if (index == compStatus.index) return 0;
                if (index > compstatus.index) return 1;
                return -1;
            }
    }

	// Virtual class handling common logic and properties
	public virtual class AbstractStatusCalculator implements StatusCalculator.IStatusCalculator {
		public sObject so;
        public Schema.sObjectType objType;
        public List<Status> statusList = new List<Status>();
        public Integer numStatus;
        public Integer oldNumStatus;
		
        public AbstractStatusCalculator(sObject so, Map<Integer,String> statusMap) {
            this.so = so;
            for (Integer index : statusMap.keySet()) {
                statusList.add(new Status(index, statusMap.get(index)) );
            }
            
            statusList.sort();
            
            Status pred = null;
            
            for (Status s : statusList){
                s.setPredecessor(pred);
                pred = s;
            }
            
            this.oldNumStatus = (so.get('NumStatus__c') != null)?((Decimal) so.get('NumStatus__c')).intValue():0;
        }
        
		public Boolean setStatus(sObject so) {
            Integer count = statusList.size() -1;
            while (count >= 0) {
                if ( this.validateStage(so, statusList[count]) ) {
                	so.put('Status__c', statusList[count].name);
                	so.put('NumStatus__c',statusList[count].index);
                    break;
                }
                count--;
            }
            return ( so.get('NumStatus__c') != this.oldNumStatus ); // return TRUE if status changed
        }
        
        // Check if so validates for a certain stage (and all below)
        public Boolean validateStage(sObject so, Status status) {
            if (status.predecessor != null) 
                return ( passCriteria(so, status.index) && validateStage(so, status.predecessor) );
            else 
                return passCriteria(so,status.index);
            
        }
        
		// method will be overridden in specific implementations
        public virtual Boolean passCriteria(sObject so, Integer stage) {
            return stage==0?true:false;
        }
		
	}
    
	public class StatusCalculatorException extends Exception {}
}