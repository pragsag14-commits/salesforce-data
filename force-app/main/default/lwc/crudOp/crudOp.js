import { LightningElement } from 'lwc';

import createAccount from '@salesforce/apex/AccountController.createAccount';
import updateAccount from '@salesforce/apex/AccountController.updateAccount';
import deleteAccount from '@salesforce/apex/AccountController.deleteAccount';

export default class AccountCrud extends LightningElement {

    accountId = '';

    name = '';

    phone = '';

    handleName(event){

        this.name = event.target.value;

    }

    handlePhone(event){

        this.phone = event.target.value;

    }

    createAccount(){

        createAccount({
            accName: this.name,
            phone: this.phone
        })
        .then(result => {

            this.accountId = result.Id;

            alert('Account Created');

        })
        .catch(error => {

            console.error(error);

        });

    }

    updateAccount(){

        if(!this.accountId){

            alert('Create an account first');

            return;

        }

        updateAccount({
            accountId: this.accountId,
            accName: this.name,
            phone: this.phone
        })
        .then(() => {

            alert('Account Updated');

        })
        .catch(error => {

            console.error(error);

        });

    }

    deleteAccount(){

        if(!this.accountId){

            alert('No Account Found');

            return;

        }

        deleteAccount({
            accountId: this.accountId
        })
        .then(() => {

            this.accountId = '';
            this.name = '';
            this.phone = '';

            alert('Account Deleted');

        })
        .catch(error => {

            console.error(error);

        });
    }
}