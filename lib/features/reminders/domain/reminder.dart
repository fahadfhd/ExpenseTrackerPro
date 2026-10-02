import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:expensetrackerpro/core/firebase/firestore_codec.dart';
import 'package:expensetrackerpro/core/utils/recurrence.dart';

enum ReminderType {
  loanEmi,
  creditCardPayment,
  borrowed,
  lent,
  gym,
  meeting,
  insurance,
  subscription,
  bill,
  custom,
}

/// What a reminder belongs to. Entity reminders are created and kept in
/// sync by their owning module and use [Reminder.entityReminderId].
enum ReminderEntityType { none, loan, creditCard, borrowLend }

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.hour,
    required this.minute,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.recurrence = Recurrence.none,
    this.entityType = ReminderEntityType.none,
    this.entityId,
    this.offsetsMinutes = const [0],
    this.enabled = true,
  });

  /// One reminder per entity, so re-saving a loan or card updates its
  /// reminder instead of creating another.
  static String entityReminderId(ReminderEntityType type, String entityId) =>
      '${type.name}_$entityId';

  final String id;
  final String title;
  final String description;
  final ReminderType type;

  /// Calendar date of the first occurrence (time part ignored).
  final DateTime date;

  /// Local wall-clock time. Stored separately from the date so a reminder
  /// at 19:00 stays at 19:00 when the device changes time zone.
  final int hour;
  final int minute;
  final Recurrence recurrence;
  final ReminderEntityType entityType;
  final String? entityId;

  /// Minutes before each occurrence to notify; 0 = at the scheduled time.
  final List<int> offsetsMinutes;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// First occurrence as a local date-time.
  DateTime get anchor => DateTime(date.year, date.month, date.day, hour, minute);

  bool get isEntityReminder => entityType != ReminderEntityType.none;

  DateTime? nextOccurrence(DateTime now) => recurrence.nextFrom(anchor, now);

  Reminder copyWith({
    String? title,
    String? description,
    ReminderType? type,
    DateTime? date,
    int? hour,
    int? minute,
    Recurrence? recurrence,
    List<int>? offsetsMinutes,
    bool? enabled,
    DateTime? updatedAt,
  }) => Reminder(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    date: date ?? this.date,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    recurrence: recurrence ?? this.recurrence,
    entityType: entityType,
    entityId: entityId,
    offsetsMinutes: offsetsMinutes ?? this.offsetsMinutes,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'type': type.name,
    'scheduledDate': _dateKey(date),
    'scheduledTime':
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    'recurrence': recurrence.toMap(),
    'entityType': entityType.name,
    'entityId': entityId,
    'offsetsMinutes': offsetsMinutes,
    'enabled': enabled,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory Reminder.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    final date = DateTime.tryParse(Codec.string(map['scheduledDate'])) ?? now;
    final time = Codec.string(map['scheduledTime'], '09:00').split(':');
    final offsets =
        Codec.ints(map['offsetsMinutes']).where((m) => m >= 0).toSet().toList()
          ..sort();
    return Reminder(
      id: id,
      title: Codec.string(map['title']),
      description: Codec.string(map['description']),
      type: Codec.enumByName(
        ReminderType.values,
        map['type'],
        ReminderType.custom,
      ),
      date: DateTime(date.year, date.month, date.day),
      hour: (int.tryParse(time.first) ?? 9).clamp(0, 23),
      minute: (int.tryParse(time.length > 1 ? time[1] : '') ?? 0).clamp(0, 59),
      recurrence: Recurrence.fromMap(map['recurrence']),
      entityType: Codec.enumByName(
        ReminderEntityType.values,
        map['entityType'],
        ReminderEntityType.none,
      ),
      entityId: Codec.stringOrNull(map['entityId']),
      offsetsMinutes: offsets.isEmpty ? const [0] : offsets,
      enabled: Codec.boolean(map['enabled'], true),
      createdAt: Codec.date(map['createdAt']) ?? now,
      updatedAt: Codec.date(map['updatedAt']) ?? now,
    );
  }
}
