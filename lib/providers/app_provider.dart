// lib/providers/app_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

const _uuid = Uuid();

enum SyncStatus { idle, syncing, synced, error }

class AppProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  List<Income> _incomes = [];
  List<BudgetSubCategory> _subCategories = [];
  List<Expense> _expenses = [];
  List<BankAccount> _bankAccounts = [];
  List<CreditCard> _creditCards = [];
  List<RecurringTemplate> _recurringTemplates = [];
  List<SavingsGoal> _savingsGoals = [];

  String? _uid;
  final FirestoreService _fs = FirestoreService();
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _syncError;

  AppSettings get settings => _settings;
  List<Income> get incomes => _incomes;
  List<BudgetSubCategory> get subCategories => _subCategories;
  List<Expense> get expenses => _expenses;
  List<BankAccount> get bankAccounts => _bankAccounts;
  List<CreditCard> get creditCards => _creditCards;
  List<RecurringTemplate> get recurringTemplates => _recurringTemplates;
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  bool get isDarkMode => _settings.isDarkMode;
  SyncStatus get syncStatus => _syncStatus;
  String? get syncError => _syncError;
  bool get isSignedIn => _uid != null;

  /// Incomes that belong to a given month (year+month).
  List<Income> incomesForMonth(int year, int month) =>
      _incomes.where((i) => i.date.year == year && i.date.month == month).toList();

  /// Current-month incomes — used for the active budget.
  List<Income> get currentMonthIncomes {
    final now = DateTime.now();
    return incomesForMonth(now.year, now.month);
  }

  double get totalIncome => currentMonthIncomes.fold(0.0, (s, i) => s + i.amount);
  double get needsBudget => totalIncome * _settings.needsPercent / 100;
  double get wantsBudget => totalIncome * _settings.wantsPercent / 100;
  double get savingsBudget => totalIncome * _settings.savingsPercent / 100;
  double get totalNeedsSpent   => _expensesByCategory(CategoryType.needs);
  double get totalWantsSpent   => _expensesByCategory(CategoryType.wants);
  double get totalSavingsSpent => _expensesByCategory(CategoryType.savings);
  double get totalSpent     => totalNeedsSpent + totalWantsSpent + totalSavingsSpent;
  double get remainingNeeds    => needsBudget - totalNeedsSpent;
  double get remainingWants    => wantsBudget - totalWantsSpent;
  double get remainingSavings  => savingsBudget - totalSavingsSpent;
  double get remainingTotal    => totalIncome - totalSpent;

  /// Current-month expenses — source of truth for all budget/spent calculations.
  List<Expense> get currentMonthExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
  }

  double _expensesByCategory(CategoryType cat) =>
      currentMonthExpenses.where((e) => e.category == cat).fold(0.0, (s, e) => s + e.amount);
  double subCategorySpent(String id) =>
      currentMonthExpenses.where((e) => e.subCategoryId == id).fold(0.0, (s, e) => s + e.amount);
  double subCategoryBudget(String id) => _subCategories.firstWhere(
      (s) => s.id == id,
      orElse: () => BudgetSubCategory(id: '', name: '', budgetAmount: 0, category: CategoryType.needs)).budgetAmount;
  List<BudgetSubCategory> subCategoriesByType(CategoryType t) =>
      _subCategories.where((s) => s.category == t).toList();
  double totalSubBudgetByType(CategoryType t) =>
      subCategoriesByType(t).fold(0.0, (s, sc) => s + sc.budgetAmount);
  List<CreditCard> get cardsDueSoon =>
      _creditCards.where((c) => c.hasBillDue).toList();
  List<RecurringTemplate> get overdueRecurring =>
      _recurringTemplates.where((t) => t.isActive && t.isDue).toList();

  // ─── INIT ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _loadFromPrefs(prefs);
    notifyListeners();
  }

  Future<void> initForUser(String uid) async {
    // Guard: skip only if already fully synced for the exact same uid.
    // A different uid always triggers a full reload (clearUser was called first).
    if (_uid == uid && _syncStatus == SyncStatus.synced) return;

    _uid = uid;
    _setSyncing();
    notifyListeners();

    try {
      // Load local cache first so UI is not blank while waiting for Firestore
      final prefs = await SharedPreferences.getInstance();
      _loadFromPrefs(prefs);
      notifyListeners();

      final remote = await _fs.fetchAllUserData(uid);

      if (_hasRemoteData(remote)) {
        _applyRemoteData(remote);
        await _saveToPrefs();
      } else {
        // First login — push local data up to Firestore
        await _pushAllToFirestore(uid);
      }

      _setSynced();
    } catch (e, st) {
      debugPrint('initForUser error: $e\n$st');
      _setSyncError('Sync failed: ${e.toString()}');
    }

    notifyListeners();
  }

  /// Wipes only the SharedPreferences cache (not in-memory state).
  Future<void> clearLocalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('settings');
    await prefs.remove('incomes');
    await prefs.remove('subCategories');
    await prefs.remove('expenses');
    await prefs.remove('bankAccounts');
    await prefs.remove('creditCards');
    await prefs.remove('recurringTemplates');
    await prefs.remove('savingsGoals');
  }

  Future<void> clearUser() async {
    _uid = null;
    _syncStatus = SyncStatus.idle;
    _syncError = null;

    // Reset all in-memory data so it doesn't bleed into the next account
    _settings = AppSettings();
    _incomes = [];
    _subCategories = [];
    _expenses = [];
    _bankAccounts = [];
    _creditCards = [];
    _recurringTemplates = [];
    _savingsGoals = [];

    // Wipe the local cache so the next login starts clean from Firestore
    await clearLocalPrefs();

    notifyListeners();
  }

  bool _hasRemoteData(UserData r) =>
      r.incomes.isNotEmpty || r.expenses.isNotEmpty ||
      r.creditCards.isNotEmpty || r.subCategories.isNotEmpty;

  void _applyRemoteData(UserData r) {
    if (r.settings != null) _settings = r.settings!;
    _incomes            = r.incomes;
    _subCategories      = r.subCategories;
    _expenses           = r.expenses;
    _bankAccounts       = r.bankAccounts;
    _creditCards        = r.creditCards;
    _recurringTemplates = r.recurringTemplates;
    _savingsGoals       = r.savingsGoals;
  }

  /// Full authoritative push: clears every Firestore collection for this user
  /// then writes exactly what is in memory. This means push = "my device wins".
  Future<void> _pushAllToFirestore(String uid) async {
    // 1. Delete all existing remote docs so stale entries don't linger
    await _fs.deleteAllUserData(uid);
    // 2. Write current in-memory state
    await _fs.saveSettings(uid, _settings);
    for (final i in _incomes)            await _fs.saveIncome(uid, i);
    for (final s in _subCategories)      await _fs.saveSubCategory(uid, s);
    for (final e in _expenses)           await _fs.saveExpense(uid, e);
    for (final b in _bankAccounts)       await _fs.saveBankAccount(uid, b);
    for (final c in _creditCards)        await _fs.saveCreditCard(uid, c);
    for (final r in _recurringTemplates) await _fs.saveRecurringTemplate(uid, r);
    for (final g in _savingsGoals)       await _fs.saveSavingsGoal(uid, g);
  }

  void _setSyncing() { _syncStatus = SyncStatus.syncing; _syncError = null; }
  void _setSynced()  { _syncStatus = SyncStatus.synced;  _syncError = null; }
  void _setSyncError(String msg) { _syncStatus = SyncStatus.error; _syncError = msg; }

  void _loadFromPrefs(SharedPreferences prefs) {
    final sr = prefs.getString('settings');
    if (sr != null) {
      try { _settings = AppSettings.fromJson(json.decode(sr) as Map<String, dynamic>); } catch (_) {}
    }
    void load<T>(String key, T Function(Map<String, dynamic>) fn, void Function(List<T>) set) {
      final raw = prefs.getString(key);
      if (raw == null) return;
      try {
        set((json.decode(raw) as List).map((e) => fn(e as Map<String, dynamic>)).toList());
      } catch (_) {}
    }
    load('incomes',            Income.fromJson,            (v) => _incomes = v);
    load('subCategories',      BudgetSubCategory.fromJson, (v) => _subCategories = v);
    load('expenses',           Expense.fromJson,           (v) => _expenses = v);
    load('bankAccounts',       BankAccount.fromJson,       (v) => _bankAccounts = v);
    load('creditCards',        CreditCard.fromJson,        (v) => _creditCards = v);
    load('recurringTemplates', RecurringTemplate.fromJson, (v) => _recurringTemplates = v);
    load('savingsGoals',       SavingsGoal.fromJson,       (v) => _savingsGoals = v);
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings',           json.encode(_settings.toJson()));
    await prefs.setString('incomes',            json.encode(_incomes.map((e) => e.toJson()).toList()));
    await prefs.setString('subCategories',      json.encode(_subCategories.map((e) => e.toJson()).toList()));
    await prefs.setString('expenses',           json.encode(_expenses.map((e) => e.toJson()).toList()));
    await prefs.setString('bankAccounts',       json.encode(_bankAccounts.map((e) => e.toJson()).toList()));
    await prefs.setString('creditCards',        json.encode(_creditCards.map((e) => e.toJson()).toList()));
    await prefs.setString('savingsGoals',        json.encode(_savingsGoals.map((e) => e.toJson()).toList()));
    await prefs.setString('recurringTemplates', json.encode(_recurringTemplates.map((e) => e.toJson()).toList()));
  }

  Future<void> _save() => _saveToPrefs();

  /// Fire-and-forget cloud write. Catches and logs errors without crashing.
  Future<void> _cloud(Future<void> Function(String uid) op) async {
    final uid = _uid;
    if (uid == null) return; // Not signed in — offline mode, skip silently
    try {
      await op(uid);
      if (_syncStatus != SyncStatus.syncing) {
        _setSynced();
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('Firestore write error: $e\n$st');
      _setSyncError('Sync failed');
      notifyListeners();
    }
  }

  // ─── SETTINGS ─────────────────────────────────────────────────────────────
  Future<void> updateSettings(AppSettings s) async {
    _settings = s;
    await _save();
    await _cloud((uid) => _fs.saveSettings(uid, s));
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _settings.isDarkMode = !_settings.isDarkMode;
    await _save();
    await _cloud((uid) => _fs.saveSettings(uid, _settings));
    notifyListeners();
  }

  // ─── INCOME ───────────────────────────────────────────────────────────────
  Future<void> addIncome(Income i) async {
    _incomes.add(i);
    await _save();
    await _cloud((uid) => _fs.saveIncome(uid, i));
    notifyListeners();
  }

  Future<void> deleteIncome(String id) async {
    _incomes.removeWhere((i) => i.id == id);
    await _save();
    await _cloud((uid) => _fs.deleteIncome(uid, id));
    notifyListeners();
  }

  // ─── SUBCATEGORIES ────────────────────────────────────────────────────────
  Future<void> addSubCategory(BudgetSubCategory s) async {
    _subCategories.add(s);
    await _save();
    await _cloud((uid) => _fs.saveSubCategory(uid, s));
    notifyListeners();
  }

  Future<void> updateSubCategory(BudgetSubCategory s) async {
    final idx = _subCategories.indexWhere((x) => x.id == s.id);
    if (idx >= 0) {
      _subCategories[idx] = s;
      await _save();
      await _cloud((uid) => _fs.saveSubCategory(uid, s));
      notifyListeners();
    }
  }

  Future<void> deleteSubCategory(String id) async {
    _subCategories.removeWhere((s) => s.id == id);
    await _save();
    await _cloud((uid) => _fs.deleteSubCategory(uid, id));
    notifyListeners();
  }

  // ─── EXPENSES ─────────────────────────────────────────────────────────────
  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    if (expense.paymentMode == PaymentMode.creditCard && expense.creditCardId != null) {
      final i = _creditCards.indexWhere((c) => c.id == expense.creditCardId);
      if (i >= 0) {
        _creditCards[i].balance += expense.amount;
        _creditCards[i].transactions.add(CreditCardTransaction(
          id: expense.id,  // Use expense ID so deleteExpense can match exactly
          description: expense.title,
          amount: expense.amount, date: expense.date,
        ));
        _creditCards[i].transactions.sort((a, b) => b.date.compareTo(a.date));
        await _cloud((uid) => _fs.saveCreditCard(uid, _creditCards[i]));
      }
    }
    await _save();
    await _cloud((uid) => _fs.saveExpense(uid, expense));
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    final e = _expenses.firstWhere(
      (x) => x.id == id,
      orElse: () => Expense(id: '', title: '', amount: 0, category: CategoryType.needs, paymentMode: PaymentMode.cash, date: DateTime.now()),
    );
    if (e.id.isNotEmpty && e.paymentMode == PaymentMode.creditCard && e.creditCardId != null) {
      final i = _creditCards.indexWhere((c) => c.id == e.creditCardId);
      if (i >= 0) {
        // Match CC transaction by expense ID stored as the transaction id (set in addExpense),
        // falling back to description+amount+date match to handle legacy entries.
        final removed = _creditCards[i].transactions.any((t) => t.id == id);
        if (removed) {
          final tx = _creditCards[i].transactions.firstWhere((t) => t.id == id);
          if (!tx.isPaid) _creditCards[i].balance -= tx.amount;
          _creditCards[i].transactions.removeWhere((t) => t.id == id);
        } else {
          // Legacy fallback: match by date+amount (more precise than description+amount)
          final txIdx = _creditCards[i].transactions.indexWhere(
            (t) => t.amount == e.amount &&
                   t.date.year == e.date.year &&
                   t.date.month == e.date.month &&
                   t.date.day == e.date.day &&
                   !t.isPaid,
          );
          if (txIdx >= 0) {
            _creditCards[i].balance -= _creditCards[i].transactions[txIdx].amount;
            _creditCards[i].transactions.removeAt(txIdx);
          }
        }
        await _cloud((uid) => _fs.saveCreditCard(uid, _creditCards[i]));
      }
    }
    _expenses.removeWhere((x) => x.id == id);
    await _save();
    await _cloud((uid) => _fs.deleteExpense(uid, id));
    notifyListeners();
  }

  // ─── BANK ACCOUNTS ────────────────────────────────────────────────────────
  Future<void> addBankAccount(BankAccount a) async {
    _bankAccounts.add(a);
    await _save();
    await _cloud((uid) => _fs.saveBankAccount(uid, a));
    notifyListeners();
  }

  Future<void> deleteBankAccount(String id) async {
    _bankAccounts.removeWhere((a) => a.id == id);
    await _save();
    await _cloud((uid) => _fs.deleteBankAccount(uid, id));
    notifyListeners();
  }

  Future<void> addBankTransaction(String accountId, BankTransaction tx) async {
    final i = _bankAccounts.indexWhere((a) => a.id == accountId);
    if (i >= 0) {
      _bankAccounts[i].balance += tx.amount;
      _bankAccounts[i].transactions.insert(0, tx);
      await _save();
      await _cloud((uid) => _fs.saveBankAccount(uid, _bankAccounts[i]));
      notifyListeners();
    }
  }

  // ─── CREDIT CARDS ─────────────────────────────────────────────────────────
  Future<void> addCreditCard(CreditCard c) async {
    _creditCards.add(c);
    await _save();
    await _cloud((uid) => _fs.saveCreditCard(uid, c));
    notifyListeners();
  }

  Future<void> deleteCreditCard(String id) async {
    _creditCards.removeWhere((c) => c.id == id);
    await _save();
    await _cloud((uid) => _fs.deleteCreditCard(uid, id));
    notifyListeners();
  }

  Future<void> addCreditCardTransaction(String cardId, CreditCardTransaction tx) async {
    final i = _creditCards.indexWhere((c) => c.id == cardId);
    if (i >= 0) {
      _creditCards[i].balance += tx.amount;
      _creditCards[i].transactions.add(tx);
      _creditCards[i].transactions.sort((a, b) => b.date.compareTo(a.date));
      await _save();
      await _cloud((uid) => _fs.saveCreditCard(uid, _creditCards[i]));
      notifyListeners();
    }
  }

  Future<void> markCreditCardPaid(String cardId, String txId) async {
    final i = _creditCards.indexWhere((c) => c.id == cardId);
    if (i >= 0) {
      final ti = _creditCards[i].transactions.indexWhere((t) => t.id == txId);
      if (ti >= 0) {
        _creditCards[i].transactions[ti].isPaid = true;
        _creditCards[i].balance -= _creditCards[i].transactions[ti].amount;
        _creditCards[i].transactions.sort((a, b) => b.date.compareTo(a.date));
        await _save();
        await _cloud((uid) => _fs.saveCreditCard(uid, _creditCards[i]));
        notifyListeners();
      }
    }
  }

  Future<void> deleteCreditCardTransaction(String cardId, String txId) async {
    final i = _creditCards.indexWhere((c) => c.id == cardId);
    if (i >= 0) {
      final ti = _creditCards[i].transactions.indexWhere((t) => t.id == txId);
      if (ti >= 0) {
        final tx = _creditCards[i].transactions[ti];
        if (!tx.isPaid) _creditCards[i].balance -= tx.amount;
        _creditCards[i].transactions.removeAt(ti);
        await _save();
        await _cloud((uid) => _fs.saveCreditCard(uid, _creditCards[i]));
        notifyListeners();
      }
    }
  }

  // ─── RECURRING ────────────────────────────────────────────────────────────
  Future<void> addRecurringTemplate(RecurringTemplate t) async {
    _recurringTemplates.add(t);
    await _save();
    await _cloud((uid) => _fs.saveRecurringTemplate(uid, t));
    notifyListeners();
  }

  Future<void> updateRecurringTemplate(RecurringTemplate t) async {
    final i = _recurringTemplates.indexWhere((r) => r.id == t.id);
    if (i >= 0) {
      _recurringTemplates[i] = t;
      await _save();
      await _cloud((uid) => _fs.saveRecurringTemplate(uid, t));
      notifyListeners();
    }
  }

  Future<void> deleteRecurringTemplate(String id) async {
    _recurringTemplates.removeWhere((t) => t.id == id);
    await _save();
    await _cloud((uid) => _fs.deleteRecurringTemplate(uid, id));
    notifyListeners();
  }

  Future<void> processRecurringTemplate(String templateId) async {
    final i = _recurringTemplates.indexWhere((t) => t.id == templateId);
    if (i < 0) return;
    final t = _recurringTemplates[i];
    final now = DateTime.now();
    final expense = Expense(
      id: _uuid.v4(), title: t.title, amount: t.amount,
      category: t.category, subCategoryId: t.subCategoryId,
      paymentMode: t.paymentMode, date: now, notes: t.notes,
      creditCardId: t.creditCardId, isRecurring: true,
      recurringFrequency: t.frequency, recurringGroupId: t.id,
    );
    await addExpense(expense);
    _recurringTemplates[i].lastProcessed = now;
    await _save();
    await _cloud((uid) => _fs.saveRecurringTemplate(uid, _recurringTemplates[i]));
    notifyListeners();
  }

  Future<void> skipRecurringTemplate(String templateId) async {
    final i = _recurringTemplates.indexWhere((t) => t.id == templateId);
    if (i >= 0) {
      _recurringTemplates[i].lastProcessed = DateTime.now();
      await _save();
      await _cloud((uid) => _fs.saveRecurringTemplate(uid, _recurringTemplates[i]));
      notifyListeners();
    }
  }

  Future<void> syncNow() async {
    final uid = _uid;
    if (uid == null) return;
    _setSyncing();
    notifyListeners();
    try {
      await _pushAllToFirestore(uid);
      _setSynced();
    } catch (e) {
      _setSyncError(e.toString());
    }
    notifyListeners();
  }

  Future<void> pullFromCloud() async {
    final uid = _uid;
    if (uid == null) return;
    _setSyncing();
    notifyListeners();
    try {
      final remote = await _fs.fetchAllUserData(uid);
      // Apply remote data — this fully replaces in-memory state
      _applyRemoteData(remote);
      // Wipe local prefs and write the fresh remote state so nothing stale lingers
      await clearLocalPrefs();
      await _saveToPrefs();
      _setSynced();
    } catch (e) {
      _setSyncError(e.toString());
    }
    notifyListeners();
  }

  String newId() => _uuid.v4();

  // ─── SAVINGS GOALS ────────────────────────────────────────────────────────

  /// Total amount contributed across all active goals.
  double get totalGoalsSaved =>
      _savingsGoals.fold(0.0, (s, g) => s + g.savedAmount);

  /// Goals with an upcoming deadline (within 30 days, not completed).
  List<SavingsGoal> get goalsNearingDeadline {
    final cutoff = DateTime.now().add(const Duration(days: 30));
    return _savingsGoals
        .where((g) => !g.isCompleted && g.targetDate != null && g.targetDate!.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.targetDate!.compareTo(b.targetDate!));
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    _savingsGoals.add(goal);
    await _save();
    await _cloud((uid) => _fs.saveSavingsGoal(uid, goal));
    notifyListeners();
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    final idx = _savingsGoals.indexWhere((g) => g.id == goal.id);
    if (idx >= 0) {
      _savingsGoals[idx] = goal;
      await _save();
      await _cloud((uid) => _fs.saveSavingsGoal(uid, goal));
      notifyListeners();
    }
  }

  Future<void> deleteSavingsGoal(String id) async {
    _savingsGoals.removeWhere((g) => g.id == id);
    await _save();
    await _cloud((uid) => _fs.deleteSavingsGoal(uid, id));
    notifyListeners();
  }

  /// Add a contribution to a goal. Optionally also logs a BankTransaction
  /// if [fromAccountId] is provided (deduct from account balance).
  Future<void> contributeToGoal({
    required String goalId,
    required double amount,
    required String note,
    String? fromAccountId,
  }) async {
    final idx = _savingsGoals.indexWhere((g) => g.id == goalId);
    if (idx < 0) return;

    // Add contribution record
    final contrib = GoalContribution(
      id: newId(),
      goalId: goalId,
      amount: amount,
      note: note,
      date: DateTime.now(),
    );
    _savingsGoals[idx].contributions.insert(0, contrib);
    _savingsGoals[idx].savedAmount =
        (_savingsGoals[idx].savedAmount + amount).clamp(0.0, double.infinity);

    // Auto-complete if target reached
    if (_savingsGoals[idx].savedAmount >= _savingsGoals[idx].targetAmount) {
      _savingsGoals[idx].isCompleted = true;
    }

    // Optionally deduct from linked bank account
    if (fromAccountId != null) {
      final accIdx = _bankAccounts.indexWhere((a) => a.id == fromAccountId);
      if (accIdx >= 0) {
        _bankAccounts[accIdx].balance -= amount;
        _bankAccounts[accIdx].transactions.insert(
          0,
          BankTransaction(
            id: newId(),
            description: 'Savings: ${_savingsGoals[idx].name}',
            amount: -amount,
            date: DateTime.now(),
          ),
        );
        await _cloud((uid) => _fs.saveBankAccount(uid, _bankAccounts[accIdx]));
      }
    }

    await _save();
    await _cloud((uid) => _fs.saveSavingsGoal(uid, _savingsGoals[idx]));
    notifyListeners();
  }

  /// Withdraw from a goal (e.g. goal cancelled, or funds redirected).
  Future<void> withdrawFromGoal({
    required String goalId,
    required double amount,
    required String note,
    String? toAccountId,
  }) async {
    final idx = _savingsGoals.indexWhere((g) => g.id == goalId);
    if (idx < 0) return;

    final actual = amount.clamp(0.0, _savingsGoals[idx].savedAmount);
    final contrib = GoalContribution(
      id: newId(),
      goalId: goalId,
      amount: -actual,
      note: note.isEmpty ? 'Withdrawal' : note,
      date: DateTime.now(),
    );
    _savingsGoals[idx].contributions.insert(0, contrib);
    _savingsGoals[idx].savedAmount -= actual;
    if (_savingsGoals[idx].savedAmount < _savingsGoals[idx].targetAmount) {
      _savingsGoals[idx].isCompleted = false;
    }

    if (toAccountId != null) {
      final accIdx = _bankAccounts.indexWhere((a) => a.id == toAccountId);
      if (accIdx >= 0) {
        _bankAccounts[accIdx].balance += actual;
        _bankAccounts[accIdx].transactions.insert(
          0,
          BankTransaction(
            id: newId(),
            description: 'From goal: ${_savingsGoals[idx].name}',
            amount: actual,
            date: DateTime.now(),
          ),
        );
        await _cloud((uid) => _fs.saveBankAccount(uid, _bankAccounts[accIdx]));
      }
    }

    await _save();
    await _cloud((uid) => _fs.saveSavingsGoal(uid, _savingsGoals[idx]));
    notifyListeners();
  }

}