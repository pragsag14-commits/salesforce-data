//implement an interface, sObject as a datatype it can be any object in the system
//we have to implement start, execute , finish methods have to be overrided in these batchable class
//we have to query 50k queries in 
public class BatchForOpportunities implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext context){
        //Database.BatchableContext is always required in this, 
        String query = 'SELECT Id FROM Opportunity';//when we have to pass this query in the string then we need to give single quotes into it
        //Database.query(query); //because of governor limits this might fall short t
        return Database.getQueryLocator(query);    //Database.QueryLocator - record retriever fetch data from database and passes into the chunks 

    }

    public void execute(Database.BatchableContext context, List<Opportunity> opp){

    }

    //anything else we want to do here, we do in finish method
    public void finish(Database.BatchableContext context){
        //as soon as all records of all chunk jobs will be completed, finally finish method will run
        //post-processing, final notifications, clean up, storing some value, sending emails, after all the batches are processed finish method is called
    }

}