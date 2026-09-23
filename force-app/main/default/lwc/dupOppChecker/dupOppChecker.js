import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import checkDuplicates from '@salesforce/apex/OpportunityDuplicateChecker.checkDuplicates';

const COLUMNS = [
    { label: 'Opportunity Name', fieldName: 'name', type: 'text' },
    { label: 'Owner', fieldName: 'ownerName', type: 'text' },
    { label: 'Stage', fieldName: 'stage', type: 'text' },
    { label: 'Created Date', fieldName: 'createdDate', type: 'date', 
      typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' } }
];

export default class DupOppChecker extends NavigationMixin(LightningElement) {
    @api recordId; // Automatically populated with Account Id when on Account Page
    
    @track showWarningState = false;
    @track duplicateOpps = [];
    columns = COLUMNS;
    
    // Store fields temporarily if we need to bypass warning later
    savedFields = {};

    handleFormSubmit(event) {
        event.preventDefault(); // Stop immediate database commit
        
        const fields = event.detail.fields;
        this.savedFields = fields;

        // Ensure we have an AccountId to query against
        const accId = fields.AccountId || this.recordId;

        if (!accId) {
            // Fallback commit if no account is designated
            this.executeSubmit();
            return;
        }

        checkDuplicates({ accountId: accId })
            .then((result) => {
                if (result && result.length > 0) {
                    this.duplicateOpps = result;
                    this.showWarningState = true; // Switch layout view to warning screen
                } else {
                    this.executeSubmit();
                }
            })
            .catch((error) => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    executeSubmit() {
        // Explicitly submit the record edit form payload
        this.template.querySelector('lightning-record-edit-form').submit(this.savedFields);
    }

    handleSuccess(event) {
        this.showToast('Success', 'Opportunity created successfully!', 'success');
        
        // Navigate to the newly created Opportunity
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    handleCancel() {
        // Simply return to form entry or reset state
        this.showWarningState = false;
    }

    // Add these getters to handle CSS toggling
    get formVisibilityClass() {
        return this.showWarningState ? 'slds-hide' : 'slds-show slds-p-around_medium';
    }

    get warningVisibilityClass() {
        return this.showWarningState ? 'slds-show slds-p-around_medium' : 'slds-hide';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}