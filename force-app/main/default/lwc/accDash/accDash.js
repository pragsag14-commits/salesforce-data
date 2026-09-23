import { LightningElement, api, wire } from 'lwc';
import { gql, graphql } from 'lightning/graphql';

// Dynamic GraphQL query function
const getDashboardQuery = (recordId) => {
    if (!recordId) return null; // Prevents wire call if recordId is missing
    return gql`
        query getAccountDashboard($recordId: ID!) {
            uiapi {
                query {
                    Account(where: { Id: { eq: $recordId } }) {
                        edges {
                            node {
                                Id
                                Name { value }
                                AnnualRevenue { value, displayValue }
                                Rating { value }
                                Type { value }
                                Industry { value }
                                Phone { value }
                                Website { value }
                            }
                        }
                    }
                    Contact(where: { AccountId: { eq: $recordId } }, first: 5) {
                        edges {
                            node {
                                Id
                                Name { value }
                                Title { value }
                                Email { value }
                                Phone { value }
                            }
                        }
                    }
                    Opportunity(where: { AccountId: { eq: $recordId }, IsClosed: { eq: false } }, first: 100) {
                        edges {
                            node {
                                Id
                                Name { value }
                                StageName { value }
                                Amount { value, displayValue }
                                CloseDate { value }
                            }
                        }
                    }
                    Case(where: { AccountId: { eq: $recordId }, IsClosed: { eq: false } }, first: 5) {
                        edges {
                            node {
                                Id
                                CaseNumber { value }
                                Subject { value }
                                Priority { value }
                                Status { value }
                            }
                        }
                    }
                }
            }
        }
    `;
};

export default class AccDash extends LightningElement {
    @api recordId;
    dashboardData;
    error;
    isLoading = true;

    // Computed property for wire query
    get dynamicQuery() {
        return getDashboardQuery(this.recordId);
    }

    get graphqlVariables() {
        return {
            recordId: this.recordId || ''
        };
    }

    @wire(graphql, {
        query: '$dynamicQuery',
        variables: '$graphqlVariables'
    })
    wiredGraphQL({ data, errors }) {
        this.isLoading = false;
        if (data) {
            this.error = undefined;
            this.processData(data);
        } else if (errors) {
            this.dashboardData = undefined;
            this.error = errors.map(e => e.message).join(', ');
        }
    }

    processData(data) {
        const query = data.uiapi.query;

        // Account
        const accNode = query.Account?.edges[0]?.node;
        const account = accNode ? {
            Name: accNode.Name?.value,
            AnnualRevenue: accNode.AnnualRevenue?.value || 0,
            AnnualRevenueFormatted: accNode.AnnualRevenue?.displayValue || '$0',
            Rating: accNode.Rating?.value || 'N/A',
            Type: accNode.Type?.value || 'N/A',
            Industry: accNode.Industry?.value || 'N/A',
            Phone: accNode.Phone?.value,
            Website: accNode.Website?.value
        } : {};

        // Contacts
        const contacts = (query.Contact?.edges || []).map(edge => ({
            Id: edge.node.Id,
            Name: edge.node.Name?.value,
            Title: edge.node.Title?.value,
            Email: edge.node.Email?.value,
            Phone: edge.node.Phone?.value
        }));

        // Opportunities
        const opportunities = (query.Opportunity?.edges || []).map(edge => ({
            Id: edge.node.Id,
            Name: edge.node.Name?.value,
            StageName: edge.node.StageName?.value,
            Amount: edge.node.Amount?.value || 0,
            AmountFormatted: edge.node.Amount?.displayValue || '$0',
            CloseDate: edge.node.CloseDate?.value
        }));

        // Cases
        const cases = (query.Case?.edges || []).map(edge => ({
            Id: edge.node.Id,
            CaseNumber: edge.node.CaseNumber?.value,
            Subject: edge.node.Subject?.value,
            Priority: edge.node.Priority?.value,
            Status: edge.node.Status?.value
        }));

        // Summaries
        const openDealsCount = opportunities.length;
        const totalPipelineValue = opportunities.reduce((sum, opp) => sum + opp.Amount, 0);
        const openCasesCount = cases.length;

        this.dashboardData = {
            account,
            contacts,
            opportunities,
            cases,
            openDealsCount,
            totalPipelineValue: `$${totalPipelineValue.toLocaleString()}`,
            openCasesCount
        };
    }

    get hasNoRecordId() {
        return !this.recordId;
    }
}