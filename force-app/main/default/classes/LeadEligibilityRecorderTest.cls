@IsTest
private class LeadEligibilityRecorderTest {
  private static final List<SObjectField> OUTCOME_FIELDS = new List<SObjectField>{
    Lead.Eligibility_Result__c,
    Lead.Eligibility_Reasons__c,
    Lead.Eligibility_Checked_By__c,
    Lead.Eligibility_Checked_On__c
  };

  @IsTest
  static void checkSavesResultReasonsCheckedByAndCheckedOn() {
    Lead record = TestDataFactory.buildLead();
    record.Industry = 'Government';
    record.Email = null;
    insert record;
    Datetime before = System.now();

    LeadEligibilityRecorder.record(evaluate(record.Id));

    Lead saved = savedOutcome(record.Id);
    Assert.areEqual('Not eligible', saved.Eligibility_Result__c);
    Assert.areEqual(
      'Industry is Government or Education;Email is missing',
      saved.Eligibility_Reasons__c
    );
    Assert.areEqual(UserInfo.getUserId(), saved.Eligibility_Checked_By__c);
    Assert.isTrue(saved.Eligibility_Checked_On__c >= before.addSeconds(-1));
    Assert.isTrue(saved.Eligibility_Checked_On__c <= System.now());
  }

  @IsTest
  static void eligibleLeadSavesEligibleAndNoReasons() {
    Lead record = TestDataFactory.createLeads(1)[0];

    LeadEligibilityRecorder.record(evaluate(record.Id));

    Lead saved = savedOutcome(record.Id);
    Assert.areEqual('Eligible', saved.Eligibility_Result__c);
    Assert.isNull(saved.Eligibility_Reasons__c);
  }

  @IsTest
  static void newCheckReplacesSavedOutcome() {
    User rep = insertSalesRep();
    Lead record = TestDataFactory.buildLead();
    record.NumberOfEmployees = 10;
    insert record;
    LeadEligibilityRecorder.record(evaluate(record.Id));

    record.NumberOfEmployees = 60;
    update record;
    System.runAs(rep) {
      LeadEligibilityRecorder.record(evaluate(record.Id));
    }

    Lead saved = savedOutcome(record.Id);
    Assert.areEqual('Eligible', saved.Eligibility_Result__c);
    Assert.isNull(saved.Eligibility_Reasons__c);
    Assert.areEqual(rep.Id, saved.Eligibility_Checked_By__c);
  }

  @IsTest
  static void allFourFieldsTrackHistory() {
    List<FieldDefinition> fields = [
      SELECT QualifiedApiName, IsFieldHistoryTracked
      FROM FieldDefinition
      WHERE
        EntityDefinition.QualifiedApiName = 'Lead'
        AND QualifiedApiName IN (
          'Eligibility_Result__c',
          'Eligibility_Reasons__c',
          'Eligibility_Checked_By__c',
          'Eligibility_Checked_On__c'
        )
    ];

    Assert.areEqual(4, fields.size());
    for (FieldDefinition field : fields) {
      Assert.isTrue(field.IsFieldHistoryTracked, field.QualifiedApiName);
    }
  }

  @IsTest
  static void fieldsSupportManagerReports() {
    for (SObjectField field : OUTCOME_FIELDS) {
      DescribeFieldResult describe = field.getDescribe();
      Assert.isTrue(describe.isFilterable(), describe.getName());
    }
    Assert.isTrue(Lead.Eligibility_Result__c.getDescribe().isGroupable());
    Assert.isTrue(Lead.Eligibility_Checked_By__c.getDescribe().isGroupable());
    Assert.isTrue(Lead.Eligibility_Checked_On__c.getDescribe().isSortable());
  }

  @IsTest
  static void repCanReadButNotEditTheOutcome() {
    User rep = insertSalesRep();
    Lead record = TestDataFactory.createLeads(1)[0];

    System.runAs(rep) {
      for (SObjectField field : OUTCOME_FIELDS) {
        DescribeFieldResult describe = field.getDescribe();
        Assert.isTrue(describe.isAccessible(), describe.getName());
        Assert.isFalse(describe.isUpdateable(), describe.getName());
      }
      try {
        Database.update(
          new Lead(Id = record.Id, Eligibility_Result__c = 'Eligible'),
          AccessLevel.USER_MODE
        );
        Assert.fail('A rep must not be able to set the result by hand.');
      } catch (Exception e) {
        Assert.isNull(savedOutcome(record.Id).Eligibility_Result__c);
      }
    }
  }

  @IsTest
  static void repCanRunACheckAndTheOutcomeIsSaved() {
    User rep = insertSalesRep();
    Lead record = TestDataFactory.createLeads(1)[0];

    System.runAs(rep) {
      LeadEligibilityController.checkEligibility(record.Id);
    }

    Lead saved = savedOutcome(record.Id);
    Assert.areEqual('Eligible', saved.Eligibility_Result__c);
    Assert.areEqual(rep.Id, saved.Eligibility_Checked_By__c);
  }

