# ExpanseTrackerPro — implementation notes

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

All UI strings are in `lib/l10n/app_en.arb` (gen-l10n). To add Malayalam or
Arabic, add `app_ml.arb` / `app_ar.arb` with the same keys; they appear in
Settings → Language automatically. Layouts use directional padding where
direction matters. Currency and number formats come from the selected
currency's locale.

## Testing

`flutter test` runs:

* `test/domain`: EMI, rate solver, amortization (paid/skipped/prepayments),
  ledger effects, validation, monthly summary, filters/search, legacy
  migration, cards, budgets, vehicles, borrow/lend, recurrence, recurring
  generation, notification planning, backup codec, legacy Gmail parsers.
* `test/data`: repositories against `fake_cloud_firestore` (balances on
  create/edit/delete, transfers, cards, recalculation, idempotent recurring
  generation, loan payments, settlements, fuel expenses, migration).
* `test/widgets`: the full app with fake Firebase: onboarding, add account,
  expense (with balance update and validation), card, loan, reminder
  (notifications scheduled), month switching, search, global search,
  dashboard charts, dark mode.

## Known limitations

* The first launch needs connectivity once (to create the anonymous or
  Google identity); the app works offline after that.
* Guest data is tied to the device's anonymous account. Signing out or
  uninstalling without linking Google loses access. The app warns about this.
* Global search covers the last 12 months of transactions (Firestore has no
  full-text search); the transactions tab can search any custom date range.
* Attachments: the `attachmentUrl` field exists, but there is no upload UI yet.
* App lock / biometric unlock is not implemented yet.
* Only English is shipped; Malayalam and Arabic need translated ARB files.
* SMS/Gmail auto-import remains disabled (`kAutoImportEnabled = false`).
  The Gmail importer is wired into Settings when enabled. The SMS code reads
  the inbox but never parsed transactions; `READ_SMS`/`RECEIVE_SMS` in the
  Android manifest and the `sms_reader`/`permission_handler` packages should
  be removed before a Play Store release unless that feature is finished.
