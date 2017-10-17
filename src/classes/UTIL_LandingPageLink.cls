global class UTIL_LandingPageLink{
    global String inputIn { get; set; }
    global String campaignIdIn { get; set; }
    global String baseUrlIn { get; set; }
    global String styleIn { get; set; }
    global String extraActionIn { get; set; }
    
    global String getResult() {
        String result;
        String input = inputIn;
        String targetId;
        // If input is a Lead or a Contact (very likely) we want to fetch its campaignmember id so we can use this in the URL......
         if (inputIn != null && (input.substring(0,3) == '00Q' || input.substring(0,3) == '003')) {
            List<CampaignMember> cms = [SELECT Id FROM CampaignMember WHERE Campaign.Id = :campaignIdIn AND (Lead.Id = :input OR Contact.Id = :input)];
            if (cms.size() == 1) {
                targetId = cms.get(0).Id;
            } else {
                targetId = input; // this will still get somewhere, but wont know what campaign this landed from...
            }
        }  else {
            targetId = input;
        }
        
        try {
            Blob aesKey = EncodingUtil.convertFromHex('8a6a961d6a0867d55affc5a896c6e30f6b7fbe6b7421fc4498776b2cd89e9342'); // AES256 key..
            Blob dataBlob = Blob.valueOf(targetId);
            Blob encryptedData = Crypto.encryptWithManagedIV('AES256', aesKey, dataBlob );
            String extraAction = '';
            if (extraActionIn != null) {
                extraAction = extraActionIn;
            }
            if (baseUrlIn != null) {
                return '<a href="'+baseUrlIn+'?id='+EncodingUtil.convertToHex(encryptedData)+ extraAction + '" style="'+styleIn+'">';
            } else {
                return EncodingUtil.convertToHex(encryptedData);
            }
        } catch (Exception e) {
            System.debug('Exception was thrown: ' + e);
            return e.getMessage() + ' input ' + input;
        }
    }
    
    global UTIL_LandingPageLink() {
        
    }
}