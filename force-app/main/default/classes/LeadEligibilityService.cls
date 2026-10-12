/**
 * Judges Leads against the BR-014 eligibility rules (BR014-S1).
 * - R1 Based in the US, Canada or UK
 * - R2 50 or more employees
 * - R3 Annual revenue of 1M or more
 * - R4 Not Government or Education
 * - R5 Has an email address
 * Every rule is checked and every failure or missing detail is listed. A blank value is a
 * missing detail, not a failed rule. The answer depends only on the Lead's field values,
 * so every rep gets the same result.
 *
 * No queries or DML. Callers load the Leads through LeadSelector.selectByIds (WITH USER_MODE)
 * so a field the rep can't read fails loudly instead of reading as missing. Don't strip
 * REQUIRED_FIELDS with Security.stripInaccessible before calling this.
 */
public with sharing class LeadEligibilityService {
  public static final Integer MIN_EMPLOYEES = 50;
  public static final Decimal MIN_ANNUAL_REVENUE = 1000000;

  /** The fields the rules read. Callers must load all of them. */
  public static final List<SObjectField> REQUIRED_FIELDS = new List<SObjectField>{
    Lead.Country,
    Lead.NumberOfEmployees,
    Lead.AnnualRevenue,
    Lead.Industry,
    Lead.Email
  };

  @TestVisible
  private static final Set<String> ELIGIBLE_COUNTRIES = new Set<String>{
    LeadDataStandardizer.UNITED_STATES,
    LeadDataStandardizer.CANADA,
    LeadDataStandardizer.UNITED_KINGDOM
  };

  @TestVisible
  private static final Set<String> EXCLUDED_INDUSTRIES = new Set<String>{
    'government',
    'education'
  };

  public static LeadEligibilityResult evaluate(Lead lead) {
    if (lead == null) {
      throw new IllegalArgumentException('A Lead is required.');
    }
    return evaluate(new List<Lead>{ lead })[0];
  }

  /** One result per Lead, in the same order as the input. */
  public static List<LeadEligibilityResult> evaluate(List<Lead> leads) {
    if (leads == null) {
      throw new IllegalArgumentException('A list of Leads is required.');
    }
    List<LeadEligibilityResult> results = new List<LeadEligibilityResult>();
    for (Lead record : leads) {
      if (record == null) {
        throw new IllegalArgumentException(
          'The list of Leads contains a null.'
        );
      }
      results.add(evaluateLead(record));
    }
    return results;
  }

  private static LeadEligibilityResult evaluateLead(Lead record) {
    LeadEligibilityResult result = new LeadEligibilityResult(record.Id);

    String country = LeadDataStandardizer.standardCountry(record.Country);
    if (country == null) {
      addMissing(result, 'Country');
    } else if (!ELIGIBLE_COUNTRIES.contains(country)) {
      addFailed(result, 'R1', 'Not based in the US, Canada or UK');
    }

    if (record.NumberOfEmployees == null) {
      addMissing(result, 'Number of employees');
    } else if (record.NumberOfEmployees < MIN_EMPLOYEES) {
      addFailed(result, 'R2', 'Fewer than ' + MIN_EMPLOYEES + ' employees');
    }

    if (record.AnnualRevenue == null) {
      addMissing(result, 'Annual revenue');
    } else if (record.AnnualRevenue < MIN_ANNUAL_REVENUE) {
      addFailed(
        result,
        'R3',
        'Annual revenue is below ' + inMillions(MIN_ANNUAL_REVENUE)
      );
    }

    if (String.isBlank(record.Industry)) {
      addMissing(result, 'Industry');
    } else if (
      EXCLUDED_INDUSTRIES.contains(record.Industry.trim().toLowerCase())
    ) {
      addFailed(result, 'R4', 'Industry is Government or Education');
    }

    if (String.isBlank(record.Email)) {
      addMissing(result, 'Email');
    }

    result.isEligible =
      result.failedRules.isEmpty() && result.missingDetails.isEmpty();
    result.outcome = result.isEligible
      ? LeadEligibilityResult.ELIGIBLE
      : LeadEligibilityResult.NOT_ELIGIBLE;
    return result;
  }

  private static void addFailed(
    LeadEligibilityResult result,
    String rule,
    String reason
  ) {
    result.failedRules.add(rule);
    result.reasons.add(reason);
  }

  private static void addMissing(LeadEligibilityResult result, String detail) {
    result.missingDetails.add(detail);
    result.reasons.add(detail + ' is missing');
  }

  /** 1000000 -> "1M", 2500000 -> "2.5M". */
  private static String inMillions(Decimal amount) {
    return (amount / 1000000).stripTrailingZeros().toPlainString() + 'M';
  }
}
