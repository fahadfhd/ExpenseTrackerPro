// Generates the app-store images (screenshots with captions, feature
// graphic) from the real app, rendered with demo data.
//
// Not part of the normal test run (it lives outside `test/`). From the repo
// root:
//
//   STORE_LANG=en flutter test tool/store_images/store_images_test.dart
//   STORE_LANG=ml flutter test tool/store_images/store_images_test.dart
//   python3 tool/store_images/flatten.py
//
// See store/README.md. The fonts are loaded from the Flutter SDK (Roboto,
// Material icons) and macOS (Apple's Malayalam font), so run it on a Mac.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kept/app/app.dart';
import 'package:kept/features/accounts/application/account_providers.dart';
import 'package:kept/features/accounts/domain/account.dart';
import 'package:kept/features/borrow_lend/application/debt_providers.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/budgets/application/budget_providers.dart';
import 'package:kept/features/budgets/domain/budget.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/credit_cards/application/card_providers.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/loans/application/loan_providers.dart';
import 'package:kept/features/loans/domain/emi_engine.dart';
import 'package:kept/features/loans/domain/loan.dart';
import 'package:kept/features/reminders/application/reminder_providers.dart';
import 'package:kept/features/reminders/domain/reminder.dart';
import 'package:kept/core/utils/recurrence.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:kept/l10n/app_localizations.dart';

import '../../test/helpers/test_app.dart';
import '../../test/widgets/features_test.dart' as f;

final _lang = Platform.environment['STORE_LANG'] ?? 'en';
final _l10n = lookupAppLocalizations(Locale(_lang));
final _flutterRoot =
    Platform.environment['FLUTTER_ROOT'] ?? '/Users/fahadt/development/flutter';

/// Where the finished images go.
const _out = 'store';

// ---------------------------------------------------------------- fonts

Future<void> _font(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(p).readAsBytesSync())),
    );
  }
  await loader.load();
}

/// Malayalam text. Flutter loads only the first face of a .ttc, so the
/// regular and bold faces are split out first (extract_malayalam_fonts.py);
/// without that the headlines would not be bold.
List<String> _malayalamFonts() {
  const faces = [
    'build/store_fonts/SangamML-Regular.ttf',
    'build/store_fonts/SangamML-Bold.ttf',
  ];
  if (faces.every((p) => File(p).existsSync())) return faces;
  // ignore: avoid_print
  print(
    'NOTE: build/store_fonts is missing (run extract_malayalam_fonts.py): '
    'Malayalam headlines will not be bold.',
  );
  return ['/System/Library/Fonts/Supplemental/Malayalam Sangam MN.ttc'];
}

Future<void> _loadFonts() async {
  final fonts = '$_flutterRoot/bin/cache/artifacts/material_fonts';
  final text = _lang == 'ml'
      ? _malayalamFonts()
      : [
          '$fonts/Roboto-Regular.ttf',
          '$fonts/Roboto-Medium.ttf',
          '$fonts/Roboto-Bold.ttf',
          '$fonts/Roboto-Black.ttf',
        ];
  await _font('Roboto', text);
  // Captions in the English set name the Malayalam language in its own script.
  await _font('MalayalamFallback', _malayalamFonts());
  // Text without an explicit family uses the test font unless that is
  // replaced too.
  await _font('Ahem', text);
  await _font('MaterialIcons', ['$fonts/MaterialIcons-Regular.otf']);
}

// ------------------------------------------------------------- capturing

