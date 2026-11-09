import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:kept/core/firebase/collections.dart';
import 'package:kept/core/firebase/entity_store.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/transactions/data/transaction_repository.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:kept/features/vehicles/domain/vehicle.dart';

class VehicleRepository {
  VehicleRepository({
    required DocumentReference<Map<String, dynamic>> userDoc,
    required WriteDispatcher writer,
    required TransactionRepository transactions,
  }) : _transactions = transactions,
       vehicles = EntityStore(
         userDoc: userDoc,
         collection: Collections.vehicles,
         fromMap: Vehicle.fromMap,
         writer: writer,
       ),
       fuelLogs = EntityStore(
         userDoc: userDoc,
         collection: Collections.fuelLogs,
         fromMap: FuelLog.fromMap,
         writer: writer,
       );

  final EntityStore<Vehicle> vehicles;
  final EntityStore<FuelLog> fuelLogs;
  final TransactionRepository _transactions;

  String newVehicleId() => vehicles.newId();

  String newFuelLogId() => fuelLogs.newId();

  Stream<List<Vehicle>> watchVehicles() => vehicles.watchAll().map(
    (list) => list..sort((a, b) => a.name.compareTo(b.name)),
  );

  /// Fuel logs are low volume (a few per month per vehicle), so the full
  /// set is streamed and sorted client-side; no composite index needed.
  Stream<List<FuelLog>> watchFuelLogs() => fuelLogs.watchAll().map(
    (list) => list..sort((a, b) => b.date.compareTo(a.date)),
  );

  void saveVehicle(Vehicle vehicle) =>
      vehicles.set(vehicle.id, vehicle.toMap());

  static String fuelTransactionId(String logId) => 'fuel_$logId';

  /// Saves a fuel log. When [accountId] or [creditCardId] is given, the cost
  /// is also recorded as a fuel expense in the same batch.
  Future<void> saveFuelLog(
    FuelLog log, {
    required String vehicleName,
    String? accountId,
    String? creditCardId,
  }) async {
    final txId = fuelTransactionId(log.id);
    final previous = await _transactions.fetch(txId);
    final now = DateTime.now();
    final batch = _transactions.batch();
    final tracked = accountId != null || creditCardId != null;
    if (tracked) {
      _transactions.stage(
        batch,
        Transaction(
          id: txId,
          date: log.date,
          amountMinor: log.totalCostMinor,
          type: creditCardId != null
              ? TransactionType.creditCardExpense
              : TransactionType.expense,
          categoryId: Categories.fuelId,
          subCategoryId: Categories.fuelSubId,
          description: vehicleName,
          accountId: creditCardId != null ? null : accountId,
          creditCardId: creditCardId,
          vehicleId: log.vehicleId,
          createdAt: previous?.createdAt ?? now,
          updatedAt: now,
        ),
        before: previous,
      );
    } else if (previous != null) {
      _transactions.stageDelete(batch, previous);
    }
    final stored = FuelLog(
      id: log.id,
      vehicleId: log.vehicleId,
      date: log.date,
      distanceKm: log.distanceKm,
      fuelQuantity: log.fuelQuantity,
      pricePerUnitMinor: log.pricePerUnitMinor,
      totalCostMinor: log.totalCostMinor,
      odometerKm: log.odometerKm,
      notes: log.notes,
      transactionId: tracked ? txId : null,
      createdAt: log.createdAt,
    );
    batch.set(fuelLogs.ref.doc(log.id), stored.toMap());
    _transactions.commit(batch);
  }

  Future<void> deleteFuelLog(FuelLog log) async {
    final batch = _transactions.batch();
    if (log.transactionId != null) {
      final tx = await _transactions.fetch(log.transactionId!);
      if (tx != null) _transactions.stageDelete(batch, tx);
    }
    batch.delete(fuelLogs.ref.doc(log.id));
    _transactions.commit(batch);
  }

  /// Deletes the vehicle and its fuel history. Linked fuel expenses are kept
  /// as ordinary spending so past budgets and balances stay correct.
  Future<void> deleteVehicle(String vehicleId) async {
    final logs = await fuelLogs.ref
        .where('vehicleId', isEqualTo: vehicleId)
        .get();
    final batch = _transactions.batch();
    for (final doc in logs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(vehicles.ref.doc(vehicleId));
    _transactions.commit(batch);
  }
}
