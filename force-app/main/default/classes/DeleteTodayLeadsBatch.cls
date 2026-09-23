// Task 2: Delete Old Leads
// Requirement:
// Find Leads that:
// Have not been modified for more than 2 years
// Are not converted
// Delete them using Batch Apex.

public class DeleteTodayLeadsBatch implements Database.Batchable<sObject> {

    // 1. start(): Queries unconverted Leads created today
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM Lead WHERE IsConverted = false AND CreatedDate = TODAY';
        return Database.getQueryLocator(query);
    }

    // 2. execute(): Deletes records using partial success (allOrNone = false)
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        if (!scope.isEmpty()) {
            // Second parameter 'false' ensures valid records are deleted even if one fails
            List<Database.DeleteResult> results = Database.delete(scope, false);

            // Loop through results to inspect any failures
            for (Database.DeleteResult dr : results) {
                if (!dr.isSuccess()) {
                    for (Database.Error err : dr.getErrors()) {
                        System.debug('Failed to delete Lead ID: ' + dr.getId() + ' - Error: ' + err.getMessage());
                    }
                }
            }
        }
    }

    // 3. finish(): Logs job execution status
    public void finish(Database.BatchableContext bc) {
        System.debug('DeleteTodayLeadsBatch process has finished.');
    }
}