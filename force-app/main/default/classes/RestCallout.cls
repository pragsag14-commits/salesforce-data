public class RestCallout {
    @future(callout=true)
    public static void getQuote(String quoteLine) {
        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:SF_Named/services/data/v59.0/query?q=');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer 00Dg500000AyZQ9!AQEAQHHW8DwPOUpnXvMX586txpb0MVYpbCnnRncxOo6rO4IXUgOzpg5MQ57m6vUXf93I8dZhWxoRzjME1kpAqky4VjxbF9O6');
            req.setTimeout(10000);
            HttpResponse res = http.send(req);
            if(res.getStatusCode() == 200) {
                System.debug('Success Response:');
                System.debug(res.getBody());
            }
            else {
                System.debug(
                    'Error: ' + res.getStatusCode() + ' ' + res.getStatus());
            }
        }
        catch(Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }
}