public with sharing class PriceCalculator {

	private static final String DEFAULTPRICECALCULATOR = 'PriceCalculator.Default_PriceCalculator';
	// interface
	public interface IPriceCalculator {
		void init(PriceCalculatorInput pci);
		Decimal getListPrice();
		Integer getBundleSize();
		Decimal getUPCF();
		Decimal getDefaultQuantity();
		Decimal getSalesPriceNet();
		Decimal getCustomListPrice();
		Boolean applyListPrice();
		Boolean applyBundleSize();
		Boolean applySalesPriceNet();
		Boolean applyCustomListPrice();
	}

	// factory
	public static IPriceCalculator getCalculator(PriceCalculatorInput pci) {
		String calcType = '';
		if (pci == null) throw new PriceCalculatorException('PCI is NULL');
		if (pci.pbe == null) throw new PriceCalculatorException('PBE is NULL');

		if (String.isBlank(pci.pbe.PriceCalculator__c) || pci.pbe.PriceCalculator__c == 'Default') {
			calcType = PriceCalculator.DEFAULTPRICECALCULATOR;
		}
		else {
			calcType = 'PriceCalculator.' + pci.pbe.PriceCalculator__c.deleteWhitespace() + '_PriceCalculator';
		}
		Type t = Type.forName(calcType);
		if (t == null) throw new PriceCalculatorException('Revenue Calculator can not be instantiated: ' + calcType);

		IPriceCalculator pc = (IPriceCalculator) t.newInstance();
		pc.init(pci);
		return pc;
	}

	public static Decimal calculateSalesPriceNet(Decimal unitPrice, Decimal defaultAdjustmentFixed, Decimal defaultAdjustmentPercentage) {
		Decimal calculatedUnitPrice = unitPrice;
		if (defaultAdjustmentFixed != null) {
			calculatedUnitPrice += defaultAdjustmentFixed;
		}
		if (defaultAdjustmentPercentage != null) {
			calculatedUnitPrice = calculatedUnitPrice * ((100 + defaultAdjustmentPercentage) / 100);
		}
		return calculatedUnitPrice.setScale(5);
	}
	
	public static Decimal calculateSalesPriceNet( PriceCalculator.PriceCalculatorInput pci ) {
        
        Decimal lpcDiscount = pci.oli.ListPriceCorrectionForm__c == null ? 0 : pci.oli.ListPriceCorrectionForm__c;
	    
	    Decimal postLPCDiscount = pci.oli.ListPrice__c + lpcDiscount;
	    
	    Decimal agencyComission = pci.oli.IndirectDiscount__c == null ? 0 : pci.oli.IndirectDiscount__c;
	    
	    Decimal salesPriceNet = ( postLPCDiscount * ( 100 - agencyComission ) ).divide( 100 , 5 );
	    
		return salesPriceNet;
	}

	public static String getBillingCategory(Product2 prod) {
		String billingCat = '';
		try {
			String firstBillingCatCalc = prod.Billing_Category__c.split(';')[0];
			billingCat = firstBillingCatCalc.split('_')[0];
		} catch (Exception e) {
			UTIL.Log('Exception inside PriceCalculator.getBillingCategory(): ' + e);
		}
		return billingCat;
	}

	public static String getBillingCalculation(Product2 prod) {
		String billingCalc = '';
		try {
			String firstBillingCatCalc = prod.Billing_Category__c.split(';')[0];
			billingCalc = firstBillingCatCalc.split('_')[1];
		} catch (Exception e) {
			UTIL.Log('Exception inside PriceCalculator.getBillingCategory(): ' + e);
		}
		return billingCalc;
	}

	// apply
	public static void applyPriceModel(OpportunityLineItem oli) {
		PriceCalculator.PriceCalculatorInput pci = new PriceCalculator.PriceCalculatorInput(oli);
		PriceCalculator.IPriceCalculator pc = PriceCalculator.getCalculator(pci);
		oli.PriceCalculator__c = pci.pbe.PriceCalculator__c;
		oli.UPCF__c = pc.getUPCF();

		if (pc.applyListPrice()) oli.ListPrice__c = pc.getListPrice();
		if (pc.applyBundleSize()) oli.BundleSize__c = pc.getBundleSize();
		if (pc.applyCustomListPrice()) oli.CustomListPrice__c = pc.getCustomListPrice();
		if (oli.Quantity == null) oli.Quantity = pc.getDefaultQuantity();

		if( pc.applySalesPriceNet() || pci.opp.LineOfBusiness__c == 'AdSales' ){
			oli.SalesPriceNet__c = pc.getSalesPriceNet();
		}

		if (oli.TotalPrice == null) oli.UnitPrice = oli.SalesPriceNet__c * oli.UPCF__c;
		oli.Billing_Category__c = ((oli.Billing_Category__c == null || oli.Billing_Category__c == '') ? getBillingCategory(pci.prod) : oli.Billing_Category__c);
        oli.BillingCalc__c = ((oli.BillingCalc__c == null || oli.BillingCalc__c == '') ? getBillingCalculation(pci.prod) : oli.BillingCalc__c);
	}
	
	public static void applyPriceModel_optimize(OpportunityLineItem oli, Opportunity opp, PriceBookEntry pbe) {
		PriceCalculator.PriceCalculatorInput pci = new PriceCalculator.PriceCalculatorInput(oli, opp, pbe);
		PriceCalculator.IPriceCalculator pc = PriceCalculator.getCalculator(pci);
		oli.PriceCalculator__c = pci.pbe.PriceCalculator__c;
		oli.UPCF__c = pc.getUPCF();

		if (pc.applyListPrice()) oli.ListPrice__c = pc.getListPrice();
		if (pc.applyBundleSize()) oli.BundleSize__c = pc.getBundleSize();
		if (pc.applyCustomListPrice()) oli.CustomListPrice__c = pc.getCustomListPrice();
		if (oli.Quantity == null) oli.Quantity = pc.getDefaultQuantity();

		if( pc.applySalesPriceNet() || pci.opp.LineOfBusiness__c == 'AdSales' ){
			oli.SalesPriceNet__c = pc.getSalesPriceNet();
		}

		if (oli.TotalPrice == null) oli.UnitPrice = oli.SalesPriceNet__c * oli.UPCF__c;
		oli.Billing_Category__c = ((oli.Billing_Category__c == null || oli.Billing_Category__c == '') ? getBillingCategory(pci.prod) : oli.Billing_Category__c);
        oli.BillingCalc__c = ((oli.BillingCalc__c == null || oli.BillingCalc__c == '') ? getBillingCalculation(pci.prod) : oli.BillingCalc__c);
	}
	
	// apply
	public static void applyPriceModel(Rev__c rev) {
		PriceCalculator.PriceCalculatorInput pci = new PriceCalculator.PriceCalculatorInput(rev);
		PriceCalculator.IPriceCalculator pc = PriceCalculator.getCalculator(pci);

		if (pc.applyListPrice()) rev.ListPrice__c = pc.getListPrice();
		if (pc.applyBundleSize()) rev.BundleSize__c = pc.getBundleSize();
		if (pc.applyCustomListPrice()) rev.CustomListPrice__c = pc.getCustomListPrice();
        if (pc.applySalesPriceNet() ) rev.UnitPrice__c = pc.getSalesPriceNet();

		rev.BillingCategory__c = (rev.BillingCategory__c == null ? getBillingCategory(pci.prod) : rev.BillingCategory__c);
        rev.BillingCalc__c = (rev.BillingCalc__c == null ? getBillingCalculation(pci.prod) : rev.BillingCalc__c);

        rev.AutoExtend__c = pci.prod.AutoExtend__c;
		rev.UPCF__c = pc.getUPCF();
	}

	// Virtual class handling common logic and properties
	public virtual class AbstractPriceCalculator implements PriceCalculator.IPriceCalculator {
		private PriceCalculatorInput pci;
		private Integer adjustedBundleSize;

		public void init(PriceCalculatorInput pci) { this.pci = pci; }

		public Decimal getUPCF() { return GW_Product.getUPCF(pci.billingCategory); }

		// methods below control which properties will be set by the model
		public virtual Boolean applyListPrice() { return false; }
		public virtual Boolean applyBundleSize() { return false; }
		public virtual Boolean applySalesPriceNet() { return pci.salesPriceNet == null; }
		public virtual Boolean applyCustomListPrice() { return true; }

		public virtual Decimal getListPrice() { return - 1; }
		public virtual Decimal getCustomListPrice() { return((getListPrice() == null ? 0 : getListPrice()) * (1 - pci.contractDiscount)).setScale(2); }

		public virtual Integer getBundleSize() { return - 100; }
		public virtual Decimal getSalesPriceNet() { return calculateSalesPriceNet(getCustomListPrice(), pci.pbe.DefaultAdjustmentFixed__c, pci.pbe.DefaultAdjustmentPercentage__c); } // TODO; remove from priceCalculator

		public virtual Decimal getDefaultQuantity() { return 1; }
	}

	// Specific implementations
	public class IterativeTiered_PriceCalculator extends PriceCalculator.AbstractPriceCalculator {
		public override Boolean applyListPrice() { return(pci.bundleSize != null); }
		public override Boolean applyBundleSize() { return true; }

		public override Decimal getListPrice() {
			// hardcoded override for bundlesize 15, use average of 10 and 20
			if (getBundleSize() == 15) {
				return((PriceCalculator.getIterativeTieredListPrice(10, pci) + PriceCalculator.getIterativeTieredListPrice(20, pci)) / 2).setScale(2);
			}
			return PriceCalculator.getIterativeTieredListPrice(getBundleSize(), pci);
		}

		public override Integer getBundleSize() {
			Integer tierSize = (pci.pbe.Tiered_TierSize__c != null) ? Integer.valueOf(pci.pbe.Tiered_TierSize__c) : 10; // defaults to 10 if left empty

			if (this.adjustedBundleSize == null) {
				if (pci.BundleSize > 10 && pci.BundleSize <= 15) {
					this.adjustedBundleSize = 15;
					return this.adjustedBundleSize;
				}
				Integer numTiers = pci.BundleSize / tierSize;
				if (math.mod(pci.BundleSize, tierSize) > 0) numTiers++;
				this.adjustedBundleSize = numTiers * tierSize;
			}
			return this.adjustedBundleSize;
		}
	}

	public class FixedTiered_PriceCalculator extends PriceCalculator.AbstractPriceCalculator {
		// properties set by this model
		public override Boolean applyListPrice() { return(pci.bundleSize != null); }
		public override Boolean applyBundleSize() { return true; }
		public override Decimal getListPrice() {
			Map<Integer, Decimal> tiers = new Map<Integer, Decimal> ();
			if (pci.pbe.FixedTiered_JSON__c != null) tiers = (Map<Integer, Decimal>) JSON.deserialize(pci.pbe.FixedTiered_JSON__c, Map<Integer, Decimal>.class);

			if (tiers.get(getBundleSize()) != null) {
				return tiers.get(getBundleSize());
			}
			return null;
		}
		public override Integer getBundleSize() {
			Map<Integer, Decimal> tiers = new Map<Integer, Decimal> ();
			if (pci.pbe.FixedTiered_JSON__c != null) 
				tiers = (Map<Integer, Decimal>) JSON.deserialize(pci.pbe.FixedTiered_JSON__c, Map<Integer, Decimal>.class);
			
			list<Integer> bundleSizes = new list<Integer> (tiers.keySet());
			bundleSizes.sort();

			for (integer i : bundleSizes) {
                this.adjustedBundleSize = i;
				if (pci.BundleSize <= i) {
					Break;
				}			
            }
			return this.adjustedBundleSize;
		}
	}

	public class UnlimitedFixed_PriceCalculator extends PriceCalculator.AbstractPriceCalculator {
		// properties set by this model
		public override Boolean applyListPrice() { return(pci.bundleSize != null); }
		public override Boolean applyBundleSize() { return false; }
		public override Decimal getListPrice() { return pci.pbe.Fixed_PricePerMonth__c; }
	}

	public class AdSalesFixed_PriceCalculator extends PriceCalculator.AbstractPriceCalculator {
		public override Boolean applyListPrice() { return(pci.oli != null && pci.pbe != null && pci.billingCategory != null); }
		public override Boolean applyBundleSize() { return false; }

		public override Decimal getListPrice() {
			return GW_Product.getListPrice(pci.pbe.Id, pci.billingCategory);
		}

		public override Decimal getDefaultQuantity() { return GW_Product.getDefaultQuantity(pci.billingCategory); }
	}

	public class Default_PriceCalculator extends PriceCalculator.AbstractPriceCalculator {
		// Now used as fallback for AdSales. AdSales products should be set to correct price calculator.
		// properties set by this model
		public override Boolean applyListPrice() { return(pci.oli != null && pci.pbe != null && pci.billingCategory != null); }
		public override Boolean applyBundleSize() { return false; }

        public override Decimal getSalesPriceNet() {
        	return calculateSalesPriceNet( pci ); 
        } 

		public override Decimal getListPrice() {
			return GW_Product.getListPrice(pci.pbe.Id, pci.billingCategory);
		}

		public override Decimal getDefaultQuantity() { return GW_Product.getDefaultQuantity(pci.billingCategory); }
	}

	// this method calculates the iterative tiered price
	private static Decimal getIterativeTieredListPrice(Integer bundleSize, PriceCalculatorInput pci) {
		Decimal basePrice = pci.pbe.Tiered_OffsetPrice__c;
		Integer tierSize = (pci.pbe.Tiered_TierSize__c != null) ? Integer.valueOf(pci.pbe.Tiered_TierSize__c) : 10; // defaults to 10 if left empty
		Decimal tierCorrection = pci.pbe.Tiered_TierCorrection__c != null ? pci.pbe.Tiered_TierCorrection__c / 100 : 0;
		Decimal tieredFinalAdjustment = pci.pbe.Tiered_FinalAdjustment__c == null ? 0 : pci.pbe.Tiered_FinalAdjustment__c;

		for (Integer i = tierSize; i < bundleSize; i += tierSize) {
			basePrice = ((basePrice + pci.pbe.Tiered_AdditionalPrice__c) * (1 + tierCorrection)).setScale(4);
		}
		return((basePrice * (1 + pci.pbe.ProductPriceCorrection__c / 100) * (1 + pci.pbe.PricebookPriceCorrection__c / 100)) + tieredFinalAdjustment).setScale(2);
	}

	public class PriceCalculatorInput {
		public Account acc;
		public Opportunity opp;
		public OpportunityLineItem oli;
		public Rev__c rev;
		public PricebookEntry pbe;
		public Product2 prod;
		public Integer bundleSize;
		public Decimal salesPriceNet;
		public Decimal contractDiscount;
		public String billingCategory;
		public String billingCalc;

		public PriceCalculatorInput(OpportunityLineItem oli) {
			if (oli == null) throw new PriceCalculatorException('Opp.line is null');
			if (oli.PricebookEntryId == null) throw new PriceCalculatorException('oli.PricebookEntryId is null');
			this.opp = UTIL.getCached(oli.OpportunityId) == NULL ? new Opportunity() : ((Opportunity) UTIL.getCached(oli.OpportunityId));
			this.acc = UTIL.getCached(this.opp.AccountId) == NULL ? new Account() : ((Account) UTIL.getCached(this.opp.AccountId));
			this.oli = oli;
			this.pbe = (PricebookEntry) UTIL.getCached(oli.PricebookEntryId);
			this.prod = (Product2) UTIL.getCached(pbe.Product2Id);
			this.BundleSize = oli.BundleSize__c != null ? oli.BundleSize__c.intvalue() : 0;
			this.salesPriceNet = oli.SalesPriceNet__c;
			this.contractDiscount = oli.ContractDiscount__c != null ? (oli.ContractDiscount__c / 100) : 0;
			this.billingCategory = oli.Billing_Category__c;
			this.billingCalc = oli.BillingCalc__c;
		}
		
		public PriceCalculatorInput(OpportunityLineItem oli, Opportunity opp, PriceBookEntry pbe) {
			if (oli == null) throw new PriceCalculatorException('Opp.line is null');
			if (oli.PricebookEntryId == null) throw new PriceCalculatorException('oli.PricebookEntryId is null');
			this.opp = opp;
			this.oli = oli;
			this.pbe = pbe;
			this.BundleSize = oli.BundleSize__c != null ? oli.BundleSize__c.intvalue() : 0;
			this.salesPriceNet = oli.SalesPriceNet__c;
			this.contractDiscount = oli.ContractDiscount__c != null ? (oli.ContractDiscount__c / 100) : 0;
			this.billingCategory = oli.Billing_Category__c;
			this.billingCalc = oli.BillingCalc__c;
		}

		public PriceCalculatorInput(Rev__c rev) {
			this.rev = rev;
            this.pbe = GW_PriceBookEntry.getPbeFromCache(rev.Product__c,rev.PriceBook__c);
            UTIL.cache(this.pbe);
			this.prod = (Product2) UTIL.getCached(pbe.Product2Id);
			this.BundleSize = rev.BundleSize__c != null ? rev.BundleSize__c.intvalue() : 0;
			this.salesPriceNet = rev.UnitPrice__c;
			this.contractDiscount = rev.ContractDiscount__c != null ? (rev.ContractDiscount__c / 100) : 0;
			this.billingCategory = rev.BillingCategory__c;
			this.billingCalc = rev.BillingCalc__c;
		}
	}

	public class PriceCalculatorException extends Exception { }
}