import { LightningElement } from 'lwc';

export default class Practice extends LightningElement {
   //one-way binding
    name = 'Pragati';
    handleChange(event){
        this.name = event.target.value;
    }
}