/// Captures the nearest repaint boundary around [finder] (the whole screen
/// for the app), the same way Flutter's golden tests do.
Future<Uint8List> _png(WidgetTester tester, Finder finder, double ratio) async {
  RenderObject node = tester.renderObject(finder);
  while (!node.isRepaintBoundary) {
    node = node.parent!;
  }
  final layer = node.debugLayer! as OffsetLayer;
  final bounds = node.paintBounds;
  final bytes = await tester.runAsync(() async {
    final image = await layer.toImage(bounds, pixelRatio: ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

Future<ui.Image> _decode(WidgetTester tester, Uint8List bytes) async {
  final image = await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(bytes);
    return (await codec.getNextFrame()).image;
  });
  return image!;
}

void _write(String path, Uint8List bytes) {
  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

// ---------------------------------------------------------------- data

class _Names {
  const _Names({
    required this.salary,
    required this.savings,
    required this.cash,
    required this.card,
    required this.loan,
    required this.fund,
    required this.wallet,
    required this.reminders,
    required this.people,
    required this.desc,
  });

  final String salary, savings, cash, card, loan, fund, wallet;

  /// Two people for the borrow/lend records.
  final List<String> people;

  /// electricity, rent, insurance, broadband
  final List<String> reminders;

  /// Descriptions for the demo transactions, by key.
  final Map<String, String> desc;
}

const _namesEn = _Names(
  salary: 'Salary account',
  savings: 'Savings',
  cash: 'Cash',
  card: 'Rewards card',
  loan: 'Car loan',
  fund: 'Emergency fund',
  wallet: 'Wallet',
  reminders: [
    'Electricity bill',
    'House rent',
    'Insurance premium',
    'Broadband',
  ],
  people: ['Anil', 'Ravi'],
  desc: {
    'pending': 'Water tank cleaning',
    'salary': 'Monthly salary',
    'freelance': 'Freelance project',
    'rent': 'House rent',
    'groceries': 'Weekly groceries',
    'fuel': 'Fuel',
    'electricity': 'Electricity bill',
    'lunch': 'Lunch with the team',
    'stream': 'Streaming plan',
    'shoes': 'Running shoes',
    'dinner': 'Dinner with family',
    'pharmacy': 'Pharmacy',
    'mobile': 'Mobile recharge',
    'auto': 'Auto fare',
    'course': 'Online course',
    'home': 'Home essentials',
    'breakfast': 'Breakfast',
    'movie': 'Movie night',
    'internet': 'Internet bill',
    'gift': 'Birthday gift',
    'brunch': 'Weekend brunch',
    'haircut': 'Haircut',
  },
);

const _namesMl = _Names(
  salary: 'ശമ്പള അക്കൗണ്ട്',
  savings: 'സേവിംഗ്സ്',
  cash: 'പണം',
  card: 'റിവാർഡ്സ് കാർഡ്',
  loan: 'കാർ ലോൺ',
  fund: 'അടിയന്തര ഫണ്ട്',
  wallet: 'വാലറ്റ്',
  reminders: ['വൈദ്യുതി ബിൽ', 'വീട്ടുവാടക', 'ഇൻഷുറൻസ് പ്രീമിയം', 'ബ്രോഡ്ബാൻഡ്'],
  people: ['അനിൽ', 'രവി'],
  desc: {
    'pending': 'വാട്ടർ ടാങ്ക് ക്ലീനിംഗ്',
    'salary': 'മാസശമ്പളം',
    'freelance': 'ഫ്രീലാൻസ് പ്രോജക്റ്റ്',
    'rent': 'വീട്ടുവാടക',
    'groceries': 'ആഴ്ചയിലെ പലചരക്ക്',
    'fuel': 'ഇന്ധനം',
    'electricity': 'വൈദ്യുതി ബിൽ',
    'lunch': 'ഓഫീസിൽ ഉച്ചഭക്ഷണം',
    'stream': 'സ്ട്രീമിംഗ് പ്ലാൻ',
    'shoes': 'റണ്ണിംഗ് ഷൂസ്',
    'dinner': 'കുടുംബത്തോടൊപ്പം അത്താഴം',
    'pharmacy': 'ഫാർമസി',
    'mobile': 'മൊബൈൽ റീചാർജ്',
    'auto': 'ഓട്ടോ കൂലി',
    'course': 'ഓൺലൈൻ കോഴ്സ്',
    'home': 'വീട്ടുസാധനങ്ങൾ',
    'breakfast': 'പ്രഭാതഭക്ഷണം',
    'movie': 'സിനിമ',
    'internet': 'ഇന്റർനെറ്റ് ബിൽ',
    'gift': 'ജന്മദിന സമ്മാനം',
    'brunch': 'വാരാന്ത്യ ബ്രഞ്ച്',
    'haircut': 'മുടിവെട്ട്',
  },
);

_Names get _names => _lang == 'ml' ? _namesMl : _namesEn;

const _salaryAcc = 'acc_salary';
const _savingsAcc = 'acc_savings';
const _cashAcc = 'acc_cash';
const _cardId = 'card_rewards';
const _loanId = 'loan_car';

/// Fills the app with a believable month of data: the current month, spread
/// over days 1 to 28 (some of them are still ahead of today, which is fine for
/// demo data and keeps the dashboard on "this month").
Future<void> _seed(WidgetTester tester, ProviderContainer c) async {
  final n = _names;
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  DateTime day(int d, [int hour = 12]) =>
      DateTime(month.year, month.month, d, hour);
  int rs(num amount) => (amount * 100).round();

  c.read(accountRepositoryProvider)
    ..save(
      Account(
        id: _salaryAcc,
        name: n.salary,
        type: AccountType.savings,
        openingBalanceMinor: rs(41500),
        createdAt: now,
        updatedAt: now,
      ),
    )
    ..save(
      Account(
        id: _savingsAcc,
        name: n.savings,
        type: AccountType.savings,
        openingBalanceMinor: rs(125000),
        createdAt: now,
        updatedAt: now,
      ),
    )
    ..save(
      Account(
        id: 'acc_fund',
        name: n.fund,
        type: AccountType.savings,
        openingBalanceMinor: rs(240000),
        createdAt: now,
        updatedAt: now,
      ),
    )
    ..save(
      Account(
        id: 'acc_wallet',
        name: n.wallet,
        type: AccountType.wallet,
        openingBalanceMinor: rs(1850),
        createdAt: now,
        updatedAt: now,
      ),
    )
    ..save(
      Account(
        id: _cashAcc,
        name: n.cash,
        type: AccountType.cash,
        openingBalanceMinor: rs(3500),
        createdAt: now,
        updatedAt: now,
      ),
    );
  final card = CreditCard(
    id: _cardId,
    name: n.card,
    last4: '4242',
    creditLimitMinor: rs(150000),
    openingOutstandingMinor: rs(12000),
    statementDay: 1,
    dueDay: 20,
    createdAt: now,
    updatedAt: now,
  );
  c.read(creditCardRepositoryProvider).save(card);
  c.read(entityRemindersProvider).syncCard(card);
  await settle(tester);

  Transaction tx(
    String id,
    int d,
    TransactionType type,
    String category,
    num amount,
    String desc, {
    String? account,
    String? cardId,
    String? loan,
  }) => Transaction(
    id: id,
    date: day(d, 9 + d % 9),
    amountMinor: rs(amount),
    type: type,
    categoryId: category,
    description: desc,
    accountId: account,
    creditCardId: cardId,
    loanId: loan,
    createdAt: now,
    updatedAt: now,
  );
  const expense = TransactionType.expense;
  const cardExpense = TransactionType.creditCardExpense;
  final d = n.desc;

  final emi = EmiEngine.emi(
    principalMinor: rs(600000),
    periodicRate: EmiEngine.periodicRate(9.5, EmiFrequency.monthly),
    installments: 60,
  );
  c.read(transactionRepositoryProvider).saveAll([
    tx(
      'i1',
      1,
      TransactionType.income,
      'salary',
      62000,
      d['salary']!,
      account: _salaryAcc,
    ),
    tx(
      'i2',
      14,
      TransactionType.income,
      'business',
      8500,
      d['freelance']!,
      account: _salaryAcc,
    ),
    tx('e1', 1, expense, 'housing', 14000, d['rent']!, account: _salaryAcc),
    tx('e2', 2, cardExpense, 'food', 2340, d['groceries']!, cardId: _cardId),
    tx('e3', 3, cardExpense, 'transport', 2200, d['fuel']!, cardId: _cardId),
    tx('e4', 4, expense, 'bills', 1860, d['electricity']!, account: _salaryAcc),
    tx('e5', 5, cardExpense, 'food', 640, d['lunch']!, cardId: _cardId),
    tx(
      'e6',
      6,
      cardExpense,
      'entertainment',
      649,
      d['stream']!,
      cardId: _cardId,
    ),
    tx('e7', 7, cardExpense, 'shopping', 3499, d['shoes']!, cardId: _cardId),
    tx('e8', 9, expense, 'food', 1150, d['dinner']!, account: _salaryAcc),
    tx('e9', 10, expense, 'health', 820, d['pharmacy']!, account: _salaryAcc),
    tx('e10', 12, expense, 'bills', 399, d['mobile']!, account: _salaryAcc),
    tx('e11', 13, cardExpense, 'food', 2780, d['groceries']!, cardId: _cardId),
    tx('e12', 15, expense, 'transport', 320, d['auto']!, account: _cashAcc),
    tx(
      'e13',
      16,
      expense,
      'education',
      1500,
      d['course']!,
      account: _salaryAcc,
    ),
    tx('e14', 18, cardExpense, 'shopping', 2150, d['home']!, cardId: _cardId),
    tx('e15', 19, expense, 'food', 560, d['breakfast']!, account: _cashAcc),
    tx(
      'e16',
      21,
      expense,
      'entertainment',
      900,
      d['movie']!,
      account: _salaryAcc,
    ),
    tx('e17', 22, expense, 'bills', 1100, d['internet']!, account: _salaryAcc),
    tx('e18', 24, cardExpense, 'transport', 2050, d['fuel']!, cardId: _cardId),
    tx('e19', 26, expense, 'gifts', 1800, d['gift']!, account: _salaryAcc),
    tx('e20', 27, cardExpense, 'food', 1320, d['brunch']!, cardId: _cardId),
    tx('e21', 28, expense, 'personal', 700, d['haircut']!, account: _salaryAcc),
    Transaction(
      id: 'emi1',
      date: day(8),
      amountMinor: emi,
      type: TransactionType.loanPayment,
      categoryId: Categories.loanId,
      description: n.loan,
      accountId: _salaryAcc,
      loanId: _loanId,
      createdAt: now,
      updatedAt: now,
    ),
    Transaction(
      id: 'pending1',
      date: day(29),
      amountMinor: rs(2500),
      type: expense,
      categoryId: 'bills',
      description: d['pending']!,
      accountId: _salaryAcc,
      status: TransactionStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),
    Transaction(
      id: 'cardpay1',
      date: day(20),
      amountMinor: rs(12000),
      type: TransactionType.creditCardPayment,
      categoryId: Categories.cardPaymentId,
      accountId: _salaryAcc,
      creditCardId: _cardId,
      createdAt: now,
      updatedAt: now,
    ),
  ]);
  await settle(tester);

  final debts = c.read(debtRepositoryProvider);
  final soon = DateTime(now.year, now.month, now.day);
  debts
    ..save(
      DebtRecord(
        id: 'debt1',
        direction: DebtDirection.borrowed,
        personName: n.people[0],
        amountMinor: rs(4000),
        date: day(11),
        dueDate: soon.add(const Duration(days: 6)),
        accountId: _salaryAcc,
        createdAt: now,
        updatedAt: now,
      ),
    )
    ..save(
      DebtRecord(
        id: 'debt2',
        direction: DebtDirection.lent,
        personName: n.people[1],
        amountMinor: rs(6500),
        date: day(17),
        dueDate: soon.add(const Duration(days: 15)),
        accountId: _salaryAcc,
        createdAt: now,
        updatedAt: now,
      ),
    );
  await settle(tester);

  // A car loan, eight EMIs in; the next one falls due in eight days.
  final next = now.add(const Duration(days: 8));
  final first = DateTime(next.year, next.month - 8, math.min(next.day, 28));
  final loan = Loan(
    id: _loanId,
    name: n.loan,
    principalMinor: rs(600000),
    annualRatePercent: 9.5,
    installments: 60,
    frequency: EmiFrequency.monthly,
    emiMinor: emi,
    firstDueDate: first,
    accountId: _salaryAcc,
    createdAt: now,
    updatedAt: now,
  );
  final loans = c.read(loanRepositoryProvider)..save(loan);
  loans.recordPastPayments(loan, 8);

  final budgets = c.read(budgetRepositoryProvider);
  Budget budget(num amount, [String? category]) => Budget(
    id: Budget.idFor(category),
    amountMinor: rs(amount),
    categoryId: category,
    createdAt: now,
    updatedAt: now,
  );
  budgets
    ..save(budget(70000))
    ..save(budget(15000, 'food'))
    ..save(budget(7500, 'transport'))
    ..save(budget(6000, 'shopping'))
    ..save(budget(5000, 'entertainment'));

  final today = DateTime(now.year, now.month, now.day);
  final reminders = c.read(reminderRepositoryProvider);
  Reminder reminder(
    String id,
    String title,
    ReminderType type,
    int inDays,
    int hour,
    Recurrence recurrence,
  ) => Reminder(
    id: id,
    title: title,
    type: type,
    date: today.add(Duration(days: inDays)),
    hour: hour,
    minute: 0,
    recurrence: recurrence,
    offsetsMinutes: const [1440, 0],
    createdAt: now,
    updatedAt: now,
  );
  const monthly = Recurrence(frequency: RecurrenceFrequency.monthly);
  reminders
    ..save(reminder('r1', n.reminders[0], ReminderType.bill, 3, 9, monthly))
    ..save(reminder('r2', n.reminders[1], ReminderType.bill, 6, 9, monthly))
    ..save(reminder('r3', n.reminders[3], ReminderType.bill, 10, 10, monthly))
    ..save(
      reminder(
        'r4',
        n.reminders[2],
        ReminderType.insurance,
        14,
        10,
        const Recurrence(frequency: RecurrenceFrequency.yearly),
      ),
    );

  c.read(selectedMonthProvider.notifier).select(month);
  await settle(tester);
  await settle(tester);
}

// --------------------------------------------------------------- scenes

/// One store screenshot: how to reach the screen, and its captions.
class _Scene {
  const _Scene(
    this.file,
    this.go, {
    this.dark = false,
    this.headline = '',
    this.sub = '',
  });

  final String file;
  final Future<void> Function(WidgetTester tester) go;
  final bool dark;
  final String headline;
  final String sub;
}

const _captions = {
  'en': {
    'home': (
      'Your money, beautifully organised',
      'Spending, income and savings at a glance',
    ),
    'add': (
      'Add an expense in seconds',
      'Pick the account or card you paid with',
    ),
    'accounts': (
      'Every account and card in one place',
      'Balances, credit limits and what is left to pay',
    ),
    'loans': (
      'Loans and EMIs made clear',
      'Your rate, your schedule, what is left',
    ),
    'reminders': (
      'Never miss a due date',
      'Bills, EMIs and card payments, reminded in time',
    ),
    'reports': (
      'See where your money goes',
      'Clear charts by category, account and month',
    ),
    'budgets': ('Stay on budget', 'A heads-up before you overspend'),
    'dark': (
      'Private, offline, in your language',
      'English and മലയാളം · light and dark',
    ),
  },
  'ml': {
    'home': (
      'നിങ്ങളുടെ പണം, ഭംഗിയായി ക്രമീകരിച്ച്',
      'ചെലവ്, വരുമാനം, സമ്പാദ്യം — ഒറ്റനോട്ടത്തിൽ',
    ),
    'add': (
      'നിമിഷങ്ങൾക്കുള്ളിൽ ചെലവ് ചേർക്കാം',
      'പണമടച്ച അക്കൗണ്ടോ കാർഡോ തിരഞ്ഞെടുക്കുക',
    ),
    'accounts': (
      'എല്ലാ അക്കൗണ്ടും കാർഡും ഒരിടത്ത്',
      'ബാലൻസ്, ക്രെഡിറ്റ് പരിധി, അടയ്ക്കാനുള്ള തുക',
    ),
    'loans': (
      'ലോണുകളും EMI-കളും വ്യക്തമായി',
      'പലിശ നിരക്ക്, ഷെഡ്യൂൾ, ബാക്കി തുക — എല്ലാം അറിയാം',
    ),
    'reminders': (
      'ഒരു അവസാന തീയതിയും മറക്കരുത്',
      'ബില്ലുകൾ, EMI-കൾ, കാർഡ് അടവുകൾ — സമയത്ത് ഓർമ്മപ്പെടുത്തും',
    ),
    'reports': (
      'നിങ്ങളുടെ പണം എങ്ങോട്ട് പോകുന്നു എന്നറിയാം',
      'വിഭാഗം, അക്കൗണ്ട്, മാസം തിരിച്ച് വ്യക്തമായ ചാർട്ടുകൾ',
    ),
    'budgets': ('ബജറ്റിനുള്ളിൽ നിൽക്കാം', 'പരിധി കടക്കും മുമ്പേ മുന്നറിയിപ്പ്'),
    'dark': (
      'സ്വകാര്യം, ഇന്റർനെറ്റ് ഇല്ലാതെയും, നിങ്ങളുടെ ഭാഷയിൽ',
      'English · മലയാളം · ലൈറ്റ് & ഡാർക്ക്',
    ),
  },
};

List<_Scene> _scenes() {
  final l = _l10n;
  final cap = _captions[_lang]!;
  _Scene scene(
    String key,
    String file,
    Future<void> Function(WidgetTester) go, {
    bool dark = false,
  }) => _Scene(file, go, dark: dark, headline: cap[key]!.$1, sub: cap[key]!.$2);

  Future<void> openMore(WidgetTester t, String entry) async {
    await f.openTab(t, l.navMore);
    await tapText(t, entry);
  }

  return [
    scene('home', '01-home', (t) => f.openTab(t, l.navHome)),
    scene('add', '02-add-expense', (t) async {
      await t.tap(find.byTooltip(l.addTransaction));
      await settle(t);
      await enterField(t, l.amount, '1,250');
      await choosePayment(t, _names.salary);
      await chooseCategory(t, l.catFood);
      await scrollToTop(t);
    }),
    scene('accounts', '03-accounts', (t) => f.openTab(t, l.navAccounts)),
    scene('loans', '04-loans', (t) async {
      await f.openTab(t, l.navLoans);
      await tapText(t, _names.loan);
    }),
    scene('reminders', '05-reminders', (t) => openMore(t, l.remindersTitle)),
    scene('reports', '06-reports', (t) async {
      await openMore(t, l.reportsTitle);
      await tapText(t, l.reportCategories);
    }),
    scene('budgets', '07-budgets', (t) => openMore(t, l.budgetsTitle)),
    // Home, not a list: Apple's Malayalam font has no minus sign, so screens
    // with negative amounts would lose it in the Malayalam images.
    scene('dark', '08-dark-mode', (t) => f.openTab(t, l.navHome), dark: true),
  ];
}

// ----------------------------------------------------------- rendering

/// A kind of screen the app is rendered on.
class _Screen {
  const _Screen(this.size, this.ratio, this.topInset, this.bottomInset);

  /// Physical pixels.
  final Size size;
  final double ratio;

  /// Status bar / camera area and home indicator, in dp.
  final double topInset, bottomInset;
}

const _phone = _Screen(Size(1170, 2532), 3, 50, 34); // 390 x 844 dp
const _ipad = _Screen(Size(2064, 2752), 2, 24, 20); // 1032 x 1376 dp

/// Renders one scene in the real app and returns the raw screenshot.
Future<ui.Image> _shoot(
  WidgetTester tester,
  _Scene scene,
  _Screen screen,
) async {
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;

  await pumpApp(
    tester,
    themeMode: scene.dark ? ThemeMode.dark : ThemeMode.light,
    localeCode: _lang,
    physicalSize: screen.size,
    devicePixelRatio: screen.ratio,
  );
  tester.view.padding = FakeViewPadding(
    top: screen.topInset * screen.ratio,
    bottom: screen.bottomInset * screen.ratio,
  );
  tester.view.viewPadding = tester.view.padding;
  final container = ProviderScope.containerOf(
    tester.element(find.byType(KeptApp)),
  );
  await _seed(tester, container);
  await scene.go(tester);
  await settle(tester);
  final bytes = await _png(
    tester,
    find.byType(MaterialApp).first,
    screen.ratio,
  );
  return _decode(tester, bytes);
}

// ---------------------------------------------------------- composites

const _brandDark = Color(0xFF062A24);
const _brandMid = Color(0xFF0E7C66);
const _brandTop = Color(0xFF0B3D33);

Widget _brandBackground() => DecoratedBox(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_brandTop, _brandMid, _brandDark],
      stops: [0, 0.55, 1],
    ),
  ),
  child: LayoutBuilder(
    builder: (context, c) {
      Widget bloom(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      );
      return Stack(
        children: [
          Positioned(
            top: -c.maxWidth * 0.2,
            right: -c.maxWidth * 0.25,
            child: bloom(const Color(0x6634D399), c.maxWidth * 0.9),
          ),
          Positioned(
            bottom: c.maxHeight * 0.05,
            left: -c.maxWidth * 0.35,
            child: bloom(const Color(0x442DD4BF), c.maxWidth * 0.85),
          ),
        ],
      );
    },
  ),
);

