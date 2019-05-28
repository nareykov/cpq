public class SObjectUtils {

    /**
     * Get Ids from objects using field
     */
    public static Set<Id> getIdSetFromObjects(List<SObject> objects, String fieldApiName) {
        if (fieldApiName.equalsIgnoreCase('Id')) {
            return new Map<Id, SObject>(objects).keySet();
        }

        Set<Id> ids = new Set<Id>();
        if (objects == null || objects.isEmpty()) {
            return ids;
        }
        for (SObject theObject : objects) {
            ids.add((Id) getStringValueFromObject(theObject, fieldApiName));
        }
        ids.remove(null);
        return ids;
    }

    public static Set<Id> getIdSetFromObjects(Set<SObject> objects, String fieldApiName) {
        return getIdSetFromObjects(new List<SObject>(objects), fieldApiName);
    }

    public static Map<Id, List<SObject>> getIdMapFromObjects(List<SObject> objects, String fieldApiName) {
        Map<Id, List<SObject>> maps = new Map<Id, List<SObject>>();
        for (SObject theObject : objects) {
            Id objId = (Id) getStringValueFromObject(theObject, fieldApiName);
            if (objId != null) {
                if (maps.containsKey(objId)) {
                    maps.get(objId).add(theObject);
                } else {
                    maps.put(objId, new List<SObject>{
                            theObject
                    });
                }
            }
        }
        return maps;
    }

    public static Map<String, List<SObject>> getListByNamesMapFromObjects(List<SObject> objects, String fieldApiName) {
        Map<String, List<SObject>> maps = new Map<String, List<SObject>>();
        for (SObject theObject : objects) {
            String objName = getStringValueFromObject(theObject, fieldApiName);
            if (objName != null) {
                if (maps.containsKey(objName)) {
                    maps.get(objName).add(theObject);
                } else {
                    maps.put(objName, new List<SObject>{
                            theObject
                    });
                }
            }
        }
        return maps;
    }

    public static Map<Id, Id> getIdToIdMapFromObjects(List<SObject> objects, SObjectField idMapKey, SObjectField idMapValue) {
        Map<Id, Id> result = new Map<Id, Id>();
        for (SObject theObject : objects) {
            result.put((Id) theObject.get(idMapKey), (Id) theObject.get(idMapValue));
        }
        return result;
    }

    public static String getsNameObjectById(Id objectId) {
        if (objectId != null) {
            Schema.SObjectType sobjectType = objectId.getSobjectType();
            return sobjectType.getDescribe().getName();
        }
        return null;
    }

    public static Map<String, SObject> getNameMapFromObjects(List<SObject> objects, String fieldApiName) {
        Map<String, SObject> maps = new Map<String, SObject>();
        for (SObject theObject : objects) {
            String objName = getStringValueFromObject(theObject, fieldApiName);
            if (objName != null) {
                maps.put(objName, theObject);
            }
        }
        return maps;
    }

    public static String getStringValueFromObject(SObject theObject, String fieldApiName) {
        Object theValue = theObject.get(fieldApiName);
        return theValue != null ? (String) theValue : null;
    }

    /**
     *  Get list of modified objects by defined list of modified fields.
     */
    public static List<SObject> getModifiedObjects(List<String> fields, List<SObject> records, Map<Id, SObject> oldRecordsMap) {
        List<SObject> results = new List<SObject>();

        if (records == null || records.isEmpty()) {
            return results;
        }

        if (oldRecordsMap == null || oldRecordsMap.isEmpty()) {
            return records;
        }

        for (SObject record : records) {
            Id recordId = record.Id;

            if (!oldRecordsMap.containsKey(recordId)) {
                results.add(record);
                continue;
            }

            SObject oldRecord = oldRecordsMap.get(recordId);
            for (String fieldName : fields) {
                if (record.get(fieldName) != oldRecord.get(fieldName)) {
                    results.add(record);
                }
            }
        }
        return results;
    }

    /**
     *   Filter records by record types.
     */
    public static List<SObject> filterRecordsByRecordType(List<SObject> records, Set<Id> recordTypeIds) {
        List<SObject> result = new List<SObject>();
        if (records != null) {
            for (SObject record : records) {
                if (recordTypeIds.contains((Id) record.get('RecordTypeId'))) {
                    result.add(record);
                }
            }
        }
        return result;
    }

    /**
     *   Filter records by record type.
     */
    public static List<SObject> filterRecordsByRecordType(List<SObject> records, Id recordTypeId) {
        return filterRecordsByRecordType(records, new Set<Id>{
                recordTypeId
        });
    }

    public static List<String> getPicklistValues(String objectApiName, String fieldApiName) {
        List<String> result = new List<String>();
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectApiName).newSObject().getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        List<Schema.PicklistEntry> picklistValues = fieldMap.get(fieldApiName).getDescribe().getPicklistValues();
        for (Schema.PicklistEntry entry : picklistValues) {
            result.add(entry.getValue());
        }
        return result;
    }

    public static List<String> getFieldsApiNames(Schema.SObjectType objectType) {
        DescribeSObjectResult describeResult = objectType.getDescribe();
        return new List<String>(describeResult.fields.getMap().keySet());
    }

    public static Map<String, String> getSObjectTabIcons(List<String> sObjectApiName) {
        Set<String> objectNames = new Set<String>();
        objectNames.addAll(sObjectApiName);

        Map<String, String> outputMap = new Map<String, String>();
        for (Schema.DescribeTabSetResult tabSetDescRes : Schema.describeTabs()) {
            List<Schema.DescribeTabResult> tabDescResults = tabSetDescRes.getTabs();

            for (Schema.DescribeTabResult tabDesc : tabDescResults) {
                String sObjectName = tabDesc.getSobjectName();

                if (objectNames.contains(sObjectName)) {
                    if (!tabDesc.isCustom()) {
                        outputMap.put(sObjectName, 'standard:' + sObjectName.toLowerCase());
                        break;
                    }

                    for (Schema.DescribeIconResult iconDesc : tabDesc.getIcons()) {
                        if (iconDesc.getContentType() == 'image/svg+xml') {
                            outputMap.put(sObjectName, 'custom:' + iconDesc.getUrl().substringBetween('custom/', '.svg').substringBefore('_'));
                            break;
                        }
                    }
                }
            }
        }
        return outputMap;
    }

    public static List<Map<String, String>> getPicklistValues(Schema.SObjectType objectType, String fieldApiName) {
        List<Map<String, String>> items = new List<Map<String, String>>();
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        List<Schema.PicklistEntry> ple = fieldMap.get(fieldApiName).getDescribe().getPicklistValues();
        items.add(new Map<String, String>{
                'value' => '', 'label' => '--None--'
        });
        for (Schema.PicklistEntry f : ple) {
            items.add(new Map<String, String>{
                    'value' => f.getValue(), 'label' => f.getLabel()
            });
        }
        return items;
    }

    public static List<String> getFieldValuesFromObjects(List<SObject> records, String fieldName) {
        List<String> result = new List<String>();
        for (SObject record : records) {
            if (record.get(fieldName) != null) {
                result.add(record.get(fieldName).toString());
            }
        }
        return result;
    }

    public class ObjectPermission {
        @AuraEnabled
        public String sObjectName { get; set; }
        @AuraEnabled
        public Map<String, FieldPermission> fields { get; set; }

        public ObjectPermission(Schema.DescribeSObjectResult objectDescribe) {
            this.sObjectName = objectDescribe.getName();
            this.fields = new Map<String, FieldPermission>();

            for (Schema.SObjectField field : objectDescribe.fields.getMap().values()) {
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                this.fields.put(fieldDescribe.getName(), new FieldPermission(fieldDescribe));
            }
        }
    }

    public class FieldPermission {
        @AuraEnabled
        public String helpText { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public List<PicklistValue> picklistValues { get; set; }
        @AuraEnabled
        public Map<String, String> picklistValuesMap { get; set; }

        public FieldPermission(Schema.DescribeFieldResult fieldDescribe) {
            this.helpText = fieldDescribe.getInlineHelpText();
            this.label = fieldDescribe.getLabel();
            this.setPicklistValues(fieldDescribe);
        }

        private void setPicklistValues(Schema.DescribeFieldResult fieldDescribe) {
            this.picklistValues = new List<PicklistValue>();
            this.picklistValuesMap = new Map<String, String>();

            if (fieldDescribe.isRestrictedPicklist() || fieldDescribe.getType() == Schema.DisplayType.PICKLIST) {
                for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                    if (entry.isActive()) {
                        this.picklistValuesMap.put(entry.getValue(), entry.getLabel());
                        this.picklistValues.add(new PicklistValue(entry));
                    }
                }
            }
        }
    }

    public class PicklistValue {
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public String label { get; set; }

        public PicklistValue(Schema.PicklistEntry entry) {
            this.label = entry.getLabel();
            this.value = entry.getValue();
        }
    }
}
