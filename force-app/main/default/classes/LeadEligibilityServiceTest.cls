@IsTest
private class LeadEligibilityServiceTest {
  @IsTest
  static void leadPassingAllRulesIsEligible() {
    LeadEligibilityResult result = LeadEligibilityService.evaluate(
      TestDataFactory.buildLead()
    );

    Assert.isTrue(result.isEligible);
    Assert.areEqual(LeadEligibilityResult.ELIGIBLE, result.outcome);
    Assert.isTrue(result.failedRules.isEmpty());
    Assert.isTrue(result.missingDetails.isEmpty());
    Assert.isTrue(result.reasons.isEmpty());
  }

  @IsTest
  static void eachFailedRuleMakesLeadNotEligible() {
    Lead outsideRegion = TestDataFactory.buildLead();
    outsideRegion.Country = 'Germany';
    Lead tooSmall = TestDataFactory.buildLead();
    tooSmall.NumberOfEmployees = 10;
    Lead lowRevenue = TestDataFactory.buildLead();
    lowRevenue.AnnualRevenue = 500000;
    Lead government = TestDataFactory.buildLead();
    government.Industry = 'Government';
    Lead education = TestDataFactory.buildLead();
    education.Industry = 'Education';

    List<LeadEligibilityResult> results = LeadEligibilityService.evaluate(
      new List<Lead>{ outsideRegion, tooSmall, lowRevenue, government, education }
    );

    assertFailedOnly(results[0], 'R1', 'Not based in the US, Canada or UK');
    assertFailedOnly(results[1], 'R2', 'Fewer than 50 employees');
    assertFailedOnly(results[2], 'R3', 'Annual revenue is below 1M');
    assertFailedOnly(results[3], 'R4', 'Industry is Government or Education');
    assertFailedOnly(results[4], 'R4', 'Industry is Government or Education');
  }

  @IsTest
  static void listsEveryFailedRuleNotJustTheFirst() {
    Lead record = TestDataFactory.buildLead();
    record.Country = 'Germany';
    record.NumberOfEmployees = 10;
    record.Industry = 'Education';

    LeadEligibilityResult result = LeadEligibilityService.evaluate(record);

    Assert.isFalse(result.isEligible);
    Assert.areEqual(
      new List<String>{ 'R1', 'R2', 'R4' },
      result.failedRules
    );
    Assert.areEqual(3, result.reasons.size());
  }

  @IsTest
  static void eachMissingDetailMakesLeadNotEligible() {
    Lead noCountry = TestDataFactory.buildLead();
    noCountry.Country = '  ';
    Lead noEmployees = TestDataFactory.buildLead();
    noEmployees.NumberOfEmployees = null;
    Lead noRevenue = TestDataFactory.buildLead();
    noRevenue.AnnualRevenue = null;
    Lead noIndustry = TestDataFactory.buildLead();
    noIndustry.Industry = null;
    Lead noEmail = TestDataFactory.buildLead();
    noEmail.Email = null;

    List<LeadEligibilityResult> results = LeadEligibilityService.evaluate(
      new List<Lead>{ noCountry, noEmployees, noRevenue, noIndustry, noEmail }
    );

    assertMissingOnly(results[0], 'Country');
    assertMissingOnly(results[1], 'Number of employees');
    assertMissingOnly(results[2], 'Annual revenue');
    assertMissingOnly(results[3], 'Industry');
    assertMissingOnly(results[4], 'Email');
  }

  @IsTest
  static void listsFailedRulesAndMissingDetailsTogether() {
    Lead record = TestDataFactory.buildLead();
    record.Company = 'Pine County Services';
    record.Industry = 'Government';
    record.Email = null;

    LeadEligibilityResult result = LeadEligibilityService.evaluate(record);

    Assert.isFalse(result.isEligible);
    Assert.areEqual(new List<String>{ 'R4' }, result.failedRules);
    Assert.areEqual(new List<String>{ 'Email' }, result.missingDetails);
    Assert.areEqual(
      new List<String>{
        'Industry is Government or Education',
        'Email is missing'
      },
      result.reasons
    );
  }

