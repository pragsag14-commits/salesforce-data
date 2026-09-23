import { LightningElement, wire } from 'lwc';
import getOpportunitiesByStages from '@salesforce/apex/OpportunityController.getOpportunitiesByStages';
import getOpportunityStages from '@salesforce/apex/OpportunityController.getOpportunityStages';
import getRegions from '@salesforce/apex/OpportunityController.getRegions';
import updateOpportunityStage from '@salesforce/apex/OpportunityController.updateOpportunityStage';
import getUsers from '@salesforce/apex/OpportunityController.getUsers';
import assignOwner from '@salesforce/apex/OpportunityController.assignOwner';
import deleteOpportunities from '@salesforce/apex/OpportunityController.deleteOpportunities';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


const COLUMNS = [
    {
        label: 'Opportunity Name',
        type: 'button',
        typeAttributes: {
            label: { fieldName: 'Name' },
            name: 'view_details',
            variant: 'base'
        }
    },
    {
        label: 'Account',
        fieldName: 'AccountName'
    },
    {
        label: 'Stage',
        fieldName: 'StageName'
    },
    {
        label: 'Amount',
        fieldName: 'Amount',
        type: 'currency'
    },
    {
        label: 'Probability',
        fieldName: 'Probability',
        type: 'percent'
    },
    {
        label: 'Owner',
        fieldName: 'OwnerName'
    },
    {
        label: 'Close Date',
        fieldName: 'CloseDate',
        type: 'date',
        typeAttributes: { year: 'numeric', month: '2-digit', day: '2-digit' }
    },
    {
        label: 'Expected Revenue',
        fieldName: 'ExpectedRevenue',
        type: 'currency'
    }
];






export default class OpportunityList extends LightningElement {


    selectedRecordId = null;

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

    // 3. Handle clicking Opportunity Name inside table
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;


