/**
 * Saves the latest eligibility outcome on each Lead (BR014-S3).
 * Reps can read the four eligibility fields but not edit them, so only a check can set them.
 * That needs the one approved exception to the user-mode DML rule: the save runs in system
 * mode, which skips field permissions. The class is `with sharing`, so record sharing still
 * applies, and only Id plus the four eligibility fields are ever written.
 * Approved in features/BR014-S3/architecture.md (question 1). Don't copy this pattern elsewhere.
 */
public with sharing class LeadEligibilityRecorder {
  /** One DML for all results. A new check replaces the saved outcome. */
  public static void record(List<LeadEligibilityResult> results) {
    if (results == null) {
      throw new IllegalArgumentException('A list of results is required.');
    }
    if (results.isEmpty()) {
      return;
    }
    if (!Schema.SObjectType.Lead.isUpdateable()) {
      throw new NoAccessException();
    }

    Id checkedBy = UserInfo.getUserId();
    Datetime checkedOn = System.now();
    List<Lead> outcomes = new List<Lead>();
    for (LeadEligibilityResult result : results) {
      outcomes.add(
        new Lead(
          Id = result.leadId,
          Eligibility_Result__c = result.outcome,
          Eligibility_Reasons__c = result.reasons.isEmpty()
            ? null
            : String.join(result.reasons, ';'),
          Eligibility_Checked_By__c = checkedBy,
          Eligibility_Checked_On__c = checkedOn
        )
      );
    }
    Database.update(outcomes, AccessLevel.SYSTEM_MODE);
  }
}
