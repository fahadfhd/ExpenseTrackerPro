import 'dart:ui' show PlatformDispatcher;

import 'package:kept/core/errors/app_failure.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/utils/recurrence.dart';
import 'package:kept/features/accounts/domain/account.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/loans/domain/amortization.dart';
import 'package:kept/features/loans/domain/emi_engine.dart';
import 'package:kept/features/loans/domain/loan.dart';
import 'package:kept/features/reminders/domain/reminder.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:kept/features/transactions/domain/transaction_query.dart';
import 'package:kept/features/transactions/domain/transaction_validator.dart';
import 'package:kept/features/vehicles/domain/vehicle.dart';
import 'package:kept/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:kept/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The app's resolved locale, usable outside the widget tree (notification
/// text, search indexes, default reminder titles).
final appLocaleProvider = Provider<Locale>((ref) {
  final preferred =
      ref.watch(settingsProvider.select((s) => s.locale)) ??
      PlatformDispatcher.instance.locale;
  return AppLocalizations.supportedLocales.firstWhere(
    (l) => l.languageCode == preferred.languageCode,
    orElse: () => AppLocalizations.supportedLocales.first,
  );
});

/// A language's name in its own script, so people can find theirs even when
/// the app is currently showing a language they cannot read.
String languageNativeName(String languageCode) => switch (languageCode) {
  'en' => 'English',
  'ml' => 'മലയാളം',
  _ => languageCode.toUpperCase(),
};

final l10nProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(ref.watch(appLocaleProvider)),
);

/// Localized labels for domain enums and ids. Kept in one place so domain
/// classes stay free of UI strings.
extension DomainLabels on AppLocalizations {
  String categoryLabel(String? id) =>
      Categories.customName(id) ?? _builtInCategoryLabel(id);

  String _builtInCategoryLabel(String? id) => switch (id) {
    'food' => catFood,
    'food.groceries' => catFoodGroceries,
    'food.dining' => catFoodDining,
    'food.delivery' => catFoodDelivery,
    'transport' => catTransport,
    'transport.fuel' => catTransportFuel,
    'transport.public' => catTransportPublic,
    'transport.cab' => catTransportCab,
    'transport.parking' => catTransportParking,
    'transport.service' => catTransportService,
    'shopping' => catShopping,
    'shopping.clothing' => catShoppingClothing,
    'shopping.electronics' => catShoppingElectronics,
    'shopping.home' => catShoppingHome,
    'bills' => catBills,
    'bills.electricity' => catBillsElectricity,
    'bills.water' => catBillsWater,
    'bills.internet' => catBillsInternet,
    'bills.phone' => catBillsPhone,
    'housing' => catHousing,
    'housing.rent' => catHousingRent,
    'housing.maintenance' => catHousingMaintenance,
    'health' => catHealth,
    'health.medical' => catHealthMedical,
    'health.pharmacy' => catHealthPharmacy,
    'health.fitness' => catHealthFitness,
    'entertainment' => catEntertainment,
    'entertainment.subscriptions' => catEntertainmentSubscriptions,
    'entertainment.outings' => catEntertainmentOutings,
    'entertainment.travel' => catEntertainmentTravel,
    'education' => catEducation,
    'insurance' => catInsurance,
    'personal' => catPersonal,
    'gifts' => catGifts,
    'fees' => catFees,
    'salary' => catSalary,
    'business' => catBusiness,
    'interest' => catInterest,
    'investment' => catInvestment,
    'gift_income' => catGiftIncome,
    'other_income' => catOtherIncome,
    'transfer' => catTransfer,
    'debt' => catDebt,
    'loan_emi' => catLoanEmi,
    'card_payment' => catCardPayment,
    _ => catOther,
  };

  String transactionType(TransactionType t) => switch (t) {
    TransactionType.expense => txTypeExpense,
    TransactionType.income => txTypeIncome,
    TransactionType.transfer => txTypeTransfer,
    TransactionType.creditCardExpense => txTypeCreditCardExpense,
    TransactionType.creditCardPayment => txTypeCreditCardPayment,
    TransactionType.loanPayment => txTypeLoanPayment,
    TransactionType.refund => txTypeRefund,
    TransactionType.borrowed => txTypeBorrowed,
    TransactionType.lent => txTypeLent,
    TransactionType.debtRepayment => txTypeDebtRepayment,
    TransactionType.debtCollection => txTypeDebtCollection,
  };

  String transactionStatus(TransactionStatus s) => switch (s) {
    TransactionStatus.cleared => txStatusCleared,
    TransactionStatus.pending => txStatusPending,
  };

  String accountType(AccountType t) => switch (t) {
    AccountType.savings => accountTypeSavings,
    AccountType.current => accountTypeCurrent,
    AccountType.cash => accountTypeCash,
    AccountType.wallet => accountTypeWallet,
    AccountType.other => accountTypeOther,
  };

