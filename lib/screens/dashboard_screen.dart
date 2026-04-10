// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/shared_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    if (p.totalIncome == 0) {
      return const EmptyState(icon: Icons.account_balance_wallet_outlined, title: 'No income yet', message: 'Add your income in the Income tab to get started with budgeting.');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _HeroCard(p: p),
        const SizedBox(height: 16),
        _ThreeStats(p: p),
        const SizedBox(height: 16),
        _SpendingDonut(p: p),
        const SizedBox(height: 16),
        _BudgetProgressCard(p: p),
        if (p.expenses.isNotEmpty) ...[const SizedBox(height: 16), _MonthlyBarChart(p: p)],
        // ── Recurring Due ──────────────────────────────────────────────────
        if (p.overdueRecurring.isNotEmpty) ...[const SizedBox(height: 16), _RecurringDueCard(p: p)],
        // ── CC Due Soon — only shows if statement-period unpaid balance > 0 ──
        if (p.cardsDueSoon.isNotEmpty) ...[const SizedBox(height: 16), _DueSoonCard(cards: p.cardsDueSoon)],
        const SizedBox(height: 16),
        _RecentExpenses(p: p),
      ],
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final AppProvider p;
  const _HeroCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final spentPct = p.totalIncome > 0 ? (p.totalSpent / p.totalIncome).clamp(0.0, 1.0) : 0.0;
    final isOver = p.remainingTotal < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: colors.isDark
              ? [const Color(0xFF1C1C22), const Color(0xFF141418)]
              : [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(monthFmt.format(DateTime.now()), style: GoogleFonts.inter(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('Total Income', style: GoogleFonts.inter(fontSize: 13, color: Colors.white60, fontWeight: FontWeight.w500)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isOver ? kDangerColor.withOpacity(0.2) : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isOver ? kDangerColor.withOpacity(0.5) : Colors.white.withOpacity(0.15)),
            ),
            child: Text(isOver ? '⚠ Over budget' : '✓ On track',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isOver ? kDangerColor : Colors.white70)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(pesoFmt.format(p.totalIncome), style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
        const SizedBox(height: 20),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${pesoFmt.format(p.totalSpent)} spent', style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
            Text('${pesoFmt.format(p.remainingTotal.abs())} ${isOver ? "over" : "left"}',
              style: GoogleFonts.inter(fontSize: 12, color: isOver ? kDangerColor : kSuccessColor, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: spentPct, backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(isOver ? kDangerColor : kSuccessColor), minHeight: 8),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _MiniPill('Needs',   p.needsBudget,   p.totalNeedsSpent,   kNeedsColor),
          const SizedBox(width: 8),
          _MiniPill('Wants',   p.wantsBudget,   p.totalWantsSpent,   kWantsColor),
          const SizedBox(width: 8),
          _MiniPill('Savings', p.savingsBudget, p.totalSavingsSpent, kSavingsColor),
        ]),
      ]),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final double budget, spent;
  final Color color;
  const _MiniPill(this.label, this.budget, this.spent, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(pesoFmt.format(budget - spent), style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        ClipRRect(borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: pct, backgroundColor: Colors.white.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 3)),
      ]),
    ));
  }
}

class _ThreeStats extends StatelessWidget {
  final AppProvider p;
  const _ThreeStats({required this.p});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: StatTile(label: 'Total Spent', value: p.totalSpent, icon: Icons.trending_up_rounded)),
    const SizedBox(width: 10),
    Expanded(child: StatTile(label: 'Total Saved', value: p.bankAccounts.fold(0.0, (s, a) => s + a.balance), accentColor: kSavingsColor, icon: Icons.savings_outlined)),
  ]);
}

// ─── Donut ────────────────────────────────────────────────────────────────────
class _SpendingDonut extends StatefulWidget {
  final AppProvider p;
  const _SpendingDonut({required this.p});
  @override
  State<_SpendingDonut> createState() => _SpendingDonutState();
}