  @IsTest
  static void boundaryValuesPassAndJustBelowFail() {
    Lead atLimits = TestDataFactory.buildLead();
    atLimits.NumberOfEmployees = 50;
    atLimits.AnnualRevenue = 1000000;
    Lead justBelow = TestDataFactory.buildLead();
    justBelow.NumberOfEmployees = 49;
    justBelow.AnnualRevenue = 999999;

    List<LeadEligibilityResult> results = LeadEligibilityService.evaluate(
      new List<Lead>{ atLimits, justBelow }
    );

    Assert.isTrue(results[0].isEligible);
    Assert.areEqual(new List<String>{ 'R2', 'R3' }, results[1].failedRules);
  }

  @IsTest
  static void commonCountrySpellingsMeetRuleOne() {
    List<String> spellings = new List<String>{
      'USA',
      'US',
      'us',
      ' United States ',
      'Canada',
      'U.K.',
      'United Kingdom'
    };
    List<Lead> leads = new List<Lead>();
    for (String spelling : spellings) {
      Lead record = TestDataFactory.buildLead();
      record.Country = spelling;
      leads.add(record);
    }

    List<LeadEligibilityResult> results = LeadEligibilityService.evaluate(
      leads
    );

    for (Integer i = 0; i < spellings.size(); i++) {
      Assert.isTrue(
        results[i].isEligible,
        'Expected "' + spellings[i] + '" to meet R1'
      );
    }
  }

  @IsTest
  static void sameLeadGivesSameResultForDifferentUsers() {
    Lead record = TestDataFactory.buildLead();
    record.NumberOfEmployees = 10;
    User rep = TestDataFactory.buildUser('Standard User');

    LeadEligibilityResult asAdmin = LeadEligibilityService.evaluate(record);
    LeadEligibilityResult asRep;
    System.runAs(rep) {
      asRep = LeadEligibilityService.evaluate(record);
    }

    Assert.areEqual(asAdmin.outcome, asRep.outcome);
    Assert.areEqual(asAdmin.failedRules, asRep.failedRules);
    Assert.areEqual(asAdmin.reasons, asRep.reasons);
  }

  @IsTest
  static void bulkLeadsGetExpectedResultsInInputOrder() {
    List<Lead> leads = TestDataFactory.buildLeads(200);
    for (Integer i = 0; i < leads.size(); i++) {
      if (Math.mod(i, 2) == 1) {
        leads[i].NumberOfEmployees = 10;
      }
    }
    insert leads;
    Map<Id, Lead> saved = new Map<Id, Lead>(
      LeadSelector.selectByIds(new Map<Id, Lead>(leads).keySet())
    );
    List<Lead> ordered = new List<Lead>();
    for (Lead record : leads) {
      ordered.add(saved.get(record.Id));
    }

    Test.startTest();
    List<LeadEligibilityResult> results = LeadEligibilityService.evaluate(
      ordered
    );
    Test.stopTest();

    Assert.areEqual(200, results.size());
    for (Integer i = 0; i < results.size(); i++) {
      Assert.areEqual(leads[i].Id, results[i].leadId);
      Assert.areEqual(Math.mod(i, 2) == 0, results[i].isEligible);
    }
  }

  private static void assertFailedOnly(
    LeadEligibilityResult result,
    String rule,
    String reason
  ) {
    Assert.isFalse(result.isEligible);
    Assert.areEqual(LeadEligibilityResult.NOT_ELIGIBLE, result.outcome);
    Assert.areEqual(new List<String>{ rule }, result.failedRules);
    Assert.isTrue(result.missingDetails.isEmpty());
    Assert.areEqual(new List<String>{ reason }, result.reasons);
  }

  private static void assertMissingOnly(
    LeadEligibilityResult result,
    String detail
  ) {
    Assert.isFalse(result.isEligible);
    Assert.isTrue(result.failedRules.isEmpty());
    Assert.areEqual(new List<String>{ detail }, result.missingDetails);
    Assert.areEqual(new List<String>{ detail + ' is missing' }, result.reasons);
  }
}
