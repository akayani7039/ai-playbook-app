@IsTest
private class LeadSelectorTest {
  @IsTest
  static void returnsRequestedLeads() {
    List<Lead> leads = TestDataFactory.createLeads(3);
    Set<Id> leadIds = new Map<Id, Lead>(leads).keySet();

    Test.startTest();
    List<Lead> results = LeadSelector.selectByIds(leadIds);
    Test.stopTest();

    Assert.areEqual(3, results.size());
  }

  @IsTest
  static void enforcesUserAccess() {
    List<Lead> leads = TestDataFactory.createLeads(1);
    User noAccessUser = TestDataFactory.buildUser(
      'Minimum Access - Salesforce'
    );
    Boolean blocked = false;

    System.runAs(noAccessUser) {
      try {
        LeadSelector.selectByIds(new Set<Id>{ leads[0].Id });
      } catch (QueryException e) {
        blocked = true;
      }
    }

    Assert.isTrue(
      blocked,
      'A user without Lead access must not be able to query Leads'
    );
  }
}
