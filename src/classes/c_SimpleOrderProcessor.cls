public without sharing class c_SimpleOrderProcessor implements c_Common.IOrderProcessor {
    // Constructor
    public c_SimpleOrderProcessor() {
        this.buildFieldConfiguration();
        this.response = new c_Common.ResponseObject();
        this.response.success = true;
        this.response.errorMessages = new List<String>();
        this.response.errorFieldMap = new Map<String,String>();
        this.response.responseMap = new Map<String,String>();
    }

    public c_Common.ResponseObject validate(String inputJson, Id portalOrderId) {
        c_Common.ResponseObject response = new c_Common.ResponseObject();
        response.success = true;
        response.errorMessages = new List<String>();
        response.errorFieldMap = new Map<String,String>();
        response.responseMap = new Map<String,String>();

        this.retrieveData(inputJson, portalOrderId);
        this.setValues();

        // Check our checkboxes...
        /*if (orderAccount.Billing_Preference__c == 'Direct Debit' && inputMap.get('checkbox_sepa') != 'on') {
            response.success = false;
            response.errorFieldMap.put('checkbox_sepa', 'Required field');
            response.errorMessages.add('You need to agree with SEPA if you want to use direct debit');
        }

        if (inputMap.get('checkbox_tc') != 'on') {
            response.success = false;
            response.errorFieldMap.put('checkbox_tc', 'Required field');
            response.errorMessages.add('You need to agree with T&C');
        }*/

        // Run all field validations..

        for (FieldConfiguration fc : this.fieldConfiguration) {
            if (orderAccount.Billing_Preference__c == 'Direct Debit' && fc.sfObjectName == 'Account' && (fc.sfFieldName == 'Billing_Preference__c' || fc.sfFieldName == 'BankAccountHolderName__c')) {
                fc.required = true;
            }
            FieldValidation fv = this.validateField(fc, (String) (fc.sfObjectName == 'Account' ? orderAccount.get(fc.sfFieldName) : orderContact.get(fc.sfFieldName)));
            if (fv.valid == false) {
                response.errorFieldMap.put(fc.inputFieldName, String.join(fv.errors,','));
                for (String e : fv.errors) {
                    response.errorMessages.add('Field ' + fc.inputFieldName + ': ' + e);
                }
                response.success = false;
            }
        }

        // Some page validations, if we find orderAccount.paymentMethod = 'Direct Debit' then required account holder and IBAN...


        // We need to run callouts before any DML (even with rollbacks..) so we run the accountvalidation to start with (but update account before)
        try {
            AccountValidator.IAccountValidator validator = AccountValidator.getValidator(orderAccount);
            Boolean taxCheck;
            Boolean bankCheck;
            Boolean accountNumberCheck;

            taxCheck = validator.checkAndSetCompanyTaxDetails();

            try {
                bankCheck = (orderAccount.Billing_Preference__c == 'Direct Debit') ? validator.checkAndSetBankDetails() : true;
            } catch (Exception e) {
                // Server might be down
                bankCheck = true;
            }

            accountNumberCheck = (orderAccount.Billing_Preference__c == 'Direct Debit') ? validator.checkBankAccountNumber() : true;


            if (!taxCheck) {
                response.success = false;
                response.errorFieldMap.put('account_vatnr', 'Invalid VAT number');
                response.errorMessages.add('Tax check failed');
            }
            if (!bankCheck) {
                response.success = false;
                response.errorFieldMap.put('bankaccount_iban', 'Invalid IBAN number');
                response.errorMessages.add('Bank check failed');
            }
            if (!accountNumberCheck ) {
                response.success = false;
                response.errorFieldMap.put('bankaccount_iban', 'Invalid IBAN number');
                response.errorMessages.add('Account number check failed');
            }

            // These were specific account validations, now object-level validations..

            Savepoint sp = Database.setSavePoint();
            try {
                update orderContact;
            } catch (Exception e) {
                // We expect this to render us some permission error, nothing else...
                response.errorMessages.add('E1: TYPE: ' + e.getTypeName() + ' MSG: ' + e.getMessage());
                response.success = false;
                response.errorFieldMap.putAll(c_Common.parseFieldErrorDetails(e, getFieldConfigurationMapFromSFName('Contact')));
            }

            try {
                update orderAccount;
            } catch (Exception e) {
                // We expect this to render us some permission error, nothing else...
                response.errorMessages.add('E2: TYPE: ' + e.getTypeName() + ' MSG: ' + e.getMessage());
                response.success = false;
                response.errorFieldMap.putAll(c_Common.parseFieldErrorDetails(e, getFieldConfigurationMapFromSFName('Account')));
            }

            Database.rollback(sp);

        } catch (Exception e) {
            response.success = false;
            response.errorMessages.add('Uncaught error: ' + e.getMessage());
            response.stackTrace = e.getStacktraceString();
            response.errorMessages.add('Account: ' + orderAccount);
        }

        return response;
    }

    public c_Common.ResponseObject save(String inputJson, Id portalOrderId) {
        c_Common.ResponseObject validateResponse;
        try {
            validateResponse = this.validate(inputJson, portalOrderId);
        } catch (Exception e) {
            response.success = false;
            response.errorMessages.add('Error in validate: ' + e.getMessage());
            response.stackTrace = e.getStacktraceString();
            return response;
        }

        if (validateResponse.success == false) {
            return validateResponse;
        } else {
            update orderContact;
            update orderAccount;

            if (portalOrder == null) {
                /* Save PO */
                PortalOrder__c po = new PortalOrder__c();
                po.Contact__c = orderContact.Id;
                po.PortalName__c = config.Name;
                po.Status__c = 'In progress';
                po.Account__c = orderAccount.Id;

                insert po;

                Attachment a = new Attachment();
                a.Name = 'formdata.json';
                a.Body = Blob.valueOf(inputJson);
                a.ParentId = po.Id;

                insert a;

                po.Status__c = 'Ready to process';
                update po;
            }

            return response;
        }
    }

    public c_Common.ResponseObject process(Id portalOrderId, List<Attachment> attachments) {
        c_Common.ResponseObject saveResponse;

        Map<String,String> attachmentMap = new Map<String,String>();
        for (Attachment a : attachments) {
            attachmentMap.put(a.Name, a.Body.toString());
        }

        String inputJson = attachmentMap.get('formdata.json');

        try {
            saveResponse = this.save(inputJson, portalOrderId);
        } catch (Exception e) {
            response.success = false;
            response.errorMessages.add('Error in save: ' + e.getMessage());
            response.stackTrace = e.getStacktraceString();
            return response;
        }

        if (saveResponse.success == false) {
            return saveResponse;
        } else {
            MemberUnit__c mu = [SELECT Id, Name FROM MemberUnit__c WHERE MemberUnitId__c = :config.MemberUnit__c];
            Product2 pr = (Product2) GW_sObject.queryRecord('Product2', portalProduct.Product__c);

            c_BaseOrderController.PortalProductPrice portalProductPrice = new c_BaseOrderController.PortalProductPrice(portalProduct.Id, null);

            // Insert opportunity
            Opportunity o = new Opportunity();
            if (config.OrderOpportunityName__c != null) {
                o.Name = config.OrderOpportunityName__c;
                if (o.Name.contains('{accountName}')) {
                    o.Name = o.Name.replace('{accountName}', orderAccount.Name);
                }
                if (o.Name.contains('{today}')) {
                    o.Name = o.Name.replace('{today}', String.valueOf(Date.today()));
                }
            } else {
            	o.Name = 'Self-service generated opportunity';
            }
            o.CloseDate = Date.today();
            o.AccountId = orderAccount.Id;
            o.Primary_Contact__c = orderContact.Id;
            o.MemberUnit__c = mu.Id;
            o.CurrencyIsoCode = portalProduct.CurrencyIsoCode;
            if(config.OpportunityOwner__c != null) {
              o.OwnerId = config.OpportunityOwner__c;
            }
            insert o;

            // Insert OLI
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.PricebookEntryId = portalProductPrice.pbe.Id;
            if (config.OrderEarliestStartDate__c != null && Date.today() < config.OrderEarliestStartDate__c) {
                oli.From_Date__c = config.OrderEarliestStartDate__c;
            } else {
                oli.From_Date__c = Date.today();
            }
            oli.Until_Date__c = oli.From_Date__c.addMonths(Integer.valueOf(pr.ContractPeriodInMonths__c)).addDays(-1);
            oli.SalesPriceNet__c = portalProductPrice.salesPriceNet;
            oli.UnitPrice = 0;
            oli.OpportunityId = o.Id;
            oli.Quantity = 1;
            insert oli;


			//UTIL.throwError('retrieved o: ' + GW_sObject.queryRecord('Opportunity', o.Id));

            Approval.ProcessSubmitRequest appReq = new Approval.ProcessSubmitRequest();
            appReq.setComments('Submitting for self-service');
            appReq.setObjectId(o.id);
            Approval.ProcessResult result = Approval.process(appReq);

            if (orderAccount.Billing_Preference__c == 'Direct Debit') {
                echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c();
                agreement.Name = 'Dummy mandate';
                agreement.echosign_dev1__Account__c = orderAccount.Id;
                agreement.MemberUnit__c = mu.Id;
                agreement.Type__c = 'Mandate';
                agreement.echosign_dev1__Recipient__c = orderAccount.Finance_contact__c;
                agreement.Billing_Preference__c = orderAccount.Billing_Preference__c;
                agreement.Bank_AccountNumber__c = orderAccount.Bank_AccountNumber__c;
                agreement.Bank_Name__c = orderAccount.Bank_Name__c;
                agreement.Bank_Account_Holder_Name__c = orderAccount.Name;
                agreement.echosign_dev1__Message__c = 'None';
                agreement.echosign_dev1__AgreementLocale__c = GW_Agreement.getLocale(orderAccount.Language_Preference__c);
                agreement.echosign_dev1__Opportunity__c = o.Id;
                insert agreement;
                agreement = GW_Agreement.getRecord(agreement.Id);
                agreement.Mandate_id__c = orderAccount.AccountExtId__c+'-'+agreement.AgreementNumber__c;
                agreement.Name = agreement.Mandate_Id__c;
                agreement.echosign_dev1__Status__c = 'Signed';
                update agreement;
            }

            o.ContractStatus__c = 'Signed';
            update o;

            //GW_Revenue.checkStatusChangeAndUpdate((List<Rev__c>) GW_sObject.getChildren(o.Id, 'Revenue_Items__r'));

            PortalOrder__c po = (PortalOrder__c) GW_sObject.queryRecord('PortalOrder__c', portalOrderId);
            po.Opportunity__c = o.id;
            update po;

            if (config.OrderConfirmationEmailAddress__c != null) {
                    this.sendEmailConfirmation(config.OrderConfirmationEmailTemplate__c, config.OrderConfirmationEmailAddress__c, portalOrder.Id);
            }

            response.responseMap = new Map<String,String>();
            response.responseMap.put('Opportunity__c', o.Id);
            response.responseMap.put('Account__c', orderAccount.Id);

            return response;
        }
    }

    private void sendEmailConfirmation(String emailTemplateName, String fromAddress, Id whatId) {
        OrgWideEmailAddress owea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = :fromAddress];
        EmailTemplate et = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = :emailTemplateName];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(et.Id);
        mail.setOrgWideEmailAddressId(owea.Id);
        mail.setWhatId(whatId);
        mail.setTargetObjectId(orderContact.Id);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    public c_Common.ResponseObject submitCase(String inputJson) {
        //this.retrieveData(inputJson, null);
        //this.setValues();

        c_Common.ResponseObject validateResponse;
        try {
            validateResponse = this.validate(inputJson, null);
        } catch (Exception e) {
            response.success = false;
            response.errorMessages.add('Error in validate: ' + e.getMessage());
            response.stackTrace = e.getStacktraceString();
            return response;
        }

        if (validateResponse.success == false) {
            return validateResponse;
        } else {
            update orderContact;
            update orderAccount;

            Case c = new Case();
            c.Origin = config.CaseOrigin__c;
            c.Description = 'Entered information:\n Account Name: ' + orderAccount.Name + '\n';
            c.Priority = config.CasePriority__c;
            c.Reason = config.CaseReason__c;
            c.Status = 'New';
            c.Subject = config.CaseSubject__c + ' ' + portalProduct.Name;
            c.Type = config.CaseType__c ;
            c.AccountId = orderAccount.Id;
            c.ContactId = orderContact.Id;
            c.RecordTypeId = UTIL_RecordType.getRecordTypeByName('Case','Customer').Id;
            c.MemberId__c = config.MemberUnit__c.substring(0,5);
            c.MemberUnitId__c = config.MemberUnit__c;
            c.OwnerId = config.CaseOwner__c == null ? UserInfo.getUserId() : config.CaseOwner__c;

            insert c;

            if (config.CaseConfirmationEmailTemplate__c != null) {
                this.sendEmailConfirmation(config.CaseConfirmationEmailTemplate__c, config.CaseConfirmationEmailAddress__c, c.Id);
            }

            return response;
        }
    }

    private void retrieveData(String inputJson, Id portalOrderId) {
        if (portalOrderId == null) {
            c_BaseController baseCtrl = new c_BaseController();
            orderAccount = baseCtrl.currentAccount;
            orderContact = baseCtrl.currentContact;
            config = baseCtrl.config;
        } else {
            portalOrder = (PortalOrder__c) GW_sObject.queryRecord('PortalOrder__c', portalOrderId);
            config = CommunityConfiguration__c.getInstance(portalOrder.PortalName__c);
            orderUser = (User) GW_sObject.queryRecord('User', portalOrder.CreatedById);
            orderContact = (Contact) GW_sObject.queryRecord('Contact', orderUser.ContactId);
            orderAccount = (Account) GW_sObject.queryRecord('Account', orderContact.AccountId);
        }

        inputMap = (Map<String,Object>) JSON.deserializeUntyped(inputJson);
        portalProduct = (PortalProduct__c) GW_sObject.queryRecord('PortalProduct__c', (Id) inputMap.get('product_id'));

        return;
    }

    private void setValues() {
        for (FieldConfiguration fc : this.fieldConfiguration) {
            String input = (String) inputMap.get(fc.inputFieldName);
            if (fc.valueMap != null) {
                Boolean found = false;
                for (String s : fc.valueMap.keySet()) {
                    if (s == input) {
                        input = fc.valueMap.get(input);
                        found = true;
                        break;
                    }
                }
                if (found == false) {
                    input = '';
                }
            }
            if (fc.trimSpaces) {
                input = input.replaceAll(' ','');
            }
            if (fc.sfObjectName == 'Account') {
                orderAccount.put(fc.sfFieldName, input);
            }
            if (fc.sfObjectName == 'Contact') {
                orderContact.put(fc.sfFieldName, input);
            }
        }

        orderAccount.Finance_contact__c = orderContact.Id;
    }

    private c_Common.ResponseObject createEmptyResponse() {
        c_Common.ResponseObject response = new c_Common.ResponseObject();
        response.success = true;
        response.errorMessages = new List<String>();
        response.errorFieldMap = new Map<String,String>();
        response.responseMap = new Map<String,String>();
        return response;
    }

    private void buildFieldConfiguration() {
        this.fieldConfiguration = new List<FieldConfiguration>();
        fieldConfiguration.add(new FieldConfiguration('Account', 'Name', 'account_name', true, 2, 100, false, null, false));
        fieldConfiguration.add(new FieldConfiguration('Account', 'Bank_AccountNumber__c', 'bankaccount_iban', false, 22, 22, false, null, true));
        fieldConfiguration.add(new FieldConfiguration('Account', 'BankAccountHolderName__c', 'bankaccount_name', false, 2, 100, false, null, false));
        fieldConfiguration.add(new FieldConfiguration('Account', 'Billing_Preference__c', 'payment_method', true, 0, 0, false, new Map<String,String>{'directdebit' => 'Direct Debit', 'invoice' => 'Invoice'}, false));
        fieldConfiguration.add(new FieldConfiguration('Account', 'Company_VAT_No__c', 'account_vatnr', false, 11, 11, false, null, false));
        fieldConfiguration.add(new FieldConfiguration('Account', 'BillingStreet', 'billing_street', true, 2, 100, false, null, false));
        fieldConfiguration.add(new FieldConfiguration('Account', 'BillingPostalCode', 'billing_postalcode', true, 5, 5, false, null, false));
        fieldConfiguration.add(new FieldConfiguration('Account', 'BillingCity', 'billing_city', true, 2, 100, false, null, false));
        fieldConfiguration.add(new FieldConfiguration('Account', 'BillingCountryCode', 'billing_country', true, 2, 3, false, null, false));
        fieldConfiguration.add(new FieldConfiguration('Contact', 'FirstName', 'contact_firstname', true, 2, 50, false, null, false));
        fieldConfiguration.add(new FieldConfiguration('Contact', 'LastName', 'contact_lastname', true, 2, 50, false, null, false));
        //fieldConfiguration.add(new FieldConfiguration('Contact', 'Email', 'contact_email', true, 5, 100, true, null, false));
        //fieldConfiguration.add(new FieldConfiguration('Contact', 'Phone', 'contact_phone', true, 8, 100, false, null, false));
    }

    private FieldValidation validateField(FieldConfiguration fc, String value) {
        FieldValidation fv = new FieldValidation();
        if (value != null && value.length() > 0) {
            if (fc.minLength > 0) {
                if (value.length() < fc.minLength) {
                    fv.valid = false;
                    fv.errors.add('Minimum length is ' + fc.minLength + ' found length was ' + value.length());
                }
            }
            if (fc.maxLength > 0) {
                if (value.length() > fc.maxLength) {
                    fv.valid = false;
                    fv.errors.add('Maximum length is ' + fc.maxLength + ' found length was ' + value.length());
                }
            }
        } else {
            if (fc.required) {
                fv.valid = false;
                fv.errors.add('Field is required but empty value passed');
            }
        }
        return fv;
    }


    private Map<String,String> getFieldConfigurationMap(String objectName, Boolean fromSFName) {
        Map<String,String> result = new Map<String,String>();
        for (FieldConfiguration fc : this.fieldConfiguration) {
            if (fc.sfObjectName == objectName || objectName == null) {
                if (fromSFName) {
                    result.put(fc.sfFieldName, fc.inputFieldName);
                } else {
                    result.put(fc.inputFieldName, fc.sfFieldName);
                }
            }
        }
        return result;
    }

    private Map<String,String> getFieldConfigurationMapFromInputName(String objectName) {
        return this.getFieldConfigurationMap(objectName, false);
    }

    private Map<String,String> getFieldConfigurationMapFromInputName() {
        return this.getFieldConfigurationMapFromInputName(null);
    }

    private Map<String,String> getFieldConfigurationMapFromSFName(String objectName) {
        return this.getFieldConfigurationMap(objectName, true);
    }

    private Map<String,String> getFieldConfigurationMapFromSFName() {
        return this.getFieldConfigurationMapFromSFName(null);
    }

    public class FieldConfiguration {
        public FieldConfiguration(String sfObjectName, String sfFieldname, String inputFieldName, Boolean required, Integer minLength, Integer maxLength, Boolean isEmail, Map<String,String> valueMap, Boolean trimSpaces) {
            this.sfObjectName = sfObjectName;
            this.sfFieldName = sfFieldName;
            this.inputFieldName = inputFieldName;
            this.required = required;
            this.minLength = minLength;
            this.maxLength = maxLength;
            this.valueMap = valueMap;
            this.isEmail = isEmail;
            this.trimSpaces = trimSpaces;
        }
        public Map<String,String> valueMap;
        public String sfObjectName;
        public String sfFieldName;
        public String inputFieldName;
        public Boolean required;
        public Integer minLength;
        public Integer maxLength;
        public Boolean isEmail;
        public Boolean trimSpaces;
    }

    public class FieldValidation {
        public FieldValidation() {
            this.valid = true;
            this.errors = new List<String>();
        }
        public Boolean valid;
        public List<String> errors;
    }

    Account orderAccount;
    Contact orderContact;
    User orderUser;
    CommunityConfiguration__c config;
    PortalOrder__c portalOrder;
    PortalProduct__c portalProduct;
    Map<String,Object> inputMap;
    c_Common.ResponseObject response;
    List<FieldConfiguration> fieldConfiguration;
}