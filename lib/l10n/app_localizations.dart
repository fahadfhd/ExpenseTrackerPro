import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ml.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ml'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get appTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDate;

  /// No description provided for @pickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get pickTime;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDate;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {item}?'**
  String deleteConfirmTitle(String item);

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteConfirmBody;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyTitle;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount greater than zero'**
  String get invalidAmount;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get invalidNumber;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get nameRequired;

  /// No description provided for @valueBetween.
  ///
  /// In en, this message translates to:
  /// **'Enter a value between {min} and {max}'**
  String valueBetween(String min, String max);

  /// No description provided for @comingFromInstallments.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total}'**
  String comingFromInstallments(String count, String total);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// No description provided for @navLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get navLoans;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @failureNetwork.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline or the connection is unstable. Changes are saved on this device and will sync when you\'re back online.'**
  String get failureNetwork;

  /// No description provided for @failurePermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that. Try signing in again.'**
  String get failurePermission;

  /// No description provided for @failureUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get failureUnauthenticated;

  /// No description provided for @failureNotFound.
  ///
  /// In en, this message translates to:
  /// **'That item no longer exists.'**
  String get failureNotFound;

  /// No description provided for @failureInvalidData.
  ///
  /// In en, this message translates to:
  /// **'The data is invalid or damaged.'**
  String get failureInvalidData;

  /// No description provided for @failureUnsupportedSchema.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of the app. Update the app to restore it.'**
  String get failureUnsupportedSchema;

  /// No description provided for @failureNotification.
  ///
  /// In en, this message translates to:
  /// **'A reminder could not be scheduled on this device.'**
  String get failureNotification;

  /// No description provided for @failureUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get failureUnknown;

  /// No description provided for @syncRejected.
  ///
  /// In en, this message translates to:
  /// **'A change could not be saved to the cloud: {reason}'**
  String syncRejected(String reason);

  /// No description provided for @syncAllSynced.
  ///
  /// In en, this message translates to:
  /// **'All changes synced'**
  String get syncAllSynced;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} change(s) waiting to sync'**
  String syncPending(String count);

  /// No description provided for @syncLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String syncLastSynced(String time);

  /// No description provided for @failureSignInMethodDisabled.
  ///
  /// In en, this message translates to:
  /// **'This sign-in option isn\'t available right now. Please use another option.'**
  String get failureSignInMethodDisabled;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes that will be lost.'**
  String get discardBody;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get restored;

  /// No description provided for @txTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get txTypeExpense;

  /// No description provided for @txTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get txTypeIncome;

  /// No description provided for @txTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get txTypeTransfer;

  /// No description provided for @txTypeCreditCardExpense.
  ///
  /// In en, this message translates to:
  /// **'Card expense'**
  String get txTypeCreditCardExpense;

  /// No description provided for @txTypeCreditCardPayment.
  ///
  /// In en, this message translates to:
  /// **'Card bill payment'**
  String get txTypeCreditCardPayment;

  /// No description provided for @txTypeLoanPayment.
  ///
  /// In en, this message translates to:
  /// **'Loan payment'**
  String get txTypeLoanPayment;

  /// No description provided for @txTypeRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get txTypeRefund;

  /// No description provided for @txTypeBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get txTypeBorrowed;

  /// No description provided for @txTypeLent.
  ///
  /// In en, this message translates to:
  /// **'Lent'**
  String get txTypeLent;

  /// No description provided for @txTypeDebtRepayment.
  ///
  /// In en, this message translates to:
  /// **'Repaid debt'**
  String get txTypeDebtRepayment;

  /// No description provided for @txTypeDebtCollection.
  ///
  /// In en, this message translates to:
  /// **'Collected debt'**
  String get txTypeDebtCollection;

  /// No description provided for @txStatusCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get txStatusCleared;

  /// No description provided for @txStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get txStatusPending;

  /// No description provided for @accountTypeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings account'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current account'**
  String get accountTypeCurrent;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypeWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get accountTypeWallet;

  /// No description provided for @accountTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get accountTypeOther;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catFoodGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get catFoodGroceries;

  /// No description provided for @catFoodDining.
  ///
  /// In en, this message translates to:
  /// **'Dining out'**
  String get catFoodDining;

  /// No description provided for @catFoodDelivery.
  ///
  /// In en, this message translates to:
  /// **'Food delivery'**
  String get catFoodDelivery;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catTransportFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get catTransportFuel;

  /// No description provided for @catTransportPublic.
  ///
  /// In en, this message translates to:
  /// **'Public transport'**
  String get catTransportPublic;

  /// No description provided for @catTransportCab.
  ///
  /// In en, this message translates to:
  /// **'Cab'**
  String get catTransportCab;

  /// No description provided for @catTransportParking.
  ///
  /// In en, this message translates to:
  /// **'Parking & tolls'**
  String get catTransportParking;

  /// No description provided for @catTransportService.
  ///
  /// In en, this message translates to:
  /// **'Vehicle service'**
  String get catTransportService;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catShoppingClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get catShoppingClothing;

  /// No description provided for @catShoppingElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get catShoppingElectronics;

  /// No description provided for @catShoppingHome.
  ///
  /// In en, this message translates to:
  /// **'Home & kitchen'**
  String get catShoppingHome;

  /// No description provided for @catBills.
  ///
  /// In en, this message translates to:
  /// **'Bills & utilities'**
  String get catBills;

  /// No description provided for @catBillsElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get catBillsElectricity;

  /// No description provided for @catBillsWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get catBillsWater;

  /// No description provided for @catBillsInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get catBillsInternet;

  /// No description provided for @catBillsPhone.
  ///
  /// In en, this message translates to:
  /// **'Mobile & phone'**
  String get catBillsPhone;

  /// No description provided for @catHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get catHousing;

  /// No description provided for @catHousingRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get catHousingRent;

  /// No description provided for @catHousingMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get catHousingMaintenance;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catHealthMedical.
  ///
  /// In en, this message translates to:
  /// **'Doctor & hospital'**
  String get catHealthMedical;

  /// No description provided for @catHealthPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get catHealthPharmacy;

  /// No description provided for @catHealthFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get catHealthFitness;

  /// No description provided for @catEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get catEntertainment;

  /// No description provided for @catEntertainmentSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get catEntertainmentSubscriptions;

  /// No description provided for @catEntertainmentOutings.
  ///
  /// In en, this message translates to:
  /// **'Movies & outings'**
  String get catEntertainmentOutings;

  /// No description provided for @catEntertainmentTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel & holidays'**
  String get catEntertainmentTravel;

  /// No description provided for @catEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catEducation;

  /// No description provided for @catInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get catInsurance;

  /// No description provided for @catPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal care'**
  String get catPersonal;

  /// No description provided for @catGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts & donations'**
  String get catGifts;

  /// No description provided for @catFees.
  ///
  /// In en, this message translates to:
  /// **'Fees & charges'**
  String get catFees;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @catSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get catSalary;

  /// No description provided for @catBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get catBusiness;

  /// No description provided for @catInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get catInterest;

  /// No description provided for @catInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get catInvestment;

  /// No description provided for @catGiftIncome.
  ///
  /// In en, this message translates to:
  /// **'Gifts received'**
  String get catGiftIncome;

  /// No description provided for @catOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other income'**
  String get catOtherIncome;

  /// No description provided for @catTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get catTransfer;

  /// No description provided for @catDebt.
  ///
  /// In en, this message translates to:
  /// **'Borrow & lend'**
  String get catDebt;

  /// No description provided for @catLoanEmi.
  ///
  /// In en, this message translates to:
  /// **'Loan EMI'**
  String get catLoanEmi;

  /// No description provided for @catCardPayment.
  ///
  /// In en, this message translates to:
  /// **'Card payment'**
  String get catCardPayment;

  /// No description provided for @freqOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get freqOnce;

  /// No description provided for @freqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get freqDaily;

  /// No description provided for @freqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get freqMonthly;

  /// No description provided for @freqYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get freqYearly;

  /// No description provided for @freqQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get freqQuarterly;

  /// No description provided for @freqHalfYearly.
  ///
  /// In en, this message translates to:
  /// **'Half-yearly'**
  String get freqHalfYearly;

  /// No description provided for @everyNDays.
  ///
  /// In en, this message translates to:
  /// **'Every {n} days'**
  String everyNDays(String n);

  /// No description provided for @everyNWeeks.
  ///
  /// In en, this message translates to:
  /// **'Every {n} weeks'**
  String everyNWeeks(String n);

  /// No description provided for @everyNMonths.
  ///
  /// In en, this message translates to:
  /// **'Every {n} months'**
  String everyNMonths(String n);

  /// No description provided for @everyNYears.
  ///
  /// In en, this message translates to:
  /// **'Every {n} years'**
  String everyNYears(String n);

  /// No description provided for @loanStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get loanStatusActive;

  /// No description provided for @loanStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get loanStatusCompleted;

  /// No description provided for @loanStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get loanStatusClosed;

  /// No description provided for @loanStatusPrepaid.
  ///
  /// In en, this message translates to:
  /// **'Prepaid'**
  String get loanStatusPrepaid;

  /// No description provided for @installmentPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get installmentPaid;

  /// No description provided for @installmentSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get installmentSkipped;

  /// No description provided for @installmentOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get installmentOverdue;

  /// No description provided for @installmentUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get installmentUpcoming;

  /// No description provided for @debtPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get debtPending;

  /// No description provided for @debtPartial.
  ///
  /// In en, this message translates to:
  /// **'Partially settled'**
  String get debtPartial;

  /// No description provided for @debtSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get debtSettled;

  /// No description provided for @debtOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get debtOverdue;

  /// No description provided for @debtBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get debtBorrowed;

  /// No description provided for @debtLent.
  ///
  /// In en, this message translates to:
  /// **'Lent'**
  String get debtLent;

  /// No description provided for @reminderTypeLoanEmi.
  ///
  /// In en, this message translates to:
  /// **'Loan EMI'**
  String get reminderTypeLoanEmi;

  /// No description provided for @reminderTypeCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card payment'**
  String get reminderTypeCreditCard;

  /// No description provided for @reminderTypeBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Borrowed money'**
  String get reminderTypeBorrowed;

  /// No description provided for @reminderTypeLent.
  ///
  /// In en, this message translates to:
  /// **'Lent money'**
  String get reminderTypeLent;

  /// No description provided for @reminderTypeGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get reminderTypeGym;

  /// No description provided for @reminderTypeMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get reminderTypeMeeting;

  /// No description provided for @reminderTypeInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get reminderTypeInsurance;

  /// No description provided for @reminderTypeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get reminderTypeSubscription;

  /// No description provided for @reminderTypeBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get reminderTypeBill;

  /// No description provided for @reminderTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reminderTypeCustom;

  /// No description provided for @fuelPetrol.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get fuelPetrol;

  /// No description provided for @fuelDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelDiesel;

  /// No description provided for @fuelCng.
  ///
  /// In en, this message translates to:
  /// **'CNG'**
  String get fuelCng;

  /// No description provided for @fuelLpg.
  ///
  /// In en, this message translates to:
  /// **'LPG'**
  String get fuelLpg;

  /// No description provided for @fuelElectric.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get fuelElectric;

  /// No description provided for @fuelHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get fuelHybrid;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldest;

  /// No description provided for @sortLargest.
  ///
  /// In en, this message translates to:
  /// **'Largest amount'**
  String get sortLargest;

  /// No description provided for @sortSmallest.
  ///
  /// In en, this message translates to:
  /// **'Smallest amount'**
  String get sortSmallest;

  /// No description provided for @issueAmountNotPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero.'**
  String get issueAmountNotPositive;

  /// No description provided for @issueAmountTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Amount is too large.'**
  String get issueAmountTooLarge;

  /// No description provided for @issueCategoryMismatch.
  ///
  /// In en, this message translates to:
  /// **'Choose a category that matches the transaction type.'**
  String get issueCategoryMismatch;

  /// No description provided for @issueCardRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a credit card.'**
  String get issueCardRequired;

  /// No description provided for @issueCardNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'A credit card can\'t be used for this type.'**
  String get issueCardNotAllowed;

  /// No description provided for @issueSourceAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the account the money leaves.'**
  String get issueSourceAccountRequired;

  /// No description provided for @issueDestinationAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the account the money goes to.'**
  String get issueDestinationAccountRequired;

  /// No description provided for @issueSameTransferAccounts.
  ///
  /// In en, this message translates to:
  /// **'Source and destination must be different accounts.'**
  String get issueSameTransferAccounts;

  /// No description provided for @issueLoanRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a loan.'**
  String get issueLoanRequired;

  /// No description provided for @issueDebtRecordRequired.
  ///
  /// In en, this message translates to:
  /// **'This needs a borrow/lend record.'**
  String get issueDebtRecordRequired;

  /// No description provided for @issueRefundTargetAmbiguous.
  ///
  /// In en, this message translates to:
  /// **'A refund goes to either an account or a card, not both.'**
  String get issueRefundTargetAmbiguous;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @reminderNew.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get reminderNew;

  /// No description provided for @reminderEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get reminderEdit;

  /// No description provided for @reminderTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reminderTitleLabel;

  /// No description provided for @reminderTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Gym, Pay electricity bill'**
  String get reminderTitleHint;

  /// No description provided for @reminderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get reminderTypeLabel;

  /// No description provided for @reminderRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get reminderRepeat;

  /// No description provided for @reminderEvery.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get reminderEvery;

  /// No description provided for @reminderUntil.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get reminderUntil;

  /// No description provided for @reminderNeverEnds.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get reminderNeverEnds;

  /// No description provided for @reminderNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify me'**
  String get reminderNotify;

  /// No description provided for @reminderOffsetAtTime.
  ///
  /// In en, this message translates to:
  /// **'At the time'**
  String get reminderOffsetAtTime;

  /// No description provided for @reminderOffsetMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min before'**
  String reminderOffsetMinutes(String n);

  /// No description provided for @reminderOffsetHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h before'**
  String reminderOffsetHours(String n);

  /// No description provided for @reminderOffsetDays.
  ///
  /// In en, this message translates to:
  /// **'{n} day(s) before'**
  String reminderOffsetDays(String n);

  /// No description provided for @reminderOffsetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get reminderOffsetCustom;

  /// No description provided for @reminderOffsetCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Days before'**
  String get reminderOffsetCustomTitle;

  /// No description provided for @reminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get reminderEnabled;

  /// No description provided for @reminderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get reminderDisabled;

  /// No description provided for @reminderNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String reminderNext(String date);

  /// No description provided for @reminderEnded.
  ///
  /// In en, this message translates to:
  /// **'No upcoming occurrences'**
  String get reminderEnded;

  /// No description provided for @reminderLinked.
  ///
  /// In en, this message translates to:
  /// **'Managed from {module}. You can change time, alerts and on/off here.'**
  String reminderLinked(String module);

  /// No description provided for @remindersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet. Add gym sessions, bills, renewals or anything else you don\'t want to miss.'**
  String get remindersEmpty;

  /// No description provided for @remindersUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get remindersUpcoming;

  /// No description provided for @remindersInactive.
  ///
  /// In en, this message translates to:
  /// **'Off or finished'**
  String get remindersInactive;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for this app, so reminders won\'t alert you.'**
  String get notificationsOff;

  /// No description provided for @notificationsEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get notificationsEnable;

  /// No description provided for @notifDue.
  ///
  /// In en, this message translates to:
  /// **'{what} · due now'**
  String notifDue(String what);

  /// No description provided for @notifInDays.
  ///
  /// In en, this message translates to:
  /// **'{what} · in {n} day(s)'**
  String notifInDays(String what, String n);

  /// No description provided for @notifInHours.
  ///
  /// In en, this message translates to:
  /// **'{what} · in {n} h'**
  String notifInHours(String what, String n);

  /// No description provided for @notifInMinutes.
  ///
  /// In en, this message translates to:
  /// **'{what} · in {n} min'**
  String notifInMinutes(String what, String n);

  /// No description provided for @reminderLoanTitle.
  ///
  /// In en, this message translates to:
  /// **'EMI due: {name}'**
  String reminderLoanTitle(String name);

  /// No description provided for @reminderCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Card bill due: {name}'**
  String reminderCardTitle(String name);

  /// No description provided for @reminderBorrowedTitle.
  ///
  /// In en, this message translates to:
  /// **'Repay {person}'**
  String reminderBorrowedTitle(String person);

  /// No description provided for @reminderLentTitle.
  ///
  /// In en, this message translates to:
  /// **'Collect from {person}'**
  String reminderLentTitle(String person);

  /// No description provided for @moduleLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get moduleLoans;

  /// No description provided for @moduleCards.
  ///
  /// In en, this message translates to:
  /// **'Credit cards'**
  String get moduleCards;

  /// No description provided for @moduleBorrowLend.
  ///
  /// In en, this message translates to:
  /// **'Borrow & lend'**
  String get moduleBorrowLend;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTransaction;

  /// No description provided for @duplicateTransaction.
  ///
  /// In en, this message translates to:
  /// **'Duplicate transaction'**
  String get duplicateTransaction;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transactionDetails;

  /// No description provided for @txMoreTypes.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get txMoreTypes;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @subcategory.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get subcategory;

  /// No description provided for @paidWith.
  ///
  /// In en, this message translates to:
  /// **'Paid with'**
  String get paidWith;

  /// No description provided for @receivedIn.
  ///
  /// In en, this message translates to:
  /// **'Received in'**
  String get receivedIn;

  /// No description provided for @fromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get fromAccount;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get toAccount;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get creditCard;

  /// No description provided for @refundTo.
  ///
  /// In en, this message translates to:
  /// **'Refund to'**
  String get refundTo;

  /// No description provided for @cashUntracked.
  ///
  /// In en, this message translates to:
  /// **'Cash / not tracked'**
  String get cashUntracked;

  /// No description provided for @merchantOrPerson.
  ///
  /// In en, this message translates to:
  /// **'Merchant or person'**
  String get merchantOrPerson;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma separated, e.g. trip, office'**
  String get tagsHint;

  /// No description provided for @markPending.
  ///
  /// In en, this message translates to:
  /// **'Pending (not yet paid)'**
  String get markPending;

  /// No description provided for @markPendingHelp.
  ///
  /// In en, this message translates to:
  /// **'Pending items don\'t change balances or totals until cleared.'**
  String get markPendingHelp;

  /// No description provided for @noAccountsHint.
  ///
  /// In en, this message translates to:
  /// **'Add an account or card to track balances. You can still record cash spending.'**
  String get noAccountsHint;

  /// No description provided for @transactionSaved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get transactionSaved;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// No description provided for @budgetWarning.
  ///
  /// In en, this message translates to:
  /// **'{budget} budget is at {percent}% for this month'**
  String budgetWarning(String budget, String percent);

  /// No description provided for @budgetOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get budgetOverall;

  /// No description provided for @managedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'This entry is managed from {module}. Open it there to change or remove it.'**
  String managedElsewhere(String module);

  /// No description provided for @moduleVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get moduleVehicles;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search description, category, amount, date…'**
  String get searchTransactions;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filtersActive.
  ///
  /// In en, this message translates to:
  /// **'Filters ({count})'**
  String filtersActive(String count);

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @accountsLabel.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsLabel;

  /// No description provided for @cardsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cardsLabel;

  /// No description provided for @categoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesLabel;

  /// No description provided for @amountRange.
  ///
  /// In en, this message translates to:
  /// **'Amount range'**
  String get amountRange;

  /// No description provided for @minAmount.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minAmount;

  /// No description provided for @maxAmount.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxAmount;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get customRange;

  /// No description provided for @backToMonth.
  ///
  /// In en, this message translates to:
  /// **'Back to month view'**
  String get backToMonth;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @calendarView.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarView;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this period yet. Tap + to add your first one.'**
  String get noTransactions;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No transactions match your search or filters.'**
  String get noMatches;

  /// No description provided for @dayTotal.
  ///
  /// In en, this message translates to:
  /// **'Spent {amount}'**
  String dayTotal(String amount);

  /// No description provided for @moneyIn.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get moneyIn;

  /// No description provided for @moneyOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get moneyOut;

  /// No description provided for @transactionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String transactionsCount(String count);

  /// No description provided for @recurringGenerated.
  ///
  /// In en, this message translates to:
  /// **'Created by recurring rule'**
  String get recurringGenerated;

  /// No description provided for @importedFrom.
  ///
  /// In en, this message translates to:
  /// **'Imported ({source})'**
  String importedFrom(String source);

  /// No description provided for @selectDay.
  ///
  /// In en, this message translates to:
  /// **'Select a day to see its transactions'**
  String get selectDay;

  /// No description provided for @noTransactionsOnDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded on this day.'**
  String get noTransactionsOnDay;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @entriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entriesLabel;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @dashboardSpentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent in {month}'**
  String dashboardSpentThisMonth(String month);

  /// No description provided for @dashboardIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboardIncome;

  /// No description provided for @dashboardSpending.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get dashboardSpending;

  /// No description provided for @dashboardSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get dashboardSavings;

  /// No description provided for @dashboardSavingsRate.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of income saved'**
  String dashboardSavingsRate(String percent);

  /// No description provided for @dashboardOverspent.
  ///
  /// In en, this message translates to:
  /// **'Spent {amount} more than earned'**
  String dashboardOverspent(String amount);

  /// No description provided for @dashboardNoIncome.
  ///
  /// In en, this message translates to:
  /// **'No income recorded this month'**
  String get dashboardNoIncome;

  /// No description provided for @dashboardEmi.
  ///
  /// In en, this message translates to:
  /// **'EMIs paid'**
  String get dashboardEmi;

  /// No description provided for @dashboardCardSpending.
  ///
  /// In en, this message translates to:
  /// **'Card spending'**
  String get dashboardCardSpending;

  /// No description provided for @dashboardBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get dashboardBorrowed;

  /// No description provided for @dashboardLent.
  ///
  /// In en, this message translates to:
  /// **'Lent'**
  String get dashboardLent;

  /// No description provided for @dashboardPendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Pending payments'**
  String get dashboardPendingPayments;

  /// No description provided for @dashboardScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All accounts & cards'**
  String get dashboardScopeAll;

  /// No description provided for @dashboardUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get dashboardUpcoming;

  /// No description provided for @dashboardUpcomingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No dues in the next 30 days.'**
  String get dashboardUpcomingEmpty;

  /// No description provided for @dashboardOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dashboardOverdue;

  /// No description provided for @dashboardDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dashboardDueOn(String date);

  /// No description provided for @dashboardRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get dashboardRecent;

  /// No description provided for @dashboardBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get dashboardBudget;

  /// No description provided for @dashboardBudgetLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String dashboardBudgetLeft(String amount);

  /// No description provided for @dashboardBudgetOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over budget'**
  String dashboardBudgetOver(String amount);

  /// No description provided for @chartByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get chartByCategory;

  /// No description provided for @chartDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily spending'**
  String get chartDaily;

  /// No description provided for @chartIncomeVsSpending.
  ///
  /// In en, this message translates to:
  /// **'Income vs spending'**
  String get chartIncomeVsSpending;

  /// No description provided for @chartByAccount.
  ///
  /// In en, this message translates to:
  /// **'Spending by account'**
  String get chartByAccount;

  /// No description provided for @chartByCard.
  ///
  /// In en, this message translates to:
  /// **'Spending by card'**
  String get chartByCard;

  /// No description provided for @chartTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly spending trend'**
  String get chartTrend;

  /// No description provided for @chartNoData.
  ///
  /// In en, this message translates to:
  /// **'No spending to chart for this period.'**
  String get chartNoData;

  /// No description provided for @chartOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chartOther;

  /// No description provided for @chartSemanticsTotal.
  ///
  /// In en, this message translates to:
  /// **'{title}. Total {amount}.'**
  String chartSemanticsTotal(String title, String amount);

  /// No description provided for @netWorth.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get netWorth;

  /// No description provided for @searchEverything.
  ///
  /// In en, this message translates to:
  /// **'Search everything'**
  String get searchEverything;

  /// No description provided for @emptyDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Let\'s set things up'**
  String get emptyDashboardTitle;

  /// No description provided for @emptyDashboardBody.
  ///
  /// In en, this message translates to:
  /// **'Add an account or card, then record your first expense. Everything works offline and syncs when you\'re online.'**
  String get emptyDashboardBody;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get addCard;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts & cards'**
  String get accountsTitle;

  /// No description provided for @accountsTab.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTab;

  /// No description provided for @cardsTab.
  ///
  /// In en, this message translates to:
  /// **'Credit cards'**
  String get cardsTab;

  /// No description provided for @newAccount.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get newAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get editAccount;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @accountNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Salary account, Wallet'**
  String get accountNameHint;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank name'**
  String get bankName;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @openingBalanceHelp.
  ///
  /// In en, this message translates to:
  /// **'Balance on the day you start tracking. Transactions recorded here adjust it automatically.'**
  String get openingBalanceHelp;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @noCredentialsNote.
  ///
  /// In en, this message translates to:
  /// **'Never enter passwords, PINs or card numbers. This app doesn\'t need them.'**
  String get noCredentialsNote;

  /// No description provided for @accountsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. Add your bank accounts, cash or wallets to see balances.'**
  String get accountsEmpty;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get assets;

  /// No description provided for @cardDebt.
  ///
  /// In en, this message translates to:
  /// **'Card dues'**
  String get cardDebt;

  /// No description provided for @showArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived ({count})'**
  String showArchived(String count);

  /// No description provided for @accountInUse.
  ///
  /// In en, this message translates to:
  /// **'This account is used by transactions, loans, borrow/lend records, recurring entries or a card, so it can\'t be deleted. Archive it instead to hide it.'**
  String get accountInUse;

  /// No description provided for @accountArchived.
  ///
  /// In en, this message translates to:
  /// **'Account archived'**
  String get accountArchived;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No transactions linked yet.'**
  String get noActivity;

  /// No description provided for @inThisMonth.
  ///
  /// In en, this message translates to:
  /// **'In this month'**
  String get inThisMonth;

  /// No description provided for @outThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Out this month'**
  String get outThisMonth;

  /// No description provided for @newCard.
  ///
  /// In en, this message translates to:
  /// **'New credit card'**
  String get newCard;

  /// No description provided for @editCard.
  ///
  /// In en, this message translates to:
  /// **'Edit credit card'**
  String get editCard;

  /// No description provided for @cardName.
  ///
  /// In en, this message translates to:
  /// **'Card name'**
  String get cardName;

  /// No description provided for @cardNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Millennia, Amazon Pay'**
  String get cardNameHint;

  /// No description provided for @last4.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits'**
  String get last4;

  /// No description provided for @last4Help.
  ///
  /// In en, this message translates to:
  /// **'Only to recognise the card. Never enter the full number.'**
  String get last4Help;

  /// No description provided for @last4Invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter exactly 4 digits'**
  String get last4Invalid;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get creditLimit;

  /// No description provided for @currentOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Current outstanding'**
  String get currentOutstanding;

  /// No description provided for @currentOutstandingHelp.
  ///
  /// In en, this message translates to:
  /// **'What you owe today. New card transactions update it automatically.'**
  String get currentOutstandingHelp;

  /// No description provided for @statementDay.
  ///
  /// In en, this message translates to:
  /// **'Statement day'**
  String get statementDay;

  /// No description provided for @dueDay.
  ///
  /// In en, this message translates to:
  /// **'Payment due day'**
  String get dueDay;

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month (1–31)'**
  String get dayOfMonth;

  /// No description provided for @minimumDuePercent.
  ///
  /// In en, this message translates to:
  /// **'Minimum due %'**
  String get minimumDuePercent;

  /// No description provided for @minimumDuePercentHelp.
  ///
  /// In en, this message translates to:
  /// **'Used to estimate the minimum due. Check your statement for the exact figure.'**
  String get minimumDuePercentHelp;

  /// No description provided for @linkedAccount.
  ///
  /// In en, this message translates to:
  /// **'Pays from account'**
  String get linkedAccount;

  /// No description provided for @cardsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No credit cards yet. Add one to track limits, utilisation and due dates.'**
  String get cardsEmpty;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @utilization.
  ///
  /// In en, this message translates to:
  /// **'Utilisation'**
  String get utilization;

  /// No description provided for @utilizationValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String utilizationValue(String percent);

  /// No description provided for @statement.
  ///
  /// In en, this message translates to:
  /// **'Last statement'**
  String get statement;

  /// No description provided for @statementBalance.
  ///
  /// In en, this message translates to:
  /// **'Statement balance'**
  String get statementBalance;

  /// No description provided for @totalDue.
  ///
  /// In en, this message translates to:
  /// **'Total due'**
  String get totalDue;

  /// No description provided for @minimumDueEstimate.
  ///
  /// In en, this message translates to:
  /// **'Minimum due (est.)'**
  String get minimumDueEstimate;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @paidInFull.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidInFull;

  /// No description provided for @payBill.
  ///
  /// In en, this message translates to:
  /// **'Pay bill'**
  String get payBill;

  /// No description provided for @addCardExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addCardExpense;

  /// No description provided for @cardSpending6m.
  ///
  /// In en, this message translates to:
  /// **'Card spending, last 6 months'**
  String get cardSpending6m;

  /// No description provided for @cardInUse.
  ///
  /// In en, this message translates to:
  /// **'This card is used by transactions or recurring entries, so it can\'t be deleted. Archive it instead.'**
  String get cardInUse;

  /// No description provided for @cardReminderNote.
  ///
  /// In en, this message translates to:
  /// **'A due-date reminder is created automatically. Adjust it in Reminders.'**
  String get cardReminderNote;

  /// No description provided for @recalcBalances.
  ///
  /// In en, this message translates to:
  /// **'Recalculate balances'**
  String get recalcBalances;

  /// No description provided for @recalcBalancesHelp.
  ///
  /// In en, this message translates to:
  /// **'Rebuilds every account and card balance from your full transaction history. Use this if a balance looks wrong.'**
  String get recalcBalancesHelp;

  /// No description provided for @recalcDone.
  ///
  /// In en, this message translates to:
  /// **'Balances recalculated'**
  String get recalcDone;

  /// No description provided for @dayInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a day between 1 and 31'**
  String get dayInvalid;

  /// No description provided for @accountTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountTypeLabel;

  /// No description provided for @outstandingWhenAdded.
  ///
  /// In en, this message translates to:
  /// **'Outstanding when added'**
  String get outstandingWhenAdded;

  /// No description provided for @outstandingWhenAddedHelp.
  ///
  /// In en, this message translates to:
  /// **'The card\'s current outstanding is {current}, which already includes transactions recorded in the app. Only change this to correct the starting amount.'**
  String outstandingWhenAddedHelp(String current);

  /// No description provided for @cardDueDate.
  ///
  /// In en, this message translates to:
  /// **'Payment due date'**
  String get cardDueDate;

  /// No description provided for @cardDueDateHelp.
  ///
  /// In en, this message translates to:
  /// **'Repeats every month on this day.'**
  String get cardDueDateHelp;

  /// No description provided for @cardDueDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the payment due date'**
  String get cardDueDateRequired;

  /// No description provided for @cardMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'More details (optional)'**
  String get cardMoreDetails;

  /// No description provided for @loansTitle.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loansTitle;

  /// No description provided for @loansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No loans yet. Add a loan to track EMIs, interest and what\'s left to pay.'**
  String get loansEmpty;

  /// No description provided for @addLoan.
  ///
  /// In en, this message translates to:
  /// **'Add loan'**
  String get addLoan;

  /// No description provided for @newLoan.
  ///
  /// In en, this message translates to:
  /// **'New loan'**
  String get newLoan;

  /// No description provided for @editLoan.
  ///
  /// In en, this message translates to:
  /// **'Edit loan'**
  String get editLoan;

  /// No description provided for @loanName.
  ///
  /// In en, this message translates to:
  /// **'Loan name'**
  String get loanName;

  /// No description provided for @loanNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home loan, Car loan'**
  String get loanNameHint;

  /// No description provided for @lender.
  ///
  /// In en, this message translates to:
  /// **'Lender'**
  String get lender;

  /// No description provided for @principal.
  ///
  /// In en, this message translates to:
  /// **'Principal amount'**
  String get principal;

  /// No description provided for @interestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest rate (% per year)'**
  String get interestRate;

  /// No description provided for @tenure.
  ///
  /// In en, this message translates to:
  /// **'Number of installments'**
  String get tenure;

  /// No description provided for @tenureMonthsHelp.
  ///
  /// In en, this message translates to:
  /// **'{months} months'**
  String tenureMonthsHelp(String months);

  /// No description provided for @firstEmiDate.
  ///
  /// In en, this message translates to:
  /// **'First EMI date'**
  String get firstEmiDate;

  /// No description provided for @emiAmount.
  ///
  /// In en, this message translates to:
  /// **'EMI amount'**
  String get emiAmount;

  /// No description provided for @payFromAccount.
  ///
  /// In en, this message translates to:
  /// **'Pay EMIs from'**
  String get payFromAccount;

  /// No description provided for @loanReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me before each EMI'**
  String get loanReminder;

  /// No description provided for @loansOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total outstanding'**
  String get loansOutstanding;

  /// No description provided for @loansMonthlyEmi.
  ///
  /// In en, this message translates to:
  /// **'Monthly EMIs'**
  String get loansMonthlyEmi;

  /// No description provided for @loansActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String loansActive(String count);

  /// No description provided for @loanOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String loanOverdueCount(String count);

  /// No description provided for @loanProgress.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total} EMIs paid'**
  String loanProgress(String paid, String total);

  /// No description provided for @outstandingPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Outstanding principal'**
  String get outstandingPrincipal;

  /// No description provided for @nextEmi.
  ///
  /// In en, this message translates to:
  /// **'Next EMI'**
  String get nextEmi;

  /// No description provided for @nextEmiOn.
  ///
  /// In en, this message translates to:
  /// **'#{number} on {date}'**
  String nextEmiOn(String number, String date);

  /// No description provided for @noNextEmi.
  ///
  /// In en, this message translates to:
  /// **'No EMIs left'**
  String get noNextEmi;

  /// No description provided for @paidEmis.
  ///
  /// In en, this message translates to:
  /// **'Paid EMIs'**
  String get paidEmis;

  /// No description provided for @remainingEmis.
  ///
  /// In en, this message translates to:
  /// **'Remaining EMIs'**
  String get remainingEmis;

  /// No description provided for @totalInterest.
  ///
  /// In en, this message translates to:
  /// **'Total interest'**
  String get totalInterest;

  /// No description provided for @paidInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest paid'**
  String get paidInterest;

  /// No description provided for @remainingInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest remaining'**
  String get remainingInterest;

  /// No description provided for @principalPaid.
  ///
  /// In en, this message translates to:
  /// **'Principal paid'**
  String get principalPaid;

  /// No description provided for @prepaid.
  ///
  /// In en, this message translates to:
  /// **'Prepaid'**
  String get prepaid;

  /// No description provided for @principalVsInterest.
  ///
  /// In en, this message translates to:
  /// **'Principal vs interest'**
  String get principalVsInterest;

  /// No description provided for @principalLabel.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get principalLabel;

  /// No description provided for @interestLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get interestLabel;

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark EMI paid'**
  String get markPaid;

  /// No description provided for @markPaidTitle.
  ///
  /// In en, this message translates to:
  /// **'EMI #{number}'**
  String markPaidTitle(String number);

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get paidOn;

  /// No description provided for @skipEmi.
  ///
  /// In en, this message translates to:
  /// **'Mark as skipped'**
  String get skipEmi;

  /// No description provided for @clearMark.
  ///
  /// In en, this message translates to:
  /// **'Undo mark'**
  String get clearMark;

  /// No description provided for @recordPrepayment.
  ///
  /// In en, this message translates to:
  /// **'Record prepayment'**
  String get recordPrepayment;

  /// No description provided for @prepaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Prepayment amount'**
  String get prepaymentAmount;

  /// No description provided for @prepaymentMode.
  ///
  /// In en, this message translates to:
  /// **'After the prepayment'**
  String get prepaymentMode;

  /// No description provided for @prepayReduceTenure.
  ///
  /// In en, this message translates to:
  /// **'Keep EMI, finish sooner'**
  String get prepayReduceTenure;

  /// No description provided for @prepayReduceEmi.
  ///
  /// In en, this message translates to:
  /// **'Keep tenure, lower EMI'**
  String get prepayReduceEmi;

  /// No description provided for @prepayPreview.
  ///
  /// In en, this message translates to:
  /// **'What changes'**
  String get prepayPreview;

  /// No description provided for @prepayNewEmi.
  ///
  /// In en, this message translates to:
  /// **'EMI: {before} → {after}'**
  String prepayNewEmi(String before, String after);

  /// No description provided for @prepayNewTenure.
  ///
  /// In en, this message translates to:
  /// **'Remaining EMIs: {before} → {after}'**
  String prepayNewTenure(String before, String after);

  /// No description provided for @prepayInterestSaved.
  ///
  /// In en, this message translates to:
  /// **'Interest saved: {amount}'**
  String prepayInterestSaved(String amount);

  /// No description provided for @prepayOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding: {before} → {after}'**
  String prepayOutstanding(String before, String after);

  /// No description provided for @prepayExplain.
  ///
  /// In en, this message translates to:
  /// **'Prepayments reduce principal immediately. You choose whether the EMI stays the same (loan ends earlier) or the number of EMIs stays the same (EMI goes down). Nothing changes until you confirm.'**
  String get prepayExplain;

  /// No description provided for @prepayments.
  ///
  /// In en, this message translates to:
  /// **'Prepayments'**
  String get prepayments;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Repayment schedule'**
  String get schedule;

  /// No description provided for @scheduleRowSemantics.
  ///
  /// In en, this message translates to:
  /// **'EMI {number}, due {date}, {emi}, principal {principal}, interest {interest}, balance {balance}, {status}'**
  String scheduleRowSemantics(
    String number,
    String date,
    String emi,
    String principal,
    String interest,
    String balance,
    String status,
  );

  /// No description provided for @balanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balanceLabel;

  /// No description provided for @emiDoesNotCoverInterest.
  ///
  /// In en, this message translates to:
  /// **'This EMI doesn\'t cover the interest, so the loan would never be repaid. Check the EMI, rate and principal.'**
  String get emiDoesNotCoverInterest;

  /// No description provided for @unappliedPrepayment.
  ///
  /// In en, this message translates to:
  /// **'{amount} of prepayments exceeded what was owed and was not applied.'**
  String unappliedPrepayment(String amount);

  /// No description provided for @closeLoan.
  ///
  /// In en, this message translates to:
  /// **'Mark loan closed'**
  String get closeLoan;

  /// No description provided for @reopenLoan.
  ///
  /// In en, this message translates to:
  /// **'Reopen loan'**
  String get reopenLoan;

  /// No description provided for @loanClosedNote.
  ///
  /// In en, this message translates to:
  /// **'Closed loans stop sending reminders.'**
  String get loanClosedNote;

  /// No description provided for @emiCalculator.
  ///
  /// In en, this message translates to:
  /// **'EMI calculator'**
  String get emiCalculator;

  /// No description provided for @rateFinder.
  ///
  /// In en, this message translates to:
  /// **'Interest rate finder'**
  String get rateFinder;

  /// No description provided for @financialTools.
  ///
  /// In en, this message translates to:
  /// **'Financial tools'**
  String get financialTools;

  /// No description provided for @calcResultEmi.
  ///
  /// In en, this message translates to:
  /// **'Monthly EMI'**
  String get calcResultEmi;

  /// No description provided for @calcTotalPayment.
  ///
  /// In en, this message translates to:
  /// **'Total payment'**
  String get calcTotalPayment;

  /// No description provided for @calcInterestPercent.
  ///
  /// In en, this message translates to:
  /// **'Interest is {percent}% of principal'**
  String calcInterestPercent(String percent);

  /// No description provided for @calcFirstEmiSplit.
  ///
  /// In en, this message translates to:
  /// **'First EMI split'**
  String get calcFirstEmiSplit;

  /// No description provided for @calcRateResult.
  ///
  /// In en, this message translates to:
  /// **'Approximate interest rate'**
  String get calcRateResult;

  /// No description provided for @calcRateValue.
  ///
  /// In en, this message translates to:
  /// **'{rate}% per year'**
  String calcRateValue(String rate);

  /// No description provided for @calcRateImpossible.
  ///
  /// In en, this message translates to:
  /// **'These numbers can\'t work: the EMIs add up to less than the principal.'**
  String get calcRateImpossible;

  /// No description provided for @calcRateTooHigh.
  ///
  /// In en, this message translates to:
  /// **'The implied rate is unrealistically high. Check the inputs.'**
  String get calcRateTooHigh;

  /// No description provided for @calcRateZero.
  ///
  /// In en, this message translates to:
  /// **'0% — the EMIs exactly repay the principal (no interest).'**
  String get calcRateZero;

  /// No description provided for @useThisRate.
  ///
  /// In en, this message translates to:
  /// **'Use this rate'**
  String get useThisRate;

  /// No description provided for @calcEnterValues.
  ///
  /// In en, this message translates to:
  /// **'Enter the values to see the result.'**
  String get calcEnterValues;

  /// No description provided for @emiFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'EMI frequency'**
  String get emiFrequencyLabel;

  /// No description provided for @loanRateCalculated.
  ///
  /// In en, this message translates to:
  /// **'Interest rate (calculated)'**
  String get loanRateCalculated;

  /// No description provided for @loanRateFromEmi.
  ///
  /// In en, this message translates to:
  /// **'Worked out from the principal, EMI amount and number of EMIs, so you don\'t have to look it up.'**
  String get loanRateFromEmi;

  /// No description provided for @loanInterestSummary.
  ///
  /// In en, this message translates to:
  /// **'Total interest {interest} · total payable {total}'**
  String loanInterestSummary(String interest, String total);

  /// No description provided for @loanEmisPaid.
  ///
  /// In en, this message translates to:
  /// **'EMIs already paid'**
  String get loanEmisPaid;

  /// No description provided for @loanEmisPaidHelp.
  ///
  /// In en, this message translates to:
  /// **'How many EMIs you\'ve already paid. They\'re marked paid in the schedule; no account balance changes.'**
  String get loanEmisPaidHelp;

  /// No description provided for @loanEmisPaidInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number from 0 to {max}'**
  String loanEmisPaidInvalid(String max);

  /// No description provided for @loanFirstEmiDate.
  ///
  /// In en, this message translates to:
  /// **'First EMI date'**
  String get loanFirstEmiDate;

  /// No description provided for @loanNextEmiDate.
  ///
  /// In en, this message translates to:
  /// **'Next EMI date'**
  String get loanNextEmiDate;

  /// No description provided for @loanNextEmiHelp.
  ///
  /// In en, this message translates to:
  /// **'Due date of EMI #{number}'**
  String loanNextEmiHelp(String number);

  /// No description provided for @loanKnowRate.
  ///
  /// In en, this message translates to:
  /// **'I know the interest rate instead'**
  String get loanKnowRate;

  /// No description provided for @loanUseEmi.
  ///
  /// In en, this message translates to:
  /// **'Use the EMI amount instead'**
  String get loanUseEmi;

  /// No description provided for @loanEmiCalculated.
  ///
  /// In en, this message translates to:
  /// **'Calculated EMI: {amount}'**
  String loanEmiCalculated(String amount);

  /// No description provided for @loanPayFromHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. Used as the default account when you mark an EMI paid.'**
  String get loanPayFromHelp;

  /// No description provided for @loanSavedWithPaid.
  ///
  /// In en, this message translates to:
  /// **'Loan saved. {count} EMIs marked as paid.'**
  String loanSavedWithPaid(String count);

  /// No description provided for @borrowLendTitle.
  ///
  /// In en, this message translates to:
  /// **'Borrow & lend'**
  String get borrowLendTitle;

  /// No description provided for @debtsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Record money you\'ve borrowed from or lent to someone.'**
  String get debtsEmpty;

  /// No description provided for @newDebt.
  ///
  /// In en, this message translates to:
  /// **'New record'**
  String get newDebt;

  /// No description provided for @editDebt.
  ///
  /// In en, this message translates to:
  /// **'Edit record'**
  String get editDebt;

  /// No description provided for @iBorrowed.
  ///
  /// In en, this message translates to:
  /// **'I borrowed'**
  String get iBorrowed;

  /// No description provided for @iLent.
  ///
  /// In en, this message translates to:
  /// **'I lent'**
  String get iLent;

  /// No description provided for @personName.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get personName;

  /// No description provided for @personNameHint.
  ///
  /// In en, this message translates to:
  /// **'Who is it with?'**
  String get personNameHint;

  /// No description provided for @personRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get personRequired;

  /// No description provided for @givenOn.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get givenOn;

  /// No description provided for @dueDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Due date (optional)'**
  String get dueDateOptional;

  /// No description provided for @moneyMovedThrough.
  ///
  /// In en, this message translates to:
  /// **'Money moved through'**
  String get moneyMovedThrough;

  /// No description provided for @debtReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me before the due date'**
  String get debtReminder;

  /// No description provided for @debtReminderOffsets.
  ///
  /// In en, this message translates to:
  /// **'When to remind'**
  String get debtReminderOffsets;

  /// No description provided for @iOwe.
  ///
  /// In en, this message translates to:
  /// **'I owe'**
  String get iOwe;

  /// No description provided for @owedToMe.
  ///
  /// In en, this message translates to:
  /// **'Owed to me'**
  String get owedToMe;

  /// No description provided for @overdueAmount.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueAmount;

  /// No description provided for @totalBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Total borrowed'**
  String get totalBorrowed;

  /// No description provided for @totalLent.
  ///
  /// In en, this message translates to:
  /// **'Total lent'**
  String get totalLent;

  /// No description provided for @openRecords.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String openRecords(String count);

  /// No description provided for @outstandingOf.
  ///
  /// In en, this message translates to:
  /// **'{outstanding} of {total} left'**
  String outstandingOf(String outstanding, String total);

  /// No description provided for @settlements.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get settlements;

  /// No description provided for @addSettlement.
  ///
  /// In en, this message translates to:
  /// **'Record repayment'**
  String get addSettlement;

  /// No description provided for @settlementAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount repaid'**
  String get settlementAmount;

  /// No description provided for @noSettlements.
  ///
  /// In en, this message translates to:
  /// **'No repayments recorded yet.'**
  String get noSettlements;

  /// No description provided for @settleFull.
  ///
  /// In en, this message translates to:
  /// **'Settle in full'**
  String get settleFull;

  /// No description provided for @filterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get filterOpen;

  /// No description provided for @filterSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get filterSettled;

  /// No description provided for @debtDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String debtDueOn(String date);

  /// No description provided for @vehiclesTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehiclesTitle;

  /// No description provided for @vehiclesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No vehicles yet. Add one to track mileage and fuel costs.'**
  String get vehiclesEmpty;

  /// No description provided for @addVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle'**
  String get addVehicle;

  /// No description provided for @newVehicle.
  ///
  /// In en, this message translates to:
  /// **'New vehicle'**
  String get newVehicle;

  /// No description provided for @editVehicle.
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get editVehicle;

  /// No description provided for @vehicleName.
  ///
  /// In en, this message translates to:
  /// **'Vehicle name'**
  String get vehicleName;

  /// No description provided for @vehicleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Swift, Activa'**
  String get vehicleNameHint;

  /// No description provided for @registrationNickname.
  ///
  /// In en, this message translates to:
  /// **'Registration / nickname'**
  String get registrationNickname;

  /// No description provided for @fuelPrice.
  ///
  /// In en, this message translates to:
  /// **'Fuel price per unit'**
  String get fuelPrice;

  /// No description provided for @expectedMileage.
  ///
  /// In en, this message translates to:
  /// **'Expected mileage'**
  String get expectedMileage;

  /// No description provided for @expectedMileageHelp.
  ///
  /// In en, this message translates to:
  /// **'Used until you log fuel fills; then the measured average is used.'**
  String get expectedMileageHelp;

  /// No description provided for @unitKmPerL.
  ///
  /// In en, this message translates to:
  /// **'km/l'**
  String get unitKmPerL;

  /// No description provided for @unitKmPerKwh.
  ///
  /// In en, this message translates to:
  /// **'km/kWh'**
  String get unitKmPerKwh;

  /// No description provided for @unitKmPerKg.
  ///
  /// In en, this message translates to:
  /// **'km/kg'**
  String get unitKmPerKg;

  /// No description provided for @unitLitre.
  ///
  /// In en, this message translates to:
  /// **'l'**
  String get unitLitre;

  /// No description provided for @unitKwh.
  ///
  /// In en, this message translates to:
  /// **'kWh'**
  String get unitKwh;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKm;

  /// No description provided for @avgMileage.
  ///
  /// In en, this message translates to:
  /// **'Average mileage'**
  String get avgMileage;

  /// No description provided for @costPerKm.
  ///
  /// In en, this message translates to:
  /// **'Cost per km'**
  String get costPerKm;

  /// No description provided for @fuelThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Fuel this month'**
  String get fuelThisMonth;

  /// No description provided for @fuelMonthlyAverage.
  ///
  /// In en, this message translates to:
  /// **'Monthly average'**
  String get fuelMonthlyAverage;

  /// No description provided for @fuelYearlyEstimate.
  ///
  /// In en, this message translates to:
  /// **'Yearly estimate'**
  String get fuelYearlyEstimate;

  /// No description provided for @fuelCost6m.
  ///
  /// In en, this message translates to:
  /// **'Fuel cost, last 6 months'**
  String get fuelCost6m;

  /// No description provided for @totalDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance logged'**
  String get totalDistance;

  /// No description provided for @fuelLogs.
  ///
  /// In en, this message translates to:
  /// **'Fuel history'**
  String get fuelLogs;

  /// No description provided for @fuelLogsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No fuel fills logged yet.'**
  String get fuelLogsEmpty;

  /// No description provided for @addFuel.
  ///
  /// In en, this message translates to:
  /// **'Log fuel'**
  String get addFuel;

  /// No description provided for @editFuel.
  ///
  /// In en, this message translates to:
  /// **'Edit fuel fill'**
  String get editFuel;

  /// No description provided for @odometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer (optional)'**
  String get odometer;

  /// No description provided for @distanceTravelled.
  ///
  /// In en, this message translates to:
  /// **'Distance since last fill'**
  String get distanceTravelled;

  /// No description provided for @fuelQuantity.
  ///
  /// In en, this message translates to:
  /// **'Fuel added'**
  String get fuelQuantity;

  /// No description provided for @pricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Price per unit'**
  String get pricePerUnit;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get totalCost;

  /// No description provided for @recordAsExpense.
  ///
  /// In en, this message translates to:
  /// **'Record as expense from'**
  String get recordAsExpense;

  /// No description provided for @dontRecord.
  ///
  /// In en, this message translates to:
  /// **'Don\'t record as expense'**
  String get dontRecord;

  /// No description provided for @mileageCalculator.
  ///
  /// In en, this message translates to:
  /// **'Mileage calculator'**
  String get mileageCalculator;

  /// No description provided for @mileageResult.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get mileageResult;

  /// No description provided for @tripCost.
  ///
  /// In en, this message translates to:
  /// **'Fuel cost for this trip'**
  String get tripCost;

  /// No description provided for @tripDistance.
  ///
  /// In en, this message translates to:
  /// **'Trip distance'**
  String get tripDistance;

  /// No description provided for @calcCostPerKm.
  ///
  /// In en, this message translates to:
  /// **'Cost per km'**
  String get calcCostPerKm;

  /// No description provided for @noMileageYet.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get noMileageYet;

  /// No description provided for @vehicleFuelExpenseNote.
  ///
  /// In en, this message translates to:
  /// **'Fuel fills recorded as expenses also appear in Transactions and budgets.'**
  String get vehicleFuelExpenseNote;

  /// No description provided for @fuelTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuel type'**
  String get fuelTypeLabel;

  /// No description provided for @budgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// No description provided for @budgetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet. Set a monthly limit overall or per category.'**
  String get budgetsEmpty;

  /// No description provided for @addBudget.
  ///
  /// In en, this message translates to:
  /// **'Add budget'**
  String get addBudget;

  /// No description provided for @editBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get editBudget;

  /// No description provided for @budgetFor.
  ///
  /// In en, this message translates to:
  /// **'Budget for'**
  String get budgetFor;

  /// No description provided for @budgetLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get budgetLimit;

  /// No description provided for @budgetThresholds.
  ///
  /// In en, this message translates to:
  /// **'Warn me at'**
  String get budgetThresholds;

  /// No description provided for @budgetThresholdsHelp.
  ///
  /// In en, this message translates to:
  /// **'Percent of the limit, comma separated (e.g. 75, 90, 100)'**
  String get budgetThresholdsHelp;

  /// No description provided for @budgetThresholdsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter percentages between 1 and 200'**
  String get budgetThresholdsInvalid;

  /// No description provided for @budgetSpentOf.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {limit}'**
  String budgetSpentOf(String spent, String limit);

  /// No description provided for @budgetRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String budgetRemaining(String amount);

  /// No description provided for @budgetOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String budgetOver(String amount);

  /// No description provided for @budgetReached.
  ///
  /// In en, this message translates to:
  /// **'Reached {percent}%'**
  String budgetReached(String percent);

  /// No description provided for @budgetAlertsSetting.
  ///
  /// In en, this message translates to:
  /// **'Warn when a budget threshold is crossed'**
  String get budgetAlertsSetting;

  /// No description provided for @recurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringTitle;

  /// No description provided for @recurringEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recurring entries. Add salary, rent, subscriptions and other regular payments; they\'re recorded automatically on their dates.'**
  String get recurringEmpty;

  /// No description provided for @addRecurring.
  ///
  /// In en, this message translates to:
  /// **'Add recurring'**
  String get addRecurring;

  /// No description provided for @editRecurring.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring'**
  String get editRecurring;

  /// No description provided for @recurringTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get recurringTitleLabel;

  /// No description provided for @recurringTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rent, Netflix, Salary'**
  String get recurringTitleHint;

  /// No description provided for @startsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts on'**
  String get startsOn;

  /// No description provided for @recurringNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String recurringNext(String date);

  /// No description provided for @recurringPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurringPaused;

  /// No description provided for @recurringActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get recurringActive;

  /// No description provided for @recurringAutoNote.
  ///
  /// In en, this message translates to:
  /// **'Entries are created on each date (when the app opens), at most once per date. Loan EMIs are tracked in Loans instead.'**
  String get recurringAutoNote;

  /// No description provided for @recurringGeneratedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} recurring entries recorded'**
  String recurringGeneratedCount(String count);

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reportSummary;

  /// No description provided for @reportCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get reportCategories;

  /// No description provided for @reportAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get reportAccounts;

  /// No description provided for @reportCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get reportCards;

  /// No description provided for @reportLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get reportLoans;

  /// No description provided for @reportDebts.
  ///
  /// In en, this message translates to:
  /// **'Borrow & lend'**
  String get reportDebts;

  /// No description provided for @reportFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get reportFuel;

  /// No description provided for @reportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportPeriod;

  /// No description provided for @reportAllAccounts.
  ///
  /// In en, this message translates to:
  /// **'All accounts'**
  String get reportAllAccounts;

  /// No description provided for @reportAllCards.
  ///
  /// In en, this message translates to:
  /// **'All cards'**
  String get reportAllCards;

  /// No description provided for @reportAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get reportAllCategories;

  /// No description provided for @reportMonthly.
  ///
  /// In en, this message translates to:
  /// **'By month'**
  String get reportMonthly;

  /// No description provided for @reportPeriodSpending.
  ///
  /// In en, this message translates to:
  /// **'Spending in period'**
  String get reportPeriodSpending;

  /// No description provided for @reportPeriodIncome.
  ///
  /// In en, this message translates to:
  /// **'Income in period'**
  String get reportPeriodIncome;

  /// No description provided for @reportTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get reportTransactions;

  /// No description provided for @reportNoVehicles.
  ///
  /// In en, this message translates to:
  /// **'No vehicles to report.'**
  String get reportNoVehicles;

  /// No description provided for @reportNoLoans.
  ///
  /// In en, this message translates to:
  /// **'No loans to report.'**
  String get reportNoLoans;

  /// No description provided for @reportNoCards.
  ///
  /// In en, this message translates to:
  /// **'No cards to report.'**
  String get reportNoCards;

  /// No description provided for @reportNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts to report.'**
  String get reportNoAccounts;

  /// No description provided for @reportNoDebts.
  ///
  /// In en, this message translates to:
  /// **'No borrow/lend records.'**
  String get reportNoDebts;

  /// No description provided for @reportByPerson.
  ///
  /// In en, this message translates to:
  /// **'By person'**
  String get reportByPerson;

  /// No description provided for @reportFuelInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Fuel cost in period'**
  String get reportFuelInPeriod;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions, accounts, loans, people…'**
  String get searchHint;

  /// No description provided for @searchScopeNote.
  ///
  /// In en, this message translates to:
  /// **'Transactions from the last 12 months are searched.'**
  String get searchScopeNote;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResults(String query);

  /// No description provided for @searchStart.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters to search.'**
  String get searchStart;

  /// No description provided for @searchGroupTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get searchGroupTransactions;

  /// No description provided for @searchGroupAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get searchGroupAccounts;

  /// No description provided for @searchGroupCards.
  ///
  /// In en, this message translates to:
  /// **'Credit cards'**
  String get searchGroupCards;

  /// No description provided for @searchGroupLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get searchGroupLoans;

  /// No description provided for @searchGroupDebts.
  ///
  /// In en, this message translates to:
  /// **'Borrow & lend'**
  String get searchGroupDebts;

  /// No description provided for @searchGroupReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get searchGroupReminders;

  /// No description provided for @searchGroupVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get searchGroupVehicles;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystem;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @notificationsStatusOn.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get notificationsStatusOn;

  /// No description provided for @notificationsStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get notificationsStatusOff;

  /// No description provided for @notificationsResync.
  ///
  /// In en, this message translates to:
  /// **'Reschedule all reminders'**
  String get notificationsResync;

  /// No description provided for @notificationsResynced.
  ///
  /// In en, this message translates to:
  /// **'Reminders rescheduled'**
  String get notificationsResynced;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data & sync'**
  String get settingsData;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @guestAccount.
  ///
  /// In en, this message translates to:
  /// **'Guest (this device only)'**
  String get guestAccount;

  /// No description provided for @guestWarning.
  ///
  /// In en, this message translates to:
  /// **'You\'re using a guest account. Sign in with Google so your data is backed up and can be restored on a new phone.'**
  String get guestWarning;

  /// No description provided for @linkGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get linkGoogle;

  /// No description provided for @googleAccountExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Use your existing account?'**
  String get googleAccountExistsTitle;

  /// No description provided for @googleAccountExistsBody.
  ///
  /// In en, this message translates to:
  /// **'This Google account already has data. Switching to it will hide the data you created as a guest on this device. You can\'t merge them.'**
  String get googleAccountExistsBody;

  /// No description provided for @switchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get switchAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutGuestWarning.
  ///
  /// In en, this message translates to:
  /// **'You\'re a guest: signing out permanently loses access to this data unless you sign in with Google first.'**
  String get signOutGuestWarning;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirm;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupTitle;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNow;

  /// No description provided for @backupAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic weekly backup'**
  String get backupAuto;

  /// No description provided for @backupLast.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {time}'**
  String backupLast(String time);

  /// No description provided for @backupNever.
  ///
  /// In en, this message translates to:
  /// **'No backup yet'**
  String get backupNever;

  /// No description provided for @backupDone.
  ///
  /// In en, this message translates to:
  /// **'Backup complete ({count} records)'**
  String backupDone(String count);

  /// No description provided for @backupList.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup'**
  String get backupList;

  /// No description provided for @backupEmpty.
  ///
  /// In en, this message translates to:
  /// **'No backups found for this account.'**
  String get backupEmpty;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Records in the backup will overwrite matching records. Records you added after the backup are kept. Reminders will be rescheduled.'**
  String get restoreConfirmBody;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} records'**
  String restoreDone(String count);

  /// No description provided for @restoreSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count} invalid records were skipped'**
  String restoreSkipped(String count);

  /// No description provided for @backupNeedsAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to use cloud backups.'**
  String get backupNeedsAccount;

  /// No description provided for @backupInProgress.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get backupInProgress;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from Gmail'**
  String get importTitle;

  /// No description provided for @importBody.
  ///
  /// In en, this message translates to:
  /// **'Scan bank and card emails (read-only) and add the transactions found. Duplicates are merged.'**
  String get importBody;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions imported'**
  String importDone(String count);

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored in your private Firebase space. Only you can read it. The app never stores passwords, PINs, CVVs or full card numbers.'**
  String get privacyNote;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @moreMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get moreMoney;

  /// No description provided for @moreTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get moreTools;

  /// No description provided for @moreApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get moreApp;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your money, beautifully organised'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Expenses, accounts, cards, loans and reminders — all in one calm, private place.'**
  String get welcomeBody;

  /// No description provided for @welcomePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your data is private to your account. We never ask for bank passwords, PINs or card numbers.'**
  String get welcomePrivacy;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue without an account'**
  String get continueAsGuest;

  /// No description provided for @guestNote.
  ///
  /// In en, this message translates to:
  /// **'Start right away. Link Google later in Settings to back up and use your data on a new phone.'**
  String get guestNote;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in didn\'t complete. Please try again.'**
  String get signInFailed;

  /// No description provided for @firstLaunchOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to the internet once to set up your private space — after that the app works offline.'**
  String get firstLaunchOffline;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your data stays in your account. Sign in again with the same Google account to see it.'**
  String get signOutBody;

  /// No description provided for @welcomeFeatureTrack.
  ///
  /// In en, this message translates to:
  /// **'Every rupee in one place'**
  String get welcomeFeatureTrack;

  /// No description provided for @welcomeFeatureDues.
  ///
  /// In en, this message translates to:
  /// **'Never miss a due date'**
  String get welcomeFeatureDues;

  /// No description provided for @welcomeFeatureLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans made clear'**
  String get welcomeFeatureLoans;

  /// No description provided for @welcomeFeaturePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private and offline-first'**
  String get welcomeFeaturePrivate;

  /// No description provided for @googleNote.
  ///
  /// In en, this message translates to:
  /// **'Recommended: your data is backed up and follows you to a new phone.'**
  String get googleNote;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing you in…'**
  String get signingIn;

  /// No description provided for @signInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get signInCancelled;

  /// No description provided for @guestUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Guest access is turned off for this app right now. Please continue with Google.'**
  String get guestUnavailable;

  /// No description provided for @guestUnavailableDev.
  ///
  /// In en, this message translates to:
  /// **'Developer: enable Anonymous sign-in in Firebase Console → Authentication → Sign-in method.'**
  String get guestUnavailableDev;

  /// No description provided for @backupConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up your data'**
  String get backupConnectTitle;

  /// No description provided for @backupConnectBody.
  ///
  /// In en, this message translates to:
  /// **'Connect your Google account to back up automatically and restore on a new phone. Without it, your data lives only on this device.'**
  String get backupConnectBody;

  /// No description provided for @backupConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect backup'**
  String get backupConnect;

  /// No description provided for @backupConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup connected'**
  String get backupConnectedTitle;

  /// No description provided for @backupConnectedAs.
  ///
  /// In en, this message translates to:
  /// **'Backing up to {email}'**
  String backupConnectedAs(String email);

  /// No description provided for @backupConnectUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup needs Google sign-in, which isn\'t available on this device.'**
  String get backupConnectUnavailable;

  /// No description provided for @adPrivacyOptions.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy settings'**
  String get adPrivacyOptions;

  /// No description provided for @adPrivacyOptionsHelp.
  ///
  /// In en, this message translates to:
  /// **'Review or change your choice about personalised ads.'**
  String get adPrivacyOptionsHelp;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesManage.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get categoriesManage;

  /// No description provided for @categoryBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get categoryBuiltIn;

  /// No description provided for @categoryYours.
  ///
  /// In en, this message translates to:
  /// **'Your categories'**
  String get categoryYours;

  /// No description provided for @categoryYoursEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any categories yet. Tap + to create one.'**
  String get categoryYoursEmpty;

  /// No description provided for @categoryAdd.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoryAdd;

  /// No description provided for @categoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoryEdit;

  /// No description provided for @categoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameLabel;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pets, Coffee, Freelance'**
  String get categoryNameHint;

  /// No description provided for @categoryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Used for'**
  String get categoryTypeLabel;

  /// No description provided for @categoryIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryIconLabel;

  /// No description provided for @categoryColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoryColorLabel;

  /// No description provided for @categoryNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get categoryNameEmpty;

  /// No description provided for @categoryNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep it under {max} characters'**
  String categoryNameTooLong(String max);

  /// No description provided for @categoryNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A category with this name already exists'**
  String get categoryNameDuplicate;

  /// No description provided for @categoryTypeLocked.
  ///
  /// In en, this message translates to:
  /// **'The type can\'t be changed after creation.'**
  String get categoryTypeLocked;

  /// No description provided for @categoryArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get categoryArchived;

  /// No description provided for @categoryArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get categoryArchive;

  /// No description provided for @categoryRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get categoryRestore;

  /// No description provided for @categoryArchivedNote.
  ///
  /// In en, this message translates to:
  /// **'Archived categories are hidden when adding transactions, but existing transactions keep them.'**
  String get categoryArchivedNote;

  /// No description provided for @categoryInUse.
  ///
  /// In en, this message translates to:
  /// **'This category is used by transactions, a budget or a recurring entry, so it can\'t be deleted. Archive it instead.'**
  String get categoryInUse;

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoryDeleted;

  /// No description provided for @categoryNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get categoryNew;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get categoryRequired;

  /// No description provided for @categoryTapToClear.
  ///
  /// In en, this message translates to:
  /// **'Tap the selected category again to clear it'**
  String get categoryTapToClear;

  /// No description provided for @typeTapToClear.
  ///
  /// In en, this message translates to:
  /// **'Tap again to switch back to Expense'**
  String get typeTapToClear;

  /// No description provided for @paymentRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose how you paid'**
  String get paymentRequired;

  /// No description provided for @receivedRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose where the money went'**
  String get receivedRequired;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash / not tracked'**
  String get paymentCash;

  /// No description provided for @paymentCashHint.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t change any balance'**
  String get paymentCashHint;

  /// No description provided for @paymentNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No accounts or cards yet. Add one to see balances update automatically, or continue with untracked cash.'**
  String get paymentNoneYet;

  /// No description provided for @paymentTapToClear.
  ///
  /// In en, this message translates to:
  /// **'Tap again to clear'**
  String get paymentTapToClear;

  /// No description provided for @paymentPaidFrom.
  ///
  /// In en, this message translates to:
  /// **'Paid from'**
  String get paymentPaidFrom;

  /// No description provided for @paymentPayingAccount.
  ///
  /// In en, this message translates to:
  /// **'Pay the bill from'**
  String get paymentPayingAccount;

  /// No description provided for @paymentDestination.
  ///
  /// In en, this message translates to:
  /// **'Add to account'**
  String get paymentDestination;

  /// No description provided for @addExpenseFromAccount.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addExpenseFromAccount;

  /// No description provided for @adLabel.
  ///
  /// In en, this message translates to:
  /// **'Advertisement'**
  String get adLabel;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Bill, EMI, card and personal reminders'**
  String get notificationChannelDescription;

  /// No description provided for @settingsAds.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get settingsAds;

  /// No description provided for @adFreeTitle.
  ///
  /// In en, this message translates to:
  /// **'No ads for 24 hours'**
  String get adFreeTitle;

  /// No description provided for @adFreeShort.
  ///
  /// In en, this message translates to:
  /// **'Watch a video, no ads for 24 hours'**
  String get adFreeShort;

  /// No description provided for @adFreeWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch a video'**
  String get adFreeWatch;

  /// No description provided for @adFreeHelp.
  ///
  /// In en, this message translates to:
  /// **'Watch one short video and Kept shows no ads for the next 24 hours.'**
  String get adFreeHelp;

  /// No description provided for @adFreeActive.
  ///
  /// In en, this message translates to:
  /// **'Ads are off until {time}'**
  String adFreeActive(String time);

  /// No description provided for @adFreeLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting a video ready…'**
  String get adFreeLoading;

  /// No description provided for @adFreeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No video is available right now. Please try again later.'**
  String get adFreeUnavailable;

  /// No description provided for @adFreeThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks! No ads for the next 24 hours.'**
  String get adFreeThanks;

  /// No description provided for @adFreeNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Watch the video to the end to turn ads off.'**
  String get adFreeNotCompleted;

  /// No description provided for @paymentTypeAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get paymentTypeAccount;

  /// No description provided for @paymentTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentTypeCash;

  /// No description provided for @txTypeRepayBorrow.
  ///
  /// In en, this message translates to:
  /// **'Repay a borrow'**
  String get txTypeRepayBorrow;

  /// No description provided for @repayWhich.
  ///
  /// In en, this message translates to:
  /// **'Which borrow?'**
  String get repayWhich;

  /// No description provided for @repayLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String repayLeft(String amount);

  /// No description provided for @moreTypes.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTypes;

  /// No description provided for @moreDetails.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get moreDetails;

  /// No description provided for @moreCategories.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreCategories;

  /// No description provided for @debtPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt-free plan'**
  String get debtPlanTitle;

  /// No description provided for @debtPlanEmpty.
  ///
  /// In en, this message translates to:
  /// **'No loans, card balances or borrowed money to clear. You\'re debt-free!'**
  String get debtPlanEmpty;

  /// No description provided for @debtPlanDebtFreeBy.
  ///
  /// In en, this message translates to:
  /// **'Debt-free by'**
  String get debtPlanDebtFreeBy;

  /// No description provided for @debtPlanIn.
  ///
  /// In en, this message translates to:
  /// **'in {duration}'**
  String debtPlanIn(String duration);

  /// No description provided for @debtPlanDurationMonths.
  ///
  /// In en, this message translates to:
  /// **'{months} mo'**
  String debtPlanDurationMonths(String months);

  /// No description provided for @debtPlanDurationYears.
  ///
  /// In en, this message translates to:
  /// **'{years} yr {months} mo'**
  String debtPlanDurationYears(String years, String months);

  /// No description provided for @debtPlanTotalOwed.
  ///
  /// In en, this message translates to:
  /// **'Total owed'**
  String get debtPlanTotalOwed;

  /// No description provided for @debtPlanInterestAhead.
  ///
  /// In en, this message translates to:
  /// **'Interest still to pay'**
  String get debtPlanInterestAhead;

  /// No description provided for @debtPlanSavings.
  ///
  /// In en, this message translates to:
  /// **'Saves {amount} and {duration} compared with paying only the minimums'**
  String debtPlanSavings(String amount, String duration);

  /// No description provided for @debtPlanSavingsInterestOnly.
  ///
  /// In en, this message translates to:
  /// **'Saves {amount} compared with paying only the minimums'**
  String debtPlanSavingsInterestOnly(String amount);

  /// No description provided for @debtPlanNeverClears.
  ///
  /// In en, this message translates to:
  /// **'At this payment some debts never clear. Add more each month to finish them.'**
  String get debtPlanNeverClears;

  /// No description provided for @debtPlanChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Your debt going down'**
  String get debtPlanChartTitle;

  /// No description provided for @debtPlanChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Total debt falls from {amount} to zero by {date}'**
  String debtPlanChartSemantics(String amount, String date);

  /// No description provided for @debtPlanMonthlyTitle.
  ///
  /// In en, this message translates to:
  /// **'What you pay each month'**
  String get debtPlanMonthlyTitle;

  /// No description provided for @debtPlanExtraLabel.
  ///
  /// In en, this message translates to:
  /// **'Extra per month'**
  String get debtPlanExtraLabel;

  /// No description provided for @debtPlanMinimums.
  ///
  /// In en, this message translates to:
  /// **'Minimum payments'**
  String get debtPlanMinimums;

  /// No description provided for @debtPlanExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get debtPlanExtra;

  /// No description provided for @debtPlanTotalMonthly.
  ///
  /// In en, this message translates to:
  /// **'Total each month'**
  String get debtPlanTotalMonthly;

  /// No description provided for @debtPlanCommitNote.
  ///
  /// In en, this message translates to:
  /// **'Keep paying this total even after a debt closes. The freed-up money clears the next one.'**
  String get debtPlanCommitNote;

  /// No description provided for @debtPlanWhatIfTitle.
  ///
  /// In en, this message translates to:
  /// **'What if you paid more?'**
  String get debtPlanWhatIfTitle;

  /// No description provided for @debtPlanWhatIfRow.
  ///
  /// In en, this message translates to:
  /// **'+{amount} a month'**
  String debtPlanWhatIfRow(String amount);

  /// No description provided for @debtPlanWhatIfDetail.
  ///
  /// In en, this message translates to:
  /// **'Done by {date}, saves {amount}'**
  String debtPlanWhatIfDetail(String date, String amount);

  /// No description provided for @debtPlanWhatIfStillOpen.
  ///
  /// In en, this message translates to:
  /// **'Some debts still won\'t clear'**
  String get debtPlanWhatIfStillOpen;

  /// No description provided for @debtPlanStrategyTitle.
  ///
  /// In en, this message translates to:
  /// **'Which debt first?'**
  String get debtPlanStrategyTitle;

  /// No description provided for @debtPlanAvalanche.
  ///
  /// In en, this message translates to:
  /// **'Highest interest first'**
  String get debtPlanAvalanche;

  /// No description provided for @debtPlanAvalancheHelp.
  ///
  /// In en, this message translates to:
  /// **'Costs the least overall.'**
  String get debtPlanAvalancheHelp;

  /// No description provided for @debtPlanSnowball.
  ///
  /// In en, this message translates to:
  /// **'Smallest balance first'**
  String get debtPlanSnowball;

  /// No description provided for @debtPlanSnowballHelp.
  ///
  /// In en, this message translates to:
  /// **'Closes debts sooner, so you see progress early.'**
  String get debtPlanSnowballHelp;

  /// No description provided for @debtPlanStrategyResult.
  ///
  /// In en, this message translates to:
  /// **'Done by {date} · {amount} interest'**
  String debtPlanStrategyResult(String date, String amount);

  /// No description provided for @debtPlanCheapest.
  ///
  /// In en, this message translates to:
  /// **'Lowest cost'**
  String get debtPlanCheapest;

  /// No description provided for @debtPlanThisMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay this in {month}'**
  String debtPlanThisMonthTitle(String month);

  /// No description provided for @debtPlanFocus.
  ///
  /// In en, this message translates to:
  /// **'Put your extra here'**
  String get debtPlanFocus;

  /// No description provided for @debtPlanRoadmapTitle.
  ///
  /// In en, this message translates to:
  /// **'Your roadmap'**
  String get debtPlanRoadmapTitle;

  /// No description provided for @debtPlanStepCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared by {date}'**
  String debtPlanStepCleared(String date);

  /// No description provided for @debtPlanStepOpen.
  ///
  /// In en, this message translates to:
  /// **'Not cleared at this payment'**
  String get debtPlanStepOpen;

  /// No description provided for @debtPlanRate.
  ///
  /// In en, this message translates to:
  /// **'{rate}% a year'**
  String debtPlanRate(String rate);

  /// No description provided for @debtPlanRateEstimated.
  ///
  /// In en, this message translates to:
  /// **'{rate}% a year (estimated)'**
  String debtPlanRateEstimated(String rate);

  /// No description provided for @debtPlanNoInterest.
  ///
  /// In en, this message translates to:
  /// **'No interest'**
  String get debtPlanNoInterest;

  /// No description provided for @debtPlanSetRate.
  ///
  /// In en, this message translates to:
  /// **'Set interest rate'**
  String get debtPlanSetRate;

  /// No description provided for @debtPlanSetRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Interest rate for {name}'**
  String debtPlanSetRateTitle(String name);

  /// No description provided for @debtPlanEstimatedWarning.
  ///
  /// In en, this message translates to:
  /// **'Some cards use an estimated {rate}% interest rate. Set the real rate from your statement for an accurate plan.'**
  String debtPlanEstimatedWarning(String rate);

  /// No description provided for @debtPlanLowPayment.
  ///
  /// In en, this message translates to:
  /// **'{names}: the minimum payment doesn\'t cover the interest, so this balance grows unless you pay more.'**
  String debtPlanLowPayment(String names);

  /// No description provided for @debtPlanTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear it faster'**
  String get debtPlanTipsTitle;

  /// No description provided for @debtPlanTipOverdue.
  ///
  /// In en, this message translates to:
  /// **'Clear overdue payments first. Late fees and penalty interest cost more than anything in this plan.'**
  String get debtPlanTipOverdue;

  /// No description provided for @debtPlanTipCardInterest.
  ///
  /// In en, this message translates to:
  /// **'Your cards cost about {amount} in interest this month. Avoid new spending on them until they are cleared.'**
  String debtPlanTipCardInterest(String amount);

  /// No description provided for @debtPlanTipUtilization.
  ///
  /// In en, this message translates to:
  /// **'{names}: over 30% of the limit is in use. Bringing it lower can help your credit score.'**
  String debtPlanTipUtilization(String names);

  /// No description provided for @debtPlanTipConsolidate.
  ///
  /// In en, this message translates to:
  /// **'Ask your bank about moving card dues to a lower-rate loan or EMI. Do it only if the total cost, with fees, is lower.'**
  String get debtPlanTipConsolidate;

  /// No description provided for @debtPlanAssumptions.
  ///
  /// In en, this message translates to:
  /// **'Estimate only. Assumes no new card spending, on-time payments and unchanged rates. Lenders may charge for prepayment, so check first.'**
  String get debtPlanAssumptions;

  /// No description provided for @cardAnnualRate.
  ///
  /// In en, this message translates to:
  /// **'Interest rate (% a year)'**
  String get cardAnnualRate;

  /// No description provided for @cardAnnualRateHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown on your statement. Used by the Debt-free plan.'**
  String get cardAnnualRateHelp;

  /// No description provided for @extraMoneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Got extra money?'**
  String get extraMoneyTitle;

  /// No description provided for @extraMoneySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bonus, arrears or side income: see which debt to close with it.'**
  String get extraMoneySubtitle;

  /// No description provided for @extraMoneyAction.
  ///
  /// In en, this message translates to:
  /// **'See where to put it'**
  String get extraMoneyAction;

  /// No description provided for @extraMoneyDetected.
  ///
  /// In en, this message translates to:
  /// **'{amount} more income than usual this month. Put it to work on your debt.'**
  String extraMoneyDetected(String amount);

  /// No description provided for @extraMoneyIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter the extra amount you received and we\'ll show which loan, EMI or card to pay.'**
  String get extraMoneyIntro;

  /// No description provided for @extraMoneyAmount.
  ///
  /// In en, this message translates to:
  /// **'Extra money received'**
  String get extraMoneyAmount;

  /// No description provided for @extraMoneyRecordIncome.
  ///
  /// In en, this message translates to:
  /// **'Add it to my income'**
  String get extraMoneyRecordIncome;

  /// No description provided for @extraMoneyKeepReserve.
  ///
  /// In en, this message translates to:
  /// **'Keep some as emergency money'**
  String get extraMoneyKeepReserve;

  /// No description provided for @extraMoneyKeepReserveHelp.
  ///
  /// In en, this message translates to:
  /// **'Your savings are below 3 months of expenses and payments. Up to 25% is set aside.'**
  String get extraMoneyKeepReserveHelp;

  /// No description provided for @extraMoneyDoThis.
  ///
  /// In en, this message translates to:
  /// **'Do this'**
  String get extraMoneyDoThis;

  /// No description provided for @extraMoneyCloses.
  ///
  /// In en, this message translates to:
  /// **'Closes this debt'**
  String get extraMoneyCloses;

  /// No description provided for @extraMoneyPartPayment.
  ///
  /// In en, this message translates to:
  /// **'Part payment'**
  String get extraMoneyPartPayment;

  /// No description provided for @extraMoneyKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep as emergency money'**
  String get extraMoneyKeep;

  /// No description provided for @extraMoneyLeftover.
  ///
  /// In en, this message translates to:
  /// **'Left over for you'**
  String get extraMoneyLeftover;

  /// No description provided for @extraMoneyResult.
  ///
  /// In en, this message translates to:
  /// **'What this does'**
  String get extraMoneyResult;

  /// No description provided for @extraMoneyClearsAll.
  ///
  /// In en, this message translates to:
  /// **'This clears all your debt!'**
  String get extraMoneyClearsAll;

  /// No description provided for @extraMoneyNewDate.
  ///
  /// In en, this message translates to:
  /// **'Debt-free by {date}'**
  String extraMoneyNewDate(String date);

  /// No description provided for @extraMoneyInterestSaved.
  ///
  /// In en, this message translates to:
  /// **'Interest saved'**
  String get extraMoneyInterestSaved;

  /// No description provided for @extraMoneySooner.
  ///
  /// In en, this message translates to:
  /// **'Finishes {duration} sooner'**
  String extraMoneySooner(String duration);

  /// No description provided for @extraMoneyFreed.
  ///
  /// In en, this message translates to:
  /// **'Monthly payments that stop'**
  String get extraMoneyFreed;

  /// No description provided for @extraMoneyInstead.
  ///
  /// In en, this message translates to:
  /// **'Prefer one less EMI? {name} can be closed outright for {amount}, which stops {monthly} a month.'**
  String extraMoneyInstead(String name, String amount, String monthly);

  /// No description provided for @extraMoneyCaution.
  ///
  /// In en, this message translates to:
  /// **'Tap a debt to record the payment. Ask your lender for the exact closing amount and any prepayment charges first.'**
  String get extraMoneyCaution;

  /// No description provided for @debtProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get debtProgressTitle;

  /// No description provided for @debtProgressPaid.
  ///
  /// In en, this message translates to:
  /// **'{paid} paid off of {peak}'**
  String debtProgressPaid(String paid, String peak);

  /// No description provided for @debtProgressJustCleared.
  ///
  /// In en, this message translates to:
  /// **'Well done! You cleared {names}.'**
  String debtProgressJustCleared(String names);

  /// No description provided for @debtLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt load'**
  String get debtLoadTitle;

  /// No description provided for @debtLoadShare.
  ///
  /// In en, this message translates to:
  /// **'Required payments take {percent}% of your usual income.'**
  String debtLoadShare(String percent);

  /// No description provided for @debtLoadHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get debtLoadHealthy;

  /// No description provided for @debtLoadHealthyHelp.
  ///
  /// In en, this message translates to:
  /// **'You have room to pay extra and finish sooner.'**
  String get debtLoadHealthyHelp;

  /// No description provided for @debtLoadWatch.
  ///
  /// In en, this message translates to:
  /// **'Be careful'**
  String get debtLoadWatch;

  /// No description provided for @debtLoadWatchHelp.
  ///
  /// In en, this message translates to:
  /// **'Avoid taking on new EMIs until this comes down.'**
  String get debtLoadWatchHelp;

  /// No description provided for @debtLoadHigh.
  ///
  /// In en, this message translates to:
  /// **'Too high'**
  String get debtLoadHigh;

  /// No description provided for @debtLoadHighHelp.
  ///
  /// In en, this message translates to:
  /// **'Above 40% is hard to sustain. Avoid new loans and consider asking your lender about restructuring.'**
  String get debtLoadHighHelp;

  /// No description provided for @debtLoadOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Usual spending and payments are {amount} a month more than your usual income.'**
  String debtLoadOverBudget(String amount);

  /// No description provided for @debtPlanSuggestedExtra.
  ///
  /// In en, this message translates to:
  /// **'Your last few months suggest you can afford {amount} extra a month.'**
  String debtPlanSuggestedExtra(String amount);

  /// No description provided for @debtPlanUseSuggested.
  ///
  /// In en, this message translates to:
  /// **'Use this amount'**
  String get debtPlanUseSuggested;

  /// No description provided for @debtPlanReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me each month'**
  String get debtPlanReminder;

  /// No description provided for @debtPlanReminderHelp.
  ///
  /// In en, this message translates to:
  /// **'A notification on the 1st says what to pay.'**
  String get debtPlanReminderHelp;

  /// No description provided for @debtPlanReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt plan: pay {amount} to {name}'**
  String debtPlanReminderTitle(String amount, String name);

  /// No description provided for @debtPlanCompareSwitch.
  ///
  /// In en, this message translates to:
  /// **'Compare the cost'**
  String get debtPlanCompareSwitch;

  /// No description provided for @debtSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to a cheaper loan?'**
  String get debtSwitchTitle;

  /// No description provided for @debtSwitchIntro.
  ///
  /// In en, this message translates to:
  /// **'Compare keeping a balance at its current rate with a card-to-EMI plan, balance transfer or personal loan.'**
  String get debtSwitchIntro;

  /// No description provided for @debtSwitchBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount to move'**
  String get debtSwitchBalance;

  /// No description provided for @debtSwitchCurrentRate.
  ///
  /// In en, this message translates to:
  /// **'Current interest rate (% a year)'**
  String get debtSwitchCurrentRate;

  /// No description provided for @debtSwitchNewRate.
  ///
  /// In en, this message translates to:
  /// **'New interest rate (% a year)'**
  String get debtSwitchNewRate;

  /// No description provided for @debtSwitchMonths.
  ///
  /// In en, this message translates to:
  /// **'Months to repay'**
  String get debtSwitchMonths;

  /// No description provided for @debtSwitchFee.
  ///
  /// In en, this message translates to:
  /// **'Processing fee'**
  String get debtSwitchFee;

  /// No description provided for @debtSwitchFeeHelp.
  ///
  /// In en, this message translates to:
  /// **'Include GST. Some EMI offers charge interest at a flat rate, so ask for the reducing-balance rate.'**
  String get debtSwitchFeeHelp;

  /// No description provided for @debtSwitchResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get debtSwitchResult;

  /// No description provided for @debtSwitchWorthIt.
  ///
  /// In en, this message translates to:
  /// **'Worth it: saves {amount} after the fee'**
  String debtSwitchWorthIt(String amount);

  /// No description provided for @debtSwitchNotWorthIt.
  ///
  /// In en, this message translates to:
  /// **'Not worth it: the fee cancels out the saving'**
  String get debtSwitchNotWorthIt;

  /// No description provided for @debtSwitchKeepInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest if you stay'**
  String get debtSwitchKeepInterest;

  /// No description provided for @debtSwitchNewInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest if you move'**
  String get debtSwitchNewInterest;

  /// No description provided for @debtSwitchFeeAmount.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get debtSwitchFeeAmount;

  /// No description provided for @debtSwitchNewEmi.
  ///
  /// In en, this message translates to:
  /// **'New monthly EMI'**
  String get debtSwitchNewEmi;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ml'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ml':
      return AppLocalizationsMl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
