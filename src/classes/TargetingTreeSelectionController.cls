global  class TargetingTreeSelectionController {
    transient public DTOTreeItem  content{get;set;}
    transient public String jsonObject{get;set;}
    public String selectedContent{get;set;}
    
    global TargetingTreeSelectionController(){
        resetTree(); 
    }   
    
    //for synchronize from page is tree select or not
    public void convertJsonToDTOTreeItem(){
        content = (DTOTreeItem)JSON.deserialize(jsonObject,TargetingTreeSelectionController.DTOTreeItem.class);
    }
    
    //for control is tree select or not on page
    public void convertDTOTreItemToJson(){
        jsonObject = JSON.serialize(content);  
    }
    
    Set<String> setOldSelectedTargeting = new Set<String>();
    private void doSelectedTargeting(){
        setOldSelectedTargeting = new Set<String>();
        try{            
           targetId = ApexPages.currentPage().getParameters().get('targetId');          
            if( targetId == null || targetId==''){           
                return;
            }
            
            for( TargetingContentAssociation__c tca: [ Select TargetingContent__c From TargetingContentAssociation__c Where Targeting__c = :targetId And Targeting__c != null]){               
              setOldSelectedTargeting.add(tca.TargetingContent__c);
            }
        }catch(Exception e){  ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());   ApexPages.addMessage(lastNameMsg);}
    }
    
    public void resetTree(){
         try{
            doSelectedTargeting();
            initLstContent();           
         }catch(Exception e){  ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'resetTree=='+e.getMessage() + '===' + e.getStackTraceString()); ApexPages.addMessage(lastNameMsg);}
       
        
    }
    
    /**
     */
    String conId;
    public void initLstContent(){ 
    		 
         String proId = Apexpages.currentPage().getParameters().get('proId');
         if( proId == null || proId == ''){
            content = new DTOTreeItem( 0 , 'NoContent', 'No Content', false, null, 1, false, true);
            convertDTOTreItemToJson();
            ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'Invalid product id.' );
            ApexPages.addMessage(lastNameMsg);
            return;
         }
         List<Product2> lstPro= [Select Content__c, PredifinedAdunit__c, PredifinedAdunit__r.Active__c From Product2  where id= : proId]; 
         
         if( !lstPro.isEmpty() && lstPro.get(0).Content__c == null ){
            content = new DTOTreeItem( 0 , 'NoContent', 'No Content', false, null, 1, false, true);
            convertDTOTreItemToJson();
            ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, 'No content found for this product.' );
            ApexPages.addMessage(lastNameMsg);
            return;
         }else{
            conId = lstPro.get(0).Content__c;
         }
         
         // Bunhor @20-Feb-15: add Content__c from predifined, Product2.PredifinedAdunit__c 
         if( String.isBlank(targetId) && ModifyProductController2.isAdUnitPredifined(new OpportunityLineItem(), lstPro[0]) ){
         	setOldSelectedTargeting.add(lstPro[0].PredifinedAdunit__c);
         }
         system.debug('setOldSelectedTargeting>>>>>' +setOldSelectedTargeting);
         
         initAllRelated(setOldSelectedTargeting);
         initContentTree(conId);
         convertDTOTreItemToJson();
    }
    
    private Map<String, List<Content__c>> allCont2Childs;
    /**
     * @Desc: get all relate contents of tartgetingcontentassociation
     * @param: selectedContIds, Set<String> to store the selected content id that get from TargetingContentAssociation
     * @return
     * @createdate: 27/3/15
     * @author: suy sreymol
     */
    private void initAllRelated(Set<String> selectedContIds){ 
    	allCont2Childs = new Map<String, List<Content__c>>(); // clear before start
    	
    	Set<String> allRelatedCont = new Set<String>(); 
    	getContIdUpLevel(allRelatedCont, selectedContIds);  
    	getContIdDownLevel(allRelatedCont, selectedContIds);
    	getContIdCoLevel(allRelatedCont, selectedContIds); 
    	 
    	// init allCont2Childs for selectedContent   
    	for(Content__c cont :[Select Name, Type__c, Id, Site_Content_Category__c, DartName__c, (Select id From Contents__r Where Active__c = true limit 1) From Content__c where id IN :allRelatedCont and Active__c = true order by DartName__c ]){
            mContId2IsFolder.put(cont.Id, cont.Contents__r.size()>0); 
            //set all content ids into a set to use when searching
            setValidId.add(cont.Id); 
            if(cont.Site_Content_Category__c != null){
            	if(allCont2Childs.get(cont.Site_Content_Category__c)==null) allCont2Childs.put(cont.Site_Content_Category__c, new List<Content__c>());
            	allCont2Childs.get(cont.Site_Content_Category__c).add(cont);
            }
        } 
    }
    
    /**
     * @Desc: get all related contents of tartgetingcontentassociation of up level
     * @param: selectedContIds, Set<String> to store the selected content id that get from TargetingContentAssociation
     * @param: reference, Set<String> to store all related contents Id of selected content that get from TargetingContentAssociation
     * @return
     * @createdate: 27/3/15
     * @author: suy sreymol
     */
    private static void getContIdUpLevel(Set<String> reference, Set<String> selectedContIds){ 
    	Content__c[] lstCont = [Select id, Site_Content_Category__c From Content__c where id in :selectedContIds and Site_Content_Category__c != null and Active__c = true]; 
    	if(lstCont.isEmpty()) return;
    	
    	Set<String> temCurrentIds = new Set<String>();
    	for(Content__c con : lstCont){
    		reference.add(con.Site_Content_Category__c);
    		temCurrentIds.add(con.Site_Content_Category__c);
    	} 
    	getContIdUpLevel(reference, temCurrentIds); 
    }
    
    /**
     * @Desc: get all related contents of tartgetingcontentassociation of down level
     * @param: selectedContIds, Set<String> to store the selected content id that get from TargetingContentAssociation
     * @param: reference, Set<String> to store all related contents Id of selected content that get from TargetingContentAssociation
     * @return
     * @createdate: 27/3/15
     * @author: suy sreymol
     */
    private static void getContIdDownLevel(Set<String> reference, Set<String> currentContIds){ 
    	Content__c[] lstCont = [Select id, Site_Content_Category__c From Content__c where Site_Content_Category__c in :currentContIds and Site_Content_Category__c != null and Active__c = true]; 
    	if(lstCont.isEmpty()) return;
    	
    	Set<String> temCurrentIds = new Set<String>();
    	for(Content__c con : lstCont){
    		reference.add(con.Id);
    		temCurrentIds.add(con.Id);
    	} 
    	getContIdDownLevel(reference, temCurrentIds);																	
    }
    
    /**
     * @Desc: get all related contents of tartgetingcontentassociation of the same level
     * @param: selectedContIds, Set<String> to store the selected content id that get from TargetingContentAssociation
     * @param: reference, Set<String> to store all related contents Id of selected content that get from TargetingContentAssociation
     * @return
     * @createdate: 27/3/15
     * @author: suy sreymol
     */
    private static void getContIdCoLevel(Set<String> reference, Set<String> currentContIds){ 
    	Content__c[] lstCont = [Select id, Site_Content_Category__c From Content__c where Id in :currentContIds and Site_Content_Category__c != null and Active__c = true]; 
    	if(lstCont.isEmpty()) return;
    	
    	Set<String> parrentIds = new Set<String>();
    	for(Content__c cont : lstCont){
    		parrentIds.add(cont.Site_Content_Category__c); 
    	} 
    	for(Content__c con : [Select id, Site_Content_Category__c From Content__c where Site_Content_Category__c in :parrentIds and Active__c = true])
    	//for(Content__c con : [Select id, Site_Content_Category__c From Content__c where (Site_Content_Category__c in :parrentIds and Id in :currentContIds) and Active__c = true]) 
    	reference.add(con.Id); 	
    	
    	getContIdCoLevel(reference, parrentIds);															
    }
    
    /**
     * @Desc: create dto tree
     * @param: contId, String Id of top level 
     * @return
     * @createdate: 27/3/15
     * @author: suy sreymol
     */
    private void initContentTree(String contId){
        for(Content__c con : [Select Id, Name, Type__c, DartName__c From Content__c Where Active__c = true And Id =: contId]){
            String key = con.id;
            //pos,treeId,treeName,ParrentId,treeLv,isExpand,isHideCheckBox, treeType
            DTOTreeItem dto =new DTOTreeItem( 0, con.id, con.DartName__c, true, null , 1, false, false); 
            dto.isSelected = setOldSelectedTargeting.contains(key);
            dto.isExpand = setOldSelectedTargeting.contains(key);
            
            // Add Exist child to tree
            doSetExistValueToTree(dto); 
            content =  dto;
        }
        if(content!=null) checkisFolder(content.lstChild, true);  
    }
    
    private Map<Id, Boolean> mContId2IsFolder = new Map<Id, Boolean>();
    /**
     * @Desc: to test if a node should be displayed as folder
     * @param: listRoot, List<DTOTreeItem> list tree node
     * @param: isFolder, Boolean a flag that markes as folder or not
     * @return
     * @createdate: 27/3/15
     * @author: suy sreymol
     */
    private void checkisFolder(List<DTOTreeItem> listRoot, Boolean isFolder){
    	for(DTOTreeItem dto : listRoot){
    		if(dto.lstChild.isEmpty()){
    			dto.isFolder = isFolder;
    			if(mContId2IsFolder.get(dto.treeId)!=null) dto.isFolder = mContId2IsFolder.get(dto.treeId);
    		}else{
    			dto.isFolder = true;
    			checkisFolder(dto.lstChild, false); // recursived call
    		} 
    	} 
    }
    
    // Adding Existing TargetingAssociation to tree when page loaded
    private void doSetExistValueToTree(DTOTreeItem dto){
        if(allCont2Childs.containsKey(dto.treeId)) {
            for(Content__c cont : allCont2Childs.get(dto.treeId)) {
            	DTOTreeItem dtoChild =  new DTOTreeItem(dto.lstChild.size(), cont.Id , cont.DartName__c, (cont.Contents__r.isEmpty() || cont.Contents__r.size() < 1) ? false : true, dto.treeId, null, false, false);
            	 
                dtoChild.isExpand = dto.isSelected || setOldSelectedTargeting.contains(cont.id);   
                dtoChild.isSelected = dto.isSelected || setOldSelectedTargeting.contains(cont.id); 
            	 
            	dto.lstChild.add(dtoChild);
            	doSetExistValueToTree(dtoChild);
            }
        }   
    }
    
   public Set<String> setValidId = new Set<String>();  
   public String targetId{get;set;}
   public String tarText{get;set;}
   public Boolean isSaveError{get;set;}
   public Boolean isShowCancel{
        get{
            String froIfr = ApexPages.currentPage().getParameters().get('froIfr');
            return froIfr == null || froIfr=='' ? false : Boolean.valueOf( froIfr );
        }set;
    }
   
   /**
    * Save button clicked
    */
   public void saveRecords(){
        try{
            convertJsonToDTOTreeItem();
            String lineItemId = ApexPages.currentPage().getParameters().get('itemId');          
            isSaveError = false;
            if( targetId == null || targetId==''){           
                Targeting__c t = new Targeting__c(TempBinder__c = true, Description__c = 'TargetingTreeProduct');
                insert t;
                targetId = t.Id; 
            }   
            Set<String> sdartzone = new Set<String>();
            tarText='';
            
            //-02-07-2014: 
            //- Save only parent if all child are selected
            //- Save only child if all child doesn't selected all
            List<TargetingContentAssociation__c> targAss2bUpsert = new List<TargetingContentAssociation__c>();
            //create targeting association depend on the selected contents on the tree
            doCreateTargetAssociation(new List<DTOTreeItem>{content}, targAss2bUpsert, targetId);
            
            if(!targAss2bUpsert.isEmpty()) upsert targAss2bUpsert Target_Content_Key__c;
            //remove the unselected content association
            delete [Select Id From TargetingContentAssociation__c Where Targeting__c= :targetId And Id Not In :targAss2bUpsert ];
            //covert tree to json after updating 
			convertDTOTreItemToJson();            
            //populate all content name in the Rich_Line_Description__c of line items         
            if( lineItemId <> null && lineItemId != '') {
               	OpportunityLineItem oppProd = new OpportunityLineItem();
               	oppProd.Id = lineItemId;
                tarText = tarText !='' ? tarText.substring( 0, ( tarText.length() -1 )  ) : tarText;
                oppProd.Rich_Line_Description__c = tarText ;
                oppProd.Targeting__c = targetId;
                update oppProd;
            }
         }catch(Exception e){ ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());  ApexPages.addMessage(lastNameMsg); isSaveError = true;}
       
   }
   
    /**
     * @Desc : to set the search item to the tree if the search term is already on the tree
     * @param: node, DTOTreeItem the tree node that need to update to selected node
     * @return 
     * @author : suy sreymol
     * @createddat: 30/3/15
     */
   	private void doSelectExistingContent(DTOTreeItem node) {
   		for (DTOTreeItem dto : node.lstChild) {
   			if (selectedContent == dto.treeId) {
   				dto.isSelected = true;
            	dto.isExpand =  true;
            	break;
   			}
   			doSelectExistingContent(dto);
   		}
   	}
   	
   /**
    * @Desc: add the search content to the tree
    * @param
    * @return 
    * @author : suy sreymol
    * @modifiedDade: 30/03/15
    */
   public void addContent(){
         try {
         	//if no selected content from search results, nothing to do more
            if( selectedContent == null || selectedContent == '' ) return;
            convertJsonToDTOTreeItem();
            //if the selected content from search results table is the top level
            if ( selectedContent == content.treeId ) {
            	content.isSelected = true;
            	content.isExpand =  true;
            //if the selected content from search results table is the one which already in the tree
            } else if ( setValidId.contains(selectedContent) ) {
            	doSelectExistingContent(content);
            //if the selected content from search results table not yet on the tree
            } else {
            	setOldSelectedTargeting.add(selectedContent);
            	initAllRelated(setOldSelectedTargeting);
         		initContentTree(conId);
            }
            //convert dto to json update the nodes
            convertDTOTreItemToJson();
         }catch(Exception e){ ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()); ApexPages.addMessage(lastNameMsg);}
   	}
   
    // JS Remoting action called when searching for a content
    @RemoteAction
    global static List<Content__c > searchContent(String searchTerm, String topLevelId) { 
        List<Content__c> lstTmp = new List<Content__c>();
        try{   
            searchTerm = searchTerm<> null ? searchTerm.trim() : '';            
            String queryName = '%' + searchTerm.trim() + '%'; 
            String queryString = 'Select DartName__c, Id, Site_Content_Category__c From Content__c where DartName__c Like :queryName and Active__c = true order by DartName__c limit ' + CHILD_ROW_LIMIT_LOAD; 
            for (Content__c con : Database.query( queryString )) {
            	//if search results have the top level, add it to the results list
            	if (con.Id == topLevelId) lstTmp.add(con);
            	//add only content that has parent to the search result
            	else if (con.Site_Content_Category__c != null) lstTmp.add(con);
            }
        }catch(Exception e){ ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()); ApexPages.addMessage(lastNameMsg);}
        
        return lstTmp;
    }
    
	//HCS 06.09.2014
    //fixed error view state
    private static final Integer CHILD_ROW_LIMIT_LOAD = 20;
	private final String SHOW_MORE = 'Show more';
	private final String SHOW_MORE_KEY = 'SHOW_MORE';
	private final Integer CHILD_ROW_LIMIT_DISPLAY = 5;
	
	//return show more dto item
    private DTOTreeItem getShowMoreRecord( String nodeId, Integer pos){
		return new DTOTreeItem( pos, SHOW_MORE_KEY, SHOW_MORE , true, nodeId, 2, false, true);
	}
	
    private void collapsedAllTopNode(){
   		for(DTOTreeItem dtoNode : content.lstChild ){
   			dtoNode.isExpand = true;
   			collapsedAllChildNode(dtoNode);
   		}
	 }
	  
	 private void collapsedAllChildNode(DTOTreeItem node){ 
  		for (DTOTreeItem dtoNode: node.lstChild) {
  			dtoNode.isExpand = true;
  			collapsedAllChildNode(dtoNode);
  		}
	 }
	  
	/**
	 * @Desc: invok when user click on 'Show more' in the tree
	 * @author: sreymol
	 * @createddate: 27/3/15
	 */
	public void showMore(){
		try {
			//convert json to Dto tree
			convertJsonToDTOTreeItem();
			collapsedAllTopNode();
			//store existing child ids of the clicking node
			Set<String> currentChildIds = new Set<String>();
			//store the possition of childs node, postion start from the last index of list childs node
			Integer pos = currentChildIds.size();
			//do finding the existing childs of the clicking node
			getExistingChilds(content, currentChildIds);
			//to store list childs of node
			List<DTOTreeItem> dtoChilds = new List<DTOTreeItem>();
			//get more childs of the node limit 6 start from level 3
			String query = 'Select Id, DartName__c, Name, (Select Id From Contents__r where Active__c = true limit 1) From Content__c Where Active__c = true and Id NOT IN : currentChildIds And Site_Content_Category__c =: selectedContent order by DartName__c';
			//if start from level 2, it should get 5 childs
			if (selectedContent != content.treeId ) query += ' limit 6';
			List<Content__c> moreChilds = Database.query(query);
			for (Content__c c : moreChilds) 
			{
				//if childs list >= 5, stop to add child into list
				if (dtoChilds.size() >= CHILD_ROW_LIMIT_DISPLAY && selectedContent != content.treeId) break;
				//create new dto item
				DTOTreeItem dto = new DTOTreeItem(pos, c.Id, c.DartName__c, !c.Contents__r.isEmpty(), selectedContent, null, false, false);
				//increase one more number of position every loop
				pos++;
				//add child to list
				dtoChilds.add(dto);
			}
			
			//if the node not yet contains all childs, add show more button to get the left childs
			if (moreChilds.size() > CHILD_ROW_LIMIT_DISPLAY && selectedContent != content.treeId) dtoChilds.add(getShowMoreRecord(selectedContent, pos+1));
			
			//processing to add more childs to clicked node
			addMoreChilds(dtoChilds, content);
			//convert the updated tree to json string to update on the page
			convertDTOTreItemToJson();
		 }catch(Exception e){ ApexPages.Message lastNameMsg = new ApexPages.Message(ApexPages.Severity.Error, e.getMessage());  ApexPages.addMessage(lastNameMsg);}
	}
	
	/**
	 * @Desc: recusive method to find the click node on the tree and get all existing ids of the childs of the click node
	 * @param: node, DTOTreeItem node of the tree
	 * @param: existingIds, Set<String> set that contains all existing childs id of the clicking node
	 * @author: sreymol
	 * @createddate: 27/3/15
	 */
	public void getExistingChilds(DTOTreeItem node, Set<String> existingIds) {
		//if cliked node is the top level, no need to do anyting because the top level already get all childs
		if ( selectedContent == content.treeId ) return;
		//find the existing child of the clicked node
		for (DTOTreeItem treeItem : node.lstChild) {
			//if the clicked node found, add all existing childs ids to list. It will be used to filter when getting more childs
			if ( selectedContent == treeItem.treeParrentId ) {
				existingIds.add(treeItem.treeId);
				continue;
			}
			//if the clicked node not found, find it in other tree level
			getExistingChilds(treeItem, existingIds);
		}
	}
	
	/**
	 * @Desc: recusive method to find the click node on the tree and add new childs to existing childs list of the click node
	 * @param: node, DTOTreeItem node of the tree
	 * @param: lchilds, List<DTOTreeItem> new list childs that need to update on the tree
	 * @author: sreymol
	 * @createddate: 27/3/15
	 */
	public void addMoreChilds(List<DTOTreeItem> lchilds, DTOTreeItem node) {
		//if the clicking node is the top level, it shoud add list childs to it without recusive
		if (selectedContent == content.treeId) {
			content.lstChild.addAll(lchilds);
			return;
		} else {
			for (DTOTreeItem treeItem : node.lstChild) {
				if (treeItem.treeId == selectedContent) {
					//get last index number
					integer lastInd = treeItem.lstChild.size() - 1;
					//remove show more at the last index before add new lsit childs to node
					if (treeItem.lstChild.size() > CHILD_ROW_LIMIT_DISPLAY && treeItem.lstChild[lastInd].treeId == SHOW_MORE_KEY) treeItem.lstChild.remove(lastInd);
					//add new lsit childs to existing list
					treeItem.lstChild.addAll(lchilds);
					return;
				}
				//if cannot find the clicking node, find in other tree level
				addMoreChilds(lchilds, treeItem);
			}
		}
	}
	
    /**
     * go through the dto for:
     *   1 > create TargetingGeographyAssociation__c
     *   2 > add to list for upsert
     *   3 > populate string for assigning to lineitem 
     */
     private void doCreateTargetAssociation(DTOTreeItem[] lstDTO, List<TargetingContentAssociation__c> targAssTobeUpsert, String targetId){
     	if(lstDTO==null || lstDTO.isEmpty()) return;
     	for(DTOTreeItem dto : lstDTO){
     		checkAllChilds(dto);
            if(dto.isSelected){
            	Id contId = dto.treeId;
            	// 1 > create TargetingContentAssociation__c
            	TargetingContentAssociation__c tca = new TargetingContentAssociation__c(Targeting__c = targetId ,TargetingContent__c = contId, Target_Content_Key__c = targetId + contId);
                // 2 > add to list for upsert
                targAssTobeUpsert.add(tca);
                // 3 > populate string for assigning to lineitem 
                tarText += dto.treeName +','; 
                // 4 > next element of the loop
                continue;   
            }
            // recursive
            doCreateTargetAssociation(dto.lstChild, targAssTobeUpsert, targetId);
        }	
     }
     
     private void checkAllChilds(DTOTreeItem dto){
     	if( dto.lstChild == null || dto.lstChild.isEmpty() ) return;
     	
     	Integer countSelection = 0; 
     	for(DTOTreeItem child : dto.lstChild){
     		if(child.isSelected) countSelection++;
     	}
     	
     	if(dto.lstChild.size()==countSelection)
     	dto.isSelected = true;
     }
    
    public class DTOTreeItem {
        public Integer pos{get;set;}
        public String treeId{get;set;}
        public String treeName{get;set;}
        public String treeParrentId{get;set;}
        public List<DTOTreeItem> lstChild{get;set;}
        public Integer treeLv{get;set;}
        public Boolean isExpand{get;set;}
        public Boolean isHideCheckBox{get;set;}
        public Boolean isFolder{get;set;}
        public Boolean isSelected{get;set;}
        
        public DTOTreeItem(){}
        
        public DTOTreeItem(Integer pos,String treeId,String treeName,Boolean isFolder,String treeParrentId,Integer treeLv,Boolean isExpand,Boolean isHideCheckBox ){
            this.treeId = treeId;
            this.treeName = treeName;
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
}