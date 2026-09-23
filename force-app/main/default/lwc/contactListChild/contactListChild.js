import { LightningElement, api } from 'lwc';

export default class ContactListChild extends LightningElement {
    @api contacts = []; // Parent se data yaha aayega

    onEditClick(event) {
        const contactId = event.target.dataset.id;
        // Parent ko batane ke liye event fire kiya aur data 'detail' me pass kiya
        const editEvent = new CustomEvent('editcontact', {
            detail: { contactId }
        });
        this.dispatchEvent(editEvent);
    }

    onDeleteClick(event) {
        const contactId = event.target.dataset.id;
        const deleteEvent = new CustomEvent('deletecontact', {
            detail: { contactId }
        });
        this.dispatchEvent(deleteEvent);
    }
}