import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetrackerpro/core/firebase/collections.dart';
import 'package:expensetrackerpro/core/firebase/entity_store.dart';
import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/features/reminders/domain/reminder.dart';

class ReminderRepository {
  ReminderRepository({
    required DocumentReference<Map<String, dynamic>> userDoc,
    required WriteDispatcher writer,
  }) : store = EntityStore(
         userDoc: userDoc,
         collection: Collections.reminders,
         fromMap: Reminder.fromMap,
         writer: writer,
       );

  final EntityStore<Reminder> store;

  String newId() => store.newId();

  Stream<List<Reminder>> watchAll() => store.watchAll();

  void save(Reminder reminder) => store.set(reminder.id, reminder.toMap());

  void delete(String id) => store.delete(id);

  /// Creates, updates or removes the single reminder owned by an entity.
  void syncEntityReminder(
    ReminderEntityType type,
    String entityId,
    Reminder? reminder,
  ) {
    final id = Reminder.entityReminderId(type, entityId);
    if (reminder == null) {
      store.delete(id);
    } else {
      assert(reminder.id == id, 'Entity reminders must use entityReminderId');
      store.set(id, reminder.toMap());
    }
  }
}
