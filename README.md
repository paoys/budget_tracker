# BudgetWise

A personal finance tracker built with Flutter and Firebase. Track your income, expenses, budget, savings, and credit cards — all in one place, with cloud sync across devices.

---

## Features

- **Overview** — 6-month spending trend, payment due alerts, and recent expenses at a glance
- **Expenses** — Log and categorize spending by Needs, Wants, or Savings; supports multiple payment modes (cash, GCash, Maya, credit card, etc.)
- **Budget** — Set budget targets per category and track how much you've used
- **Savings** — Monitor savings goals and progress
- **Credit Cards** — Track card balances, statement periods, and payment due dates with correct billing cycle logic
- **Income & Setup** — Configure income sources and budget split percentages (accessible from the Budget tab)
- **Recurring** — Manage recurring transactions and templates (accessible from the Cards tab)
- **Authentication** — Email/password sign-in, registration, Google Sign-In, and password reset via Firebase Auth
- **Cloud Sync** — Data synced to Firestore per user; local persistence via SharedPreferences for offline support
- **Dark/Light mode** — Toggleable from Settings

---

## Project Structure

```
lib/
├── main.dart                    # App entry point, auth gate, navigation shell, bottom nav
├── firebase_options.dart        # Firebase configuration (generated)
├── models/
│   └── models.dart              # All data models (Expense, CreditCard, Income, etc.)
├── providers/
│   ├── app_provider.dart        # Main state management via ChangeNotifier
│   └── auth_provider.dart       # Auth state (Firebase Auth + Google Sign-In)
├── services/
│   └── firestore_service.dart   # Firestore read/write helpers
├── screens/
│   ├── login_screen.dart        # Login, registration, and password reset
│   ├── dashboard_screen.dart    # Home / Overview
│   ├── expenses_screen.dart     # Expenses list and logging
│   ├── budget_screen.dart       # Budget breakdown
│   ├── savings_screen.dart      # Savings goals
│   ├── credit_card_screen.dart  # Credit card management
│   ├── income_screen.dart       # Income & setup (pushed screen)
│   ├── recurring_screen.dart    # Recurring transactions (pushed screen)
│   └── settings_screen.dart     # App settings and sign-out
├── utils/
│   └── theme.dart               # Colors, typography, AppColors extension
└── widgets/
    └── shared_widgets.dart      # Reusable UI components
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

## Authentication

BudgetWise uses **Firebase Authentication** with the following flows:

- **Email & Password** — Sign in or register with a name, email, and password
- **Google Sign-In** — One-tap sign-in via Google (uses popup on web, native flow on mobile)
- **Password Reset** — Send a reset email from the login screen
- **Auth Gate** — The app listens to `authStateChanges()` and routes to the login screen or main shell automatically

User data in Firestore is scoped per `uid`, so each account has isolated data.

---

## Data & Sync

- **Firestore** is used as the primary cloud store. Data is read and written through `FirestoreService`.
- **SharedPreferences** provides local persistence so the app works offline.
- `AppProvider` initializes local data on startup and syncs with Firestore when a user is signed in (`initForUser(uid)`). On sign-out, local user data is cleared via `clearUser()`.
- A **sync status indicator** in the AppBar shows `Syncing`, `Synced`, or `Offline` states.

---

## Credit Card Billing Logic

Statement cut-off day and due day are configurable per card. The billing logic works as follows:

- **Previous statement** — the closed billing cycle (e.g. Feb 25 → Mar 25). Unpaid charges here are **due now**.
- **Current period** — the open billing cycle (e.g. Mar 25 → Apr 25). Charges here are **not yet due**.
- **Due date** — always the `dueDay` of the month following the statement cut-off (e.g. Apr 14 for a Mar 25 cut-off).

A transaction made on Apr 10 with a cut-off of the 25th will appear under "Current period (not yet due)" and will **not** trigger a payment alert until the next statement closes.

---

## Getting Started

### Requirements

- Flutter SDK 3.x+
- Dart 3.x+
- A Firebase project with **Authentication** and **Firestore** enabled

### Firebase Setup

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password** and **Google** sign-in methods under Authentication → Sign-in methods
3. Enable **Cloud Firestore** under Firestore Database
4. Run `flutterfire configure` to generate `firebase_options.dart`

### Run

```bash
flutter pub get
flutter run
```

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Authentication |
| `cloud_firestore` | Cloud database |
| `google_sign_in` | Google OAuth |
| `provider` | State management |
| `shared_preferences` | Local persistence |
| `google_fonts` | Plus Jakarta Sans, Inter |
| `uuid` | Unique ID generation |

---

## Recent Changes

| File | Change |
|------|--------|
| `lib/providers/auth_provider.dart` | Added Firebase Auth integration; email/password, Google Sign-In (web popup + mobile), password reset, and friendly error messages |
| `lib/services/firestore_service.dart` | New service layer for all Firestore reads and writes, scoped per user |
| `lib/providers/app_provider.dart` | Added `initForUser(uid)` and `clearUser()` for per-user cloud sync; integrated FirestoreService |
| `lib/screens/login_screen.dart` | New login screen with sign-in, registration, and password reset flows |
| `lib/main.dart` | Added `_AuthGate` to route between login and main shell based on Firebase auth state |
| `lib/models/models.dart` | Fixed credit card billing cycle logic — added `prevStatementDate`, `previousStatementTransactions`; corrected `nextDueDate` and `hasBillDue` |
| `lib/screens/credit_card_screen.dart` | Updated statement info UI to correctly show previous vs current period; fixed Pay Bill modal |
| `lib/screens/dashboard_screen.dart` | Fixed Payment Due Soon card to show correct statement date range |
| `lib/screens/income_screen.dart` | Added AppBar with back button |
| `lib/screens/recurring_screen.dart` | Added AppBar with back button |
