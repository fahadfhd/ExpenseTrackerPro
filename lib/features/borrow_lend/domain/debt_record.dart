import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:kept/core/firebase/firestore_codec.dart';
import 'package:kept/core/utils/dates.dart';

enum DebtDirection {
  /// I borrowed from someone; I owe them.
  borrowed,

  /// I lent to someone; they owe me.
  lent,
}

enum DebtStatus { pending, partiallySettled, settled, overdue }

class Settlement {
  const Settlement({
    required this.id,
    required this.amountMinor,
    required this.date,
    this.note = '',
    this.accountId,
    this.transactionId,
  });

  final String id;
  final int amountMinor;
  final DateTime date;
  final String note;
  final String? accountId;
  final String? transactionId;

  Map<String, dynamic> toMap() => {
    'id': id,
    'amountMinor': amountMinor,
    'date': Timestamp.fromDate(date),
    'note': note,
    'accountId': accountId,
    'transactionId': transactionId,
  };

  factory Settlement.fromMap(Map<String, dynamic> map) => Settlement(
    id: Codec.string(map['id']),
    amountMinor: Codec.integer(map['amountMinor']).abs(),
    date: Codec.date(map['date']) ?? DateTime.now(),
    note: Codec.string(map['note']),
    accountId: Codec.stringOrNull(map['accountId']),
    transactionId: Codec.stringOrNull(map['transactionId']),
  );
}

/// Default reminder offsets for due dates: 7 days, 2 days, 1 day before and
/// on the day itself (in minutes).
const defaultDueOffsetsMinutes = [7 * 1440, 2 * 1440, 1440, 0];

class DebtRecord {
  const DebtRecord({
    required this.id,
    required this.direction,
    required this.personName,
    required this.amountMinor,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.description = '',
    this.notes = '',
    this.accountId,
    this.transactionId,
    this.settlements = const [],
    this.reminderEnabled = true,
    this.reminderOffsetsMinutes = defaultDueOffsetsMinutes,
  });

  final String id;
  final DebtDirection direction;
  final String personName;
  final int amountMinor;
  final DateTime date;
  final DateTime? dueDate;
  final String description;
  final String notes;

  /// Account the money originally moved through, if tracked.
  final String? accountId;

  /// The `borrowed`/`lent` transaction created with this record.
  final String? transactionId;
  final List<Settlement> settlements;
  final bool reminderEnabled;
  final List<int> reminderOffsetsMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get settledMinor => settlements.fold(0, (s, e) => s + e.amountMinor);

  int get outstandingMinor {
    final value = amountMinor - settledMinor;
    return value < 0 ? 0 : value;
  }

  bool get isSettled => outstandingMinor == 0;

  DebtStatus statusAt(DateTime now) {
    if (isSettled) return DebtStatus.settled;
    if (dueDate != null && Dates.dayOf(dueDate!).isBefore(Dates.dayOf(now))) {
      return DebtStatus.overdue;
    }
    return settledMinor > 0 ? DebtStatus.partiallySettled : DebtStatus.pending;
  }

  DebtRecord copyWith({
    DebtDirection? direction,
    String? personName,
    int? amountMinor,
    DateTime? date,
    DateTime? Function()? dueDate,
    String? description,
    String? notes,
    String? Function()? accountId,
    String? Function()? transactionId,
    List<Settlement>? settlements,
    bool? reminderEnabled,
    List<int>? reminderOffsetsMinutes,
    DateTime? updatedAt,
  }) => DebtRecord(
    id: id,
    direction: direction ?? this.direction,
    personName: personName ?? this.personName,
    amountMinor: amountMinor ?? this.amountMinor,
    date: date ?? this.date,
    dueDate: dueDate != null ? dueDate() : this.dueDate,
    description: description ?? this.description,
    notes: notes ?? this.notes,
    accountId: accountId != null ? accountId() : this.accountId,
    transactionId: transactionId != null ? transactionId() : this.transactionId,
    settlements: settlements ?? this.settlements,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderOffsetsMinutes:
        reminderOffsetsMinutes ?? this.reminderOffsetsMinutes,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'direction': direction.name,
    'personName': personName,
    'amountMinor': amountMinor,
    'date': Timestamp.fromDate(date),
    'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
    'description': description,
    'notes': notes,
    'accountId': accountId,
    'transactionId': transactionId,
    'settlements': settlements.map((s) => s.toMap()).toList(),
    'reminderEnabled': reminderEnabled,
    'reminderOffsetsMinutes': reminderOffsetsMinutes,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory DebtRecord.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    return DebtRecord(
      id: id,
      direction: Codec.enumByName(
        DebtDirection.values,
        map['direction'],
        DebtDirection.lent,
      ),
      personName: Codec.string(map['personName']),
      amountMinor: Codec.integer(map['amountMinor']).abs(),
      date: Codec.date(map['date']) ?? now,
      dueDate: Codec.date(map['dueDate']),
      description: Codec.string(map['description']),
      notes: Codec.string(map['notes']),
      accountId: Codec.stringOrNull(map['accountId']),
      transactionId: Codec.stringOrNull(map['transactionId']),
      settlements: (map['settlements'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((m) => Settlement.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      reminderEnabled: Codec.boolean(map['reminderEnabled'], true),
      reminderOffsetsMinutes: map.containsKey('reminderOffsetsMinutes')
          ? Codec.ints(map['reminderOffsetsMinutes'])
          : defaultDueOffsetsMinutes,
      createdAt: Codec.date(map['createdAt']) ?? now,
      updatedAt: Codec.date(map['updatedAt']) ?? now,
    );
  }
}

class DebtSummary {
  const DebtSummary({
    required this.borrowedTotalMinor,
    required this.lentTotalMinor,
    required this.iOweMinor,
    required this.owedToMeMinor,
    required this.overdueMinor,
    required this.openCount,
  });

  /// Principal of all borrow records (ever).
  final int borrowedTotalMinor;

  /// Principal of all lend records (ever).
  final int lentTotalMinor;

  /// Outstanding amount still owed to others.
  final int iOweMinor;

  /// Outstanding amount others still owe me.
  final int owedToMeMinor;

  /// Outstanding amount (both directions) past its due date.
  final int overdueMinor;
  final int openCount;

  static DebtSummary compute(Iterable<DebtRecord> records, DateTime now) {
    var borrowed = 0, lent = 0, iOwe = 0, owedToMe = 0, overdue = 0, open = 0;
    for (final r in records) {
      final outstanding = r.outstandingMinor;
      if (r.direction == DebtDirection.borrowed) {
        borrowed += r.amountMinor;
        iOwe += outstanding;
      } else {
        lent += r.amountMinor;
        owedToMe += outstanding;
      }
      if (outstanding > 0) open++;
      if (r.statusAt(now) == DebtStatus.overdue) overdue += outstanding;
    }
    return DebtSummary(
      borrowedTotalMinor: borrowed,
      lentTotalMinor: lent,
      iOweMinor: iOwe,
      owedToMeMinor: owedToMe,
      overdueMinor: overdue,
      openCount: open,
    );
  }
}
