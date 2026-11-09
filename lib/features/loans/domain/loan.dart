import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:kept/core/firebase/firestore_codec.dart';
import 'package:kept/features/loans/domain/emi_engine.dart';

/// Status the user sets explicitly. `completed` and `prepaid` are derived
/// from the schedule (see `LoanSchedule.effectiveStatus`), while `closed`
/// (foreclosed / settled outside the app) is a manual override.
enum LoanStatus { active, completed, closed, prepaid }

class Loan {
  const Loan({
    required this.id,
    required this.name,
    required this.principalMinor,
    required this.annualRatePercent,
    required this.installments,
    required this.frequency,
    required this.emiMinor,
    required this.firstDueDate,
    required this.createdAt,
    required this.updatedAt,
    this.lender = '',
    this.accountId,
    this.status = LoanStatus.active,
    this.notes = '',
    this.reminderEnabled = true,
  });

  final String id;
  final String name;
  final String lender;
  final int principalMinor;
  final double annualRatePercent;

  /// Number of installments in the original contract.
  final int installments;
  final EmiFrequency frequency;

  /// Installment amount as charged by the lender. Defaults to the computed
  /// EMI but can be overridden because lenders round differently.
  final int emiMinor;

  /// Due date of installment 1; later due dates keep its day of month.
  final DateTime firstDueDate;

  /// Account EMIs are paid from, used as the default when paying.
  final String? accountId;
  final LoanStatus status;
  final String notes;
  final bool reminderEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get periodicRate =>
      EmiEngine.periodicRate(annualRatePercent, frequency);

  int get tenureMonths => installments * frequency.monthsPerPeriod;

  Loan copyWith({
    String? name,
    String? lender,
    int? principalMinor,
    double? annualRatePercent,
    int? installments,
    EmiFrequency? frequency,
    int? emiMinor,
    DateTime? firstDueDate,
    String? Function()? accountId,
    LoanStatus? status,
    String? notes,
    bool? reminderEnabled,
    DateTime? updatedAt,
  }) => Loan(
    id: id,
    name: name ?? this.name,
    lender: lender ?? this.lender,
    principalMinor: principalMinor ?? this.principalMinor,
    annualRatePercent: annualRatePercent ?? this.annualRatePercent,
    installments: installments ?? this.installments,
    frequency: frequency ?? this.frequency,
    emiMinor: emiMinor ?? this.emiMinor,
    firstDueDate: firstDueDate ?? this.firstDueDate,
    accountId: accountId != null ? accountId() : this.accountId,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'lender': lender,
    'principalMinor': principalMinor,
    'annualRatePercent': annualRatePercent,
    'installments': installments,
    'frequency': frequency.name,
    'emiMinor': emiMinor,
    'firstDueDate': Timestamp.fromDate(firstDueDate),
    'accountId': accountId,
    'status': status.name,
    'notes': notes,
    'reminderEnabled': reminderEnabled,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory Loan.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    return Loan(
      id: id,
      name: Codec.string(map['name']),
      lender: Codec.string(map['lender']),
      principalMinor: Codec.integer(map['principalMinor']),
      annualRatePercent: Codec.decimal(map['annualRatePercent']),
      installments: Codec.integer(map['installments'], 1).clamp(1, 1200),
      frequency: Codec.enumByName(
        EmiFrequency.values,
        map['frequency'],
        EmiFrequency.monthly,
      ),
      emiMinor: Codec.integer(map['emiMinor']),
      firstDueDate: Codec.date(map['firstDueDate']) ?? now,
      accountId: Codec.stringOrNull(map['accountId']),
      status: Codec.enumByName(
        LoanStatus.values,
        map['status'],
        LoanStatus.active,
      ),
      notes: Codec.string(map['notes']),
      reminderEnabled: Codec.boolean(map['reminderEnabled'], true),
      createdAt: Codec.date(map['createdAt']) ?? now,
      updatedAt: Codec.date(map['updatedAt']) ?? now,
    );
  }
}

enum LoanEventKind { emiPaid, skipped, prepayment }

/// What a prepayment does to the rest of the loan. Chosen explicitly by the
/// user; the app never picks one silently.
enum PrepaymentMode {
  /// Keep the EMI; the loan ends earlier.
  reduceTenure,

  /// Keep the remaining number of installments; the EMI drops.
  reduceEmi,
}

/// A recorded action against a loan (stored in `loan_payments`).
class LoanEvent {
  const LoanEvent({
    required this.id,
    required this.loanId,
    required this.kind,
    required this.date,
    required this.createdAt,
    this.installmentNumber,
    this.amountMinor = 0,
    this.prepaymentMode,
    this.transactionId,
    this.note = '',
  });

  /// One payment/skip record per installment: re-recording the same
  /// installment overwrites instead of duplicating.
  static String installmentEventId(String loanId, int number) =>
      '${loanId}_i$number';

  final String id;
  final String loanId;
  final LoanEventKind kind;
  final DateTime date;
  final int? installmentNumber;
  final int amountMinor;
  final PrepaymentMode? prepaymentMode;

  /// Linked `loanPayment` transaction, when the payment moved money from a
  /// tracked account.
  final String? transactionId;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'loanId': loanId,
    'kind': kind.name,
    'date': Timestamp.fromDate(date),
    'installmentNumber': installmentNumber,
    'amountMinor': amountMinor,
    'prepaymentMode': prepaymentMode?.name,
    'transactionId': transactionId,
    'note': note,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory LoanEvent.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    final modeName = map['prepaymentMode'];
    return LoanEvent(
      id: id,
      loanId: Codec.string(map['loanId']),
      kind: Codec.enumByName(
        LoanEventKind.values,
        map['kind'],
        LoanEventKind.emiPaid,
      ),
      date: Codec.date(map['date']) ?? now,
      installmentNumber: Codec.intOrNull(map['installmentNumber']),
      amountMinor: Codec.integer(map['amountMinor']),
      prepaymentMode: modeName == null
          ? null
          : Codec.enumByName(
              PrepaymentMode.values,
              modeName,
              PrepaymentMode.reduceTenure,
            ),
      transactionId: Codec.stringOrNull(map['transactionId']),
      note: Codec.string(map['note']),
      createdAt: Codec.date(map['createdAt']) ?? now,
    );
  }
}
