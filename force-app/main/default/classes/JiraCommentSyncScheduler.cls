global class JiraCommentSyncScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new JiraCommentSync(), 25);
    }
}