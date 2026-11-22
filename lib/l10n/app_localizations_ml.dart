// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get appTitle => 'Kept';

  @override
  String get save => 'സേവ് ചെയ്യുക';

  @override
  String get cancel => 'റദ്ദാക്കുക';

  @override
  String get delete => 'ഇല്ലാതാക്കുക';

  @override
  String get edit => 'എഡിറ്റ് ചെയ്യുക';

  @override
  String get duplicate => 'പകർത്തുക';

  @override
  String get add => 'ചേർക്കുക';

  @override
  String get close => 'അടയ്ക്കുക';

  @override
  String get done => 'പൂർത്തിയായി';

  @override
  String get retry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get confirm => 'സ്ഥിരീകരിക്കുക';

  @override
  String get apply => 'പ്രയോഗിക്കുക';

  @override
  String get reset => 'റീസെറ്റ് ചെയ്യുക';

  @override
  String get clear => 'മായ്ക്കുക';

  @override
  String get none => 'ഒന്നുമില്ല';

  @override
  String get all => 'എല്ലാം';

  @override
  String get optional => 'ഓപ്ഷണൽ';

  @override
  String get required => 'ആവശ്യമാണ്';

  @override
  String get notes => 'കുറിപ്പുകൾ';

  @override
  String get description => 'വിവരണം';

  @override
  String get date => 'തീയതി';

  @override
  String get time => 'സമയം';

  @override
  String get amount => 'തുക';

  @override
  String get name => 'പേര്';

  @override
  String get archive => 'ആർക്കൈവ് ചെയ്യുക';

  @override
  String get unarchive => 'ആർക്കൈവിൽ നിന്ന് മാറ്റുക';

  @override
  String get archived => 'ആർക്കൈവ് ചെയ്തത്';

  @override
  String get seeAll => 'എല്ലാം കാണുക';

  @override
  String get today => 'ഇന്ന്';

  @override
  String get yesterday => 'ഇന്നലെ';

  @override
  String get previousMonth => 'കഴിഞ്ഞ മാസം';

  @override
  String get nextMonth => 'അടുത്ത മാസം';

  @override
  String get thisMonth => 'ഈ മാസം';

  @override
  String get pickDate => 'തീയതി തിരഞ്ഞെടുക്കുക';

  @override
  String get pickTime => 'സമയം തിരഞ്ഞെടുക്കുക';

  @override
  String get noDate => 'തീയതി ഇല്ല';

  @override
  String deleteConfirmTitle(String item) {
    return '$item ഇല്ലാതാക്കണോ?';
  }

  @override
  String get deleteConfirmBody => 'ഇത് തിരിച്ചെടുക്കാൻ കഴിയില്ല.';

  @override
  String get deleted => 'ഇല്ലാതാക്കി';

  @override
  String get saved => 'സേവ് ചെയ്തു';

  @override
  String get loading => 'ലോഡ് ചെയ്യുന്നു…';

  @override
  String get somethingWentWrong => 'എന്തോ പിശക് സംഭവിച്ചു';

  @override
  String get emptyTitle => 'ഇവിടെ ഇതുവരെ ഒന്നുമില്ല';

  @override
  String get invalidAmount => 'പൂജ്യത്തേക്കാൾ വലിയ ശരിയായ തുക നൽകുക';

  @override
  String get invalidNumber => 'ശരിയായ സംഖ്യ നൽകുക';

  @override
  String get nameRequired => 'പേര് നൽകുക';

  @override
  String valueBetween(String min, String max) {
    return '$min-നും $max-നും ഇടയിലുള്ള മൂല്യം നൽകുക';
  }

  @override
  String comingFromInstallments(String count, String total) {
    return '$total-ൽ $count';
  }

  @override
  String get navHome => 'ഹോം';

  @override
  String get navTransactions => 'ഇടപാടുകൾ';

  @override
  String get navAccounts => 'അക്കൗണ്ട്';

  @override
  String get navLoans => 'ലോണുകൾ';

  @override
  String get navMore => 'കൂടുതൽ';

  @override
  String get failureNetwork =>
      'ഇന്റർനെറ്റ് കണക്ഷൻ ഇല്ല, അല്ലെങ്കിൽ കണക്ഷൻ ദുർബലമാണ്. മാറ്റങ്ങൾ ഈ ഫോണിൽ സേവ് ചെയ്തിട്ടുണ്ട്; വീണ്ടും കണക്ഷൻ കിട്ടുമ്പോൾ സിങ്ക് ചെയ്യും.';

  @override
  String get failurePermission =>
      'അതിനുള്ള അനുമതി നിങ്ങൾക്കില്ല. വീണ്ടും സൈൻ ഇൻ ചെയ്ത് നോക്കുക.';

  @override
  String get failureUnauthenticated =>
      'നിങ്ങളുടെ സെഷൻ കഴിഞ്ഞു. ദയവായി വീണ്ടും സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String get failureNotFound => 'ആ ഇനം ഇപ്പോൾ നിലവിലില്ല.';

  @override
  String get failureInvalidData =>
      'ഡാറ്റ തെറ്റാണ് അല്ലെങ്കിൽ കേടായിരിക്കുന്നു.';

  @override
  String get failureUnsupportedSchema =>
      'ഈ ബാക്കപ്പ് ആപ്പിന്റെ പുതിയ പതിപ്പിൽ എടുത്തതാണ്. പുനഃസ്ഥാപിക്കാൻ ആപ്പ് അപ്‌ഡേറ്റ് ചെയ്യുക.';

  @override
  String get failureNotification =>
      'ഈ ഫോണിൽ ഒരു ഓർമ്മപ്പെടുത്തൽ സെറ്റ് ചെയ്യാൻ കഴിഞ്ഞില്ല.';

  @override
  String get failureUnknown => 'എന്തോ പിശക് സംഭവിച്ചു. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String syncRejected(String reason) {
    return 'ഒരു മാറ്റം ക്ലൗഡിൽ സേവ് ചെയ്യാൻ കഴിഞ്ഞില്ല: $reason';
  }

  @override
  String get syncAllSynced => 'എല്ലാ മാറ്റങ്ങളും സിങ്ക് ചെയ്തു';

  @override
  String syncPending(String count) {
    return '$count മാറ്റങ്ങൾ സിങ്ക് ചെയ്യാനുണ്ട്';
  }

  @override
  String syncLastSynced(String time) {
    return 'അവസാനം സിങ്ക് ചെയ്തത്: $time';
  }

  @override
  String get failureSignInMethodDisabled =>
      'ഈ സൈൻ ഇൻ രീതി ഇപ്പോൾ ലഭ്യമല്ല. മറ്റൊരു രീതി ഉപയോഗിക്കുക.';

  @override
  String get undo => 'പഴയപടിയാക്കുക';

  @override
  String get discardTitle => 'മാറ്റങ്ങൾ ഉപേക്ഷിക്കണോ?';

  @override
  String get discardBody => 'സേവ് ചെയ്യാത്ത മാറ്റങ്ങൾ നഷ്ടപ്പെടും.';

  @override
  String get discard => 'ഉപേക്ഷിക്കുക';

  @override
  String get keepEditing => 'എഡിറ്റ് തുടരുക';

  @override
  String get restored => 'പുനഃസ്ഥാപിച്ചു';

  @override
  String get txTypeExpense => 'ചെലവ്';

  @override
  String get txTypeIncome => 'വരുമാനം';

  @override
  String get txTypeTransfer => 'ട്രാൻസ്ഫർ';

  @override
  String get txTypeCreditCardExpense => 'കാർഡ് ചെലവ്';

  @override
  String get txTypeCreditCardPayment => 'കാർഡ് ബിൽ അടവ്';

  @override
  String get txTypeLoanPayment => 'ലോൺ അടവ്';

  @override
  String get txTypeRefund => 'റീഫണ്ട്';

  @override
  String get txTypeBorrowed => 'കടം വാങ്ങിയത്';

  @override
  String get txTypeLent => 'കടം കൊടുത്തത്';

  @override
  String get txTypeDebtRepayment => 'കടം തിരിച്ചടച്ചു';

  @override
  String get txTypeDebtCollection => 'കടം തിരികെ കിട്ടി';

  @override
  String get txStatusCleared => 'പൂർത്തിയായത്';

  @override
  String get txStatusPending => 'തീർപ്പാകാത്തത്';

  @override
  String get accountTypeSavings => 'സേവിംഗ്സ് അക്കൗണ്ട്';

  @override
  String get accountTypeCurrent => 'കറന്റ് അക്കൗണ്ട്';

  @override
  String get accountTypeCash => 'പണം';

  @override
  String get accountTypeWallet => 'വാലറ്റ്';

  @override
  String get accountTypeOther => 'മറ്റുള്ളവ';

  @override
  String get catFood => 'ഭക്ഷണം';

  @override
  String get catFoodGroceries => 'പലചരക്ക്';

  @override
  String get catFoodDining => 'പുറത്തുനിന്നുള്ള ഭക്ഷണം';

  @override
  String get catFoodDelivery => 'ഫുഡ് ഡെലിവറി';

  @override
  String get catTransport => 'ഗതാഗതം';

  @override
  String get catTransportFuel => 'ഇന്ധനം';

  @override
  String get catTransportPublic => 'പൊതുഗതാഗതം';

  @override
  String get catTransportCab => 'ടാക്സി';

  @override
  String get catTransportParking => 'പാർക്കിംഗും ടോളും';

  @override
  String get catTransportService => 'വാഹന സർവീസ്';

  @override
  String get catShopping => 'ഷോപ്പിംഗ്';

  @override
  String get catShoppingClothing => 'വസ്ത്രങ്ങൾ';

  @override
  String get catShoppingElectronics => 'ഇലക്ട്രോണിക്സ്';

  @override
  String get catShoppingHome => 'വീട്ടുപകരണങ്ങൾ';

  @override
  String get catBills => 'ബില്ലുകൾ';

  @override
  String get catBillsElectricity => 'വൈദ്യുതി';

  @override
  String get catBillsWater => 'വെള്ളം';

  @override
  String get catBillsInternet => 'ഇന്റർനെറ്റ്';

  @override
  String get catBillsPhone => 'മൊബൈലും ഫോണും';

  @override
  String get catHousing => 'വീട്';

  @override
  String get catHousingRent => 'വാടക';

  @override
  String get catHousingMaintenance => 'അറ്റകുറ്റപ്പണി';

  @override
  String get catHealth => 'ആരോഗ്യം';

  @override
  String get catHealthMedical => 'ഡോക്ടറും ആശുപത്രിയും';

  @override
  String get catHealthPharmacy => 'ഫാർമസി';

  @override
  String get catHealthFitness => 'ഫിറ്റ്നസ്';

  @override
  String get catEntertainment => 'വിനോദം';

  @override
  String get catEntertainmentSubscriptions => 'സബ്സ്ക്രിപ്ഷനുകൾ';

  @override
  String get catEntertainmentOutings => 'സിനിമയും വിനോദയാത്രകളും';

  @override
  String get catEntertainmentTravel => 'യാത്രയും അവധിക്കാലവും';

  @override
  String get catEducation => 'വിദ്യാഭ്യാസം';

  @override
  String get catInsurance => 'ഇൻഷുറൻസ്';

  @override
  String get catPersonal => 'വ്യക്തിഗത പരിചരണം';

  @override
  String get catGifts => 'സമ്മാനങ്ങളും സംഭാവനകളും';

  @override
  String get catFees => 'ഫീസും ചാർജുകളും';

  @override
  String get catOther => 'മറ്റുള്ളവ';

  @override
  String get catSalary => 'ശമ്പളം';

  @override
  String get catBusiness => 'ബിസിനസ്';

  @override
  String get catInterest => 'പലിശ';

  @override
  String get catInvestment => 'നിക്ഷേപങ്ങൾ';

  @override
  String get catGiftIncome => 'ലഭിച്ച സമ്മാനങ്ങൾ';

  @override
  String get catOtherIncome => 'മറ്റ് വരുമാനം';

  @override
  String get catTransfer => 'ട്രാൻസ്ഫർ';

  @override
  String get catDebt => 'കടം വാങ്ങലും കൊടുക്കലും';

  @override
  String get catLoanEmi => 'ലോൺ EMI';

  @override
  String get catCardPayment => 'കാർഡ് അടവ്';

  @override
  String get freqOnce => 'ഒരിക്കൽ';

  @override
  String get freqDaily => 'ദിവസവും';

  @override
  String get freqWeekly => 'ആഴ്ചതോറും';

  @override
  String get freqMonthly => 'മാസംതോറും';

  @override
  String get freqYearly => 'വർഷംതോറും';

  @override
  String get freqQuarterly => 'മൂന്ന് മാസത്തിലൊരിക്കൽ';

  @override
  String get freqHalfYearly => 'ആറ് മാസത്തിലൊരിക്കൽ';

  @override
  String everyNDays(String n) {
    return 'ഓരോ $n ദിവസത്തിലും';
  }

  @override
  String everyNWeeks(String n) {
    return 'ഓരോ $n ആഴ്ചയിലും';
  }

  @override
  String everyNMonths(String n) {
    return 'ഓരോ $n മാസത്തിലും';
  }

  @override
  String everyNYears(String n) {
    return 'ഓരോ $n വർഷത്തിലും';
  }

  @override
  String get loanStatusActive => 'സജീവം';

  @override
  String get loanStatusCompleted => 'പൂർത്തിയായി';

  @override
  String get loanStatusClosed => 'അവസാനിപ്പിച്ചു';

  @override
  String get loanStatusPrepaid => 'മുൻകൂർ അടച്ചു';

  @override
  String get installmentPaid => 'അടച്ചു';

  @override
  String get installmentSkipped => 'ഒഴിവാക്കി';

  @override
  String get installmentOverdue => 'കാലാവധി കഴിഞ്ഞു';

  @override
  String get installmentUpcoming => 'വരാനിരിക്കുന്നത്';

  @override
  String get debtPending => 'തീർപ്പാകാത്തത്';

  @override
  String get debtPartial => 'ഭാഗികമായി തീർപ്പാക്കി';

  @override
  String get debtSettled => 'തീർപ്പാക്കി';

  @override
  String get debtOverdue => 'കാലാവധി കഴിഞ്ഞു';

  @override
  String get debtBorrowed => 'കടം വാങ്ങിയത്';

  @override
  String get debtLent => 'കടം കൊടുത്തത്';

  @override
  String get reminderTypeLoanEmi => 'ലോൺ EMI';

  @override
  String get reminderTypeCreditCard => 'ക്രെഡിറ്റ് കാർഡ് അടവ്';

  @override
  String get reminderTypeBorrowed => 'വാങ്ങിയ കടം';

  @override
  String get reminderTypeLent => 'കൊടുത്ത കടം';

  @override
  String get reminderTypeGym => 'ജിം';

  @override
  String get reminderTypeMeeting => 'മീറ്റിംഗ്';

  @override
  String get reminderTypeInsurance => 'ഇൻഷുറൻസ്';

  @override
  String get reminderTypeSubscription => 'സബ്സ്ക്രിപ്ഷൻ';

  @override
  String get reminderTypeBill => 'ബിൽ';

  @override
  String get reminderTypeCustom => 'മറ്റുള്ളവ';

  @override
  String get fuelPetrol => 'പെട്രോൾ';

  @override
  String get fuelDiesel => 'ഡീസൽ';

  @override
  String get fuelCng => 'CNG';

  @override
  String get fuelLpg => 'LPG';

  @override
  String get fuelElectric => 'ഇലക്ട്രിക്';

  @override
  String get fuelHybrid => 'ഹൈബ്രിഡ്';

  @override
  String get sortNewest => 'പുതിയത് ആദ്യം';

  @override
  String get sortOldest => 'പഴയത് ആദ്യം';

  @override
  String get sortLargest => 'ഏറ്റവും വലിയ തുക';

  @override
  String get sortSmallest => 'ഏറ്റവും ചെറിയ തുക';

  @override
  String get issueAmountNotPositive => 'തുക പൂജ്യത്തേക്കാൾ കൂടുതലായിരിക്കണം.';

  @override
  String get issueAmountTooLarge => 'തുക വളരെ വലുതാണ്.';

  @override
  String get issueCategoryMismatch =>
      'ഇടപാടിന്റെ തരത്തിന് ചേരുന്ന വിഭാഗം തിരഞ്ഞെടുക്കുക.';

  @override
  String get issueCardRequired => 'ഒരു ക്രെഡിറ്റ് കാർഡ് തിരഞ്ഞെടുക്കുക.';

  @override
  String get issueCardNotAllowed =>
      'ഈ തരത്തിന് ക്രെഡിറ്റ് കാർഡ് ഉപയോഗിക്കാൻ കഴിയില്ല.';

  @override
  String get issueSourceAccountRequired =>
      'പണം പോകുന്ന അക്കൗണ്ട് തിരഞ്ഞെടുക്കുക.';

  @override
  String get issueDestinationAccountRequired =>
      'പണം എത്തുന്ന അക്കൗണ്ട് തിരഞ്ഞെടുക്കുക.';

  @override
  String get issueSameTransferAccounts =>
      'അയയ്ക്കുന്ന അക്കൗണ്ടും സ്വീകരിക്കുന്ന അക്കൗണ്ടും വ്യത്യസ്തമായിരിക്കണം.';

  @override
  String get issueLoanRequired => 'ഒരു ലോൺ തിരഞ്ഞെടുക്കുക.';

  @override
  String get issueDebtRecordRequired =>
      'ഇതിന് ഒരു കടം വാങ്ങൽ/കൊടുക്കൽ രേഖ ആവശ്യമാണ്.';

  @override
  String get issueRefundTargetAmbiguous =>
      'റീഫണ്ട് ഒരു അക്കൗണ്ടിലേക്കോ ഒരു കാർഡിലേക്കോ ആണ് പോകേണ്ടത്, രണ്ടിലേക്കുമല്ല.';

  @override
  String get remindersTitle => 'ഓർമ്മപ്പെടുത്തലുകൾ';

  @override
  String get reminderNew => 'പുതിയ ഓർമ്മപ്പെടുത്തൽ';

  @override
  String get reminderEdit => 'ഓർമ്മപ്പെടുത്തൽ എഡിറ്റ് ചെയ്യുക';

  @override
  String get reminderTitleLabel => 'തലക്കെട്ട്';

  @override
  String get reminderTitleHint => 'ഉദാ. ജിം, വൈദ്യുതി ബിൽ അടയ്ക്കുക';

  @override
  String get reminderTypeLabel => 'തരം';

  @override
  String get reminderRepeat => 'ആവർത്തനം';

  @override
  String get reminderEvery => 'ഓരോ';

  @override
  String get reminderUntil => 'അവസാനിക്കുന്നത്';

  @override
  String get reminderNeverEnds => 'ഒരിക്കലുമില്ല';

  @override
  String get reminderNotify => 'എന്നെ അറിയിക്കുക';

  @override
  String get reminderOffsetAtTime => 'ആ സമയത്ത്';

  @override
  String reminderOffsetMinutes(String n) {
    return '$n മിനിറ്റ് മുമ്പ്';
  }

  @override
  String reminderOffsetHours(String n) {
    return '$n മണിക്കൂർ മുമ്പ്';
  }

  @override
  String reminderOffsetDays(String n) {
    return '$n ദിവസം മുമ്പ്';
  }

  @override
  String get reminderOffsetCustom => 'ഇഷ്ടാനുസൃതം…';

  @override
  String get reminderOffsetCustomTitle => 'എത്ര ദിവസം മുമ്പ്';

  @override
  String get reminderEnabled => 'പ്രവർത്തനക്ഷമം';

  @override
  String get reminderDisabled => 'പ്രവർത്തനരഹിതം';

  @override
  String reminderNext(String date) {
    return 'അടുത്തത്: $date';
  }

  @override
  String get reminderEnded => 'ഇനി വരാനുള്ളവ ഇല്ല';

  @override
  String reminderLinked(String module) {
    return '$module-ൽ നിന്നാണ് ഇത് നിയന്ത്രിക്കുന്നത്. സമയം, അലർട്ടുകൾ, ഓൺ/ഓഫ് എന്നിവ ഇവിടെ മാറ്റാം.';
  }

  @override
  String get remindersEmpty =>
      'ഇതുവരെ ഓർമ്മപ്പെടുത്തലുകളില്ല. ജിം, ബില്ലുകൾ, പുതുക്കലുകൾ, അല്ലെങ്കിൽ മറക്കാൻ പാടില്ലാത്ത മറ്റെന്തെങ്കിലും ചേർക്കുക.';

  @override
  String get remindersUpcoming => 'വരാനിരിക്കുന്നവ';

  @override
  String get remindersInactive => 'ഓഫ് ആയതോ കഴിഞ്ഞതോ';

  @override
  String get notificationsOff =>
      'ഈ ആപ്പിന് അറിയിപ്പുകൾ ഓഫാണ്, അതിനാൽ ഓർമ്മപ്പെടുത്തലുകൾ നിങ്ങളെ അറിയിക്കില്ല.';

  @override
  String get notificationsEnable => 'ഓൺ ആക്കുക';

  @override
  String notifDue(String what) {
    return '$what · സമയമായി';
  }

  @override
  String notifInDays(String what, String n) {
    return '$what · $n ദിവസം കഴിഞ്ഞ്';
  }

  @override
  String notifInHours(String what, String n) {
    return '$what · $n മണിക്കൂർ കഴിഞ്ഞ്';
  }

  @override
  String notifInMinutes(String what, String n) {
    return '$what · $n മിനിറ്റ് കഴിഞ്ഞ്';
  }

  @override
  String reminderLoanTitle(String name) {
    return 'EMI അടയ്ക്കണം: $name';
  }

  @override
  String reminderCardTitle(String name) {
    return 'കാർഡ് ബിൽ അടയ്ക്കണം: $name';
  }

  @override
  String reminderBorrowedTitle(String person) {
    return '$person-ന് തിരിച്ചടയ്ക്കുക';
  }

  @override
  String reminderLentTitle(String person) {
    return '$person-ൽ നിന്ന് തിരികെ വാങ്ങുക';
  }

  @override
  String get moduleLoans => 'ലോണുകൾ';

  @override
  String get moduleCards => 'ക്രെഡിറ്റ് കാർഡുകൾ';

  @override
  String get moduleBorrowLend => 'കടം വാങ്ങലും കൊടുക്കലും';

  @override
  String get addTransaction => 'ഇടപാട് ചേർക്കുക';

  @override
  String get editTransaction => 'ഇടപാട് എഡിറ്റ് ചെയ്യുക';

  @override
  String get duplicateTransaction => 'ഇടപാട് പകർത്തുക';

  @override
  String get transactionDetails => 'ഇടപാട്';

  @override
  String get txMoreTypes => 'കൂടുതൽ';

  @override
  String get category => 'വിഭാഗം';

  @override
  String get subcategory => 'ഉപവിഭാഗം';

  @override
  String get paidWith => 'പേയ്മെന്റ് മാർഗം';

  @override
  String get receivedIn => 'ലഭിച്ച അക്കൗണ്ട്';

  @override
  String get fromAccount => 'അയയ്ക്കുന്ന അക്കൗണ്ട്';

  @override
  String get toAccount => 'സ്വീകരിക്കുന്ന അക്കൗണ്ട്';

  @override
  String get creditCard => 'ക്രെഡിറ്റ് കാർഡ്';

  @override
  String get refundTo => 'റീഫണ്ട് ലഭിക്കുന്നത്';

  @override
  String get cashUntracked => 'പണം / ട്രാക്ക് ചെയ്യാത്തത്';

  @override
  String get merchantOrPerson => 'കടയോ വ്യക്തിയോ';

  @override
  String get tags => 'ടാഗുകൾ';

  @override
  String get tagsHint => 'കോമ ഇട്ട് വേർതിരിക്കുക, ഉദാ. യാത്ര, ഓഫീസ്';

  @override
  String get markPending => 'തീർപ്പാകാത്തത് (ഇതുവരെ അടച്ചിട്ടില്ല)';

  @override
  String get markPendingHelp =>
      'തീർപ്പാകാത്ത ഇടപാടുകൾ പൂർത്തിയാകുന്നതുവരെ ബാലൻസിനെയോ മൊത്തത്തെയോ ബാധിക്കില്ല.';

  @override
  String get noAccountsHint =>
      'ബാലൻസ് ട്രാക്ക് ചെയ്യാൻ ഒരു അക്കൗണ്ടോ കാർഡോ ചേർക്കുക. പണമായുള്ള ചെലവുകളും രേഖപ്പെടുത്താം.';

  @override
  String get transactionSaved => 'ഇടപാട് സേവ് ചെയ്തു';

  @override
  String get transactionDeleted => 'ഇടപാട് ഇല്ലാതാക്കി';

  @override
  String budgetWarning(String budget, String percent) {
    return 'ഈ മാസത്തെ $budget ബജറ്റിന്റെ $percent% ഉപയോഗിച്ചു';
  }

  @override
  String get budgetOverall => 'ആകെ';

  @override
  String managedElsewhere(String module) {
    return 'ഈ എൻട്രി $module-ൽ നിന്നാണ് നിയന്ത്രിക്കുന്നത്. മാറ്റാനോ നീക്കാനോ അവിടെ തുറക്കുക.';
  }

  @override
  String get moduleVehicles => 'വാഹനങ്ങൾ';

  @override
  String get searchTransactions => 'തിരയുക: വിവരണം, വിഭാഗം, തുക, തീയതി…';

  @override
  String get filters => 'ഫിൽട്ടറുകൾ';

  @override
  String filtersActive(String count) {
    return 'ഫിൽട്ടറുകൾ ($count)';
  }

  @override
  String get sortBy => 'ക്രമീകരിക്കേണ്ടത്';

  @override
  String get accountsLabel => 'അക്കൗണ്ടുകൾ';

  @override
  String get cardsLabel => 'കാർഡുകൾ';

  @override
  String get categoriesLabel => 'വിഭാഗങ്ങൾ';

  @override
  String get amountRange => 'തുകയുടെ പരിധി';

  @override
  String get minAmount => 'കുറഞ്ഞത്';

  @override
  String get maxAmount => 'കൂടിയത്';

  @override
  String get clearFilters => 'ഫിൽട്ടറുകൾ മായ്ക്കുക';

  @override
  String get dateRange => 'തീയതി പരിധി';

  @override
  String get customRange => 'ഇഷ്ടാനുസൃത പരിധി';

  @override
  String get backToMonth => 'മാസ കാഴ്ചയിലേക്ക് മടങ്ങുക';

  @override
  String get listView => 'ലിസ്റ്റ്';

  @override
  String get calendarView => 'കലണ്ടർ';

  @override
  String get noTransactions =>
      'ഈ കാലയളവിൽ ഇതുവരെ ഇടപാടുകളില്ല. ആദ്യത്തേത് ചേർക്കാൻ + അമർത്തുക.';

  @override
  String get noMatches =>
      'നിങ്ങളുടെ തിരയലിനോ ഫിൽട്ടറുകൾക്കോ യോജിക്കുന്ന ഇടപാടുകളില്ല.';

  @override
  String dayTotal(String amount) {
    return 'ചെലവ് $amount';
  }

  @override
  String get moneyIn => 'വരവ്';

  @override
  String get moneyOut => 'ചെലവ്';

  @override
  String transactionsCount(String count) {
    return '$count ഇടപാടുകൾ';
  }

  @override
  String get recurringGenerated => 'ആവർത്തന ഇടപാട് ഉണ്ടാക്കിയത്';

  @override
  String importedFrom(String source) {
    return 'ഇമ്പോർട്ട് ചെയ്തത് ($source)';
  }

  @override
  String get selectDay => 'ഇടപാടുകൾ കാണാൻ ഒരു ദിവസം തിരഞ്ഞെടുക്കുക';

  @override
  String get noTransactionsOnDay => 'ഈ ദിവസം ഒന്നും രേഖപ്പെടുത്തിയിട്ടില്ല.';

  @override
  String get status => 'സ്ഥിതി';

  @override
  String get entriesLabel => 'എൻട്രികൾ';

  @override
  String get typeLabel => 'തരം';

  @override
  String dashboardSpentThisMonth(String month) {
    return '$month-ലെ ചെലവ്';
  }

  @override
  String get dashboardIncome => 'വരുമാനം';

  @override
  String get dashboardSpending => 'ചെലവ്';

  @override
  String get dashboardSavings => 'സമ്പാദ്യം';

  @override
  String dashboardSavingsRate(String percent) {
    return 'വരുമാനത്തിന്റെ $percent% സമ്പാദിച്ചു';
  }

  @override
  String dashboardOverspent(String amount) {
    return 'വരുമാനത്തേക്കാൾ $amount കൂടുതൽ ചെലവായി';
  }

  @override
  String get dashboardNoIncome => 'ഈ മാസം വരുമാനം രേഖപ്പെടുത്തിയിട്ടില്ല';

  @override
  String get dashboardEmi => 'അടച്ച EMI-കൾ';

  @override
  String get dashboardCardSpending => 'കാർഡ് ചെലവ്';

  @override
  String get dashboardBorrowed => 'കടം വാങ്ങിയത്';

  @override
  String get dashboardLent => 'കടം കൊടുത്തത്';

  @override
  String get dashboardPendingPayments => 'ബാക്കിയുള്ള അടവുകൾ';

  @override
  String get dashboardScopeAll => 'എല്ലാ അക്കൗണ്ടുകളും കാർഡുകളും';

  @override
  String get dashboardUpcoming => 'വരാനിരിക്കുന്നത്';

  @override
  String get dashboardUpcomingEmpty =>
      'അടുത്ത 30 ദിവസത്തിനുള്ളിൽ അടയ്ക്കാനൊന്നുമില്ല.';

  @override
  String get dashboardOverdue => 'കാലാവധി കഴിഞ്ഞത്';

  @override
  String dashboardDueOn(String date) {
    return '$date-ന് അടയ്ക്കണം';
  }

  @override
  String get dashboardRecent => 'സമീപകാല ഇടപാടുകൾ';

  @override
  String get dashboardBudget => 'പ്രതിമാസ ബജറ്റ്';

  @override
  String dashboardBudgetLeft(String amount) {
    return '$amount ബാക്കി';
  }

  @override
  String dashboardBudgetOver(String amount) {
    return 'ബജറ്റിനേക്കാൾ $amount കൂടുതൽ';
  }

  @override
  String get chartByCategory => 'വിഭാഗം അനുസരിച്ചുള്ള ചെലവ്';

  @override
  String get chartDaily => 'ദിവസേനയുള്ള ചെലവ്';

  @override
  String get chartIncomeVsSpending => 'വരുമാനവും ചെലവും';

  @override
  String get chartByAccount => 'അക്കൗണ്ട് അനുസരിച്ചുള്ള ചെലവ്';

  @override
  String get chartByCard => 'കാർഡ് അനുസരിച്ചുള്ള ചെലവ്';

  @override
  String get chartTrend => 'പ്രതിമാസ ചെലവിന്റെ പ്രവണത';

  @override
  String get chartNoData => 'ഈ കാലയളവിൽ ചാർട്ട് ചെയ്യാൻ ചെലവുകളില്ല.';

  @override
  String get chartOther => 'മറ്റുള്ളവ';

  @override
  String chartSemanticsTotal(String title, String amount) {
    return '$title. ആകെ $amount.';
  }

  @override
  String get netWorth => 'നെറ്റ് വർത്ത്';

  @override
  String get searchEverything => 'എല്ലാം തിരയുക';

  @override
  String get emptyDashboardTitle => 'സ്വാഗതം! നമുക്ക് തുടങ്ങാം';

  @override
  String get emptyDashboardBody =>
      'ഒരു അക്കൗണ്ടോ കാർഡോ ചേർത്ത ശേഷം ആദ്യത്തെ ചെലവ് രേഖപ്പെടുത്തുക. എല്ലാം ഇന്റർനെറ്റ് ഇല്ലാതെയും പ്രവർത്തിക്കും; ഓൺലൈനിൽ വരുമ്പോൾ സിങ്ക് ചെയ്യും.';

  @override
  String get addAccount => 'അക്കൗണ്ട് ചേർക്കുക';

  @override
  String get addCard => 'കാർഡ് ചേർക്കുക';

  @override
  String get addExpense => 'ചെലവ് ചേർക്കുക';

  @override
  String get accountsTitle => 'അക്കൗണ്ടുകളും കാർഡുകളും';

  @override
  String get accountsTab => 'അക്കൗണ്ടുകൾ';

  @override
  String get cardsTab => 'ക്രെഡിറ്റ് കാർഡുകൾ';

  @override
  String get newAccount => 'പുതിയ അക്കൗണ്ട്';

  @override
  String get editAccount => 'അക്കൗണ്ട് എഡിറ്റ് ചെയ്യുക';

  @override
  String get accountName => 'അക്കൗണ്ടിന്റെ പേര്';

  @override
  String get accountNameHint => 'ഉദാ. ശമ്പള അക്കൗണ്ട്, വാലറ്റ്';

  @override
  String get bankName => 'ബാങ്കിന്റെ പേര്';

  @override
  String get openingBalance => 'ആരംഭ ബാലൻസ്';

  @override
  String get openingBalanceHelp =>
      'ട്രാക്ക് ചെയ്യാൻ തുടങ്ങുന്ന ദിവസത്തെ ബാലൻസ്. ഇവിടെ രേഖപ്പെടുത്തുന്ന ഇടപാടുകൾ ഇതിനെ സ്വയം ക്രമീകരിക്കും.';

  @override
  String get currentBalance => 'നിലവിലെ ബാലൻസ്';

  @override
  String get noCredentialsNote =>
      'പാസ്‌വേഡ്, പിൻ, കാർഡ് നമ്പർ എന്നിവ ഒരിക്കലും നൽകരുത്. ഈ ആപ്പിന് അവ ആവശ്യമില്ല.';

  @override
  String get accountsEmpty =>
      'ഇതുവരെ അക്കൗണ്ടുകളില്ല. ബാലൻസ് കാണാൻ ബാങ്ക് അക്കൗണ്ടുകൾ, പണം, വാലറ്റുകൾ എന്നിവ ചേർക്കുക.';

  @override
  String get assets => 'അക്കൗണ്ടുകൾ';

  @override
  String get cardDebt => 'കാർഡ് കുടിശ്ശിക';

  @override
  String showArchived(String count) {
    return 'ആർക്കൈവ് ചെയ്തത് ($count)';
  }

  @override
  String get accountInUse =>
      'ഈ അക്കൗണ്ട് ഇടപാടുകളിലോ ലോണുകളിലോ കടം രേഖകളിലോ ആവർത്തന എൻട്രികളിലോ കാർഡിലോ ഉപയോഗിക്കുന്നുണ്ട്, അതിനാൽ ഇല്ലാതാക്കാൻ കഴിയില്ല. പകരം ആർക്കൈവ് ചെയ്ത് മറയ്ക്കുക.';

  @override
  String get accountArchived => 'അക്കൗണ്ട് ആർക്കൈവ് ചെയ്തു';

  @override
  String get recentActivity => 'സമീപകാല പ്രവർത്തനം';

  @override
  String get noActivity => 'ബന്ധിപ്പിച്ച ഇടപാടുകൾ ഇതുവരെയില്ല.';

  @override
  String get inThisMonth => 'ഈ മാസത്തെ വരവ്';

  @override
  String get outThisMonth => 'ഈ മാസത്തെ ചെലവ്';

  @override
  String get newCard => 'പുതിയ ക്രെഡിറ്റ് കാർഡ്';

  @override
  String get editCard => 'ക്രെഡിറ്റ് കാർഡ് എഡിറ്റ് ചെയ്യുക';

  @override
  String get cardName => 'കാർഡിന്റെ പേര്';

  @override
  String get cardNameHint => 'ഉദാ. മില്ലേനിയ, ആമസോൺ പേ';

  @override
  String get last4 => 'അവസാന 4 അക്കങ്ങൾ';

  @override
  String get last4Help =>
      'കാർഡ് തിരിച്ചറിയാൻ മാത്രം. മുഴുവൻ നമ്പർ ഒരിക്കലും നൽകരുത്.';

  @override
  String get last4Invalid => 'കൃത്യം 4 അക്കങ്ങൾ നൽകുക';

  @override
  String get creditLimit => 'ക്രെഡിറ്റ് പരിധി';

  @override
  String get currentOutstanding => 'നിലവിലെ ബാക്കി തുക';

  @override
  String get currentOutstandingHelp =>
      'ഇന്ന് നിങ്ങൾ അടയ്ക്കാനുള്ള തുക. പുതിയ കാർഡ് ഇടപാടുകൾ ഇത് സ്വയം പുതുക്കും.';

  @override
  String get statementDay => 'സ്റ്റേറ്റ്മെന്റ് ദിവസം';

  @override
  String get dueDay => 'അടവിന്റെ അവസാന ദിവസം';

  @override
  String get dayOfMonth => 'മാസത്തിലെ ദിവസം (1–31)';

  @override
  String get minimumDuePercent => 'കുറഞ്ഞ അടവ് %';

  @override
  String get minimumDuePercentHelp =>
      'കുറഞ്ഞ അടവ് ഏകദേശം കണക്കാക്കാൻ ഉപയോഗിക്കുന്നു. കൃത്യമായ തുകയ്ക്ക് നിങ്ങളുടെ സ്റ്റേറ്റ്മെന്റ് നോക്കുക.';

  @override
  String get linkedAccount => 'പണം അടയ്ക്കുന്ന അക്കൗണ്ട്';

  @override
  String get cardsEmpty =>
      'ഇതുവരെ ക്രെഡിറ്റ് കാർഡുകളില്ല. പരിധി, ഉപയോഗം, അവസാന തീയതികൾ എന്നിവ ട്രാക്ക് ചെയ്യാൻ ഒന്ന് ചേർക്കുക.';

  @override
  String get outstanding => 'ബാക്കി തുക';

  @override
  String get available => 'ലഭ്യമായത്';

  @override
  String get utilization => 'ഉപയോഗം';

  @override
  String utilizationValue(String percent) {
    return '$percent% ഉപയോഗിച്ചു';
  }

  @override
  String get statement => 'അവസാന സ്റ്റേറ്റ്മെന്റ്';

  @override
  String get statementBalance => 'സ്റ്റേറ്റ്മെന്റ് ബാലൻസ്';

  @override
  String get totalDue => 'ആകെ അടയ്ക്കേണ്ടത്';

  @override
  String get minimumDueEstimate => 'കുറഞ്ഞ അടവ് (ഏകദേശം)';

  @override
  String get dueDate => 'അവസാന തീയതി';

  @override
  String get paidInFull => 'അടച്ചു';

  @override
  String get payBill => 'ബിൽ അടയ്ക്കുക';

  @override
  String get addCardExpense => 'ചെലവ് ചേർക്കുക';

  @override
  String get cardSpending6m => 'കാർഡ് ചെലവ്, കഴിഞ്ഞ 6 മാസം';

  @override
  String get cardInUse =>
      'ഈ കാർഡ് ഇടപാടുകളിലോ ആവർത്തന എൻട്രികളിലോ ഉപയോഗിക്കുന്നുണ്ട്, അതിനാൽ ഇല്ലാതാക്കാൻ കഴിയില്ല. പകരം ആർക്കൈവ് ചെയ്യുക.';

  @override
  String get cardReminderNote =>
      'അവസാന തീയതിക്കുള്ള ഓർമ്മപ്പെടുത്തൽ സ്വയം ഉണ്ടാക്കും. ഓർമ്മപ്പെടുത്തലുകളിൽ ഇത് മാറ്റാം.';

  @override
  String get recalcBalances => 'ബാലൻസുകൾ വീണ്ടും കണക്കാക്കുക';

  @override
  String get recalcBalancesHelp =>
      'നിങ്ങളുടെ മുഴുവൻ ഇടപാട് ചരിത്രത്തിൽ നിന്ന് എല്ലാ അക്കൗണ്ട്, കാർഡ് ബാലൻസുകളും വീണ്ടും കണക്കാക്കുന്നു. ഒരു ബാലൻസ് തെറ്റായി തോന്നിയാൽ ഇത് ഉപയോഗിക്കുക.';

  @override
  String get recalcDone => 'ബാലൻസുകൾ വീണ്ടും കണക്കാക്കി';

  @override
  String get dayInvalid => '1 നും 31 നും ഇടയിലുള്ള ദിവസം നൽകുക';

  @override
  String get accountTypeLabel => 'അക്കൗണ്ട് തരം';

  @override
  String get outstandingWhenAdded => 'ചേർത്തപ്പോഴത്തെ ബാക്കി തുക';

  @override
  String outstandingWhenAddedHelp(String current) {
    return 'കാർഡിന്റെ നിലവിലെ ബാക്കി തുക $current ആണ്; ആപ്പിൽ രേഖപ്പെടുത്തിയ ഇടപാടുകൾ ഇതിൽ ഉൾപ്പെടുന്നു. തുടക്കത്തിലെ തുക തിരുത്താൻ മാത്രം ഇത് മാറ്റുക.';
  }

  @override
  String get cardDueDate => 'അടയ്ക്കേണ്ട അവസാന തീയതി';

  @override
  String get cardDueDateHelp => 'എല്ലാ മാസവും ഈ ദിവസം ആവർത്തിക്കും.';

  @override
  String get cardDueDateRequired => 'അടയ്ക്കേണ്ട തീയതി തിരഞ്ഞെടുക്കുക';

  @override
  String get cardMoreDetails => 'കൂടുതൽ വിവരങ്ങൾ (ഓപ്ഷണൽ)';

  @override
  String get loansTitle => 'ലോണുകൾ';

  @override
  String get loansEmpty =>
      'ഇതുവരെ ലോണുകളില്ല. EMI, പലിശ, അടയ്ക്കാൻ ബാക്കിയുള്ളത് എന്നിവ ട്രാക്ക് ചെയ്യാൻ ഒരു ലോൺ ചേർക്കുക.';

  @override
  String get addLoan => 'ലോൺ ചേർക്കുക';

  @override
  String get newLoan => 'പുതിയ ലോൺ';

  @override
  String get editLoan => 'ലോൺ എഡിറ്റ് ചെയ്യുക';

  @override
  String get loanName => 'ലോണിന്റെ പേര്';

  @override
  String get loanNameHint => 'ഉദാ. ഹോം ലോൺ, കാർ ലോൺ';

  @override
  String get lender => 'ലോൺ നൽകിയ സ്ഥാപനം';

  @override
  String get principal => 'മുതൽ തുക';

  @override
  String get interestRate => 'പലിശ നിരക്ക് (വർഷത്തിൽ %)';

  @override
  String get tenure => 'EMI-കളുടെ എണ്ണം';

  @override
  String tenureMonthsHelp(String months) {
    return '$months മാസം';
  }

  @override
  String get firstEmiDate => 'ആദ്യ EMI തീയതി';

  @override
  String get emiAmount => 'EMI തുക';

  @override
  String get payFromAccount => 'EMI അടയ്ക്കുന്ന അക്കൗണ്ട്';

  @override
  String get loanReminder => 'ഓരോ EMI-ക്കും മുമ്പ് ഓർമ്മിപ്പിക്കുക';

  @override
  String get loansOutstanding => 'ആകെ ബാക്കി തുക';

  @override
  String get loansMonthlyEmi => 'പ്രതിമാസ EMI-കൾ';

  @override
  String loansActive(String count) {
    return '$count സജീവം';
  }

  @override
  String loanOverdueCount(String count) {
    return '$count കാലാവധി കഴിഞ്ഞത്';
  }

  @override
  String loanProgress(String paid, String total) {
    return '$total EMI-യിൽ $paid അടച്ചു';
  }

  @override
  String get outstandingPrincipal => 'ബാക്കിയുള്ള മുതൽ';

  @override
  String get nextEmi => 'അടുത്ത EMI';

  @override
  String nextEmiOn(String number, String date) {
    return '#$number, $date';
  }

  @override
  String get noNextEmi => 'ഇനി EMI ബാക്കിയില്ല';

  @override
  String get paidEmis => 'അടച്ച EMI-കൾ';

  @override
  String get remainingEmis => 'ബാക്കി EMI-കൾ';

  @override
  String get totalInterest => 'ആകെ പലിശ';

  @override
  String get paidInterest => 'അടച്ച പലിശ';

  @override
  String get remainingInterest => 'ബാക്കി പലിശ';

  @override
  String get principalPaid => 'അടച്ച മുതൽ';

  @override
  String get prepaid => 'മുൻകൂർ അടച്ചത്';

  @override
  String get principalVsInterest => 'മുതലും പലിശയും';

  @override
  String get principalLabel => 'മുതൽ';

  @override
  String get interestLabel => 'പലിശ';

  @override
  String get markPaid => 'EMI അടച്ചതായി രേഖപ്പെടുത്തുക';

  @override
  String markPaidTitle(String number) {
    return 'EMI #$number';
  }

  @override
  String get paidOn => 'അടച്ച തീയതി';

  @override
  String get skipEmi => 'ഒഴിവാക്കിയതായി രേഖപ്പെടുത്തുക';

  @override
  String get clearMark => 'അടയാളം നീക്കുക';

  @override
  String get recordPrepayment => 'മുൻകൂർ അടവ് രേഖപ്പെടുത്തുക';

  @override
  String get prepaymentAmount => 'മുൻകൂർ അടയ്ക്കുന്ന തുക';

  @override
  String get prepaymentMode => 'മുൻകൂർ അടച്ച ശേഷം';

  @override
  String get prepayReduceTenure => 'EMI അതേപടി, ലോൺ നേരത്തെ തീരും';

  @override
  String get prepayReduceEmi => 'കാലാവധി അതേപടി, EMI കുറയും';

  @override
  String get prepayPreview => 'എന്തൊക്കെ മാറും';

  @override
  String prepayNewEmi(String before, String after) {
    return 'EMI: $before → $after';
  }

  @override
  String prepayNewTenure(String before, String after) {
    return 'ബാക്കി EMI-കൾ: $before → $after';
  }

  @override
  String prepayInterestSaved(String amount) {
    return 'ലാഭിക്കുന്ന പലിശ: $amount';
  }

  @override
  String prepayOutstanding(String before, String after) {
    return 'ബാക്കി തുക: $before → $after';
  }

  @override
  String get prepayExplain =>
      'മുൻകൂർ അടവ് മുതൽ ഉടൻ കുറയ്ക്കുന്നു. EMI തുക അതേപടി നിലനിർത്തണോ (ലോൺ നേരത്തെ തീരും) അതോ EMI-കളുടെ എണ്ണം അതേപടി നിലനിർത്തണോ (EMI കുറയും) എന്ന് നിങ്ങൾക്ക് തിരഞ്ഞെടുക്കാം. നിങ്ങൾ സ്ഥിരീകരിക്കുന്നതുവരെ ഒന്നും മാറില്ല.';

  @override
  String get prepayments => 'മുൻകൂർ അടവുകൾ';

  @override
  String get schedule => 'തിരിച്ചടവ് ഷെഡ്യൂൾ';

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
    return 'EMI $number, അവസാന തീയതി $date, $emi, മുതൽ $principal, പലിശ $interest, ബാലൻസ് $balance, $status';
  }

  @override
  String get balanceLabel => 'ബാലൻസ്';

  @override
  String get emiDoesNotCoverInterest =>
      'ഈ EMI പലിശയ്ക്ക് പോലും തികയില്ല, അതിനാൽ ലോൺ ഒരിക്കലും അടഞ്ഞുതീരില്ല. EMI, പലിശ നിരക്ക്, മുതൽ എന്നിവ പരിശോധിക്കുക.';

  @override
  String unappliedPrepayment(String amount) {
    return 'മുൻകൂർ അടവുകളിൽ $amount ബാക്കിയുള്ള തുകയേക്കാൾ കൂടുതലായിരുന്നു, അത് ഉപയോഗിച്ചില്ല.';
  }

  @override
  String get closeLoan => 'ലോൺ അവസാനിപ്പിച്ചതായി രേഖപ്പെടുത്തുക';

  @override
  String get reopenLoan => 'ലോൺ വീണ്ടും തുറക്കുക';

  @override
  String get loanClosedNote =>
      'അവസാനിപ്പിച്ച ലോണുകൾ ഓർമ്മപ്പെടുത്തൽ അയയ്ക്കില്ല.';

  @override
  String get emiCalculator => 'EMI കാൽക്കുലേറ്റർ';

  @override
  String get rateFinder => 'പലിശ നിരക്ക് കണ്ടെത്തുക';

  @override
  String get financialTools => 'സാമ്പത്തിക ടൂളുകൾ';

  @override
  String get calcResultEmi => 'പ്രതിമാസ EMI';

  @override
  String get calcTotalPayment => 'ആകെ അടവ്';

  @override
  String calcInterestPercent(String percent) {
    return 'പലിശ മുതലിന്റെ $percent% ആണ്';
  }

  @override
  String get calcFirstEmiSplit => 'ആദ്യ EMI-യുടെ വിഭജനം';

  @override
  String get calcRateResult => 'ഏകദേശ പലിശ നിരക്ക്';

  @override
  String calcRateValue(String rate) {
    return 'വർഷത്തിൽ $rate%';
  }

  @override
  String get calcRateImpossible =>
      'ഈ സംഖ്യകൾ ചേരില്ല: EMI-കളുടെ ആകെ തുക മുതലിനേക്കാൾ കുറവാണ്.';

  @override
  String get calcRateTooHigh =>
      'കണക്കാക്കിയ പലിശ നിരക്ക് വിശ്വസിക്കാൻ കഴിയാത്തത്ര കൂടുതലാണ്. നൽകിയ വിവരങ്ങൾ പരിശോധിക്കുക.';

  @override
  String get calcRateZero =>
      '0% — EMI-കൾ മുതൽ കൃത്യമായി തിരിച്ചടയ്ക്കുന്നു (പലിശയില്ല).';

  @override
  String get useThisRate => 'ഈ നിരക്ക് ഉപയോഗിക്കുക';

  @override
  String get calcEnterValues => 'ഫലം കാണാൻ വിവരങ്ങൾ നൽകുക.';

  @override
  String get emiFrequencyLabel => 'EMI ഇടവേള';

  @override
  String get loanRateCalculated => 'പലിശ നിരക്ക് (കണക്കാക്കിയത്)';

  @override
  String get loanRateFromEmi =>
      'മുതൽ തുക, EMI തുക, EMI-കളുടെ എണ്ണം എന്നിവയിൽ നിന്ന് കണക്കാക്കിയതാണ്, അതിനാൽ നിങ്ങൾ അന്വേഷിച്ച് കണ്ടെത്തേണ്ടതില്ല.';

  @override
  String loanInterestSummary(String interest, String total) {
    return 'ആകെ പലിശ $interest · ആകെ അടയ്ക്കേണ്ടത് $total';
  }

  @override
  String get loanEmisPaid => 'ഇതിനകം അടച്ച EMI-കൾ';

  @override
  String get loanEmisPaidHelp =>
      'ഇതിനകം എത്ര EMI അടച്ചു എന്ന് നൽകുക. അവ ഷെഡ്യൂളിൽ അടച്ചതായി അടയാളപ്പെടുത്തും; അക്കൗണ്ട് ബാലൻസ് മാറില്ല.';

  @override
  String loanEmisPaidInvalid(String max) {
    return '0 മുതൽ $max വരെയുള്ള സംഖ്യ നൽകുക';
  }

  @override
  String get loanFirstEmiDate => 'ആദ്യ EMI തീയതി';

  @override
  String get loanNextEmiDate => 'അടുത്ത EMI തീയതി';

  @override
  String loanNextEmiHelp(String number) {
    return 'EMI #$number-ന്റെ അവസാന തീയതി';
  }

  @override
  String get loanKnowRate => 'പകരം പലിശ നിരക്ക് എനിക്കറിയാം';

  @override
  String get loanUseEmi => 'പകരം EMI തുക ഉപയോഗിക്കുക';

  @override
  String loanEmiCalculated(String amount) {
    return 'കണക്കാക്കിയ EMI: $amount';
  }

  @override
  String get loanPayFromHelp =>
      'ഓപ്ഷണൽ. EMI അടച്ചതായി രേഖപ്പെടുത്തുമ്പോൾ ഡിഫോൾട്ട് അക്കൗണ്ടായി ഉപയോഗിക്കും.';

  @override
  String loanSavedWithPaid(String count) {
    return 'ലോൺ സേവ് ചെയ്തു. $count EMI അടച്ചതായി രേഖപ്പെടുത്തി.';
  }

  @override
  String get borrowLendTitle => 'കടം വാങ്ങലും കൊടുക്കലും';

  @override
  String get debtsEmpty =>
      'ഇവിടെ ഇതുവരെ ഒന്നുമില്ല. ആരിൽ നിന്നെങ്കിലും വാങ്ങിയതോ ആർക്കെങ്കിലും കൊടുത്തതോ ആയ കടം രേഖപ്പെടുത്തുക.';

  @override
  String get newDebt => 'പുതിയ രേഖ';

  @override
  String get editDebt => 'രേഖ എഡിറ്റ് ചെയ്യുക';

  @override
  String get iBorrowed => 'ഞാൻ വാങ്ങി';

  @override
  String get iLent => 'ഞാൻ കൊടുത്തു';

  @override
  String get personName => 'വ്യക്തി';

  @override
  String get personNameHint => 'ആരുമായിട്ടാണ്?';

  @override
  String get personRequired => 'പേര് നൽകുക';

  @override
  String get givenOn => 'തീയതി';

  @override
  String get dueDateOptional => 'അവസാന തീയതി (ഓപ്ഷണൽ)';

  @override
  String get moneyMovedThrough => 'പണം കൈമാറിയ മാർഗം';

  @override
  String get debtReminder => 'അവസാന തീയതിക്ക് മുമ്പ് ഓർമ്മിപ്പിക്കുക';

  @override
  String get debtReminderOffsets => 'എപ്പോൾ ഓർമ്മിപ്പിക്കണം';

  @override
  String get iOwe => 'ഞാൻ കൊടുക്കാനുള്ളത്';

  @override
  String get owedToMe => 'എനിക്ക് കിട്ടാനുള്ളത്';

  @override
  String get overdueAmount => 'കാലാവധി കഴിഞ്ഞത്';

  @override
  String get totalBorrowed => 'ആകെ വാങ്ങിയത്';

  @override
  String get totalLent => 'ആകെ കൊടുത്തത്';

  @override
  String openRecords(String count) {
    return '$count തീർപ്പാകാത്തത്';
  }

  @override
  String outstandingOf(String outstanding, String total) {
    return '$total-ൽ $outstanding ബാക്കി';
  }

  @override
  String get settlements => 'തിരിച്ചടവുകൾ';

  @override
  String get addSettlement => 'തിരിച്ചടവ് രേഖപ്പെടുത്തുക';

  @override
  String get settlementAmount => 'തിരിച്ചടച്ച തുക';

  @override
  String get noSettlements => 'ഇതുവരെ തിരിച്ചടവുകൾ രേഖപ്പെടുത്തിയിട്ടില്ല.';

  @override
  String get settleFull => 'മുഴുവനായി തീർപ്പാക്കുക';

  @override
  String get filterOpen => 'തീർപ്പാകാത്തത്';

  @override
  String get filterSettled => 'തീർപ്പാക്കിയത്';

  @override
  String debtDueOn(String date) {
    return '$date-ന് അടയ്ക്കണം';
  }

  @override
  String get vehiclesTitle => 'വാഹനങ്ങൾ';

  @override
  String get vehiclesEmpty =>
      'ഇതുവരെ വാഹനങ്ങളില്ല. മൈലേജും ഇന്ധനച്ചെലവും ട്രാക്ക് ചെയ്യാൻ ഒന്ന് ചേർക്കുക.';

  @override
  String get addVehicle => 'വാഹനം ചേർക്കുക';

  @override
  String get newVehicle => 'പുതിയ വാഹനം';

  @override
  String get editVehicle => 'വാഹനം എഡിറ്റ് ചെയ്യുക';

  @override
  String get vehicleName => 'വാഹനത്തിന്റെ പേര്';

  @override
  String get vehicleNameHint => 'ഉദാ. സ്വിഫ്റ്റ്, ആക്ടിവ';

  @override
  String get registrationNickname => 'രജിസ്ട്രേഷൻ / വിളിപ്പേര്';

  @override
  String get fuelPrice => 'ഒരു യൂണിറ്റ് ഇന്ധനത്തിന്റെ വില';

  @override
  String get expectedMileage => 'പ്രതീക്ഷിക്കുന്ന മൈലേജ്';

  @override
  String get expectedMileageHelp =>
      'ഇന്ധനം നിറച്ചത് രേഖപ്പെടുത്തുന്നതുവരെ ഇത് ഉപയോഗിക്കും; അതിനുശേഷം അളന്ന ശരാശരി ഉപയോഗിക്കും.';

  @override
  String get unitKmPerL => 'കി.മീ/ലി';

  @override
  String get unitKmPerKwh => 'കി.മീ/kWh';

  @override
  String get unitKmPerKg => 'കി.മീ/കി.ഗ്രാം';

  @override
  String get unitLitre => 'ലി';

  @override
  String get unitKwh => 'kWh';

  @override
  String get unitKg => 'കി.ഗ്രാം';

  @override
  String get unitKm => 'കി.മീ';

  @override
  String get avgMileage => 'ശരാശരി മൈലേജ്';

  @override
  String get costPerKm => 'ഒരു കിലോമീറ്ററിന്റെ ചെലവ്';

  @override
  String get fuelThisMonth => 'ഈ മാസത്തെ ഇന്ധനച്ചെലവ്';

  @override
  String get fuelMonthlyAverage => 'പ്രതിമാസ ശരാശരി';

  @override
  String get fuelYearlyEstimate => 'വാർഷിക ഏകദേശം';

  @override
  String get fuelCost6m => 'ഇന്ധനച്ചെലവ്, കഴിഞ്ഞ 6 മാസം';

  @override
  String get totalDistance => 'രേഖപ്പെടുത്തിയ ദൂരം';

  @override
  String get fuelLogs => 'ഇന്ധന ചരിത്രം';

  @override
  String get fuelLogsEmpty => 'ഇതുവരെ ഇന്ധനം നിറച്ചത് രേഖപ്പെടുത്തിയിട്ടില്ല.';

  @override
  String get addFuel => 'ഇന്ധനം രേഖപ്പെടുത്തുക';

  @override
  String get editFuel => 'ഇന്ധനം നിറച്ചത് എഡിറ്റ് ചെയ്യുക';

  @override
  String get odometer => 'ഓഡോമീറ്റർ (ഓപ്ഷണൽ)';

  @override
  String get distanceTravelled => 'അവസാനം നിറച്ചതിന് ശേഷമുള്ള ദൂരം';

  @override
  String get fuelQuantity => 'നിറച്ച ഇന്ധനം';

  @override
  String get pricePerUnit => 'യൂണിറ്റ് വില';

  @override
  String get totalCost => 'ആകെ ചെലവ്';

  @override
  String get recordAsExpense => 'ചെലവായി രേഖപ്പെടുത്തേണ്ട അക്കൗണ്ട്';

  @override
  String get dontRecord => 'ചെലവായി രേഖപ്പെടുത്തരുത്';

  @override
  String get mileageCalculator => 'മൈലേജ് കാൽക്കുലേറ്റർ';

  @override
  String get mileageResult => 'മൈലേജ്';

  @override
  String get tripCost => 'ഈ യാത്രയുടെ ഇന്ധനച്ചെലവ്';

  @override
  String get tripDistance => 'യാത്രാ ദൂരം';

  @override
  String get calcCostPerKm => 'ഒരു കിലോമീറ്ററിന്റെ ചെലവ്';

  @override
  String get noMileageYet => '—';

  @override
  String get vehicleFuelExpenseNote =>
      'ചെലവായി രേഖപ്പെടുത്തിയ ഇന്ധന ഇടപാടുകൾ ഇടപാടുകളിലും ബജറ്റുകളിലും കാണിക്കും.';

  @override
  String get fuelTypeLabel => 'ഇന്ധന തരം';

  @override
  String get budgetsTitle => 'ബജറ്റുകൾ';

  @override
  String get budgetsEmpty =>
      'ഇതുവരെ ബജറ്റുകളില്ല. മൊത്തത്തിലോ ഓരോ വിഭാഗത്തിനോ പ്രതിമാസ പരിധി നിശ്ചയിക്കുക.';

  @override
  String get addBudget => 'ബജറ്റ് ചേർക്കുക';

  @override
  String get editBudget => 'ബജറ്റ് എഡിറ്റ് ചെയ്യുക';

  @override
  String get budgetFor => 'ബജറ്റ് ഇതിന്';

  @override
  String get budgetLimit => 'പ്രതിമാസ പരിധി';

  @override
  String get budgetThresholds => 'ഇവിടെ എത്തുമ്പോൾ അറിയിക്കുക';

  @override
  String get budgetThresholdsHelp =>
      'പരിധിയുടെ ശതമാനം, കോമ ഇട്ട് വേർതിരിക്കുക (ഉദാ. 75, 90, 100)';

  @override
  String get budgetThresholdsInvalid => '1 നും 200 നും ഇടയിലുള്ള ശതമാനം നൽകുക';

  @override
  String budgetSpentOf(String spent, String limit) {
    return '$limit-ൽ $spent';
  }

  @override
  String budgetRemaining(String amount) {
    return '$amount ബാക്കി';
  }

  @override
  String budgetOver(String amount) {
    return '$amount കൂടുതൽ';
  }

  @override
  String budgetReached(String percent) {
    return '$percent% എത്തി';
  }

  @override
  String get budgetAlertsSetting =>
      'ബജറ്റ് പരിധി കടക്കുമ്പോൾ മുന്നറിയിപ്പ് നൽകുക';

  @override
  String get recurringTitle => 'ആവർത്തന ഇടപാടുകൾ';

  @override
  String get recurringEmpty =>
      'ആവർത്തന എൻട്രികളില്ല. ശമ്പളം, വാടക, സബ്സ്ക്രിപ്ഷനുകൾ, മറ്റ് സ്ഥിരം അടവുകൾ എന്നിവ ചേർക്കുക; അവ അതത് തീയതികളിൽ സ്വയം രേഖപ്പെടുത്തും.';

  @override
  String get addRecurring => 'ആവർത്തന ഇടപാട് ചേർക്കുക';

  @override
  String get editRecurring => 'ആവർത്തന ഇടപാട് എഡിറ്റ് ചെയ്യുക';

  @override
  String get recurringTitleLabel => 'തലക്കെട്ട്';

  @override
  String get recurringTitleHint => 'ഉദാ. വാടക, നെറ്റ്ഫ്ലിക്സ്, ശമ്പളം';

  @override
  String get startsOn => 'തുടങ്ങുന്ന തീയതി';

  @override
  String recurringNext(String date) {
    return 'അടുത്തത്: $date';
  }

  @override
  String get recurringPaused => 'നിർത്തിവെച്ചു';

  @override
  String get recurringActive => 'സജീവം';

  @override
  String get recurringAutoNote =>
      'ഓരോ തീയതിയിലും (ആപ്പ് തുറക്കുമ്പോൾ) എൻട്രികൾ ഉണ്ടാക്കും, ഒരു തീയതിക്ക് ഒരിക്കൽ മാത്രം. ലോൺ EMI-കൾ ലോണുകളിലാണ് ട്രാക്ക് ചെയ്യുന്നത്.';

  @override
  String recurringGeneratedCount(String count) {
    return '$count ആവർത്തന എൻട്രികൾ രേഖപ്പെടുത്തി';
  }

  @override
  String get reportsTitle => 'റിപ്പോർട്ടുകൾ';

  @override
  String get reportSummary => 'സംഗ്രഹം';

  @override
  String get reportCategories => 'വിഭാഗങ്ങൾ';

  @override
  String get reportAccounts => 'അക്കൗണ്ടുകൾ';

  @override
  String get reportCards => 'കാർഡുകൾ';

  @override
  String get reportLoans => 'ലോണുകൾ';

  @override
  String get reportDebts => 'കടം വാങ്ങലും കൊടുക്കലും';

  @override
  String get reportFuel => 'ഇന്ധനം';

  @override
  String get reportPeriod => 'കാലയളവ്';

  @override
  String get reportAllAccounts => 'എല്ലാ അക്കൗണ്ടുകളും';

  @override
  String get reportAllCards => 'എല്ലാ കാർഡുകളും';

  @override
  String get reportAllCategories => 'എല്ലാ വിഭാഗങ്ങളും';

  @override
  String get reportMonthly => 'മാസം തിരിച്ച്';

  @override
  String get reportPeriodSpending => 'കാലയളവിലെ ചെലവ്';

  @override
  String get reportPeriodIncome => 'കാലയളവിലെ വരുമാനം';

  @override
  String get reportTransactions => 'ഇടപാടുകൾ';

  @override
  String get reportNoVehicles => 'റിപ്പോർട്ട് ചെയ്യാൻ വാഹനങ്ങളില്ല.';

  @override
  String get reportNoLoans => 'റിപ്പോർട്ട് ചെയ്യാൻ ലോണുകളില്ല.';

  @override
  String get reportNoCards => 'റിപ്പോർട്ട് ചെയ്യാൻ കാർഡുകളില്ല.';

  @override
  String get reportNoAccounts => 'റിപ്പോർട്ട് ചെയ്യാൻ അക്കൗണ്ടുകളില്ല.';

  @override
  String get reportNoDebts => 'കടം വാങ്ങൽ/കൊടുക്കൽ രേഖകളില്ല.';

  @override
  String get reportByPerson => 'വ്യക്തി തിരിച്ച്';

  @override
  String get reportFuelInPeriod => 'കാലയളവിലെ ഇന്ധനച്ചെലവ്';

  @override
  String get searchTitle => 'തിരയുക';

  @override
  String get searchHint =>
      'ഇടപാടുകൾ, അക്കൗണ്ടുകൾ, ലോണുകൾ, ആളുകൾ എന്നിവ തിരയുക…';

  @override
  String get searchScopeNote => 'കഴിഞ്ഞ 12 മാസത്തെ ഇടപാടുകളിലാണ് തിരയുന്നത്.';

  @override
  String searchNoResults(String query) {
    return '“$query”-ന് ഫലങ്ങളില്ല';
  }

  @override
  String get searchStart => 'തിരയാൻ കുറഞ്ഞത് 2 അക്ഷരങ്ങൾ ടൈപ്പ് ചെയ്യുക.';

  @override
  String get searchGroupTransactions => 'ഇടപാടുകൾ';

  @override
  String get searchGroupAccounts => 'അക്കൗണ്ടുകൾ';

  @override
  String get searchGroupCards => 'ക്രെഡിറ്റ് കാർഡുകൾ';

  @override
  String get searchGroupLoans => 'ലോണുകൾ';

  @override
  String get searchGroupDebts => 'കടം വാങ്ങലും കൊടുക്കലും';

  @override
  String get searchGroupReminders => 'ഓർമ്മപ്പെടുത്തലുകൾ';

  @override
  String get searchGroupVehicles => 'വാഹനങ്ങൾ';

  @override
  String get settingsTitle => 'ക്രമീകരണങ്ങൾ';

  @override
  String get settingsAppearance => 'രൂപം';

  @override
  String get themeSystem => 'സിസ്റ്റം';

  @override
  String get themeLight => 'ലൈറ്റ്';

  @override
  String get themeDark => 'ഡാർക്ക്';

  @override
  String get settingsCurrency => 'കറൻസി';

  @override
  String get settingsLanguage => 'ഭാഷ';

  @override
  String get languageSystem => 'ഫോണിന്റെ ഭാഷ';

  @override
  String get settingsNotifications => 'അറിയിപ്പുകൾ';

  @override
  String get notificationsStatusOn => 'അനുവദിച്ചിരിക്കുന്നു';

  @override
  String get notificationsStatusOff => 'അനുവദിച്ചിട്ടില്ല';

  @override
  String get notificationsResync =>
      'എല്ലാ ഓർമ്മപ്പെടുത്തലുകളും വീണ്ടും സെറ്റ് ചെയ്യുക';

  @override
  String get notificationsResynced =>
      'ഓർമ്മപ്പെടുത്തലുകൾ വീണ്ടും സെറ്റ് ചെയ്തു';

  @override
  String get settingsData => 'ഡാറ്റയും സിങ്കും';

  @override
  String get settingsAccount => 'അക്കൗണ്ട്';

  @override
  String signedInAs(String email) {
    return '$email ആയി സൈൻ ഇൻ ചെയ്തിരിക്കുന്നു';
  }

  @override
  String get guestAccount => 'അതിഥി (ഈ ഫോണിൽ മാത്രം)';

  @override
  String get guestWarning =>
      'നിങ്ങൾ അതിഥി അക്കൗണ്ടാണ് ഉപയോഗിക്കുന്നത്. നിങ്ങളുടെ ഡാറ്റ ബാക്കപ്പ് ചെയ്യാനും പുതിയ ഫോണിൽ പുനഃസ്ഥാപിക്കാനും Google ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String get linkGoogle => 'Google ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യുക';

  @override
  String get googleAccountExistsTitle => 'നിലവിലുള്ള അക്കൗണ്ട് ഉപയോഗിക്കണോ?';

  @override
  String get googleAccountExistsBody =>
      'ഈ Google അക്കൗണ്ടിൽ ഇതിനകം ഡാറ്റയുണ്ട്. അതിലേക്ക് മാറിയാൽ ഈ ഫോണിൽ അതിഥിയായി നിങ്ങൾ ഉണ്ടാക്കിയ ഡാറ്റ മറയും. അവ രണ്ടും ഒന്നാക്കാൻ കഴിയില്ല.';

  @override
  String get switchAccount => 'അക്കൗണ്ട് മാറുക';

  @override
  String get signOut => 'സൈൻ ഔട്ട്';

  @override
  String get signOutGuestWarning =>
      'നിങ്ങൾ അതിഥിയാണ്: ആദ്യം Google ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്തില്ലെങ്കിൽ, സൈൻ ഔട്ട് ചെയ്താൽ ഈ ഡാറ്റ എന്നെന്നേക്കുമായി നഷ്ടപ്പെടും.';

  @override
  String get signOutConfirm => 'സൈൻ ഔട്ട് ചെയ്യണോ?';

  @override
  String get backupTitle => 'ബാക്കപ്പും പുനഃസ്ഥാപിക്കലും';

  @override
  String get backupNow => 'ഇപ്പോൾ ബാക്കപ്പ് ചെയ്യുക';

  @override
  String get backupAuto => 'ആഴ്ചതോറും സ്വയം ബാക്കപ്പ്';

  @override
  String backupLast(String time) {
    return 'അവസാന ബാക്കപ്പ്: $time';
  }

  @override
  String get backupNever => 'ഇതുവരെ ബാക്കപ്പ് ഇല്ല';

  @override
  String backupDone(String count) {
    return 'ബാക്കപ്പ് പൂർത്തിയായി ($count രേഖകൾ)';
  }

  @override
  String get backupList => 'ബാക്കപ്പിൽ നിന്ന് പുനഃസ്ഥാപിക്കുക';

  @override
  String get backupEmpty => 'ഈ അക്കൗണ്ടിന് ബാക്കപ്പുകളൊന്നും കണ്ടെത്തിയില്ല.';

  @override
  String get restoreConfirmTitle => 'ഈ ബാക്കപ്പ് പുനഃസ്ഥാപിക്കണോ?';

  @override
  String get restoreConfirmBody =>
      'ബാക്കപ്പിലെ രേഖകൾ ഒരേപോലെയുള്ള രേഖകളെ മാറ്റിയെഴുതും. ബാക്കപ്പിന് ശേഷം നിങ്ങൾ ചേർത്ത രേഖകൾ നിലനിൽക്കും. ഓർമ്മപ്പെടുത്തലുകൾ വീണ്ടും സെറ്റ് ചെയ്യും.';

  @override
  String restoreDone(String count) {
    return '$count രേഖകൾ പുനഃസ്ഥാപിച്ചു';
  }

  @override
  String restoreSkipped(String count) {
    return '$count തെറ്റായ രേഖകൾ ഒഴിവാക്കി';
  }

  @override
  String get backupNeedsAccount =>
      'ക്ലൗഡ് ബാക്കപ്പ് ഉപയോഗിക്കാൻ Google ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String get backupInProgress => 'പ്രവർത്തിക്കുന്നു…';

  @override
  String get importTitle => 'Gmail-ൽ നിന്ന് ഇമ്പോർട്ട് ചെയ്യുക';

  @override
  String get importBody =>
      'ബാങ്ക്, കാർഡ് ഇമെയിലുകൾ സ്കാൻ ചെയ്ത് (വായിക്കാൻ മാത്രം) കണ്ടെത്തുന്ന ഇടപാടുകൾ ചേർക്കുന്നു. ഒരേ ഇടപാടുകൾ ഒന്നായി ചേർക്കും.';

  @override
  String importDone(String count) {
    return '$count ഇടപാടുകൾ ഇമ്പോർട്ട് ചെയ്തു';
  }

  @override
  String get privacyNote =>
      'നിങ്ങളുടെ ഡാറ്റ നിങ്ങളുടെ സ്വകാര്യ Firebase സ്ഥലത്താണ് സൂക്ഷിക്കുന്നത്. നിങ്ങൾക്ക് മാത്രമേ അത് വായിക്കാൻ കഴിയൂ. പാസ്‌വേഡ്, പിൻ, CVV, മുഴുവൻ കാർഡ് നമ്പർ എന്നിവ ആപ്പ് ഒരിക്കലും സൂക്ഷിക്കില്ല.';

  @override
  String aboutVersion(String version) {
    return 'പതിപ്പ് $version';
  }

  @override
  String get moreTitle => 'കൂടുതൽ';

  @override
  String get moreMoney => 'പണം';

  @override
  String get moreTools => 'ടൂളുകൾ';

  @override
  String get moreApp => 'ആപ്പ്';

  @override
  String get welcomeTitle => 'നിങ്ങളുടെ പണം, ഭംഗിയായി ക്രമീകരിച്ച്';

  @override
  String get welcomeBody =>
      'ചെലവുകൾ, അക്കൗണ്ടുകൾ, കാർഡുകൾ, ലോണുകൾ, ഓർമ്മപ്പെടുത്തലുകൾ — എല്ലാം ശാന്തവും സ്വകാര്യവുമായ ഒരിടത്ത്.';

  @override
  String get welcomePrivacy =>
      'നിങ്ങളുടെ ഡാറ്റ നിങ്ങളുടെ അക്കൗണ്ടിന് മാത്രം സ്വകാര്യമാണ്. ബാങ്ക് പാസ്‌വേഡ്, പിൻ, കാർഡ് നമ്പർ എന്നിവ ഞങ്ങൾ ഒരിക്കലും ചോദിക്കില്ല.';

  @override
  String get continueWithGoogle => 'Google ഉപയോഗിച്ച് തുടരുക';

  @override
  String get continueAsGuest => 'അക്കൗണ്ട് ഇല്ലാതെ തുടരുക';

  @override
  String get guestNote =>
      'ഉടൻ തുടങ്ങാം. ഡാറ്റ ബാക്കപ്പ് ചെയ്ത് പുതിയ ഫോണിൽ ഉപയോഗിക്കാൻ പിന്നീട് ക്രമീകരണങ്ങളിൽ Google ബന്ധിപ്പിക്കുക.';

  @override
  String get signInFailed =>
      'സൈൻ ഇൻ പൂർത്തിയായില്ല. ദയവായി വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get firstLaunchOffline =>
      'നിങ്ങൾക്ക് ഇന്റർനെറ്റ് ഇല്ല. നിങ്ങളുടെ സ്വകാര്യ ഇടം സജ്ജമാക്കാൻ ഒരിക്കൽ ഇന്റർനെറ്റിൽ കണക്റ്റ് ചെയ്യുക — അതിനുശേഷം ആപ്പ് ഇന്റർനെറ്റ് ഇല്ലാതെയും പ്രവർത്തിക്കും.';

  @override
  String get signOutBody =>
      'നിങ്ങളുടെ ഡാറ്റ നിങ്ങളുടെ അക്കൗണ്ടിൽ തന്നെയുണ്ടാകും. അത് കാണാൻ അതേ Google അക്കൗണ്ടിൽ വീണ്ടും സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String get welcomeFeatureTrack => 'ഓരോ രൂപയും ഒരിടത്ത്';

  @override
  String get welcomeFeatureDues => 'ഒരു അവസാന തീയതിയും മറക്കരുത്';

  @override
  String get welcomeFeatureLoans => 'ലോണുകൾ വ്യക്തമായി';

  @override
  String get welcomeFeaturePrivate => 'സ്വകാര്യവും ഇന്റർനെറ്റ് ഇല്ലാതെയും';

  @override
  String get googleNote =>
      'ശുപാർശ ചെയ്യുന്നത്: നിങ്ങളുടെ ഡാറ്റ ബാക്കപ്പ് ചെയ്യപ്പെടും, പുതിയ ഫോണിലും ലഭിക്കും.';

  @override
  String get signingIn => 'സൈൻ ഇൻ ചെയ്യുന്നു…';

  @override
  String get signInCancelled => 'സൈൻ ഇൻ റദ്ദാക്കി.';

  @override
  String get guestUnavailable =>
      'ഈ ആപ്പിൽ അതിഥി പ്രവേശനം ഇപ്പോൾ ഓഫാണ്. ദയവായി Google ഉപയോഗിച്ച് തുടരുക.';

  @override
  String get guestUnavailableDev =>
      'ഡെവലപ്പർ: Firebase Console → Authentication → Sign-in method-ൽ Anonymous സൈൻ ഇൻ ഓൺ ചെയ്യുക.';

  @override
  String get backupConnectTitle => 'നിങ്ങളുടെ ഡാറ്റ ബാക്കപ്പ് ചെയ്യുക';

  @override
  String get backupConnectBody =>
      'സ്വയം ബാക്കപ്പ് ചെയ്യാനും പുതിയ ഫോണിൽ പുനഃസ്ഥാപിക്കാനും നിങ്ങളുടെ Google അക്കൗണ്ട് ബന്ധിപ്പിക്കുക. ഇല്ലെങ്കിൽ നിങ്ങളുടെ ഡാറ്റ ഈ ഫോണിൽ മാത്രമേ ഉണ്ടാകൂ.';

  @override
  String get backupConnect => 'ബാക്കപ്പ് ബന്ധിപ്പിക്കുക';

  @override
  String get backupConnectedTitle => 'ബാക്കപ്പ് ബന്ധിപ്പിച്ചു';

  @override
  String backupConnectedAs(String email) {
    return '$email-ലേക്ക് ബാക്കപ്പ് ചെയ്യുന്നു';
  }

  @override
  String get backupConnectUnavailable =>
      'ക്ലൗഡ് ബാക്കപ്പിന് Google സൈൻ ഇൻ ആവശ്യമാണ്, ഈ ഉപകരണത്തിൽ അത് ലഭ്യമല്ല.';

  @override
  String get adPrivacyOptions => 'പരസ്യ സ്വകാര്യതാ ക്രമീകരണങ്ങൾ';

  @override
  String get adPrivacyOptionsHelp =>
      'വ്യക്തിഗതമാക്കിയ പരസ്യങ്ങളെക്കുറിച്ചുള്ള നിങ്ങളുടെ തിരഞ്ഞെടുപ്പ് പരിശോധിക്കുകയോ മാറ്റുകയോ ചെയ്യുക.';

  @override
  String get categoriesTitle => 'വിഭാഗങ്ങൾ';

  @override
  String get categoriesManage => 'വിഭാഗങ്ങൾ നിയന്ത്രിക്കുക';

  @override
  String get categoryBuiltIn => 'ആപ്പിലുള്ളവ';

  @override
  String get categoryYours => 'നിങ്ങളുടെ വിഭാഗങ്ങൾ';

  @override
  String get categoryYoursEmpty =>
      'നിങ്ങൾ ഇതുവരെ വിഭാഗങ്ങളൊന്നും ചേർത്തിട്ടില്ല. ഒന്ന് ഉണ്ടാക്കാൻ + അമർത്തുക.';

  @override
  String get categoryAdd => 'പുതിയ വിഭാഗം';

  @override
  String get categoryEdit => 'വിഭാഗം എഡിറ്റ് ചെയ്യുക';

  @override
  String get categoryNameLabel => 'വിഭാഗത്തിന്റെ പേര്';

  @override
  String get categoryNameHint => 'ഉദാ. വളർത്തുമൃഗങ്ങൾ, കാപ്പി, ഫ്രീലാൻസ്';

  @override
  String get categoryTypeLabel => 'ഉപയോഗം';

  @override
  String get categoryIconLabel => 'ഐക്കൺ';

  @override
  String get categoryColorLabel => 'നിറം';

  @override
  String get categoryNameEmpty => 'പേര് നൽകുക';

  @override
  String categoryNameTooLong(String max) {
    return '$max അക്ഷരങ്ങളിൽ കുറവായിരിക്കണം';
  }

  @override
  String get categoryNameDuplicate => 'ഈ പേരിൽ ഇതിനകം ഒരു വിഭാഗമുണ്ട്';

  @override
  String get categoryTypeLocked => 'ഉണ്ടാക്കിയ ശേഷം തരം മാറ്റാൻ കഴിയില്ല.';

  @override
  String get categoryArchived => 'ആർക്കൈവ് ചെയ്തത്';

  @override
  String get categoryArchive => 'ആർക്കൈവ് ചെയ്യുക';

  @override
  String get categoryRestore => 'തിരികെ കൊണ്ടുവരിക';

  @override
  String get categoryArchivedNote =>
      'ആർക്കൈവ് ചെയ്ത വിഭാഗങ്ങൾ ഇടപാട് ചേർക്കുമ്പോൾ മറഞ്ഞിരിക്കും, എന്നാൽ നിലവിലുള്ള ഇടപാടുകളിൽ അവ നിലനിൽക്കും.';

  @override
  String get categoryInUse =>
      'ഈ വിഭാഗം ഇടപാടുകളിലോ ബജറ്റിലോ ആവർത്തന എൻട്രിയിലോ ഉപയോഗിക്കുന്നുണ്ട്, അതിനാൽ ഇല്ലാതാക്കാൻ കഴിയില്ല. പകരം ആർക്കൈവ് ചെയ്യുക.';

  @override
  String get categoryDeleted => 'വിഭാഗം ഇല്ലാതാക്കി';

  @override
  String get categoryNew => 'പുതിയത്';

  @override
  String get categoryRequired => 'ഒരു വിഭാഗം തിരഞ്ഞെടുക്കുക';

  @override
  String get categoryTapToClear =>
      'തിരഞ്ഞെടുത്ത വിഭാഗം മായ്ക്കാൻ അതിൽ വീണ്ടും അമർത്തുക';

  @override
  String get subcategoriesLabel => 'ഉപവിഭാഗങ്ങൾ';

  @override
  String get subcategoriesEmpty =>
      'ഇതുവരെ ഉപവിഭാഗങ്ങളില്ല. ഈ വിഭാഗത്തെ കൂടുതൽ വേർതിരിക്കാൻ ഒന്ന് ചേർക്കുക.';

  @override
  String get subcategoryAdd => 'ഉപവിഭാഗം ചേർക്കുക';

  @override
  String get subcategoryRename => 'ഉപവിഭാഗത്തിന്റെ പേര് മാറ്റുക';

  @override
  String get subcategoryNameLabel => 'ഉപവിഭാഗത്തിന്റെ പേര്';

  @override
  String get subcategoryNameDuplicate =>
      'ഈ പേരിൽ ഒരു ഉപവിഭാഗം ഈ വിഭാഗത്തിൽ ഇതിനകം ഉണ്ട്';

  @override
  String get subcategoryInUse =>
      'ഈ ഉപവിഭാഗം ഇടപാടുകളിലോ ആവർത്തന എൻട്രിയിലോ ഉപയോഗത്തിലുള്ളതിനാൽ ഇല്ലാതാക്കാൻ കഴിയില്ല. പകരം പേര് മാറ്റുക.';

  @override
  String get subcategoryDeleted => 'ഉപവിഭാഗം ഇല്ലാതാക്കി';

  @override
  String get categoryBuiltInLocked =>
      'ബിൽറ്റ്-ഇൻ വിഭാഗങ്ങൾ എഡിറ്റ് ചെയ്യാനോ ഇല്ലാതാക്കാനോ കഴിയില്ല. പുതിയത് ഉപയോഗിച്ച് സ്വന്തമായി ഒന്ന് സൃഷ്ടിക്കുക.';

  @override
  String get categoryOptionsHint =>
      'എഡിറ്റ് ചെയ്യാനോ ഇല്ലാതാക്കാനോ നിങ്ങളുടെ വിഭാഗത്തിൽ അമർത്തിപ്പിടിക്കുക';

  @override
  String get rename => 'പേര് മാറ്റുക';

  @override
  String get typeTapToClear => 'ചെലവിലേക്ക് മടങ്ങാൻ വീണ്ടും അമർത്തുക';

  @override
  String get paymentRequired => 'എങ്ങനെയാണ് അടച്ചതെന്ന് തിരഞ്ഞെടുക്കുക';

  @override
  String get receivedRequired => 'പണം എവിടെയാണ് പോയതെന്ന് തിരഞ്ഞെടുക്കുക';

  @override
  String get paymentCash => 'പണം / ട്രാക്ക് ചെയ്യാത്തത്';

  @override
  String get paymentCashHint => 'ഒരു ബാലൻസും മാറില്ല';

  @override
  String get paymentNoneYet =>
      'ഇതുവരെ അക്കൗണ്ടുകളോ കാർഡുകളോ ഇല്ല. ബാലൻസ് സ്വയം പുതുക്കുന്നത് കാണാൻ ഒന്ന് ചേർക്കുക, അല്ലെങ്കിൽ ട്രാക്ക് ചെയ്യാത്ത പണവുമായി തുടരുക.';

  @override
  String get paymentTapToClear => 'മായ്ക്കാൻ വീണ്ടും അമർത്തുക';

  @override
  String get paymentPaidFrom => 'അടച്ചത്';

  @override
  String get paymentPayingAccount => 'ബിൽ അടയ്ക്കുന്ന അക്കൗണ്ട്';

  @override
  String get paymentDestination => 'ഈ അക്കൗണ്ടിലേക്ക് ചേർക്കുക';

  @override
  String get addExpenseFromAccount => 'ഇടപാട് ചേർക്കുക';

  @override
  String get adLabel => 'പരസ്യം';

  @override
  String get notificationChannelName => 'ഓർമ്മപ്പെടുത്തലുകൾ';

  @override
  String get notificationChannelDescription =>
      'ബിൽ, EMI, കാർഡ്, വ്യക്തിഗത ഓർമ്മപ്പെടുത്തലുകൾ';

  @override
  String get settingsAds => 'പരസ്യങ്ങൾ';

  @override
  String get adFreeTitle => '24 മണിക്കൂർ പരസ്യങ്ങളില്ലാതെ';

  @override
  String get adFreeShort => 'വീഡിയോ കാണൂ, 24 മണിക്കൂർ പരസ്യങ്ങളില്ല';

  @override
  String get adFreeWatch => 'വീഡിയോ കാണുക';

  @override
  String get adFreeHelp =>
      'ഒരു ചെറിയ വീഡിയോ കാണൂ, അടുത്ത 24 മണിക്കൂർ Kept-ൽ പരസ്യങ്ങൾ കാണിക്കില്ല.';

  @override
  String adFreeActive(String time) {
    return '$time വരെ പരസ്യങ്ങൾ ഓഫാണ്';
  }

  @override
  String get adFreeLoading => 'വീഡിയോ തയ്യാറാക്കുന്നു…';

  @override
  String get adFreeUnavailable =>
      'ഇപ്പോൾ വീഡിയോ ലഭ്യമല്ല. ദയവായി അൽപ്പം കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get adFreeThanks => 'നന്ദി! അടുത്ത 24 മണിക്കൂർ പരസ്യങ്ങളില്ല.';

  @override
  String get adFreeNotCompleted =>
      'പരസ്യങ്ങൾ ഓഫാക്കാൻ വീഡിയോ അവസാനം വരെ കാണുക.';

  @override
  String get paymentTypeAccount => 'ബാങ്ക് അക്കൗണ്ട്';

  @override
  String get paymentTypeCash => 'പണം';

  @override
  String get txTypeRepayBorrow => 'കടം തിരികെ നൽകൽ';

  @override
  String get repayWhich => 'ഏത് കടം?';

  @override
  String repayLeft(String amount) {
    return '$amount ബാക്കി';
  }

  @override
  String get moreTypes => 'കൂടുതൽ';

  @override
  String get moreDetails => 'കൂടുതൽ വിവരങ്ങൾ';

  @override
  String get moreCategories => 'കൂടുതൽ';

  @override
  String get debtPlanTitle => 'കടരഹിത പ്ലാൻ';

  @override
  String get debtPlanEmpty =>
      'അടച്ചുതീർക്കാൻ ലോണോ കാർഡ് ബാക്കിയോ കടമോ ഇല്ല. നിങ്ങൾക്ക് കടമൊന്നുമില്ല!';

  @override
  String get debtPlanDebtFreeBy => 'കടരഹിതമാകുന്നത്';

  @override
  String debtPlanIn(String duration) {
    return '$duration കൊണ്ട്';
  }

  @override
  String debtPlanDurationMonths(String months) {
    return '$months മാസം';
  }

  @override
  String debtPlanDurationYears(String years, String months) {
    return '$years വർഷം $months മാസം';
  }

  @override
  String get debtPlanTotalOwed => 'ആകെ കടം';

  @override
  String get debtPlanInterestAhead => 'ഇനി അടയ്ക്കേണ്ട പലിശ';

  @override
  String debtPlanSavings(String amount, String duration) {
    return 'മിനിമം മാത്രം അടയ്ക്കുന്നതിനേക്കാൾ $amount ലാഭവും $duration നേരത്തെയും';
  }

  @override
  String debtPlanSavingsInterestOnly(String amount) {
    return 'മിനിമം മാത്രം അടയ്ക്കുന്നതിനേക്കാൾ $amount ലാഭം';
  }

  @override
  String get debtPlanNeverClears =>
      'ഈ തുക കൊണ്ട് ചില കടങ്ങൾ ഒരിക്കലും തീരില്ല. അവ തീർക്കാൻ മാസം തോറും കൂടുതൽ അടയ്ക്കുക.';

  @override
  String get debtPlanChartTitle => 'കുറയുന്ന നിങ്ങളുടെ കടം';

  @override
  String debtPlanChartSemantics(String amount, String date) {
    return 'ആകെ കടം $amount ൽ നിന്ന് $date ആകുമ്പോഴേക്കും പൂജ്യമാകും';
  }

  @override
  String get debtPlanMonthlyTitle => 'ഓരോ മാസവും അടയ്ക്കുന്നത്';

  @override
  String get debtPlanExtraLabel => 'മാസം തോറും അധികം';

  @override
  String get debtPlanMinimums => 'മിനിമം അടവുകൾ';

  @override
  String get debtPlanExtra => 'അധികം';

  @override
  String get debtPlanTotalMonthly => 'മാസം തോറും ആകെ';

  @override
  String get debtPlanCommitNote =>
      'ഒരു കടം തീർന്നാലും ഈ തുക അടയ്ക്കുന്നത് തുടരുക. ഒഴിവാകുന്ന പണം അടുത്ത കടം തീർക്കും.';

  @override
  String get debtPlanWhatIfTitle => 'കൂടുതൽ അടച്ചാൽ എന്താകും?';

  @override
  String debtPlanWhatIfRow(String amount) {
    return 'മാസം +$amount';
  }

  @override
  String debtPlanWhatIfDetail(String date, String amount) {
    return '$date ആകുമ്പോഴേക്കും തീരും, $amount ലാഭം';
  }

  @override
  String get debtPlanWhatIfStillOpen => 'ചില കടങ്ങൾ അപ്പോഴും തീരില്ല';

  @override
  String get debtPlanStrategyTitle => 'ആദ്യം ഏത് കടം?';

  @override
  String get debtPlanAvalanche => 'കൂടുതൽ പലിശയുള്ളത് ആദ്യം';

  @override
  String get debtPlanAvalancheHelp => 'മൊത്തത്തിൽ ഏറ്റവും കുറഞ്ഞ ചെലവ്.';

  @override
  String get debtPlanSnowball => 'ചെറിയ ബാക്കിയുള്ളത് ആദ്യം';

  @override
  String get debtPlanSnowballHelp =>
      'കടങ്ങൾ വേഗം അവസാനിക്കും, പുരോഗതി നേരത്തെ കാണാം.';

  @override
  String debtPlanStrategyResult(String date, String amount) {
    return '$date ആകുമ്പോഴേക്കും തീരും · പലിശ $amount';
  }

  @override
  String get debtPlanCheapest => 'കുറഞ്ഞ ചെലവ്';

  @override
  String debtPlanThisMonthTitle(String month) {
    return '$month ൽ അടയ്ക്കേണ്ടത്';
  }

  @override
  String get debtPlanFocus => 'അധിക തുക ഇവിടെ അടയ്ക്കുക';

  @override
  String get debtPlanRoadmapTitle => 'നിങ്ങളുടെ റോഡ്മാപ്പ്';

  @override
  String debtPlanStepCleared(String date) {
    return '$date ആകുമ്പോഴേക്കും തീരും';
  }

  @override
  String get debtPlanStepOpen => 'ഈ തുക കൊണ്ട് തീരില്ല';

  @override
  String debtPlanRate(String rate) {
    return 'വർഷം $rate%';
  }

  @override
  String debtPlanRateEstimated(String rate) {
    return 'വർഷം $rate% (ഏകദേശം)';
  }

  @override
  String get debtPlanNoInterest => 'പലിശയില്ല';

  @override
  String get debtPlanSetRate => 'പലിശ നിരക്ക് നൽകുക';

  @override
  String debtPlanSetRateTitle(String name) {
    return '$name ന്റെ പലിശ നിരക്ക്';
  }

  @override
  String debtPlanEstimatedWarning(String rate) {
    return 'ചില കാർഡുകൾക്ക് ഏകദേശം $rate% പലിശ നിരക്കാണ് കണക്കാക്കിയത്. കൃത്യമായ പ്ലാനിന് സ്റ്റേറ്റ്മെന്റിലെ യഥാർത്ഥ നിരക്ക് നൽകുക.';
  }

  @override
  String debtPlanLowPayment(String names) {
    return '$names: മിനിമം അടവ് പലിശയ്ക്ക് പോലും തികയില്ല, കൂടുതൽ അടച്ചില്ലെങ്കിൽ ബാക്കി വർധിക്കും.';
  }

  @override
  String get debtPlanTipsTitle => 'വേഗത്തിൽ തീർക്കാൻ';

  @override
  String get debtPlanTipOverdue =>
      'കുടിശ്ശിക ആദ്യം അടയ്ക്കുക. ലേറ്റ് ഫീസും പിഴപ്പലിശയും ഈ പ്ലാനിലെ എന്തിനേക്കാളും ചെലവേറിയതാണ്.';

  @override
  String debtPlanTipCardInterest(String amount) {
    return 'ഈ മാസം കാർഡുകൾക്ക് ഏകദേശം $amount പലിശ വരും. അവ തീരുന്നതുവരെ കാർഡിൽ പുതിയ ചെലവ് ഒഴിവാക്കുക.';
  }

  @override
  String debtPlanTipUtilization(String names) {
    return '$names: ലിമിറ്റിന്റെ 30% ൽ കൂടുതൽ ഉപയോഗിച്ചിരിക്കുന്നു. ഇത് കുറയ്ക്കുന്നത് ക്രെഡിറ്റ് സ്കോറിന് സഹായകമാകും.';
  }

  @override
  String get debtPlanTipConsolidate =>
      'കാർഡ് ബാക്കി കുറഞ്ഞ പലിശയുള്ള ലോണിലേക്കോ EMI യിലേക്കോ മാറ്റാനാകുമോ എന്ന് ബാങ്കിനോട് ചോദിക്കുക. ഫീസ് ഉൾപ്പെടെ ആകെ ചെലവ് കുറവാണെങ്കിൽ മാത്രം ചെയ്യുക.';

  @override
  String get debtPlanAssumptions =>
      'ഏകദേശ കണക്ക് മാത്രം. പുതിയ കാർഡ് ചെലവില്ല, അടവുകൾ കൃത്യസമയത്ത്, നിരക്കുകൾ മാറില്ല എന്ന് കണക്കാക്കുന്നു. മുൻകൂർ അടവിന് ചാർജ് ഉണ്ടാകാം, ആദ്യം പരിശോധിക്കുക.';

  @override
  String get cardAnnualRate => 'പലിശ നിരക്ക് (വർഷം %)';

  @override
  String get cardAnnualRateHelp =>
      'സ്റ്റേറ്റ്മെന്റിൽ കാണാം. കടരഹിത പ്ലാനിൽ ഉപയോഗിക്കുന്നു.';

  @override
  String get extraMoneyTitle => 'അധിക പണം കിട്ടിയോ?';

  @override
  String get extraMoneySubtitle =>
      'ബോണസ്, കുടിശ്ശിക ശമ്പളം, അധിക വരുമാനം: ഇത് കൊണ്ട് ഏത് കടം തീർക്കണമെന്ന് കാണുക.';

  @override
  String get extraMoneyAction => 'എവിടെ അടയ്ക്കണമെന്ന് കാണുക';

  @override
  String extraMoneyDetected(String amount) {
    return 'ഈ മാസം പതിവിലും $amount കൂടുതൽ വരുമാനം. ഇത് കടം കുറയ്ക്കാൻ ഉപയോഗിക്കൂ.';
  }

  @override
  String get extraMoneyIntro =>
      'കിട്ടിയ അധിക തുക നൽകുക. ഏത് ലോൺ, EMI അല്ലെങ്കിൽ കാർഡ് അടയ്ക്കണമെന്ന് കാണിക്കാം.';

  @override
  String get extraMoneyAmount => 'കിട്ടിയ അധിക പണം';

  @override
  String get extraMoneyRecordIncome => 'വരുമാനത്തിൽ ചേർക്കുക';

  @override
  String get extraMoneyKeepReserve =>
      'കുറച്ച് അടിയന്തര ആവശ്യത്തിന് സൂക്ഷിക്കുക';

  @override
  String get extraMoneyKeepReserveHelp =>
      'നിങ്ങളുടെ സമ്പാദ്യം 3 മാസത്തെ ചെലവിനും അടവുകൾക്കും താഴെയാണ്. 25% വരെ മാറ്റിവയ്ക്കും.';

  @override
  String get extraMoneyDoThis => 'ഇങ്ങനെ ചെയ്യുക';

  @override
  String get extraMoneyCloses => 'ഈ കടം പൂർണ്ണമായും തീരും';

  @override
  String get extraMoneyPartPayment => 'ഭാഗിക അടവ്';

  @override
  String get extraMoneyKeep => 'അടിയന്തര ആവശ്യത്തിന് സൂക്ഷിക്കുക';

  @override
  String get extraMoneyLeftover => 'നിങ്ങൾക്ക് ബാക്കി';

  @override
  String get extraMoneyResult => 'ഇതിന്റെ ഫലം';

  @override
  String get extraMoneyClearsAll => 'ഇതോടെ നിങ്ങളുടെ എല്ലാ കടവും തീരും!';

  @override
  String extraMoneyNewDate(String date) {
    return '$date ആകുമ്പോഴേക്കും കടം തീരും';
  }

  @override
  String get extraMoneyInterestSaved => 'ലാഭിക്കുന്ന പലിശ';

  @override
  String extraMoneySooner(String duration) {
    return '$duration നേരത്തെ തീരും';
  }

  @override
  String get extraMoneyFreed => 'നിൽക്കുന്ന മാസ അടവുകൾ';

  @override
  String extraMoneyInstead(String name, String amount, String monthly) {
    return 'ഒരു EMI കുറയ്ക്കണോ? $amount കൊണ്ട് $name പൂർണ്ണമായും തീർക്കാം, മാസം $monthly അടവ് നിൽക്കും.';
  }

  @override
  String get extraMoneyCaution =>
      'അടവ് രേഖപ്പെടുത്താൻ കടത്തിൽ ടാപ്പ് ചെയ്യുക. കൃത്യമായ ക്ലോസിംഗ് തുകയും മുൻകൂർ അടവ് ചാർജും ആദ്യം ബാങ്കിനോട് ചോദിക്കുക.';

  @override
  String get debtProgressTitle => 'നിങ്ങളുടെ പുരോഗതി';

  @override
  String debtProgressPaid(String paid, String peak) {
    return '$peak ൽ $paid അടച്ചുതീർത്തു';
  }

  @override
  String debtProgressJustCleared(String names) {
    return 'അഭിനന്ദനങ്ങൾ! $names തീർത്തു.';
  }

  @override
  String get debtLoadTitle => 'കടഭാരം';

  @override
  String debtLoadShare(String percent) {
    return 'നിർബന്ധിത അടവുകൾ പതിവ് വരുമാനത്തിന്റെ $percent% എടുക്കുന്നു.';
  }

  @override
  String get debtLoadHealthy => 'ആരോഗ്യകരം';

  @override
  String get debtLoadHealthyHelp =>
      'അധികം അടച്ച് നേരത്തെ തീർക്കാൻ നിങ്ങൾക്ക് സാധിക്കും.';

  @override
  String get debtLoadWatch => 'ശ്രദ്ധിക്കുക';

  @override
  String get debtLoadWatchHelp =>
      'ഇത് കുറയുന്നതുവരെ പുതിയ EMI എടുക്കാതിരിക്കുക.';

  @override
  String get debtLoadHigh => 'വളരെ കൂടുതൽ';

  @override
  String get debtLoadHighHelp =>
      '40% ന് മുകളിൽ താങ്ങാൻ പ്രയാസമാണ്. പുതിയ ലോൺ ഒഴിവാക്കുക, പുനഃക്രമീകരണത്തെക്കുറിച്ച് ബാങ്കിനോട് ചോദിക്കുന്നത് പരിഗണിക്കുക.';

  @override
  String debtLoadOverBudget(String amount) {
    return 'പതിവ് ചെലവും അടവുകളും പതിവ് വരുമാനത്തേക്കാൾ മാസം $amount കൂടുതലാണ്.';
  }

  @override
  String debtPlanSuggestedExtra(String amount) {
    return 'കഴിഞ്ഞ മാസങ്ങൾ വെച്ച് മാസം $amount അധികം അടയ്ക്കാൻ കഴിയും.';
  }

  @override
  String get debtPlanUseSuggested => 'ഈ തുക ഉപയോഗിക്കുക';

  @override
  String get debtPlanReminder => 'എല്ലാ മാസവും ഓർമ്മിപ്പിക്കുക';

  @override
  String get debtPlanReminderHelp =>
      'എന്ത് അടയ്ക്കണമെന്ന് ഒന്നാം തീയതി അറിയിക്കും.';

  @override
  String debtPlanReminderTitle(String amount, String name) {
    return 'കടരഹിത പ്ലാൻ: $name ന് $amount അടയ്ക്കുക';
  }

  @override
  String get debtPlanCompareSwitch => 'ചെലവ് താരതമ്യം ചെയ്യുക';

  @override
  String get debtSwitchTitle => 'കുറഞ്ഞ പലിശയിലേക്ക് മാറണോ?';

  @override
  String get debtSwitchIntro =>
      'നിലവിലെ നിരക്കിൽ തുടരുന്നതും കാർഡ്-ടു-EMI, ബാലൻസ് ട്രാൻസ്ഫർ അല്ലെങ്കിൽ പേഴ്സണൽ ലോണും താരതമ്യം ചെയ്യുക.';

  @override
  String get debtSwitchBalance => 'മാറ്റേണ്ട തുക';

  @override
  String get debtSwitchCurrentRate => 'നിലവിലെ പലിശ നിരക്ക് (വർഷം %)';

  @override
  String get debtSwitchNewRate => 'പുതിയ പലിശ നിരക്ക് (വർഷം %)';

  @override
  String get debtSwitchMonths => 'തിരിച്ചടവ് മാസങ്ങൾ';

  @override
  String get debtSwitchFee => 'പ്രോസസ്സിംഗ് ഫീസ്';

  @override
  String get debtSwitchFeeHelp =>
      'GST ഉൾപ്പെടുത്തുക. ചില EMI ഓഫറുകൾ ഫ്ലാറ്റ് നിരക്കാണ്, റെഡ്യൂസിംഗ് ബാലൻസ് നിരക്ക് ചോദിക്കുക.';

  @override
  String get debtSwitchResult => 'ഫലം';

  @override
  String debtSwitchWorthIt(String amount) {
    return 'ഗുണകരം: ഫീസ് കഴിഞ്ഞ് $amount ലാഭം';
  }

  @override
  String get debtSwitchNotWorthIt => 'ഗുണകരമല്ല: ഫീസ് ലാഭം ഇല്ലാതാക്കുന്നു';

  @override
  String get debtSwitchKeepInterest => 'തുടർന്നാൽ പലിശ';

  @override
  String get debtSwitchNewInterest => 'മാറിയാൽ പലിശ';

  @override
  String get debtSwitchFeeAmount => 'ഫീസ്';

  @override
  String get debtSwitchNewEmi => 'പുതിയ മാസ EMI';
}
