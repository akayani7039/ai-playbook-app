@IsTest
private class LeadEligibilityControllerTest {
  @IsTest
  static void eligibleLeadReturnsEligibleWithNoReasons() {
    Lead record = TestDataFactory.createLeads(1)[0];

    LeadEligibilityResult result = LeadEligibilityController.checkEligibility(
      record.Id
    );

    Assert.areEqual(record.Id, result.leadId);
    Assert.areEqual(LeadEligibilityResult.ELIGIBLE, result.outcome);
    Assert.isTrue(result.reasons.isEmpty());
  }

  @IsTest
  static void notEligibleLeadListsEveryReason() {
    Lead record = TestDataFactory.buildLead();
    record.Industry = 'Government';
    record.Email = null;
    insert record;

    LeadEligibilityResult result = LeadEligibilityController.checkEligibility(
      record.Id
    );

    Assert.areEqual(LeadEligibilityResult.NOT_ELIGIBLE, result.outcome);
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
  static void resultMatchesTheS1Decision() {
    Lead record = TestDataFactory.buildLead();
    record.Country = 'USA';
    record.NumberOfEmployees = 49;
    insert record;

    LeadEligibilityResult fromController = LeadEligibilityController.checkEligibility(
      record.Id
    );
    LeadEligibilityResult fromService = LeadEligibilityService.evaluate(
      LeadSelector.selectByIds(new Set<Id>{ record.Id })[0]
    );

    Assert.areEqual(fromService.outcome, fromController.outcome);
    Assert.areEqual(fromService.failedRules, fromController.failedRules);
    Assert.areEqual(fromService.missingDetails, fromController.missingDetails);
    Assert.areEqual(fromService.reasons, fromController.reasons);
  }

  @IsTest
  static void checkAgainUsesLatestSavedValues() {
    Lead record = TestDataFactory.buildLead();
    record.NumberOfEmployees = 10;
    insert record;
    Assert.areEqual(
      LeadEligibilityResult.NOT_ELIGIBLE,
      LeadEligibilityController.checkEligibility(record.Id).outcome
    );

    record.NumberOfEmployees = 60;
    update record;

    Assert.areEqual(
      LeadEligibilityResult.ELIGIBLE,
      LeadEligibilityController.checkEligibility(record.Id).outcome
    );
  }

  @IsTest
  static void blankLeadIdGetsClearMessage() {
    assertClearMessage(null, LeadEligibilityController.NO_LEAD_MESSAGE);
  }

  @IsTest
  static void deletedLeadGetsClearMessage() {
    Lead record = TestDataFactory.createLeads(1)[0];
    delete record;

    assertClearMessage(
      record.Id,
      LeadEligibilityController.NOT_AVAILABLE_MESSAGE
    );
  }

  @IsTest
  static void userWithoutLeadAccessGetsClearMessage() {
    Lead record = TestDataFactory.createLeads(1)[0];
    User noAccess = insertUser('Minimum Access - Salesforce', false);

    System.runAs(noAccess) {
      assertClearMessage(
        record.Id,
        LeadEligibilityController.NO_ACCESS_MESSAGE
      );
    }
  }

  @IsTest
  static void salesRepWithBasePermissionSetGetsSameResultAsAdmin() {
    User rep = insertUser('Standard User', true);
    Lead record = TestDataFactory.buildLead();
    record.OwnerId = rep.Id;
    record.AnnualRevenue = 999999;
    insert record;

    LeadEligibilityResult asAdmin = LeadEligibilityController.checkEligibility(
      record.Id
    );
    LeadEligibilityResult asRep;
    System.runAs(rep) {
      asRep = LeadEligibilityController.checkEligibility(record.Id);
    }

    Assert.areEqual(LeadEligibilityResult.NOT_ELIGIBLE, asRep.outcome);
    Assert.areEqual(asAdmin.outcome, asRep.outcome);
    Assert.areEqual(asAdmin.reasons, asRep.reasons);
  }

  private static void assertClearMessage(Id leadId, String expectedMessage) {
    try {
      LeadEligibilityController.checkEligibility(leadId);
      Assert.fail('Expected an AuraHandledException.');
    } catch (AuraHandledException e) {
      Assert.areEqual(expectedMessage, e.getMessage());
    }
  }

  /** Setup DML runs as the current user so it doesn't mix with Lead DML. */
  private static User insertUser(String profileName, Boolean salesRepBase) {
    User newUser = TestDataFactory.buildUser(profileName);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert newUser;
      if (salesRepBase) {
        insert new PermissionSetAssignment(
          AssigneeId = newUser.Id,
          PermissionSetId = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'Sales_Rep_Base'
          ]
          .Id
        );
      }
    }
    return newUser;
  }
}