  @IsTest
  static void changingLeadDetailsLeavesSavedOutcomeUnchanged() {
    Lead record = TestDataFactory.createLeads(1)[0];
    LeadEligibilityRecorder.record(evaluate(record.Id));
    Lead before = savedOutcome(record.Id);

    record.NumberOfEmployees = 10;
    record.Industry = 'Education';
    update record;

    Lead after = savedOutcome(record.Id);
    Assert.areEqual('Eligible', after.Eligibility_Result__c);
    Assert.isNull(after.Eligibility_Reasons__c);
    Assert.areEqual(
      before.Eligibility_Checked_On__c,
      after.Eligibility_Checked_On__c
    );
  }

  @IsTest
  static void everyReasonFromTheRulesIsAValidReasonValue() {
    Lead failsEveryRule = TestDataFactory.buildLead();
    failsEveryRule.Country = 'Germany';
    failsEveryRule.NumberOfEmployees = 10;
    failsEveryRule.AnnualRevenue = 500000;
    failsEveryRule.Industry = 'Education';
    Lead missingEverything = new Lead(LastName = 'Blank', Company = 'Blank');

    Set<String> reasons = new Set<String>();
    Set<String> outcomes = new Set<String>();
    for (
      LeadEligibilityResult result : LeadEligibilityService.evaluate(
        new List<Lead>{
          failsEveryRule,
          missingEverything,
          TestDataFactory.buildLead()
        }
      )
    ) {
      reasons.addAll(result.reasons);
      outcomes.add(result.outcome);
    }

    Assert.areEqual(9, reasons.size());
    Assert.isTrue(
      picklistValues(Lead.Eligibility_Reasons__c).containsAll(reasons),
      'Every reason the rules can give must be a Reasons value: ' + reasons
    );
    Assert.areEqual(outcomes, picklistValues(Lead.Eligibility_Result__c));
  }

  @IsTest
  static void recordsTwoHundredResultsWithOneSave() {
    List<Lead> leads = TestDataFactory.buildLeads(200);
    for (Integer i = 0; i < leads.size(); i += 2) {
      leads[i].NumberOfEmployees = 10;
    }
    insert leads;
    List<LeadEligibilityResult> results = LeadEligibilityService.evaluate(
      LeadSelector.selectByIds(new Map<Id, Lead>(leads).keySet())
    );

    Integer dmlBefore = Limits.getDmlStatements();
    LeadEligibilityRecorder.record(results);
    Assert.areEqual(1, Limits.getDmlStatements() - dmlBefore);

    Integer notEligible = 0;
    for (Lead saved : [
      SELECT Eligibility_Result__c
      FROM Lead
      WHERE Id IN :leads AND Eligibility_Result__c != NULL
    ]) {
      if (saved.Eligibility_Result__c == 'Not eligible') {
        notEligible++;
      }
    }
    Assert.areEqual(100, notEligible);
    Assert.areEqual(
      200,
      [
        SELECT COUNT()
        FROM Lead
        WHERE Id IN :leads AND Eligibility_Result__c != NULL
      ]
    );
  }

  @IsTest
  static void nullInputThrowsAClearError() {
    try {
      LeadEligibilityRecorder.record(null);
      Assert.fail('Expected an IllegalArgumentException.');
    } catch (IllegalArgumentException e) {
      Assert.areEqual('A list of results is required.', e.getMessage());
    }
  }

  @IsTest
  static void emptyInputSavesNothing() {
    Integer dmlBefore = Limits.getDmlStatements();
    LeadEligibilityRecorder.record(new List<LeadEligibilityResult>());
    Assert.areEqual(0, Limits.getDmlStatements() - dmlBefore);
  }

  private static List<LeadEligibilityResult> evaluate(Id leadId) {
    return LeadEligibilityService.evaluate(
      LeadSelector.selectByIds(new Set<Id>{ leadId })
    );
  }

  private static Lead savedOutcome(Id leadId) {
    return [
      SELECT
        Eligibility_Result__c,
        Eligibility_Reasons__c,
        Eligibility_Checked_By__c,
        Eligibility_Checked_On__c
      FROM Lead
      WHERE Id = :leadId
    ];
  }

  private static Set<String> picklistValues(SObjectField field) {
    Set<String> values = new Set<String>();
    for (PicklistEntry entry : field.getDescribe().getPicklistValues()) {
      values.add(entry.getValue());
    }
    return values;
  }

  /** A Standard User with Sales_Rep_Base. Setup DML runs as the current user. */
  private static User insertSalesRep() {
    User rep = TestDataFactory.buildUser('Standard User');
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert rep;
      insert new PermissionSetAssignment(
        AssigneeId = rep.Id,
        PermissionSetId = [
          SELECT Id
          FROM PermissionSet
          WHERE Name = 'Sales_Rep_Base'
        ]
        .Id
      );
    }
    return rep;
  }
}
