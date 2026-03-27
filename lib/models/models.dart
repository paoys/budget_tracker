// lib/models/models.dart

enum IncomeMode { monthly, cutoff }
enum CategoryType { needs, wants, savings }
enum PaymentMode { cash, creditCard, debitCard, gcash, maya, bankTransfer, other }

class AppSettings {
  double needsPercent;
  double wantsPercent;
  double savingsPercent;
  IncomeMode incomeMode;
  bool isDarkMode;

  AppSettings({
    this.needsPercent = 50,
    this.wantsPercent = 30,
    this.savingsPercent = 20,
    this.incomeMode = IncomeMode.monthly,
    this.isDarkMode = true,
  });

  Map<String, dynamic> toJson() => {
    'needsPercent': needsPercent,
    'wantsPercent': wantsPercent,
    'savingsPercent': savingsPercent,
    'incomeMode': incomeMode.index,
    'isDarkMode': isDarkMode,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    needsPercent: (json['needsPercent'] as num?)?.toDouble() ?? 50,
    wantsPercent: (json['wantsPercent'] as num?)?.toDouble() ?? 30,
    savingsPercent: (json['savingsPercent'] as num?)?.toDouble() ?? 20,
    incomeMode: IncomeMode.values[json['incomeMode'] as int? ?? 0],
    isDarkMode: json['isDarkMode'] as bool? ?? true,
  );
}

class Income {
  final String id;
  double amount;
  String label;
  IncomeMode mode;
  int? cutoffPeriod; // 1 = first half (1-15), 2 = second half (16-end)
  DateTime date;

  Income({
    required this.id,
    required this.amount,
    required this.label,
    required this.mode,
    this.cutoffPeriod,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'label': label,
    'mode': mode.index,
    'cutoffPeriod': cutoffPeriod,
    'date': date.toIso8601String(),
  };

  factory Income.fromJson(Map<String, dynamic> json) => Income(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    label: json['label'] as String,
    mode: IncomeMode.values[json['mode'] as int? ?? 0],
    cutoffPeriod: json['cutoffPeriod'] as int?,
    date: DateTime.parse(json['date'] as String),
  );
}

class BudgetSubCategory {
  final String id;
  String name;
  double budgetAmount;
  CategoryType category;

  BudgetSubCategory({
    required this.id,
    required this.name,
    required this.budgetAmount,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'budgetAmount': budgetAmount,
    'category': category.index,
  };

  factory BudgetSubCategory.fromJson(Map<String, dynamic> json) => BudgetSubCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    budgetAmount: (json['budgetAmount'] as num).toDouble(),
    category: CategoryType.values[json['category'] as int],
  );
}

class Expense {
  final String id;
  String title;
  double amount;
  CategoryType category;
  String? subCategoryId;
  PaymentMode paymentMode;
  DateTime date;
  String? notes;
  String? creditCardId;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.subCategoryId,
    required this.paymentMode,
    required this.date,
    this.notes,
    this.creditCardId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category.index,
    'subCategoryId': subCategoryId,
    'paymentMode': paymentMode.index,
    'date': date.toIso8601String(),
    'notes': notes,
    'creditCardId': creditCardId,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: CategoryType.values[json['category'] as int],
    subCategoryId: json['subCategoryId'] as String?,
    paymentMode: PaymentMode.values[json['paymentMode'] as int? ?? 0],
    date: DateTime.parse(json['date'] as String),
    notes: json['notes'] as String?,
    creditCardId: json['creditCardId'] as String?,
  );
}

class BankAccount {
  final String id;
  String name;
  String bankName;
  double balance;
  List<BankTransaction> transactions;

  BankAccount({
    required this.id,
    required this.name,
    required this.bankName,
    required this.balance,
    List<BankTransaction>? transactions,
  }) : transactions = transactions ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bankName': bankName,
    'balance': balance,
    'transactions': transactions.map((t) => t.toJson()).toList(),
  };

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
    id: json['id'] as String,
    name: json['name'] as String,
    bankName: json['bankName'] as String,
    balance: (json['balance'] as num).toDouble(),
    transactions: (json['transactions'] as List<dynamic>?)
        ?.map((t) => BankTransaction.fromJson(t as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class BankTransaction {
  final String id;
  String description;
  double amount; // positive = in, negative = out
  DateTime date;

  BankTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory BankTransaction.fromJson(Map<String, dynamic> json) => BankTransaction(
    id: json['id'] as String,
    description: json['description'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
  );
}

class CreditCard {
  final String id;
  String name;
  String bank;
  double creditLimit;
  double balance; // current outstanding balance
  int statementDay; // day of month when statement cuts
  int dueDay; // day of month payment is due
  List<CreditCardTransaction> transactions;

  CreditCard({
    required this.id,
    required this.name,
    required this.bank,
    required this.creditLimit,
    required this.balance,
    required this.statementDay,
    required this.dueDay,
    List<CreditCardTransaction>? transactions,
  }) : transactions = transactions ?? [];

  double get availableCredit => creditLimit - balance;

  DateTime get nextDueDate {
    final now = DateTime.now();
    DateTime due = DateTime(now.year, now.month, dueDay);
    if (due.isBefore(now)) {
      due = DateTime(now.year, now.month + 1, dueDay);
    }
    return due;
  }

  int get daysUntilDue {
    return nextDueDate.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bank': bank,
    'creditLimit': creditLimit,
    'balance': balance,
    'statementDay': statementDay,
    'dueDay': dueDay,
    'transactions': transactions.map((t) => t.toJson()).toList(),
  };

  factory CreditCard.fromJson(Map<String, dynamic> json) => CreditCard(
    id: json['id'] as String,
    name: json['name'] as String,
    bank: json['bank'] as String,
    creditLimit: (json['creditLimit'] as num).toDouble(),
    balance: (json['balance'] as num).toDouble(),
    statementDay: json['statementDay'] as int? ?? 25,
    dueDay: json['dueDay'] as int? ?? 20,
    transactions: (json['transactions'] as List<dynamic>?)
        ?.map((t) => CreditCardTransaction.fromJson(t as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class CreditCardTransaction {
  final String id;
  String description;
  double amount;
  DateTime date;
  bool isPaid;

  CreditCardTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'isPaid': isPaid,
  };

  factory CreditCardTransaction.fromJson(Map<String, dynamic> json) => CreditCardTransaction(
    id: json['id'] as String,
    description: json['description'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    isPaid: json['isPaid'] as bool? ?? false,
  );
}
