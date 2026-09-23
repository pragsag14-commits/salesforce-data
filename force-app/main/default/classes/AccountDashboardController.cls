public with sharing class AccountDashboardController {

    @AuraEnabled(cacheable=true)
    public static DashboardWrapper getDashboardData(Id accountId) {
        DashboardWrapper wrapper = new DashboardWrapper();

        // ---------- 1. ACCOUNT DETAILS ----------
        wrapper.acc = [
            SELECT Id, Name, Industry, Rating, AnnualRevenue,
                   Owner.Name, LastActivityDate
            FROM Account
            WHERE Id = :accountId
            WITH USER_MODE
        ];

        // ---------- 2. RELATED CONTACTS (recent 5) ----------
        wrapper.contacts = [
            SELECT Id, Name, Title, Email, Phone
            FROM Contact
            WHERE AccountId = :accountId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];

        // ---------- 3. OPEN OPPORTUNITIES ----------
        wrapper.opportunities = [
            SELECT Id, Name, StageName, Amount, CloseDate
            FROM Opportunity
            WHERE AccountId = :accountId AND IsClosed = false
            WITH USER_MODE
            ORDER BY CloseDate ASC
        ];

        // ---------- 4. RECENT ACTIVITIES (Tasks + Events, merged) ----------
        List<ActivityWrapper> activityList = new List<ActivityWrapper>();

        List<Task> recentTasks = [
            SELECT Id, Subject, ActivityDate, Status, TaskSubtype
            FROM Task
            WHERE AccountId = :accountId
            WITH USER_MODE
            ORDER BY ActivityDate DESC NULLS LAST
            LIMIT 5
        ];
        for (Task t : recentTasks) {
            String activityType = (t.TaskSubtype == 'Call') ? 'Call' : 'Task';
            activityList.add(new ActivityWrapper(
                activityType, t.Subject, t.ActivityDate, t.Status
            ));
        }

        List<Event> recentEvents = [
            SELECT Id, Subject, ActivityDate
            FROM Event
            WHERE AccountId = :accountId
            WITH USER_MODE
            ORDER BY ActivityDate DESC NULLS LAST
            LIMIT 5
        ];
        for (Event e : recentEvents) {
            activityList.add(new ActivityWrapper(
                'Event', e.Subject, e.ActivityDate, 'Scheduled'
            ));
        }

        // Sort combined Task+Event list by date (most recent first), cap at 5
activityList.sort();

List<ActivityWrapper> topFiveActivities = new List<ActivityWrapper>();
Integer activityCount = Math.min(5, activityList.size());
for (Integer i = 0; i < activityCount; i++) {
    topFiveActivities.add(activityList[i]);
}
wrapper.activities = topFiveActivities;

        // ---------- 5. OPEN CASES (recent 5) ----------
        wrapper.cases = [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate
            FROM Case
            WHERE AccountId = :accountId AND IsClosed = false
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];

        // ---------- 6. KPIs (derived from data already queried above) ----------
        KPIWrapper kpi = new KPIWrapper();
        Decimal totalRevenue = 0;
        Integer openOppCount = wrapper.opportunities.size();

        for (Opportunity o : wrapper.opportunities) {
            totalRevenue += (o.Amount != null ? o.Amount : 0);
        }

        kpi.totalRevenue    = totalRevenue;
        kpi.totalOpenOpps   = openOppCount;
        kpi.avgDealSize     = (openOppCount > 0) ? (totalRevenue / openOppCount) : 0;
        kpi.lastActivityDate = wrapper.acc.LastActivityDate;

        kpi.totalContacts = [SELECT COUNT() FROM Contact WHERE AccountId = :accountId];

        wrapper.kpis = kpi;

        return wrapper;
    }

    // =====================================================
    // WRAPPER CLASSES
    // =====================================================

    public class DashboardWrapper {
        @AuraEnabled public Account acc;
        @AuraEnabled public List<Contact> contacts;
        @AuraEnabled public List<Opportunity> opportunities;
        @AuraEnabled public List<ActivityWrapper> activities;
        @AuraEnabled public List<Case> cases;
        @AuraEnabled public KPIWrapper kpis;
    }

    public class ActivityWrapper implements Comparable {
        @AuraEnabled public String activityType; // Task / Call / Event
        @AuraEnabled public String subject;
        @AuraEnabled public Date activityDate;
        @AuraEnabled public String status;

        public ActivityWrapper(String activityType, String subject, Date activityDate, String status) {
            this.activityType = activityType;
            this.subject = subject;
            this.activityDate = activityDate;
            this.status = status;
        }

        // Sorts descending (most recent activity first)
        public Integer compareTo(Object compareTo) {
            ActivityWrapper other = (ActivityWrapper) compareTo;
            if (this.activityDate == other.activityDate) return 0;
            if (this.activityDate == null) return 1;
            if (other.activityDate == null) return -1;
            return (this.activityDate < other.activityDate) ? 1 : -1;
        }
    }

    public class KPIWrapper {
        @AuraEnabled public Decimal totalRevenue;
        @AuraEnabled public Integer totalOpenOpps;
        @AuraEnabled public Date lastActivityDate;
        @AuraEnabled public Integer totalContacts;
        @AuraEnabled public Decimal avgDealSize;
    }
}