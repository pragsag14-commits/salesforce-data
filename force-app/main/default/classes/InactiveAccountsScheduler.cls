public class InactiveAccountsScheduler implements Schedulable {
    public void execute(SchedulableContext sc){
        InactiveAccounts batchJob = new InactiveAccounts();
        Database.executeBatch(batchJob, 200);
    }
}