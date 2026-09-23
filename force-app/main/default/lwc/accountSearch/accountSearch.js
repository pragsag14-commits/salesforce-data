import { LightningElement, track, wire } from 'lwc';
import { gql, graphql, refreshGraphQL } from 'lightning/uiGraphQLApi';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// GraphQL query replacing searchAccounts Apex method
const ACCOUNT_SEARCH_QUERY = gql`
    query searchAccounts($searchKey: String!) {
        uiapi {
            query {
                Account(
                    where: { Name: { like: $searchKey } }
                    first: 50
                ) {
                    edges {
                        node {
                            Id
                            Name { value }
                            Industry { value }
                            Contacts {
                                edges {
                                    node {
                                        Id
                                        Name { value }
                                        Title { value }
                                        Phone { value }
                                        Email { value }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
`;

export default class AccountSearch extends LightningElement {
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

    // Holds wire provisioned result for refreshGraphQL
    graphqlResult;

    // Reactive variable for GraphQL wire query
    get gqlVariables() {
        return {
            searchKey: this.searchTerm && this.searchTerm.length >= 2 
                ? `%${this.searchTerm}%` 
                : ''
        };
    }

    // Wired GraphQL Adapter
    @wire(graphql, {
        query: ACCOUNT_SEARCH_QUERY,
        variables: '$gqlVariables'
    })
    wiredAccounts(result) {
        this.graphqlResult = result;
        const { data, error } = result;

        if (data && this.searchTerm.length >= 2) {
            const accountEdges = data.uiapi?.query?.Account?.edges || [];
            
            // Normalize GraphQL Relay structure into flat JS objects
            this.accounts = accountEdges.map(edge => {
                const acc = edge.node;
                const contacts = (acc.Contacts?.edges || []).map(conEdge => ({
                    Id: conEdge.node.Id,
                    Name: conEdge.node.Name?.value,
                    Title: conEdge.node.Title?.value,
                    Phone: conEdge.node.Phone?.value,
                    Email: conEdge.node.Email?.value
                }));

                const hasContacts = contacts.length > 0;

                return {
                    Id: acc.Id,
                    Name: acc.Name?.value,
                    Industry: acc.Industry?.value,
                    Contacts: contacts,
                    hasContacts: hasContacts,
                    buttonLabel: hasContacts ? 'View Contact' : 'Add Contact',
                    buttonVariant: hasContacts ? 'brand' : 'success'
                };
            });

            // Keep modal list synchronized if modal is open during a refresh
            if (this.isListModalOpen) {
                const currentAcc = this.accounts.find(acc => acc.Id === this.selectedAccountId);
                this.selectedContacts = currentAcc ? currentAcc.Contacts : [];
                if (!this.selectedContacts || this.selectedContacts.length === 0) {
                    this.closeModal();
                }
            }
        } else {
            this.accounts = [];
            if (error && this.searchTerm.length >= 2) {
                this.showToast('Error', error[0]?.message || 'Error fetching data', 'error');
            }
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleMainAction(event) {
        this.selectedAccountId = event.target.dataset.id;
        const hasContacts = event.target.dataset.hascontacts === 'true';

        if (hasContacts) {
            const selectedAcc = this.accounts.find(acc => acc.Id === this.selectedAccountId);
            this.selectedContacts = selectedAcc ? selectedAcc.Contacts : [];
            this.isListModalOpen = true;
        } else {
            this.editContactId = null;
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
        
        // Native LDS delete function replacing Apex deleteContact
        deleteRecord(conId)
            .then(() => {
                this.showToast('Success', 'Contact deleted successfully', 'success');
                return refreshGraphQL(this.graphqlResult);
            })
            .catch(error => {
                this.showToast('Error', error?.body?.message || 'Failed to delete contact', 'error');
            });
    }

    handleFormSuccessEvent() {
        this.showToast('Success', 'Contact saved successfully!', 'success');
        this.closeModal();
        // Refresh GraphQL cache after adding or editing a contact
        refreshGraphQL(this.graphqlResult);
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