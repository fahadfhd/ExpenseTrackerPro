import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:expensetrackerpro/features/vehicles/data/vehicle_repository.dart';
import 'package:expensetrackerpro/features/vehicles/domain/vehicle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) throw StateError('Requires a signed-in user');
  return VehicleRepository(
    userDoc: userDoc,
    writer: ref.watch(writeDispatcherProvider),
    transactions: ref.watch(transactionRepositoryProvider),
  );
});

final vehiclesProvider = StreamProvider<List<Vehicle>>(
  (ref) => ref.watch(vehicleRepositoryProvider).watchVehicles(),
);

final fuelLogsProvider = StreamProvider<List<FuelLog>>(
  (ref) => ref.watch(vehicleRepositoryProvider).watchFuelLogs(),
);

final vehicleFuelLogsProvider = Provider.family<List<FuelLog>, String>(
  (ref, vehicleId) => (ref.watch(fuelLogsProvider).value ?? const [])
      .where((l) => l.vehicleId == vehicleId)
      .toList(),
);

final vehicleStatsProvider = Provider.family<VehicleStats?, String>((
  ref,
  vehicleId,
) {
  final vehicle = (ref.watch(vehiclesProvider).value ?? const [])
      .where((v) => v.id == vehicleId)
      .firstOrNull;
  if (vehicle == null) return null;
  return VehicleStats.compute(
    vehicle,
    ref.watch(vehicleFuelLogsProvider(vehicleId)),
    DateTime.now(),
  );
});
