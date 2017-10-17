/**
 * Task #9780: CD-952 - Streaming API real time query to optimise lightning app load speed
 * @author: GIS-DevTeam
 * @createdDate: 06/Oct/2016
 * @description:
 *  - Create Streaming_Api_Support__c records for alert notification to lightning components
 * @references:
 *  - LPC_ConfigTab lightning component
 * @changeLog:
 *
 */
public class LPC_StreamingApiHelper {
    
    public static Boolean isDoneAlert = false;
    
    /**
     * Create Streaming_Api_Support__c records for alert notification to lightning component 
     * @param action, transaction action (insert, update, delete)
     * @param lstRecords, list OpportunityLineItem records
     */
    public static void createOppLineNotifyRecords(String action, List<OpportunityLineItem>lstRecords){
        
        // skip create multiple notification record for one transaction 
        if(isDoneAlert) return;
                
        List<Streaming_Api_Support__c>lst2Upsert = new List<Streaming_Api_Support__c>();
        for(OpportunityLineItem oppLine : lstRecords){
            lst2Upsert.add(new Streaming_Api_Support__c(Action__c=action, RecordId__c=oppLine.Id+'', SobjectType__c='OpportunityLineItem', ParentId__c=oppLine.OpportunityId+''));
        }
        
        if(!lst2Upsert.isEmpty()) upsert lst2Upsert RecordId__c;
        isDoneAlert = true;
    }
    
}