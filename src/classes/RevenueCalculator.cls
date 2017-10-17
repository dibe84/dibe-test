public with sharing class RevenueCalculator {

    // interface
    public interface IRevenueCalculator{
        void init(RS__c rs, Rev__c rev, List<Metric__c> metrics);
        void init(RS__c rs, Rev__c rev, List<Metric__c> metrics, List<RS__c> allRSForRev);
        Decimal calcRevenue();
        Decimal calcRevenueOverdelivered();
        Decimal calcQuantityBooked();
        Decimal calcQuantityDelivered();
		Decimal calcQuantityOverdelivered();
        Decimal calcQuantityBilled();
        Decimal calcUPCF();

        String getProductCode();
    }

    // factory
    public static IRevenueCalculator getCalculator(RS__c rs) {
        Rev__c rev = (Rev__c) UTIL.getCached(rs.Rev__c);
        Map<Id,Metric__c> metrics = GW_RS.rsMetrics.get(rs.Id);
        if (rev == null) throw new RevenueCalculatorException('Revenue object not in cache');
        if (metrics == null) throw new RevenueCalculatorException('Metrics not in cache'); // TODO: no metrics required for certain types
        if (rev.BillingCategory__c == null) throw new RevenueCalculatorException('Billing Category is not selected.');
        if (rev.BillingCalc__c == null) throw new RevenueCalculatorException('Billing Calculation is not selected.');

        String calcType = 'RevenueCalculator.'+ rev.BillingCategory__c.deleteWhitespace() + '_'+ rev.BillingCalc__c.deleteWhitespace() +'_RevenueCalculator';
        Type t = Type.forName(calcType);
        if (t == null) throw new RevenueCalculatorException('Revenue Calculator can not be instantiated: '+calcType);

        IRevenueCalculator irc = (IRevenueCalculator) t.newInstance();

		if(t.getName().contains('MultiMonth') || t.getName().contains('Delivery')) {
            irc.init(rs,rev,metrics.values(),getRelatedRS(rev));
		} else {
			irc.init(rs, rev, metrics.values());
		}

        return irc;
    }

    private static List<RS__c> getRelatedRS(Rev__c rev) {
        if(rev == null) return new List<RS__c>();

        List<RS__c> rsList;
        Map<Id,sObject> relObjMap = UTIL.getRelatedFromCache('Rev__c',rev.Id,'RS__c');
        if(relObjMap.size() != rev.NumRSs__c) {
            rsList = GW_RS.getExistingRS(new List<Rev__c>{rev});
            UTIL.cache(rsList);
        } else {
            rsList = (List<RS__c>) relObjMap.values();
        }

        return rsList;
    }

    // Virtual class handling common logic and properties
    public virtual class AbstractRevenueCalculator implements RevenueCalculator.IRevenueCalculator {
        RS__c rs;
        Rev__c rev;
        List<Metric__c> metrics;
        List<RS__c> allRSList;

        Decimal qDelivered;
        Decimal qBooked;
        Decimal unitPrice;

        public void init(RS__c rs, Rev__c rev, List<Metric__c> metrics) {
            this.rs =           rs;
            this.rev =          rev;
            this.metrics =      metrics;
            this.qDelivered =   calcQuantityDelivered();
            this.qBooked =      (rs==null || rs.QuantityBooked__c==null)? 0 : (Decimal) rs.QuantityBooked__c;
            this.unitPrice =    (rev==null || rev.UnitPrice__c==null)? 0 : (Decimal) rev.UnitPrice__c;
            this.allRSList =    new List<RS__c>();
        }

        public void init(RS__c rs, Rev__c rev, List<Metric__c> metrics, List<RS__c> allRSForRev) {
            this.rs =           rs;
            this.rev =          rev;
            this.metrics =      metrics;
            this.unitPrice =    (rev==null || rev.UnitPrice__c==null)? 0 : (Decimal) rev.UnitPrice__c;
            this.allRSList =    (allRSForRev == null ? new List<RS__c>() : allRSForRev);
        }

        public virtual Decimal calcQuantityBooked() { return -1; }
        public virtual Decimal calcQuantityDelivered() { return -1; }
        public virtual Decimal calcUPCF() { return GW_Product.getUPCF('DEFAULT'); }
        public virtual String getProductCode() { return 'UK_AUS_BAN'; } // TODO make dynamic

        public virtual Decimal calcRevenueOverdelivered() {
            return (this.unitPrice * calcUPCF() * calcQuantityOverdelivered()).setScale(2);
        }

        public virtual Decimal calcRevenue() {
            Decimal revCalcd = (this.unitPrice * calcUPCF() * calcQuantityBilled()).setScale(2);
         
            return revCalcd;
        }

        public virtual Decimal calcQuantityOverdelivered() {
            Decimal qDeliveredTotal = calcQuantityDeliveredTotal();
            Decimal qDelivered = calcQuantityDelivered();
            Decimal qOverdelivered = 0.0;
            Decimal revQBooked = (rev.QuantityBooked__c == NULL ? 0.0 : rev.QuantityBooked__c);
            // Already over delivered
            if(qDeliveredTotal >= revQBooked) {
                return qDelivered;
            }

            // How much left in the jar until we hit the budget?
            Decimal qAvailable = revQBooked - qDeliveredTotal;

            // Jar has more space left than we delivered, so no over delivery
            if(qAvailable >= qDelivered) return qOverdelivered;
            // Jar has less space than we delivered, so over delivery
            if(qAvailable < qDelivered) return qDelivered - qAvailable;

            return qOverdelivered;
        }

        public virtual Decimal calcQuantityBilled() {
            Decimal qOverdelivered = calcQuantityOverdelivered();
            Decimal qDelivered = calcQuantityDelivered();

            return qDelivered - qOverdelivered;
        }

        // Helper - gets deliveries count for all RS before current one
        public Decimal calcQuantityDeliveredTotal() {
            Decimal qDeliveredTotal = 0;
            for(RS__c revschedule : allRSList) {
                if(revschedule.From_Date__c < rs.From_Date__c) {
                    qDeliveredTotal += (revschedule.QuantityDelivered__c == NULL ? 0.0 : revschedule.QuantityDelivered__c);
                }
            }
            return qDeliveredTotal;
        }
    }

    // Specific implementations
    public class CPD_Delivery_RevenueCalculator extends RevenueCalculator.AbstractRevenueCalculator {

        public override Decimal calcQuantityDelivered() {
            this.qDelivered = 0;
            for (Metric__c m : metrics) {
                if (m.AD_Impressions__c>0) this.qDelivered++;
            }
            return this.qDelivered;
        }
    }

    public class CPD_DailyFixed_RevenueCalculator extends RevenueCalculator.AbstractRevenueCalculator {

        public override Decimal calcQuantityDelivered() {
            if ( this.qDelivered == null ) {
                this.qDelivered = rs.MetricsDelivered__c!=null?rs.MetricsDelivered__c:0;
            }
            return this.qDelivered;
        }
        public override Decimal calcQuantityBilled() {
            return this.qBooked;
        }
    }
    public class CPM_Delivery_RevenueCalculator extends RevenueCalculator.AbstractRevenueCalculator {

        public override Decimal calcQuantityDelivered() { // TODO implement using aggregate query
			// Only recalc if not calculated in constructor
            if (this.qDelivered == null) {
                this.qDelivered = 0;
                for (Metric__c m : metrics) {
                    if (m.AD_Impressions__c != null ) qDelivered += m.AD_Impressions__c;// /1000;
                }
            }
            return this.qDelivered;
        }

        public override Decimal calcUPCF() { return GW_Product.getUPCF('CPM'); }
    }
    public class CPM_DailyFixed_RevenueCalculator extends RevenueCalculator.AbstractRevenueCalculator {

        public override Decimal calcQuantityBilled() {
            return this.qBooked;
        }
        public override Decimal calcQuantityDelivered() { // TODO implement using aggregate query
            if ( this.qDelivered == null ) {
                this.qDelivered = 0;
                for (Metric__c m : metrics) {
                    if (m.AD_Impressions__c != null ) qDelivered += m.AD_Impressions__c;// /1000;
                }
            }
            return this.qDelivered;
        }

        public override Decimal calcUPCF() { return GW_Product.getUPCF('CPM'); }
    }
    public class CPC_Delivery_RevenueCalculator extends RevenueCalculator.AbstractRevenueCalculator {

        public override Decimal calcQuantityDelivered() {
            if ( this.qDelivered == null ) {
                this.qDelivered = 0;
                for (Metric__c m : metrics) {
                    if (m.AD_Clicks__c != null ) qDelivered += m.AD_Clicks__c;
                }
            }
            return this.qDelivered;
        }
    }
    public class ServiceFee_OneTime_RevenueCalculator extends RevenueCalculator.AbstractRevenueCalculator {

        public override Decimal calcRevenue() {
            return (this.unitPrice * calcUPCF() * calcQuantityBilled()).setScale(2);
        }

        public override Decimal calcQuantityBilled() {
            return 1;
        }
        public override Decimal calcQuantityDelivered() {
            return 1;
        }
    }
    public class ServiceFee_MonthlyFixed_RevenueCalculator extends RevenueCalculator.AbstractRevenueCalculator {

        public override Decimal calcRevenue() {
            return (this.unitPrice * calcUPCF() * calcQuantityBilled()).setScale(2);
        }

        public override Decimal calcQuantityBilled() {
            return 1;
        }
        public override Decimal calcQuantityDelivered() {
            return 1;
        }
    }
    public class Subscription_MonthlyProRata_RevenueCalculator extends RevenueCalculator.AbstractRevenueCalculator {

        public override Decimal calcRevenue() {
            return (this.unitPrice * calcUPCF() * calcQuantityBilled()).setScale(2);
        }

        public override Decimal calcQuantityBilled() {
            Date fromDate = this.rs.From_Date__c;
            Date untilDate = this.rs.Until_Date__c;

            Integer daysBetween = 0;
            Decimal fractionOfMonth = 1;

            if (fromDate != null && untilDate != null){
                daysBetween = fromDate.daysBetween(untilDate);
                fractionOfMonth = ((Decimal) (daysBetween+1)/Date.daysInMonth(fromDate.year(), fromDate.month())).setscale(8);
            }
            if (this.rev.TerminationDate__c == this.rev.From_Date__c) {
                daysBetween = 0;
                fractionOfMonth = 0;
            }


            return fractionOfMonth;
		}

        public override Decimal calcQuantityDelivered(){
            return 1;
        }

    }

    public class Subscription_MonthlyRevenueDelivery_RevenueCalculator extends RevenueCalculator.AbstractRevenueCalculator {

        public override Decimal calcRevenue() {
            Decimal revenue = 0;

            for (Metric__c m : metrics) {
                if (m.AD_Amount__c != null && m.AD_Amount__c > 0) revenue+=m.AD_Amount__c;
            }

            return revenue.setScale(2);
		}

        public override Decimal calcQuantityDelivered() {
            if ( this.qDelivered == null ) {
                this.qDelivered = 0;
                for (Metric__c m : metrics) {
                    if (m.AD_Quantity__c != null && m.AD_Quantity__c > 0) this.qDelivered +=  m.AD_Quantity__c;
                }
            }
            return this.qDelivered;
		}

		public override Decimal calcQuantityBilled() {
			return this.qDelivered;
		}
    }

	public class Subscription_MultiMonth_RevenueCalculator extends RevenueCalculator.AbstractRevenueCalculator {

        public override Decimal calcQuantityBooked() {
			Integer numMonths = Integer.valueOf(this.rev.ContractPeriodInMonths__c == null ? 0 : (this.rev.ContractPeriodInMonths__c));
			Date contractEndDate = this.rev.From_Date__c.addMonths(numMonths).addDays(-1);
			Decimal rsQuantity = 0.0;

			// Check if last RS
			if(rs.Until_Date__c == contractEndDate) {
				// Calculate for all RS
				Decimal totalRevCalc = 0.0;
				for(RS__c ars : allRSList) {
					if(ars.Id == rs.Id) continue;
					Decimal qBookedCalc = calcQBooked(ars,rev);
					totalRevCalc += (rev.UnitPrice__c * qBookedCalc).setScale(2);
				}
				Decimal revUnitPrice = rev.UnitPrice__c == 0 ? 1 : rev.UnitPrice__c;
				rsQuantity = (1.0 - (totalRevCalc / revUnitPrice));
			} else {
				rsQuantity = calcQBooked(rs,rev);
			}
            return rsQuantity;
		}

		private Decimal calcQBooked(RS__c rs, Rev__c rev) {
			Date rsFromDate = rs.From_Date__c;
            Date rsUntilDate = rs.Until_Date__c;
			Date contractStartDate = rev.From_Date__c;
			Integer numMonths = Integer.valueOf(rev.ContractPeriodInMonths__c == null ? 0 : (rev.ContractPeriodInMonths__c));
			Date contractEndDate = rev.From_Date__c.addMonths(numMonths).addDays(-1);

			Decimal rsNumDays = 0;
            Decimal totalNumDays = 0;
			Decimal rsQuantity = 0;

            if(rsFromDate != null && rsUntilDate != null){
                rsNumDays = rsFromDate.daysBetween(rsUntilDate) + 1;
            }
			if(contractStartDate != null && contractEndDate != null) {
				totalNumDays = contractStartDate.daysBetween(contractEndDate) + 1;
			}
			if(rsFromDate == rev.TerminationDate__c || (rsNumDays == 0) || (totalNumDays == 0)) {
                return 0.0;
            }

			if(rsNumDays != 0 && totalNumDays != 0) {
				rsQuantity = rsNumDays/totalNumDays;
			}
			return rsQuantity.setScale(2,System.RoundingMode.FLOOR);
		}

        public override Decimal calcQuantityDelivered(){
            return calcQuantityBooked();
        }

		public override Decimal calcQuantityBilled() {
			return calcQuantityBooked();
		}
    }


	public class RevenueCalculatorException extends Exception {}
}