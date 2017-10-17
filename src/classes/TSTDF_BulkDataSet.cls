/**
 * Created by ronvelzeboer on 21/07/16.
 */

public with sharing class TSTDF_BulkDataSet {
    private TSTDF_BulkDataSet.Config config { get; set; }

    public TSTDF_BulkDataSet(TSTDF_BulkDataSet.Config config) {
        this.config = config;
    }

    public SObject getSObjectByRef(String ref) {

        return new Account(Name='test');
    }

    public class Config {
        public List<TSTDF_BulkDataSet.ConfigItem> items { get; private set; }

        public Config() {
            this.items = new List<TSTDF_BulkDataSet.ConfigItem>();
        }

        public void add(ConfigItem item) {
            this.items.add(item);
        }
    }

    public class ConfigItem {
        public String member { get; set; }
        public String memberUnit { get; set; }

        public Integer accountCount { get; set; }
        public Integer pricebookCount { get; set; }
        public Integer productSetCount { get; set; }
        public Integer productsInProductSetCount { get; set; }
    }

}