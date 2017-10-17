/**
 * 
 * change log
 * 			suy sreymol			01-Dec-2016							#10195 - CD-1354 - Remove case sensitive from IBAN Validation: error with "de" but ok with "DE" 
 																	> checkBankAccountNumber() > Fix IBAN validation to work with insensitive data
 */
public with sharing class AccountValidator {

    private static final String DEFAULTACCOUNTVALIDATOR = 'AccountValidator.Default_AccountValidator';
	// interface
	public interface IAccountValidator{ 

        void init(Account acc);

        boolean checkAndSetCompanyTaxDetails();
        boolean checkAndSetBankDetails();
        boolean checkBankAccountNumber();

	}

	// factory
	public static IAccountValidator getValidator(Account acc) {
		String validatorType = AccountValidator.DEFAULTACCOUNTVALIDATOR;
        String countryCode = acc.BillingCountryCode;

        if (acc == null) throw new AccountValidatorException('Account is null');
        if (countryCode == null) throw new AccountValidatorException('Billing Country is null');

        if ('NL'.equals(countryCode) || 'BE'.equals(countryCode) || 'IT'.equals(countryCode) || 'SM'.equals(countryCode) || 'DE'.equals(countryCode) || 'DK'.equals(countryCode) || 'SE'.equals(countryCode))
             validatorType = 'AccountValidator.'+countryCode+'_AccountValidator';

        Type t = Type.forName(validatorType);
        if (t == null) throw new AccountValidatorException('Account Validator can not be instantiated: '+validatorType);

        IAccountValidator av = (IAccountValidator) t.newInstance();

        av.init(acc);
        return av;
    }

    // Virtual class handling common logic and properties
    public virtual class AbstractAccountValidator implements AccountValidator.IAccountValidator {
        private Account acc;

        public void init(Account acc) { this.acc = acc; }


        public virtual boolean checkAndSetCompanyTaxDetails() {return false;}
        public virtual boolean checkAndSetBankDetails() {return true;}
        public virtual boolean checkBankAccountNumber() {return false;}

    }

    // Specific implementations
    //

    public class IT_AccountValidator extends AccountValidator.AbstractAccountValidator {

        public override boolean checkAndSetCompanyTaxDetails() {return AccountValidator.checkVATForm(acc, 'IT');}
        public override boolean checkBankAccountNumber() {return AccountValidator.checkBankAccountNumber(acc);}

    }

    public class SM_AccountValidator extends AccountValidator.AbstractAccountValidator {

        public override boolean checkAndSetCompanyTaxDetails() {return AccountValidator.checkVATForm(acc, 'SM');}
        public override boolean checkBankAccountNumber() {return AccountValidator.checkBankAccountNumber(acc);}

    }

    public class NL_AccountValidator extends AccountValidator.AbstractAccountValidator {

        public override boolean checkAndSetCompanyTaxDetails() {return AccountValidator.checkVATForm(acc, 'NL');}
        //public override boolean checkAndSetBankDetails() {return AccountValidator.checkAndSetBankDetails(acc);}
        public override boolean checkBankAccountNumber() {return AccountValidator.checkBankAccountNumber(acc);}

    }

    public class DE_AccountValidator extends AccountValidator.AbstractAccountValidator {

        public override boolean checkAndSetCompanyTaxDetails() {return AccountValidator.checkVATForm(acc, 'DE');}
        //public override boolean checkAndSetBankDetails() {return AccountValidator.checkAndSetBankDetails(acc);}
        public override boolean checkBankAccountNumber() {return AccountValidator.checkBankAccountNumber(acc);}

    }

    public class DK_AccountValidator extends AccountValidator.AbstractAccountValidator {
        public override boolean checkAndSetCompanyTaxDetails() {return AccountValidator.checkVATForm(acc, 'DK');}
    }

	public class SE_AccountValidator extends AccountValidator.AbstractAccountValidator {
        public override boolean checkAndSetCompanyTaxDetails() {return AccountValidator.checkVATForm(acc, 'SE');}
    }

    public class BE_AccountValidator extends AccountValidator.AbstractAccountValidator {

        public override boolean checkAndSetCompanyTaxDetails() {return AccountValidator.checkVATForm(acc, 'BE');}
        //public override boolean checkAndSetBankDetails() {return AccountValidator.checkAndSetBankDetails(acc);}
        public override boolean checkBankAccountNumber() {return AccountValidator.checkBankAccountNumber(acc);}

    }

    private static Boolean checkVATForm(Account acc, String country) {
        
        String vatRegex = null;
        acc.Company_VAT_No__c = (acc.Company_VAT_No__c == null) ? '' :  acc.Company_VAT_No__c;
        
        // Removes white spaces and dots. Transform to Upper Case.
        String VATNumberInputNoSpaces = acc.Company_VAT_No__c.replace(' ', '')
                                                             .replace('.','')
                                                             .toUpperCase();
        
		acc.Company_VAT_No__c = VATNumberInputNoSpaces;

        if (country == 'DE') {
             vatRegex = 'DE[0-9]{9}';
        } else if (country == 'NL') {
             vatRegex = 'NL[0-9]{9}B[0-9]{2}';
        } else if (country == 'IT') {
             vatRegex = 'IT[0-9]{11}';
        } else if (country == 'BE') {
             vatRegex = 'BE[0-1]{1}[0-9]{9}';
        }
        else if (country == 'DK') {
            vatRegex = 'DK[0-9]{8}';
        }
        else if (country == 'SE') {
            vatRegex = 'SE[0-9]{12}';
        }
        if (country == 'SM') {
            vatRegex = 'SM[0-9]{5}';
        }

        if (vatRegex != null && VATNumberInputNoSpaces != '') {
            return Pattern.matches( vatRegex , VATNumberInputNoSpaces );
        } else if (VATNumberInputNoSpaces == '') {
            return true;
        } else if (vatRegex == null) {
            return false;
        }

        return false;
    }

    // provides validation for bankaccount string fields...
	private static Boolean checkBankAccountNumber(Account acc) {

        String accountNumber = acc.Bank_AccountNumber__c == null ? '' : acc.Bank_AccountNumber__c;
        //accountNumber = accountNumber.replace(' ', '');
        
        //remove all special characters include space
        accountNumber = accountNumber.replaceAll('[^0-9a-zA-Z]+', '').toUpperCase();
        acc.Bank_AccountNumber__c = accountNumber;

        Boolean isDutchIBANformat = Pattern.matches('NL[0-9]{2}[A-Z]{4}[0-9]{10}', accountNumber);
        Boolean isBelgiumIBANformat = Pattern.matches('BE[0-9]{14}', accountNumber);
        Boolean isLuxIBANformat = Pattern.matches('LU[0-9]{18}', accountNumber);
        Boolean isFranceIBANformat = Pattern.matches('FR[0-9]{19}[A-Z]{1}[0-9]{5}', accountNumber);
        Boolean isDeutschIBANformat = Pattern.matches('DE[0-9]{20}', accountNumber);
        Boolean isItalianIBANformat = Pattern.matches('IT\\d{2}[A-Z]\\d{10}[0-9A-Z]{12}', accountNumber);
        Boolean isSanMarinoIBANformat = Pattern.matches('SM\\d{2}[A-Z]\\d{10}[0-9A-Z]{12}', accountNumber);
        Boolean formatValid = isDutchIBANformat || isBelgiumIBANformat || isLuxIBANformat || isFranceIBANformat || isDeutschIBANformat || isItalianIBANformat || isSanMarinoIBANformat;

		if (formatValid) {
			return AccountValidator.checkIBAN(accountNumber);
		}
		return false;
	}

    public static Boolean checkIBAN( String inputIban ) {
        String iban;
        if( String.isBlank( inputIban) ) return false;
        else iban = inputIban.replace(' ', ''); // remove whitespace

        if( iban.length() > 34 || iban.length() < 5 ) return false; // check size
        String countryCode = iban.substring( 0, 2 ).toUpperCase(); // first two characters should be the countryCode
        String controlS = iban.substring( 2, 4 ); // next two characters are the control digits
        if( !controlS.isNumeric() ) return false;

        // basic bank account number starts at index 4
        String bban = iban.substring( 4 );

        // Only NL is checked and of this form: NLxxAAAAxxxxxxxxxx
        if( countryCode == 'NL' ) {
            if( iban.length() != 18 ) {
                return false;
            }
            String controlDigits = AccountValidator.generateControlDigits( bban, 'NL' );
            return controlDigits == controlS;
        } else if (countryCode == 'BE') {
            if (iban.length() != 16){
               return false;
            }
            String controlDigits = AccountValidator.generateControlDigits( bban, 'BE');
            return controlDigits == controlS;
        } else if (countryCode == 'LU') {
            if (iban.length() != 20){
               return false;
            }
            String controlDigits = AccountValidator.generateControlDigits( bban, 'LU');
            return controlDigits == controlS;
        }else if (countryCode == 'FR') {
            if (iban.length() != 27){
               return false;
            }
            String controlDigits = AccountValidator.generateControlDigits( bban, 'FR');
            return controlDigits == controlS;
        }else if (countryCode == 'DE') {
            if (iban.length() != 22){
               return false;
            }
            String controlDigits = AccountValidator.generateControlDigits( bban, 'DE');
            return controlDigits == controlS;
        }else if (countryCode == 'IT' || countryCode == 'SM') {
            if (iban.length() != 27){
               return false;
            }
            String controlDigits = AccountValidator.generateControlDigits( bban, countryCode);
            return controlDigits == controlS;
        }
        else{
           return false;
        }
    }

    private static String generateControlDigits( String bban, String landCode ) {
		// generate the control string
		String controlS = '';
		// - replace all characters in the iban with their base-36 equivalent
		for( Integer i = 0; i < bban.length(); i++ ) {
			String s = bban.substring( i, i + 1 );
			if( s.isNumeric() ) {
				controlS += s;
			} else if( s.isAlpha() && s.isAsciiPrintable() ) {
				controlS += letterCodes.get( s.toUpperCase() );
			} else {
				throw new AccountValidatorException( 'character at index ' + i + ' of basic bank account number \'' + bban + '\' is not ascii-alphanumeric' );
			}
		}
		// - replace all characters in the landcode with their base-36 equivalent
		for( Integer i = 0; i < landCode.length(); i++ ) {
			String s = landCode.substring( i, i + 1 );
			if( s.isAlpha() && s.isAsciiPrintable() ) {
				controlS += letterCodes.get( s.toUpperCase() );
			} else {
				throw new AccountValidatorException( 'character at index ' + i + ' of landcode \'' + landCode + '\' is not an ascii-alpha' );
			}
		}
		// add the final '00'
		controlS += '00';
		return AccountValidator.prefixWithZeroes( String.valueOf( 98 - AccountValidator.calcModLongNumber(controlS, 97) ), 2 );
	}

    /** Pads the string with zeroes until the maxLength is reached */
	private static String prefixWithZeroes( String s, Integer maxLength ) {
		Integer numPadZeroes = maxLength - s.length();
		if( numPadZeroes <= 0 ) {
			return s;
		}
		return '0'.repeat( numPadZeroes ) + s;
	}

    // Calculates the modulo of a long number (too long for a primitive type)
	private static integer calcModLongNumber(string longNumber, integer divider) {
		// longNumber must be a number
		if( !longNumber.isNumeric() ) throw new AccountValidatorException('calcModLongNumber: Not a valid number');

		Integer maxIntLength = 9;
		Integer startIndex = 0;
		Integer endIndex = Math.min( maxIntLength, longNumber.length() );

		// recursive pattern that take first <maxIntLength> digits of the long number, calculates the mod and places in front of the remaining digits, and repeats...
		if ( endIndex < longNumber.length() ) {
			String tmpNumber = longNumber.subString(startIndex, endIndex);
			String tmpRemainder = String.valueOf( Math.mod( Integer.valueOf( tmpNumber ), divider ) );
			String strResult = tmpRemainder + longNumber.subString(endIndex);
			return AccountValidator.calcModLongNumber(strResult, divider);
		} else {
			return Math.mod( Integer.valueOf( longNumber ), divider );
		}
	}

    public static List<String> allLetters {
		get {
			if( allLetters == null ) {
				allLetters = new String[] { 'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z' };
			}
			return allLetters;
		} set;
	}

	public static Map<String, String> letterCodes {
		get {
			if( letterCodes == null ) {
				letterCodes = new Map<String, String>();
				Integer start = 10;
				List<String> letters = allLetters;
				for( Integer i = 0; i < letters.size(); i++ ) {
					letterCodes.put( letters.get( i ), String.valueOf( start + i ) );
				}
			}
			return letterCodes;
		} set;
	}

    public class Default_AccountValidator extends AccountValidator.AbstractAccountValidator {

        public override boolean checkAndSetCompanyTaxDetails() {return true;}
        public override boolean checkAndSetBankDetails() {return true;}
        public override boolean checkBankAccountNumber() {return true;}

	}



	public class AccountValidatorException extends Exception {}
}