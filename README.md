# BudgetWise

A personal finance tracker built with Flutter, Firebase, and the 50/30/20 budgeting method. Track income, expenses, credit cards, recurring bills, and savings accounts — all synced to the cloud.

---

## Features

### Dashboard
- Hero card showing total monthly income, amount spent, and remaining balance with a live progress bar
- Over-budget / on-track status badge
- Spending donut chart broken down by Needs, Wants, and Savings
- Budget progress cards per category
- Monthly bar chart of expenses over time
- Overdue recurring transactions banner
- Credit card bills due soon alert (within 7 days)
- Recent expenses list

### Income (`IncomeScreen`)
- Add multiple income sources per month with a label and amount
- Two income modes: **Monthly** (standard) and **Cutoff** (for salary periods tied to a cutoff day)
- Navigate backward and forward between months (up to one month ahead)
- Per-month breakdown showing how income splits into Needs / Wants / Savings allocations
- Edit and delete individual income entries

### Budget (`BudgetScreen`)
- Visualizes the 50/30/20 split across three categories: **Needs**, **Wants**, **Savings**
- Summary row: Total Budget, Total Allocated, Total Spent
- Per-category progress bars showing spent vs. budget
- Add, edit, and delete **sub-categories** (e.g. Rent, Electricity, Groceries) within each category
- Real-time available balance shown when adding a sub-category
- Prevents sub-category budgets from exceeding the parent category allocation
- Unallocated balance indicator per category

### Expenses (`ExpensesScreen`)
- Log expenses with: title, amount, category, sub-category (optional), payment method, date, and notes
- Filter by All / Needs / Wants / Savings using animated pill tabs
- Payment methods: Cash, Credit Card, Debit Card, GCash, Maya, Bank Transfer, Other
- Link credit card expenses directly to a specific card
- Category and sub-category tags on each expense card
- Swipe-to-delete with confirmation dialog
- Sorted by date (most recent first)

### Recurring Transactions (`RecurringScreen`)
- Create recurring expense templates with daily, weekly, monthly, or yearly frequency
- Set a start date and optional end date
- Active vs. inactive template sections
- Monthly cost summary across all active recurring items
- Due-now banner on dashboard and recurring screen when a template is overdue
- Process due templates directly from the dashboard or recurring screen
- Frequency label and next due date displayed per template

### Credit Cards (`CreditCardScreen`)
- Add cards with: name, bank, credit limit, statement cut-off day, and payment due day
- Automatically calculates:
  - Previous statement period (closed, payment now due)
  - Current open statement period (not yet billed)
  - Next due date, with a days-until-due counter
  - Unpaid balance from the closed statement
  - Available credit remaining
- Per-card transaction log: add transactions, mark individual transactions as paid
- Bill due soon warning when unpaid statement balance exists and due date is within 7 days
- Total owed summary across all cards
- Edit and delete cards

### Savings / Bank Accounts (`SavingsScreen`)
- Add bank accounts and e-wallets (BDO, BPI, GCash, Maya, etc.)
- Track balance per account
- Log transactions (deposits/withdrawals) per account
- Total savings summary across all accounts

### Settings (`SettingsScreen`)
- Adjust the budget split percentages (Needs / Wants / Savings) — defaults to 50 / 30 / 20
- Toggle between **Monthly** and **Cutoff** income modes globally
- Dark / Light mode toggle
- Account profile display (name, email, profile photo)
- Cloud sync status indicator (Syncing / Synced / Error)
- Manual sync trigger and retry on error
- Sign out

---

## Architecture

```
lib/
├── main.dart                  # App entry point, Firebase init, auth gate, bottom nav
├── firebase_options.dart      # FlutterFire generated config
├── models/
│   └── models.dart            # All data models and enums
├── providers/
│   ├── app_provider.dart      # Main state management (ChangeNotifier)
│   └── auth_provider.dart     # Firebase Auth state
├── screens/
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── income_screen.dart
│   ├── budget_screen.dart
│   ├── expenses_screen.dart
│   ├── recurring_screen.dart
│   ├── credit_card_screen.dart
│   ├── savings_screen.dart
│   └── settings_screen.dart
├── services/
│   └── firestore_service.dart # Firestore CRUD layer
├── utils/
│   └── theme.dart             # AppColors, theme builder, shared formatters
└── widgets/
    └── shared_widgets.dart    # Reusable UI components
```

