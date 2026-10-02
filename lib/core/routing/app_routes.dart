import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/features/accounts/domain/account.dart';
import 'package:expensetrackerpro/features/accounts/presentation/account_detail_screen.dart';
import 'package:expensetrackerpro/features/accounts/presentation/account_form_screen.dart';
import 'package:expensetrackerpro/features/borrow_lend/presentation/borrow_lend_screen.dart';
import 'package:expensetrackerpro/features/budgets/presentation/budgets_screen.dart';
import 'package:expensetrackerpro/features/credit_cards/domain/credit_card.dart';
import 'package:expensetrackerpro/features/credit_cards/presentation/card_detail_screen.dart';
import 'package:expensetrackerpro/features/credit_cards/presentation/card_form_screen.dart';
import 'package:expensetrackerpro/features/dashboard/application/upcoming_provider.dart';
import 'package:expensetrackerpro/features/loans/domain/loan.dart';
import 'package:expensetrackerpro/features/loans/presentation/emi_calculator_screen.dart';
import 'package:expensetrackerpro/features/loans/presentation/loan_detail_screen.dart';
import 'package:expensetrackerpro/features/loans/presentation/loan_form_screen.dart';
import 'package:expensetrackerpro/features/recurring/presentation/recurring_screen.dart';
import 'package:expensetrackerpro/features/reminders/presentation/reminders_screen.dart';
import 'package:expensetrackerpro/features/reports/presentation/reports_screen.dart';
import 'package:expensetrackerpro/features/search/presentation/search_screen.dart';
import 'package:expensetrackerpro/features/settings/presentation/settings_screen.dart';
import 'package:expensetrackerpro/features/vehicles/presentation/vehicles_screen.dart';
import 'package:expensetrackerpro/shared/widgets/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Primary destinations of the bottom navigation.
enum ShellTab { home, transactions, accounts, loans, more }

class ShellTabNotifier extends Notifier<ShellTab> {
  @override
  ShellTab build() {
    ref.watch(uidProvider);
    return ShellTab.home;
  }

  void select(ShellTab tab) => state = tab;
}

final shellTabProvider = NotifierProvider<ShellTabNotifier, ShellTab>(
  ShellTabNotifier.new,
);

/// Every secondary screen is opened through here, so navigation stays in
/// one place and screens don't import each other.
abstract final class AppRoutes {
  static Future<void> account(BuildContext c, String id) =>
      pushPage(c, AccountDetailScreen(accountId: id));

  static Future<void> newAccount(BuildContext c) =>
      pushPage(c, const AccountFormScreen());

  static Future<void> editAccount(BuildContext c, Account a) =>
      pushPage(c, AccountFormScreen(initial: a));

  static Future<void> card(BuildContext c, String id) =>
      pushPage(c, CardDetailScreen(cardId: id));

  static Future<void> newCard(BuildContext c) =>
      pushPage(c, const CardFormScreen());

  static Future<void> editCard(BuildContext c, CreditCard card) =>
      pushPage(c, CardFormScreen(initial: card));

  static Future<void> loan(BuildContext c, String id) =>
      pushPage(c, LoanDetailScreen(loanId: id));

  static Future<void> newLoan(BuildContext c) =>
      pushPage(c, const LoanFormScreen());

  static Future<void> editLoan(BuildContext c, Loan loan) =>
      pushPage(c, LoanFormScreen(initial: loan));

  static Future<void> emiCalculator(BuildContext c) =>
      pushPage(c, const EmiCalculatorScreen());

  static Future<void> borrowLend(BuildContext c) =>
      pushPage(c, const BorrowLendScreen());

  static Future<void> debt(BuildContext c, String id) =>
      pushPage(c, DebtDetailScreen(recordId: id));

  static Future<void> reminders(BuildContext c) =>
      pushPage(c, const RemindersScreen());

  static Future<void> vehicles(BuildContext c) =>
      pushPage(c, const VehiclesScreen());

  static Future<void> mileageCalculator(BuildContext c) =>
      pushPage(c, const MileageCalculatorScreen());

  static Future<void> budgets(BuildContext c) =>
      pushPage(c, const BudgetsScreen());

  static Future<void> recurring(BuildContext c) =>
      pushPage(c, const RecurringScreen());

  static Future<void> reports(BuildContext c) =>
      pushPage(c, const ReportsScreen());

  static Future<void> search(BuildContext c) =>
      pushPage(c, const SearchScreen());

  static Future<void> settings(BuildContext c) =>
      pushPage(c, const SettingsScreen());

  static Future<void> upcoming(BuildContext c, UpcomingItem item) =>
      switch (item.kind) {
        UpcomingKind.card => card(c, item.entityId),
        UpcomingKind.loan => loan(c, item.entityId),
        UpcomingKind.borrowed || UpcomingKind.lent => debt(c, item.entityId),
        UpcomingKind.reminder => reminders(c),
      };
}
