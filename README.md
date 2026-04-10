# BudgetWise

A personal finance tracker built with Flutter. Track your income, expenses, budget, savings, and credit cards — all in one place.

---

## Features

- **Overview** — 6-month spending trend, payment due alerts, and recent expenses at a glance
- **Expenses** — Log and categorize spending by Needs, Wants, or Savings; supports multiple payment modes (cash, GCash, Maya, credit card, etc.)
- **Budget** — Set budget targets per category and track how much you've used
- **Savings** — Monitor savings goals and progress
- **Credit Cards** — Track card balances, statement periods, and payment due dates with correct billing cycle logic
- **Income & Setup** — Configure income sources and budget split percentages (accessible from the Budget tab)
- **Recurring** — Manage recurring transactions and templates (accessible from the Cards tab)
- **Dark/Light mode** — Toggleable from Settings

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, navigation shell, bottom nav
├── models/
│   └── models.dart            # All data models (Expense, CreditCard, Income, etc.)
├── providers/
│   └── app_provider.dart      # State management via ChangeNotifier
├── screens/
│   ├── dashboard_screen.dart  # Home / Overview
│   ├── expenses_screen.dart   # Expenses list and logging
│   ├── budget_screen.dart     # Budget breakdown
│   ├── savings_screen.dart    # Savings goals
│   ├── credit_card_screen.dart# Credit card management
│   ├── income_screen.dart     # Income & setup (pushed screen)
│   ├── recurring_screen.dart  # Recurring transactions (pushed screen)
│   └── settings_screen.dart   # App settings
├── utils/
│   └── theme.dart             # Colors, typography, AppColors extension
└── widgets/
    └── shared_widgets.dart    # Reusable UI components
```

---

## Navigation

The bottom nav bar has **5 tabs**: Home, Expenses, Budget, Savings, Cards.

| Tab | Screen |
|-----|--------|
| Home | Dashboard / Overview |
| Expenses | Expenses |
| Budget | Budget |
| Savings | Savings |
| Cards | Credit Cards |

**Income & Setup** and **Recurring** are accessible via icon buttons in the top AppBar — Income appears when on the Budget tab, Recurring appears when on the Cards tab. Both screens have a back button to return to the previous tab.

---

## Credit Card Billing Logic

Statement cut-off day and due day are configurable per card. The billing logic works as follows:

- **Previous statement** — the closed billing cycle (e.g. Feb 25 → Mar 25). Unpaid charges here are **due now**.
- **Current period** — the open billing cycle (e.g. Mar 25 → Apr 25). Charges here are **not yet due**.
- **Due date** — always the `dueDay` of the month following the statement cut-off (e.g. Apr 14 for a Mar 25 cut-off).

This means a transaction made on Apr 10 with a cut-off of the 25th will appear under "Current period (not yet due)" and will **not** trigger a payment alert until the next statement closes.

---

## Getting Started

### Requirements

- Flutter SDK 3.x+
- Dart 3.x+

### Run

```bash
flutter pub get
flutter run
```

### Dependencies

- `provider` — state management
- `google_fonts` — Plus Jakarta Sans, Inter
- `shared_preferences` — local data persistence

---

## Recent Changes

| File | Change |
|------|--------|
| `lib/models/models.dart` | Fixed credit card billing cycle logic — added `prevStatementDate`, `previousStatementTransactions`; corrected `nextDueDate` and `hasBillDue` |
| `lib/screens/credit_card_screen.dart` | Updated statement info UI to correctly show previous vs current period; fixed Pay Bill modal |
| `lib/screens/dashboard_screen.dart` | Fixed Payment Due Soon card to show correct statement date range |
| `lib/main.dart` | Reduced bottom nav from 7 to 5 tabs; increased nav bar height to 72px; added contextual Income and Recurring shortcuts in AppBar |
| `lib/screens/income_screen.dart` | Added AppBar with back button |
| `lib/screens/recurring_screen.dart` | Added AppBar with back button |