        if (actionName === 'view_details') {
            this.selectedRecordId = row.Id; // Sets ID to display detail component in place
        }
    }
    // 4. Return back to list view
    handleBackToList() {
        this.selectedRecordId = null; // Clears ID to bring back the list view
    }


    columns = COLUMNS;


    opportunities = [];


    searchKey = '';


    connectedCallback() {
        this.fetchOpportunitiesByStages();
    }


    selectedStageDropdown = '';
    selectedRegionDropdown = '';
    // single-select owner filter value (OwnerId)
    ownerFilterValue = '';
    // for combobox binding (shows selected option)
    selectedOwnerDropdown = '';
    closeDate = '';


    // Amount range filter (single-select). Values represent numeric boundaries as strings.
    selectedAmountRange = '';
    amountOptions = [
        { label: '₹0 - ₹10,000', value: '0-10000' },
        { label: '₹10,000 - ₹50,000', value: '10000-50000' },
        { label: '₹50,000 - ₹100,000', value: '50000-100000' },
        { label: '₹100,000 - ₹500,000', value: '100000-500000' },
        { label: '₹500,000 - ₹1,000,000', value: '500000-1000000' },
        { label: '₹1,000,000 and above', value: '1000000-*' }
    ];


    handleSearch(event) {
        this.searchKey = event.target.value;
        this.fetchOpportunitiesByStages();
    }


    handleStageDropdownChange(event) {
        const selectedStage = event.detail.value;
        if (selectedStage && !this.stageFilterValues.includes(selectedStage)) {
            this.stageFilterValues = [...this.stageFilterValues, selectedStage];
            this.fetchOpportunitiesByStages();
        }
        this.selectedStageDropdown = '';
    }


    handleRegionDropdownChange(event) {
        const selectedRegion = event.detail.value;
        if (selectedRegion && !this.regionFilterValues.includes(selectedRegion)) {
            this.regionFilterValues = [...this.regionFilterValues, selectedRegion];
            this.fetchOpportunitiesByStages();
        }
        // clear combobox value so user can pick the next region easily
        this.selectedRegionDropdown = '';
    }


    handleCloseDateChange(event) {
        this.closeDate = event.target.value;
        this.fetchOpportunitiesByStages();
    }


    handleStageFilterRemove(event) {
        const valueToRemove = event.currentTarget.dataset.stage;
        this.stageFilterValues = this.stageFilterValues.filter(stage => stage !== valueToRemove);
        this.fetchOpportunitiesByStages();
    }


    handleRegionFilterRemove(event) {
        const valueToRemove = event.currentTarget.dataset.region;
        this.regionFilterValues = this.regionFilterValues.filter(region => region !== valueToRemove);
        this.fetchOpportunitiesByStages();
    }


    handleOwnerDropdownChange(event) {
        const selectedOwner = event.detail.value;
        // single-select: set the selected owner id and fetch
        this.ownerFilterValue = selectedOwner || '';
        // keep combobox in sync
        this.selectedOwnerDropdown = this.ownerFilterValue;
        this.fetchOpportunitiesByStages();
    }


    handleOwnerFilterRemove(event) {
        // clear single owner filter
        this.ownerFilterValue = '';
        this.selectedOwnerDropdown = '';
        this.fetchOpportunitiesByStages();
    }


    handleAmountChange(event) {
        this.selectedAmountRange = event.detail.value || '';
        this.fetchOpportunitiesByStages();
    }


    handleAmountFilterRemove(event) {
        this.selectedAmountRange = '';
        this.fetchOpportunitiesByStages();
    }


    get hasStageFilters() {
        return this.stageFilterValues && this.stageFilterValues.length > 0;
    }


    get hasRegionFilters() {
        return this.regionFilterValues && this.regionFilterValues.length > 0;
    }


    get hasOwnerFilters() {
        return !!this.ownerFilterValue;
    }


    get hasAmountFilter() {
        return !!this.selectedAmountRange;
    }


    get availableStageOptions() {
        return this.stageOptions.filter(option => !this.stageFilterValues.includes(option.value));
    }


    get availableRegionOptions() {
        return this.regionOptions.filter(option => !this.regionFilterValues.includes(option.value));
    }


    get availableOwnerOptions() {
        // single-select owner combobox should show all options
        return this.ownerOptions || [];
    }


    get availableAmountOptions() {
        return this.amountOptions;
    }


    handleRefresh() {
        this.fetchOpportunitiesByStages();
    }


    fetchOpportunitiesByStages() {
        console.log('Fetching opportunities with closeDate:', this.closeDate, 'stageFilters:', this.stageFilterValues, 'regionFilters:', this.regionFilterValues, 'searchKey:', this.searchKey);
        getOpportunitiesByStages({
            stageNames: this.stageFilterValues,
            regionNames: this.regionFilterValues,
            searchKey: this.searchKey,
            closeDate: this.closeDate
        })
            .then(data => {
                // map incoming records and normalize fields for datatable
                let mapped = data.map(item => ({
                    ...item,
                    opportunityLink: '/' + item.Id,
                    AccountName: item.Account ? item.Account.Name : '',
                    OwnerName: item.Owner ? item.Owner.Name : '',
                    Probability: item.Probability ? item.Probability / 100 : 0
                }));


                // If owner single-select filter is applied, filter client-side by OwnerId (owners come from wired getUsers)
                if (this.ownerFilterValue) {
                    mapped = mapped.filter(item => item.OwnerId === this.ownerFilterValue);
                }


                // If amount range filter is applied, filter client-side by Amount
                if (this.selectedAmountRange) {
                    mapped = this.applyAmountFilter(mapped, this.selectedAmountRange);
                }


                this.opportunities = mapped;
            })
            .catch(error => {
                console.error(error);
            });
    }


    handleDelete() {


        if (this.selectedOpportunityIds.length === 0) {
            alert('Please select at least one Opportunity.');
            return;
        }


        // Ask for confirmation before deleting
        if (!confirm('Are you sure you want to delete the selected opportunities? This action cannot be undone.')) {
            return;
        }


        deleteOpportunities({ opportunityIds: this.selectedOpportunityIds })
            .then(() => {
                // clear selection and refresh data
                this.selectedOpportunityIds = [];
                this.fetchOpportunitiesByStages();
            })
            .catch(error => {
                console.error(error);
                const message = (error && error.body && error.body.message) ? error.body.message : (error && error.message) ? error.message : 'Unknown error';
                alert('Error deleting opportunities: ' + message);
            });


    }


    selectedOpportunityIds = [];
    showStageModal = false;
    selectedStage = '';


    stageFilterValues = [];
    stageOptions = [];


    regionFilterValues = [];
    regionOptions = [];




    @wire(getOpportunityStages)
    wiredStages({ error, data }) {
        if (data) {
            this.stageOptions = data;
        } else if (error) {
            console.error(error);
        }
    }


    @wire(getRegions)
    wiredRegions({ error, data }) {
        if (data) {
            this.regionOptions = data;
        } else if (error) {
            console.error(error);
        }
    }


    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedOpportunityIds = selectedRows.map(row => row.Id);
        console.log(this.selectedOpportunityIds);
    }


    handleStage() {


        if (this.selectedOpportunityIds.length === 0) {
            alert('Please select at least one Opportunity.');
            return;
        }
        this.showStageModal = true;
    }


    handleStageChange(event) {


        this.selectedStage = event.detail.value;
        if (this.selectedStage === "Closed Lost") {
            this.showReasonField = true;
        }
        else {


            this.showReasonField = false;


            this.closedLostReason = '';


        }
    }
    closeModal() {


        this.showStageModal = false;
        this.selectedStage = '';


        this.closedLostReason = '';


        this.showReasonField = false;




    }
    saveStage() {


        if (
            this.selectedStage === 'Closed Lost' &&
            !this.closedLostReason.trim()
        ) {
            alert('Please enter the reason for Closing Lost.');
            return;
        }


        updateOpportunityStage({


            opportunityIds: this.selectedOpportunityIds,


            stageName: this.selectedStage,


            reason: this.closedLostReason


        })






            .then(() => {


                this.showStageModal = false;


                this.selectedOpportunityIds = [];


                this.selectedStage = '';
                this.closedLostReason = '';


                this.showReasonField = false;


                this.fetchOpportunitiesByStages();


            })


            .catch(error => {


                console.log(error);


            });


    }


    //For Reason Giving of Closed Lost
    closedLostReason = '';


    showReasonField = false;


    handleReasonChange(event) {


        this.closedLostReason = event.target.value;


    }
    //For Assigning Owner
    showOwnerModal = false;
    selectedOwnerId = '';
    ownerOptions = [];
    @wire(getUsers)
    wiredUsers({ data, error }) {


        if (data) {


            this.ownerOptions = data.map(user => {


                return {


                    label: user.Name,
                    value: user.Id


                };


            });


        } else if (error) {


            console.error(error);


        }


    }
    handleOwner() {


        if (this.selectedOpportunityIds.length === 0) {


            alert('Please select at least one Opportunity.');


            return;


        }


        this.showOwnerModal = true;


    }
    handleOwnerChange(event) {


        this.selectedOwnerId = event.detail.value;


    }
    saveOwner() {


        assignOwner({


            opportunityIds: this.selectedOpportunityIds,


            ownerId: this.selectedOwnerId


        })


            .then(() => {
                this.showOwnerModal = false;


                this.selectedOwnerId = '';


                this.selectedOpportunityIds = [];


                this.fetchOpportunitiesByStages();


            })
            .catch(error => {


                console.error(error);


            });


    }
    closeOwnerModal() {


        this.showOwnerModal = false;


        this.selectedOwnerId = '';


    }


    get ownerFilterPills() {
        if (!this.ownerFilterValue) return [];
        const opt = (this.ownerOptions || []).find(o => o.value === this.ownerFilterValue);
        return [{ id: this.ownerFilterValue, label: opt ? opt.label : this.ownerFilterValue }];
    }


    get amountFilterPill() {
        if (!this.selectedAmountRange) return null;
        const opt = (this.amountOptions || []).find(o => o.value === this.selectedAmountRange);
        return opt ? { id: this.selectedAmountRange, label: opt.label } : { id: this.selectedAmountRange, label: this.selectedAmountRange };
    }


    // small helper: filter by amount range
    applyAmountFilter(records, rangeValue) {
        if (!rangeValue) return records;
        const parts = rangeValue.split('-');
        const lower = parseFloat(parts[0]) || 0;
        const upper = parts[1] === '*' ? null : (parseFloat(parts[1]) || null);


        return records.filter(rec => {
            const amt = rec.Amount == null ? 0 : Number(rec.Amount);
            if (upper === null) {
                return amt >= lower;
            }
            return amt >= lower && amt <= upper;
        });
    }


    //Export to CSV
    handleExport() {


        if (this.selectedOpportunityIds.length === 0) {
            alert('Please select at least one Opportunity to export.');
            return;
        }


        const selectedRecords = this.opportunities.filter(
            opportunity => this.selectedOpportunityIds.includes(opportunity.Id)
        );


        this.exportToCSV(selectedRecords);
    }




    exportToCSV(records) {
    const headers = [
        'Opportunity Name',
        'Account',
        'Stage',
        'Amount',
        'Probability',
        'Owner',
        'Expected Revenue'
    ];


    const rows = records.map(record => {
        return [
            record.Name,
            record.AccountName,
            record.StageName,
            record.Amount,
            (record.Probability*100)+'%',
            record.OwnerName,
            record.ExpectedRevenue
        ];
    });


    let csvContent = headers.join(',') + '\n';


    rows.forEach(row => {
        csvContent += row.map(value =>
            {
                return `"${value ?? ''}"`;
            }).join(',') + '\n';
    });


    this.downloadCSV(csvContent);
    }


    downloadCSV(csvContent) {
        const element = document.createElement('a');
        element.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);
        element.target = '_self';
        element.download = 'Opportunities.csv';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    }
}