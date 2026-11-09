# Kept — implementation notes

How the app is put together, the rules behind every number it shows, and
what has to be configured in Firebase.

## Architecture

```
lib/
  app/            MaterialApp, auth gate, bottom-nav shell, startup tasks
  core/           cross-cutting: money, dates, recurrence, errors, l10n,
                  Firebase providers, notifications, settings, theme, routing
  features/<x>/   one folder per module
    domain/       immutable models + pure calculations (no Flutter, no I/O)
    data/         Firestore repositories
    application/  Riverpod providers (streams + derived/memoised values)
    presentation/ screens and widgets
  shared/widgets/ reusable UI (money text, charts, form fields, states)
  l10n/           ARB source + generated AppLocalizations
  data/, domain/  legacy Gmail/SMS import layer (kept behind kAutoImportEnabled)
```

* State management: Riverpod 3 (`Notifier`, `StreamProvider`, families,
  derived `Provider`s). Widgets only read providers and call repositories.
* Navigation: `AppRoutes` (lib/core/routing) is the single place that opens
  screens; the shell's tab is `shellTabProvider`.
* Per-screen UI state (tab, month, filters, dashboard scope) resets when
  the signed-in user changes.
* No code generation: models are hand-written immutable classes with
  `copyWith`/`toMap`/`fromMap`, keeping the build simple.

## Offline-first and sync

Firestore's persistent cache is the on-device database
(`persistenceEnabled`, unlimited cache, set in `main.dart`).

* Writes go through `WriteDispatcher`: they apply to the local cache
  immediately (streams update, also offline) and the server acknowledgement
  is tracked in `syncStatusProvider` (pending count, last synced, last
  rejection shown as a snackbar). The entry flow never waits on the network.
* IDs are generated on the device (`collection.doc().id`) or are
  deterministic, so sync never creates duplicates.
* Identity: every user has a Firebase UID. "Continue without an account"
  uses anonymous auth; Settings → *Sign in with Google* links the guest
  account in place (same UID, data kept). The very first launch needs
  connectivity once to obtain the UID.

## Money

* All amounts are `int` minor units (paise/cents). `Money.parse` rejects
  negatives and more than two decimals. `CurrencyFormatter` is the only
  formatter; the currency is a user setting (INR, USD, EUR, GBP, AED, SAR —
  all two-decimal currencies).
* `Transaction.amountMinor` is always positive; direction comes from `type`.

## Balances (single source of truth: `LedgerEffects`)

`LedgerEffects.of(tx)` defines how a cleared transaction moves money:

| Type | Account balance | Card outstanding |
|---|---|---|
| expense, loanPayment, lent, debtRepayment | −amount (source) | |
| income, borrowed, debtCollection | +amount | |
| transfer | −source, +destination | |
| creditCardExpense | | +amount |
| creditCardPayment | −amount (paying account, optional) | −amount |
| refund | +amount (account) | −amount (if to a card) |

Pending transactions have no effect until cleared.

Account balance = `openingBalanceMinor + ledgerDeltaMinor`; card
outstanding = `openingOutstandingMinor + ledgerDeltaMinor`. The delta is
updated with `FieldValue.increment` **in the same batch** as the transaction
write (create: +effect, edit: −old +new, delete: −effect), so balances never
require loading the full history. Profile edits merge only editable fields
and never touch the delta.

*Settings → Recalculate balances* rebuilds every delta from the full
history with the same function. It also runs after a restore. (Drift is only
possible if two offline devices generate the same recurring occurrence before
either syncs.)

Accounts referenced by transactions, loans, borrow/lend records, recurring
rules or a card's "pays from" link can't be deleted, and neither can cards
referenced by transactions or recurring rules (later balance updates would
be rejected by the server and rolled back). They can be archived. Forms
never preselect an account that no longer exists, and recurring generation
skips a rule whose account/card is missing instead of failing every launch.

## Monthly summary definitions (`MonthlySummary`)

* Spending = expenses + card expenses − refunds. Card **payments** and
  transfers are excluded, so card spending is not counted twice.
* EMI = loan payments (shown separately). Savings = income − spending − EMI.
* Borrowed / lent are reported separately and don't affect savings.
* Pending transactions only count towards "pending".
* Dashboard "Pending payments" = unpaid card dues and EMIs due in the month,
  amounts you owe that are due in the month, plus pending outflows.

## Credit cards

