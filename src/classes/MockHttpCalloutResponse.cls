@isTest global class MockHttpCalloutResponse implements HttpCalloutMock { 
    
    public HttpRequest request {get; set;} // the HTTP Request 
    public Boolean testException {get; set;} // Test exception flag 
    public String exceptionMessage {get; set;} // Test exception message 
    public String resultType {get; set;} // Test result type 
    public Integer resultStatusCode {get; set;} // Test result status code 
    public String resultBody {get; set;} // Test result body 
    
    // Test exception class 
    public class MockException extends Exception {} 
    
    // Constructor to specify if throw exception 
    public MockHttpCalloutResponse(Boolean testException, String message) { 
        this.testException = testException; 
        this.exceptionMessage = message; 
    }    
    
    // Constructor to specify a result boday 
    public MockHttpCalloutResponse(String resultType, Integer statusCode, String body) {
        this.testException = false; 
        this.resultType = resultType; 
        this.resultStatusCode = statusCode; 
        this.resultBody = body; 
    }
    
    // Implement this interface method 
    global HttpResponse respond(HttpRequest req) { 
        System.debug('req.getBody======='+req.getBody()); 
        this.request = req; 
        if (testException) { 
            throw new MockException(exceptionMessage);
        }
        HttpResponse response = new HttpResponse(); 
        response.setHeader('Content-Type', resultType); 
        response.setStatusCode(resultStatusCode);
        if (resultBody != null) { 
            response.setBody(resultBody); 
        }
        return response;
    }
}