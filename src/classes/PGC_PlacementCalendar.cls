/**
 * Created by ronvelzeboer on 05/10/16.
 */

public with sharing class PGC_PlacementCalendar {
    public Id placementId { get; set; }
    public Opportunity opp { get; set; }
    public List<CalendarItem> calendarItems { get; set; }
    public Product2 prod { get; set; }

    public PGC_PlacementCalendar() {
        this.prod = new Product2(Name='Dummy');
        // test url RV4: /apex/PlacementCalendar?Id=a0zN0000001b0FK&opportunityId=006N00000098SVC
        if (ApexPages.currentPage().getParameters().containsKey('Id')) {
            placementId = (Id) ApexPages.currentPage().getParameters().get('Id');
            this.prod.Placement__c = placementId;
        }
        if (ApexPages.currentPage().getParameters().containsKey('opportunityId')) {
            Id opportunityId = (Id) ApexPages.currentPage().getParameters().get('opportunityId');
            opp = [ SELECT Id, Name, MemberId__c FROM Opportunity WHERE Id = :opportunityId ];
        }
        if (null == opp){
            UTIL.throwError('Incorrect page call: OpportunityId is required!');
        }
        buildCalendar();
    }

    public void buildCalendar() {
        if (null == opp || null == prod.Placement__c) {
            this.calendarItems = null;
            return;
        }
        Date startDate = Date.today();
        Date endDate = Date.today().addMonths(2);

        List<Rev__c> exclusiveItems = [
            SELECT Product__r.Site__r.Name,
                Product__r.Placement__r.Id,
                Product__r.Placement__r.Name,
                Product__r.Name,
                Product__r.Id,
                Product__r.Advertising_Medium__r.DART_AdType__c,
                Opportunity__r.Name,
                Opportunity__r.Owner.Id,
                Opportunity__r.Owner.Name,
                Opportunity__r.NumStatus__c,
                From_Date__c,
                Until_Date__c
            FROM Rev__c
            WHERE Product__r.Exclusive_Placement__c = true
                AND Product__r.Placement__c = :prod.Placement__c
                AND Opportunity__r.MemberId__c = :opp.MemberId__c
                AND Opportunity__r.NumStatus__c >= 0
                AND Until_Date__c >= :startDate AND From_Date__c <= :endDate
        ];
        UTIL.log('~!@ exclusiveItems: ' + exclusiveItems);
        this.calendarItems = doBuildCalendar(exclusiveItems, startDate, endDate);
    }

    public List<CalendarItem> doBuildCalendar(List<Rev__c> revs, Date startDate, Date endDate) {
        Map<Date, List<Rev__c>> waitPool = buildWaitPool(revs, startDate);
        Set<Rev__c> activePool = new Set<Rev__c>();

        Date evaluatedDate = startDate;
        List<CalendarItem> calendar = new List<CalendarItem>();

        while (evaluatedDate <= endDate) {
            if (waitPool.containsKey(evaluatedDate)) {
                activePool.addAll(waitPool.get(evaluatedDate));
                waitPool.remove(evaluatedDate);
            }
            calendar.add(new CalendarItem(evaluatedDate, activePool.clone()));

            removeRevsFromPoolEndedOnDate(evaluatedDate, activePool);

            evaluatedDate = evaluatedDate.addDays(1);
        }
        return calendar;
    }

    public void removeRevsFromPoolEndedOnDate(Date evaluatedDate, Set<Rev__c> pool) {
        for (Rev__c poolRev : pool) {
            if (poolRev.Until_Date__c == evaluatedDate) {
                pool.remove(poolRev);
            }
        }
    }

    public Map<Date, List<Rev__c>> buildWaitPool(List<Rev__c> revs, Date startDate) {
        Map<Date, List<Rev__c>> pool = new Map<Date, List<Rev__c>>();
        for (Rev__c rev : revs) {
            if (null == rev.From_Date__c) {
                continue;
            }
            Date poolKey = rev.From_Date__c;
            if (rev.From_Date__c < startDate) {
                poolKey = startDate;
            }
            if (!pool.containsKey(poolKey)) {
                pool.put(poolKey, new List<Rev__c>());
            }
            pool.get(poolKey).add(rev);
        }
        return pool;
    }

    public class CalendarItem {
        public Date itemDate { get; set; }
        public Set<Rev__c> bookedRevs { get; set; }
        public List<Rev__c> reservedRevs { get; set; }
        public List<Rev__c> soldRevs { get; set; }
        public Integer reservedCount { get; set; }
        public Integer soldCount { get; set; }
        public String itemStyleClass { get; set; }

        public CalendarItem(Date d, Set<Rev__c> revs) {
            itemDate = d;
            bookedRevs = revs;
            reservedRevs = new List<Rev__c>();
            soldRevs = new List<Rev__c>();

            if (null != revs) {
                for (Rev__c rev : bookedRevs) {
                    if (rev.Opportunity__r.NumStatus__c < 2) {
                        reservedRevs.add(rev);
                    } else {
                        soldRevs.add(rev);
                    }
                }
            }
            reservedCount = reservedRevs.size();
            soldCount = soldRevs.size();
            if (soldCount > 0) {
                itemStyleClass = 'redItem';
            } else if (reservedCount > 0) {
                itemStyleClass = 'orangeItem';
            } else {
                itemStyleClass = 'greenItem';
            }
        }
    }
}