import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:kept/core/firebase/firestore_codec.dart';

enum AccountType { savings, current, cash, wallet, other }

/// A bank or cash account. Never holds credentials: only a display name,
/// bank name and balances.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.bankName = '',
    this.openingBalanceMinor = 0,
    this.ledgerDeltaMinor = 0,
    this.notes = '',
    this.archived = false,
  });

  final String id;
  final String name;
  final String bankName;
  final AccountType type;
  final int openingBalanceMinor;

  /// Sum of all transaction effects, maintained by the transaction
  /// repository via `LedgerEffects`. Do not edit directly.
  final int ledgerDeltaMinor;
  final String notes;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get balanceMinor => openingBalanceMinor + ledgerDeltaMinor;

  String get displayName => bankName.isEmpty ? name : '$name · $bankName';

  Account copyWith({
    String? name,
    String? bankName,
    AccountType? type,
    int? openingBalanceMinor,
    String? notes,
    bool? archived,
    DateTime? updatedAt,
  }) => Account(
    id: id,
    name: name ?? this.name,
    bankName: bankName ?? this.bankName,
    type: type ?? this.type,
    openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
    ledgerDeltaMinor: ledgerDeltaMinor,
    notes: notes ?? this.notes,
    archived: archived ?? this.archived,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Fields the user edits. [ledgerDeltaMinor] is deliberately absent so a
  /// profile edit can never overwrite a concurrently incremented balance.
  Map<String, dynamic> toEditableMap() => {
    'name': name,
    'bankName': bankName,
    'type': type.name,
    'openingBalanceMinor': openingBalanceMinor,
    'notes': notes,
    'archived': archived,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  Map<String, dynamic> toMap() => {
    ...toEditableMap(),
    'ledgerDeltaMinor': ledgerDeltaMinor,
  };

  factory Account.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    return Account(
      id: id,
      name: Codec.string(map['name']),
      bankName: Codec.string(map['bankName']),
      type: Codec.enumByName(
        AccountType.values,
        map['type'],
        AccountType.other,
      ),
      openingBalanceMinor: Codec.integer(map['openingBalanceMinor']),
      ledgerDeltaMinor: Codec.integer(map['ledgerDeltaMinor']),
      notes: Codec.string(map['notes']),
      archived: Codec.boolean(map['archived']),
      createdAt: Codec.date(map['createdAt']) ?? now,
      updatedAt: Codec.date(map['updatedAt']) ?? now,
    );
  }
}
