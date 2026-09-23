import { LightningElement } from "lwc";

export default class test extends LightningElement{
    isKanbanView = false;

    //Kanban View 
    // --- VIEW TOGGLE LOGIC ---
    get listViewVariant() {
        return this.isKanbanView ? 'border' : 'brand';
    }

    get kanbanViewVariant() {
        return this.isKanbanView ? 'brand' : 'border';
    }

    switchToListView() {
        this.isKanbanView = false;
    }

    switchToKanbanView() {
        this.isKanbanView = true;
    }

    // --- KANBAN COLUMN BUILDER ---
    get kanbanColumns() {
        if (!this.stageOptions || !this.opportunities) return [];
        
        return this.stageOptions.map(stage => {
            let columnRecords = this.opportunities.filter(opp => opp.StageName === stage.value);
            return {
                label: stage.label,
                value: stage.value,
                count: columnRecords.length,
                records: columnRecords.map(rec => ({
                    ...rec,
                    ProbabilityDisplay: (rec.Probability * 100).toFixed(0) + '%'
                }))
            };
        });
    }

    // --- KANBAN CARD CLICK (Opens Detailed View) ---
    handleKanbanCardClick(event) {
        // This mimics the "view_details" row action from the datatable
        this.selectedRecordId = event.currentTarget.dataset.id;
    }

    // --- DRAG AND DROP LOGIC ---
    handleDragStart(event) {
        event.dataTransfer.setData('opportunity_id', event.currentTarget.dataset.id);
        event.currentTarget.classList.add('dragging');
    }

    handleDragOver(event) {
        event.preventDefault(); 
        event.currentTarget.classList.add('drag-over'); 
    }

    handleDragLeave(event) {
        event.currentTarget.classList.remove('drag-over');
    }

    handleDrop(event) {
        event.preventDefault();
        event.currentTarget.classList.remove('drag-over');

        const recordId = event.dataTransfer.getData('opportunity_id');
        const newStage = event.currentTarget.dataset.stage; 

        const draggedRecord = this.opportunities.find(opp => opp.Id === recordId);
        
        if (draggedRecord && draggedRecord.StageName !== newStage) {
            // Require reason for Closed Lost directly on drop via your existing modal
            if (newStage === 'Closed Lost') {
                this.selectedOpportunityIds = [recordId];
                this.selectedStage = newStage;
                this.showReasonField = true;
                this.showStageModal = true;
                return;
            }

            this.updateStageViaApi(recordId, newStage);
        }
    }

    updateStageViaApi(recordId, newStageName) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = recordId;
        fields[STAGE_FIELD.fieldApiName] = newStageName;
        
        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Opportunity Stage Updated',
                        variant: 'success'
                    })
                );
                // Refresh data to grab the new calculated probability
                this.fetchOpportunitiesByStages();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating stage',
                        message: error.body ? error.body.message : error.message,
                        variant: 'error'
                    })
                );
            });
    }

}