import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:expensetrackerpro/core/firebase/firestore_codec.dart';
import 'package:expensetrackerpro/core/utils/dates.dart';

enum FuelType { petrol, diesel, cng, lpg, electric, hybrid }

class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.fuelType,
    required this.createdAt,
    required this.updatedAt,
    this.registrationNickname = '',
    this.fuelPricePerUnitMinor = 0,
    this.mileage = 0,
    this.notes = '',
    this.archived = false,
  });

  final String id;
  final String name;
  final String registrationNickname;
  final FuelType fuelType;

  /// Current price per litre / kg / kWh.
  final int fuelPricePerUnitMinor;

  /// Distance per unit of fuel the user expects (km/l etc.). Replaced by
  /// the measured average once fuel logs exist.
  final double mileage;
  final String notes;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle copyWith({
    String? name,
    String? registrationNickname,
    FuelType? fuelType,
    int? fuelPricePerUnitMinor,
    double? mileage,
    String? notes,
    bool? archived,
    DateTime? updatedAt,
  }) => Vehicle(
    id: id,
    name: name ?? this.name,
    registrationNickname: registrationNickname ?? this.registrationNickname,
    fuelType: fuelType ?? this.fuelType,
    fuelPricePerUnitMinor: fuelPricePerUnitMinor ?? this.fuelPricePerUnitMinor,
    mileage: mileage ?? this.mileage,
    notes: notes ?? this.notes,
    archived: archived ?? this.archived,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'registrationNickname': registrationNickname,
    'fuelType': fuelType.name,
    'fuelPricePerUnitMinor': fuelPricePerUnitMinor,
    'mileage': mileage,
    'notes': notes,
    'archived': archived,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    return Vehicle(
      id: id,
      name: Codec.string(map['name']),
      registrationNickname: Codec.string(map['registrationNickname']),
      fuelType: Codec.enumByName(
        FuelType.values,
        map['fuelType'],
        FuelType.petrol,
      ),
      fuelPricePerUnitMinor: Codec.integer(map['fuelPricePerUnitMinor']),
      mileage: Codec.decimal(map['mileage']),
      notes: Codec.string(map['notes']),
      archived: Codec.boolean(map['archived']),
      createdAt: Codec.date(map['createdAt']) ?? now,
      updatedAt: Codec.date(map['updatedAt']) ?? now,
    );
  }
}

/// A refuel (or recharge) record.
class FuelLog {
  const FuelLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.distanceKm,
    required this.fuelQuantity,
    required this.pricePerUnitMinor,
    required this.totalCostMinor,
    required this.createdAt,
    this.odometerKm,
    this.notes = '',
    this.transactionId,
  });

  final String id;
  final String vehicleId;
  final DateTime date;

  /// Distance covered since the previous fill.
  final double distanceKm;
  final double fuelQuantity;
  final int pricePerUnitMinor;
  final int totalCostMinor;
  final double? odometerKm;
  final String notes;

  /// Linked expense transaction, if the fill was recorded as spending.
  final String? transactionId;
  final DateTime createdAt;

  double? get mileage => VehicleMath.mileage(distanceKm, fuelQuantity);

  Map<String, dynamic> toMap() => {
    'vehicleId': vehicleId,
    'date': Timestamp.fromDate(date),
    'distanceKm': distanceKm,
    'fuelQuantity': fuelQuantity,
    'pricePerUnitMinor': pricePerUnitMinor,
    'totalCostMinor': totalCostMinor,
    'odometerKm': odometerKm,
    'notes': notes,
    'transactionId': transactionId,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory FuelLog.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    return FuelLog(
      id: id,
      vehicleId: Codec.string(map['vehicleId']),
      date: Codec.date(map['date']) ?? now,
      distanceKm: Codec.decimal(map['distanceKm']),
      fuelQuantity: Codec.decimal(map['fuelQuantity']),
      pricePerUnitMinor: Codec.integer(map['pricePerUnitMinor']),
      totalCostMinor: Codec.integer(map['totalCostMinor']),
      odometerKm: map['odometerKm'] is num
          ? (map['odometerKm'] as num).toDouble()
          : null,
      notes: Codec.string(map['notes']),
      transactionId: Codec.stringOrNull(map['transactionId']),
      createdAt: Codec.date(map['createdAt']) ?? now,
    );
  }
}

