import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/money/money.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/features/accounts/application/account_providers.dart';
import 'package:kept/features/credit_cards/application/card_providers.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:kept/features/vehicles/application/vehicle_providers.dart';
import 'package:kept/features/vehicles/domain/vehicle.dart';
import 'package:kept/shared/widgets/charts.dart';
import 'package:kept/shared/widgets/dialogs.dart';
import 'package:kept/shared/widgets/form_fields.dart';
import 'package:kept/shared/widgets/money_text.dart';
import 'package:kept/shared/widgets/section_card.dart';
import 'package:kept/shared/widgets/states.dart';
import 'package:kept/shared/widgets/payment_source_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

String mileageUnit(AppLocalizations l10n, FuelType f) => switch (f) {
  FuelType.electric => l10n.unitKmPerKwh,
  FuelType.cng => l10n.unitKmPerKg,
  _ => l10n.unitKmPerL,
};

String fuelUnit(AppLocalizations l10n, FuelType f) => switch (f) {
  FuelType.electric => l10n.unitKwh,
  FuelType.cng => l10n.unitKg,
  _ => l10n.unitLitre,
};

String _num(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final vehicles = ref.watch(vehiclesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vehiclesTitle),
        actions: [
          IconButton(
            tooltip: l10n.mileageCalculator,
            icon: const Icon(Icons.calculate_rounded),
            onPressed: () => pushPage(context, const MileageCalculatorScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addVehicle),
        onPressed: () => pushPage(context, const VehicleFormScreen()),
      ),
      body: AsyncView<List<Vehicle>>(
        value: vehicles,
        onRetry: () => ref.invalidate(vehiclesProvider),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.directions_car_rounded,
                message: l10n.vehiclesEmpty,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [for (final v in list) _VehicleTile(v)],
              ),
      ),
    );
  }
}

