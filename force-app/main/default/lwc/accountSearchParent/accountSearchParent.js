import { LightningElement, track } from 'lwc';
import searchAccounts from '@salesforce/apex/AccountSearchController.searchAccounts';
import deleteContact from '@salesforce/apex/AccountSearchController.deleteContact';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountSearchParent extends LightningElement {
    @track searchTerm = '';
    @track accounts = [];
    
    // Modal controls
    @track isListModalOpen = false;
    @track isFormModalOpen = false;
    @track formModalHeader = '';

    // Data tracking
    @track selectedContacts = [];
    selectedAccountId = '';
    editContactId = null;

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        if (this.searchTerm.length >= 2) {
            this.fetchAccounts();
        } else {
            this.accounts = [];
        }
    }

    fetchAccounts() {
        searchAccounts({ searchKey: this.searchTerm })
            .then(result => {
                this.accounts = result.map(acc => {
                    const hasContacts = acc.Contacts && acc.Contacts.length > 0;
                    return {
                        ...acc,
                        hasContacts: hasContacts,
                        buttonLabel: hasContacts ? 'View Contact' : 'Add Contact',
                        buttonVariant: hasContacts ? 'brand' : 'success'
                    };
                });
                if (this.isListModalOpen) {
                    const currentAcc = this.accounts.find(acc => acc.Id === this.selectedAccountId);
                    this.selectedContacts = currentAcc ? currentAcc.Contacts : [];
                    if (!this.selectedContacts || this.selectedContacts.length === 0) {
                        this.closeModal();
                    }
                }
            })
            .catch(error => this.showToast('Error', error.body.message, 'error'));
    }

    handleMainAction(event) {
        this.selectedAccountId = event.target.dataset.id;
        const hasContacts = event.target.dataset.hascontacts === 'true';

        if (hasContacts) {
            const selectedAcc = this.accounts.find(acc => acc.Id === this.selectedAccountId);
            this.selectedContacts = selectedAcc.Contacts;
            this.isListModalOpen = true;
        } else {
            this.editContactId = null; // Fresh entry
            this.formModalHeader = 'Add Contact';
            this.isFormModalOpen = true;
        }
    }

    handleEditContactEvent(event) {
        this.editContactId = event.detail.contactId;
        this.isListModalOpen = false; 
        this.formModalHeader = 'Edit Contact';
        this.isFormModalOpen = true; 
    }

    handleDeleteContactEvent(event) {
        const conId = event.detail.contactId;
        deleteContact({ contactId: conId })
            .then(() => {
                this.showToast('Success', 'Contact deleted successfully', 'success');
                this.fetchAccounts(); 
            })
            .catch(error => this.showToast('Error', 'Failed to delete contact', 'error'));
    }

    handleFormSuccessEvent() {
        this.showToast('Success', 'Contact saved successfully!', 'success');
        this.closeModal();
        this.fetchAccounts(); 
    }

    closeModal() {
        this.isListModalOpen = false;
        this.isFormModalOpen = false;
        this.editContactId = null;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}