  String recurrence(Recurrence r) {
    final n = '${r.interval}';
    return switch (r.frequency) {
      RecurrenceFrequency.once => freqOnce,
      RecurrenceFrequency.daily => r.interval == 1 ? freqDaily : everyNDays(n),
      RecurrenceFrequency.weekly =>
        r.interval == 1 ? freqWeekly : everyNWeeks(n),
      RecurrenceFrequency.monthly =>
        r.interval == 1 ? freqMonthly : everyNMonths(n),
      RecurrenceFrequency.yearly =>
        r.interval == 1 ? freqYearly : everyNYears(n),
    };
  }

  String frequency(RecurrenceFrequency f) =>
      recurrence(Recurrence(frequency: f));

  String emiFrequency(EmiFrequency f) => switch (f) {
    EmiFrequency.monthly => freqMonthly,
    EmiFrequency.quarterly => freqQuarterly,
    EmiFrequency.halfYearly => freqHalfYearly,
    EmiFrequency.yearly => freqYearly,
  };

  String loanStatus(LoanStatus s) => switch (s) {
    LoanStatus.active => loanStatusActive,
    LoanStatus.completed => loanStatusCompleted,
    LoanStatus.closed => loanStatusClosed,
    LoanStatus.prepaid => loanStatusPrepaid,
  };

  String installmentStatus(InstallmentStatus s) => switch (s) {
    InstallmentStatus.paid => installmentPaid,
    InstallmentStatus.skipped => installmentSkipped,
    InstallmentStatus.overdue => installmentOverdue,
    InstallmentStatus.upcoming => installmentUpcoming,
  };

  String debtStatus(DebtStatus s) => switch (s) {
    DebtStatus.pending => debtPending,
    DebtStatus.partiallySettled => debtPartial,
    DebtStatus.settled => debtSettled,
    DebtStatus.overdue => debtOverdue,
  };

  String debtDirection(DebtDirection d) => switch (d) {
    DebtDirection.borrowed => debtBorrowed,
    DebtDirection.lent => debtLent,
  };

  String reminderType(ReminderType t) => switch (t) {
    ReminderType.loanEmi => reminderTypeLoanEmi,
    ReminderType.creditCardPayment => reminderTypeCreditCard,
    ReminderType.borrowed => reminderTypeBorrowed,
    ReminderType.lent => reminderTypeLent,
    ReminderType.gym => reminderTypeGym,
    ReminderType.meeting => reminderTypeMeeting,
    ReminderType.insurance => reminderTypeInsurance,
    ReminderType.subscription => reminderTypeSubscription,
    ReminderType.bill => reminderTypeBill,
    ReminderType.custom => reminderTypeCustom,
  };

  String fuelType(FuelType t) => switch (t) {
    FuelType.petrol => fuelPetrol,
    FuelType.diesel => fuelDiesel,
    FuelType.cng => fuelCng,
    FuelType.lpg => fuelLpg,
    FuelType.electric => fuelElectric,
    FuelType.hybrid => fuelHybrid,
  };

  String sort(TransactionSort s) => switch (s) {
    TransactionSort.newest => sortNewest,
    TransactionSort.oldest => sortOldest,
    TransactionSort.largest => sortLargest,
    TransactionSort.smallest => sortSmallest,
  };

  String issue(TransactionIssue i) => switch (i) {
    TransactionIssue.amountNotPositive => issueAmountNotPositive,
    TransactionIssue.amountTooLarge => issueAmountTooLarge,
    TransactionIssue.categoryMismatch => issueCategoryMismatch,
    TransactionIssue.cardRequired => issueCardRequired,
    TransactionIssue.cardNotAllowed => issueCardNotAllowed,
    TransactionIssue.sourceAccountRequired => issueSourceAccountRequired,
    TransactionIssue.destinationAccountRequired =>
      issueDestinationAccountRequired,
    TransactionIssue.sameTransferAccounts => issueSameTransferAccounts,
    TransactionIssue.loanRequired => issueLoanRequired,
    TransactionIssue.debtRecordRequired => issueDebtRecordRequired,
    TransactionIssue.refundTargetAmbiguous => issueRefundTargetAmbiguous,
  };

  /// User-facing message for any error; never exposes raw exceptions.
  String failure(Object error) => switch (AppFailure.from(error).kind) {
    FailureKind.network => failureNetwork,
    FailureKind.permissionDenied => failurePermission,
    FailureKind.unauthenticated => failureUnauthenticated,
    FailureKind.signInMethodDisabled => failureSignInMethodDisabled,
    FailureKind.notFound => failureNotFound,
    FailureKind.invalidData => failureInvalidData,
    FailureKind.unsupportedSchema => failureUnsupportedSchema,
    FailureKind.notificationScheduling => failureNotification,
    FailureKind.unknown => failureUnknown,
  };
}
