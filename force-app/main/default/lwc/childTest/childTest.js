import { LightningElement } from 'lwc';

export default class ChildTest extends LightningElement {
    constructor(){
        super();
        console.log("child constructor");
    }
    connectedCallback(){
        console.log("child connectedCallback");
    }

    renderedCallback(){
        console.log("child renderedCallback");
    }

    disconnectedCallback(){
        console.log("child disconnectedCallback");
    }

    errorCallback(){
        console.log("child errorCallback");
    }
}