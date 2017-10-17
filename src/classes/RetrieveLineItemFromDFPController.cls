/**
 * @created date: 15-06-2015
 * @autor: Chr
 * @desc: Retrieving lineItem's fields from DFP and update to SF controller
 * 		Start Time --> save in externalFromDate__c
 *		End Time --> save in externalEndDate__c
 *		Quantity --> save in externalQuantity__c
 *		Rate type --> save in externalBillngCategory__c
 *		Rate --> save in externalSalesPrice__c
 */

public with sharing class RetrieveLineItemFromDFPController {
	
	private List<DARTObject.DARTAds> lstItems;
	private OpportunityLineItem item;
	private String dartVersion;
    private AdServer_Login__c credential;
	
	/**
	 * Contructor
	 */
	public RetrieveLineItemFromDFPController(OpportunityLineItem item){
		this.item = item;
		lstItems = new List<DARTObject.DARTAds>();
		dartVersion = item.PricebookEntry.Product2.RecordType.Name;
		credential = DARTUtil.getCredential(dartVersion,item.PriceBookEntry.Product2.Site__r.Country__c);
	}
	
	/**
	 * Method to invoke request to DFP and parse DFP's lineItem to SF object
	 */
	public void retrieveLineItemValueFromDFP(){
		HTTPWrapper.IGenericRequest dartItemRequest = FactoryDARTRequest.getInstance().createGetLineItemRequestByAdIds(credential, item);
        DART6Parser.IDartParser dartItemParser = FactoryParser.getInstance().createItemAdditionalFiledParser(dartVersion, item);
        DARTObject.IDARTConnector dartItemCon = FactoryConnector.getInstance().createConnector(dartVersion, dartItemRequest, dartItemParser);
        dartItemCon.connect();
        lstItems = (List<DARTObject.DARTAds>) dartItemCon.getDartObjects();
	}
	
	/**
	 * @return lineItem object(DARTAds)
	 */
	public List<DARTObject.DARTAds> getObjectLineItem() {
		return lstItems;
	} 
	
}