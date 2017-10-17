/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description:
 * @references:
 *	- LPC_TargetingTreeSelector lightning component
 * @changeLog:
 *
 */
public without sharing class LPC_TargetingTreeSelectorController {

	public static final String VAL_SEPARATOR = ', ';
	public static final String DEVICE_TREE_TYPE = 'Device';
	public static final String GEO_TREE_TYPE = 'Geography';
	public static final String BROWSER_TREE_TYPE = 'Browser';
	public static final String CONNECTION_TREE_TYPE = 'Connection';
	public static final String BANDWIDTH_TREE_TYPE = 'Bandwidth';
	public static final String OS_TREE_TYPE = 'OperatingSystem';
	public static final String ADUNIT_TREE_TYPE = 'Ad_Unit';


    private static Map<String, String> mRelationChildren = new Map<String, String> {
		DEVICE_TREE_TYPE => 'Devices__r',
		GEO_TREE_TYPE => 'Geographies__r',
		BROWSER_TREE_TYPE => 'Devices__r',
		CONNECTION_TREE_TYPE => 'Connections__r',
		BANDWIDTH_TREE_TYPE => 'Connections__r',
		OS_TREE_TYPE => 'Devices__r',
		ADUNIT_TREE_TYPE => 'Contents1__r'
	};

	private static Map<String, String> mTypeToSObj = new Map<String, String> {
		DEVICE_TREE_TYPE => 'Devices__c',
		GEO_TREE_TYPE => 'Geography__c',
		BROWSER_TREE_TYPE => 'Devices__c',
		CONNECTION_TREE_TYPE => 'Connection__c',
		BANDWIDTH_TREE_TYPE => 'Connection__c',
		OS_TREE_TYPE => 'Devices__c',
		ADUNIT_TREE_TYPE => 'Content__c'
	};

    //Define checked node
    private static Map<Id, String> mapSelectedMode = new Map<Id, String>();
    private static Map<Id, List<DTOTreeItem>> mapParentChildNodes = new Map<Id, List<DTOTreeItem>>();
    private static Map<String, List<DTOTreeItem>> mapSelectedTreeName = new Map<String, List<DTOTreeItem>>();

	private static List<OpportunityLineItem> predefineId ;

    @AuraEnabled
    public List<DTOTreeItem> lsts { get; set; }

    /**
     * Check Existing Associate Nodes
     * @param treeType, type name
     * @param targetId, Targeting__c Id
     * @return Set<Id>
     */
    private static Set<Id> checkExistingAssociateNodes (String treeType, String targetId, String predefindedId) {

    	if (treeType == DEVICE_TREE_TYPE || treeType == BROWSER_TREE_TYPE || treeType == OS_TREE_TYPE) {
    		for( TargetingDeviceAssociation__c targeting:  [Select Device__r.Node_ID__r.DFP_API_Name__c, Device__r.Node_ID__c, Device__c, Device__r.Name, Device__r.DFP_API_Name__c, Device__r.MajorVersion__c, Device__r.MinorVersion__c  From TargetingDeviceAssociation__c Where Targeting__c=:targetId]){
	            mapSelectedMode.put(targeting.Device__c, 'checked');
	            String keyApiName =  targeting.Device__r.Node_ID__r.DFP_API_Name__c;
	            if(keyApiName == OS_TREE_TYPE) keyApiName = OS_TREE_TYPE;
	            else if(targeting.Device__r.DFP_API_Name__c == BROWSER_TREE_TYPE) keyApiName = BROWSER_TREE_TYPE;
	            else keyApiName = DEVICE_TREE_TYPE;
	            DTOTreeItem dto = new DTOTreeItem();
	            dto.treeId = targeting.Device__c;
            	dto.treeName = targeting.Device__r.Name;
            	dto.typeLabel = '';
            	dto.isContainsChilds = true;
	            if (BROWSER_TREE_TYPE == treeType) dto.typeLabel = ' (' + (targeting.Device__r.MajorVersion__c == 'Any'?'x':targeting.Device__r.MajorVersion__c) + '.' + (targeting.Device__r.MinorVersion__c=='Any'?'x':targeting.Device__r.MinorVersion__c) +')';
	            if(!mapSelectedTreeName.containsKey(keyApiName)) mapSelectedTreeName.put(keyApiName, new List<DTOTreeItem>());
	            mapSelectedTreeName.get(keyApiName).add(dto);
	     	}
    	}
     	if (treeType == CONNECTION_TREE_TYPE || treeType == BANDWIDTH_TREE_TYPE) {
     		for( TargetingConnectionAssociation__c targeting:  [Select Connection__c, Connection__r.DFP_API_Name__c, Connection__r.Name From TargetingConnectionAssociation__c Where Targeting__c=:targetId]){
	            mapSelectedMode.put(targeting.Connection__c, 'checked');
	            String keyApiName =  targeting.Connection__r.DFP_API_Name__c;
	            if(keyApiName != 'BandwidthGroup') keyApiName = CONNECTION_TREE_TYPE;
	            else keyApiName = BANDWIDTH_TREE_TYPE;
	            DTOTreeItem dto = new DTOTreeItem();
	            dto.treeId = targeting.Connection__c;
            	dto.treeName = targeting.Connection__r.Name;
            	dto.typeLabel = '';
            	dto.isContainsChilds = true;
	            if(!mapSelectedTreeName.keySet().contains(keyApiName)) mapSelectedTreeName.put(keyApiName, new List<DTOTreeItem>());
	            mapSelectedTreeName.get(keyApiName).add(dto);
	     	}
     	}
     	if (treeType == GEO_TREE_TYPE) {
     		for( TargetingGeographyAssociation__c targeting:  [Select Geography__c, Geography__r.Name, Geography__r.Type__c From TargetingGeographyAssociation__c Where Targeting__c=:targetId]){
	            mapSelectedMode.put(targeting.Geography__c, 'checked');
	            String keyApiName = GEO_TREE_TYPE;
	            DTOTreeItem dto = new DTOTreeItem();
	            dto.treeId = targeting.Geography__c;
            	dto.treeName = targeting.Geography__r.Name;
            	dto.typeLabel = ' (' + targeting.Geography__r.Type__c + ' )';
            	dto.isContainsChilds = true;
	            if(!mapSelectedTreeName.keySet().contains(keyApiName)) mapSelectedTreeName.put(keyApiName, new List<DTOTreeItem>());
	            mapSelectedTreeName.get(keyApiName).add(dto);
	     	}
     	}
     	if (treeType == ADUNIT_TREE_TYPE) {
     	    for( TargetingContentAssociation__c targeting:  [Select TargetingContent__c, TargetingContent__r.DartName__c, TargetingContent__r.Type__c From TargetingContentAssociation__c Where Targeting__c=:targetId ]){ //And TargetingContent__c <>:predefindedId
                mapSelectedMode.put(targeting.TargetingContent__c, 'checked');
                String keyApiName = ADUNIT_TREE_TYPE;
                DTOTreeItem dto = new DTOTreeItem();
                dto.treeId = targeting.TargetingContent__c;
                String strType = String.isEmpty(targeting.TargetingContent__r.Type__c) ? '' : targeting.TargetingContent__r.Type__c.substringAfter('-');
                dto.treeName = targeting.TargetingContent__r.DartName__c;
                dto.typeLabel = ' (' + strType.trim() + ')';
                dto.isContainsChilds = true;
                if(!mapSelectedTreeName.keySet().contains(keyApiName)) mapSelectedTreeName.put(keyApiName, new List<DTOTreeItem>());
                mapSelectedTreeName.get(keyApiName).add(dto);
            }

            for( PlacementTargetingAssociation__c placetargeting:  [Select Placement__r.Content_Category_Site__c, Placement__r.Content_Category_Site__r.DartName__c, Placement__r.Content_Category_Site__r.Type__c From PlacementTargetingAssociation__c Where Targeting__c=:targetId]){
                if(placetargeting.Placement__r.Content_Category_Site__c == null) continue;
                mapSelectedMode.put(placetargeting.Placement__r.Content_Category_Site__c, 'checked');
                String keyApiName = ADUNIT_TREE_TYPE;
                DTOTreeItem dto = new DTOTreeItem();
                dto.treeId = placetargeting.Placement__r.Content_Category_Site__c;
                dto.treeName = placetargeting.Placement__r.Content_Category_Site__r.DartName__c;
                String strType = placetargeting.Placement__r.Content_Category_Site__r.Type__c.substringAfter('-');
                dto.typeLabel = ' (' + strType.trim() + ')';
                dto.isContainsChilds = true;
                if(!mapSelectedTreeName.keySet().contains(keyApiName)) mapSelectedTreeName.put(keyApiName, new List<DTOTreeItem>());
                mapSelectedTreeName.get(keyApiName).add(dto);
            }
       	}
		return mapSelectedMode.keySet();
    }

    /**
     * Define h-checked nodes
     * Since Data Struture is a tree, we have to do recursive method. But it would be maximum 6 depths, so maximum 6 SQL queries only
     * @param treeType, type name
     * @param setCheckedIds, Set<Id> checked Ids
     */
    private static void checkParentAssociateNodes(String treeType, Set<Id> setCheckedIds, Set<Id> renderedIds) {
        Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;
    	Set<Id> parentIds = new Set<Id>();
    	String selectFields = '';
        if(treeType == BROWSER_TREE_TYPE){
            selectFields = ', MajorVersion__c, MinorVersion__c ';
        }else if(treeType == GEO_TREE_TYPE || treeType == ADUNIT_TREE_TYPE){
            selectFields = ', Type__c ';
        }

    	String queryStr = 'Select Name, Id, Node_ID__c' + selectFields + ' From ' + mTypeToSObj.get(treeType) + ' Where Id IN: setCheckedIds';
    	String parentFieldName = 'Node_ID__c';
    	String nodeFieldName = 'Name';
    	if (isContentTree) {
    	    queryStr = 'Select DartName__c, Id, Content__c' + selectFields + ', (Select Id  From ' + mRelationChildren.get(treeType) + ' Where Active__c = true limit 1) From ' + mTypeToSObj.get(treeType) + ' Where Id IN: setCheckedIds';
    	    parentFieldName = 'Content__c';
    	    nodeFieldName = 'DartName__c';
    	}
    	
    	
    	
     	for(SObject sobj : database.query(queryStr)) {
     		if (sobj.get(parentFieldName) != null) {
     			String parentId = String.valueOf(sobj.get(parentFieldName));
     			parentIds.add(parentId);
     			if (mapSelectedMode.get(parentId) != 'checked') {
     			    mapSelectedMode.put(parentId, 'hchecked');
     			}

     			//load parent to its children for first load
     			if (!mapParentChildNodes.containsKey(parentId)) {
     				mapParentChildNodes.put(parentId, new List<DTOTreeItem>());
     			}
     			DTOTreeItem dto = new DTOTreeItem();
	            dto.treeId = sobj.id;
	            dto.treeName = String.valueOf(sobj.get(nodeFieldName));
	            dto.isContainsChilds = true;
                if(isContentTree) dto.isContainsChilds = sobj.getSObjects(mRelationChildren.get(treeType)) != null;
	            dto.typeLabel = '';
	            if(treeType == BROWSER_TREE_TYPE){
	                dto.typeLabel = ' ('+ (sobj.get('MajorVersion__c') == 'Any'?'x': sobj.get('MajorVersion__c')) + '.' + (sobj.get('MinorVersion__c')=='Any'?'x':sobj.get('MinorVersion__c')) +')';
	            }else if(treeType == GEO_TREE_TYPE){
	                dto.typeLabel = ' ('+ sobj.get('Type__c') +')';
	            }else if(treeType == ADUNIT_TREE_TYPE){
	                String typ = String.valueOf(sobj.get('Type__c')) + '';
	                String strType = typ.substringAfter('-');
	                dto.typeLabel = ' ('+ strType.trim() +')';
	            }

	            if (!renderedIds.contains(sobj.id)) {
	               renderedIds.add(sobj.id);
	               mapParentChildNodes.get(parentId).add(dto);
	            }
     		}
    	}
    	if (!parentIds.isEmpty()) {
    		checkParentAssociateNodes(treeType, parentIds, renderedIds);
    	}
    }

	/**
     * Get Tree Data Source By Type at level 1
     * @param treeType, type name
     * @param targetId, Targeting__c Id
     * @param contentId, contentId for AdUnit Treee
     * @return List<SObject>
     */
	private static List<SObject> getTreeSourceByType(String treeType, String contentId) {
		String queryStr = '';

		if (treeType == DEVICE_TREE_TYPE) {

			queryStr = 'Select Id, Name, Node_ID__c, (Select id From Devices__r limit 1) From Devices__c ' +
			'Where DFP_API_Name__c <> \'OperatingSystem\' And DFP_API_Name__c <> \'Browser\' And Node_ID__c = null order by Name';

		} else if (treeType == GEO_TREE_TYPE) {

			queryStr = 'Select Id, Name, Node_ID__c, Type__c, (Select id From Geographies__r limit 1) From Geography__c ' +
			'Where Node_ID__c = null order by Name';

		} else if (treeType == BROWSER_TREE_TYPE) {

			queryStr = 'Select Id, Name, Node_ID__c, MajorVersion__c, MinorVersion__c,  (Select id From Devices__r limit 1) From Devices__c ' +
			'Where Node_ID__r.DFP_API_Name__c = \'Browser\' order by Name';

		} else if (treeType == CONNECTION_TREE_TYPE) {

			queryStr = 'Select Id, Name, Node_ID__c, (Select id From Connections__r limit 1) From Connection__c ' +
			'Where DFP_API_Name__c <> \'BandwidthGroup\' And Node_ID__c = null order by Name';

		} else if (treeType == BANDWIDTH_TREE_TYPE) {

			queryStr = 'Select Id, Name, Node_ID__c, (Select id From Connections__r limit 1) From Connection__c ' +
			'Where Node_ID__r.DFP_API_Name__c = \'BandwidthGroup\' order by Name';

		} else if (treeType == OS_TREE_TYPE) {

			queryStr = 'Select Id, Name, Node_ID__c, (Select id From Devices__r limit 1) From Devices__c ' +
			'Where Node_ID__r.DFP_API_Name__c = \'OperatingSystem\' And Node_ID__r.Node_ID__c = null order by Name';

		} else if (treeType == ADUNIT_TREE_TYPE) {

		    queryStr = 'Select Id, DartName__c, Content__c, Type__c,Site_Content_Category__c, (Select Id From ' + mRelationChildren.get(treeType) + ' Where Active__c = true limit 1) From Content__c  ' +
		    'Where (Id =: contentId) and Active__c = true order by DartName__c';

		}

		return database.query(queryStr);
	}

	/**
     * Get Tree Nodes By Type at level 1
     * @param treeType, type name
     * @param lineItemId, OpportunityLineItem Id
     * @return List<SObject>
     */
    @AuraEnabled
    public static RemoteResponse getTree(String treeType, String lineItemId) {
    	try{
    		OpportunityLineItem oppLine = [Select Name, Targeting__c, Product2.Content__c, Product2Id, Predefined_DeviceCategory__c, Predefined_Adunit__r.DartName__c, Predefined_Adunit__c,Predefined_Placement__r.Name,Predefined_Placement__r.Id From OpportunityLineItem Where Id =: lineItemId];
			String targetId = oppLine.Targeting__c;
			if (oppLine.Targeting__c == null) {
				Targeting__c tg = new Targeting__c(Description__c = oppLine.Name + ' Targeting');
				insert tg;
				targetId = tg.Id;
				oppLine.Targeting__c =  tg.Id;
				update oppLine;
			}
            String predefinedId = oppLine.Predefined_Adunit__c!=null?oppLine.Predefined_Adunit__c+'':'';

    		RemoteResponse response = new RemoteResponse();
	        List<Object> objs = getTargetingTree(treeType, targetId, oppLine.Product2.Content__c, predefinedId);

            Map<String, String> predefined = new Map<String, String>();
            Map<String,String> placement = new Map<String,String>();

            String predefinedAdunit = oppLine.Predefined_Adunit__r.DartName__c!=null?oppLine.Predefined_Adunit__r.DartName__c+'':'';
            String predefinedDevice = oppLine.Predefined_DeviceCategory__c!=null?oppLine.Predefined_DeviceCategory__c+'':'';

            String placementAdunit = oppLine.Predefined_Placement__r.Name!=null?oppLine.Predefined_Placement__r.Name +'':'';

            predefined.put('predefinedAdunit', predefinedAdunit);
            predefined.put('predefinedDevice', predefinedDevice);
           	predefined.put('placementAdunit',placementAdunit);
            objs.add(predefined);

            response.content = objs;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
    	}catch(Exception e){
    		return new RemoteResponse(e.getStackTraceString() + '  ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    	}
    	return new RemoteResponse();
    }

	/**
     * Get Tree Template Nodes By Type at level 1
     * @param treeType, type name
     * @param lineItemId, OpportunityLineItem Id
     * @return List<SObject>
     */
    @AuraEnabled
    public static RemoteResponse getTreeTemplate(String treeType, String targetId, String lineItemId) {
    	try{
    	    OpportunityLineItem oppLine = [Select Name, Targeting__c, Product2.Content__c, Product2Id From OpportunityLineItem Where Id =: lineItemId];
	        RemoteResponse response = new RemoteResponse();
	        List<Object> objs = getTargetingTree(treeType, targetId, oppLine.Product2.Content__c, '');
            response.content = objs;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
    	}catch(Exception e){
    		return new RemoteResponse(e.getStackTraceString() + '  ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    	}
    	return new RemoteResponse();
    }

	/**
     * Get TargetingTree Template Nodes By Type at level 1
     * @param treeType, type name
     * @param targetId, Targeting__c Id
     * @return List<Object>
     */
    private static List<Object> getTargetingTree(String treeType, String targetId, String contentId, String predefindedId){
    	mapSelectedTreeName = new Map<String, List<DTOTreeItem>>{
    		treeType => new List<DTOTreeItem>()
    	};
    	mapParentChildNodes = new Map<Id, List<DTOTreeItem>>();

    	Set<Id> exIds = checkExistingAssociateNodes(treeType, targetId, predefindedId);
    	Set<Id> renderedIds = new Set<Id>();
		checkParentAssociateNodes(treeType, exIds, renderedIds);

		Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;
        String nodeFieldName = 'Name';
        if (isContentTree) {
            nodeFieldName = 'DartName__c';
        }
		List<DTOTreeItem> lstTree = new List<DTOTreeItem>();
    	List<SObject> lSobject = getTreeSourceByType(treeType, contentId);
        for(SObject sobj : lSobject){
            DTOTreeItem dto =new DTOTreeItem();
            dto.treeId = sobj.id;

			dto.treeName = String.valueOf(sobj.get(nodeFieldName));
            if(treeType == BROWSER_TREE_TYPE){
            	dto.treeName = dto.treeName;
                dto.typeLabel = ' ('+ (sobj.get('MajorVersion__c') == 'Any'?'x': sobj.get('MajorVersion__c')) + '.' + (sobj.get('MinorVersion__c')=='Any'?'x':sobj.get('MinorVersion__c')) +')';
            }else if(treeType == GEO_TREE_TYPE){
            	dto.treeName = dto.treeName;
            	dto.typeLabel = ' ('+ sobj.get('Type__c') +')';
            }else if(treeType == ADUNIT_TREE_TYPE){
            	String typ = String.valueOf(sobj.get('Type__c'))+'';
            	String strType = typ.substringAfter('-');
            	dto.treeName = dto.treeName;
            	dto.typeLabel = ' ('+ strType.trim() +')';
            }

            dto.level = 1;
            dto.isContainsChilds = sobj.getSObjects(mRelationChildren.get(treeType)) != null;
            dto.selectMode = mapSelectedMode.containsKey(sobj.id) ? mapSelectedMode.get(sobj.id) : 'unchecked';
            dto.isSecretNode = false;
            lstTree.add(dto);
            //Add children on load
            addChildrenNode(dto, lstTree, isContentTree && true);
        }

        repareIndexList(lstTree);

        List<Object> objs = new List<Object>();
        objs.add(lstTree);
        objs.add(mapSelectedMode);
        objs.add(exIds);
        objs.add(mapSelectedTreeName);
        return objs;
    }

    /**
     * Repare Index of List
     * @param lstTree, List<DTOTreeItem>
     */
    private static void repareIndexList(List<DTOTreeItem> lstTree) {
    	Integer posIndex = 0;
        for (DTOTreeItem dto : lstTree) {
        	dto.pos = posIndex;
        	posIndex++;
        }
    }

    /**
     * Add Children Nodes to parent on retrieval
     * @param pnode, parent node
     * @param lstTree, children nodes
     * @param increaseLevel, fake level for adUnit Tree Nodes
     */
    private static void addChildrenNode(DTOTreeItem pnode, List<DTOTreeItem> lstTree, Boolean increaseLevel) {
    	if (!mapParentChildNodes.containsKey(pnode.treeId)) return;
    	List<DTOTreeItem> lstChildren = mapParentChildNodes.get(pnode.treeId);
    	for (DTOTreeItem dto : lstChildren) {
    		dto.level = pnode.level + 1;
    		if (increaseLevel) dto.level = dto.level + 1;
    		dto.selectMode = mapSelectedMode.containsKey(dto.treeId) ? mapSelectedMode.get(dto.treeId) : 'unchecked';
    		dto.isSecretNode = true;
    		lstTree.add(dto);
    		addChildrenNode(dto, lstTree, false);
    	}
    }

    /**
     * Get Children Nodes to add to parent on retrieval
     * @param treeType, type of tree
     * @param parentId, parent Id
     * @param level, parent level
     * @param mapDevSelectedMode, Selected Mode List
     * @return List<Object>
     */
    @AuraEnabled
    public static RemoteResponse getChildren(String treeType, String parentId, Integer level, Map<String, String> mapDevSelectedMode){
    	List<DTOTreeItem> lstTree = new List<DTOTreeItem>();

    	String selectFields = '';
    	if(treeType == BROWSER_TREE_TYPE){
    		selectFields = ', MajorVersion__c, MinorVersion__c ';
    	}else if(treeType == GEO_TREE_TYPE || treeType == ADUNIT_TREE_TYPE){
    		selectFields = ', Type__c ';
    	}

    	String queryStr = 'Select Id, Name '+ selectFields +', (Select Id  From ' + mRelationChildren.get(treeType) + ' limit 1) From ' + mTypeToSObj.get(treeType) + ' Where Node_ID__c =: parentId order by Name';
        String parentFieldName = 'Node_ID__c';
        String nodeFieldName = 'Name';
        Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;
        if (isContentTree) {
        	String strWhere = 'Active__c = true';
        	String parentIdFolder = parentId.substringAfter('-');
        	if(level == 2 && parentIdFolder == 'placement'){
    			parentId = parentId.substringBefore('-');
    			strWhere += ' And Site_Content_Category__c =: parentId';
        	}else if(level == 2 && parentIdFolder == 'adunit'){
        		parentId = parentId.substringBefore('-');
    			strWhere += ' And Content__c =: parentId';
        	}else{
        		strWhere += ' And Content__c =: parentId';
        	}
            queryStr = 'Select DartName__c, Id, Content__c '+ selectFields +', (Select Id  From ' + mRelationChildren.get(treeType) + ' Where Active__c = true limit 1) From ' + mTypeToSObj.get(treeType) + ' Where ' + strWhere + ' order by DartName__c';
            parentFieldName = 'Content__c';
            nodeFieldName = 'DartName__c';
        }
        try{
	        //add new placement tree
	        if(level == 1 && treeType == ADUNIT_TREE_TYPE){
	        	fetchContentTreeWithPlacement(treeType, parentId, level, lstTree, true);
	        }else{
	        	for(SObject sobj: database.query(queryStr)){
					DTOTreeItem dto =new DTOTreeItem();
		            dto.treeId = sobj.id;

					dto.treeName = String.valueOf(sobj.get(nodeFieldName));
					dto.typeLabel = '';
		            if(treeType == BROWSER_TREE_TYPE){
		            	dto.treeName = dto.treeName;
                        dto.typeLabel = ' ('+ (sobj.get('MajorVersion__c') == 'Any'?'x': sobj.get('MajorVersion__c')) + '.' + (sobj.get('MinorVersion__c')=='Any'?'x':sobj.get('MinorVersion__c')) +')';
		            }else if(treeType == GEO_TREE_TYPE){
		            	dto.treeName = dto.treeName;
		            	dto.typeLabel = ' ('+ sobj.get('Type__c') +')';
		            }
		            else if(treeType == ADUNIT_TREE_TYPE){
		            	String typ = String.valueOf(sobj.get('Type__c'))+'';
		            	String strType = typ.substringAfter('-');
		            	dto.treeName = dto.treeName;
		            	dto.typeLabel = ' ('+ strType.trim() +')';
		            }

		            dto.parentId = parentId;
		            dto.level = level + 1;
		            dto.isContainsChilds = sobj.getSObjects(mRelationChildren.get(treeType)) != null;
		           
		            dto.selectMode = mapDevSelectedMode.containsKey(sobj.id) ? mapDevSelectedMode.get(sobj.id) : 'unchecked';
		            dto.isSecretNode = false;
		            lstTree.add(dto);
		            //Add children on load
		            addChildrenNode(dto, lstTree, false);
				}
	        }

	    	repareIndexList(lstTree);

	    	List<Object> objs = new List<Object>();
		    objs.add(lstTree);

	    	RemoteResponse response = new RemoteResponse();
	        response.content = objs;
	        response.statusCode = RemoteResponse.STATUSCODE_OK;
	        return response;
	    }catch(Exception e){
            return new RemoteResponse(e.getStackTraceString() + '  ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
        return new RemoteResponse();
    }

    /**
     * Create Tree From Node Ids
     * @param treeType, Tree Type
     * @param parentId, Node parent Id
     * @param level, parent level
     * @param lstTree, tree to return
     * @param isGetChild, invoked from getChild method
     */
    private static void fetchContentTreeWithPlacement(String treeType, String parentId, Integer level, List<DTOTreeItem> lstTree, Boolean isGetChild) {
        //search result need an insertion to the tree
        Integer i = -1;
        for (DTOTreeItem nodeTree : lstTree) {
            if (!isGetChild) nodeTree.level = nodeTree.level + 1;
            if (!nodeTree.isPlacement) i++;
        }

        //adunit
        DTOTreeItem dto =new DTOTreeItem();
        dto.treeId = parentId + '-adunit';
        dto.treeName = 'Ad Units';
        dto.level = 2;
        dto.isContainsChilds = true;
        dto.selectMode = '';
        dto.isSecretNode = false;
        dto.isPlacement = false;

        //placement
        DTOTreeItem dto1 =new DTOTreeItem();
        dto1.treeId = parentId + '-placement';
        dto1.treeName = 'Placements';
        dto1.level = 2;
        dto1.isContainsChilds = true;
        dto1.selectMode = '';
        dto1.isSecretNode = false;
        dto1.isPlacement = false;
        if (isGetChild) {
            lstTree.add(dto);
            lstTree.add(dto1);
        } else {
            lstTree.add(i, dto1);
            lstTree.add(1, dto);
        }
    }

    /**
     * Create Tree From Node Ids
     * @param treeType, Tree Type
     * @param treeNodeIds, Nodes to create a tree
     * @param nodesToDisplay, Nodes to show based on filter
     * @param contentId, AdUnit Id
     * @return List<DTOTreeItem>
     */
    private static List<DTOTreeItem> createTreeFromNodeIds(String treeType, Set<String> treeNodeIds, Set<String> nodesToDisplay, String contentId) {
        String queryStr = 'Select Id, Name, Node_ID__c From ' + mTypeToSObj.get(treeType) + ' Where Id IN: treeNodeIds';
        String parentFieldName = 'Node_ID__c';
        String nodeFieldName = 'Name';
        Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;
        if (isContentTree) {
            queryStr = 'Select DartName__c, Id, Content__c,Site_Content_Category__c,Type__c From ' + mTypeToSObj.get(treeType) + ' Where Id IN: treeNodeIds';
            parentFieldName = 'Content__c';
            nodeFieldName = 'DartName__c';
        }
        if(treeType==GEO_TREE_TYPE){
        	queryStr = 'Select Id, Name, Node_ID__c, Type__c From ' + mTypeToSObj.get(treeType) + ' Where Id IN: treeNodeIds';
        }

        List<SObject> lTreeIncluded = database.query(queryStr);
        //Prepare Children
        Map<String, List<SObject>> mChildren = new Map<String, List<SObject>>();
        for (SObject sobj : lTreeIncluded) {
        	if( isContentTree && sobj.get('Type__c') + '' == 'Dart - ContentCategory') {
        		parentFieldName = 'Site_Content_Category__c';
        	}
            if (sobj.get(parentFieldName) == null) continue;
            String parentId = String.valueOf(sobj.get(parentFieldName));
            if (!mChildren.containsKey(parentId)) {
                mChildren.put(parentId, new List<SObject>());
            }
            mChildren.get(parentId).add(sobj);
        }

        //Create Tree Structure
        List<SObject> lTreeSource = getTreeSourceByType(treeType, contentId);
        List<DTOTreeItem> lstTree = new List<DTOTreeItem>();
        for (SObject sobjRoot : lTreeSource) {
            if (!treeNodeIds.contains(sobjRoot.Id)) {
                continue;
            }
            createTreeFromSObject(treeType, isContentTree, lstTree, sobjRoot, 1, mChildren, nodesToDisplay);
        }
        return lstTree;
    }

    /**
     * Create Tree From SObject
     * Since Data Struture is a tree, we have to do recursive method. But it would be maximum 6 depths, so maximum 6 SQL queries only
     * @param isContentTree, AdUnit Tree
     * @param lstTree, Tree Result
     * @param sobjNode, Node of tree
     * @param level, current level
     * @param nodesToDisplay, Nodes to show based on filter
     * @param mChildren, children belonging to sobjNode
     */
    private static void createTreeFromSObject(String treeType, Boolean isContentTree, List<DTOTreeItem> lstTree, SObject sobjNode, Integer level, Map<String, List<SObject>> mChildren, Set<String> nodesToDisplay) {
        String parentFieldName = 'Node_ID__c';
        String nodeFieldName = 'Name';
        DTOTreeItem dto =new DTOTreeItem();
        if (isContentTree) {
            parentFieldName = 'Content__c';
            nodeFieldName = 'DartName__c';
            dto.isPlacement = sobjNode.get('Type__c') == 'Dart - ContentCategory';
            dto.treeName = String.valueOf(sobjNode.get(nodeFieldName));
        }
        dto.typeLabel = '';
        if(treeType == BROWSER_TREE_TYPE){
            dto.typeLabel = ' ('+ (sobjNode.get('MajorVersion__c') == 'Any'?'x': sobjNode.get('MajorVersion__c')) + '.' + (sobjNode.get('MinorVersion__c')=='Any'?'x':sobjNode.get('MinorVersion__c')) +')';
        }else if(treeType == GEO_TREE_TYPE){
            dto.typeLabel = ' ('+ sobjNode.get('Type__c') +')';
        }else if(treeType == ADUNIT_TREE_TYPE){
            String typ = String.valueOf(sobjNode.get('Type__c'))+'';
            String strType = typ.substringAfter('-');
            dto.typeLabel = ' ('+ strType.trim() +')';
        }

        dto.treeId = sobjNode.id;
        dto.treeName = String.valueOf(sobjNode.get(nodeFieldName));
        dto.parentId = sobjNode.get(parentFieldName) == null ? (isContentTree ? (sobjNode.get('Site_Content_Category__c')== null ? null : sobjNode.get('Site_Content_Category__c')+'') : null )  : String.valueOf(sobjNode.get(parentFieldName));
        dto.level = level;
        dto.isContainsChilds = mChildren.containsKey(sobjNode.id);
        dto.selectMode = 'unchecked';
        dto.isSecretNode = !nodesToDisplay.contains(sobjNode.id);
        lstTree.add(dto);
        if (dto.isContainsChilds) {
		    List<SObject> lchildren = mChildren.get(sobjNode.id);
		    for (SObject sobjChild : lchildren) {
		        createTreeFromSObject(treeType, isContentTree, lstTree, sobjChild, level + 1, mChildren, nodesToDisplay);
		    }
        }
    }

    /**
     * Find matching parent to nodes
     * Since Data Struture is a tree, we have to do recursive method. But it would be maximum 6 depths, so maximum 6 SQL queries only
     * @param treeType, Tree Type
     * @param includedNodeIds, Nodes to create a tree
     * @param matchingNodeIds, children nodes
     */
    private static void findMatchingParentNodes(String treeType, Set<String> includedNodeIds, Set<String> matchingNodeIds) {
        Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;
        String queryStr = 'Select Id, Name, Node_ID__c From ' + mTypeToSObj.get(treeType) + ' Where Id IN: matchingNodeIds';
        String parentFieldName = 'Node_ID__c';
        String nodeFieldName = 'Name';
        if (isContentTree) {
            queryStr = 'Select DartName__c, Id, Content__c,Site_Content_Category__c,Type__c From ' + mTypeToSObj.get(treeType) + ' Where Id IN: matchingNodeIds';
            parentFieldName = 'Content__c';
            nodeFieldName = 'DartName__c';
        }

        for (String nodeId : matchingNodeIds) {
           includedNodeIds.add(nodeId);
        }
        Set<String> parentIds = new Set<String>();
        for(SObject sobj: database.query(queryStr)){
        	if(isContentTree && sobj.get('Type__c')+''== 'Dart - ContentCategory') {
        		parentFieldName = 'Site_Content_Category__c';
        	}
            if (sobj.get(parentFieldName) == null) {
                includedNodeIds.add(sobj.id);
                continue;
            }
            String parentId = String.valueOf(sobj.get(parentFieldName));
            parentIds.add(parentId);
        }
        if (!parentIds.isEmpty()) {
            findMatchingParentNodes(treeType, includedNodeIds, parentIds);
        }
    }

    /**
     * To maintain the selection behaviour in tree, we have to include other nodes in same level to result
     * @param treeType, Tree Type
     * @param includedNodeIds, more nodes to create a tree
     */
    private static void includeNodesInSameLvl(String treeType, Set<String> includedNodeIds) {
        Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;
        String queryStr = 'Select Id, Name, Node_ID__c From ' + mTypeToSObj.get(treeType) + ' Where Node_ID__c IN: includedNodeIds';
        String parentFieldName = 'Node_ID__c';
        String nodeFieldName = 'Name';
        if (isContentTree) {
            queryStr = 'Select DartName__c, Id, Content__c From ' + mTypeToSObj.get(treeType) + ' Where Content__c IN: includedNodeIds';
            parentFieldName = 'Content__c';
            nodeFieldName = 'DartName__c';
        }
        Set<String> parentIds = new Set<String>();
        for(SObject sobj: database.query(queryStr)){
          includedNodeIds.add(sobj.id);
        }
    }

    /**
     * Do Save Tree to SObject Records
     * @param treeType, Tree Type
     * @param textSearch, Keyword to find
     * @param lineItemId, OppLine Id
     * @return List<DTOTreeItem>
     */
    @AuraEnabled
    public static RemoteResponse doSearchTree (String treeType, String textSearch, String lineItemId) {
        try{
            OpportunityLineItem oppLine = [Select Name, Targeting__c, Product2.Content__c, Product2Id From OpportunityLineItem Where Id =: lineItemId];
	        Set<String> matchingNodeIds = new Set<String>();
	        Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;

	        String queryStr = 'Select Id, Name, Node_ID__c From ' + mTypeToSObj.get(treeType) + ' Where Name like \'%' + String.escapeSingleQuotes(textSearch) + '%\' order by Name';
	        if (isContentTree) {
	            queryStr = 'Select DartName__c, Id, Type__c, Content__c From ' + mTypeToSObj.get(treeType) + ' Where DartName__c like \'%' + String.escapeSingleQuotes(textSearch) + '%\' order by DartName__c';
	        }
	        if(treeType == GEO_TREE_TYPE){
	        	queryStr = 'Select Id, Name, Node_ID__c, Type__c From ' + mTypeToSObj.get(treeType) + ' Where Name like \'%' + String.escapeSingleQuotes(textSearch) + '%\' order by Name';
	        }
	        for(SObject sobj: database.query(queryStr)){
	            matchingNodeIds.add(sobj.id);
	        }
	        Set<String> treeNodeIds = new Set<String>();
	        List<DTOTreeItem> lstTree = new List<DTOTreeItem>();
	        Set<String> nodesToDisplay = new Set<String>();
	        if (!matchingNodeIds.isEmpty()) {
	            findMatchingParentNodes(treeType, treeNodeIds, matchingNodeIds);
	            nodesToDisplay.addAll(treeNodeIds);
	            includeNodesInSameLvl(treeType, treeNodeIds);
	            lstTree = createTreeFromNodeIds(treeType, treeNodeIds, nodesToDisplay, oppLine.Product2.Content__c);
	        }
	        if (isContentTree && !lstTree.isEmpty()) {
	           fetchContentTreeWithPlacement(treeType, lstTree[0].treeId, 1, lstTree, false);
	        }
	        List<Object> objs = new List<Object>();
	        objs.add(lstTree);
	        RemoteResponse response = new RemoteResponse();
	        response.content = objs;
	        response.statusCode = RemoteResponse.STATUSCODE_OK;
	        return response;
        }catch(exception e){
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

    /**
     * Apply selected string to OpportunityLineItem
     * @param oppLine, OpportunityLineItem
     * @param targetId, Targeting__c Id
     */
    private static void setTargetingString(OpportunityLineItem oppLine, String targetId) {
    	List<String> deviceSet = new List<String>();
    	for (TargetingDeviceAssociation__c deviceAss : [Select Device__r.Name From TargetingDeviceAssociation__c Where Targeting__c=: targetId]) {
    		deviceSet.add(deviceAss.Device__r.Name);
    	}
    	oppLine.Device_Targeting__c = String.join(deviceSet, VAL_SEPARATOR);


    	List<String> connectionSet = new List<String>();
    	for (TargetingConnectionAssociation__c connAss : [Select Connection__r.Name From TargetingConnectionAssociation__c Where Targeting__c=: targetId]) {
    		connectionSet.add(connAss.Connection__r.Name);
    	}
    	oppLine.Connection_Targeting__c = String.join(connectionSet, VAL_SEPARATOR);

    	List<String> geographySet = new List<String>();
    	for (TargetingGeographyAssociation__c geoAss : [Select Geography__r.Name From TargetingGeographyAssociation__c Where Targeting__c=: targetId]) {
    		geographySet.add(geoAss.Geography__r.Name);
    	}
    	oppLine.Geography__c = String.join(geographySet, VAL_SEPARATOR);

    	List<String> contentSet = new List<String>();
        for (TargetingContentAssociation__c contAss : [Select TargetingContent__c, TargetingContent__r.DartName__c From TargetingContentAssociation__c Where Targeting__c=: targetId]) {
            contentSet.add(contAss.TargetingContent__r.DartName__c);
        }
        oppLine.Rich_Line_Description__c = String.join(contentSet, VAL_SEPARATOR);

    	update oppLine;
    }

    /**
     * Do Save Tree to SObject Records
     * @param treeType, Tree Type
     * @param lineItemId, OpportunityLineItem Id
     * @param lstTobeSaved, String to save
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse doSaveRecords(String treeType, String lineItemId, String lstTobeSaved){
    	try{
	    	OpportunityLineItem oppLine = [Select Name, Targeting__c From OpportunityLineItem Where Id =: lineItemId];

			String targetId = oppLine.Targeting__c;
			if (oppLine.Targeting__c == null) {
				Targeting__c tg = new Targeting__c(Description__c = oppLine.Name + ' Targeting');
				insert tg;
				targetId = tg.Id;
				oppLine.Targeting__c =  tg.Id;
			}
			String nodeDes = doSaveRecordsTargetingTree(treeType, targetId, lstTobeSaved);
			oppLine.Device_Targeting__c = nodeDes;

			setTargetingString(oppLine, targetId);

	    	RemoteResponse response = new RemoteResponse();
	        response.statusCode = RemoteResponse.STATUSCODE_OK;
	        response.message = nodeDes;

	        return response;
    	}catch(exception e){
    		return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }

	/**
     * Do Save Tree Template to SObject Records
     * @param treeType, Tree Type
     * @param lineItemId, OpportunityLineItem Id
     * @param lstTobeSaved, String to save
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse doSaveRecordsTempleate(String treeType, String targetId, String lstTobeSaved){
    	try{

			String nodeDes = doSaveRecordsTargetingTree(treeType, targetId, lstTobeSaved);

	    	RemoteResponse response = new RemoteResponse();
	        response.statusCode = RemoteResponse.STATUSCODE_OK;

	        return response;
    	}catch(exception e){
    		return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }

	/**
     * Do Save Records of Targeting Tree
     * @param treeType, Tree Type
     * @param targetId, Targeting__c Id
     * @param lstTobeSaved, String to save
     * @return String
     */
    public static String doSaveRecordsTargetingTree(String treeType, String targetId, String lstTobeSaved){
    	try{
			List<DTOTreeItem> lstDto = (List<DTOTreeItem>) JSON.deserialize(lstTobeSaved, List<DTOTreeItem>.class);

			List<String> nodeDes = new List<String>();
			Set<String> assoNotToDelete = new Set<String>();

			if (treeType == DEVICE_TREE_TYPE || treeType == BROWSER_TREE_TYPE || treeType == OS_TREE_TYPE) {
	    		List<TargetingDeviceAssociation__c> lstTargs = new List<TargetingDeviceAssociation__c>();
				for(DTOTreeItem dto : lstDto){
					String conId = dto.treeId;
		            TargetingDeviceAssociation__c tca = new TargetingDeviceAssociation__c(Targeting__c = targetId ,Device__c  = conId , TargetDevice__c  = targetId + conId);
		            lstTargs.add(tca);
		            assoNotToDelete.add(tca.TargetDevice__c);
		            nodeDes.add(dto.treeName);
				}
				if(!lstTargs.isEmpty())  upsert lstTargs TargetDevice__c ;
				if(treeType == DEVICE_TREE_TYPE) delete [Select Id From TargetingDeviceAssociation__c Where Targeting__c= :targetId And (TargetDevice__c Not In :assoNotToDelete) AND Device__r.DFP_API_Name__c <>: OS_TREE_TYPE And Device__r.DFP_API_Name__c <>: BROWSER_TREE_TYPE];
				else if(treeType == BROWSER_TREE_TYPE) delete [Select Id From TargetingDeviceAssociation__c Where Targeting__c= :targetId And (TargetDevice__c Not In :assoNotToDelete) AND Device__r.DFP_API_Name__c =: BROWSER_TREE_TYPE];
				else if(treeType == OS_TREE_TYPE) delete [Select Id From TargetingDeviceAssociation__c Where Targeting__c= :targetId And (TargetDevice__c Not In :assoNotToDelete) AND Device__r.DFP_API_Name__c =: OS_TREE_TYPE];

	    	}
	     	if (treeType == CONNECTION_TREE_TYPE || treeType == BANDWIDTH_TREE_TYPE) {
	     		List<TargetingConnectionAssociation__c> lstTargs = new List<TargetingConnectionAssociation__c>();
				for(DTOTreeItem dto : lstDto){
					String conId = dto.treeId;
		            TargetingConnectionAssociation__c tca = new TargetingConnectionAssociation__c(Targeting__c = targetId ,Connection__c  = conId , TargetConnection__c  = targetId + conId);
		            lstTargs.add(tca);
		            assoNotToDelete.add(tca.TargetConnection__c);
		            nodeDes.add(dto.treeName);
				}
				if(!lstTargs.isEmpty())  upsert lstTargs TargetConnection__c ;
				if (treeType == CONNECTION_TREE_TYPE) delete [Select Id From TargetingConnectionAssociation__c Where Targeting__c =: targetId And (TargetConnection__c Not In :assoNotToDelete) AND Connection__r.DFP_API_Name__c <> 'BandwidthGroup' ];
		    	else if(treeType == BANDWIDTH_TREE_TYPE) delete [Select Id From TargetingConnectionAssociation__c Where Targeting__c =: targetId And (TargetConnection__c Not In :assoNotToDelete) AND Connection__r.DFP_API_Name__c = 'BandwidthGroup' ];

	     	}
	     	if (treeType == GEO_TREE_TYPE) {
	     		List<TargetingGeographyAssociation__c> lstTargs = new List<TargetingGeographyAssociation__c>();
				for(DTOTreeItem dto : lstDto){
					String conId = dto.treeId;
		            TargetingGeographyAssociation__c tca = new TargetingGeographyAssociation__c(Targeting__c = targetId ,Geography__c  = conId , TargetGeography__c  = targetId + conId);
		            lstTargs.add(tca);
		            assoNotToDelete.add(tca.TargetGeography__c);
		            nodeDes.add(dto.treeName);
				}
				if(!lstTargs.isEmpty())  upsert lstTargs TargetGeography__c ;
				delete [Select Id From TargetingGeographyAssociation__c Where Targeting__c =: targetId And (TargetGeography__c Not In :assoNotToDelete) ];

	     	}
	     	if (treeType == ADUNIT_TREE_TYPE) {
                List<TargetingContentAssociation__c> lstTargs = new List<TargetingContentAssociation__c>();
                List<PlacementTargetingAssociation__c> lstPlacesTarget = new List<PlacementTargetingAssociation__c>();
                Map<Id,String> mapDTOTree = new  Map<Id,String>();

                for(DTOTreeItem dto : lstDto){
                    String conId = dto.treeId;
                    String arrTreeType = dto.typeLabel.substringBetween('(',')');
                    String paymentName = dto.treeName.substringBeforeLast('(');
                    if(arrTreeType.contains('ContentCategory')){
                    	mapDTOTree.put(dto.treeId,paymentName);
                    }else{

                    	TargetingContentAssociation__c tca = new TargetingContentAssociation__c(Targeting__c = targetId ,TargetingContent__c  = conId , Target_Content_Key__c  = targetId + conId);
                    	lstTargs.add(tca);
                    	assoNotToDelete.add(tca.Target_Content_Key__c);
                    }
                    nodeDes.add(dto.treeName);
                }
                List<Content__c> newLstContent = new List<Content__c>();
                predefineId = [SELECT Predefined_Adunit__r.Id,Predefined_Placement__r.Id FROM OpportunityLineItem WHERE Targeting__c =: targetId limit 1];

               	if(!mapDTOTree.isEmpty()){
                	List<Content__c> lstContent = [SELECT Id,Name,(SELECT Id,Name, Content_Category_Site__c FROM Placement__r) FROM Content__c WHERE Id In: mapDTOTree.keySet()];
                	//Placement Predefine  Id and Adunit Predefine Id
                	for(content__c con :lstContent){
                		if(con.Placement__r.isEmpty()){
                			newLstContent.add(con);
                		}else{
                				PlacementTargetingAssociation__c pta = new PlacementTargetingAssociation__c(Targeting__c = targetId,Placement__c = con.Placement__r[0].Id);
                				lstPlacesTarget.add(pta);
                		}
                	}
                }

                if(!newLstContent.isEmpty()){
                	List<Placement__c> lstPlacement = createPlacement(newLstContent,mapDTOTree);
                	for(Placement__c place : lstPlacement){
                		PlacementTargetingAssociation__c pta = new PlacementTargetingAssociation__c(Targeting__c = targetId,Placement__c = place.Id );
                		lstPlacesTarget.add(pta);
                	}
                }

                if(!lstPlacesTarget.isEmpty())  upsert lstPlacesTarget ;

                if(!predefineId.isEmpty()){
	                if(checkPredefinePlacementOppLine(lstPlacesTarget,predefineId[0]) == false){
	                	 OpportunityLineItem oppline = [SELECT Id ,Predefined_Placement__c FROM OpportunityLineItem WHERE Targeting__c =: targetId limit 1];
	                	 oppline.Predefined_Placement__c = null;
	                	 update oppline;

	                }
	            }
                delete [Select Id From PlacementTargetingAssociation__c Where Targeting__c =: targetId And Id Not In :lstPlacesTarget ]; //And Placement__c <>: predefineId[0].Predefined_Placement__r.Id

                if(!lstTargs.isEmpty())  upsert lstTargs Target_Content_Key__c ;
                if(checkPredefineAdunitOppLine(lstTargs,predefineId[0]) == false){
                	 OpportunityLineItem oppline = [SELECT Id ,Predefined_Adunit__c FROM OpportunityLineItem WHERE Targeting__c =: targetId limit 1];
                	 oppline.Predefined_Adunit__c = null;
                	 update oppline;
                }
                delete [Select Id From TargetingContentAssociation__c Where Targeting__c =: targetId And (Target_Content_Key__c Not In :assoNotToDelete)]; //And TargetingContent__c <>: predefineId[0].Predefined_Adunit__r.Id

            }
	        return String.join(nodeDes, VAL_SEPARATOR);
    	}catch(exception e){
    		system.debug(e.getStackTraceString() + ' ' + e.getMessage());
    		return '';
    	}
    }

    private static Boolean checkPredefinePlacementOppLine(List<PlacementTargetingAssociation__c> lstPlaceTargeting,OpportunityLineItem oppline){
    	if(!lstPlaceTargeting.isEmpty()){
    		for(PlacementTargetingAssociation__c obj : lstPlaceTargeting){
    			if(obj.Placement__c == oppline.Predefined_Placement__c){
    				return true;
    			}
    		}
    	}
    	return false;
    }

    private static Boolean checkPredefineAdunitOppLine(List<TargetingContentAssociation__c> lstAdunitTargeting,OpportunityLineItem oppline){
		if(!lstAdunitTargeting.isEmpty()){
			for(TargetingContentAssociation__c obj : lstAdunitTargeting){
				if(obj.TargetingContent__c == oppline.Predefined_Adunit__c){
					return true;
				}
			}
		}
		return false;
	}

   /**
    * Create New Placement__c If Content__c don't have
    */
    private static List<Placement__c> createPlacement(List<Content__c> lstContent,Map<Id,String> mapDTOTree){
		List<Placement__c> lstPlacement = new List<Placement__c>();
		for(Content__c con : lstContent){
			Placement__c newPlacement =	new Placement__c();
			newPlacement.Name = mapDTOTree.get(con.Id);
    		newPlacement.Content_Category_Site__c = con.Id;
    		newPlacement.Dart_ID__c = Decimal.valueOf(con.Name);
    		newPlacement.CurrencyIsoCode = userInfo.getDefaultCurrency();
    		lstPlacement.add(newPlacement);
		}

		try {
			insert lstPlacement;
		} catch(Exception ex) {}

    	return lstPlacement;
    }

    /**
     * TreeItem Wrapper Class
     */
    public class DTOTreeItem {
    	@AuraEnabled
    	public Integer pos{get;set;}
    	@AuraEnabled
        public String treeId{get;set;}
        @AuraEnabled
        public String treeName{get;set;}
        @AuraEnabled
        public String parentId{get;set;}
        @AuraEnabled
        public Integer level{get;set;}
        @AuraEnabled
        public String selectMode{get;set;}
        @AuraEnabled
        public Boolean isContainsChilds{get;set;}
        @AuraEnabled
        public Boolean isSecretNode{get;set;}
        @AuraEnabled
        public String typeLabel{get;set;}

        public Boolean isPlacement {get;set;}
    }
}