trigger OpportunityTrigger on Opportunity(before insert, after update){
    if(Trigger.isInsert && Trigger.isBefore){
    	OpportunityTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    if(Trigger.isUpdate && Trigger.isAfter){
        OpportunityTriggerHandler.handleUpdateStage(Trigger.new, Trigger.oldMap);
    }
}