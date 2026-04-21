// lib/services/notification_service.dart
import '../models/models.dart';
import '../providers/app_provider.dart';

enum NotifType { recurringOverdue, creditCardDue, overBudget }

class AppNotification {
  final NotifType type;
  final String title;
  final String subtitle;
  final double? amount;
  final String? actionId; // templateId or cardId or categoryName

  const AppNotification({
    required this.type,
    required this.title,
    required this.subtitle,
    this.amount,
    this.actionId,
  });
}

class NotificationService {
  static List<AppNotification> buildNotifications(AppProvider p) {
    final List<AppNotification> notifs = [];

    // ── 1. Overdue recurring templates ──────────────────────────────────────
    for (final t in p.overdueRecurring) {
      final daysOverdue = DateTime.now().difference(t.nextDueDate).inDays;
      final suffix = daysOverdue > 0 ? ' · $daysOverdue day${daysOverdue > 1 ? 's' : ''} overdue' : ' · due today';
      notifs.add(AppNotification(
        type: NotifType.recurringOverdue,
        title: t.title,
        subtitle: '${t.frequencyLabel} recurring$suffix',
        amount: t.amount,
        actionId: t.id,
      ));
    }

    // ── 2. Credit card bills due soon (≤7 days) ──────────────────────────
    for (final c in p.cardsDueSoon) {
      final days = c.daysUntilDue;
      final when = days == 0 ? 'Due today' : days == 1 ? 'Due tomorrow' : 'Due in $days days';
      notifs.add(AppNotification(
        type: NotifType.creditCardDue,
        title: c.name,
        subtitle: '$when · ${c.bank}',
        amount: c.currentStatementBalance,
        actionId: c.id,
      ));
    }

    // ── 3. Over-budget categories ─────────────────────────────────────────
    // Top-level (Needs / Wants / Savings)
    final topLevel = [
      ('Needs',   p.totalNeedsSpent,   p.needsBudget),
      ('Wants',   p.totalWantsSpent,   p.wantsBudget),
      ('Savings', p.totalSavingsSpent, p.savingsBudget),
    ];
    for (final (label, spent, budget) in topLevel) {
      if (budget > 0 && spent > budget) {
        final over = spent - budget;
        notifs.add(AppNotification(
          type: NotifType.overBudget,
          title: '$label over budget',
          subtitle: '${_pct(spent, budget)}% of budget used',
          amount: over,
          actionId: label,
        ));
      }
    }

    // Sub-categories
    for (final sub in p.subCategories) {
      final spent = p.subCategorySpent(sub.id);
      if (sub.budgetAmount > 0 && spent > sub.budgetAmount) {
        final over = spent - sub.budgetAmount;
        notifs.add(AppNotification(
          type: NotifType.overBudget,
          title: '${sub.name} over budget',
          subtitle: '${_pct(spent, sub.budgetAmount)}% of budget used',
          amount: over,
          actionId: sub.id,
        ));
      }
    }

    return notifs;
  }

  static int _pct(double spent, double budget) =>
      budget > 0 ? (spent / budget * 100).round() : 0;
}
