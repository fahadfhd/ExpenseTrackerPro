# Kept

A personal finance manager built with Flutter and Firebase: expenses and
income, bank accounts, credit cards, loans with EMI schedules, borrow/lend,
budgets, recurring transactions, vehicle fuel tracking, reminders with local
notifications, reports, and cloud backup. Works offline and syncs when
online.

## Getting started

```sh
flutter pub get
flutter run
```

Firebase setup (Anonymous + Google auth, Firestore rules/indexes, Storage
rules) is described in [docs/IMPLEMENTATION_NOTES.md](docs/IMPLEMENTATION_NOTES.md#firebase-setup-required).

## Development

```sh
flutter analyze
flutter test
```

Architecture, calculation rules (balances, summaries, EMI/amortization,
prepayments), notification and backup design, migrations and known
limitations are documented in
[docs/IMPLEMENTATION_NOTES.md](docs/IMPLEMENTATION_NOTES.md).
