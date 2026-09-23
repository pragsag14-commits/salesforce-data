public with sharing class JiraPayloadBuilder {
    public static Map<String, Object> buildPayloadMap(
        Case caseRecord,
        Jira_Mapping__mdt mapping
    ) {

        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> fields = new Map<String, Object>();

        // Project
        fields.put(
            'project',
            new Map<String, Object>{
                'key' => mapping.Jira_Project_Key__c
            }
        );
        
        // Issue Type
        fields.put(
            'issuetype',
            new Map<String, Object>{
                'name' => mapping.Jira_Issue_Type__c
            }
        );
        
        // Summary
        fields.put(
            'summary',
            String.isBlank(caseRecord.Subject)
                ? 'Salesforce Case'
                : caseRecord.Subject
        );
        
        // Description (ADF Format)
        Map<String, Object> description = new Map<String, Object>{
            'type' => 'doc',
            'version' => 1,
            'content' => new List<Object>{
                new Map<String, Object>{
                    'type' => 'paragraph',
                    'content' => new List<Object>{
                        new Map<String, Object>{
                            'type' => 'text',
                            'text' => String.isBlank(caseRecord.Description)
                                ? 'No Description Provided'
                                : caseRecord.Description
                        }
                    }
                }
            }
        };

        fields.put('description', description);

        // Labels
        fields.put(
            'labels',
            new List<String>{
                'Salesforce',
                'EmailToCase'
            }
        );

        payload.put('fields', fields);

        return payload;

    }

    /**
     * Returns serialized JSON.
     */
    public static String buildPayload(
        Case caseRecord,
        Jira_Mapping__mdt mapping
    ) {

        return JSON.serialize(
            buildPayloadMap(caseRecord, mapping)
        );

    }

}