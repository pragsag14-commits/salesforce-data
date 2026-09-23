import { LightningElement, wire } from 'lwc';
import getOpportunities from '@salesforce/apex/OpportunityController.getOpportunities';
import { refreshApex } from '@salesforce/apex';
import updateOpportunityStage from '@salesforce/apex/OpportunityController.updateOpportunityStage';
import getUsers from '@salesforce/apex/OpportunityController.getUsers';
import assignOwner from '@salesforce/apex/OpportunityController.assignOwner';

const COLUMNS = [
    {
        label: 'Opportunity Name',
        fieldName: 'opportunityLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_self'
        }
    },
    {
        label: 'Account',
        fieldName: 'AccountName'
    },
    {
        label: 'Stage',
        fieldName: 'StageName'
    },
    {
        label: 'Amount',
        fieldName: 'Amount',
        type: 'currency'
    },
    {
        label: 'Probability',
        fieldName: 'Probability',
        type: 'percent'
    },
    {
        label: 'Owner',
        fieldName: 'OwnerName'
    },
    {
        label: 'Expected Revenue',
        fieldName: 'ExpectedRevenue',
        type: 'currency'
    }
];

export default class OppCreateTest1 extends LightningElement {

    
    columns = COLUMNS;
    opportunities=[];
    searchKey = '';

    wiredResult;
    @wire(getOpportunities, {searchKey : '$searchKey'})
    wiredOpportunities(result){
        //this.wiredResult = result;
        const { data, error } = result;
        if(data){
            this.opportunities = data.map(opp => {
                return{
                    ...opp,
                    opportunityLink: '/' + opp.Id,
                    AccountName: opp.Account ? opp.Account.Name : '',
                    OwnerName: opp.Owner? opp.Owner.Name : '',
                    Probability: opp.Probability? opp.Probability/100 : 0

                };
            });
            
        }
        else{
            console.error(error);
        }
    }

   

    handleSearch(event) {
        this.searchKey = event.target.value;
    }

}