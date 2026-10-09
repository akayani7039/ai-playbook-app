/**
 * All Lead queries live here.
 * Team rule: every query runs WITH USER_MODE so CRUD, FLS and sharing are enforced.
 * Code Analyzer treats a query without it as a Sev 1 finding and blocks the merge.
 */
public inherited sharing class LeadSelector {
  public static List<Lead> selectByIds(Set<Id> leadIds) {
    return [
      SELECT
        Id,
        Company,
        Country,
        NumberOfEmployees,
        AnnualRevenue,
        Industry,
        Email,
        Status,
        Rating,
        LeadSource
      FROM Lead
      WHERE Id IN :leadIds
      WITH USER_MODE
    ];
  }
}
