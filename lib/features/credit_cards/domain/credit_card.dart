import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:kept/core/firebase/firestore_codec.dart';
import 'package:kept/core/utils/dates.dart';

/// A credit card. Only the last four digits are kept for recognition; the
/// app never stores the full number, CVV, PIN, OTP or banking passwords.
class CreditCard {
  const CreditCard({
    required this.id,
    required this.name,
    required this.creditLimitMinor,
    required this.statementDay,
    required this.dueDay,
    required this.createdAt,
    required this.updatedAt,
    this.bankName = '',
    this.last4 = '',
    this.openingOutstandingMinor = 0,
    this.ledgerDeltaMinor = 0,
    this.minimumDuePercent = 5,
    this.annualRatePercent,
    this.linkedAccountId,
    this.notes = '',
    this.archived = false,
  });

  static final last4Pattern = RegExp(r'^\d{4}$');

  /// Typical gap between a card's statement date and its payment due date.
  static const defaultStatementToDueDays = 20;

  /// Used by the debt-free plan, labelled as an estimate, until the user
  /// enters the rate from their statement.
  static const typicalAnnualRatePercent = 36.0;

  /// Statement day when the user only gave the payment due day: about
  /// [defaultStatementToDueDays] days earlier, kept within 1–28 so it
  /// exists in every month. Statement figures built on it are estimates.
  static int defaultStatementDay(int dueDay) {
    var day = dueDay - defaultStatementToDueDays;
    if (day < 1) day += 30;
    return day.clamp(1, 28);
  }

  final String id;
  final String name;
  final String bankName;
  final String last4;
  final int creditLimitMinor;

  /// Outstanding when the card was added to the app.
  final int openingOutstandingMinor;

  /// Sum of transaction effects; maintained by the transaction repository.
  final int ledgerDeltaMinor;

  /// Day of month the statement is generated (1–31, clamped to month end).
  final int statementDay;

  /// Day of month the payment is due.
  final int dueDay;

  /// Used to estimate minimum due; banks differ, so it is configurable and
  /// always labelled as an estimate.
  final double minimumDuePercent;

  /// Interest charged on a carried balance; null until the user enters it.
  final double? annualRatePercent;
  final String? linkedAccountId;
  final String notes;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get outstandingMinor => openingOutstandingMinor + ledgerDeltaMinor;

  int get availableMinor {
    final owed = outstandingMinor < 0 ? 0 : outstandingMinor;
    final available = creditLimitMinor - owed;
    return available < 0 ? 0 : available;
  }

  /// 0.0–1.0+ (can exceed 1 when over limit).
  double get utilization => creditLimitMinor <= 0 || outstandingMinor <= 0
      ? 0
      : outstandingMinor / creditLimitMinor;

  String get displayName {
    final suffix = last4.isEmpty ? '' : ' ••$last4';
    return '$name$suffix';
  }

  /// Most recent statement date on or before [now].
  DateTime lastStatementDate(DateTime now) {
    final today = Dates.dayOf(now);
    final thisMonth = _onDay(today.year, today.month, statementDay);
    if (!thisMonth.isAfter(today)) return thisMonth;
    return _onDay(today.year, today.month - 1, statementDay);
  }

  /// Next payment due date on or after [now].
  DateTime nextDueDate(DateTime now) {
    final today = Dates.dayOf(now);
    final thisMonth = _onDay(today.year, today.month, dueDay);
    if (!thisMonth.isBefore(today)) return thisMonth;
    return _onDay(today.year, today.month + 1, dueDay);
  }

  /// Current billing cycle: the day after the last statement through the
  /// next statement date (inclusive), as a half-open range.
  DateRange currentCycle(DateTime now) {
    final last = lastStatementDate(now);
    final next = _onDay(last.year, last.month + 1, statementDay);
    return DateRange(
      last.add(const Duration(days: 1)),
      next.add(const Duration(days: 1)),
    );
  }

  static DateTime _onDay(int year, int month, int day) {
    final normalized = DateTime(year, month);
    final clamped = day.clamp(
      1,
      Dates.daysInMonth(normalized.year, normalized.month),
    );
    return DateTime(normalized.year, normalized.month, clamped);
  }

