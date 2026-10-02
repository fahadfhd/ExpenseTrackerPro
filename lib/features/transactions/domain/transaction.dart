import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:expensetrackerpro/core/firebase/firestore_codec.dart';
import 'package:expensetrackerpro/features/categories/domain/category.dart';

/// Every way money can move. Persisted by [Enum.name]; never rename values.
enum TransactionType {
  expense,
  income,
  transfer,
  creditCardExpense,
  creditCardPayment,
  loanPayment,
  refund,

  /// Money received as a loan from a person (borrow/lend module).
  borrowed,

  /// Money given to a person as a loan.
  lent,

  /// Paying back money that was borrowed.
  debtRepayment,

  /// Receiving back money that was lent.
  debtCollection;

  bool get isInflow => switch (this) {
    income || refund || borrowed || debtCollection => true,
    _ => false,
  };

  /// Types that represent consumption and count towards spending analytics.
  bool get isSpending => this == expense || this == creditCardExpense;

  bool get isDebt =>
      this == borrowed ||
      this == lent ||
      this == debtRepayment ||
      this == debtCollection;
}

enum TransactionStatus { cleared, pending }

class Transaction {
  const Transaction({
    required this.id,
    required this.date,
    required this.amountMinor,
    required this.type,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.subCategoryId,
    this.description = '',
    this.notes = '',
    this.counterparty = '',
    this.accountId,
    this.toAccountId,
    this.creditCardId,
    this.loanId,
    this.borrowLendId,
    this.vehicleId,
    this.recurringRuleId,
    this.tags = const [],
    this.attachmentUrl,
    this.status = TransactionStatus.cleared,
    this.importSource,
  });

  /// Bump when the stored shape changes, and teach [fromMap] to read the
  /// previous version.
  static const schemaVersion = 2;

  final String id;
  final DateTime date;

  /// Always positive; direction comes from [type].
  final int amountMinor;
  final TransactionType type;
  final String categoryId;
  final String? subCategoryId;
  final String description;
  final String notes;

  /// Merchant or person involved.
  final String counterparty;

  /// Bank/cash account the money moved out of (or into, for inflows).
  final String? accountId;

  /// Destination account of a [TransactionType.transfer].
  final String? toAccountId;
  final String? creditCardId;
  final String? loanId;
  final String? borrowLendId;
  final String? vehicleId;
  final String? recurringRuleId;
  final List<String> tags;
  final String? attachmentUrl;
  final TransactionStatus status;

  /// Set for records created by the SMS/Gmail importer.
  final String? importSource;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCleared => status == TransactionStatus.cleared;

