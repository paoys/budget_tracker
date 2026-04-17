// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference _settingsDoc(String uid) =>
      _db.collection('users').doc(uid).collection('data').doc('settings');

  CollectionReference _col(String uid, String name) =>
      _db.collection('users').doc(uid).collection(name);

  // ── Settings ───────────────────────────────────────────────────────────────
  Future<void> saveSettings(String uid, AppSettings s) =>
      _settingsDoc(uid).set(s.toJson());

  Future<AppSettings?> fetchSettings(String uid) async {
    final doc = await _settingsDoc(uid).get();
    if (!doc.exists) return null;
    return AppSettings.fromJson(doc.data()! as Map<String, dynamic>);
  }

  // ── Generic helpers ────────────────────────────────────────────────────────
  Future<void> upsert(String uid, String col, String id, Map<String, dynamic> data) =>
      _col(uid, col).doc(id).set(data);

  Future<void> remove(String uid, String col, String id) =>
      _col(uid, col).doc(id).delete();

  Future<List<Map<String, dynamic>>> fetchAll(String uid, String col) async {
    final snap = await _col(uid, col).get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  // ── Typed fetch helpers ────────────────────────────────────────────────────
  Future<List<T>> _fetch<T>(String uid, String col, T Function(Map<String, dynamic>) fromJson) async {
    final rows = await fetchAll(uid, col);
    return rows.map(fromJson).toList();
  }

  // ── Incomes ────────────────────────────────────────────────────────────────
  Future<void> saveIncome(String uid, Income i)    => upsert(uid, 'incomes', i.id, i.toJson());
  Future<void> deleteIncome(String uid, String id) => remove(uid, 'incomes', id);
  Future<List<Income>> fetchIncomes(String uid)    => _fetch(uid, 'incomes', Income.fromJson);

  // ── Sub-categories ─────────────────────────────────────────────────────────
  Future<void> saveSubCategory(String uid, BudgetSubCategory s)  => upsert(uid, 'subCategories', s.id, s.toJson());
  Future<void> deleteSubCategory(String uid, String id)           => remove(uid, 'subCategories', id);
  Future<List<BudgetSubCategory>> fetchSubCategories(String uid)  => _fetch(uid, 'subCategories', BudgetSubCategory.fromJson);

  // ── Expenses ───────────────────────────────────────────────────────────────
  Future<void> saveExpense(String uid, Expense e)    => upsert(uid, 'expenses', e.id, e.toJson());
  Future<void> deleteExpense(String uid, String id)  => remove(uid, 'expenses', id);
  Future<List<Expense>> fetchExpenses(String uid)    => _fetch(uid, 'expenses', Expense.fromJson);

  // ── Bank Accounts ──────────────────────────────────────────────────────────
  Future<void> saveBankAccount(String uid, BankAccount a)   => upsert(uid, 'bankAccounts', a.id, a.toJson());
  Future<void> deleteBankAccount(String uid, String id)     => remove(uid, 'bankAccounts', id);
  Future<List<BankAccount>> fetchBankAccounts(String uid)   => _fetch(uid, 'bankAccounts', BankAccount.fromJson);

  // ── Credit Cards ───────────────────────────────────────────────────────────
  Future<void> saveCreditCard(String uid, CreditCard c)   => upsert(uid, 'creditCards', c.id, c.toJson());
  Future<void> deleteCreditCard(String uid, String id)    => remove(uid, 'creditCards', id);
  Future<List<CreditCard>> fetchCreditCards(String uid)   => _fetch(uid, 'creditCards', CreditCard.fromJson);

  // ── Recurring Templates ────────────────────────────────────────────────────
  Future<void> saveRecurringTemplate(String uid, RecurringTemplate t) => upsert(uid, 'recurringTemplates', t.id, t.toJson());
  Future<void> deleteRecurringTemplate(String uid, String id)          => remove(uid, 'recurringTemplates', id);
  Future<List<RecurringTemplate>> fetchRecurringTemplates(String uid)  => _fetch(uid, 'recurringTemplates', RecurringTemplate.fromJson);

  // ── Full user data fetch ────────────────────────────────────────────────────
  Future<UserData> fetchAllUserData(String uid) async {
    final settings           = await fetchSettings(uid);
    final incomes            = await fetchIncomes(uid);
    final subCategories      = await fetchSubCategories(uid);
    final expenses           = await fetchExpenses(uid);
    final bankAccounts       = await fetchBankAccounts(uid);
    final creditCards        = await fetchCreditCards(uid);
    final recurringTemplates = await fetchRecurringTemplates(uid);
    final savingsGoals       = await fetchSavingsGoals(uid);

    return UserData(
      settings:           settings,
      incomes:            incomes,
      subCategories:      subCategories,
      expenses:           expenses,
      bankAccounts:       bankAccounts,
      creditCards:        creditCards,
      recurringTemplates: recurringTemplates,
      savingsGoals:       savingsGoals,
    );
  }

  // ── Savings Goals ──────────────────────────────────────────────────────────
  Future<void> saveSavingsGoal(String uid, SavingsGoal g)  => upsert(uid, 'savings_goals', g.id, g.toJson());
  Future<void> deleteSavingsGoal(String uid, String id)    => remove(uid, 'savings_goals', id);
  Future<List<SavingsGoal>> fetchSavingsGoals(String uid)  => _fetch(uid, 'savings_goals', SavingsGoal.fromJson);
}

class UserData {
  final AppSettings? settings;
  final List<Income> incomes;
  final List<BudgetSubCategory> subCategories;
  final List<Expense> expenses;
  final List<BankAccount> bankAccounts;
  final List<CreditCard> creditCards;
  final List<RecurringTemplate> recurringTemplates;
  final List<SavingsGoal> savingsGoals;

  const UserData({
    this.settings,
    required this.incomes,
    required this.subCategories,
    required this.expenses,
    required this.bankAccounts,
    required this.creditCards,
    required this.recurringTemplates,
    required this.savingsGoals,
  });
}
