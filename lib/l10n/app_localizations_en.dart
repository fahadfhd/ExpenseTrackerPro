// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kept';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get confirm => 'Confirm';

  @override
  String get apply => 'Apply';

  @override
  String get reset => 'Reset';

  @override
  String get clear => 'Clear';

  @override
  String get none => 'None';

  @override
  String get all => 'All';

  @override
  String get optional => 'Optional';

  @override
  String get required => 'Required';

  @override
  String get notes => 'Notes';

  @override
  String get description => 'Description';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get amount => 'Amount';

  @override
  String get name => 'Name';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get archived => 'Archived';

  @override
  String get seeAll => 'See all';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get thisMonth => 'This month';

  @override
  String get pickDate => 'Pick a date';

  @override
  String get pickTime => 'Pick a time';

  @override
  String get noDate => 'No date';

  @override
  String deleteConfirmTitle(String item) {
    return 'Delete $item?';
  }

  @override
  String get deleteConfirmBody => 'This cannot be undone.';

  @override
  String get deleted => 'Deleted';

  @override
  String get saved => 'Saved';

  @override
  String get loading => 'Loading…';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get invalidAmount => 'Enter a valid amount greater than zero';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String get nameRequired => 'Enter a name';

  @override
  String valueBetween(String min, String max) {
    return 'Enter a value between $min and $max';
  }

  @override
  String comingFromInstallments(String count, String total) {
    return '$count of $total';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navLoans => 'Loans';

  @override
  String get navMore => 'More';

  @override
  String get failureNetwork =>
      'You\'re offline or the connection is unstable. Changes are saved on this device and will sync when you\'re back online.';

  @override
  String get failurePermission =>
      'You don\'t have permission to do that. Try signing in again.';

  @override
  String get failureUnauthenticated =>
      'Your session has expired. Please sign in again.';

  @override
  String get failureNotFound => 'That item no longer exists.';

  @override
  String get failureInvalidData => 'The data is invalid or damaged.';

  @override
  String get failureUnsupportedSchema =>
      'This backup was made by a newer version of the app. Update the app to restore it.';

  @override
  String get failureNotification =>
      'A reminder could not be scheduled on this device.';

  @override
  String get failureUnknown => 'Something went wrong. Please try again.';

  @override
  String syncRejected(String reason) {
    return 'A change could not be saved to the cloud: $reason';
  }

  @override
  String get syncAllSynced => 'All changes synced';

  @override
  String syncPending(String count) {
    return '$count change(s) waiting to sync';
  }

  @override
  String syncLastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get failureSignInMethodDisabled =>
      'This sign-in option isn\'t available right now. Please use another option.';

  @override
  String get undo => 'Undo';

  @override
  String get discardTitle => 'Discard changes?';

  @override
  String get discardBody => 'You have unsaved changes that will be lost.';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get restored => 'Restored';

  @override
  String get txTypeExpense => 'Expense';

  @override
  String get txTypeIncome => 'Income';

  @override
  String get txTypeTransfer => 'Transfer';

  @override
  String get txTypeCreditCardExpense => 'Card expense';

  @override
  String get txTypeCreditCardPayment => 'Card bill payment';

  @override
  String get txTypeLoanPayment => 'Loan payment';

  @override
  String get txTypeRefund => 'Refund';

  @override
  String get txTypeBorrowed => 'Borrowed';

  @override
  String get txTypeLent => 'Lent';

  @override
  String get txTypeDebtRepayment => 'Repaid debt';

  @override
  String get txTypeDebtCollection => 'Collected debt';

  @override
  String get txStatusCleared => 'Cleared';

  @override
  String get txStatusPending => 'Pending';

  @override
  String get accountTypeSavings => 'Savings account';

  @override
  String get accountTypeCurrent => 'Current account';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeWallet => 'Wallet';

  @override
  String get accountTypeOther => 'Other';

  @override
  String get catFood => 'Food';

  @override
  String get catFoodGroceries => 'Groceries';

  @override
  String get catFoodDining => 'Dining out';

  @override
  String get catFoodDelivery => 'Food delivery';

  @override
  String get catTransport => 'Transport';

  @override
  String get catTransportFuel => 'Fuel';

  @override
  String get catTransportPublic => 'Public transport';

  @override
  String get catTransportCab => 'Cab';

  @override
  String get catTransportParking => 'Parking & tolls';

  @override
  String get catTransportService => 'Vehicle service';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catShoppingClothing => 'Clothing';

  @override
  String get catShoppingElectronics => 'Electronics';

  @override
  String get catShoppingHome => 'Home & kitchen';

  @override
  String get catBills => 'Bills & utilities';

  @override
  String get catBillsElectricity => 'Electricity';

  @override
  String get catBillsWater => 'Water';

  @override
  String get catBillsInternet => 'Internet';

  @override
  String get catBillsPhone => 'Mobile & phone';

  @override
  String get catHousing => 'Housing';

  @override
  String get catHousingRent => 'Rent';

  @override
  String get catHousingMaintenance => 'Maintenance';

  @override
  String get catHealth => 'Health';

  @override
  String get catHealthMedical => 'Doctor & hospital';

  @override
  String get catHealthPharmacy => 'Pharmacy';

  @override
  String get catHealthFitness => 'Fitness';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get catEntertainmentSubscriptions => 'Subscriptions';

  @override
  String get catEntertainmentOutings => 'Movies & outings';

  @override
  String get catEntertainmentTravel => 'Travel & holidays';

  @override
  String get catEducation => 'Education';

  @override
  String get catInsurance => 'Insurance';

  @override
  String get catPersonal => 'Personal care';

  @override
  String get catGifts => 'Gifts & donations';

  @override
  String get catFees => 'Fees & charges';

  @override
  String get catOther => 'Other';

  @override
  String get catSalary => 'Salary';

  @override
  String get catBusiness => 'Business';

  @override
  String get catInterest => 'Interest';

  @override
  String get catInvestment => 'Investments';

  @override
  String get catGiftIncome => 'Gifts received';

  @override
  String get catOtherIncome => 'Other income';

  @override
  String get catTransfer => 'Transfer';

  @override
  String get catDebt => 'Borrow & lend';

  @override
  String get catLoanEmi => 'Loan EMI';

  @override
  String get catCardPayment => 'Card payment';

  @override
  String get freqOnce => 'Once';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqYearly => 'Yearly';

  @override
  String get freqQuarterly => 'Quarterly';

  @override
  String get freqHalfYearly => 'Half-yearly';

  @override
  String everyNDays(String n) {
    return 'Every $n days';
  }

  @override
  String everyNWeeks(String n) {
    return 'Every $n weeks';
  }

  @override
  String everyNMonths(String n) {
    return 'Every $n months';
  }

  @override
  String everyNYears(String n) {
    return 'Every $n years';
  }

  @override
  String get loanStatusActive => 'Active';

  @override
  String get loanStatusCompleted => 'Completed';

  @override
  String get loanStatusClosed => 'Closed';

  @override
  String get loanStatusPrepaid => 'Prepaid';

  @override
  String get installmentPaid => 'Paid';

  @override
  String get installmentSkipped => 'Skipped';

  @override
  String get installmentOverdue => 'Overdue';

  @override
  String get installmentUpcoming => 'Upcoming';

  @override
  String get debtPending => 'Pending';

  @override
  String get debtPartial => 'Partially settled';

  @override
  String get debtSettled => 'Settled';

  @override
  String get debtOverdue => 'Overdue';

  @override
  String get debtBorrowed => 'Borrowed';

  @override
  String get debtLent => 'Lent';

  @override
  String get reminderTypeLoanEmi => 'Loan EMI';

  @override
  String get reminderTypeCreditCard => 'Credit card payment';

  @override
  String get reminderTypeBorrowed => 'Borrowed money';

  @override
  String get reminderTypeLent => 'Lent money';

  @override
  String get reminderTypeGym => 'Gym';

  @override
  String get reminderTypeMeeting => 'Meeting';

  @override
  String get reminderTypeInsurance => 'Insurance';

  @override
  String get reminderTypeSubscription => 'Subscription';

  @override
  String get reminderTypeBill => 'Bill';

  @override
  String get reminderTypeCustom => 'Custom';

  @override
  String get fuelPetrol => 'Petrol';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelCng => 'CNG';

  @override
  String get fuelLpg => 'LPG';

  @override
  String get fuelElectric => 'Electric';

  @override
  String get fuelHybrid => 'Hybrid';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortLargest => 'Largest amount';

  @override
  String get sortSmallest => 'Smallest amount';

  @override
  String get issueAmountNotPositive => 'Amount must be greater than zero.';

  @override
  String get issueAmountTooLarge => 'Amount is too large.';

  @override
  String get issueCategoryMismatch =>
      'Choose a category that matches the transaction type.';

  @override
  String get issueCardRequired => 'Choose a credit card.';

  @override
  String get issueCardNotAllowed =>
      'A credit card can\'t be used for this type.';

  @override
  String get issueSourceAccountRequired =>
      'Choose the account the money leaves.';

  @override
  String get issueDestinationAccountRequired =>
      'Choose the account the money goes to.';

  @override
  String get issueSameTransferAccounts =>
      'Source and destination must be different accounts.';

  @override
  String get issueLoanRequired => 'Choose a loan.';

  @override
  String get issueDebtRecordRequired => 'This needs a borrow/lend record.';

  @override
  String get issueRefundTargetAmbiguous =>
      'A refund goes to either an account or a card, not both.';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get reminderNew => 'New reminder';

  @override
  String get reminderEdit => 'Edit reminder';

  @override
  String get reminderTitleLabel => 'Title';

  @override
  String get reminderTitleHint => 'e.g. Gym, Pay electricity bill';

  @override
  String get reminderTypeLabel => 'Type';

  @override
  String get reminderRepeat => 'Repeat';

  @override
  String get reminderEvery => 'Every';

  @override
  String get reminderUntil => 'Ends';

  @override
  String get reminderNeverEnds => 'Never';

  @override
  String get reminderNotify => 'Notify me';

  @override
  String get reminderOffsetAtTime => 'At the time';

  @override
  String reminderOffsetMinutes(String n) {
    return '$n min before';
  }

  @override
  String reminderOffsetHours(String n) {
    return '$n h before';
  }

  @override
  String reminderOffsetDays(String n) {
    return '$n day(s) before';
  }

  @override
  String get reminderOffsetCustom => 'Custom…';

  @override
  String get reminderOffsetCustomTitle => 'Days before';

  @override
  String get reminderEnabled => 'Enabled';

  @override
  String get reminderDisabled => 'Disabled';

  @override
  String reminderNext(String date) {
    return 'Next: $date';
  }

  @override
  String get reminderEnded => 'No upcoming occurrences';

  @override
  String reminderLinked(String module) {
    return 'Managed from $module. You can change time, alerts and on/off here.';
  }

  @override
  String get remindersEmpty =>
      'No reminders yet. Add gym sessions, bills, renewals or anything else you don\'t want to miss.';

  @override
  String get remindersUpcoming => 'Upcoming';

  @override
  String get remindersInactive => 'Off or finished';

  @override
  String get notificationsOff =>
      'Notifications are turned off for this app, so reminders won\'t alert you.';

  @override
  String get notificationsEnable => 'Turn on';

  @override
  String notifDue(String what) {
    return '$what · due now';
  }

  @override
  String notifInDays(String what, String n) {
    return '$what · in $n day(s)';
  }

  @override
  String notifInHours(String what, String n) {
    return '$what · in $n h';
  }

  @override
  String notifInMinutes(String what, String n) {
    return '$what · in $n min';
  }

  @override
  String reminderLoanTitle(String name) {
    return 'EMI due: $name';
  }

  @override
  String reminderCardTitle(String name) {
    return 'Card bill due: $name';
  }

  @override
  String reminderBorrowedTitle(String person) {
    return 'Repay $person';
  }

  @override
  String reminderLentTitle(String person) {
    return 'Collect from $person';
  }

  @override
  String get moduleLoans => 'Loans';

  @override
  String get moduleCards => 'Credit cards';

  @override
  String get moduleBorrowLend => 'Borrow & lend';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get duplicateTransaction => 'Duplicate transaction';

  @override
  String get transactionDetails => 'Transaction';

  @override
  String get txMoreTypes => 'More';

  @override
  String get category => 'Category';

  @override
  String get subcategory => 'Subcategory';

  @override
  String get paidWith => 'Paid with';

  @override
  String get receivedIn => 'Received in';

  @override
  String get fromAccount => 'From account';

  @override
  String get toAccount => 'To account';

  @override
  String get creditCard => 'Credit card';

  @override
  String get refundTo => 'Refund to';

  @override
  String get cashUntracked => 'Cash / not tracked';

  @override
  String get merchantOrPerson => 'Merchant or person';

  @override
  String get tags => 'Tags';

  @override
  String get tagsHint => 'Comma separated, e.g. trip, office';

  @override
  String get markPending => 'Pending (not yet paid)';

  @override
  String get markPendingHelp =>
      'Pending items don\'t change balances or totals until cleared.';

  @override
  String get noAccountsHint =>
      'Add an account or card to track balances. You can still record cash spending.';

  @override
  String get transactionSaved => 'Transaction saved';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String budgetWarning(String budget, String percent) {
    return '$budget budget is at $percent% for this month';
  }

  @override
  String get budgetOverall => 'Overall';

  @override
  String managedElsewhere(String module) {
    return 'This entry is managed from $module. Open it there to change or remove it.';
  }

  @override
  String get moduleVehicles => 'Vehicles';

  @override
  String get searchTransactions =>
      'Search description, category, amount, date…';

  @override
  String get filters => 'Filters';

  @override
  String filtersActive(String count) {
    return 'Filters ($count)';
  }

  @override
  String get sortBy => 'Sort by';

  @override
  String get accountsLabel => 'Accounts';

  @override
  String get cardsLabel => 'Cards';

  @override
  String get categoriesLabel => 'Categories';

  @override
  String get amountRange => 'Amount range';

  @override
  String get minAmount => 'Min';

  @override
  String get maxAmount => 'Max';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get dateRange => 'Date range';

  @override
  String get customRange => 'Custom range';

  @override
  String get backToMonth => 'Back to month view';

  @override
  String get listView => 'List';

  @override
  String get calendarView => 'Calendar';

  @override
  String get noTransactions =>
      'No transactions in this period yet. Tap + to add your first one.';

  @override
  String get noMatches => 'No transactions match your search or filters.';

  @override
  String dayTotal(String amount) {
    return 'Spent $amount';
  }

  @override
  String get moneyIn => 'In';

  @override
  String get moneyOut => 'Out';

  @override
  String transactionsCount(String count) {
    return '$count transactions';
  }

  @override
  String get recurringGenerated => 'Created by recurring rule';

  @override
  String importedFrom(String source) {
    return 'Imported ($source)';
  }

  @override
  String get selectDay => 'Select a day to see its transactions';

  @override
  String get noTransactionsOnDay => 'Nothing recorded on this day.';

  @override
  String get status => 'Status';

  @override
  String get entriesLabel => 'Entries';

  @override
  String get typeLabel => 'Type';

  @override
  String dashboardSpentThisMonth(String month) {
    return 'Spent in $month';
  }

  @override
  String get dashboardIncome => 'Income';

  @override
  String get dashboardSpending => 'Spending';

  @override
  String get dashboardSavings => 'Savings';

  @override
  String dashboardSavingsRate(String percent) {
    return '$percent% of income saved';
  }

  @override
  String dashboardOverspent(String amount) {
    return 'Spent $amount more than earned';
  }

  @override
  String get dashboardNoIncome => 'No income recorded this month';

  @override
  String get dashboardEmi => 'EMIs paid';

  @override
  String get dashboardCardSpending => 'Card spending';

  @override
  String get dashboardBorrowed => 'Borrowed';

  @override
  String get dashboardLent => 'Lent';

  @override
  String get dashboardPendingPayments => 'Pending payments';

  @override
  String get dashboardScopeAll => 'All accounts & cards';

  @override
  String get dashboardUpcoming => 'Coming up';

  @override
  String get dashboardUpcomingEmpty => 'No dues in the next 30 days.';

  @override
  String get dashboardOverdue => 'Overdue';

  @override
  String dashboardDueOn(String date) {
    return 'Due $date';
  }

  @override
  String get dashboardRecent => 'Recent transactions';

  @override
  String get dashboardBudget => 'Monthly budget';

  @override
  String dashboardBudgetLeft(String amount) {
    return '$amount left';
  }

  @override
  String dashboardBudgetOver(String amount) {
    return '$amount over budget';
  }

  @override
  String get chartByCategory => 'Spending by category';

  @override
  String get chartDaily => 'Daily spending';

  @override
  String get chartIncomeVsSpending => 'Income vs spending';

  @override
  String get chartByAccount => 'Spending by account';

  @override
  String get chartByCard => 'Spending by card';

  @override
  String get chartTrend => 'Monthly spending trend';

  @override
  String get chartNoData => 'No spending to chart for this period.';

  @override
  String get chartOther => 'Other';

  @override
  String chartSemanticsTotal(String title, String amount) {
    return '$title. Total $amount.';
  }

  @override
  String get netWorth => 'Net worth';

  @override
  String get searchEverything => 'Search everything';

  @override
  String get emptyDashboardTitle => 'Welcome! Let\'s set things up';

  @override
  String get emptyDashboardBody =>
      'Add an account or card, then record your first expense. Everything works offline and syncs when you\'re online.';

  @override
  String get addAccount => 'Add account';

  @override
  String get addCard => 'Add card';

  @override
  String get addExpense => 'Add expense';

  @override
  String get accountsTitle => 'Accounts & cards';

  @override
  String get accountsTab => 'Accounts';

  @override
  String get cardsTab => 'Credit cards';

  @override
  String get newAccount => 'New account';

  @override
  String get editAccount => 'Edit account';

  @override
  String get accountName => 'Account name';

  @override
  String get accountNameHint => 'e.g. Salary account, Wallet';

  @override
  String get bankName => 'Bank name';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get openingBalanceHelp =>
      'Balance on the day you start tracking. Transactions recorded here adjust it automatically.';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get noCredentialsNote =>
      'Never enter passwords, PINs or card numbers. This app doesn\'t need them.';

  @override
  String get accountsEmpty =>
      'No accounts yet. Add your bank accounts, cash or wallets to see balances.';

  @override
  String get assets => 'Accounts';

  @override
  String get cardDebt => 'Card dues';

  @override
  String showArchived(String count) {
    return 'Archived ($count)';
  }

  @override
  String get accountInUse =>
      'This account is used by transactions, loans, borrow/lend records, recurring entries or a card, so it can\'t be deleted. Archive it instead to hide it.';

  @override
  String get accountArchived => 'Account archived';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get noActivity => 'No transactions linked yet.';

  @override
  String get inThisMonth => 'In this month';

  @override
  String get outThisMonth => 'Out this month';

  @override
  String get newCard => 'New credit card';

  @override
  String get editCard => 'Edit credit card';

  @override
  String get cardName => 'Card name';

  @override
  String get cardNameHint => 'e.g. Millennia, Amazon Pay';

  @override
  String get last4 => 'Last 4 digits';

  @override
  String get last4Help =>
      'Only to recognise the card. Never enter the full number.';

  @override
  String get last4Invalid => 'Enter exactly 4 digits';

  @override
  String get creditLimit => 'Credit limit';

  @override
  String get currentOutstanding => 'Current outstanding';

  @override
  String get currentOutstandingHelp =>
      'What you owe today. New card transactions update it automatically.';

  @override
  String get statementDay => 'Statement day';

  @override
  String get dueDay => 'Payment due day';

  @override
  String get dayOfMonth => 'Day of month (1–31)';

  @override
  String get minimumDuePercent => 'Minimum due %';

  @override
  String get minimumDuePercentHelp =>
      'Used to estimate the minimum due. Check your statement for the exact figure.';

  @override
  String get linkedAccount => 'Pays from account';

  @override
  String get cardsEmpty =>
      'No credit cards yet. Add one to track limits, utilisation and due dates.';

  @override
  String get outstanding => 'Outstanding';

  @override
  String get available => 'Available';

  @override
  String get utilization => 'Utilisation';

  @override
  String utilizationValue(String percent) {
    return '$percent% used';
  }

  @override
  String get statement => 'Last statement';

  @override
  String get statementBalance => 'Statement balance';

  @override
  String get totalDue => 'Total due';

  @override
  String get minimumDueEstimate => 'Minimum due (est.)';

  @override
  String get dueDate => 'Due date';

  @override
  String get paidInFull => 'Paid';

  @override
  String get payBill => 'Pay bill';

  @override
  String get addCardExpense => 'Add expense';

  @override
  String get cardSpending6m => 'Card spending, last 6 months';

  @override
  String get cardInUse =>
      'This card is used by transactions or recurring entries, so it can\'t be deleted. Archive it instead.';

  @override
  String get cardReminderNote =>
      'A due-date reminder is created automatically. Adjust it in Reminders.';

  @override
  String get recalcBalances => 'Recalculate balances';

  @override
  String get recalcBalancesHelp =>
      'Rebuilds every account and card balance from your full transaction history. Use this if a balance looks wrong.';

  @override
  String get recalcDone => 'Balances recalculated';

  @override
  String get dayInvalid => 'Enter a day between 1 and 31';

  @override
  String get accountTypeLabel => 'Account type';

  @override
  String get outstandingWhenAdded => 'Outstanding when added';

  @override
  String outstandingWhenAddedHelp(String current) {
    return 'The card\'s current outstanding is $current, which already includes transactions recorded in the app. Only change this to correct the starting amount.';
  }

  @override
  String get cardDueDate => 'Payment due date';

  @override
  String get cardDueDateHelp => 'Repeats every month on this day.';

  @override
  String get cardDueDateRequired => 'Choose the payment due date';

  @override
  String get cardMoreDetails => 'More details (optional)';

  @override
  String get loansTitle => 'Loans';

  @override
  String get loansEmpty =>
      'No loans yet. Add a loan to track EMIs, interest and what\'s left to pay.';

  @override
  String get addLoan => 'Add loan';

  @override
  String get newLoan => 'New loan';

  @override
  String get editLoan => 'Edit loan';

  @override
  String get loanName => 'Loan name';

  @override
  String get loanNameHint => 'e.g. Home loan, Car loan';

  @override
  String get lender => 'Lender';

  @override
  String get principal => 'Principal amount';

  @override
  String get interestRate => 'Interest rate (% per year)';

  @override
  String get tenure => 'Number of installments';

  @override
  String tenureMonthsHelp(String months) {
    return '$months months';
  }

  @override
  String get firstEmiDate => 'First EMI date';

  @override
  String get emiAmount => 'EMI amount';

  @override
  String get payFromAccount => 'Pay EMIs from';

  @override
  String get loanReminder => 'Remind me before each EMI';

  @override
  String get loansOutstanding => 'Total outstanding';

  @override
  String get loansMonthlyEmi => 'Monthly EMIs';

  @override
  String loansActive(String count) {
    return '$count active';
  }

  @override
  String loanOverdueCount(String count) {
    return '$count overdue';
  }

  @override
  String loanProgress(String paid, String total) {
    return '$paid of $total EMIs paid';
  }

  @override
  String get outstandingPrincipal => 'Outstanding principal';

  @override
  String get nextEmi => 'Next EMI';

  @override
  String nextEmiOn(String number, String date) {
    return '#$number on $date';
  }

  @override
  String get noNextEmi => 'No EMIs left';

  @override
  String get paidEmis => 'Paid EMIs';

  @override
  String get remainingEmis => 'Remaining EMIs';

  @override
  String get totalInterest => 'Total interest';

  @override
  String get paidInterest => 'Interest paid';

  @override
  String get remainingInterest => 'Interest remaining';

  @override
  String get principalPaid => 'Principal paid';

  @override
  String get prepaid => 'Prepaid';

  @override
  String get principalVsInterest => 'Principal vs interest';

  @override
  String get principalLabel => 'Principal';

  @override
  String get interestLabel => 'Interest';

  @override
  String get markPaid => 'Mark EMI paid';

  @override
  String markPaidTitle(String number) {
    return 'EMI #$number';
  }

  @override
  String get paidOn => 'Paid on';

  @override
  String get skipEmi => 'Mark as skipped';

  @override
  String get clearMark => 'Undo mark';

  @override
  String get recordPrepayment => 'Record prepayment';

  @override
  String get prepaymentAmount => 'Prepayment amount';

  @override
  String get prepaymentMode => 'After the prepayment';

  @override
  String get prepayReduceTenure => 'Keep EMI, finish sooner';

  @override
  String get prepayReduceEmi => 'Keep tenure, lower EMI';

  @override
  String get prepayPreview => 'What changes';

  @override
  String prepayNewEmi(String before, String after) {
    return 'EMI: $before → $after';
  }

  @override
  String prepayNewTenure(String before, String after) {
    return 'Remaining EMIs: $before → $after';
  }

  @override
  String prepayInterestSaved(String amount) {
    return 'Interest saved: $amount';
  }

  @override
  String prepayOutstanding(String before, String after) {
    return 'Outstanding: $before → $after';
  }

  @override
  String get prepayExplain =>
      'Prepayments reduce principal immediately. You choose whether the EMI stays the same (loan ends earlier) or the number of EMIs stays the same (EMI goes down). Nothing changes until you confirm.';

  @override
  String get prepayments => 'Prepayments';

  @override
  String get schedule => 'Repayment schedule';

  @override
  String scheduleRowSemantics(
    String number,
    String date,
    String emi,
    String principal,
    String interest,
    String balance,
    String status,
  ) {
    return 'EMI $number, due $date, $emi, principal $principal, interest $interest, balance $balance, $status';
  }

  @override
  String get balanceLabel => 'Balance';

  @override
  String get emiDoesNotCoverInterest =>
      'This EMI doesn\'t cover the interest, so the loan would never be repaid. Check the EMI, rate and principal.';

  @override
  String unappliedPrepayment(String amount) {
    return '$amount of prepayments exceeded what was owed and was not applied.';
  }

  @override
  String get closeLoan => 'Mark loan closed';

  @override
  String get reopenLoan => 'Reopen loan';

  @override
  String get loanClosedNote => 'Closed loans stop sending reminders.';

  @override
  String get emiCalculator => 'EMI calculator';

  @override
  String get rateFinder => 'Interest rate finder';

  @override
  String get financialTools => 'Financial tools';

  @override
  String get calcResultEmi => 'Monthly EMI';

  @override
  String get calcTotalPayment => 'Total payment';

  @override
  String calcInterestPercent(String percent) {
    return 'Interest is $percent% of principal';
  }

  @override
  String get calcFirstEmiSplit => 'First EMI split';

  @override
  String get calcRateResult => 'Approximate interest rate';

  @override
  String calcRateValue(String rate) {
    return '$rate% per year';
  }

  @override
  String get calcRateImpossible =>
      'These numbers can\'t work: the EMIs add up to less than the principal.';

  @override
  String get calcRateTooHigh =>
      'The implied rate is unrealistically high. Check the inputs.';

  @override
  String get calcRateZero =>
      '0% — the EMIs exactly repay the principal (no interest).';

  @override
  String get useThisRate => 'Use this rate';

  @override
  String get calcEnterValues => 'Enter the values to see the result.';

  @override
  String get emiFrequencyLabel => 'EMI frequency';

  @override
  String get loanRateCalculated => 'Interest rate (calculated)';

  @override
  String get loanRateFromEmi =>
      'Worked out from the principal, EMI amount and number of EMIs, so you don\'t have to look it up.';

  @override
  String loanInterestSummary(String interest, String total) {
    return 'Total interest $interest · total payable $total';
  }

  @override
  String get loanEmisPaid => 'EMIs already paid';

  @override
  String get loanEmisPaidHelp =>
      'How many EMIs you\'ve already paid. They\'re marked paid in the schedule; no account balance changes.';

  @override
  String loanEmisPaidInvalid(String max) {
    return 'Enter a number from 0 to $max';
  }

  @override
  String get loanFirstEmiDate => 'First EMI date';

  @override
  String get loanNextEmiDate => 'Next EMI date';

  @override
  String loanNextEmiHelp(String number) {
    return 'Due date of EMI #$number';
  }

  @override
  String get loanKnowRate => 'I know the interest rate instead';

  @override
  String get loanUseEmi => 'Use the EMI amount instead';

  @override
  String loanEmiCalculated(String amount) {
    return 'Calculated EMI: $amount';
  }

  @override
  String get loanPayFromHelp =>
      'Optional. Used as the default account when you mark an EMI paid.';

  @override
  String loanSavedWithPaid(String count) {
    return 'Loan saved. $count EMIs marked as paid.';
  }

  @override
  String get borrowLendTitle => 'Borrow & lend';

  @override
  String get debtsEmpty =>
      'Nothing here yet. Record money you\'ve borrowed from or lent to someone.';

  @override
  String get newDebt => 'New record';

  @override
  String get editDebt => 'Edit record';

  @override
  String get iBorrowed => 'I borrowed';

  @override
  String get iLent => 'I lent';

  @override
  String get personName => 'Person';

  @override
  String get personNameHint => 'Who is it with?';

  @override
  String get personRequired => 'Enter a name';

  @override
  String get givenOn => 'Date';

  @override
  String get dueDateOptional => 'Due date (optional)';

  @override
  String get moneyMovedThrough => 'Money moved through';

  @override
  String get debtReminder => 'Remind me before the due date';

  @override
  String get debtReminderOffsets => 'When to remind';

  @override
  String get iOwe => 'I owe';

  @override
  String get owedToMe => 'Owed to me';

  @override
  String get overdueAmount => 'Overdue';

  @override
  String get totalBorrowed => 'Total borrowed';

  @override
  String get totalLent => 'Total lent';

  @override
  String openRecords(String count) {
    return '$count open';
  }

  @override
  String outstandingOf(String outstanding, String total) {
    return '$outstanding of $total left';
  }

  @override
  String get settlements => 'Settlements';

  @override
  String get addSettlement => 'Record repayment';

  @override
  String get settlementAmount => 'Amount repaid';

  @override
  String get noSettlements => 'No repayments recorded yet.';

  @override
  String get settleFull => 'Settle in full';

  @override
  String get filterOpen => 'Open';

  @override
  String get filterSettled => 'Settled';

  @override
  String debtDueOn(String date) {
    return 'Due $date';
  }

  @override
  String get vehiclesTitle => 'Vehicles';

  @override
  String get vehiclesEmpty =>
      'No vehicles yet. Add one to track mileage and fuel costs.';

  @override
  String get addVehicle => 'Add vehicle';

  @override
  String get newVehicle => 'New vehicle';

  @override
  String get editVehicle => 'Edit vehicle';

  @override
  String get vehicleName => 'Vehicle name';

  @override
  String get vehicleNameHint => 'e.g. Swift, Activa';

  @override
  String get registrationNickname => 'Registration / nickname';

  @override
  String get fuelPrice => 'Fuel price per unit';

  @override
  String get expectedMileage => 'Expected mileage';

  @override
  String get expectedMileageHelp =>
      'Used until you log fuel fills; then the measured average is used.';

  @override
  String get unitKmPerL => 'km/l';

  @override
  String get unitKmPerKwh => 'km/kWh';

  @override
  String get unitKmPerKg => 'km/kg';

  @override
  String get unitLitre => 'l';

  @override
  String get unitKwh => 'kWh';

  @override
  String get unitKg => 'kg';

  @override
  String get unitKm => 'km';

  @override
  String get avgMileage => 'Average mileage';

  @override
  String get costPerKm => 'Cost per km';

  @override
  String get fuelThisMonth => 'Fuel this month';

  @override
  String get fuelMonthlyAverage => 'Monthly average';

  @override
  String get fuelYearlyEstimate => 'Yearly estimate';

  @override
  String get fuelCost6m => 'Fuel cost, last 6 months';

  @override
  String get totalDistance => 'Distance logged';

  @override
  String get fuelLogs => 'Fuel history';

  @override
  String get fuelLogsEmpty => 'No fuel fills logged yet.';

  @override
  String get addFuel => 'Log fuel';

  @override
  String get editFuel => 'Edit fuel fill';

  @override
  String get odometer => 'Odometer (optional)';

  @override
  String get distanceTravelled => 'Distance since last fill';

  @override
  String get fuelQuantity => 'Fuel added';

  @override
  String get pricePerUnit => 'Price per unit';

  @override
  String get totalCost => 'Total cost';

  @override
  String get recordAsExpense => 'Record as expense from';

  @override
  String get dontRecord => 'Don\'t record as expense';

  @override
  String get mileageCalculator => 'Mileage calculator';

  @override
  String get mileageResult => 'Mileage';

  @override
  String get tripCost => 'Fuel cost for this trip';

  @override
  String get tripDistance => 'Trip distance';

  @override
  String get calcCostPerKm => 'Cost per km';

  @override
  String get noMileageYet => '—';

  @override
  String get vehicleFuelExpenseNote =>
      'Fuel fills recorded as expenses also appear in Transactions and budgets.';

  @override
  String get fuelTypeLabel => 'Fuel type';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get budgetsEmpty =>
      'No budgets yet. Set a monthly limit overall or per category.';

  @override
  String get addBudget => 'Add budget';

  @override
  String get editBudget => 'Edit budget';

  @override
  String get budgetFor => 'Budget for';

  @override
  String get budgetLimit => 'Monthly limit';

  @override
  String get budgetThresholds => 'Warn me at';

  @override
  String get budgetThresholdsHelp =>
      'Percent of the limit, comma separated (e.g. 75, 90, 100)';

  @override
  String get budgetThresholdsInvalid => 'Enter percentages between 1 and 200';

  @override
  String budgetSpentOf(String spent, String limit) {
    return '$spent of $limit';
  }

  @override
  String budgetRemaining(String amount) {
    return '$amount left';
  }

  @override
  String budgetOver(String amount) {
    return '$amount over';
  }

  @override
  String budgetReached(String percent) {
    return 'Reached $percent%';
  }

  @override
  String get budgetAlertsSetting => 'Warn when a budget threshold is crossed';

  @override
  String get recurringTitle => 'Recurring';

  @override
  String get recurringEmpty =>
      'No recurring entries. Add salary, rent, subscriptions and other regular payments; they\'re recorded automatically on their dates.';

  @override
  String get addRecurring => 'Add recurring';

  @override
  String get editRecurring => 'Edit recurring';

  @override
  String get recurringTitleLabel => 'Title';

  @override
  String get recurringTitleHint => 'e.g. Rent, Netflix, Salary';

  @override
  String get startsOn => 'Starts on';

  @override
  String recurringNext(String date) {
    return 'Next: $date';
  }

  @override
  String get recurringPaused => 'Paused';

  @override
  String get recurringActive => 'Active';

  @override
  String get recurringAutoNote =>
      'Entries are created on each date (when the app opens), at most once per date. Loan EMIs are tracked in Loans instead.';

  @override
  String recurringGeneratedCount(String count) {
    return '$count recurring entries recorded';
  }

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportSummary => 'Summary';

  @override
  String get reportCategories => 'Categories';

  @override
  String get reportAccounts => 'Accounts';

  @override
  String get reportCards => 'Cards';

  @override
  String get reportLoans => 'Loans';

  @override
  String get reportDebts => 'Borrow & lend';

  @override
  String get reportFuel => 'Fuel';

  @override
  String get reportPeriod => 'Period';

  @override
  String get reportAllAccounts => 'All accounts';

  @override
  String get reportAllCards => 'All cards';

  @override
  String get reportAllCategories => 'All categories';

  @override
  String get reportMonthly => 'By month';

  @override
  String get reportPeriodSpending => 'Spending in period';

  @override
  String get reportPeriodIncome => 'Income in period';

  @override
  String get reportTransactions => 'Transactions';

  @override
  String get reportNoVehicles => 'No vehicles to report.';

  @override
  String get reportNoLoans => 'No loans to report.';

  @override
  String get reportNoCards => 'No cards to report.';

  @override
  String get reportNoAccounts => 'No accounts to report.';

  @override
  String get reportNoDebts => 'No borrow/lend records.';

  @override
  String get reportByPerson => 'By person';

  @override
  String get reportFuelInPeriod => 'Fuel cost in period';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search transactions, accounts, loans, people…';

  @override
  String get searchScopeNote =>
      'Transactions from the last 12 months are searched.';

  @override
  String searchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchStart => 'Type at least 2 characters to search.';

  @override
  String get searchGroupTransactions => 'Transactions';

  @override
  String get searchGroupAccounts => 'Accounts';

  @override
  String get searchGroupCards => 'Credit cards';

  @override
  String get searchGroupLoans => 'Loans';

  @override
  String get searchGroupDebts => 'Borrow & lend';

  @override
  String get searchGroupReminders => 'Reminders';

  @override
  String get searchGroupVehicles => 'Vehicles';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get notificationsStatusOn => 'Allowed';

  @override
  String get notificationsStatusOff => 'Not allowed';

  @override
  String get notificationsResync => 'Reschedule all reminders';

  @override
  String get notificationsResynced => 'Reminders rescheduled';

  @override
  String get settingsData => 'Data & sync';

  @override
  String get settingsAccount => 'Account';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get guestAccount => 'Guest (this device only)';

  @override
  String get guestWarning =>
      'You\'re using a guest account. Sign in with Google so your data is backed up and can be restored on a new phone.';

  @override
  String get linkGoogle => 'Sign in with Google';

  @override
  String get googleAccountExistsTitle => 'Use your existing account?';

  @override
  String get googleAccountExistsBody =>
      'This Google account already has data. Switching to it will hide the data you created as a guest on this device. You can\'t merge them.';

  @override
  String get switchAccount => 'Switch account';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutGuestWarning =>
      'You\'re a guest: signing out permanently loses access to this data unless you sign in with Google first.';

  @override
  String get signOutConfirm => 'Sign out?';

  @override
  String get backupTitle => 'Backup & restore';

  @override
  String get backupNow => 'Back up now';

  @override
  String get backupAuto => 'Automatic weekly backup';

  @override
  String backupLast(String time) {
    return 'Last backup: $time';
  }

  @override
  String get backupNever => 'No backup yet';

  @override
  String backupDone(String count) {
    return 'Backup complete ($count records)';
  }

  @override
  String get backupList => 'Restore from a backup';

  @override
  String get backupEmpty => 'No backups found for this account.';

  @override
  String get restoreConfirmTitle => 'Restore this backup?';

  @override
  String get restoreConfirmBody =>
      'Records in the backup will overwrite matching records. Records you added after the backup are kept. Reminders will be rescheduled.';

  @override
  String restoreDone(String count) {
    return 'Restored $count records';
  }

  @override
  String restoreSkipped(String count) {
    return '$count invalid records were skipped';
  }

  @override
  String get backupNeedsAccount => 'Sign in with Google to use cloud backups.';

  @override
  String get backupInProgress => 'Working…';

  @override
  String get importTitle => 'Import from Gmail';

  @override
  String get importBody =>
      'Scan bank and card emails (read-only) and add the transactions found. Duplicates are merged.';

  @override
  String importDone(String count) {
    return '$count transactions imported';
  }

  @override
  String get privacyNote =>
      'Your data is stored in your private Firebase space. Only you can read it. The app never stores passwords, PINs, CVVs or full card numbers.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get moreTitle => 'More';

  @override
  String get moreMoney => 'Money';

  @override
  String get moreTools => 'Tools';

  @override
  String get moreApp => 'App';

  @override
  String get welcomeTitle => 'Your money, beautifully organised';

  @override
  String get welcomeBody =>
      'Expenses, accounts, cards, loans and reminders — all in one calm, private place.';

  @override
  String get welcomePrivacy =>
      'Your data is private to your account. We never ask for bank passwords, PINs or card numbers.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueAsGuest => 'Continue without an account';

  @override
  String get guestNote =>
      'Start right away. Link Google later in Settings to back up and use your data on a new phone.';

  @override
  String get signInFailed => 'Sign-in didn\'t complete. Please try again.';

  @override
  String get firstLaunchOffline =>
      'You\'re offline. Connect to the internet once to set up your private space — after that the app works offline.';

  @override
  String get signOutBody =>
      'Your data stays in your account. Sign in again with the same Google account to see it.';

  @override
  String get welcomeFeatureTrack => 'Every rupee in one place';

  @override
  String get welcomeFeatureDues => 'Never miss a due date';

  @override
  String get welcomeFeatureLoans => 'Loans made clear';

  @override
  String get welcomeFeaturePrivate => 'Private and offline-first';

  @override
  String get googleNote =>
      'Recommended: your data is backed up and follows you to a new phone.';

  @override
  String get signingIn => 'Signing you in…';

  @override
  String get signInCancelled => 'Sign-in was cancelled.';

  @override
  String get guestUnavailable =>
      'Guest access is turned off for this app right now. Please continue with Google.';

  @override
  String get guestUnavailableDev =>
      'Developer: enable Anonymous sign-in in Firebase Console → Authentication → Sign-in method.';

  @override
  String get backupConnectTitle => 'Back up your data';

  @override
  String get backupConnectBody =>
      'Connect your Google account to back up automatically and restore on a new phone. Without it, your data lives only on this device.';

  @override
  String get backupConnect => 'Connect backup';

  @override
  String get backupConnectedTitle => 'Backup connected';

  @override
  String backupConnectedAs(String email) {
    return 'Backing up to $email';
  }

  @override
  String get backupConnectUnavailable =>
      'Cloud backup needs Google sign-in, which isn\'t available on this device.';

  @override
  String get adPrivacyOptions => 'Ad privacy settings';

  @override
  String get adPrivacyOptionsHelp =>
      'Review or change your choice about personalised ads.';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesManage => 'Manage categories';

  @override
  String get categoryBuiltIn => 'Built-in';

  @override
  String get categoryYours => 'Your categories';

  @override
  String get categoryYoursEmpty =>
      'You haven\'t added any categories yet. Tap + to create one.';

  @override
  String get categoryAdd => 'New category';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryNameLabel => 'Category name';

  @override
  String get categoryNameHint => 'e.g. Pets, Coffee, Freelance';

  @override
  String get categoryTypeLabel => 'Used for';

  @override
  String get categoryIconLabel => 'Icon';

  @override
  String get categoryColorLabel => 'Color';

  @override
  String get categoryNameEmpty => 'Enter a name';

  @override
  String categoryNameTooLong(String max) {
    return 'Keep it under $max characters';
  }

  @override
  String get categoryNameDuplicate =>
      'A category with this name already exists';

  @override
  String get categoryTypeLocked => 'The type can\'t be changed after creation.';

  @override
  String get categoryArchived => 'Archived';

  @override
  String get categoryArchive => 'Archive';

  @override
  String get categoryRestore => 'Restore';

  @override
  String get categoryArchivedNote =>
      'Archived categories are hidden when adding transactions, but existing transactions keep them.';

  @override
  String get categoryInUse =>
      'This category is used by transactions, a budget or a recurring entry, so it can\'t be deleted. Archive it instead.';

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String get categoryNew => 'New';

  @override
  String get categoryRequired => 'Choose a category';

  @override
  String get categoryTapToClear =>
      'Tap the selected category again to clear it';

  @override
  String get typeTapToClear => 'Tap again to switch back to Expense';

  @override
  String get paymentRequired => 'Choose how you paid';

  @override
  String get receivedRequired => 'Choose where the money went';

  @override
  String get paymentCash => 'Cash / not tracked';

  @override
  String get paymentCashHint => 'Doesn\'t change any balance';

  @override
  String get paymentNoneYet =>
      'No accounts or cards yet. Add one to see balances update automatically, or continue with untracked cash.';

  @override
  String get paymentTapToClear => 'Tap again to clear';

  @override
  String get paymentPaidFrom => 'Paid from';

  @override
  String get paymentPayingAccount => 'Pay the bill from';

  @override
  String get paymentDestination => 'Add to account';

  @override
  String get addExpenseFromAccount => 'Add transaction';

  @override
  String get adLabel => 'Advertisement';

  @override
  String get notificationChannelName => 'Reminders';

  @override
  String get notificationChannelDescription =>
      'Bill, EMI, card and personal reminders';

  @override
  String get settingsAds => 'Ads';

  @override
  String get adFreeTitle => 'No ads for 24 hours';

  @override
  String get adFreeShort => 'Watch a video, no ads for 24 hours';

  @override
  String get adFreeWatch => 'Watch a video';

  @override
  String get adFreeHelp =>
      'Watch one short video and Kept shows no ads for the next 24 hours.';

  @override
  String adFreeActive(String time) {
    return 'Ads are off until $time';
  }

  @override
  String get adFreeLoading => 'Getting a video ready…';

  @override
  String get adFreeUnavailable =>
      'No video is available right now. Please try again later.';

  @override
  String get adFreeThanks => 'Thanks! No ads for the next 24 hours.';

  @override
  String get adFreeNotCompleted =>
      'Watch the video to the end to turn ads off.';

  @override
  String get paymentTypeAccount => 'Bank account';

  @override
  String get paymentTypeCash => 'Cash';

  @override
  String get txTypeRepayBorrow => 'Repay a borrow';

  @override
  String get repayWhich => 'Which borrow?';

  @override
  String repayLeft(String amount) {
    return '$amount left';
  }

  @override
  String get moreTypes => 'More';

  @override
  String get moreDetails => 'More details';

  @override
  String get moreCategories => 'More';

  @override
  String get debtPlanTitle => 'Debt-free plan';

  @override
  String get debtPlanEmpty =>
      'No loans, card balances or borrowed money to clear. You\'re debt-free!';

  @override
  String get debtPlanDebtFreeBy => 'Debt-free by';

  @override
  String debtPlanIn(String duration) {
    return 'in $duration';
  }

  @override
  String debtPlanDurationMonths(String months) {
    return '$months mo';
  }

  @override
  String debtPlanDurationYears(String years, String months) {
    return '$years yr $months mo';
  }

  @override
  String get debtPlanTotalOwed => 'Total owed';

  @override
  String get debtPlanInterestAhead => 'Interest still to pay';

  @override
  String debtPlanSavings(String amount, String duration) {
    return 'Saves $amount and $duration compared with paying only the minimums';
  }

  @override
  String debtPlanSavingsInterestOnly(String amount) {
    return 'Saves $amount compared with paying only the minimums';
  }

  @override
  String get debtPlanNeverClears =>
      'At this payment some debts never clear. Add more each month to finish them.';

  @override
  String get debtPlanChartTitle => 'Your debt going down';

  @override
  String debtPlanChartSemantics(String amount, String date) {
    return 'Total debt falls from $amount to zero by $date';
  }

  @override
  String get debtPlanMonthlyTitle => 'What you pay each month';

  @override
  String get debtPlanExtraLabel => 'Extra per month';

  @override
  String get debtPlanMinimums => 'Minimum payments';

  @override
  String get debtPlanExtra => 'Extra';

  @override
  String get debtPlanTotalMonthly => 'Total each month';

  @override
  String get debtPlanCommitNote =>
      'Keep paying this total even after a debt closes. The freed-up money clears the next one.';

  @override
  String get debtPlanWhatIfTitle => 'What if you paid more?';

  @override
  String debtPlanWhatIfRow(String amount) {
    return '+$amount a month';
  }

  @override
  String debtPlanWhatIfDetail(String date, String amount) {
    return 'Done by $date, saves $amount';
  }

  @override
  String get debtPlanWhatIfStillOpen => 'Some debts still won\'t clear';

  @override
  String get debtPlanStrategyTitle => 'Which debt first?';

  @override
  String get debtPlanAvalanche => 'Highest interest first';

  @override
  String get debtPlanAvalancheHelp => 'Costs the least overall.';

  @override
  String get debtPlanSnowball => 'Smallest balance first';

  @override
  String get debtPlanSnowballHelp =>
      'Closes debts sooner, so you see progress early.';

  @override
  String debtPlanStrategyResult(String date, String amount) {
    return 'Done by $date · $amount interest';
  }

  @override
  String get debtPlanCheapest => 'Lowest cost';

  @override
  String debtPlanThisMonthTitle(String month) {
    return 'Pay this in $month';
  }

  @override
  String get debtPlanFocus => 'Put your extra here';

  @override
  String get debtPlanRoadmapTitle => 'Your roadmap';

  @override
  String debtPlanStepCleared(String date) {
    return 'Cleared by $date';
  }

  @override
  String get debtPlanStepOpen => 'Not cleared at this payment';

  @override
  String debtPlanRate(String rate) {
    return '$rate% a year';
  }

  @override
  String debtPlanRateEstimated(String rate) {
    return '$rate% a year (estimated)';
  }

  @override
  String get debtPlanNoInterest => 'No interest';

  @override
  String get debtPlanSetRate => 'Set interest rate';

  @override
  String debtPlanSetRateTitle(String name) {
    return 'Interest rate for $name';
  }

  @override
  String debtPlanEstimatedWarning(String rate) {
    return 'Some cards use an estimated $rate% interest rate. Set the real rate from your statement for an accurate plan.';
  }

  @override
  String debtPlanLowPayment(String names) {
    return '$names: the minimum payment doesn\'t cover the interest, so this balance grows unless you pay more.';
  }

  @override
  String get debtPlanTipsTitle => 'Clear it faster';

  @override
  String get debtPlanTipOverdue =>
      'Clear overdue payments first. Late fees and penalty interest cost more than anything in this plan.';

  @override
  String debtPlanTipCardInterest(String amount) {
    return 'Your cards cost about $amount in interest this month. Avoid new spending on them until they are cleared.';
  }

  @override
  String debtPlanTipUtilization(String names) {
    return '$names: over 30% of the limit is in use. Bringing it lower can help your credit score.';
  }

  @override
  String get debtPlanTipConsolidate =>
      'Ask your bank about moving card dues to a lower-rate loan or EMI. Do it only if the total cost, with fees, is lower.';

  @override
  String get debtPlanAssumptions =>
      'Estimate only. Assumes no new card spending, on-time payments and unchanged rates. Lenders may charge for prepayment, so check first.';

  @override
  String get cardAnnualRate => 'Interest rate (% a year)';

  @override
  String get cardAnnualRateHelp =>
      'Shown on your statement. Used by the Debt-free plan.';

  @override
  String get extraMoneyTitle => 'Got extra money?';

  @override
  String get extraMoneySubtitle =>
      'Bonus, arrears or side income: see which debt to close with it.';

  @override
  String get extraMoneyAction => 'See where to put it';

  @override
  String extraMoneyDetected(String amount) {
    return '$amount more income than usual this month. Put it to work on your debt.';
  }

  @override
  String get extraMoneyIntro =>
      'Enter the extra amount you received and we\'ll show which loan, EMI or card to pay.';

  @override
  String get extraMoneyAmount => 'Extra money received';

  @override
  String get extraMoneyRecordIncome => 'Add it to my income';

  @override
  String get extraMoneyKeepReserve => 'Keep some as emergency money';

  @override
  String get extraMoneyKeepReserveHelp =>
      'Your savings are below 3 months of expenses and payments. Up to 25% is set aside.';

  @override
  String get extraMoneyDoThis => 'Do this';

  @override
  String get extraMoneyCloses => 'Closes this debt';

  @override
  String get extraMoneyPartPayment => 'Part payment';

  @override
  String get extraMoneyKeep => 'Keep as emergency money';

  @override
  String get extraMoneyLeftover => 'Left over for you';

  @override
  String get extraMoneyResult => 'What this does';

  @override
  String get extraMoneyClearsAll => 'This clears all your debt!';

  @override
  String extraMoneyNewDate(String date) {
    return 'Debt-free by $date';
  }

  @override
  String get extraMoneyInterestSaved => 'Interest saved';

  @override
  String extraMoneySooner(String duration) {
    return 'Finishes $duration sooner';
  }

  @override
  String get extraMoneyFreed => 'Monthly payments that stop';

  @override
  String extraMoneyInstead(String name, String amount, String monthly) {
    return 'Prefer one less EMI? $name can be closed outright for $amount, which stops $monthly a month.';
  }

  @override
  String get extraMoneyCaution =>
      'Tap a debt to record the payment. Ask your lender for the exact closing amount and any prepayment charges first.';

  @override
  String get debtProgressTitle => 'Your progress';

  @override
  String debtProgressPaid(String paid, String peak) {
    return '$paid paid off of $peak';
  }

  @override
  String debtProgressJustCleared(String names) {
    return 'Well done! You cleared $names.';
  }

  @override
  String get debtLoadTitle => 'Debt load';

  @override
  String debtLoadShare(String percent) {
    return 'Required payments take $percent% of your usual income.';
  }

  @override
  String get debtLoadHealthy => 'Healthy';

  @override
  String get debtLoadHealthyHelp =>
      'You have room to pay extra and finish sooner.';

  @override
  String get debtLoadWatch => 'Be careful';

  @override
  String get debtLoadWatchHelp =>
      'Avoid taking on new EMIs until this comes down.';

  @override
  String get debtLoadHigh => 'Too high';

  @override
  String get debtLoadHighHelp =>
      'Above 40% is hard to sustain. Avoid new loans and consider asking your lender about restructuring.';

  @override
  String debtLoadOverBudget(String amount) {
    return 'Usual spending and payments are $amount a month more than your usual income.';
  }

  @override
  String debtPlanSuggestedExtra(String amount) {
    return 'Your last few months suggest you can afford $amount extra a month.';
  }

  @override
  String get debtPlanUseSuggested => 'Use this amount';

  @override
  String get debtPlanReminder => 'Remind me each month';

  @override
  String get debtPlanReminderHelp =>
      'A notification on the 1st says what to pay.';

  @override
  String debtPlanReminderTitle(String amount, String name) {
    return 'Debt plan: pay $amount to $name';
  }

  @override
  String get debtPlanCompareSwitch => 'Compare the cost';

  @override
  String get debtSwitchTitle => 'Move to a cheaper loan?';

  @override
  String get debtSwitchIntro =>
      'Compare keeping a balance at its current rate with a card-to-EMI plan, balance transfer or personal loan.';

  @override
  String get debtSwitchBalance => 'Amount to move';

  @override
  String get debtSwitchCurrentRate => 'Current interest rate (% a year)';

  @override
  String get debtSwitchNewRate => 'New interest rate (% a year)';

  @override
  String get debtSwitchMonths => 'Months to repay';

  @override
  String get debtSwitchFee => 'Processing fee';

  @override
  String get debtSwitchFeeHelp =>
      'Include GST. Some EMI offers charge interest at a flat rate, so ask for the reducing-balance rate.';

  @override
  String get debtSwitchResult => 'Result';

  @override
  String debtSwitchWorthIt(String amount) {
    return 'Worth it: saves $amount after the fee';
  }

  @override
  String get debtSwitchNotWorthIt =>
      'Not worth it: the fee cancels out the saving';

  @override
  String get debtSwitchKeepInterest => 'Interest if you stay';

  @override
  String get debtSwitchNewInterest => 'Interest if you move';

  @override
  String get debtSwitchFeeAmount => 'Fee';

  @override
  String get debtSwitchNewEmi => 'New monthly EMI';
}
