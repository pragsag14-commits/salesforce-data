import { LightningElement } from "lwc";

export default class test extends LightningElement{
    isKanbanView = false;
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
}