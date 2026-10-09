@IsTest
private class TriggerHandlerTest {
  private class RecordingHandler extends TriggerHandler {
    public List<String> calls = new List<String>();

    public RecordingHandler(System.TriggerOperation operation) {
      super(operation, new List<SObject>(), new Map<Id, SObject>());
    }

    protected override void beforeInsert(List<SObject> newRecords) {
      calls.add('beforeInsert');
    }

    protected override void beforeUpdate(
      List<SObject> newRecords,
      Map<Id, SObject> oldRecordsById
    ) {
      calls.add('beforeUpdate');
    }

    protected override void beforeDelete(Map<Id, SObject> oldRecordsById) {
      calls.add('beforeDelete');
    }

    protected override void afterInsert(List<SObject> newRecords) {
      calls.add('afterInsert');
    }

    protected override void afterUpdate(
      List<SObject> newRecords,
      Map<Id, SObject> oldRecordsById
    ) {
      calls.add('afterUpdate');
    }

    protected override void afterDelete(Map<Id, SObject> oldRecordsById) {
      calls.add('afterDelete');
    }

    protected override void afterUndelete(List<SObject> newRecords) {
      calls.add('afterUndelete');
    }
  }

  @IsTest
  static void runCallsTheMatchingEvent() {
    Map<System.TriggerOperation, String> expected = new Map<System.TriggerOperation, String>{
      System.TriggerOperation.BEFORE_INSERT => 'beforeInsert',
      System.TriggerOperation.BEFORE_UPDATE => 'beforeUpdate',
      System.TriggerOperation.BEFORE_DELETE => 'beforeDelete',
      System.TriggerOperation.AFTER_INSERT => 'afterInsert',
      System.TriggerOperation.AFTER_UPDATE => 'afterUpdate',
      System.TriggerOperation.AFTER_DELETE => 'afterDelete',
      System.TriggerOperation.AFTER_UNDELETE => 'afterUndelete'
    };

    for (System.TriggerOperation operation : expected.keySet()) {
      RecordingHandler handler = new RecordingHandler(operation);
      handler.run();
      Assert.areEqual(
        new List<String>{ expected.get(operation) },
        handler.calls,
        String.valueOf(operation)
      );
    }
  }

  @IsTest
  static void bypassedHandlerDoesNothing() {
    RecordingHandler handler = new RecordingHandler(
      System.TriggerOperation.BEFORE_INSERT
    );
    String handlerName = handler.getHandlerName();

    TriggerHandler.bypass(handlerName);
    handler.run();
    Assert.isTrue(handler.calls.isEmpty(), 'Bypassed handler should not run');

    TriggerHandler.clearBypass(handlerName);
    handler.run();
    Assert.areEqual(
      1,
      handler.calls.size(),
      'Handler should run after the bypass is cleared'
    );
  }

  @IsTest
  static void runOutsideTriggerDoesNothing() {
    TriggerHandler handler = new TriggerHandler();
    handler.run();
    Assert.isFalse(
      TriggerHandler.isBypassed(handler.getHandlerName()),
      'Nothing should be bypassed'
    );
  }
}
