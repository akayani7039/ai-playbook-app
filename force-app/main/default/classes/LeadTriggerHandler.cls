/**
 * Routes Lead trigger events. Add new Lead logic as a service call here.
 */
public with sharing class LeadTriggerHandler extends TriggerHandler {
  protected override void beforeInsert(List<SObject> newRecords) {
    LeadDataStandardizer.standardize((List<Lead>) newRecords);
  }

  protected override void beforeUpdate(
    List<SObject> newRecords,
    Map<Id, SObject> oldRecordsById
  ) {
    LeadDataStandardizer.standardize((List<Lead>) newRecords);
  }
}
