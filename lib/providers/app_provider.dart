// lib/providers/app_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  List<Income> _incomes = [];
  List<BudgetSubCategory> _subCategories = [];
  List<Expense> _expenses = [];
  List<BankAccount> _bankAccounts = [];
  List<CreditCard> _creditCards = [];

  AppSettings get settings => _settings;
  List<Income> get incomes => _incomes;
  List<BudgetSubCategory> get subCategories => _subCategories;
  List<Expense> get expenses => _expenses;
  List<BankAccount> get bankAccounts => _bankAccounts;
  List<CreditCard> get creditCards => _creditCards;

  bool get isDarkMode => _settings.isDarkMode;

  // ─── TOTALS ───────────────────────────────────────────────────────────────
  double get totalIncome {
    return _incomes.fold(0, (sum, i) => sum + i.amount);
  }

  double get needsBudget => totalIncome * _settings.needsPercent / 100;
  double get wantsBudget => totalIncome * _settings.wantsPercent / 100;
  double get savingsBudget => totalIncome * _settings.savingsPercent / 100;

  double get totalNeedsSpent => _expensesByCategory(CategoryType.needs);
  double get totalWantsSpent => _expensesByCategory(CategoryType.wants);
  double get totalSavingsSpent => _expensesByCategory(CategoryType.savings);
  double get totalSpent => totalNeedsSpent + totalWantsSpent + totalSavingsSpent;

  double get remainingNeeds => needsBudget - totalNeedsSpent;
  double get remainingWants => wantsBudget - totalWantsSpent;
  double get remainingSavings => savingsBudget - totalSavingsSpent;
  double get remainingTotal => totalIncome - totalSpent;

  double _expensesByCategory(CategoryType cat) =>
      _expenses.where((e) => e.category == cat).fold(0.0, (s, e) => s + e.amount);

  double subCategorySpent(String subCategoryId) =>
      _expenses.where((e) => e.subCategoryId == subCategoryId).fold(0.0, (s, e) => s + e.amount);

  double subCategoryBudget(String subCategoryId) {
    final sub = _subCategories.firstWhere((s) => s.id == subCategoryId, orElse: () => BudgetSubCategory(id: '', name: '', budgetAmount: 0, category: CategoryType.needs));
    return sub.budgetAmount;
  }

  List<BudgetSubCategory> subCategoriesByType(CategoryType type) =>
      _subCategories.where((s) => s.category == type).toList();

  double totalSubBudgetByType(CategoryType type) =>
      subCategoriesByType(type).fold(0.0, (s, sc) => s + sc.budgetAmount);

  // ─── INIT ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _loadSettings(prefs);
    _loadIncomes(prefs);
    _loadSubCategories(prefs);
    _loadExpenses(prefs);
    _loadBankAccounts(prefs);
    _loadCreditCards(prefs);
    notifyListeners();
  }

  void _loadSettings(SharedPreferences prefs) {
    final raw = prefs.getString('settings');
    if (raw != null) {
      try { _settings = AppSettings.fromJson(json.decode(raw) as Map<String, dynamic>); } catch (_) {}
    }
  }

  void _loadIncomes(SharedPreferences prefs) {
    final raw = prefs.getString('incomes');
    if (raw != null) {
      try {
        _incomes = (json.decode(raw) as List).map((e) => Income.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
  }

  void _loadSubCategories(SharedPreferences prefs) {
    final raw = prefs.getString('subCategories');
    if (raw != null) {
      try {
        _subCategories = (json.decode(raw) as List).map((e) => BudgetSubCategory.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
  }

  void _loadExpenses(SharedPreferences prefs) {
    final raw = prefs.getString('expenses');
    if (raw != null) {
      try {
        _expenses = (json.decode(raw) as List).map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
  }

  void _loadBankAccounts(SharedPreferences prefs) {
    final raw = prefs.getString('bankAccounts');
    if (raw != null) {
      try {
        _bankAccounts = (json.decode(raw) as List).map((e) => BankAccount.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
  }

  void _loadCreditCards(SharedPreferences prefs) {
    final raw = prefs.getString('creditCards');
    if (raw != null) {
      try {
        _creditCards = (json.decode(raw) as List).map((e) => CreditCard.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings', json.encode(_settings.toJson()));
    await prefs.setString('incomes', json.encode(_incomes.map((e) => e.toJson()).toList()));
    await prefs.setString('subCategories', json.encode(_subCategories.map((e) => e.toJson()).toList()));
    await prefs.setString('expenses', json.encode(_expenses.map((e) => e.toJson()).toList()));
    await prefs.setString('bankAccounts', json.encode(_bankAccounts.map((e) => e.toJson()).toList()));
    await prefs.setString('creditCards', json.encode(_creditCards.map((e) => e.toJson()).toList()));
  }

  // ─── SETTINGS ─────────────────────────────────────────────────────────────
  Future<void> updateSettings(AppSettings s) async {
    _settings = s;
    await _save();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _settings.isDarkMode = !_settings.isDarkMode;
    await _save();
    notifyListeners();
  }

  // ─── INCOME ───────────────────────────────────────────────────────────────
  Future<void> addIncome(Income income) async {
    _incomes.add(income);
    await _save();
    notifyListeners();
  }

  Future<void> deleteIncome(String id) async {
    _incomes.removeWhere((i) => i.id == id);
    await _save();
    notifyListeners();
  }

  // ─── SUBCATEGORIES ────────────────────────────────────────────────────────
  Future<void> addSubCategory(BudgetSubCategory sub) async {
    _subCategories.add(sub);
    await _save();
    notifyListeners();
  }

  Future<void> updateSubCategory(BudgetSubCategory sub) async {
    final idx = _subCategories.indexWhere((s) => s.id == sub.id);
    if (idx >= 0) {
      _subCategories[idx] = sub;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteSubCategory(String id) async {
    _subCategories.removeWhere((s) => s.id == id);
    await _save();
    notifyListeners();
  }

  // ─── EXPENSES ─────────────────────────────────────────────────────────────
  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    // If CC payment, add to CC balance
    if (expense.paymentMode == PaymentMode.creditCard && expense.creditCardId != null) {
      final ccIdx = _creditCards.indexWhere((c) => c.id == expense.creditCardId);
      if (ccIdx >= 0) {
        _creditCards[ccIdx].balance += expense.amount;
        _creditCards[ccIdx].transactions.add(CreditCardTransaction(
          id: _uuid.v4(),
          description: expense.title,
          amount: expense.amount,
          date: expense.date,
        ));
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    final expense = _expenses.firstWhere((e) => e.id == id, orElse: () => Expense(id: '', title: '', amount: 0, category: CategoryType.needs, paymentMode: PaymentMode.cash, date: DateTime.now()));
    if (expense.id.isNotEmpty && expense.paymentMode == PaymentMode.creditCard && expense.creditCardId != null) {
      final ccIdx = _creditCards.indexWhere((c) => c.id == expense.creditCardId);
      if (ccIdx >= 0) {
        _creditCards[ccIdx].balance -= expense.amount;
        _creditCards[ccIdx].transactions.removeWhere((t) => t.description == expense.title && t.amount == expense.amount);
      }
    }
    _expenses.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  // ─── BANK ACCOUNTS ────────────────────────────────────────────────────────
  Future<void> addBankAccount(BankAccount account) async {
    _bankAccounts.add(account);
    await _save();
    notifyListeners();
  }

  Future<void> deleteBankAccount(String id) async {
    _bankAccounts.removeWhere((a) => a.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> addBankTransaction(String accountId, BankTransaction tx) async {
    final idx = _bankAccounts.indexWhere((a) => a.id == accountId);
    if (idx >= 0) {
      _bankAccounts[idx].balance += tx.amount;
      _bankAccounts[idx].transactions.insert(0, tx);
      await _save();
      notifyListeners();
    }
  }

  // ─── CREDIT CARDS ─────────────────────────────────────────────────────────
  Future<void> addCreditCard(CreditCard card) async {
    _creditCards.add(card);
    await _save();
    notifyListeners();
  }

  Future<void> deleteCreditCard(String id) async {
    _creditCards.removeWhere((c) => c.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> addCreditCardTransaction(String cardId, CreditCardTransaction tx) async {
    final idx = _creditCards.indexWhere((c) => c.id == cardId);
    if (idx >= 0) {
      _creditCards[idx].balance += tx.amount;
      _creditCards[idx].transactions.insert(0, tx);
      await _save();
      notifyListeners();
    }
  }

  Future<void> markCreditCardPaid(String cardId, String txId) async {
    final idx = _creditCards.indexWhere((c) => c.id == cardId);
    if (idx >= 0) {
      final txIdx = _creditCards[idx].transactions.indexWhere((t) => t.id == txId);
      if (txIdx >= 0) {
        _creditCards[idx].transactions[txIdx].isPaid = true;
        _creditCards[idx].balance -= _creditCards[idx].transactions[txIdx].amount;
        await _save();
        notifyListeners();
      }
    }
  }

  String newId() => _uuid.v4();
}
