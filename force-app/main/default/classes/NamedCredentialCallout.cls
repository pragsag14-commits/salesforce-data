public class NamedCredentialCallout {

    public static void getAccounts() {

        HttpRequest req = new HttpRequest();

        req.setEndpoint('https://bluethinkitconsultingprivat-dev-ed.develop.lightning.force.com');
        req.setMethod('GET');

        Http http = new Http();

        HttpResponse res = http.send(req);

        System.debug(res.getBody());
    }
}