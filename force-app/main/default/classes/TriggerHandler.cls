/**
 * Base class for trigger handlers.
 * Pattern: one trigger per object. The trigger only calls new XxxTriggerHandler().run().
 * Subclasses override just the events they need. Keep logic in service classes, not here.
 */
public virtual inherited sharing class TriggerHandler {
  private static final Set<String> BYPASSED_HANDLERS = new Set<String>();

  private final System.TriggerOperation operation;
  private final List<SObject> newRecords;
  private final Map<Id, SObject> oldRecordsById;

  public TriggerHandler() {
    this(Trigger.operationType, Trigger.new, Trigger.oldMap);
  }

  public TriggerHandler(
    System.TriggerOperation operation,
    List<SObject> newRecords,
    Map<Id, SObject> oldRecordsById
  ) {
    this.operation = operation;
    this.newRecords = newRecords;
    this.oldRecordsById = oldRecordsById;
  }

  public void run() {
    if (operation == null || isBypassed(getHandlerName())) {
      return;
    }
    switch on operation {
      when BEFORE_INSERT {
        beforeInsert(newRecords);
      }
      when BEFORE_UPDATE {
        beforeUpdate(newRecords, oldRecordsById);
      }
      when BEFORE_DELETE {
        beforeDelete(oldRecordsById);
      }
      when AFTER_INSERT {
        afterInsert(newRecords);
      }
      when AFTER_UPDATE {
        afterUpdate(newRecords, oldRecordsById);
      }
      when AFTER_DELETE {
        afterDelete(oldRecordsById);
      }
      when AFTER_UNDELETE {
        afterUndelete(newRecords);
      }
    }
  }

  /** Skip a handler, e.g. during data loads. Always clear the bypass afterwards. */
  public static void bypass(String handlerName) {
    BYPASSED_HANDLERS.add(handlerName);
  }

  public static void clearBypass(String handlerName) {
    BYPASSED_HANDLERS.remove(handlerName);
  }

  public static Boolean isBypassed(String handlerName) {
    return BYPASSED_HANDLERS.contains(handlerName);
  }

  @TestVisible
  private String getHandlerName() {
    return String.valueOf(this).substringBefore(':');
  }

  protected virtual void beforeInsert(List<SObject> newRecords) {
  }

  protected virtual void beforeUpdate(
    List<SObject> newRecords,
    Map<Id, SObject> oldRecordsById
  ) {
  }

  protected virtual void beforeDelete(Map<Id, SObject> oldRecordsById) {
  }

  protected virtual void afterInsert(List<SObject> newRecords) {
  }

  protected virtual void afterUpdate(
    List<SObject> newRecords,
    Map<Id, SObject> oldRecordsById
  ) {
  }

  protected virtual void afterDelete(Map<Id, SObject> oldRecordsById) {
  }

  protected virtual void afterUndelete(List<SObject> newRecords) {
  }
}
