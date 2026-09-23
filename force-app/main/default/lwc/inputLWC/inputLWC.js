import { LightningElement } from 'lwc';

export default class InputLWC extends LightningElement {
    greeting = 'World';

    handleEvent(event){
        this.greeting = handleEvent.target.value;
    }
}