  CreditCard copyWith({
    String? name,
    String? bankName,
    String? last4,
    int? creditLimitMinor,
    int? openingOutstandingMinor,
    int? statementDay,
    int? dueDay,
    double? minimumDuePercent,
    double? Function()? annualRatePercent,
    String? Function()? linkedAccountId,
    String? notes,
    bool? archived,
    DateTime? updatedAt,
  }) => CreditCard(
    id: id,
    name: name ?? this.name,
    bankName: bankName ?? this.bankName,
    last4: last4 ?? this.last4,
    creditLimitMinor: creditLimitMinor ?? this.creditLimitMinor,
    openingOutstandingMinor:
        openingOutstandingMinor ?? this.openingOutstandingMinor,
    ledgerDeltaMinor: ledgerDeltaMinor,
    statementDay: statementDay ?? this.statementDay,
    dueDay: dueDay ?? this.dueDay,
    minimumDuePercent: minimumDuePercent ?? this.minimumDuePercent,
    annualRatePercent: annualRatePercent != null
        ? annualRatePercent()
        : this.annualRatePercent,
    linkedAccountId: linkedAccountId != null
        ? linkedAccountId()
        : this.linkedAccountId,
    notes: notes ?? this.notes,
    archived: archived ?? this.archived,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toEditableMap() => {
    'name': name,
    'bankName': bankName,
    'last4': last4,
    'creditLimitMinor': creditLimitMinor,
    'openingOutstandingMinor': openingOutstandingMinor,
    'statementDay': statementDay,
    'dueDay': dueDay,
    'minimumDuePercent': minimumDuePercent,
    'annualRatePercent': annualRatePercent,
    'linkedAccountId': linkedAccountId,
    'notes': notes,
    'archived': archived,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  Map<String, dynamic> toMap() => {
    ...toEditableMap(),
    'ledgerDeltaMinor': ledgerDeltaMinor,
  };

  factory CreditCard.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    final last4 = Codec.string(map['last4']);
    return CreditCard(
      id: id,
      name: Codec.string(map['name']),
      bankName: Codec.string(map['bankName']),
      last4: last4Pattern.hasMatch(last4) ? last4 : '',
      creditLimitMinor: Codec.integer(map['creditLimitMinor']),
      openingOutstandingMinor: Codec.integer(map['openingOutstandingMinor']),
      ledgerDeltaMinor: Codec.integer(map['ledgerDeltaMinor']),
      statementDay: Codec.integer(map['statementDay'], 1).clamp(1, 31),
      dueDay: Codec.integer(map['dueDay'], 1).clamp(1, 31),
      minimumDuePercent: Codec.decimal(map['minimumDuePercent'], 5),
      annualRatePercent: map['annualRatePercent'] is num
          ? Codec.decimal(map['annualRatePercent'])
          : null,
      linkedAccountId: Codec.stringOrNull(map['linkedAccountId']),
      notes: Codec.string(map['notes']),
      archived: Codec.boolean(map['archived']),
      createdAt: Codec.date(map['createdAt']) ?? now,
      updatedAt: Codec.date(map['updatedAt']) ?? now,
    );
  }
}

/// Statement figures derived from the outstanding balance and the card's
/// transactions since the last statement date.
class CardStatus {
  const CardStatus({
    required this.statementBalanceMinor,
    required this.totalDueMinor,
    required this.minimumDueMinor,
    required this.chargesSinceStatementMinor,
    required this.paymentsSinceStatementMinor,
    required this.lastStatementDate,
    required this.dueDate,
  });

  /// [chargesSince] and [paymentsSince] are the card's ledger movements after
  /// the last statement date (charges increase outstanding; payments and
  /// refunds decrease it).
  factory CardStatus.compute({
    required CreditCard card,
    required DateTime now,
    required int chargesSince,
    required int paymentsSince,
  }) {
    final statementBalance =
        card.outstandingMinor - chargesSince + paymentsSince;
    final totalDue = max(0, statementBalance - paymentsSince);
    final minimum =
        (statementBalance * card.minimumDuePercent / 100).ceil() -
        paymentsSince;
    final lastStatement = card.lastStatementDate(now);
    // The due date belongs to the last statement: the first due day after it.
    final dueAfterStatement = card.nextDueDate(
      lastStatement.add(const Duration(days: 1)),
    );
    return CardStatus(
      statementBalanceMinor: max(0, statementBalance),
      totalDueMinor: totalDue,
      minimumDueMinor: minimum.clamp(0, totalDue),
      chargesSinceStatementMinor: chargesSince,
      paymentsSinceStatementMinor: paymentsSince,
      lastStatementDate: lastStatement,
      dueDate: dueAfterStatement,
    );
  }

  final int statementBalanceMinor;
  final int totalDueMinor;
  final int minimumDueMinor;
  final int chargesSinceStatementMinor;
  final int paymentsSinceStatementMinor;
  final DateTime lastStatementDate;
  final DateTime dueDate;

  bool get isPaid => totalDueMinor == 0;
}
