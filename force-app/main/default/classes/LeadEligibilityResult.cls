/**
 * The eligibility answer for one Lead (BR014-S1).
 * S2 shows it to the rep and S3 saves it on the Lead, so both use the same answer.
 */
public with sharing class LeadEligibilityResult {
  public static final String ELIGIBLE = 'Eligible';
  public static final String NOT_ELIGIBLE = 'Not eligible';

  @AuraEnabled
  public Id leadId;
  @AuraEnabled
  public Boolean isEligible;
  @AuraEnabled
  public String outcome;
  /**
   * Rule codes the lead failed, for example R2 and R4. Only R1 to R4 can appear:
   * a missing email is a missing detail, so R5 never shows up here.
   */
  @AuraEnabled
  public List<String> failedRules = new List<String>();
  /** Details the rules need but the lead does not have, for example Email. */
  @AuraEnabled
  public List<String> missingDetails = new List<String>();
  /** Plain-word lines for the rep, one per failed rule or missing detail. */
  @AuraEnabled
  public List<String> reasons = new List<String>();

  public LeadEligibilityResult(Id leadId) {
    this.leadId = leadId;
  }
}
