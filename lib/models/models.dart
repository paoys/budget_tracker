// lib/models/models.dart

enum IncomeMode { monthly, cutoff }
enum CategoryType { needs, wants, savings }
enum PaymentMode { cash, creditCard, debitCard, gcash, maya, bankTransfer, other }
enum RecurringFrequency { daily, weekly, monthly, yearly }

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
  int? cutoffPeriod;
  DateTime date;

  Income({required this.id, required this.amount, required this.label, required this.mode, this.cutoffPeriod, required this.date});

  Map<String, dynamic> toJson() => {'id': id, 'amount': amount, 'label': label, 'mode': mode.index, 'cutoffPeriod': cutoffPeriod, 'date': date.toIso8601String()};

  factory Income.fromJson(Map<String, dynamic> json) => Income(
    id: json['id'] as String, amount: (json['amount'] as num).toDouble(), label: json['label'] as String,
    mode: IncomeMode.values[json['mode'] as int? ?? 0], cutoffPeriod: json['cutoffPeriod'] as int?,
    date: DateTime.parse(json['date'] as String),
  );
}

class BudgetSubCategory {
  final String id;
  String name;
  double budgetAmount;
  CategoryType category;

  BudgetSubCategory({required this.id, required this.name, required this.budgetAmount, required this.category});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'budgetAmount': budgetAmount, 'category': category.index};

  factory BudgetSubCategory.fromJson(Map<String, dynamic> json) => BudgetSubCategory(
    id: json['id'] as String, name: json['name'] as String,
    budgetAmount: (json['budgetAmount'] as num).toDouble(), category: CategoryType.values[json['category'] as int],
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
  // Recurring
  bool isRecurring;
  RecurringFrequency? recurringFrequency;
  DateTime? recurringEndDate;
  String? recurringGroupId; // groups all instances together

  Expense({
    required this.id, required this.title, required this.amount, required this.category,
    this.subCategoryId, required this.paymentMode, required this.date,
    this.notes, this.creditCardId,
    this.isRecurring = false, this.recurringFrequency, this.recurringEndDate, this.recurringGroupId,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'amount': amount, 'category': category.index,
    'subCategoryId': subCategoryId, 'paymentMode': paymentMode.index,
    'date': date.toIso8601String(), 'notes': notes, 'creditCardId': creditCardId,
    'isRecurring': isRecurring, 'recurringFrequency': recurringFrequency?.index,
    'recurringEndDate': recurringEndDate?.toIso8601String(), 'recurringGroupId': recurringGroupId,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String, title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(), category: CategoryType.values[json['category'] as int],
    subCategoryId: json['subCategoryId'] as String?, paymentMode: PaymentMode.values[json['paymentMode'] as int? ?? 0],
    date: DateTime.parse(json['date'] as String), notes: json['notes'] as String?,
    creditCardId: json['creditCardId'] as String?, isRecurring: json['isRecurring'] as bool? ?? false,
    recurringFrequency: json['recurringFrequency'] != null ? RecurringFrequency.values[json['recurringFrequency'] as int] : null,
    recurringEndDate: json['recurringEndDate'] != null ? DateTime.parse(json['recurringEndDate'] as String) : null,
    recurringGroupId: json['recurringGroupId'] as String?,
  );
}

// ── Recurring Transaction Template ──────────────────────────────────────────
class RecurringTemplate {
  final String id;
  String title;
  double amount;
  CategoryType category;
  String? subCategoryId;
  PaymentMode paymentMode;
  RecurringFrequency frequency;
  DateTime startDate;
  DateTime? endDate;
  String? creditCardId;
  String? notes;
  DateTime? lastProcessed;

  RecurringTemplate({
    required this.id, required this.title, required this.amount, required this.category,
    this.subCategoryId, required this.paymentMode, required this.frequency,
    required this.startDate, this.endDate, this.creditCardId, this.notes, this.lastProcessed,
  });

  /// Returns true if this template is due today or overdue
  bool get isDue {
    final now = DateTime.now();
    final last = lastProcessed;
    if (last == null) return !startDate.isAfter(now);
    return nextDueDate.isBefore(now) || _isSameDay(nextDueDate, now);
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime get nextDueDate {
    final last = lastProcessed ?? startDate.subtract(const Duration(days: 1));
    switch (frequency) {
      case RecurringFrequency.daily:   return last.add(const Duration(days: 1));
      case RecurringFrequency.weekly:  return last.add(const Duration(days: 7));
      case RecurringFrequency.monthly: return DateTime(last.year, last.month + 1, last.day);
      case RecurringFrequency.yearly:  return DateTime(last.year + 1, last.month, last.day);
    }
  }

  bool get isActive {
    if (endDate == null) return true;
    return endDate!.isAfter(DateTime.now());
  }

  String get frequencyLabel {
    switch (frequency) {
      case RecurringFrequency.daily:   return 'Daily';
      case RecurringFrequency.weekly:  return 'Weekly';
      case RecurringFrequency.monthly: return 'Monthly';
      case RecurringFrequency.yearly:  return 'Yearly';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'amount': amount, 'category': category.index,
    'subCategoryId': subCategoryId, 'paymentMode': paymentMode.index,
    'frequency': frequency.index, 'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(), 'creditCardId': creditCardId,
    'notes': notes, 'lastProcessed': lastProcessed?.toIso8601String(),
  };

  factory RecurringTemplate.fromJson(Map<String, dynamic> json) => RecurringTemplate(
    id: json['id'] as String, title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(), category: CategoryType.values[json['category'] as int],
    subCategoryId: json['subCategoryId'] as String?, paymentMode: PaymentMode.values[json['paymentMode'] as int? ?? 0],
    frequency: RecurringFrequency.values[json['frequency'] as int],
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
    creditCardId: json['creditCardId'] as String?, notes: json['notes'] as String?,
    lastProcessed: json['lastProcessed'] != null ? DateTime.parse(json['lastProcessed'] as String) : null,
  );
}

class BankAccount {
  final String id;
  String name;
  String bankName;
  double balance;
  List<BankTransaction> transactions;

  BankAccount({required this.id, required this.name, required this.bankName, required this.balance, List<BankTransaction>? transactions}) : transactions = transactions ?? [];

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'bankName': bankName, 'balance': balance, 'transactions': transactions.map((t) => t.toJson()).toList()};

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
    id: json['id'] as String, name: json['name'] as String, bankName: json['bankName'] as String,
    balance: (json['balance'] as num).toDouble(),
    transactions: (json['transactions'] as List<dynamic>?)?.map((t) => BankTransaction.fromJson(t as Map<String, dynamic>)).toList() ?? [],
  );
}

class BankTransaction {
  final String id;
  String description;
  double amount;
  DateTime date;

  BankTransaction({required this.id, required this.description, required this.amount, required this.date});

  Map<String, dynamic> toJson() => {'id': id, 'description': description, 'amount': amount, 'date': date.toIso8601String()};

  factory BankTransaction.fromJson(Map<String, dynamic> json) => BankTransaction(
    id: json['id'] as String, description: json['description'] as String,
    amount: (json['amount'] as num).toDouble(), date: DateTime.parse(json['date'] as String),
  );
}

class CreditCard {
  final String id;
  String name;
  String bank;
  double creditLimit;
  double balance;
  int statementDay;
  int dueDay;
  List<CreditCardTransaction> transactions;

  CreditCard({required this.id, required this.name, required this.bank, required this.creditLimit, required this.balance, required this.statementDay, required this.dueDay, List<CreditCardTransaction>? transactions}) : transactions = transactions ?? [];

  double get availableCredit => creditLimit - balance;

  /// The statement cut-off date that just passed (e.g. Mar 25 if today is Apr 10 and statementDay=25)
  DateTime get lastStatementDate {
    final now = DateTime.now();
    DateTime candidate = DateTime(now.year, now.month, statementDay);
    if (candidate.isAfter(now)) {
      candidate = DateTime(now.year, now.month - 1, statementDay);
    }
    return candidate;
  }

  /// The statement cut-off date before lastStatementDate (e.g. Feb 25)
  DateTime get prevStatementDate {
    final last = lastStatementDate;
    return DateTime(last.year, last.month - 1, statementDay);
  }

  /// Next upcoming statement cut-off date (e.g. Apr 25 if today is Apr 10)
  DateTime get nextStatementDate {
    final now = DateTime.now();
    DateTime candidate = DateTime(now.year, now.month, statementDay);
    if (!candidate.isAfter(now)) {
      candidate = DateTime(now.year, now.month + 1, statementDay);
    }
    return candidate;
  }

  /// Due date for the PREVIOUS statement (the one that has already closed).
  /// e.g. if statementDay=25 and dueDay=14, and today is Apr 10:
  ///   - Previous statement closed Mar 25
  ///   - Its payment is due Apr 14
  /// If Apr 14 has already passed, rolls forward to the next cycle's due date (May 14).
  DateTime get nextDueDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = lastStatementDate;
    // Due date falls in the month AFTER the statement cut-off
    DateTime due = DateTime(last.year, last.month + 1, dueDay);
    // If the due date has already passed, advance to the next statement's due date
    if (due.isBefore(today)) {
      final next = nextStatementDate;
      due = DateTime(next.year, next.month + 1, dueDay);
    }
    return due;
  }

  int get daysUntilDue => nextDueDate.difference(
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  ).inDays;

  /// Transactions from the PREVIOUS closed statement period (prevStatementDate → lastStatementDate).
  /// These are the transactions that are now DUE for payment.
  List<CreditCardTransaction> get previousStatementTransactions {
    final from = prevStatementDate;
    final to   = lastStatementDate;
    return transactions.where((t) {
      return !t.date.isBefore(from) && t.date.isBefore(to);
    }).toList();
  }

  /// Transactions within the CURRENT open statement period (lastStatementDate → nextStatementDate).
  /// These are NOT yet due — they will be billed on the next statement.
  List<CreditCardTransaction> get currentStatementTransactions {
    final from = lastStatementDate;
    final to   = nextStatementDate;
    return transactions.where((t) {
      return !t.date.isBefore(from) && t.date.isBefore(to);
    }).toList();
  }

  /// Unpaid amount from the PREVIOUS closed statement (what the user actually owes now)
  double get currentStatementBalance {
    return previousStatementTransactions
        .where((t) => !t.isPaid)
        .fold(0.0, (s, t) => s + t.amount);
  }

  /// Whether there is a bill due: unpaid charges from the closed statement, and due date is within 7 days
  bool get hasBillDue => currentStatementBalance > 0 && daysUntilDue <= 7;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'bank': bank, 'creditLimit': creditLimit, 'balance': balance, 'statementDay': statementDay, 'dueDay': dueDay, 'transactions': transactions.map((t) => t.toJson()).toList()};

  factory CreditCard.fromJson(Map<String, dynamic> json) => CreditCard(
    id: json['id'] as String, name: json['name'] as String, bank: json['bank'] as String,
    creditLimit: (json['creditLimit'] as num).toDouble(), balance: (json['balance'] as num).toDouble(),
    statementDay: json['statementDay'] as int? ?? 25, dueDay: json['dueDay'] as int? ?? 20,
    transactions: (json['transactions'] as List<dynamic>?)?.map((t) => CreditCardTransaction.fromJson(t as Map<String, dynamic>)).toList() ?? [],
  );
}

class CreditCardTransaction {
  final String id;
  String description;
  double amount;
  DateTime date;
  bool isPaid;

  CreditCardTransaction({required this.id, required this.description, required this.amount, required this.date, this.isPaid = false});

  Map<String, dynamic> toJson() => {'id': id, 'description': description, 'amount': amount, 'date': date.toIso8601String(), 'isPaid': isPaid};

  factory CreditCardTransaction.fromJson(Map<String, dynamic> json) => CreditCardTransaction(
    id: json['id'] as String, description: json['description'] as String,
    amount: (json['amount'] as num).toDouble(), date: DateTime.parse(json['date'] as String),
    isPaid: json['isPaid'] as bool? ?? false,
  );
}
