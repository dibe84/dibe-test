/**
 * Created by ronvelzeboer on 13/09/16.
 */

public with sharing class VAL_EBAYK {

    public class AccountVATFieldsValidator implements UTIL_FieldValidator.IDelegatedValidator {
        public AccountVATFieldsValidator() { }

        public UTIL_FieldValidator.IFieldValidationResult validate(SObject so, FieldValidation__c fv) {
            Account acc = (Account) so;

            if (acc.Apply_VAT__c == true && String.isNotEmpty(acc.Company_VAT_No__c)) {
                String applyVATFieldLabel = GW_sObject.getFieldLabel('Account', 'Apply_VAT__c');
                String companyVATNoFieldLabel = GW_sObject.getFieldLabel('Account', 'Company_VAT_No__c');
                return new UTIL_FieldValidator.InvalidErrorResult(so, null, fv, null);
            }
            return null;
        }
    }
	
	public class AccountLocalPlatform implements UTIL_FieldValidator.IDelegatedValidator {
        public AccountLocalPlatform() { }

        public UTIL_FieldValidator.IFieldValidationResult validate(SObject so, FieldValidation__c fv) {
            Account acc = (Account) so;
            
            UserRole ur = GW_User.getUserRole(UserInfo.getUserId());
            Boolean isCreatedByAD = (acc.id == null && ur != null && ur.DeveloperName == 'EBAYKAD');
            if( !isCreatedByAD ) {
				if(!UTIL_WSC_Subscription.isAccOnlyAdsales(acc.id) ) {
					if(acc.UniquePlatformId__c == null) {
						String fname = GW_sObject.getFieldLabel('Account', 'UniquePlatformId__c');
						return new UTIL_FieldValidator.IncompleteErrorResult(so, fname, fv, null);
					}
				}
            }
            return null;
        }
    }
}