class _VehicleTile extends ConsumerWidget {
  const _VehicleTile(this.vehicle);
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(vehicleStatsProvider(vehicle.id));
    final money = ref.watch(currencyFormatterProvider);
    final mileage = stats?.averageMileage;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () =>
            pushPage(context, VehicleDetailScreen(vehicleId: vehicle.id)),
        leading: CircleAvatar(
          child: Icon(
            vehicle.fuelType == FuelType.electric
                ? Icons.electric_car_rounded
                : Icons.directions_car_rounded,
          ),
        ),
        title: Text(
          vehicle.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (vehicle.registrationNickname.isNotEmpty)
              vehicle.registrationNickname,
            l10n.fuelType(vehicle.fuelType),
            if (mileage != null)
              '${_num(mileage)} ${mileageUnit(l10n, vehicle.fuelType)}',
          ].join(' · '),
        ),
        trailing: stats == null
            ? null
            : Text(money.format(stats.thisMonthCostMinor)),
      ),
    );
  }
}

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.initial});
  final Vehicle? initial;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _reg = TextEditingController(
    text: widget.initial?.registrationNickname,
  );
  late final _price = TextEditingController(
    text: widget.initial == null || widget.initial!.fuelPricePerUnitMinor == 0
        ? ''
        : Money.toEditable(widget.initial!.fuelPricePerUnitMinor),
  );
  late final _mileage = TextEditingController(
    text: widget.initial == null || widget.initial!.mileage == 0
        ? ''
        : '${widget.initial!.mileage}',
  );
  late final _notes = TextEditingController(text: widget.initial?.notes);
  late FuelType _fuel = widget.initial?.fuelType ?? FuelType.petrol;

  @override
  void dispose() {
    for (final c in [_name, _reg, _price, _mileage, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(vehicleRepositoryProvider);
    final now = DateTime.now();
    final initial = widget.initial;
    final price = Money.parse(_price.text) ?? 0;
    final mileage = NumberField.parse(_mileage.text) ?? 0;
    final vehicle = initial == null
        ? Vehicle(
            id: repo.newVehicleId(),
            name: _name.text.trim(),
            registrationNickname: _reg.text.trim(),
            fuelType: _fuel,
            fuelPricePerUnitMinor: price,
            mileage: mileage,
            notes: _notes.text.trim(),
            createdAt: now,
            updatedAt: now,
          )
        : initial.copyWith(
            name: _name.text.trim(),
            registrationNickname: _reg.text.trim(),
            fuelType: _fuel,
            fuelPricePerUnitMinor: price,
            mileage: mileage,
            notes: _notes.text.trim(),
            updatedAt: now,
          );
    repo.saveVehicle(vehicle);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? l10n.newVehicle : l10n.editVehicle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.vehicleName,
                hintText: l10n.vehicleNameHint,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.nameRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reg,
              decoration: InputDecoration(labelText: l10n.registrationNickname),
            ),
            const SizedBox(height: 12),
            PickerField<FuelType>(
              label: l10n.fuelTypeLabel,
              value: _fuel,
              options: [
                for (final f in FuelType.values)
                  PickerOption(f, l10n.fuelType(f)),
              ],
              onChanged: (v) => setState(() => _fuel = v ?? _fuel),
            ),
            const SizedBox(height: 12),
            AmountField(
              controller: _price,
              label: '${l10n.fuelPrice} (${fuelUnit(l10n, _fuel)})',
              required: false,
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _mileage,
              label: l10n.expectedMileage,
              suffix: mileageUnit(l10n, _fuel),
              min: 0,
              max: 1000,
              required: false,
              helper: l10n.expectedMileageHelp,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: l10n.notes),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final vehicle = (ref.watch(vehiclesProvider).value ?? const <Vehicle>[])
        .where((v) => v.id == vehicleId)
        .firstOrNull;
    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.search_off_rounded,
          message: l10n.failureNotFound,
        ),
      );
    }
    final stats = ref.watch(vehicleStatsProvider(vehicleId))!;
    final logs = ref.watch(vehicleFuelLogsProvider(vehicleId));
    final money = ref.watch(currencyFormatterProvider);
    final locale = Localizations.localeOf(context).toString();
    final unit = mileageUnit(l10n, vehicle.fuelType);

    Widget stat(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.name),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () =>
                pushPage(context, VehicleFormScreen(initial: vehicle)),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              if (!await confirmDelete(context, vehicle.name)) return;
              await ref
                  .read(vehicleRepositoryProvider)
                  .deleteVehicle(vehicle.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.local_gas_station_rounded),
        label: Text(l10n.addFuel),
        onPressed: () => showFormSheet(context, FuelLogSheet(vehicle: vehicle)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          SectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    stat(
                      l10n.avgMileage,
                      stats.averageMileage == null
                          ? l10n.noMileageYet
                          : '${_num(stats.averageMileage!)} $unit',
                    ),
                    stat(
                      l10n.costPerKm,
                      stats.costPerKmMinor == null
                          ? l10n.noMileageYet
                          : money.format(stats.costPerKmMinor!.round()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    stat(
                      l10n.fuelThisMonth,
                      money.format(stats.thisMonthCostMinor),
                    ),
                    stat(
                      l10n.fuelMonthlyAverage,
                      money.format(stats.monthlyAverageCostMinor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    stat(
                      l10n.fuelYearlyEstimate,
                      money.format(stats.yearlyEstimateMinor),
                    ),
                    stat(
                      l10n.totalDistance,
                      '${_num(stats.totalDistanceKm)} ${l10n.unitKm}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.fuelCost6m,
            child: MonthlyBarChart(
              aLabel: l10n.totalCost,
              semanticsLabel: l10n.fuelCost6m,
              months: [
                for (final e in stats.monthlyCost.entries)
                  MonthBar(
                    label: DateFormat.MMM(locale).format(e.key),
                    a: e.value,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.fuelLogs,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (logs.isEmpty)
            EmptyState(
              icon: Icons.local_gas_station_rounded,
              message: l10n.fuelLogsEmpty,
              compact: true,
            )
          else
            for (final log in logs)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => showFormSheet(
                    context,
                    FuelLogSheet(vehicle: vehicle, initial: log),
                  ),
                  leading: const Icon(Icons.local_gas_station_rounded),
                  title: MoneyText(
                    log.totalCostMinor,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      DateFormat.yMMMd(locale).format(log.date),
                      '${_num(log.fuelQuantity)} ${fuelUnit(l10n, vehicle.fuelType)}',
                      if (log.distanceKm > 0)
                        '${_num(log.distanceKm)} ${l10n.unitKm}',
                      if (log.mileage != null && log.distanceKm > 0)
                        '${_num(log.mileage!)} $unit',
                    ].join(' · '),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Add or edit a fuel fill. Total cost is derived from quantity × price
/// unless the user overrides it.
class FuelLogSheet extends ConsumerStatefulWidget {
  const FuelLogSheet({super.key, required this.vehicle, this.initial});
  final Vehicle vehicle;
  final FuelLog? initial;

  @override
  ConsumerState<FuelLogSheet> createState() => _FuelLogSheetState();
}

class _FuelLogSheetState extends ConsumerState<FuelLogSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _distance = TextEditingController(
    text: widget.initial == null || widget.initial!.distanceKm == 0
        ? ''
        : _num(widget.initial!.distanceKm),
  );
  late final _quantity = TextEditingController(
    text: widget.initial == null ? '' : '${widget.initial!.fuelQuantity}',
  );
  late final _price = TextEditingController(
    text: Money.toEditable(
      widget.initial?.pricePerUnitMinor ?? widget.vehicle.fuelPricePerUnitMinor,
    ),
  );
  late final _total = TextEditingController(
    text: widget.initial == null
        ? ''
        : Money.toEditable(widget.initial!.totalCostMinor),
  );
  late final _odometer = TextEditingController(
    text: widget.initial?.odometerKm == null
        ? ''
        : _num(widget.initial!.odometerKm!),
  );
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  PaymentSource? _payment;
  String? _payError;
  bool _totalEdited = false;

  @override
  void initState() {
    super.initState();
    _totalEdited = widget.initial != null;
    // An existing fill with no linked expense was deliberately not recorded.
    if (widget.initial != null && widget.initial!.transactionId == null) {
      _payment = const CashSource();
    }
    // Start from the expense already linked to this fill, so saving an edit
    // keeps it instead of removing it.
    final linkedId = widget.initial?.transactionId;
    if (linkedId != null) {
      ref.read(transactionRepositoryProvider).fetch(linkedId).then((tx) {
        if (!mounted || tx == null) return;
        setState(() {
          _payment = tx.creditCardId != null
              ? CardSource(tx.creditCardId!)
              : tx.accountId != null
              ? AccountSource(tx.accountId!)
              : const CashSource();
        });
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_distance, _quantity, _price, _total, _odometer]) {
      c.dispose();
    }
    super.dispose();
  }

  void _recalc() {
    if (_totalEdited) return;
    final qty = NumberField.parse(_quantity.text);
    final price = Money.parse(_price.text);
    if (qty != null && price != null) {
      _total.text = Money.toEditable((qty * price).round());
    }
  }

  /// Prefills distance from the previous fill's odometer reading.
  void _onOdometer(String text) {
    final reading = NumberField.parse(text);
    if (reading == null) return;
    final logs = ref.read(vehicleFuelLogsProvider(widget.vehicle.id));
    final previous = logs
        .where(
          (l) =>
              l.id != widget.initial?.id &&
              l.odometerKm != null &&
              l.date.isBefore(_date),
        )
        .firstOrNull;
    if (previous != null && reading > previous.odometerKm!) {
      _distance.text = _num(reading - previous.odometerKm!);
    }
  }

  // Guards against a double tap while the save awaits the network, which
  // would otherwise write the record (and its account movement) twice.
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _persist();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _persist() async {
    if (!_formKey.currentState!.validate()) return;
    final hasSources =
        ref.read(activeAccountsProvider).isNotEmpty ||
        ref.read(activeCardsProvider).isNotEmpty;
    if (_payment == null && hasSources) {
      setState(() => _payError = context.l10n.paymentRequired);
      return;
    }
    final repo = ref.read(vehicleRepositoryProvider);
    final payment = _payment;
    final log = FuelLog(
      id: widget.initial?.id ?? repo.newFuelLogId(),
      vehicleId: widget.vehicle.id,
      date: _date,
      distanceKm: NumberField.parse(_distance.text) ?? 0,
      fuelQuantity: NumberField.parse(_quantity.text)!,
      pricePerUnitMinor: Money.parse(_price.text) ?? 0,
      totalCostMinor: Money.parse(_total.text)!,
      odometerKm: NumberField.parse(_odometer.text),
      createdAt: widget.initial?.createdAt ?? DateTime.now(),
    );
    final navigator = Navigator.of(context);
    await repo.saveFuelLog(
      log,
      vehicleName: widget.vehicle.name,
      accountId: payment?.accountId,
      creditCardId: payment?.cardId,
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts = ref.watch(activeAccountsProvider);
    final cards = ref.watch(activeCardsProvider);
    final unit = fuelUnit(l10n, widget.vehicle.fuelType);
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.initial == null ? l10n.addFuel : l10n.editFuel,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (widget.initial != null)
                  IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      if (!await confirmDelete(context, l10n.addFuel)) return;
                      await ref
                          .read(vehicleRepositoryProvider)
                          .deleteFuelLog(widget.initial!);
                      navigator.pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DateField(
              label: l10n.date,
              value: _date,
              onChanged: (d) => setState(() => _date = d ?? _date),
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _odometer,
              label: l10n.odometer,
              suffix: l10n.unitKm,
              min: 0,
              required: false,
              onChanged: _onOdometer,
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _distance,
              label: l10n.distanceTravelled,
              suffix: l10n.unitKm,
              min: 0,
              max: 100000,
              required: false,
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _quantity,
              label: l10n.fuelQuantity,
              suffix: unit,
              min: 0.01,
              max: 10000,
              onChanged: (_) => setState(_recalc),
            ),
            const SizedBox(height: 12),
            AmountField(
              controller: _price,
              label: '${l10n.pricePerUnit} ($unit)',
              required: false,
              onChanged: (_) => setState(_recalc),
            ),
            const SizedBox(height: 12),
            AmountField(
              controller: _total,
              label: l10n.totalCost,
              onChanged: (_) => _totalEdited = true,
            ),
            const SizedBox(height: 12),
            PaymentSourceField(
              label: l10n.recordAsExpense,
              value: _payment,
              accounts: accounts,
              cards: cards,
              cashLabel: l10n.dontRecord,
              errorText: _payError,
              onChanged: (v) => setState(() {
                _payment = v;
                _payError = null;
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                l10n.vehicleFuelExpenseNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _saving ? null : _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

class MileageCalculatorScreen extends ConsumerStatefulWidget {
  const MileageCalculatorScreen({super.key});

  @override
  ConsumerState<MileageCalculatorScreen> createState() =>
      _MileageCalculatorScreenState();
}

class _MileageCalculatorScreenState
    extends ConsumerState<MileageCalculatorScreen> {
  final _distance = TextEditingController();
  final _fuel = TextEditingController();
  final _price = TextEditingController();
  final _trip = TextEditingController();

  @override
  void dispose() {
    for (final c in [_distance, _fuel, _price, _trip]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = ref.watch(currencyFormatterProvider);
    final distance = NumberField.parse(_distance.text);
    final fuel = NumberField.parse(_fuel.text);
    final price = Money.parse(_price.text);
    final trip = NumberField.parse(_trip.text);
    final mileage = distance == null || fuel == null
        ? null
        : VehicleMath.mileage(distance, fuel);
    final perKm = mileage == null || price == null || mileage == 0
        ? null
        : price / mileage;
    final tripCost = mileage == null || price == null || trip == null
        ? null
        : VehicleMath.tripCost(
            distanceKm: trip,
            mileage: mileage,
            pricePerUnitMinor: price,
          );
    void refresh(String _) => setState(() {});
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mileageCalculator)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NumberField(
            controller: _distance,
            label: l10n.distanceTravelled,
            suffix: l10n.unitKm,
            min: 0,
            onChanged: refresh,
          ),
          const SizedBox(height: 12),
          NumberField(
            controller: _fuel,
            label: l10n.fuelQuantity,
            suffix: l10n.unitLitre,
            min: 0.01,
            onChanged: refresh,
          ),
          const SizedBox(height: 12),
          AmountField(
            controller: _price,
            label: l10n.pricePerUnit,
            required: false,
            onChanged: refresh,
          ),
          const SizedBox(height: 12),
          NumberField(
            controller: _trip,
            label: l10n.tripDistance,
            suffix: l10n.unitKm,
            min: 0,
            required: false,
            onChanged: refresh,
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.mileageResult,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mileage == null
                      ? l10n.calcEnterValues
                      : '${mileage.toStringAsFixed(2)} ${l10n.unitKmPerL}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (perKm != null) ...[
                  const SizedBox(height: 8),
                  Text('${l10n.calcCostPerKm}: ${money.format(perKm.round())}'),
                ],
                if (tripCost != null)
                  Text('${l10n.tripCost}: ${money.format(tripCost)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