class _SpendingDonutState extends State<_SpendingDonut> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final p = widget.p;

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('Spending Breakdown'),
      if (p.totalSpent == 0)
        Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No expenses logged yet', style: Theme.of(context).textTheme.bodyMedium)))
      else
        SizedBox(height: 180, child: Row(children: [
          Expanded(child: PieChart(PieChartData(
            pieTouchData: PieTouchData(touchCallback: (e, res) => setState(() => _touched = res?.touchedSection?.touchedSectionIndex ?? -1)),
            sectionsSpace: 2, centerSpaceRadius: 45,
            sections: [
              if (p.totalNeedsSpent > 0)   PieChartSectionData(value: p.totalNeedsSpent,   color: colors.needs,   title: '', radius: _touched == 0 ? 48 : 40),
              if (p.totalWantsSpent > 0)   PieChartSectionData(value: p.totalWantsSpent,   color: colors.wants,   title: '', radius: _touched == 1 ? 48 : 40),
              if (p.totalSavingsSpent > 0) PieChartSectionData(value: p.totalSavingsSpent, color: colors.savings, title: '', radius: _touched == 2 ? 48 : 40),
            ],
          ))),
          const SizedBox(width: 20),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _DonutLegend('Needs',   p.totalNeedsSpent,   p.totalSpent, colors.needs),
            const SizedBox(height: 14),
            _DonutLegend('Wants',   p.totalWantsSpent,   p.totalSpent, colors.wants),
            const SizedBox(height: 14),
            _DonutLegend('Savings', p.totalSavingsSpent, p.totalSpent, colors.savings),
          ]),
        ])),
    ]));
  }
}

class _DonutLegend extends StatelessWidget {
  final String label;
  final double value, total;
  final Color color;
  const _DonutLegend(this.label, this.value, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total * 100).toStringAsFixed(0) : '0';
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.w500)),
        Text('$pct%  ${pesoFmt.format(value)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textPrimary)),
      ]),
    ]);
  }
}

// ─── Budget Progress ──────────────────────────────────────────────────────────
class _BudgetProgressCard extends StatelessWidget {
  final AppProvider p;
  const _BudgetProgressCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('Budget Progress'),
      BudgetProgressBar(label: 'Needs',   spent: p.totalNeedsSpent,   budget: p.needsBudget,   color: colors.needs),
      const SizedBox(height: 16),
      BudgetProgressBar(label: 'Wants',   spent: p.totalWantsSpent,   budget: p.wantsBudget,   color: colors.wants),
      const SizedBox(height: 16),
      BudgetProgressBar(label: 'Savings', spent: p.totalSavingsSpent, budget: p.savingsBudget, color: colors.savings),
    ]));
  }
}

// ─── Monthly Bar ──────────────────────────────────────────────────────────────
class _MonthlyBarChart extends StatelessWidget {
  final AppProvider p;
  const _MonthlyBarChart({required this.p});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
    final data = months.map((m) => p.expenses.where((e) => e.date.year == m.year && e.date.month == m.month).fold(0.0, (s, e) => s + e.amount)).toList();
    final maxVal = data.reduce((a, b) => a > b ? a : b);

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel('6-Month Spending Trend'),
      const SizedBox(height: 8),
      SizedBox(height: 140, child: BarChart(BarChartData(
        maxY: maxVal > 0 ? maxVal * 1.3 : 100,
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: colors.divider, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (touchedBarGroup) => colors.isDark ? Colors.grey[900]! : Colors.grey[100]!,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                pesoFmt.format(rod.toY),
                TextStyle(
                  color: colors.isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 6), child: Text(DateFormat('MMM').format(months[v.toInt()]), style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w500))),
            reservedSize: 22,
          )),
        ),
        barGroups: List.generate(6, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(
          toY: data[i], width: 22,
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [colors.needs.withOpacity(0.6), colors.needs]),
        )])),
      ))),
    ]));
  }
}

