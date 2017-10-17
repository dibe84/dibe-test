public with sharing class VAL_VIES {
	public VAL_VIES() {	}

	public class VATValidation implements UTIL_FieldValidator.IDelegatedValidator {
        public VATValidation() { }

        public UTIL_FieldValidator.IFieldValidationResult validate(SObject so, FieldValidation__c fv) {
            Account acc = (Account) so;

			if(acc.Company_Vat_No__c == '' && acc.Apply_VAT__c == FALSE) {
				return new UTIL_FieldValidator.IncompleteErrorResult(so, null, fv, null);
			}

			if(GW_Account.isVIESValidationApplicable(acc) && acc.VAT_Check_Result__c != 1 && acc.VAT_Check_Result__c != 0) {
				return new UTIL_FieldValidator.IncompleteErrorResult(so, null, fv, null);
			}

			return null;
        }
    }
}