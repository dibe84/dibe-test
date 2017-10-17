public class UTIL_Customizer {

	private String memberId;
	private String memberUnitId;
	private String templateCode;

	private String language;
	private Boolean isLanguageProvided;

	private List<String> baseTemplateNames;
    
    public static Map<String, Custom_ECG_Labels__c> labelMap {
        get {
            if (labelMap == null) {
                labelMap = Custom_ECG_Labels__c.getAll();
            }
            return labelMap;
        }
        
        private set;
    }

    public static Map<String, ApexPage> apexPageMap {
        get {
            if (apexPageMap == null) {
                List<ApexPage> pageResults = [SELECT Name FROM ApexPage];
    
                apexPageMap = new Map<String, ApexPage>();
        
                for (ApexPage p : pageResults ){
                    apexPageMap.put(p.Name, p);
                } 
            }
            return apexPageMap;
        }
        
        private set;
    }
    
    public static Map<String, Id> documentIdMap {
        get {
            if (documentIdMap == null) {
                documentIdMap = new Map<String, Id>();
                
                //Query all documents
                List<Document> documents = [SELECT Id, Developername FROM Document];
        
                for (Document document : documents){
                    documentIdMap.put(document.Developername, document.Id);
                }
            }
            return documentIdMap;
        }
        
        private set;
    }

    public static Map<String, List<VersionedDocumentVersion__c>> versionedDocumentVersionsMap {
        get {
            if (versionedDocumentVersionsMap == null) {
				versionedDocumentVersionsMap = new Map<String, List<VersionedDocumentVersion__c>>();

                //Query all documents
                List<VersionedDocumentVersion__c> docVersions = [
					SELECT Id, Version__c, StartDate__c, EndDate__c, VersionedDocument__r.ExternalId__c
					FROM VersionedDocumentVersion__c
				];

                for (VersionedDocumentVersion__c version : docVersions) {
					if (!versionedDocumentVersionsMap.containsKey(version.VersionedDocument__r.ExternalId__c)) {
						versionedDocumentVersionsMap.put(version.VersionedDocument__r.ExternalId__c, new List<VersionedDocumentVersion__c>());
					}
					versionedDocumentVersionsMap.get(version.VersionedDocument__r.ExternalId__c).add(version);
                }
            }
            return versionedDocumentVersionsMap;
        }

        private set;
    }

    public static Map<String, Id> emailTemplateIdMap {
        get {
            if (emailTemplateIdMap == null) {
                List<EmailTemplate> emailTemplates = [SELECT Id, DeveloperName FROM EmailTemplate];

                emailTemplateIdMap = new Map<String, Id>();
        
                for (EmailTemplate emailTemplate : emailTemplates ) {
                    emailTemplateIdMap.put(emailTemplate.Developername, emailTemplate.Id);
                }
            }
            return emailTemplateIdMap;
        }
        
        private set;
    }    
    
	public UTIL_Customizer(Member__c m, MemberUnit__c mu, Opportunity o, String language) {

		MemberUnit__c memberUnit = mu;
		Member__c member = (memberUnit != null && m == null && mu.Member__c != null) ? (Member__c) UTIL.getCached(mu.Member__c) : m;
		Opportunity opp = o;
		Pricebook2 pb = (opp != null && opp.PriceBook2Id != null) ? (PriceBook2) UTIL.getCached(opp.PriceBook2Id) : null;

		templateCode = (pb != null) ? pb.TemplateCode__c : null;
		memberId = (member != null) ? member.MemberId__c : null;
		memberUnitId = (memberUnit != null) ? memberUnit.MemberUnitId__c : null;

		init(language);
	}

	public UTIL_Customizer(String memberOrUnitId, String templateCode, String language) {

		this.memberId = (memberOrUnitId != null) ? memberOrUnitId.left(5) : '';
		this.memberUnitId = (memberOrUnitId != null && memberOrUnitId.length() > 5) ? memberOrUnitId : '';
		this.templateCode = templateCode;
		this.language = language;

		init(language);
	}

	private void init(String language) {

		this.language = language;
		this.isLanguageProvided = !String.isEmpty(this.language);
		this.setBaseTemplateNames();
	}

	///////////////////////////////////////////////////////////////////////////
	// Naming related methods
	//////////////////////////////////////////////////////////////////////////

	private void setBaseTemplateNames() {

		this.baseTemplateNames = new List<String>();
		if (!String.isEmpty(this.memberUnitId) && !String.isEmpty(this.templateCode)){
			String pbLevelTemplateName = '_' + this.memberUnitId + '_' + this.templateCode;
			if (this.isLanguageProvided) this.baseTemplateNames.add(pbLevelTemplateName + '_' + this.language);
			this.baseTemplateNames.add(pbLevelTemplateName);
		}
		if (!String.isEmpty(this.memberUnitId)) {
			String muLevelTemplateName = '_' + this.memberUnitId;
			if (this.isLanguageProvided) this.baseTemplateNames.add(muLevelTemplateName + '_' + this.language);
			this.baseTemplateNames.add(muLevelTemplateName);
		}
		if (!String.isEmpty(this.memberId)) {
			String memberLevelTemplateName = '_' + this.memberId;
			if (this.isLanguageProvided) this.baseTemplateNames.add(memberLevelTemplateName + '_' + this.language);
			this.baseTemplateNames.add(memberLevelTemplateName);
		}
		if (this.isLanguageProvided) this.baseTemplateNames.add('_' + this.language);

	}

	private List<String> getTemplateNames(String itemId) {

		List<String> templateNames = new List<String>();

		for(String baseTemplateName : this.baseTemplateNames) {
			templateNames.add(itemId + baseTemplateName);
		}
		templateNames.add(itemId);

		return templateNames;
	}

	///////////////////////////////////////////////////////////////////////////
	// Custom ECG Labels related methods (custom setting: Custom_ECG_Labels__c required)
	//////////////////////////////////////////////////////////////////////////

	public string getLabel(String itemId) {

		Custom_ECG_Labels__c selectedLabel = getLabelSetting(itemId);

		return selectedLabel.Value__c;
	}

	public string getLabel(String itemId, SObject sObj) {

		Custom_ECG_Labels__c selectedLabel = getLabelSetting(itemId);

		String labelParsedText = UTIL_StringParser.parseAndReplace(selectedLabel.Value__c, sObj);

		return labelParsedText;
	}

	private  Custom_ECG_Labels__c getLabelSetting(String itemId) {

		List<String> templateNames = getTemplateNames(itemId);

		Custom_ECG_Labels__c selectedLabel = null;

		for (String templateName : templateNames) {
            Custom_ECG_Labels__c currentLabel = labelMap.get(templateName);
			if ( currentLabel != null) {
				selectedLabel = labelMap.get(templateName);
				break;
			}
		}

		if (selectedLabel == null) {
			throw new UTIL.CustomException('Couldn\'t find custom label matching one of (' + JSON.serialize(templateNames) + ')');
		}

		return selectedLabel;
	}

	/////////////////////////////////////////////////////////////////////////
	//EmailTemplate related methods
	////////////////////////////////////////////////////////////////////////

	public EmailTemplate getEmailTemplate(String itemId) {

		List<String> templateNames = getTemplateNames(itemId);

		EmailTemplate selectedEmailTemplate = null;

		for (String templateName : templateNames) {
            Id emailTemplateId = emailTemplateIdMap.get(templateName);
			if (emailTemplateId != null) {
				selectedEmailTemplate = (EmailTemplate) UTIL.getCached(emailTemplateId);
				break;
			}
		}

		return selectedEmailTemplate;
	}

	/////////////////////////////////////////////////////////////////////////
	//VFTemplate related methods
	////////////////////////////////////////////////////////////////////////

	public PageReference getVFTemplate(String itemId) {

		List<String> templateNames = getTemplateNames(itemId);

		PageReference selectedPageReference = null;

		for (String templateName : templateNames) {
            ApexPage pageTemplate = apexPageMap.get(templateName);
			if (pageTemplate != null) {
				selectedPageReference =  new PageReference('/apex/'+templateName);
				break;
			}
		}

		if (selectedPageReference == null) {
			throw new UTIL.customException('No template available for item with id: '+ itemId + ' ' + JSON.serialize(templateNames));
		}

		return selectedPageReference;
	}

	////////////////////////////////////////////////////////////////////////////
	//Custom document related methods
	////////////////////////////////////////////////////////////////////////////

	public Document getDocument(String itemId) {

		List<String> templateNames = getTemplateNames(itemId);

		Document selectedDocument = null;

		for (String templateName : templateNames) {
			Id documentId = documentIdMap.get(templateName);
            if (documentId != null) {
				selectedDocument = (Document) UTIL.getCached(documentId);
				break;
			}
		}

		if (selectedDocument == null) {
			throw new UTIL.customException('No Document available for item with id: ' + itemId);
		}

		return selectedDocument;

	}

	public UTIL_Customizer.VersionedDocumentItem getVersionedDocument(String itemId, Date activeAtDate) {
		List<String> templateNames = getTemplateNames(itemId);

		Document selectedDocument = null;
		VersionedDocumentVersion__c activeVersion;

		for (String templateName : templateNames) {
			if (versionedDocumentVersionsMap.containsKey(templateName) && versionedDocumentVersionsMap.get(templateName).size() > 0) {
				activeVersion = UTIL_Customizer.findActiveVersionAtDate(versionedDocumentVersionsMap.get(templateName), activeAtDate);
			}
			if (null == activeVersion) { continue; }

			String templateVersionName = activeVersion.VersionedDocument__r.ExternalId__c + '_v' + activeVersion.Version__c;

			Id documentId = documentIdMap.get(templateVersionName);

			if (null == documentId) {
				throw new UTIL.CustomException('Versioned document \'' + templateVersionName + '\' not found!');
			}
			selectedDocument = (Document) UTIL.getCached(documentId);
		}
		if (null == selectedDocument) {
			throw new UTIL.customException('No Document available for item with id: ' + itemId);
		}
		return new UTIL_Customizer.VersionedDocumentItem(activeVersion, selectedDocument);
	}

	private static VersionedDocumentVersion__c findActiveVersionAtDate(List<VersionedDocumentVersion__c> versions, Date activeAtDate) {
		VersionedDocumentVersion__c activeVersion;

		for (VersionedDocumentVersion__c version : versions) {
			if (version.StartDate__c <= activeAtDate && (null == version.EndDate__c || activeAtDate <= version.EndDate__c)) {
				activeVersion = version;
				break;
			}
		}
		return activeVersion;
	}

	public class VersionedDocumentItem {
		public final VersionedDocumentVersion__c docVersion;
		public final Document doc;

		public VersionedDocumentItem(VersionedDocumentVersion__c docVersion, Document doc) {
			this.docVersion = docVersion;
			this.doc = doc;
		}
	}
}