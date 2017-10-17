global  class TreeGeographySelectingController {
    
    final static String TYPE_LEVEL1 = 'COUNTRY';
    
    transient public List<DTOTreeItem> lstCountry{get;set;} // Bunhor @25-Mar-15: adding transient to avoid view state 
    public String jsonObject{get;set;} //store jsonobject on page
    public String selectedGeography{get; set;}
    public String searchFilter{get;set;}
    public Boolean isExistSelected{get; set;}
    public String targetId{get;set;}
    public Boolean isSaveError{get;set;}
    public String strValue{get;set;}
    public String countryValue{get;set;}
     
    public Boolean isShowCancel{
        get{
            String froIfr = ApexPages.currentPage().getParameters().get('froIfr');
            return froIfr == null || froIfr=='' ? false : Boolean.valueOf( froIfr );
        }set;
    }
    
    /** Bunhor @25-Mar-15: this will determine whether a geo is a folder or not */ 
    private Map<Id, Boolean> mGeoId2IsFolder = new Map<Id, Boolean>();
    /** Bunhor @25-Mar-15: map geoId to listGeo of geos selected and its relation (colevel, uplevel, and downlevel) */ 
    private Map<String, List<Geography__c>> allGeo2Childs; 
    private Set<String> setOldSelectedCountry = new Set<String>(); 
    private List<TargetingGeographyAssociation__c> lstTgGeographies; //All objects that are checked in the tree have to be related to the targeting record.
    
    
    //for synchronize from page is tree select or not
    private void convertJsonToDTOTreeItem(){
        lstCountry = (List<DTOTreeItem>)JSON.deserialize(jsonObject,List<DTOTreeItem>.class);
    }
    //for control is tree select or not on page
    private void convertDTOTreItemToJson(){
    	checkisFolder(lstCountry, true, mGeoId2IsFolder);
        jsonObject=   JSON.serialize(lstCountry);   
    }
    
    
    /**
     * Constructor
     */ 
    global TreeGeographySelectingController(){      
        resetCountry(); 
    } 
    
     
   	public void resetCountry(){
        try{
            //getExisting country and city from associations
            setOldSelectedCountry = getGeoIdFromAsso();
            
            //generate tree 
            initCountry();
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
        }
        
    }
    
    /**
     * getting set of geo id from TargetingGeographyAssociation__c 
     * @author : Bunhor
     * @createdDate :20-Mar-15 
     */
    private Set<String> getGeoIdFromAsso(){
        Set<String> returner = new Set<String>(); 
        targetId = ApexPages.currentPage().getParameters().get('targetId');                 
        if( String.isNotBlank(targetId) ){
        	for(TargetingGeographyAssociation__c ass : [Select Geography__c, Geography__r.Node_ID__c From TargetingGeographyAssociation__c  Where Targeting__c=:targetId]){ 
	        	returner.add(ass.Geography__c); 
	        }
        }    
        return returner;  
    }
    
    //get all country, existing city into the tree
    private void initCountry(){
        lstCountry = new List<DTOTreeItem>();
        initAllRelated(setOldSelectedCountry); // init map allGeo2Childs and mGeoId2IsFolder
        for(Geography__c con : [Select Id, Name, Type__c, Node_ID__c From Geography__c Where Type__c=:TYPE_LEVEL1 And Node_ID__c=null   order by Name]){
            DTOTreeItem dto = createDTO(lstCountry.size(), con); 
            dto.isSelected = setOldSelectedCountry.contains(con.id);
            dto.isExpand = setOldSelectedCountry.contains(con.id);
            
            // Add childs to country
            addChilds2SelectedParent(dto); 
            lstCountry.add( dto);
        }
        convertDTOTreItemToJson(); 
    }
     
    /**
     * init map allGeo2Childs and mGeoId2IsFolder of selected geo (colevel, uplevel, and downlevel)
     * @author : Bunhor
     * @createdDate :23-Mar-15 
     */
    private void initAllRelated(Set<String> selectedGeoIds){ 
    	allGeo2Childs = new Map<String, List<Geography__c>>(); // clear before start
    	
    	Set<String> allRelatedGeoIds = new Set<String>(); 
    	getGeoIdUpLevel(allRelatedGeoIds, selectedGeoIds);   // uplevel 
    	getGeoIdDownLevel(allRelatedGeoIds, selectedGeoIds); // downlevel
    	getGeoIdCoLevel(allRelatedGeoIds, selectedGeoIds);   // colevel
    	 
    	// init allGeo2Childs for selectedGeo   
    	for(Geography__c geo :[Select Name, Type__c, Id, Node_ID__c, (Select id From Geographies__r limit 1) From Geography__c where id IN :allRelatedGeoIds order by Name]){
            mGeoId2IsFolder.put(geo.Id, geo.Geographies__r.size()>0);  
            if(geo.Node_ID__c!=null){
            	if(allGeo2Childs.get(geo.Node_ID__c)==null) allGeo2Childs.put(geo.Node_ID__c, new List<Geography__c>());
            	allGeo2Childs.get(geo.Node_ID__c).add(geo);
            }
        } 
    }
      
    /**
     * create child dto (recursived)
     * @author : Bunhor
     * @createdDate :23-Mar-15 
     */
    private void addChilds2SelectedParent(DTOTreeItem dto){
        if(allGeo2Childs.containsKey(dto.treeId)) {
            for(Geography__c geo : allGeo2Childs.get(dto.treeId)) { 
            	DTOTreeItem dtoChild = createDTO(dto.lstChild.size(), geo); 
                dtoChild.isExpand = dto.isSelected || setOldSelectedCountry.contains(geo.id);   
                dtoChild.isSelected = dto.isSelected || setOldSelectedCountry.contains(geo.id); 
            	 
            	dto.lstChild.add(dtoChild);
            	addChilds2SelectedParent(dtoChild);
            }
        }   
    }
    
    /**
     * go through the dto for:
     *   1 > create TargetingGeographyAssociation__c
     *   2 > add to list for upsert
     *   3 > populate string for assigning to lineitem 
     * @author : Bunhor
     * @createdDate : 23-Mar-15
     */
     private void processDTO(DTOTreeItem[] lstDTO){
     	if(lstDTO==null || lstDTO.isEmpty()) return;
     	for(DTOTreeItem dto : lstDTO){
     		checkedParrentIfAllChildsChecked(dto);
            if(dto.isSelected){
            	Id geoId = dto.treeId;
            	// 1 > create TargetingGeographyAssociation__c
            	TargetingGeographyAssociation__c ass = new TargetingGeographyAssociation__c(Targeting__c=targetId ,Geography__c =geoId , TargetGeography__c=targetId+geoId);
                // 2 > add to list for upsert
                lstTgGeographies.add(ass);
                // 3 > populate string for assigning to lineitem 
                countryValue += dto.treeName +',';
                // 4 > next element of the loop
                continue;   
            }
            // recursive
            processDTO(dto.lstChild);
        }	
     }
     
    // ============== Methods called from Page ==========================================================================================// 
    
    /**
     * Called from Save button
     * upserting/deleting: targeting, associations, lintitem 
     */ 
    public void saveRecords(){
        
        try{
            lstTgGeographies = new List<TargetingGeographyAssociation__c>();
            
            convertJsonToDTOTreeItem();          
            String lineItemId = ApexPages.currentPage().getParameters().get('itemId');          
            isSaveError = false;

            if( targetId == null || targetId==''){
                lineItemId = lineItemId == null ? '' : lineItemId;           
                Targeting__c t = new Targeting__c(Description__c = 'Tar_LineItemId ' + lineItemId);
                insert t;
                targetId = t.Id;
            }
             
            countryValue = ''; 
            processDTO(lstCountry); // Bunhor @23-Mar-15: recode this method and adding this line
            
 			upsert lstTgGeographies TargetGeography__c ;  
            delete [Select Id From TargetingGeographyAssociation__c Where Targeting__c= :targetId And id Not In :lstTgGeographies ];
                        
            convertDTOTreItemToJson(); 
            
            if( String.isNotBlank(lineItemId) ){  
				OpportunityLineItem oli = new OpportunityLineItem(id=lineItemId); 
				//oli.City_Description__c = strValue.removeEnd(',') ;
				//oli.Countries_Description__c = countryValue.removeEnd(',');
				oli.Geography__c = countryValue.removeEnd(',');
				update oli;   
            }
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
             isSaveError = true;
        }       
    }
      
    
     /**
     * Called from search is Entered
     * Todo:
     * - Create uplevel, downlevel, and colevel DTOs if these are not existed.
     * - Collapsed/Expanded
     * - Checked/Unchecked
     */ 
    public void addCountry(){ 
     	convertJsonToDTOTreeItem();
           
        Map<String,DTOTreeItem> mTreeId2Dto = new Map<String,DTOTreeItem>();
        pushList2Map(lstCountry, mTreeId2Dto);
         
        Set<String> allRelatedGeoIds = new Set<String>{selectedGeography}; 
    	getGeoIdUpLevel(allRelatedGeoIds, new Set<String>{selectedGeography});   // uplevel 
    	getGeoIdDownLevel(allRelatedGeoIds, new Set<String>{selectedGeography}); // downlevel
    	getGeoIdCoLevel(allRelatedGeoIds, new Set<String>{selectedGeography});   // colevel	
       	
       	Geography__c[] lstGeo = [select Id, Name, Type__c, Node_ID__c, (Select Id From Geographies__r limit 1) from Geography__c where id in :allRelatedGeoIds order by Name]; 
       	Map<Id, Geography__c> mGeo = new Map<Id, Geography__c>(); // NOTE: new Map<Id, Geography__c>([select....]) is not orderable
       	for(Geography__c geo : lstGeo){
       		mGeo.put(geo.id, geo);
       	}
       	 
       	for(Geography__c geo : lstGeo){
       		mGeoId2IsFolder.put(geo.Id, geo.Geographies__r.size()>0);  
       		createDtoFromSearch(mTreeId2Dto, mGeo, geo);
       	}
       	DTOTreeItem searchedDto = mTreeId2Dto.get(selectedGeography);
       	if(searchedDto!=null){
       		searchedDto.isSelected = true;
       		checkedChildIfParrentChecked(searchedDto);
       	} 
       	convertDTOTreItemToJson();   
     	return; 
        
    }
     
    /**
     * Process when clicking on each Geography(folder)
     */
    public void getGeographies(){
        try{
            convertJsonToDTOTreeItem();
           
            Map<String,DTOTreeItem> mTreeId2Dto = new Map<String,DTOTreeItem>();
            pushList2Map(lstCountry, mTreeId2Dto);
            
            DTOTreeItem clickedDto = mTreeId2Dto.get(selectedGeography);
            //if(clickedDto==null) return;
            expandThisUpLevel(clickedDto, mTreeId2Dto); // expand the tree 
            for(Geography__c geo : [select id, name, Type__c, Node_ID__c, (Select id, Type__c From Geographies__r limit 1) from Geography__c where Node_ID__c= : selectedGeography order by Name]){
                mGeoId2IsFolder.put(geo.Id, geo.Geographies__r.size()>0);   
                DTOTreeItem dto = mTreeId2Dto.get(geo.id);
                if(dto==null){ 
                	dto = createDTO(clickedDto.lstChild.size(), geo); 
                	clickedDto.lstChild.add(dto);
                }  
            }  
            convertDTOTreItemToJson();
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
        }
    }
    
    // ============== Inner classes ==========================================================================================// 
    
    public class DTOTreeItem {
        public Integer pos{get;set;}
        public String treeId{get;set;}
        public String treeName{get;set;}
        public String treeType{get;set;}
        public String treeParrentId{get;set;}
        public List<DTOTreeItem> lstChild{get;set;}
        public Integer treeLv{get;set;}
        public Boolean isExpand{get;set;}
        public Boolean isHideCheckBox{get;set;}
        public Boolean isFolder{get;set;}
        public Boolean isSelected{get;set;}
        public DTOTreeItem(Integer pos,String treeId,String treeName,String treeType, Boolean isFolder,String treeParrentId,Integer treeLv,Boolean isExpand,Boolean isHideCheckBox ){
            this.treeId = treeId;
            this.treeName = treeName;
            this.treeType = treeType;
            this.treeParrentId = treeParrentId;
            this.pos = pos;
            this.treeLv = treeLv;
            this.isExpand = isExpand;
            this.isFolder = isFolder;
            this.isHideCheckBox = isHideCheckBox;
            this.lstChild = new List<DTOTreeItem>();
            this.isSelected = false;
        }       
    }
    
    // ============== Static Methods ==========================================================================================//
    
    /**
     * JS Remoting action called when searching for a  country (jQuery autocomplete)
     */ 
    @RemoteAction
    global static List<Geography__c> searchCountry(String searchTerm) { 
        List<Geography__c> lstTmp = new List<Geography__c>();
        try{
            searchTerm = searchTerm<> null ? searchTerm.trim() : '';     		
    		String queryName = '%' + searchTerm.trim() + '%'; 
    		String queryString = 'Select Id, Name, Type__c From Geography__c where Name Like :queryName limit 20';	 	
    	    lstTmp =  Database.query( queryString );  
        }catch(Exception e){
             ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());
             ApexPages.addMessage(lastNameMsg);
        } 
        return lstTmp;
    }
    
    /**
     * getting geo ids uplevel (recursived)
     * @author : Bunhor
     * @createdDate :23-Mar-15 
     */
    private static void getGeoIdUpLevel(Set<String> reference, Set<String> currentGeoIds){ 
    	Geography__c[] lstGeo = [Select id, Node_ID__c From Geography__c where id in :currentGeoIds and Node_ID__c != null]; 
    	if(lstGeo.isEmpty()) return;
    	
    	Set<String> temCurrentIds = new Set<String>();
    	for(Geography__c geo : lstGeo){
    		reference.add(geo.Node_ID__c);
    		temCurrentIds.add(geo.Node_ID__c);
    	} 
    	getGeoIdUpLevel(reference, temCurrentIds); 
    }
    
    /**
     * getting geo ids downlevel (recursived)
     * @author : Bunhor
     * @createdDate :23-Mar-15 
     */
    private static void getGeoIdDownLevel(Set<String> reference, Set<String> currentGeoIds){ 
    	Geography__c[] lstGeo = [Select id, Node_ID__c From Geography__c where Node_ID__c in :currentGeoIds and Node_ID__c != null]; 
    	if(lstGeo.isEmpty()) return;
    	
    	Set<String> temCurrentIds = new Set<String>();
    	for(Geography__c geo : lstGeo){
    		reference.add(geo.Id);
    		temCurrentIds.add(geo.Id);
    	} 
    	getGeoIdDownLevel(reference, temCurrentIds);																	
    }
    
    /**
     * getting geo ids colevel (recursived)
     * @author : Bunhor
     * @createdDate :23-Mar-15 
     */
    private static void getGeoIdCoLevel(Set<String> reference, Set<String> currentGeoIds){ 
    	Geography__c[] lstGeo = [Select id, Node_ID__c From Geography__c where Id in :currentGeoIds and Node_ID__c != null]; 
    	if(lstGeo.isEmpty()) return;
    	
    	Set<String> parrentIds = new Set<String>();
    	for(Geography__c geo : lstGeo){
    		parrentIds.add(geo.Node_ID__c); 
    	} 
    	for(Geography__c geo : [Select id, Node_ID__c From Geography__c where Node_ID__c in :parrentIds])
    	reference.add(geo.Id); 	
    	
    	getGeoIdCoLevel(reference, parrentIds);															
    }
    
    /**
     * checking through the list and determine isFolder or not (recursived)
     * @author : Bunhor
     * @createdDate :23-Mar-15 
     */
    private static void checkisFolder(List<DTOTreeItem> listRoot, Boolean isCountry, Map<Id, Boolean> id2IsFolder){
    	for(DTOTreeItem dto : listRoot){
    		if(dto.lstChild.isEmpty()){
    			dto.isFolder = isCountry;
    			if(id2IsFolder.get(dto.treeId)!=null) dto.isFolder = id2IsFolder.get(dto.treeId);
    		}else{
    			dto.isFolder = true;
    			checkisFolder(dto.lstChild, false, id2IsFolder); // recursived call
    		} 
    	} 
    }
    
    /**
      * checking if all child selected then select parent
      * @author: Bunhor
      * @createdDate: 23-Mar-15
      */
     private static void checkedParrentIfAllChildsChecked(DTOTreeItem dto){
     	if( dto.lstChild == null || dto.lstChild.isEmpty() ) return;
     	
     	Integer countSelection = 0; 
     	for(DTOTreeItem child : dto.lstChild){
     		if(child.isSelected) countSelection++;
     	}
     	
     	if(dto.lstChild.size()==countSelection)
     	dto.isSelected = true;
     }
     
     /**
      * creating dto for tree when searching
      * @author: Bunhor
      * @createdDate: 30-Mar-15
      */
     private static void createDtoFromSearch(Map<String,DTOTreeItem> mTreeId2Dto, Map<Id, Geography__c> mGeo, Geography__c geo){
    	Geography__c parentGeo = mGeo.get(geo.Node_ID__c); 
    	if(parentGeo != null){
    		DTOTreeItem parentDTO = mTreeId2Dto.get(parentGeo.id);
    		if(parentDTO == null){
    			createDtoFromSearch(mTreeId2Dto, mGeo, parentGeo);
    			parentDTO = mTreeId2Dto.get(parentGeo.id); 
    		}
			parentDTO.isExpand = true; // expand all up level when searching
			if(mTreeId2Dto.get(geo.Id) == null){ // only create dto when it is not existed
				DTOTreeItem dto = createDTO(parentDTO.lstChild.size(), geo);
				parentDTO.lstChild.add(dto);
				mTreeId2Dto.put(dto.treeId, dto);
			} 
    	}
    }
     
    /**
     * if parrent is checked, checked all its childs
     * @author: Bunhor
     * @createdDate: 30-Mar-15
     */ 
    private static void checkedChildIfParrentChecked(DTOTreeItem dto){
    	if(dto.isSelected)
    	for(DTOTreeItem child : dto.lstChild){
    		child.isSelected = true;
    		checkedChildIfParrentChecked(child);
    	} 
    }
    
    /**
     * expand this node and its parents
     * @author : Bunhor
     * @createdDate : 27-Mar-15
     */
    private static void expandThisUpLevel(DTOTreeItem thisDTO,  Map<String,DTOTreeItem> mTreeId2Dto){
    	thisDTO.isExpand = true;
    	DTOTreeItem parent = mTreeId2Dto.get(thisDTO.treeParrentId);
    	if(parent!=null){
    		expandThisUpLevel(parent, mTreeId2Dto);
    	}
    }
     
    /**
     * initialize mTreeId2Dto_Reference param value
     * @author : Bunhor
     * @createdDate : 27-Mar-15
     */
    private static void pushList2Map(List<DTOTreeItem> lstItem, Map<String, DTOTreeItem> mTreeId2Dto_Reference){ 
        for(DTOTreeItem dto : lstItem){ 
            mTreeId2Dto_Reference.put(dto.treeId, dto);
            pushList2Map(dto.lstChild, mTreeId2Dto_Reference); 
        }
    }
     
    /**
     * create simple dto
     * @author : Bunhor
     * @createdDate : 30-Mar-15
     */
    private static DTOTreeItem createDTO(Integer pos, Geography__c geo){
    	return new DTOTreeItem(pos, geo.Id, geo.Name, geo.Type__c, false, geo.Node_ID__c, null, false, false);
    }
}