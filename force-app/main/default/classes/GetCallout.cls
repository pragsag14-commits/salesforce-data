public class GetCallout {
    public static void fetchUserData() {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setEndpoint('https://bluethinkitconsultingprivat-dev-ed.develop.my.salesforce.com');
            request.setMethod('GET');

            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            request.setTimeout(20000);
            request.setHeader('Authorization', 'Bearer 00Dg500000AyZQ9!AQEAQGaC5MDN9fgqQF7AuZWMUDP4ctAPgmoY03WFUDHphQHwZ93ElDu63ybSXABtdFxnYxh1Sjvy5tcFKGFrtOIr5.eHKvQr');
            
            
             HttpResponse response = http.send(request);

            // ✅ Print EVERYTHING first before parsing
            System.debug('Status Code : ' + response.getStatusCode());
            System.debug('Status      : ' + response.getStatus());
            System.debug('Raw Body    : ' + response.getBody());
            
              // ✅ Only parse if it is actually JSON

            if (response.getStatusCode() == 200) {
                String body = response.getBody();
           
                // ✅ Safety check before parsing
                if (body != null && body.startsWith('{') || 
                    body != null && body.startsWith('[')) {

                    Map<String, Object> result =
                        (Map<String, Object>) JSON.deserializeUntyped(body);

                    System.debug('Name  : ' + result.get('name'));
                    //System.debug('Email : ' + result.get('email'));

            }
            else {
                 System.debug('Response is not JSON: ' + body);
            }}
             else {
                System.debug('Error Code: '    + response.getStatusCode());
                System.debug('Error Message: ' + response.getStatus());
            }

        } catch (CalloutException e) {
            // Handles timeout, DNS failure, unreachable server
            System.debug('Callout Failed: ' + e.getMessage());
        }
        catch (JSONException e) {
            System.debug('JSON Parse Error: ' + e.getMessage());
            }
    }
}