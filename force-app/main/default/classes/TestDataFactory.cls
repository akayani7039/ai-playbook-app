/**
 * Shared test data. Build records here, not inline in each test class.
 */
@IsTest
public class TestDataFactory {
  private static Integer uniqueCounter = 0;

  /** An unsaved Lead with complete, realistic data. Override fields in the test. */
  public static Lead buildLead() {
    uniqueCounter++;
    return new Lead(
      FirstName = 'Test',
      LastName = 'Lead ' + uniqueCounter,
      Company = 'Test Company ' + uniqueCounter,
      Email = 'test.lead' + uniqueCounter + '@example.com',
      Country = LeadDataStandardizer.UNITED_STATES,
      NumberOfEmployees = 100,
      AnnualRevenue = 2000000,
      Industry = 'Technology',
      Status = 'Open - Not Contacted'
    );
  }

  public static List<Lead> buildLeads(Integer count) {
    List<Lead> leads = new List<Lead>();
    for (Integer i = 0; i < count; i++) {
      leads.add(buildLead());
    }
    return leads;
  }

  public static List<Lead> createLeads(Integer count) {
    List<Lead> leads = buildLeads(count);
    insert leads;
    return leads;
  }

  /** An unsaved user with the given profile. Use with System.runAs for access tests. */
  public static User buildUser(String profileName) {
    uniqueCounter++;
    Profile userProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = :profileName
      LIMIT 1
    ];
    String uniqueName =
      'playbook' +
      uniqueCounter +
      '.' +
      Datetime.now().getTime();
    return new User(
      ProfileId = userProfile.Id,
      LastName = 'Test User',
      Alias = 'tuser' + Math.mod(uniqueCounter, 100),
      Email = uniqueName + '@example.com',
      Username = uniqueName + '@example.com.test',
      TimeZoneSidKey = 'America/New_York',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
  }
}