Utilisation = outstanding / limit (0 when there's a credit balance; can
exceed 100%). Statement figures come from the outstanding balance and the
card's movements since the last statement date:
statement balance = outstanding − charges since + payments since;
total due = statement balance − payments since. Minimum due is an
**estimate** (`minimumDuePercent`, default 5%) and is labelled as such. The
app stores only the last 4 digits (validated as exactly 4 digits). No CVV,
PIN, OTP or full number, enforced in the client, backups and security rules.

## Loans (`EmiEngine`, `LoanSchedule`)

* EMI = P·r·(1+r)^n / ((1+r)^n − 1), r = annual% / 100 / periods per year;
  P/n at 0%. Rounded to the minor unit. The lender's exact EMI can override
  the computed one.
* Rate finder: bisection on the EMI formula (strictly increasing in r) over
  [0, 100% per period]. Returns 0 when payments equal principal, and nothing
  when payments can't repay the principal or the rate is absurd.
* Schedule: interest = opening balance × r (rounded); principal = EMI −
  interest; the last installment absorbs rounding so the loan closes at 0.
  Due dates keep the first EMI's day of month, clamped to short months.
* Paid: marks an installment paid; with an account it creates a
  `loanPayment` transaction (id `loan_<loan>_i<n>`). Re-recording replaces it
  and undo reverses it.
* Skipped: status only; the installment stays owed and the schedule is
  unchanged.
* Prepayment: reduces principal before the first installment due *after* its
  date (on the due date it applies after that installment). The user picks:
  * **Keep EMI, finish sooner** (`reduceTenure`): the EMI is unchanged and
    the loan ends when the balance reaches 0.
  * **Keep tenure, lower EMI** (`reduceEmi`): the EMI is recomputed on the new
    balance over the installments left in the original contract.

  The sheet previews the new EMI, remaining EMIs, outstanding and interest
  saved before anything is saved. Amounts beyond what's owed are reported as
  "not applied".
* Outstanding principal = principal − principal of paid installments −
  applied prepayments. Status: completed when all installments are paid,
  prepaid when a prepayment ended it early, closed when the user closes it.

## Borrow / lend

Status is derived, never stored: settled (outstanding 0), overdue (due date
passed), partially settled, pending. Settlements are embedded in the record;
when money moved through an account, linked transactions
(`borrowed`/`lent`/`debtRepayment`/`debtCollection`) keep the balance right.

## Debt-free plan (`DebtPlan`, `PayoffSchedule`)