  Transaction copyWith({
    String? id,
    DateTime? date,
    int? amountMinor,
    TransactionType? type,
    String? categoryId,
    String? Function()? subCategoryId,
    String? description,
    String? notes,
    String? counterparty,
    String? Function()? accountId,
    String? Function()? toAccountId,
    String? Function()? creditCardId,
    String? Function()? loanId,
    String? Function()? borrowLendId,
    String? Function()? vehicleId,
    String? Function()? recurringRuleId,
    List<String>? tags,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      amountMinor: amountMinor ?? this.amountMinor,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId != null
          ? subCategoryId()
          : this.subCategoryId,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      counterparty: counterparty ?? this.counterparty,
      accountId: accountId != null ? accountId() : this.accountId,
      toAccountId: toAccountId != null ? toAccountId() : this.toAccountId,
      creditCardId: creditCardId != null ? creditCardId() : this.creditCardId,
      loanId: loanId != null ? loanId() : this.loanId,
      borrowLendId: borrowLendId != null ? borrowLendId() : this.borrowLendId,
      vehicleId: vehicleId != null ? vehicleId() : this.vehicleId,
      recurringRuleId: recurringRuleId != null
          ? recurringRuleId()
          : this.recurringRuleId,
      tags: tags ?? this.tags,
      attachmentUrl: attachmentUrl,
      status: status ?? this.status,
      importSource: importSource,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap({required String userId}) => {
    'schemaVersion': schemaVersion,
    'userId': userId,
    'date': Timestamp.fromDate(date),
    'amountMinor': amountMinor,
    'type': type.name,
    'categoryId': categoryId,
    'subCategoryId': subCategoryId,
    'description': description,
    'notes': notes,
    'counterparty': counterparty,
    'accountId': accountId,
    'toAccountId': toAccountId,
    'creditCardId': creditCardId,
    'loanId': loanId,
    'borrowLendId': borrowLendId,
    'vehicleId': vehicleId,
    'recurringRuleId': recurringRuleId,
    'tags': tags,
    'attachmentUrl': attachmentUrl,
    'status': status.name,
    'importSource': importSource,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory Transaction.fromMap(String id, Map<String, dynamic> map) {
    if (isLegacy(map)) return _fromLegacyMap(id, map);
    final now = DateTime.now();
    return Transaction(
      id: id,
      date: Codec.date(map['date']) ?? now,
      amountMinor: Codec.integer(map['amountMinor']).abs(),
      type: Codec.enumByName(
        TransactionType.values,
        map['type'],
        TransactionType.expense,
      ),
      categoryId: Codec.string(map['categoryId'], Categories.otherExpenseId),
      subCategoryId: Codec.stringOrNull(map['subCategoryId']),
      description: Codec.string(map['description']),
      notes: Codec.string(map['notes']),
      counterparty: Codec.string(map['counterparty']),
      accountId: Codec.stringOrNull(map['accountId']),
      toAccountId: Codec.stringOrNull(map['toAccountId']),
      creditCardId: Codec.stringOrNull(map['creditCardId']),
      loanId: Codec.stringOrNull(map['loanId']),
      borrowLendId: Codec.stringOrNull(map['borrowLendId']),
      vehicleId: Codec.stringOrNull(map['vehicleId']),
      recurringRuleId: Codec.stringOrNull(map['recurringRuleId']),
      tags: Codec.strings(map['tags']),
      attachmentUrl: Codec.stringOrNull(map['attachmentUrl']),
      status: Codec.enumByName(
        TransactionStatus.values,
        map['status'],
        TransactionStatus.cleared,
      ),
      importSource: Codec.stringOrNull(map['importSource']),
      createdAt: Codec.date(map['createdAt']) ?? now,
      updatedAt: Codec.date(map['updatedAt']) ?? now,
    );
  }

  /// Documents written before schema 2 (`merchant`, whole-unit `amount`,
  /// `isCredit`, ISO-string `occurredAt`).
  static bool isLegacy(Map<String, dynamic> map) =>
      map['schemaVersion'] == null && map.containsKey('merchant');

  static Transaction _fromLegacyMap(String id, Map<String, dynamic> map) {
    final isCredit = Codec.boolean(map['isCredit']);
    final occurredAt = Codec.date(map['occurredAt']) ?? DateTime.now();
    final named = Categories.fromLegacyName(map['category'] as String?);
    // Old parsers could pair a debit with "Income" (or a credit with an
    // expense category); keep the category consistent with the type so the
    // record stays valid and editable.
    final namedKind = Categories.byId(named).kind;
    final category = isCredit
        ? (namedKind == CategoryKind.income ? named : Categories.otherIncomeId)
        : (namedKind == CategoryKind.expense ? named : Categories.otherExpenseId);
    final channels = Codec.strings(map['sourceChannels']);
    return Transaction(
      id: id,
      date: occurredAt,
      // Legacy amounts were whole currency units.
      amountMinor: Codec.integer(map['amount']).abs() * 100,
      type: isCredit ? TransactionType.income : TransactionType.expense,
      categoryId: category,
      description: Codec.string(map['merchant']),
      counterparty: Codec.string(map['merchant']),
      notes: Codec.string(map['source']),
      importSource: channels.isEmpty ? 'legacy' : channels.join('+'),
      createdAt: occurredAt,
      updatedAt: occurredAt,
    );
  }
}
