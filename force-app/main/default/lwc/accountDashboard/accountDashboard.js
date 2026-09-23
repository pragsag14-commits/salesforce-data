import { LightningElement, api, wire } from 'lwc';
import getDashboardData from '@salesforce/apex/AccountDashboardController.getDashboardData';
import { refreshApex } from '@salesforce/apex';

const CONTACT_COLUMNS = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Title', fieldName: 'Title' },
    { label: 'Email', fieldName: 'Email', type: 'email' },
    { label: 'Phone', fieldName: 'Phone', type: 'phone' }
];

const OPP_COLUMNS = [
    { label: 'Opportunity', fieldName: 'Name' },
    { label: 'Stage', fieldName: 'StageName' },
    { label: 'Amount', fieldName: 'Amount', type: 'currency' },
    { label: 'Close Date', fieldName: 'CloseDate', type: 'date-local' }
];

const ACTIVITY_COLUMNS = [
    { label: 'Type', fieldName: 'activityType' },
    { label: 'Subject', fieldName: 'subject' },
    { label: 'Date', fieldName: 'activityDate', type: 'date-local' },
    { label: 'Status', fieldName: 'status' }
];

const CASE_COLUMNS = [
    { label: 'Case #', fieldName: 'CaseNumber' },
    { label: 'Subject', fieldName: 'Subject' },
    { label: 'Status', fieldName: 'Status' },
    { label: 'Priority', fieldName: 'Priority' }
];

export default class AccountDashboard extends LightningElement {
    // recordId is auto-injected by the Account record page
    @api recordId;

    dashboardData;
    error;
    wiredResult;

    contactColumns = CONTACT_COLUMNS;
    oppColumns = OPP_COLUMNS;
    activityColumns = ACTIVITY_COLUMNS;
    caseColumns = CASE_COLUMNS;

    // Wire automatically re-runs when recordId becomes available/changes
    @wire(getDashboardData, { accountId: '$recordId' })
    wiredDashboard(result) {
        this.wiredResult = result;
        const { data, error } = result;

        if (data) {
            this.dashboardData = {
                acc: data.acc,
                contacts: data.contacts,
                opportunities: data.opportunities,
                cases: data.cases,
                kpis: data.kpis,
                // datatable needs a unique key-field; wrapper has no Id, so we synthesize one
                activities: (data.activities || []).map((activity, idx) => {
                    return Object.assign({}, activity, { id: idx });
                })
            };
            this.error = undefined;
        } else if (error) {
            this.error = this.extractErrorMessage(error);
            this.dashboardData = undefined;
        }
    }

    extractErrorMessage(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        if (error && error.message) {
            return error.message;
        }
        return 'Unknown error';
    }

    handleRefresh() {
        return refreshApex(this.wiredResult);
    }

    get noContacts() {
        return this.dashboardData && (!this.dashboardData.contacts || this.dashboardData.contacts.length === 0);
    }
    get noOpportunities() {
        return this.dashboardData && (!this.dashboardData.opportunities || this.dashboardData.opportunities.length === 0);
    }
    get noActivities() {
        return this.dashboardData && (!this.dashboardData.activities || this.dashboardData.activities.length === 0);
    }
    get noCases() {
        return this.dashboardData && (!this.dashboardData.cases || this.dashboardData.cases.length === 0);
    }

    get formattedAnnualRevenue() {
        return this.dashboardData && this.dashboardData.acc
            ? this.formatCurrency(this.dashboardData.acc.AnnualRevenue)
            : '$0';
    }
    get formattedTotalRevenue() {
        return this.dashboardData && this.dashboardData.kpis
            ? this.formatCurrency(this.dashboardData.kpis.totalRevenue)
            : '$0';
    }
    get formattedAvgDealSize() {
        return this.dashboardData && this.dashboardData.kpis
            ? this.formatCurrency(this.dashboardData.kpis.avgDealSize)
            : '$0';
    }

    formatCurrency(value) {
        if (value === undefined || value === null) {
            return '$0';
        }
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            maximumFractionDigits: 0
        }).format(value);
    }
}