/// The app screenshot inside a phone or tablet frame, with a status bar and
/// a home indicator drawn over the empty system areas (and, on a phone, a
/// camera cut-out).
class _Device extends StatelessWidget {
  const _Device({
    required this.shot,
    required this.width,
    required this.dark,
    this.tablet = false,
  });

  final ui.Image shot;
  final double width;
  final bool dark;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final aspect = shot.height / shot.width;
    final bezel = width * (tablet ? 0.022 : 0.024);
    final screenW = width - 2 * bezel;
    final screenH = screenW * aspect;
    final radius = width * (tablet ? 0.05 : 0.125);
    final ink = dark ? Colors.white : const Color(0xFF14201D);
    // One "dp" of the original screenshot.
    final unit = screenW / (tablet ? 1032 : 390);
    final barTop = tablet ? 4.0 : 16.0;
    final barSide = tablet ? 26.0 : 34.0;
    final textSize = tablet ? 13.0 : 16.0;
    final iconSize = tablet ? 16.0 : 19.0;
    return Container(
      width: width,
      height: screenH + 2 * bezel,
      padding: EdgeInsets.all(bezel),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D0E),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFF3A4346),
          width: width * 0.004,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 80,
            offset: Offset(0, 36),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - bezel),
        child: SizedBox(
          width: screenW,
          height: screenH,
          child: Stack(
            children: [
              RawImage(
                image: shot,
                width: screenW,
                height: screenH,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
              // Status bar.
              Positioned(
                top: unit * barTop,
                left: unit * barSide,
                child: Text(
                  tablet
                      ? '9:41   ${DateFormat('EEE d MMM').format(DateTime.now())}'
                      : '9:41',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: unit * textSize,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
              Positioned(
                top: unit * (barTop - 1),
                right: unit * (barSide - 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt_rounded,
                      size: unit * iconSize,
                      color: ink,
                    ),
                    SizedBox(width: unit * 4),
                    Icon(Icons.wifi_rounded, size: unit * iconSize, color: ink),
                    SizedBox(width: unit * 4),
                    Icon(
                      Icons.battery_full_rounded,
                      size: unit * (iconSize + 2),
                      color: ink,
                    ),
                  ],
                ),
              ),
              // Camera cut-out (phones only).
              if (!tablet)
                Positioned(
                  top: unit * 11,
                  left: (screenW - unit * 110) / 2,
                  child: Container(
                    width: unit * 110,
                    height: unit * 31,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(unit * 16),
                    ),
                  ),
                ),
              // Home indicator.
              Positioned(
                bottom: unit * (tablet ? 7 : 9),
                left: (screenW - unit * (tablet ? 170 : 136)) / 2,
                child: Container(
                  width: unit * (tablet ? 170 : 136),
                  height: unit * 5,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(unit * 3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A store screenshot: caption on the brand gradient, device below.
class _Marketing extends StatelessWidget {
  const _Marketing({
    required this.size,
    required this.scene,
    required this.shot,
    this.tablet = false,
  });

  final Size size;
  final _Scene scene;
  final ui.Image shot;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final w = size.width;
    final h = size.height;
    final ml = _lang == 'ml';
    final headSize = w * (tablet ? (ml ? 0.042 : 0.05) : (ml ? 0.062 : 0.074));
    final subSize = w * (tablet ? (ml ? 0.024 : 0.027) : (ml ? 0.032 : 0.036));
    final deviceTop = h * (tablet ? 0.175 : 0.215);
    final aspect = shot.height / shot.width;
    // Fit the device into the space left under the caption.
    final deviceHeightMax = h - deviceTop - h * 0.03;
    final deviceWidth = math.min(
      w * (tablet ? 0.86 : 0.78),
      deviceHeightMax / aspect * 0.985,
    );
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          Positioned.fill(child: _brandBackground()),
          Positioned(
            top: h * 0.04,
            left: w * 0.07,
            right: w * 0.07,
            height: deviceTop - h * 0.05,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  scene.headline,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontFamilyFallback: const ['MalayalamFallback'],
                    fontSize: headSize,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: w * 0.02),
                Text(
                  scene.sub,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontFamilyFallback: const ['MalayalamFallback'],
                    fontSize: subSize,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: deviceTop,
            left: 0,
            right: 0,
            child: Center(
              child: _Device(
                shot: shot,
                width: deviceWidth,
                dark: scene.dark,
                tablet: tablet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Google Play feature graphic (1024 x 500): the app icon and tagline on
/// the brand gradient, with two phones bleeding off the bottom edge.
class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic({
    required this.icon,
    required this.back,
    required this.front,
  });

  final ui.Image icon;
  final ui.Image back;
  final ui.Image front;

  @override
  Widget build(BuildContext context) {
    final ml = _lang == 'ml';
    final tagline = _captions[_lang]!['home']!.$1;
    final blurb = ml
        ? 'ചെലവുകൾ, അക്കൗണ്ടുകൾ, കാർഡുകൾ, ലോണുകൾ, ഓർമ്മപ്പെടുത്തലുകൾ'
        : 'Expenses, accounts, cards, loans and reminders';
    TextStyle style(double size, FontWeight weight, double alpha) => TextStyle(
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['MalayalamFallback'],
      fontSize: size,
      height: 1.15,
      fontWeight: weight,
      color: Colors.white.withValues(alpha: alpha),
    );
    return SizedBox(
      width: 1024,
      height: 500,
      child: Stack(
        children: [
          Positioned.fill(child: _brandBackground()),
          Positioned(
            left: 56,
            top: 0,
            bottom: 0,
            width: 500,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: RawImage(
                          image: icon,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                    Text('Kept', style: style(70, FontWeight.w900, 1)),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  tagline,
                  maxLines: 2,
                  style: style(ml ? 38 : 44, FontWeight.w800, 1),
                ),
                const SizedBox(height: 14),
                Text(
                  blurb,
                  maxLines: 2,
                  style: style(ml ? 20 : 23, FontWeight.w500, 0.8),
                ),
              ],
            ),
          ),
          Positioned(
            left: 585,
            top: 62,
            child: Transform.rotate(
              angle: 0.07,
              child: _Device(shot: back, width: 235, dark: false),
            ),
          ),
          Positioned(
            left: 770,
            top: 96,
            child: Transform.rotate(
              angle: -0.05,
              child: _Device(shot: front, width: 235, dark: false),
            ),
          ),
        ],
      ),
    );
  }
}

Future<Uint8List> _compose(
  WidgetTester tester,
  Widget canvas,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Material(
        color: _brandDark,
        child: RepaintBoundary(child: canvas),
      ),
    ),
  );
  await tester.pump();
  return _png(tester, find.byType(RepaintBoundary).last, 1);
}

// ---------------------------------------------------------------- main

void main() {
  testWidgets('store images ($_lang)', (tester) async {
    await _loadFonts();
    // Tests draw elevation shadows as hard black outlines (around the add
    // button, for one); real devices draw them soft. The flag must be put
    // back before the test ends.
    final shadowsWereDisabled = debugDisableShadows;
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = shadowsWereDisabled);
    try {
      await _renderAll(tester);
    } finally {
      debugDisableShadows = shadowsWereDisabled;
    }
  }, timeout: const Timeout(Duration(minutes: 15)));
}

/// Which images to make: all of them, only the phone ones, or only iPad.
final _only = Platform.environment['STORE_ONLY'] ?? 'all';

Future<void> _renderAll(WidgetTester tester) async {
  const play = Size(1080, 1920);
  const iphone = Size(1320, 2868);
  const ipad = Size(2064, 2752);
  final phoneShots = <String, ui.Image>{};
  for (final scene in _scenes()) {
    if (_only != 'ipad') {
      final shot = await _shoot(tester, scene, _phone);
      phoneShots[scene.file] = shot;
      for (final (folder, size) in [
        ('google-play/phone-screenshots', play),
        ('app-store/iphone-6.9', iphone),
      ]) {
        final bytes = await _compose(
          tester,
          _Marketing(size: size, scene: scene, shot: shot),
          size,
        );
        _write('$_out/$folder/$_lang/${scene.file}.png', bytes);
      }
    }
    if (_only != 'phone') {
      final shot = await _shoot(tester, scene, _ipad);
      final bytes = await _compose(
        tester,
        _Marketing(size: ipad, scene: scene, shot: shot, tablet: true),
        ipad,
      );
      _write('$_out/app-store/ipad-13/$_lang/${scene.file}.png', bytes);
    }
    // ignore: avoid_print
    print('rendered ${scene.file} ($_lang)');
  }
  if (_only != 'ipad') {
    final icon = await _decode(
      tester,
      File('assets/icon/icon.png').readAsBytesSync(),
    );
    final bytes = await _compose(
      tester,
      _FeatureGraphic(
        icon: icon,
        back: phoneShots['01-home']!,
        front: phoneShots['04-loans']!,
      ),
      const Size(1024, 500),
    );
    _write(
      '$_out/google-play/feature-graphic/feature-graphic-$_lang.png',
      bytes,
    );
    // ignore: avoid_print
    print('rendered feature graphic ($_lang)');
  }
}
