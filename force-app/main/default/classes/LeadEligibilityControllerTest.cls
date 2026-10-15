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
  static void userWithoutSalesRepBaseGetsClearMessage() {
    Lead record = TestDataFactory.createLeads(1)[0];
    User noAccess = insertUser('Minimum Access - Salesforce', false);

    System.runAs(noAccess) {
      assertClearMessage(
        record.Id,
        LeadEligibilityController.NO_ACCESS_MESSAGE
      );
    }
  }

  /** Minimum Access grants no Lead access, so the rep's access comes only from Sales_Rep_Base. */
  @IsTest
  static void salesRepBasePermissionSetAloneIsEnough() {
    User rep = insertUser('Minimum Access - Salesforce', true);
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

  @IsTest
  static void checkSavesTheOutcomeOnTheLead() {
    Lead record = TestDataFactory.buildLead();
    record.Email = null;
    insert record;

    LeadEligibilityResult result = LeadEligibilityController.checkEligibility(
      record.Id
    );

    Lead saved = [
      SELECT
        Eligibility_Result__c,
        Eligibility_Reasons__c,
        Eligibility_Checked_By__c
      FROM Lead
      WHERE Id = :record.Id
    ];
    Assert.areEqual(result.outcome, saved.Eligibility_Result__c);
    Assert.areEqual('Email is missing', saved.Eligibility_Reasons__c);
    Assert.areEqual(UserInfo.getUserId(), saved.Eligibility_Checked_By__c);
  }

  /** The user can read leads and every rule field, but can't edit leads, so the save fails. */
  @IsTest
  static void failedSaveGetsClearMessage() {
    Lead record = TestDataFactory.createLeads(1)[0];
    User readOnly = insertLeadReadOnlyUser();

    System.runAs(readOnly) {
      assertClearMessage(
        record.Id,
        LeadEligibilityController.NOT_SAVED_MESSAGE
      );
    }
    Assert.isNull(
      [SELECT Eligibility_Result__c FROM Lead WHERE Id = :record.Id]
      .Eligibility_Result__c
    );
  }

  private static void assertClearMessage(Id leadId, String expectedMessage) {
    try {
      LeadEligibilityController.checkEligibility(leadId);
      Assert.fail('Expected an AuraHandledException.');
    } catch (AuraHandledException e) {
      Assert.areEqual(expectedMessage, e.getMessage());
    }
  }

  /** Minimum Access user with a test permission set: Lead read and the rule fields, no edit. */
  private static User insertLeadReadOnlyUser() {
    User newUser = TestDataFactory.buildUser('Minimum Access - Salesforce');
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert newUser;
      PermissionSet leadRead = new PermissionSet(
        Name = 'BR014_Test_Lead_Read_Only',
        Label = 'BR014 Test Lead Read Only'
      );
      insert leadRead;
      insert new ObjectPermissions(
        ParentId = leadRead.Id,
        SobjectType = 'Lead',
        PermissionsRead = true
      );
      List<FieldPermissions> fields = new List<FieldPermissions>();
      for (
        String field : new List<String>{
          'Lead.Address',
          'Lead.NumberOfEmployees',
          'Lead.AnnualRevenue',
          'Lead.Industry',
          'Lead.Email',
          'Lead.Rating',
          'Lead.LeadSource'
        }
      ) {
        fields.add(
          new FieldPermissions(
            ParentId = leadRead.Id,
            SobjectType = 'Lead',
            Field = field,
            PermissionsRead = true
          )
        );
      }
      insert fields;
      insert new PermissionSetAssignment(
        AssigneeId = newUser.Id,
        PermissionSetId = leadRead.Id
      );
    }
    return newUser;
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