// ─── Recurring Due Card ───────────────────────────────────────────────────────
class _RecurringDueCard extends StatelessWidget {
  final AppProvider p;
  const _RecurringDueCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final due = p.overdueRecurring;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kNeedsColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kNeedsColor.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.repeat_rounded, size: 16, color: kNeedsColor),
          const SizedBox(width: 8),
          Text('Recurring Due', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: kNeedsColor, letterSpacing: 0.5)),
          const Spacer(),
          Text('${due.length} item${due.length > 1 ? "s" : ""}', style: GoogleFonts.inter(fontSize: 11, color: kNeedsColor)),
        ]),
        const SizedBox(height: 12),
        ...due.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).extension<AppColors>()!.textPrimary)),
              Text('${t.frequencyLabel} · ${pesoFmt.format(t.amount)}', style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).extension<AppColors>()!.textSecondary)),
            ])),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => p.skipRecurringTemplate(t.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: kNeedsColor.withOpacity(0.3))),
                child: Text('Skip', style: GoogleFonts.inter(fontSize: 12, color: kNeedsColor, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => p.processRecurringTemplate(t.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: kNeedsColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('Log Now', style: GoogleFonts.inter(fontSize: 12, color: kNeedsColor, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        )),
      ]),
    );
  }
}

// ─── CC Due Soon Card ─────────────────────────────────────────────────────────
// Only appears when: unpaid CC txns exist within the current statement period AND due <= 7 days
class _DueSoonCard extends StatelessWidget {
  final List<CreditCard> cards;
  const _DueSoonCard({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWarningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kWarningColor.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.notifications_active_rounded, size: 16, color: kWarningColor),
          const SizedBox(width: 8),
          Text('Payment Due Soon', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: kWarningColor, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 12),
        ...cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).extension<AppColors>()!.textPrimary)),
              Text(
                'Due ${dateFmt.format(c.nextDueDate)} · ${c.daysUntilDue} days left\n'
                'Statement: ${dateFmt.format(c.lastStatementDate)} → ${dateFmt.format(c.nextStatementDate)}',
                style: GoogleFonts.inter(fontSize: 11, color: kWarningColor),
              ),
            ]),
            Text(pesoFmt.format(c.currentStatementBalance),
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: kDangerColor)),
          ]),
        )),
      ]),
    );
  }
}

// ─── Recent Expenses ──────────────────────────────────────────────────────────
class _RecentExpenses extends StatelessWidget {
  final AppProvider p;
  const _RecentExpenses({required this.p});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final recent = [...p.expenses]..sort((a, b) => b.date.compareTo(a.date));

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const SectionLabel('Recent Expenses'),
        Text('${p.expenses.length} total', style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted)),
      ]),
      if (p.expenses.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('No expenses yet', style: Theme.of(context).textTheme.bodyMedium))
      else
        ...recent.take(5).map((e) => _ExpenseTile(expense: e, colors: colors)),
    ]));
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final AppColors colors;
  const _ExpenseTile({required this.expense, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors.forCategory(expense.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: c.withOpacity(colors.isDark ? 0.15 : 0.1), borderRadius: BorderRadius.circular(10)),
          child: Stack(alignment: Alignment.center, children: [
            Icon(_catIcon(expense.category), size: 17, color: c),
            if (expense.isRecurring)
              Positioned(bottom: 2, right: 2, child: Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(color: kNeedsColor, shape: BoxShape.circle),
                child: const Icon(Icons.repeat, size: 7, color: Colors.white),
              )),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(expense.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(children: [
            CategoryChip(category: expense.category),
            const SizedBox(width: 6),
            Text(shortDateFmt.format(expense.date), style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted)),
          ]),
        ])),
        Text(pesoFmt.format(expense.amount), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
      ]),
    );
  }

  IconData _catIcon(CategoryType t) =>
    t == CategoryType.needs ? Icons.home_outlined : t == CategoryType.wants ? Icons.shopping_bag_outlined : Icons.savings_outlined;
}
