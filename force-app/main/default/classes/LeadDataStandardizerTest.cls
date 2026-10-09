@IsTest
private class LeadDataStandardizerTest {
  @IsTest
  static void mapsKnownCountryAliases() {
    Assert.areEqual(
      LeadDataStandardizer.UNITED_STATES,
      LeadDataStandardizer.standardCountry(' USA ')
    );
    Assert.areEqual(
      LeadDataStandardizer.UNITED_STATES,
      LeadDataStandardizer.standardCountry('u.s.')
    );
    Assert.areEqual(
      LeadDataStandardizer.CANADA,
      LeadDataStandardizer.standardCountry('CA')
    );
    Assert.areEqual(
      LeadDataStandardizer.UNITED_KINGDOM,
      LeadDataStandardizer.standardCountry('Great Britain')
    );
  }

  @IsTest
  static void keepsUnknownCountriesTrimmed() {
    Assert.areEqual(
      'Germany',
      LeadDataStandardizer.standardCountry('  Germany ')
    );
  }

  @IsTest
  static void blankCountryBecomesNull() {
    Assert.isNull(LeadDataStandardizer.standardCountry('   '));
    Assert.isNull(LeadDataStandardizer.standardCountry(null));
  }

  @IsTest
  static void standardizesLeadsOnInsertAndUpdate() {
    Lead record = TestDataFactory.buildLead();
    record.Company = '  Acme Robotics  ';
    record.Country = 'usa';

    Test.startTest();
    insert record;
    Lead inserted = [SELECT Company, Country FROM Lead WHERE Id = :record.Id];
    record.Country = 'uk';
    update record;
    Test.stopTest();

    Lead updated = [SELECT Country FROM Lead WHERE Id = :record.Id];
    Assert.areEqual('Acme Robotics', inserted.Company);
    Assert.areEqual(LeadDataStandardizer.UNITED_STATES, inserted.Country);
    Assert.areEqual(LeadDataStandardizer.UNITED_KINGDOM, updated.Country);
  }

  @IsTest
  static void handlesBulkInsert() {
    List<Lead> leads = TestDataFactory.buildLeads(200);
    for (Lead record : leads) {
      record.Country = 'Canada ';
    }

    Test.startTest();
    insert leads;
    Test.stopTest();

    Assert.areEqual(
      200,
      [SELECT COUNT() FROM Lead WHERE Country = :LeadDataStandardizer.CANADA]
    );
  }

  @IsTest
  static void bypassSkipsStandardization() {
    Lead record = TestDataFactory.buildLead();
    record.Country = 'usa';

    TriggerHandler.bypass('LeadTriggerHandler');
    insert record;
    TriggerHandler.clearBypass('LeadTriggerHandler');

    Assert.areEqual(
      'usa',
      [SELECT Country FROM Lead WHERE Id = :record.Id].Country
    );
  }
}