abstract final class VehicleMath {
  /// Distance per unit of fuel, or null when fuel is not positive.
  static double? mileage(double distanceKm, double fuel) =>
      fuel > 0 && distanceKm >= 0 ? distanceKm / fuel : null;

  /// Cost of fuel per km in minor units (fractional), or null without distance.
  static double? costPerKm(int costMinor, double distanceKm) =>
      distanceKm > 0 ? costMinor / distanceKm : null;

  /// Fuel cost of a trip, rounded to the minor unit.
  static int? tripCost({
    required double distanceKm,
    required double mileage,
    required int pricePerUnitMinor,
  }) {
    if (mileage <= 0 || distanceKm < 0) return null;
    return (distanceKm / mileage * pricePerUnitMinor).round();
  }
}

class VehicleStats {
  const VehicleStats({
    required this.averageMileage,
    required this.costPerKmMinor,
    required this.totalDistanceKm,
    required this.totalFuel,
    required this.totalCostMinor,
    required this.thisMonthCostMinor,
    required this.monthlyAverageCostMinor,
    required this.monthlyCost,
  });

  /// Measured from logs, falling back to the vehicle's configured mileage.
  final double? averageMileage;
  final double? costPerKmMinor;
  final double totalDistanceKm;
  final double totalFuel;
  final int totalCostMinor;
  final int thisMonthCostMinor;

  /// Average over the months that have fuel logs in the last 12 months.
  final int monthlyAverageCostMinor;

  /// Cost per month for the last 6 months, oldest first.
  final Map<DateTime, int> monthlyCost;

  int get yearlyEstimateMinor => monthlyAverageCostMinor * 12;

  static VehicleStats compute(
    Vehicle vehicle,
    Iterable<FuelLog> logs,
    DateTime now,
  ) {
    var distance = 0.0, fuel = 0.0, cost = 0, costWithDistance = 0;
    var thisMonth = 0;
    final byMonth = <DateTime, int>{};
    final yearAgo = DateTime(now.year - 1, now.month + 1);
    final lastSix = DateRange.lastMonths(now, 6);
    for (var i = 0; i < 6; i++) {
      byMonth[DateTime(lastSix.start.year, lastSix.start.month + i)] = 0;
    }
    final monthsWithData = <DateTime>{};
    var lastYearCost = 0;

    for (final log in logs) {
      cost += log.totalCostMinor;
      if (log.distanceKm > 0 && log.fuelQuantity > 0) {
        distance += log.distanceKm;
        fuel += log.fuelQuantity;
        costWithDistance += log.totalCostMinor;
      }
      final month = Dates.monthOf(log.date);
      if (Dates.sameMonth(log.date, now)) thisMonth += log.totalCostMinor;
      if (byMonth.containsKey(month)) {
        byMonth[month] = byMonth[month]! + log.totalCostMinor;
      }
      if (!log.date.isBefore(yearAgo)) {
        monthsWithData.add(month);
        lastYearCost += log.totalCostMinor;
      }
    }

    final measured = VehicleMath.mileage(distance, fuel);
    return VehicleStats(
      averageMileage:
          measured ?? (vehicle.mileage > 0 ? vehicle.mileage : null),
      costPerKmMinor: VehicleMath.costPerKm(costWithDistance, distance),
      totalDistanceKm: distance,
      totalFuel: fuel,
      totalCostMinor: cost,
      thisMonthCostMinor: thisMonth,
      monthlyAverageCostMinor: monthsWithData.isEmpty
          ? 0
          : (lastYearCost / monthsWithData.length).round(),
      monthlyCost: byMonth,
    );
  }
}
