import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:kept/core/firebase/firestore_codec.dart';
import 'package:kept/core/utils/dates.dart';
import 'package:kept/core/utils/recurrence.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/transactions/domain/transaction.dart';

/// A template that produces a transaction on every occurrence (salary,
/// rent, subscriptions…).
///
/// Loan EMIs are deliberately not recurring rules: they are paid through the
/// loan module so installments are marked paid and the schedule stays right.
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.title,
    required this.type,
    required this.amountMinor,
    required this.categoryId,
    required this.startDate,
    required this.recurrence,
    required this.createdAt,
    required this.updatedAt,
    this.subCategoryId,
    this.accountId,
    this.toAccountId,
    this.creditCardId,
    this.notes = '',
    this.lastGeneratedDate,
    this.enabled = true,
  });

  static const allowedTypes = {
    TransactionType.expense,
    TransactionType.income,
    TransactionType.creditCardExpense,
    TransactionType.transfer,
  };

  /// Deterministic id of the transaction for one occurrence. Generation
  /// writes with this id, so running twice for the same day is harmless.
  static String occurrenceTransactionId(String ruleId, DateTime occurrence) =>
      'rec_${ruleId}_${Dates.compactKey(occurrence)}';

  final String id;
  final String title;
  final TransactionType type;
  final int amountMinor;
  final String categoryId;
  final String? subCategoryId;
  final String? accountId;
  final String? toAccountId;
  final String? creditCardId;
  final String notes;

  /// First occurrence; later ones keep its day of month / weekday.
  final DateTime startDate;
  final Recurrence recurrence;

  /// Date of the last occurrence already turned into a transaction.
  final DateTime? lastGeneratedDate;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get anchor => Dates.dayOf(startDate);

  /// Occurrences due up to and including [today] that have not been
  /// generated yet, oldest first, at most [limit].
  List<DateTime> dueOccurrences(DateTime today, {int limit = 120}) {
    if (!enabled) return const [];
    final from = lastGeneratedDate == null
        ? anchor
        : Dates.dayOf(lastGeneratedDate!).add(const Duration(days: 1));
    final to = Dates.dayOf(today).add(const Duration(days: 1));
    return recurrence.between(anchor, from, to).take(limit).toList();
  }

  /// Upcoming occurrences after [today], for previews.
  List<DateTime> upcoming(DateTime today, {int count = 3}) {
    if (!enabled) return const [];
    final from = Dates.dayOf(today).add(const Duration(days: 1));
    final start = lastGeneratedDate != null && lastGeneratedDate!.isAfter(from)
        ? lastGeneratedDate!.add(const Duration(days: 1))
        : from;
    return recurrence
        .between(anchor, start, DateTime(today.year + 3))
        .take(count)
        .toList();
  }

  Transaction transactionFor(DateTime occurrence, DateTime now) => Transaction(
    id: occurrenceTransactionId(id, occurrence),
    date: DateTime(occurrence.year, occurrence.month, occurrence.day, 9),
    amountMinor: amountMinor,
    type: type,
    categoryId: type == TransactionType.transfer
        ? Categories.transferId
        : categoryId,
    subCategoryId: subCategoryId,
    description: title,
    notes: notes,
    accountId: type == TransactionType.creditCardExpense ? null : accountId,
    toAccountId: type == TransactionType.transfer ? toAccountId : null,
    creditCardId: type == TransactionType.creditCardExpense
        ? creditCardId
        : null,
    recurringRuleId: id,
    createdAt: now,
    updatedAt: now,
  );

  RecurringRule copyWith({
    String? title,
    TransactionType? type,
    int? amountMinor,
    String? categoryId,
    String? Function()? subCategoryId,
    String? Function()? accountId,
    String? Function()? toAccountId,
    String? Function()? creditCardId,
    String? notes,
    DateTime? startDate,
    Recurrence? recurrence,
    DateTime? Function()? lastGeneratedDate,
    bool? enabled,
    DateTime? updatedAt,
  }) => RecurringRule(
    id: id,
    title: title ?? this.title,
    type: type ?? this.type,
    amountMinor: amountMinor ?? this.amountMinor,
    categoryId: categoryId ?? this.categoryId,
    subCategoryId: subCategoryId != null ? subCategoryId() : this.subCategoryId,
    accountId: accountId != null ? accountId() : this.accountId,
    toAccountId: toAccountId != null ? toAccountId() : this.toAccountId,
    creditCardId: creditCardId != null ? creditCardId() : this.creditCardId,
    notes: notes ?? this.notes,
    startDate: startDate ?? this.startDate,
    recurrence: recurrence ?? this.recurrence,
    lastGeneratedDate: lastGeneratedDate != null
        ? lastGeneratedDate()
        : this.lastGeneratedDate,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'type': type.name,
    'amountMinor': amountMinor,
    'categoryId': categoryId,
    'subCategoryId': subCategoryId,
    'accountId': accountId,
    'toAccountId': toAccountId,
    'creditCardId': creditCardId,
    'notes': notes,
    'startDate': Timestamp.fromDate(startDate),
    'recurrence': recurrence.toMap(),
    'lastGeneratedDate': lastGeneratedDate == null
        ? null
        : Timestamp.fromDate(lastGeneratedDate!),
    'enabled': enabled,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory RecurringRule.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    final type = Codec.enumByName(
      TransactionType.values,
      map['type'],
      TransactionType.expense,
    );
    return RecurringRule(
      id: id,
      title: Codec.string(map['title']),
      type: allowedTypes.contains(type) ? type : TransactionType.expense,
      amountMinor: Codec.integer(map['amountMinor']).abs(),
      categoryId: Codec.string(map['categoryId'], Categories.otherExpenseId),
      subCategoryId: Codec.stringOrNull(map['subCategoryId']),
      accountId: Codec.stringOrNull(map['accountId']),
      toAccountId: Codec.stringOrNull(map['toAccountId']),
      creditCardId: Codec.stringOrNull(map['creditCardId']),
      notes: Codec.string(map['notes']),
      startDate: Codec.date(map['startDate']) ?? now,
      recurrence: Recurrence.fromMap(map['recurrence']),
      lastGeneratedDate: Codec.date(map['lastGeneratedDate']),
      enabled: Codec.boolean(map['enabled'], true),
      createdAt: Codec.date(map['createdAt']) ?? now,
      updatedAt: Codec.date(map['updatedAt']) ?? now,
    );
  }
}
