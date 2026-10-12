/**
 * Runs the BR-014 eligibility check from the Lead record page (BR014-S2).
 * Loads the latest saved Lead and returns the S1 decision unchanged. No rule logic here.
 * The query runs WITH USER_MODE, so a rep who can't read a rule field gets a clear message
 * instead of an answer built on hidden values.
 */
public with sharing class LeadEligibilityController {
  @TestVisible
  private static final String NO_LEAD_MESSAGE = 'Open a lead to check its eligibility.';
  @TestVisible
  private static final String NOT_AVAILABLE_MESSAGE = 'This lead isn\'t available. Refresh the page and try again.';
  @TestVisible
  private static final String NO_ACCESS_MESSAGE = 'You don\'t have access to all the lead details the check needs. Ask your admin for the Sales Rep Base permission set.';

  @AuraEnabled(cacheable=false)
  public static LeadEligibilityResult checkEligibility(Id leadId) {
    if (leadId == null) {
      throw handled(NO_LEAD_MESSAGE);
    }

    List<Lead> leads;
    try {
      leads = LeadSelector.selectByIds(new Set<Id>{ leadId });
    } catch (Exception e) {
      // WITH USER_MODE throws QueryException for a missing object or field permission.
      if (!(e instanceof QueryException || e instanceof NoAccessException)) {
        throw e;
      }
      throw handled(NO_ACCESS_MESSAGE);
    }

    if (leads.isEmpty()) {
      throw handled(NOT_AVAILABLE_MESSAGE);
    }
    return LeadEligibilityService.evaluate(leads[0]);
  }

  /** AuraHandledException only shows its message to the rep when it is set with setMessage. */
  private static AuraHandledException handled(String message) {
    AuraHandledException error = new AuraHandledException(message);
    error.setMessage(message);
    return error;
  }
}
