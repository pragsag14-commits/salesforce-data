global class JiraSyncScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Enqueue the batch class with a batch size of 50
        Database.executeBatch(new JiraSyncBatch(), 50); 
    }
}