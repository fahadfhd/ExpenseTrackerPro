import 'package:kept/core/notifications/notification_planner.dart';
import 'package:kept/core/utils/recurrence.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/budgets/domain/budget.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/recurring/domain/recurring_rule.dart';
import 'package:kept/features/reminders/domain/reminder.dart';
import 'package:kept/features/transactions/domain/monthly_summary.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:kept/features/vehicles/domain/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

final _t = DateTime(2026, 1, 1);

CreditCard _card({int limit = 10000000, int opening = 0, int delta = 0}) =>
    CreditCard(
      id: 'c',
      name: 'Card',
      creditLimitMinor: limit,
      openingOutstandingMinor: opening,
      statementDay: 20,
      dueDay: 8,
      createdAt: _t,
      updatedAt: _t,
    ).copyWith().withDelta(delta);

extension on CreditCard {
  CreditCard withDelta(int delta) =>
      CreditCard.fromMap(id, {...toMap(), 'ledgerDeltaMinor': delta});
}

void main() {
  group('CreditCard', () {
    test('utilization and available credit', () {
      final card = _card(opening: 2000000, delta: 500000);
      expect(card.outstandingMinor, 2500000);
      expect(card.availableMinor, 7500000);
      expect(card.utilization, closeTo(.25, 1e-9));
    });

    test('credit balance never inflates available above limit', () {
      final card = _card(opening: -100000);
      expect(card.availableMinor, 10000000);
      expect(card.utilization, 0);
    });

    test('over-limit utilization exceeds 100%', () {
      expect(_card(opening: 12000000).utilization, closeTo(1.2, 1e-9));
      expect(_card(opening: 12000000).availableMinor, 0);
    });

    test('statement and due dates', () {
      final card = _card();
      expect(
        card.lastStatementDate(DateTime(2026, 3, 25)),
        DateTime(2026, 3, 20),
      );
      expect(
        card.lastStatementDate(DateTime(2026, 3, 5)),
        DateTime(2026, 2, 20),
      );
      expect(card.nextDueDate(DateTime(2026, 3, 5)), DateTime(2026, 3, 8));
      expect(card.nextDueDate(DateTime(2026, 3, 9)), DateTime(2026, 4, 8));
      final status = CardStatus.compute(
        card: _card(opening: 500000),
        now: DateTime(2026, 3, 25),
        chargesSince: 100000,
        paymentsSince: 10000,
      );
      // statement balance = 5000 − 1000 + 100 = 4100; due = 4100 − 100
      expect(status.statementBalanceMinor, 410000);
      expect(status.totalDueMinor, 400000);
      expect(status.minimumDueMinor, (410000 * .05).ceil() - 10000);
      // Payments beyond the minimum leave nothing minimum-due.
      expect(
        CardStatus.compute(
          card: _card(opening: 500000),
          now: DateTime(2026, 3, 25),
          chargesSince: 0,
          paymentsSince: 50000,
        ).minimumDueMinor,
        0,
      );
      expect(status.dueDate, DateTime(2026, 4, 8));
    });

    test('last4 must be exactly four digits', () {
      final card = CreditCard.fromMap('c', {'last4': '12345', 'name': 'x'});
      expect(card.last4, '');
    });
  });

  group('Budget', () {
    final budget = Budget(
      id: Budget.idFor('food'),
      categoryId: 'food',
      amountMinor: 800000,
      createdAt: _t,
      updatedAt: _t,
    );

    test('usage uses category spending and reports thresholds', () {
      const summary = MonthlySummary(
        income: 0,
        spending: 1000000,
        emi: 0,
        cardSpending: 0,
        borrowed: 0,
        lent: 0,
        pending: 0,
        byCategory: {'food': 720000},
        byDay: {},
        byAccount: {},
        byCard: {},
        transactionCount: 0,
      );
      final usage = BudgetCalculator.usage([budget], summary).single;
      expect(usage.spentMinor, 720000);
      expect(usage.remainingMinor, 80000);
      expect(usage.percent, 90);
      expect(usage.reachedThreshold, 90);
      expect(usage.isOver, isFalse);
    });

    test('crossedThreshold reports the highest newly crossed threshold', () {
      expect(BudgetCalculator.crossedThreshold(budget, 500000, 610000), 75);
      expect(BudgetCalculator.crossedThreshold(budget, 500000, 900000), 100);
      expect(BudgetCalculator.crossedThreshold(budget, 610000, 650000), isNull);
    });
  });

  group('Vehicle', () {
    test('mileage, cost per km and trip cost', () {
      expect(VehicleMath.mileage(450, 30), 15);
      expect(VehicleMath.mileage(450, 0), isNull);
      expect(VehicleMath.costPerKm(300000, 450), closeTo(666.67, .01));
      expect(
        VehicleMath.tripCost(
          distanceKm: 150,
          mileage: 15,
          pricePerUnitMinor: 10250,
        ),
        102500,
      );
    });

    test('stats aggregate logs', () {
      final vehicle = Vehicle(
        id: 'v',
        name: 'Car',
        fuelType: FuelType.petrol,
        createdAt: _t,
        updatedAt: _t,
      );
      FuelLog log(DateTime d, double km, double l, int cost) => FuelLog(
        id: '$d',
        vehicleId: 'v',
        date: d,
        distanceKm: km,
        fuelQuantity: l,
        pricePerUnitMinor: 10000,
        totalCostMinor: cost,
        createdAt: d,
      );
      final stats = VehicleStats.compute(vehicle, [
        log(DateTime(2026, 2, 3), 300, 20, 200000),
        log(DateTime(2026, 3, 3), 450, 30, 300000),
        log(DateTime(2026, 3, 20), 0, 10, 100000), // no distance: cost only
      ], DateTime(2026, 3, 25));
      expect(stats.averageMileage, 15);
      expect(stats.costPerKmMinor, closeTo(500000 / 750, 1e-9));
      expect(stats.thisMonthCostMinor, 400000);
      expect(stats.monthlyAverageCostMinor, 300000);
      expect(stats.yearlyEstimateMinor, 3600000);
      expect(stats.monthlyCost[DateTime(2026, 3)], 400000);
    });
  });

  group('Borrow/Lend', () {
    DebtRecord record(
      DebtDirection d,
      int amount, {
      DateTime? due,
      List<int> paid = const [],
    }) => DebtRecord(
      id: '$d$amount',
      direction: d,
      personName: 'Asha',
      amountMinor: amount,
      date: _t,
      dueDate: due,
      settlements: [
        for (final p in paid) Settlement(id: '$p', amountMinor: p, date: _t),
      ],
      createdAt: _t,
      updatedAt: _t,
    );

    test('status follows settlements and due date', () {
      final now = DateTime(2026, 5, 1);
      expect(
        record(DebtDirection.lent, 1000).statusAt(now),
        DebtStatus.pending,
      );
      expect(
        record(DebtDirection.lent, 1000, paid: [400]).statusAt(now),
        DebtStatus.partiallySettled,
      );
      expect(
        record(DebtDirection.lent, 1000, paid: [400, 600]).statusAt(now),
        DebtStatus.settled,
      );
      expect(
        record(
          DebtDirection.lent,
          1000,
          due: DateTime(2026, 4, 30),
        ).statusAt(now),
        DebtStatus.overdue,
      );
      expect(
        record(
          DebtDirection.lent,
          1000,
          due: DateTime(2026, 5, 1),
        ).statusAt(now),
        DebtStatus.pending,
      );
    });

    test('outstanding never goes negative on over-settlement', () {
      expect(
        record(DebtDirection.borrowed, 1000, paid: [1500]).outstandingMinor,
        0,
      );
    });

    test('summary totals by direction', () {
      final s = DebtSummary.compute([
        record(DebtDirection.borrowed, 5000, paid: [1000]),
        record(DebtDirection.lent, 3000, due: DateTime(2026, 1, 2)),
        record(DebtDirection.lent, 2000, paid: [2000]),
      ], DateTime(2026, 2, 1));
      expect(s.borrowedTotalMinor, 5000);
      expect(s.lentTotalMinor, 5000);
      expect(s.iOweMinor, 4000);
      expect(s.owedToMeMinor, 3000);
      expect(s.overdueMinor, 3000);
      expect(s.openCount, 2);
    });
  });

  group('Recurrence', () {
    test('monthly on the 31st clamps to month end', () {
      const r = Recurrence(frequency: RecurrenceFrequency.monthly);
      final dates = r
          .between(
            DateTime(2026, 1, 31, 9),
            DateTime(2026, 1, 1),
            DateTime(2026, 5, 1),
          )
          .toList();
      expect(dates, [
        DateTime(2026, 1, 31, 9),
        DateTime(2026, 2, 28, 9),
        DateTime(2026, 3, 31, 9),
        DateTime(2026, 4, 30, 9),
      ]);
    });

    test('weekly with interval and until', () {
      final r = Recurrence(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        until: DateTime(2026, 2, 1),
      );
      expect(
        r
            .between(
              DateTime(2026, 1, 1),
              DateTime(2025, 1, 1),
              DateTime(2027, 1, 1),
            )
            .toList(),
        [DateTime(2026, 1, 1), DateTime(2026, 1, 15), DateTime(2026, 1, 29)],
      );
    });

    test('jumps ahead efficiently from far anchors', () {
      const r = Recurrence(frequency: RecurrenceFrequency.daily);
      expect(
        r.nextFrom(DateTime(2000, 1, 1, 7), DateTime(2026, 6, 1, 8)),
        DateTime(2026, 6, 2, 7),
      );
    });

    test('yearly on Feb 29 falls back to Feb 28', () {
      const r = Recurrence(frequency: RecurrenceFrequency.yearly);
      expect(r.nth(DateTime(2028, 2, 29), 1), DateTime(2029, 2, 28));
    });
  });

  group('RecurringRule', () {
    RecurringRule rule({DateTime? last}) => RecurringRule(
      id: 'rent',
      title: 'Rent',
      type: TransactionType.expense,
      amountMinor: 1500000,
      categoryId: 'housing',
      accountId: 'a',
      startDate: DateTime(2026, 1, 5),
      recurrence: const Recurrence(frequency: RecurrenceFrequency.monthly),
      lastGeneratedDate: last,
      createdAt: _t,
      updatedAt: _t,
    );

    test('generates each missed occurrence once', () {
      final due = rule().dueOccurrences(DateTime(2026, 3, 10));
      expect(due, [
        DateTime(2026, 1, 5),
        DateTime(2026, 2, 5),
        DateTime(2026, 3, 5),
      ]);
      expect(
        rule(last: DateTime(2026, 3, 5)).dueOccurrences(DateTime(2026, 3, 10)),
        isEmpty,
      );
      expect(
        rule(last: DateTime(2026, 2, 5)).dueOccurrences(DateTime(2026, 3, 10)),
        [DateTime(2026, 3, 5)],
      );
    });

    test('occurrence transactions have deterministic ids', () {
      final r = rule();
      final a = r.transactionFor(DateTime(2026, 2, 5), _t);
      final b = r.transactionFor(DateTime(2026, 2, 5), DateTime(2027));
      expect(a.id, b.id);
      expect(a.id, 'rec_rent_20260205');
      expect(a.recurringRuleId, 'rent');
      expect(a.amountMinor, 1500000);
    });

    test('upcoming lists the next occurrences', () {
      expect(
        rule(
          last: DateTime(2026, 3, 5),
        ).upcoming(DateTime(2026, 3, 10), count: 2),
        [DateTime(2026, 4, 5), DateTime(2026, 5, 5)],
      );
    });
  });

  group('NotificationPlanner', () {
    Reminder reminder({
      String id = 'r',
      Recurrence recurrence = Recurrence.none,
      List<int> offsets = const [0],
      bool enabled = true,
      DateTime? date,
    }) => Reminder(
      id: id,
      title: 'Pay',
      type: ReminderType.custom,
      date: date ?? DateTime(2026, 3, 20),
      hour: 19,
      minute: 0,
      recurrence: recurrence,
      offsetsMinutes: offsets,
      enabled: enabled,
      createdAt: _t,
      updatedAt: _t,
    );
    String body(Reminder r, int o) => 'o$o';

    test('expands offsets and skips past fire times', () {
      final plan = NotificationPlanner.plan(
        [reminder(offsets: defaultDueOffsetsMinutes)],
        now: DateTime(2026, 3, 15),
        bodyFor: body,
      );
      // 7 days before (Mar 13) is already past.
      expect(plan.map((p) => p.fireAt), [
        DateTime(2026, 3, 18, 19),
        DateTime(2026, 3, 19, 19),
        DateTime(2026, 3, 20, 19),
      ]);
    });

    test('ids are deterministic and unique', () {
      final r = reminder(
        recurrence: const Recurrence(frequency: RecurrenceFrequency.daily),
      );
      final a = NotificationPlanner.plan(
        [r],
        now: DateTime(2026, 3, 21),
        bodyFor: body,
      );
      final b = NotificationPlanner.plan(
        [r],
        now: DateTime(2026, 3, 21),
        bodyFor: body,
      );
      expect(a.map((p) => p.id), b.map((p) => p.id));
      expect(a.map((p) => p.id).toSet(), hasLength(a.length));
    });

    test('caps the number of pending notifications and keeps the soonest', () {
      final plan = NotificationPlanner.plan(
        [
          reminder(
            recurrence: const Recurrence(frequency: RecurrenceFrequency.daily),
            offsets: [0, 60],
          ),
        ],
        now: DateTime(2026, 3, 21),
        bodyFor: body,
      );
      expect(plan, hasLength(NotificationPlanner.maxPending));
      expect(plan.first.fireAt, DateTime(2026, 3, 21, 18));
    });

    test('disabled reminders are not scheduled', () {
      expect(
        NotificationPlanner.plan(
          [reminder(enabled: false)],
          now: DateTime(2026, 3, 1),
          bodyFor: body,
        ),
        isEmpty,
      );
    });

    test('monthly reminder with early offset crosses month boundaries', () {
      final plan = NotificationPlanner.plan(
        [
          reminder(
            date: DateTime(2026, 1, 3),
            recurrence: const Recurrence(
              frequency: RecurrenceFrequency.monthly,
            ),
            offsets: [7 * 1440],
          ),
        ],
        now: DateTime(2026, 3, 1),
        window: const Duration(days: 40),
        bodyFor: body,
      );
      expect(plan.map((p) => p.fireAt), [DateTime(2026, 3, 27, 19)]);
      expect(plan.single.occurrence, DateTime(2026, 4, 3, 19));
    });
  });
}
