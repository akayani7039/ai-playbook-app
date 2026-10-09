/**
 * Tests the Lead_Default_Rating record-triggered flow.
 * Flows are tested through DML, the same way as triggers.
 */
@IsTest
private class LeadDefaultRatingFlowTest {
  @IsTest
  static void webLeadWithoutRatingIsWarm() {
    Lead record = TestDataFactory.buildLead();
    record.LeadSource = 'Web';

    Test.startTest();
    insert record;
    Test.stopTest();

    Assert.areEqual(
      'Warm',
      [SELECT Rating FROM Lead WHERE Id = :record.Id].Rating
    );
  }

  @IsTest
  static void existingRatingIsKept() {
    Lead record = TestDataFactory.buildLead();
    record.LeadSource = 'Web';
    record.Rating = 'Hot';

    Test.startTest();
    insert record;
    Test.stopTest();

    Assert.areEqual(
      'Hot',
      [SELECT Rating FROM Lead WHERE Id = :record.Id].Rating
    );
  }

  @IsTest
  static void otherSourcesAreNotRated() {
    Lead record = TestDataFactory.buildLead();
    record.LeadSource = 'Phone Inquiry';

    Test.startTest();
    insert record;
    Test.stopTest();

    Assert.isNull([SELECT Rating FROM Lead WHERE Id = :record.Id].Rating);
  }
}