### State Management
`AppProvider` (Provider / ChangeNotifier) holds all app state. It:
- Loads data from `SharedPreferences` on startup for instant local display
- Syncs with Firestore after sign-in, applying remote data if it exists or pushing local data up on first login
- Exposes computed getters (`totalIncome`, `needsBudget`, `totalSpent`, `remainingTotal`, `cardsDueSoon`, `overdueRecurring`, etc.) consumed directly by widgets

### Data Layer
`FirestoreService` handles all Firestore reads and writes with typed helpers per collection. Data is stored under `users/{uid}/` with separate subcollections for each entity type. All writes go through `AppProvider`, which persists to both Firestore and local `SharedPreferences`.

### Navigation
Custom animated bottom navigation bar with 5 tabs: **Dashboard**, **Budget**, **Expenses**, **Cards**, **Savings**. Income, Recurring, and Settings are accessed via modal sheets or push routes from within those tabs.

---

## Data Models

| Model | Key Fields |
|---|---|
| `AppSettings` | `needsPercent`, `wantsPercent`, `savingsPercent`, `incomeMode`, `isDarkMode` |
| `Income` | `amount`, `label`, `mode` (monthly/cutoff), `cutoffPeriod`, `date` |
| `BudgetSubCategory` | `name`, `budgetAmount`, `category` (needs/wants/savings) |
| `Expense` | `title`, `amount`, `category`, `subCategoryId`, `paymentMode`, `date`, `notes`, `creditCardId`, `isRecurring`, `recurringFrequency`, `recurringEndDate`, `recurringGroupId` |
| `RecurringTemplate` | `title`, `amount`, `category`, `paymentMode`, `frequency`, `startDate`, `endDate`, `lastProcessed` |
| `BankAccount` | `name`, `bankName`, `balance`, `transactions[]` |
| `BankTransaction` | `description`, `amount`, `date` |
| `CreditCard` | `name`, `bank`, `creditLimit`, `balance`, `statementDay`, `dueDay`, `transactions[]` |
| `CreditCardTransaction` | `description`, `amount`, `date`, `isPaid` |

### Enums

| Enum | Values |
|---|---|
| `IncomeMode` | `monthly`, `cutoff` |
| `CategoryType` | `needs`, `wants`, `savings` |
| `PaymentMode` | `cash`, `creditCard`, `debitCard`, `gcash`, `maya`, `bankTransfer`, `other` |
| `RecurringFrequency` | `daily`, `weekly`, `monthly`, `yearly` |

---

## Tech Stack

| Layer | Package |
|---|---|
| Framework | Flutter |
| State management | `provider` |
| Backend / Auth | Firebase (Firestore + Firebase Auth) |
| Local cache | `shared_preferences` |
| Charts | `fl_chart` |
| Typography | `google_fonts` (Inter, Plus Jakarta Sans) |
| ID generation | `uuid` |

---

## Getting Started

### Prerequisites
- Flutter SDK (3.x or later)
- A Firebase project with Firestore and Google Sign-In enabled

### Setup

1. Clone the repository and install dependencies:
   ```bash
   flutter pub get
   ```

2. Connect your Firebase project using FlutterFire CLI:
   ```bash
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart`.

3. In the Firebase Console:
   - Enable **Cloud Firestore**
   - Enable **Google Sign-In** under Authentication

4. Run the app:
   ```bash
   flutter run
   ```

### Firestore Security Rules

Restrict access so users can only read and write their own data:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Currency

All amounts are displayed in **Philippine Peso (₱)**. The peso formatter is defined in `utils/theme.dart` and used throughout all screens.
