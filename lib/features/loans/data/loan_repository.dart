import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:kept/core/firebase/collections.dart';
import 'package:kept/core/firebase/entity_store.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/core/utils/dates.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/loans/domain/loan.dart';
import 'package:kept/features/transactions/data/transaction_repository.dart';
import 'package:kept/features/transactions/domain/transaction.dart';

class LoanRepository {
  LoanRepository({
    required DocumentReference<Map<String, dynamic>> userDoc,
    required WriteDispatcher writer,
    required TransactionRepository transactions,
  }) : _transactions = transactions,
       loans = EntityStore(
         userDoc: userDoc,
         collection: Collections.loans,
         fromMap: Loan.fromMap,
         writer: writer,
       ),
       events = EntityStore(
         userDoc: userDoc,
         collection: Collections.loanPayments,
         fromMap: LoanEvent.fromMap,
         writer: writer,
       );

  final EntityStore<Loan> loans;
  final EntityStore<LoanEvent> events;
  final TransactionRepository _transactions;

  String newId() => loans.newId();

  Stream<List<Loan>> watchAll() => loans.watchAll().map(
    (list) => list..sort((a, b) => a.firstDueDate.compareTo(b.firstDueDate)),
  );

  /// All loan events; the volume is small (one per installment).
  Stream<List<LoanEvent>> watchAllEvents() => events.watchAll();

  Stream<List<LoanEvent>> watchEvents(String loanId) =>
      events.watchQuery((c) => c.where('loanId', isEqualTo: loanId));

  void save(Loan loan) => loans.set(loan.id, loan.toMap());

  /// Records installment [number] as paid.
  ///
  /// When [accountId] is given, a `loanPayment` transaction (deterministic
  /// id per installment) moves the money out of that account in the same
  /// batch. [previousTransaction] is the transaction currently linked to
  /// this installment, if any; it is replaced so the ledger moves only by
  /// the difference and re-recording never duplicates.
  void payInstallment({
    required Loan loan,
    required int number,
    required int amountMinor,
    required DateTime date,
    String? accountId,
    Transaction? previousTransaction,
  }) {
    final now = DateTime.now();
    final batch = _transactions.batch();
    final txId = accountId == null
        ? null
        : installmentTransactionId(loan.id, number);
    if (txId != null) {
      _transactions.stage(
        batch,
        Transaction(
          id: txId,
          date: date,
          amountMinor: amountMinor,
          type: TransactionType.loanPayment,
          categoryId: Categories.loanId,
          description: loan.name,
          counterparty: loan.lender,
          accountId: accountId,
          loanId: loan.id,
          createdAt: previousTransaction?.createdAt ?? now,
          updatedAt: now,
        ),
        before: previousTransaction?.id == txId ? previousTransaction : null,
      );
    }
    if (previousTransaction != null && previousTransaction.id != txId) {
      _transactions.stageDelete(batch, previousTransaction);
    }
    final id = LoanEvent.installmentEventId(loan.id, number);
    batch.set(
      events.ref.doc(id),
      LoanEvent(
        id: id,
        loanId: loan.id,
        kind: LoanEventKind.emiPaid,
        installmentNumber: number,
        amountMinor: amountMinor,
        date: date,
        transactionId: txId,
        createdAt: now,
      ).toMap(),
    );
    _transactions.commit(batch);
  }

  /// Marks installments 1..[count] as already paid when a loan that is
  /// part-way through is added to the app.
  ///
  /// This is history only: it creates paid marks (dated on each due date)
  /// but no transactions, so no account balance changes — those payments
  /// happened before the app was tracking the money. Idempotent: ids are
  /// per installment, so repeating it never duplicates.
  void recordPastPayments(Loan loan, int count) {
    if (count <= 0) return;
    final now = DateTime.now();
    final batch = _transactions.batch();
    for (var k = 1; k <= count && k <= loan.installments; k++) {
      final due = Dates.addMonths(
        Dates.dayOf(loan.firstDueDate),
        (k - 1) * loan.frequency.monthsPerPeriod,
        preferredDay: loan.firstDueDate.day,
      );
      final id = LoanEvent.installmentEventId(loan.id, k);
      batch.set(
        events.ref.doc(id),
        LoanEvent(
          id: id,
          loanId: loan.id,
          kind: LoanEventKind.emiPaid,
          installmentNumber: k,
          amountMinor: loan.emiMinor,
          date: due,
          createdAt: now,
        ).toMap(),
      );
    }
    _transactions.commit(batch);
  }

  static String installmentTransactionId(String loanId, int number) =>
      'loan_${loanId}_i$number';

  /// Marks installment [number] as skipped (missed). If it had been paid,
  /// the linked [previousTransaction] is reversed.
  void skipInstallment(
    Loan loan,
    int number, {
    Transaction? previousTransaction,
  }) {
    final now = DateTime.now();
    final id = LoanEvent.installmentEventId(loan.id, number);
    final batch = _transactions.batch();
    if (previousTransaction != null) {
      _transactions.stageDelete(batch, previousTransaction);
    }
    batch.set(
      events.ref.doc(id),
      LoanEvent(
        id: id,
        loanId: loan.id,
        kind: LoanEventKind.skipped,
        installmentNumber: number,
        date: now,
        createdAt: now,
      ).toMap(),
    );
    _transactions.commit(batch);
  }

  /// Removes a paid/skipped mark, reversing the linked payment transaction.
  void clearInstallment(LoanEvent event, {Transaction? linked}) {
    final batch = _transactions.batch();
    batch.delete(events.ref.doc(event.id));
    if (linked != null) _transactions.stageDelete(batch, linked);
    _transactions.commit(batch);
  }

  void addPrepayment({
    required Loan loan,
    required int amountMinor,
    required DateTime date,
    required PrepaymentMode mode,
    String? accountId,
    String note = '',
  }) {
    final now = DateTime.now();
    final id = events.newId();
    final batch = _transactions.batch();
    String? txId;
    if (accountId != null) {
      txId = 'loan_${loan.id}_p$id';
      _transactions.stage(
        batch,
        Transaction(
          id: txId,
          date: date,
          amountMinor: amountMinor,
          type: TransactionType.loanPayment,
          categoryId: Categories.loanId,
          description: loan.name,
          counterparty: loan.lender,
          notes: note,
          accountId: accountId,
          loanId: loan.id,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    batch.set(
      events.ref.doc(id),
      LoanEvent(
        id: id,
        loanId: loan.id,
        kind: LoanEventKind.prepayment,
        amountMinor: amountMinor,
        prepaymentMode: mode,
        date: date,
        transactionId: txId,
        note: note,
        createdAt: now,
      ).toMap(),
    );
    _transactions.commit(batch);
  }

  /// Deletes a loan with its events and linked payment transactions.
  Future<void> delete(Loan loan) async {
    final loanEvents = await events.ref
        .where('loanId', isEqualTo: loan.id)
        .get();
    final batch = _transactions.batch();
    for (final doc in loanEvents.docs) {
      final event = LoanEvent.fromMap(doc.id, doc.data());
      if (event.transactionId != null) {
        final tx = await _transactions.fetch(event.transactionId!);
        if (tx != null) _transactions.stageDelete(batch, tx);
      }
      batch.delete(doc.reference);
    }
    batch.delete(loans.ref.doc(loan.id));
    _transactions.commit(batch);
  }
}
