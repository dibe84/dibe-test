@isTest
private class TST_UTIL_Customizer {

	// Test Custom ECG Labels

	@isTest static void testCustomLabels(){

		List<Custom_ECG_Labels__c> labels = new List<Custom_ECG_Labels__c>();
		labels.add(new Custom_ECG_Labels__c(Name='IOSubject_ECITAAU_IT', Value__c='TEST MemberUnit Language {{name}}'));
		labels.add(new Custom_ECG_Labels__c(Name='IOSubject_ECITAAU', Value__c='TEST MemberUnit {{name}}'));
		labels.add(new Custom_ECG_Labels__c(Name='IOSubject_ECITA_IT', Value__c='TEST Member Language {{name}}'));
		labels.add(new Custom_ECG_Labels__c(Name='IOSubject_ECITA', Value__c='TEST Member {{name}}'));
		labels.add(new Custom_ECG_Labels__c(Name='IOSubject_IT', Value__c='TEST Default Language {{name}}'));
		labels.add(new Custom_ECG_Labels__c(Name='IOSubject', Value__c='TEST Default {{name}}'));

		insert labels;

		UTIL_Customizer customizer = new UTIL_Customizer(null, null, null, null);

		String testValue;

		try{
			testValue = customizer.getLabel('IOSubject', null);
			system.assert(false);
		}
		catch(Exception e) {
			system.assert(true);
		}

		Account testAcc = new Account(Name='test');
		insert testAcc;

		testValue = customizer.getLabel('IOSubject', testAcc);
		system.assertEquals('TEST Default test', testValue);

		Member__c member = new Member__c(Name='ECG Italy', MemberId__c='ECITA', Account__c=testAcc.Id);
		insert member;

		MemberUnit__c mu = new MemberUnit__c(Name='ECG Italy Automotive', Member__c=member.Id,  LineOfBusiness__c='AU');

		insert mu;

		mu = (MemberUnit__C) UTIL.getCached(mu.Id);

		member = (Member__c) UTIL.getCached(member.Id);

		customizer = new UTIL_Customizer(member, mu, null, 'IT');

		testValue = customizer.getLabel('IOSubject', testAcc);

		System.assertEquals('TEST MemberUnit Language test', testValue );

		customizer = new UTIL_Customizer(member, mu, null, 'NL');

		testValue = customizer.getLabel('IOSubject', testAcc);

		System.assertEquals('TEST MemberUnit test', testValue);

	}

	@isTest static void testVFTemplates() {

		UTIL_Customizer customizer = new UTIL_Customizer('THBELAU', null, 'FR');

		PageReference pr = customizer.getVFTemplate('IO');

		system.assertEquals('/apex/IO_THBELAU_FR', pr.getUrl());

		customizer = new UTIL_Customizer('THBELAU', null, 'IT');

		pr = customizer.getVFTemplate('IO');

		system.assertEquals('/apex/IO', pr.getUrl());

	}

	@isTest static void testEmailTemplates() {

		Folder f = [SELECT Id FROM Folder WHERE Type = 'Email' LIMIT 1];
		EmailTemplate et = new EmailTemplate(Name='IO_ECGNLAD_NL', developername='IO_ECGNL', body='test', subject='testEmail', templateType='text', folderId=f.Id);

		insert et;

		UTIL_Customizer customizer = new UTIL_Customizer('ECGNLAD', 'DM', 'NL');

		EmailTemplate testEt = customizer.getEmailTemplate('IO');

		system.assertEquals(et.Id, testEt.Id);

	}

	@isTest static void testDocuments() {

		Folder f = [SELECT Id FROM Folder WHERE Type = 'Document' LIMIT 1];
		Document d = new Document(Name='SalesTermsAndConditions_ECGNLAD_TT_NL', developername='SalesTermsAndConditions_ECGNLAD_TT_NL', keywords='test', folderId=f.Id);

		insert d;

		UTIL_Customizer customizer = new UTIL_Customizer('ECGNLAD', 'TT', 'NL');

		Document testd = customizer.getDocument('SalesTermsAndConditions');

		system.assertEquals(d.Id, testd.Id);
	}


    @isTest static void testVersionedDocuments() {
        Folder f = [SELECT Id FROM Folder WHERE Type = 'Document' LIMIT 1];
        Document d1 = new Document(Name = 'SalesTermsAndConditions_ECGNLAD_TT_NL_v1', developername = 'SalesTermsAndConditions_ECGNLAD_TT_NL_v1', keywords = 'test', folderId = f.Id);
        Document d2 = new Document(Name = 'SalesTermsAndConditions_ECGNLAD_TT_NL_v2', developername = 'SalesTermsAndConditions_ECGNLAD_TT_NL_v2', keywords = 'test', folderId = f.Id);
        insert new List<Document> { d1, d2 };

        VersionedDocument__c versionedDoc = new VersionedDocument__c(ExternalId__c = 'SalesTermsAndConditions_ECGNLAD_TT_NL');
        insert versionedDoc;

        VersionedDocumentVersion__c v1 = new VersionedDocumentVersion__c(Version__c = 1, VersionedDocument__c = versionedDoc.Id, StartDate__c = Date.newInstance(2015, 7, 1), EndDate__c = Date.newInstance(2016, 6, 30));
        VersionedDocumentVersion__c v2 = new VersionedDocumentVersion__c(Version__c = 2, VersionedDocument__c = versionedDoc.Id, StartDate__c = Date.newInstance(2016, 7, 1));
        insert new List<VersionedDocumentVersion__c> { v1, v2 };

        UTIL_Customizer customizer = new UTIL_Customizer('ECGNLAD', 'TT', 'NL');

        UTIL_Customizer.VersionedDocumentItem versionedDocItem = customizer.getVersionedDocument('SalesTermsAndConditions', Date.newInstance(2016, 1, 1));
        system.assertEquals(d1.Id, versionedDocItem.doc.Id);
        system.assertEquals(v1.Id, versionedDocItem.docVersion.Id);

        versionedDocItem = customizer.getVersionedDocument('SalesTermsAndConditions', System.today());
        system.assertEquals(d2.Id, versionedDocItem.doc.Id);
        system.assertEquals(v2.Id, versionedDocItem.docVersion.Id);

    }

}