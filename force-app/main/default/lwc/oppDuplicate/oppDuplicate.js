import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions'; 
import checkDuplicates from '@salesforce/apex/OppDuplicate.checkDuplicates';

const COLUMNS = [
    { label: 'Opportunity Name', fieldName: 'name', type: 'text' },
    { label: 'Owner', fieldName: 'ownerName', type: 'text' },
    { label: 'Stage', fieldName: 'stage', type: 'text' },
    { label: 'Created Date', fieldName: 'createdDate', type: 'date', 
      typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' } }
];

export default class OppDuplicate extends NavigationMixin(LightningElement) {
    @api recordId; // Injected automatically from the Account Record context page
    
    @track showWarningState = false;
    @track duplicateOpps = [];
    columns = COLUMNS;
    savedFields = {};

    // Getters managing smooth element state switching without DOM dropped elements
    get formVisibilityClass() {
        return this.showWarningState ? 'slds-hide' : 'slds-show slds-p-around_medium';
    }

    get warningVisibilityClass() {
        return this.showWarningState ? 'slds-show slds-p-around_medium' : 'slds-hide';
    }

    handleFormSubmit(event) {
        event.preventDefault(); // Pause the direct transaction
        
        const fields = event.detail.fields;
        this.savedFields = fields;
        
        // Ensure standard link to this parent Account
        this.savedFields.AccountId = this.recordId; 

        // Query server database configuration
        checkDuplicates({ accountId: this.recordId })
            .then((result) => {
                if (result && result.length > 0) {
                    this.duplicateOpps = result;
                    this.showWarningState = true; 
                } else {
                    this.executeSubmit();
                }
            })
            .catch((error) => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    executeSubmit() {
        this.template.querySelector('lightning-record-edit-form').submit(this.savedFields);
    }

    handleSuccess(event) {
        this.showToast('Success', 'Opportunity created successfully!', 'success');
        this.dispatchEvent(new CloseActionScreenEvent()); // Close Custom Action box

        // Go directly to the new record view layout
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
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleCancelModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}