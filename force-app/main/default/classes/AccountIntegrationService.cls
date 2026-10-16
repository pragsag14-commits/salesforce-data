@RestResource(urlMapping='/v1/AccountService/*')
global with sharing class AccountIntegrationService {
    @HttpPost
    global static ResponseWrapper createAccount(){
        ResponseWrapper resWrapper = new ResponseWrapper();
        try{
            // 1. Grab the request context and convert the blob body to string
            RestRequest req = RestContext.request;
            String requestBodyString = req.requestBody.toString();
            // 2. Deserialize the JSON request into the Request Wrapper
            RequestWrapper reqWrapper = (RequestWrapper) JSON.deserialize(requestBodyString, RequestWrapper.class);
            // 3. Validate request data
            if (reqWrapper == null || String.isBlank(reqWrapper.accountName)) {
                resWrapper.status = 'Error';
                resWrapper.message = 'Account name is required.';
                RestContext.response.statusCode = 400; // Bad Request
                return resWrapper;
            }
            // 4. Process the data (Create Account record)
            Account acc = new Account();
            acc.Name = reqWrapper.accountName;
            acc.Phone = reqWrapper.phone;
            acc.Website = reqWrapper.website;
            insert acc;
            // 5. Populate success response details
            resWrapper.status = 'Success';
            resWrapper.message = 'Account created successfully.';
            resWrapper.accountId = acc.Id;
            RestContext.response.statusCode = 201; // Created
        }
        catch (Exception ex) {
            // 6. Handle exceptions gracefully
            resWrapper.status = 'Error';
            resWrapper.message = 'An error occurred: ' + ex.getMessage();
            RestContext.response.statusCode = 500; // Internal Server Error
        }
        // Apex automatically serializes user-defined object types to JSON
        return resWrapper;
    }

    // --- WRAPPER CLASSES ---
    // Inner class representing the structure of the incoming request JSON
    global class RequestWrapper {
        global String accountName;
        global String phone;
        global String website;
    }

    // Inner class representing the structure of the outgoing response JSON
    global class ResponseWrapper {
        global String status;
        global String message;
        global String accountId;
    }
}
