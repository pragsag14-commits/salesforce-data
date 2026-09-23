import { LightningElement, api } from 'lwc';

export default class ContactFormChild extends LightningElement {
    @api accountId; 
    @api contactId; 

    handleSuccess() {
        this.dispatchEvent(new CustomEvent('formsuccess'));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}