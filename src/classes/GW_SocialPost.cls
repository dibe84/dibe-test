public with sharing class GW_SocialPost {



  /**
     * ***********************************************************************************
     * @desc: add Member ID to the Case at the creation  not at the edition of SocialPost.
     * ***********************************************************************************
     */
     private static final String FACEBOOK = 'Facebook';
     
     public static void initialCaseMemberId(List<SocialPost> lstItems) {
        
        Map<ID,String> mapMemberIds = new Map<ID,String>();
        for(SocialPost item: lstItems) {
            if( String.isNotEmpty(item.Provider) &&
                item.Provider == FACEBOOK && 
                String.isNotEmpty(item.PostTags) &&
                item.ParentId != null && 
                String.valueOf(item.ParentId.getsobjecttype()) == 'Case') {
                mapMemberIds.put(item.ParentId, item.PostTags);
            }
        }
        
        if(!mapMemberIds.isEmpty()) {
            List<Case> lstCasesUpdate = new List<Case>();
            List<Case> lstCases = GW_sObject.queryRecords('Case', new List<String> {'id','MemberId__c '}, mapMemberIds.keySet() );
            for(Case ca: lstCases) {
                String memberId =  mapMemberIds.containsKey(ca.id) ? getMemberId(mapMemberIds.get(ca.id)) : '-';
                if( ca.MemberId__c != memberId ) {
                    ca.MemberId__c = memberId;
                    lstCasesUpdate.add(ca);
                }
            }

            if(!lstCasesUpdate.isEmpty()) {
                update lstCasesUpdate;
            }
            
        }

     }
     
     /*
     * @param : curPostTage = ECGDK_XX_XXXXX_XXXXX
     */
     private static String getMemberId(String curPostTag) {
        
        if( String.isNotEmpty(curPostTag) &&
            curPostTag.contains('_')) {
            return curPostTag.split('_')[0];
        }
        return '-';
     }

}