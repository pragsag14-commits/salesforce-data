import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_ID_FIELD from '@salesforce/schema/Opportunity.AccountId';


const CONTACT_COLUMNS = [
    { label: 'Name', fieldName: 'name' },
    { label: 'Role', fieldName: 'role' },
    { label: 'Email', fieldName: 'email', type: 'email' }
];


const PRODUCT_COLUMNS = [
    { label: 'Product Name', fieldName: 'name' },
    { label: 'Quantity', fieldName: 'quantity', type: 'number' },
    { label: 'Total Price', fieldName: 'totalPrice', type: 'currency' }
];


export default class OppDetailed extends LightningElement {
    @api recordId;
   
    accountId;
    activeSections = ['account', 'contacts', 'products', 'activities', 'notes'];


    contactColumns = CONTACT_COLUMNS;
    productColumns = PRODUCT_COLUMNS;


    // Related Data Holders
    @track contacts = [];
    @track products = [];
    @track activities = [];
    @track notes = [];


    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_ID_FIELD] })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.accountId = getFieldValue(data, ACCOUNT_ID_FIELD);
        } else if (error) {
            console.error(error);
        }
    }


    handleOpportunityLoad(event) {
        // Record details loaded; trigger supplementary fetches or logic if required
    }


    get hasContacts() {
        return this.contacts && this.contacts.length > 0;
    }


    get hasProducts() {
        return this.products && this.products.length > 0;
    }


    get hasActivities() {
        return this.activities && this.activities.length > 0;
    }


    get hasNotes() {
        return this.notes && this.notes.length > 0;
    }
}