Combines active loans, card balances and money borrowed from people, and
simulates month by month in minor units. Each month interest accrues, every
minimum is paid, then the rest of a constant budget (first month's minimums +
the user's extra) goes to debts in strategy order, so a closed debt's payment
rolls onto the next.

* **Strategies.** Avalanche: highest rate, then smallest balance. Snowball:
  smallest balance, then highest rate. The order is fixed at the start.
* **Loans** use outstanding principal and the current EMI normalised to a
  month, so quarterly/yearly loans are approximate.
* **Cards** pay `minimumDuePercent` of the balance, floored at 1% of the
  starting balance. `annualRatePercent` is optional; while unset the plan uses
  `CreditCard.typicalAnnualRatePercent` and labels it an estimate.
* **Borrowed from people** has no interest or required payment; it is paid from
  extra or freed-up money and left out of the minimums-only comparison.
* **Unfinished plans.** A plan open after 600 months, or whose balance reaches
  100x its start, is reported as never clearing rather than given a date.
* **Extra money (`LumpSumAdvice`).** A one-off sum goes down the plan's order,
  closing debts where it can; up to 25% is kept when savings are below 3 months
  of spending plus required payments. The monthly budget is held constant
  afterwards. Payments are recorded by the user on the debt's own screen.
* **Income signals (`FinancialProfile`).** Averages use the last 3 complete
  months with activity. Income 20%+ above average this month counts as extra
  money. The suggested extra is half of income - spending - required payments.
  Debt load bands: under 30% healthy, 30-40% watch, over 40% high.
* **History (`DebtProgress`).** One snapshot per month in
  `settings/debt_progress` (already allowed by the security rules, not part of
  backups), written by `DebtPlanSync`. A debt deleted from the app counts as
  cleared. The opt-in monthly reminder is `debt_plan_monthly`, kept by the same
  sync.
* The plan assumes no new card spending, on-time payments and unchanged rates;
  the screen says so. The extra amount and strategy are device preferences.

## Recurring transactions

Rules expand with the shared `Recurrence` (daily/weekly/monthly/yearly,
every N, optional end; monthly/yearly keep the day, clamped). On each launch,
occurrences up to today (checked at launch and every time the app
resumes) become transactions with deterministic ids
`rec_<rule>_<yyyyMMdd>`, skipping ids that already exist, and the rule's
`lastGeneratedDate` advances in the same batch. Loan EMIs are not recurring
rules; use the loan module so installments are tracked.

## Budgets

Monthly limits, overall or per expense category (deterministic id, so one
per category). Usage comes from the same `MonthlySummary` as the dashboard.
Warning thresholds are configurable (default 75/90/100%). Saving an expense
that crosses one shows a warning (toggle in Settings).

## Reminders and notifications

* `Reminder`: wall-clock date + time (stored as `yyyy-MM-dd` and `HH:mm` so
  the time stays the same across time zones), recurrence, offsets in minutes,
  optional owning entity (loan / card / borrow-lend). Entity reminders use
  id `<entityType>_<entityId>`; their schedule follows the entity, while
  time, offsets and on/off stay user-editable.
* `NotificationPlanner` (pure) expands enabled reminders over a rolling
  60-day window and caps the result at 60 (iOS allows 64 pending). Every
  reminder's *next* occurrence (looking up to a year ahead) is reserved
  first, so a daily reminder can't crowd out an EMI; remaining slots go to
  later occurrences, soonest first. Each notification id = FNV-1a hash of
  reminder id + offset + occurrence, so it is deterministic.
* Permission is requested once per install as soon as any enabled reminder
  exists — including loan, card and borrow/lend reminders and reminders
  restored after a reinstall. The dashboard shows a banner when reminders
  exist but notifications are blocked.
* Loan reminders are derived from the live schedule by `LoanReminderSync`:
  anchored on the next unpaid EMI, removed when the loan is completed,
  prepaid, closed or deleted, and restored if a payment is undone.
* The background syncs (`NotificationSync`, `LoanReminderSync` and the
  custom-category registry) are started by `StartupTasks` and held open with
  container-level listeners. Riverpod pauses a stream once the widgets
  watching it are hidden (any pushed screen does that), and a provider that is
  only `read`, or only listened to by another provider, does not keep its
  sources running; without the explicit listeners a restore or a reminder
  change made while a screen was open would only be noticed after leaving it.
  `test/widgets/background_sync_test.dart` covers this.
* `NotificationSync` re-plans whenever reminders change (including when they
  stream in after a restore or reinstall), on app resume and on demand, and
  `LocalNotificationService.reconcile` cancels stale ids, schedules new or
  changed ones and leaves identical ones alone, so there are no duplicates.
  Scheduling is time-zone aware (`flutter_timezone` + `timezone`); Android
  uses exact alarms when permitted, otherwise inexact.

## Backup and restore

* Firestore already keeps a live cloud copy. Backups add restorable
  snapshots: Settings → *Back up now*, plus an automatic weekly backup for
  signed-in (non-guest) users. Files are written to
  `users/{uid}/backups/backup-<millis>.json` in Storage; the last 5 are kept.
* Format (`BackupCodec`): `format`, `schemaVersion` (envelope, currently 1),
  `dataSchema`, `createdAt`, `settings`, `collections`. Timestamps are encoded
  as `{"__ts": millis}`. Decoding rejects other files and newer schema
  versions, and skips invalid documents (bad ids, invalid transactions,
  credential fields).
* Restore writes documents under their original ids (overwriting matches;
  later records are kept), recalculates balances, migrates schema-1
  transactions, updates `settings/backup` and triggers notification
  rescheduling.

## Migrations

* Transactions schema 1 (`merchant`, whole-unit `amount`, `isCredit`,
  ISO `occurredAt`) are read through `Transaction.fromMap` and rewritten as
  schema 2 by a one-time startup migration per user (flag in
  SharedPreferences). Amounts ×100, `isCredit` → income/expense, category
  names → ids, `sourceChannels` → `importSource`.
* New `Transaction` fields must be optional in `fromMap`; bump
  `Transaction.schemaVersion` and handle the previous shape there.

## Firebase setup required

1. **Authentication**: enable *Anonymous* and *Google* providers.
2. **Firestore**: deploy rules and indexes:
   `firebase deploy --only firestore:rules,firestore:indexes`
3. **Storage**: create the default bucket, then
   `firebase deploy --only storage`.
4. The composite indexes in `firestore.indexes.json` back the per-account,
   per-card and per-loan activity lists. Month and range queries use the
   automatic single-field index on `date`.

## Localization

English (`en`, the template) and Malayalam (`ml`) ship in the app. Strings
live in `lib/l10n/app_<code>.arb` (gen-l10n; run `flutter gen-l10n` after
editing). Enum and id labels (categories, account types, statuses, …) are
mapped to localized text in one place, the `DomainLabels` extension in
`lib/core/l10n/l10n.dart`, so domain classes stay free of UI strings.

* **Choosing a language.** Settings → Language offers "Device language",
  English and മലയാളം (each language is listed by its own name, see
  `languageNativeName`). The welcome screen has the same switcher
  (`LanguageButton`) so people can choose before signing in. The choice is
  kept in `SharedPreferences` (`settings.locale`); null follows the phone.
* **What is not translated:** amounts and dates keep Latin digits, `₹` and
  the currency's grouping (e.g. `₹1,23,456.78`) in every language, so figures
  look the same everywhere. Brand and acronym terms stay Latin (Kept, EMI,
  Google, CNG, kWh). Text the user typed (account names, custom categories,
  descriptions) is never translated.
* **Text stored in the data.** Reminder titles for cards and borrow/lend
  records, and the loan reminder title, are saved as text. When the language
  changes they are re-titled (`EntityReminders.relabel`, `LoanReminderSync`),
  and `NotificationSync` re-plans so scheduled notification wording follows
  the new language. Writes are deferred out of the build phase because the
  change can arrive while widgets are building.
* **Platform registration.** `ios/Runner/Info.plist` (`CFBundleLocalizations`)
  and `android/app/src/main/res/xml/locales_config.xml` list the languages so
  the OS offers them in its per-app language settings.
* **Checking how it looks.** Widget tests render every glyph in the Ahem
  test font, so they catch overflow errors but not a label squeezed to a
  sliver or a word broken in the middle. To see real Malayalam shaping, load
  a system font in a throwaway test (`FontLoader('Roboto')` with
  `/System/Library/Fonts/Supplemental/Malayalam Sangam MN.ttc` and
  `MaterialIcons` from the Flutter SDK's `material_fonts`) and write goldens
  with `flutter test --update-goldens`. That is how the tab labels, the next
  EMI row and the interest-rate display were found and fixed.
* **Adding a language** (e.g. Arabic): copy `app_en.arb` to `app_<code>.arb`
  and set `@@locale`; translate every value, keeping the `{placeholders}`;
  add the code to `_languages` in `test/domain/l10n_parity_test.dart`, to
  `CFBundleLocalizations` and to `locales_config.xml`; add its name to
  `languageNativeName`. The parity test fails on a missing key, a changed
  placeholder, a blank value or a copied-over English message. For a
  right-to-left language also check the layouts (they use directional
  padding where direction matters).
* The Android notification channel's name and description (shown in the
  system's notification settings) are set in the app's language by
  `NotificationService.setChannelText`, and refreshed when the language
  changes.

## Testing

`flutter test` runs:

* `test/domain`: EMI, rate solver, amortization (paid/skipped/prepayments),
  ledger effects, validation, monthly summary, filters/search, legacy
  migration, cards, budgets, vehicles, borrow/lend, recurrence, recurring
  generation, notification planning, backup codec, legacy Gmail parsers, and
  translation parity (`l10n_parity_test.dart`: same keys and placeholders in
  every language, nothing blank or left in English).
* `test/data`: repositories against `fake_cloud_firestore` (balances on
  create/edit/delete, transfers, cards, recalculation, idempotent recurring
  generation, loan payments, settlements, fuel expenses, migration).
* `test/widgets`: the full app with fake Firebase: onboarding, add account,
  expense (with balance update and validation), card, loan, reminder
  (notifications scheduled), month switching, search, global search,
  dashboard charts, dark mode, the same screens in Malayalam (layout at 2x
  text size and on a 320 dp phone, a full add-expense flow, switching the
  language from Settings and from the welcome screen, re-titled reminders),
  and the background syncs running while another screen is open.

## UX polish

* Tapping empty space hides the keyboard (a translucent `GestureDetector`
  above the navigator; buttons and fields still win their own taps), and
  dragging a form dismisses it too. Number keyboards on iPhone have no
  "Done" key, so this is the only way out of them.
* Deleting a transaction (detail sheet or swipe left in the list) shows an
  Undo snackbar. Undo saves the same record again, which re-applies its
  balance effect. Records owned by loans, borrow/lend or vehicles can't be
  swiped away.
* Leaving a half-filled new entry (system back, swipe-back, tapping outside
  a sheet) asks "Discard changes?" (`UnsavedChangesGuard`). Saving pops
  directly and never prompts.
* Add-transaction: Today / Yesterday chips, categories can be cleared, and
  amount fields preview the formatted value (₹1,23,456) as you type.
* Light haptics on selections and saves (`Haptics`); snackbars float above
  the bottom bar; the app is portrait-only.
* App icon and launch screens use the Kept mark. Regenerate the icons with
  `dart run flutter_launcher_icons` after editing `assets/icon/`.

## Ads (AdMob)

* `lib/core/ads/ad_config.dart` holds the banner and rewarded unit ids.
  Debug/profile builds always use Google's **test** units; release builds use
  the production ids there and show **no ads** (or, for the rewarded ids, no
  video offer) while they are empty.
* App ids live in `AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`)
  and `ios/Runner/Info.plist` (`GADApplicationIdentifier`). Both are set to
  the real AdMob app ids for `com.fahadt.kept`, as are the banner unit ids in
  `ad_config.dart`. Only release builds use them; debug/profile still serve
  Google's test units.
* `startAds()` (ad_service.dart) sets mild content limits (PG), runs Google's
  User Messaging Platform consent flow (GDPR/UK form only where it applies)
  and only then initializes the SDK. Any failure just means "no ads".
  Settings shows "Ad privacy settings" where the law requires that entry.
* `BannerAdSlot` is an inline adaptive banner that takes no space until an ad
  loads. It appears only at the end of the dashboard and below the
  transactions list, never on forms or beside money-entry controls.
* **Rewarded video: "no ads for 24 hours".** Users who dislike ads can
  watch one short video of their own choice.
  * Where: a small "Watch a video, no ads for 24 hours" line under every
    loaded banner (dashboard, transactions list) and Settings → Ads. The
    inline line appears only once a video is loaded, so it is never a dead
    button; nothing ever plays without a tap.
  * `RewardedAdController` (`rewarded_ads.dart`) loads one video on demand
    (when a banner has loaded or Settings opens), replaces it before Google's
    one-hour expiry, retries a failed request after 30 s (or at once from
    Settings' "Retry") and plays it. `RewardedAdGateway` is the seam over the
    SDK, so tests use a fake.
  * The reward (`AdFreeController`, `ad_free.dart`) is an expiry time kept in
    `SharedPreferences` on this device only: not in the settings, so it is
    never backed up or restored onto another phone. Banners hide while it
    lasts and return by themselves (a timer, plus a re-check when the app
    comes back to the foreground). A stored expiry further ahead than 24 h
    (clock moved back) is cut to 24 h. There is no stacking: the offer
    returns when the time has run out.
  * Release builds need `prodRewardedAndroid` / `prodRewardedIos` in
    `ad_config.dart` (create a *Rewarded* ad unit per platform in AdMob);
    until then they simply don't show the offer.
  * Tests: `test/domain/ad_free_test.dart`, `rewarded_ads_test.dart`,
    `test/widgets/ad_free_test.dart` (Settings flow, early close, load
    failure, expiry, Malayalam, narrow screens).
* The plugin is pinned to `google_mobile_ads` **8.x**. Version 9.x imports a
  private beta header of Google's SDK that Xcode 26 rejects ("Include of
  non-modular header inside framework module"), so the iOS build fails.
  Re-test before upgrading to 9.x.
* Before release also: declare "Advertising" data use in the App Store
  privacy labels and the Play Data safety form, and add the full SKAdNetwork
  id list from AdMob's iOS guide to `Info.plist`.

## Store images

`tool/store_images/` renders the app, with generated demo data, into the
screenshots, feature graphic and icons the stores ask for, in English and
Malayalam; the results are in `store/` (see `store/README.md` for which file
goes where and how to regenerate them). Making them also exposed two real UI
bugs, both fixed: the principal/interest bar was invisible (a childless
`ColoredBox` in a loose-height `Row`) and the app bar title did not take the
theme's font family.

## Known limitations

* The first launch needs connectivity once (to create the anonymous or
  Google identity); the app works offline after that.
* Guest data is tied to the device's anonymous account. Signing out or
  uninstalling without linking Google loses access. The app warns about this.
* Global search covers the last 12 months of transactions (Firestore has no
  full-text search); the transactions tab can search any custom date range.
* Attachments: the `attachmentUrl` field exists, but there is no upload UI yet.
* App lock / biometric unlock is not implemented yet.
* English and Malayalam are shipped; other languages (e.g. Arabic) need a translated ARB file and a layout check, see Localization. The Malayalam text was written without a native-speaker review: please have one read through it before release.
* SMS/Gmail auto-import remains disabled (`kAutoImportEnabled = false`).
  The Gmail importer is wired into Settings when enabled. The SMS code reads
  the inbox but never parsed transactions; `READ_SMS`/`RECEIVE_SMS` in the
  Android manifest and the `sms_reader`/`permission_handler` packages should
  be removed before a Play Store release unless that feature is finished.
