// lib/screens/savings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/shared_widgets.dart';

const _kGoalEmojis = [
  '🎯','🏠','✈️','🚗','💻','📱','🎓','💍','👶','🏖️',
  '🏋️','🎵','📷','🛋️','💊','🐶','🌏','🏦','💰','🎁',
];

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});
  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p      = context.watch<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final totalBank  = p.bankAccounts.fold(0.0, (s, a) => s + a.balance);
    final totalGoals = p.totalGoalsSaved;

    return Scaffold(
      floatingActionButton: _SavingsFAB(tab: _tab),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors.isDark
                  ? [const Color(0xFF0D2818), const Color(0xFF0A1F12)]
                  : [const Color(0xFF064E3B), const Color(0xFF065F46)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total Savings', style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.savings_rounded, size: 18, color: Colors.white70)),
            ]),
            const SizedBox(height: 8),
            Text(pesoFmt.format(totalBank), style: GoogleFonts.plusJakartaSans(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
            const SizedBox(height: 4),
            Row(children: [
              Text('across ${p.bankAccounts.length} account${p.bankAccounts.length == 1 ? "" : "s"}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
              if (totalGoals > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text('${pesoFmt.format(totalGoals)} earmarked', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                ),
              ],
            ]),
          ]),
        ),
        Container(
          color: colors.bg,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(14)),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(color: colors.textPrimary, borderRadius: BorderRadius.circular(11)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13),
              labelColor: colors.bg,
              unselectedLabelColor: colors.textSecondary,
              tabs: [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.account_balance_outlined, size: 14),
                  const SizedBox(width: 6),
                  const Text('Accounts'),
                  if (p.bankAccounts.isNotEmpty) ...[const SizedBox(width: 5), _Chip('${p.bankAccounts.length}')],
                ])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.flag_outlined, size: 14),
                  const SizedBox(width: 6),
                  const Text('Goals'),
                  if (p.savingsGoals.isNotEmpty) ...[const SizedBox(width: 5), _Chip('${p.savingsGoals.length}')],
                ])),
              ],
            ),
          ),
        ),
        Expanded(child: TabBarView(controller: _tab, children: [_AccountsTab(), _GoalsTab()])),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

// ── FAB that adapts to active tab ─────────────────────────────────────────────
class _SavingsFAB extends StatefulWidget {
  final TabController tab;
  const _SavingsFAB({required this.tab});
  @override
  State<_SavingsFAB> createState() => _SavingsFABState();
}

class _SavingsFABState extends State<_SavingsFAB> {
  int _idx = 0;
  @override
  void initState() {
    super.initState();
    widget.tab.addListener(() => setState(() => _idx = widget.tab.index));
  }
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return FloatingActionButton.extended(
      heroTag: 'savings_fab',
      onPressed: () => _idx == 0 ? _addBank(context) : _newGoal(context),
      backgroundColor: colors.textPrimary, foregroundColor: colors.bg, elevation: 0,
      icon: const Icon(Icons.add, size: 18),
      label: Text(_idx == 0 ? 'Add Bank' : 'New Goal', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  void _addBank(BuildContext ctx) {
    final p = ctx.read<AppProvider>();
    final n = TextEditingController(), b = TextEditingController(), bal = TextEditingController();
    final fk = GlobalKey<FormState>();
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Form(key: fk, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SheetHandle(),
        Text('Add Bank Account', style: Theme.of(ctx).textTheme.headlineSmall),
        const SizedBox(height: 20),
        TextFormField(controller: n, decoration: const InputDecoration(labelText: 'Account Name', hintText: 'e.g. Main Savings', prefixIcon: Icon(Icons.account_circle_outlined, size: 18)), validator: (v) => v!.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(controller: b, decoration: const InputDecoration(labelText: 'Bank / Wallet', hintText: 'e.g. BDO, BPI, GCash', prefixIcon: Icon(Icons.account_balance_outlined, size: 18)), validator: (v) => v!.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        buildAmountField(controller: bal, label: 'Current Balance'),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            if (!fk.currentState!.validate()) return;
            p.addBankAccount(BankAccount(id: p.newId(), name: n.text.trim(), bankName: b.text.trim(), balance: double.parse(bal.text.trim())));
            Navigator.pop(ctx);
          },
          child: const Text('Add Account'),
        )),
      ])),
    ));
  }

  void _newGoal(BuildContext ctx) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (_) => const _CreateGoalSheet());
  }
}

// ── Accounts Tab ──────────────────────────────────────────────────────────────
class _AccountsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    if (p.bankAccounts.isEmpty) return const EmptyState(icon: Icons.account_balance_outlined, title: 'No bank accounts', message: 'Add your savings accounts to track your money.');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: p.bankAccounts.length,
      itemBuilder: (ctx, i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _BankCard(account: p.bankAccounts[i])),
    );
  }
}

// ── Goals Tab ─────────────────────────────────────────────────────────────────
class _GoalsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    if (p.savingsGoals.isEmpty) {
      return EmptyState(
        icon: Icons.flag_outlined,
        title: 'No savings goals',
        message: 'Set a target — emergency fund, vacation, gadget — anything you\'re saving toward.',
        action: ElevatedButton(onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const _CreateGoalSheet()), child: const Text('Create First Goal')),
      );
    }
    final active = p.savingsGoals.where((g) => !g.isCompleted).toList()
      ..sort((a, b) {
        const o = {GoalPriority.high: 0, GoalPriority.medium: 1, GoalPriority.low: 2};
        return o[a.priority]!.compareTo(o[b.priority]!);
      });
    final done = p.savingsGoals.where((g) => g.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Row(children: [
          Expanded(child: StatTile(label: 'Total Earmarked', value: p.totalGoalsSaved, accentColor: kSavingsColor, icon: Icons.savings_outlined)),
          const SizedBox(width: 10),
          Expanded(child: StatTile(label: 'Active Goals', value: active.length.toDouble(), icon: Icons.flag_outlined, isCurrency: false)),
        ]),
        const SizedBox(height: 16),
        if (p.goalsNearingDeadline.isNotEmpty) ...[_DeadlineAlert(goals: p.goalsNearingDeadline), const SizedBox(height: 16)],
        if (active.isNotEmpty) ...[
          const SectionLabel('Active'),
          ...active.map((g) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _GoalCard(goal: g))),
        ],
        if (done.isNotEmpty) ...[const SizedBox(height: 4), _CompletedSection(completed: done)],
      ],
    );
  }
}

// ── Deadline Alert ─────────────────────────────────────────────────────────────
class _DeadlineAlert extends StatelessWidget {
  final List<SavingsGoal> goals;
  const _DeadlineAlert({required this.goals});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kWarningColor.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: kWarningColor.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.schedule_rounded, size: 14, color: kWarningColor), const SizedBox(width: 7), Text('Deadlines approaching', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: kWarningColor))]),
        const SizedBox(height: 10),
        ...goals.take(3).map((g) {
          final d = g.daysRemaining!;
          return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
            Text(g.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(child: Text(g.name, style: GoogleFonts.inter(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w500))),
            Text(d < 0 ? 'Overdue' : d == 0 ? 'Today!' : '${d}d left', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: d <= 0 ? kDangerColor : kWarningColor)),
          ]));
        }),
      ]),
    );
  }
}

// ── Goal Card ──────────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final p      = context.read<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final pct    = goal.progressPct;
    final days   = goal.daysRemaining;
    final priColor = goal.priority == GoalPriority.high ? kDangerColor : goal.priority == GoalPriority.medium ? kWarningColor : colors.textSecondary;

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(goal.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(goal.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: priColor.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                child: Text(goal.priority.name[0].toUpperCase() + goal.priority.name.substring(1), style: GoogleFonts.inter(fontSize: 10, color: priColor, fontWeight: FontWeight.w600))),
            if (days != null) ...[
              const SizedBox(width: 6),
              Text(goal.isOverdue ? '⚠ Overdue' : days == 0 ? '🎯 Today' : '${days}d left',
                  style: GoogleFonts.inter(fontSize: 11, color: goal.isOverdue ? kDangerColor : colors.textSecondary, fontWeight: goal.isOverdue ? FontWeight.w700 : FontWeight.w400)),
            ],
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(pesoFmt.format(goal.remaining), style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          Text('to go', style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted)),
        ]),
      ]),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(pesoFmt.format(goal.savedAmount), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: kSavingsColor)),
        Text('of ${pesoFmt.format(goal.targetAmount)}', style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary)),
      ]),
      const SizedBox(height: 6),
      Stack(children: [
        Container(height: 8, decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(10))),
        FractionallySizedBox(
          widthFactor: pct,
          child: Container(height: 8, decoration: BoxDecoration(
            color: kSavingsColor, borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: kSavingsColor.withOpacity(0.45), blurRadius: 6)],
          )),
        ),
      ]),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${(pct * 100).toStringAsFixed(0)}% saved', style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w500)),
        if (goal.suggestedMonthly != null)
          Text('${pesoFmt.format(goal.suggestedMonthly!)}/mo to reach', style: GoogleFonts.inter(fontSize: 10, color: colors.textSecondary)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: ActionPill(label: 'Add Funds', icon: Icons.add_rounded, color: kSavingsColor, onTap: () => _contribute(context, p))),
        const SizedBox(width: 8),
        Expanded(child: ActionPill(label: 'History', icon: Icons.history_rounded, color: colors.textSecondary, onTap: () => _history(context))),
        const SizedBox(width: 8),
        _Btn(icon: Icons.edit_outlined, color: colors.textSecondary, onTap: () => _edit(context, p)),
        const SizedBox(width: 6),
        _Btn(icon: Icons.delete_outline_rounded, color: kDangerColor, onTap: () => _delete(context, p)),
      ]),
    ]));
  }

  void _contribute(BuildContext ctx, AppProvider p) {
    final ac = TextEditingController(), nc = TextEditingController(text: 'Contribution');
    String? fromAcc;
    final fk = GlobalKey<FormState>();
    final colors = Theme.of(ctx).extension<AppColors>()!;
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Form(key: fk, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SheetHandle(),
        Row(children: [Text(goal.emoji, style: const TextStyle(fontSize: 22)), const SizedBox(width: 10), Text('Add to ${goal.name}', style: Theme.of(ctx).textTheme.headlineSmall)]),
        const SizedBox(height: 4),
        Text('${pesoFmt.format(goal.savedAmount)} saved · ${pesoFmt.format(goal.remaining)} remaining', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
        const SizedBox(height: 20),
        buildAmountField(controller: ac, label: 'Amount to add'),
        const SizedBox(height: 12),
        TextFormField(controller: nc, decoration: const InputDecoration(labelText: 'Note', prefixIcon: Icon(Icons.notes_outlined, size: 18)), validator: (v) => v!.isEmpty ? 'Required' : null),
        if (p.bankAccounts.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionLabel('Deduct from account (optional)'),
          DropdownButtonFormField<String>(
            value: fromAcc,
            decoration: const InputDecoration(labelText: 'Bank account'),
            items: [
              const DropdownMenuItem(value: null, child: Text('No — just track progress')),
              ...p.bankAccounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} · ${pesoFmt.format(a.balance)}'))),
            ],
            onChanged: (v) => ss(() => fromAcc = v),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            if (!fk.currentState!.validate()) return;
            p.contributeToGoal(goalId: goal.id, amount: double.parse(ac.text.trim()), note: nc.text.trim(), fromAccountId: fromAcc);
            Navigator.pop(ctx);
          },
          child: const Text('Add Funds'),
        )),
      ])),
    )));
  }

  void _history(BuildContext ctx) {
    final colors = Theme.of(ctx).extension<AppColors>()!;
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3, expand: false,
      builder: (ctx, scroll) => Column(children: [
        const SheetHandle(),
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: Row(children: [Text(goal.emoji, style: const TextStyle(fontSize: 20)), const SizedBox(width: 10), Text('${goal.name} History', style: Theme.of(ctx).textTheme.headlineSmall)])),
        Divider(height: 1, color: colors.divider),
        if (goal.contributions.isEmpty)
          Padding(padding: const EdgeInsets.all(40), child: Text('No contributions yet', style: Theme.of(ctx).textTheme.bodyMedium))
        else
          Expanded(child: ListView.separated(
            controller: scroll,
            padding: const EdgeInsets.all(16),
            itemCount: goal.contributions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final c = goal.contributions[i];
              final isPlus = c.amount >= 0;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.divider)),
                child: Row(children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: (isPlus ? kSuccessColor : kDangerColor).withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(isPlus ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 15, color: isPlus ? kSuccessColor : kDangerColor)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.note, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                    Text(dateFmt.format(c.date), style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted)),
                  ])),
                  Text('${isPlus ? "+" : ""}${pesoFmt.format(c.amount)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isPlus ? kSuccessColor : kDangerColor)),
                ]),
              );
            },
          )),
      ]),
    ));
  }

  void _edit(BuildContext ctx, AppProvider p) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (_) => _EditGoalSheet(goal: goal));
  }

  void _delete(BuildContext ctx, AppProvider p) {
    showDialog(context: ctx, builder: (d) => AlertDialog(
      title: const Text('Delete Goal'),
      content: Text('Delete "${goal.name}"? The ${pesoFmt.format(goal.savedAmount)} earmarked will NOT be moved back to any account automatically.'),
      actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')), TextButton(onPressed: () { Navigator.pop(d); p.deleteSavingsGoal(goal.id); }, child: const Text('Delete', style: TextStyle(color: kDangerColor)))],
    ));
  }
}

class _CompletedSection extends StatefulWidget {
  final List<SavingsGoal> completed;
  const _CompletedSection({required this.completed});
  @override
  State<_CompletedSection> createState() => _CompletedSectionState();
}

class _CompletedSectionState extends State<_CompletedSection> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(onTap: () => setState(() => _open = !_open), child: Row(children: [
        Icon(Icons.check_circle_outline_rounded, size: 15, color: kSuccessColor),
        const SizedBox(width: 7),
        Text('${widget.completed.length} completed goal${widget.completed.length > 1 ? "s" : ""}', style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary, fontWeight: FontWeight.w500)),
        const Spacer(),
        Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: colors.textMuted),
      ])),
      if (_open) ...[const SizedBox(height: 10), ...widget.completed.map((g) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Opacity(opacity: 0.65, child: _GoalCard(goal: g))))],
    ]);
  }
}

// ── Create Goal Sheet ─────────────────────────────────────────────────────────
class _CreateGoalSheet extends StatefulWidget {
  const _CreateGoalSheet();
  @override
  State<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<_CreateGoalSheet> {
  final _fk = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _savedCtrl  = TextEditingController(text: '0');
  String _emoji = '🎯';
  GoalPriority _priority = GoalPriority.medium;
  DateTime? _targetDate;
  String? _linked;

  @override
  void dispose() {
    _nameCtrl.dispose(); _targetCtrl.dispose(); _savedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      child: Form(key: _fk, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SheetHandle(),
        Text('New Savings Goal', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        Row(children: [
          GestureDetector(
            onTap: () => _pickEmoji(context),
            child: Container(width: 54, height: 54, decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.divider)), alignment: Alignment.center, child: Text(_emoji, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Goal name', hintText: 'e.g. Emergency Fund'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
        ]),
        const SizedBox(height: 12),
        TextFormField(
          controller: _targetCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          decoration: const InputDecoration(labelText: 'Target amount', prefixText: '₱  ', prefixIcon: Icon(Icons.flag_outlined, size: 18)),
          validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter a valid amount' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _savedCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          decoration: const InputDecoration(labelText: 'Already saved (optional)', prefixText: '₱  ', prefixIcon: Icon(Icons.savings_outlined, size: 18)),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Priority'),
        AppSegmented<GoalPriority>(value: _priority, values: GoalPriority.values, labels: const ['Low', 'Medium', 'High'], onChanged: (v) => setState(() => _priority = v)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime(2040));
            if (d != null) setState(() => _targetDate = d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.divider)),
            child: Row(children: [
              Icon(Icons.calendar_month_outlined, size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              Expanded(child: Text(_targetDate == null ? 'Set target date (optional)' : 'Target: ${dateFmt.format(_targetDate!)}', style: GoogleFonts.inter(fontSize: 13, color: _targetDate == null ? colors.textMuted : colors.textPrimary))),
              if (_targetDate != null) GestureDetector(onTap: () => setState(() => _targetDate = null), child: Icon(Icons.close_rounded, size: 16, color: colors.textMuted)),
            ]),
          ),
        ),
        if (p.bankAccounts.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _linked,
            decoration: const InputDecoration(labelText: 'Link to account (optional)', prefixIcon: Icon(Icons.account_balance_outlined, size: 18)),
            items: [const DropdownMenuItem(value: null, child: Text('No linked account')), ...p.bankAccounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} · ${a.bankName}')))],
            onChanged: (v) => setState(() => _linked = v),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            if (!_fk.currentState!.validate()) return;
            p.addSavingsGoal(SavingsGoal(
              id: p.newId(), name: _nameCtrl.text.trim(), emoji: _emoji,
              targetAmount: double.parse(_targetCtrl.text.trim()),
              savedAmount: double.tryParse(_savedCtrl.text.trim()) ?? 0,
              targetDate: _targetDate, priority: _priority, linkedAccountId: _linked,
              createdAt: DateTime.now(),
            ));
            Navigator.pop(context);
          },
          child: const Text('Create Goal'),
        )),
      ])),
    );
  }

  void _pickEmoji(BuildContext ctx) {
    final colors = Theme.of(ctx).extension<AppColors>()!;
    showModalBottomSheet(context: ctx, builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SheetHandle(),
        Wrap(spacing: 10, runSpacing: 10, children: _kGoalEmojis.map((e) => GestureDetector(
          onTap: () { setState(() => _emoji = e); Navigator.pop(ctx); },
          child: Container(width: 48, height: 48, decoration: BoxDecoration(color: e == _emoji ? kSavingsColor.withOpacity(0.15) : colors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: e == _emoji ? kSavingsColor.withOpacity(0.5) : colors.divider)), alignment: Alignment.center, child: Text(e, style: const TextStyle(fontSize: 22))),
        )).toList()),
        const SizedBox(height: 12),
      ]),
    ));
  }
}

// ── Edit Goal Sheet ────────────────────────────────────────────────────────────
class _EditGoalSheet extends StatefulWidget {
  final SavingsGoal goal;
  const _EditGoalSheet({required this.goal});
  @override
  State<_EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends State<_EditGoalSheet> {
  final _fk = GlobalKey<FormState>();
  late final TextEditingController _nc, _tc;
  late String _emoji;
  late GoalPriority _priority;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _nc = TextEditingController(text: widget.goal.name);
    _tc = TextEditingController(text: widget.goal.targetAmount.toStringAsFixed(0));
    _emoji = widget.goal.emoji;
    _priority = widget.goal.priority;
    _targetDate = widget.goal.targetDate;
  }

  @override
  void dispose() { _nc.dispose(); _tc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.read<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      child: Form(key: _fk, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SheetHandle(),
        Text('Edit Goal', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        Row(children: [
          GestureDetector(onTap: () => _pick(context), child: Container(width: 54, height: 54, decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.divider)), alignment: Alignment.center, child: Text(_emoji, style: const TextStyle(fontSize: 26)))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: _nc, decoration: const InputDecoration(labelText: 'Goal name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
        ]),
        const SizedBox(height: 12),
        TextFormField(controller: _tc, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))], decoration: const InputDecoration(labelText: 'Target amount', prefixText: '₱  '), validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null),
        const SizedBox(height: 16),
        const SectionLabel('Priority'),
        AppSegmented<GoalPriority>(value: _priority, values: GoalPriority.values, labels: const ['Low', 'Medium', 'High'], onChanged: (v) => setState(() => _priority = v)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime(2040));
            if (d != null) setState(() => _targetDate = d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.divider)),
            child: Row(children: [
              Icon(Icons.calendar_month_outlined, size: 16, color: colors.textSecondary), const SizedBox(width: 10),
              Expanded(child: Text(_targetDate == null ? 'Set target date' : dateFmt.format(_targetDate!), style: GoogleFonts.inter(fontSize: 13, color: _targetDate == null ? colors.textMuted : colors.textPrimary))),
              if (_targetDate != null) GestureDetector(onTap: () => setState(() => _targetDate = null), child: Icon(Icons.close_rounded, size: 16, color: colors.textMuted)),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            if (!_fk.currentState!.validate()) return;
            p.updateSavingsGoal(SavingsGoal(
              id: widget.goal.id, name: _nc.text.trim(), emoji: _emoji,
              targetAmount: double.parse(_tc.text.trim()), savedAmount: widget.goal.savedAmount,
              targetDate: _targetDate, priority: _priority,
              linkedAccountId: widget.goal.linkedAccountId,
              isCompleted: widget.goal.isCompleted, createdAt: widget.goal.createdAt,
              contributions: widget.goal.contributions,
            ));
            Navigator.pop(context);
          },
          child: const Text('Save Changes'),
        )),
      ])),
    );
  }

  void _pick(BuildContext ctx) {
    final colors = Theme.of(ctx).extension<AppColors>()!;
    showModalBottomSheet(context: ctx, builder: (ctx) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SheetHandle(),
        Wrap(spacing: 10, runSpacing: 10, children: _kGoalEmojis.map((e) => GestureDetector(
          onTap: () { setState(() => _emoji = e); Navigator.pop(ctx); },
          child: Container(width: 48, height: 48, decoration: BoxDecoration(color: e == _emoji ? kSavingsColor.withOpacity(0.15) : colors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: e == _emoji ? kSavingsColor.withOpacity(0.5) : colors.divider)), alignment: Alignment.center, child: Text(e, style: const TextStyle(fontSize: 22))),
        )).toList()),
        const SizedBox(height: 12),
      ]),
    ));
  }
}

// ── Small icon button inside goal card ────────────────────────────────────────
class _Btn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _Btn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9), border: Border.all(color: color.withOpacity(0.25))),
    child: Icon(icon, size: 15, color: color),
  ));
}

// ── Bank Card (original, unchanged) ──────────────────────────────────────────
class _BankCard extends StatelessWidget {
  final BankAccount account;
  const _BankCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final p = context.read<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: kSavingsColor.withOpacity(colors.isDark ? 0.15 : 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.account_balance_outlined, size: 20, color: kSavingsColor)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(account.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          Text(account.bankName, style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
        ])),
        GestureDetector(onTap: () => _del(context, p), child: Icon(Icons.delete_outline_rounded, size: 18, color: colors.textMuted)),
      ]),
      const SizedBox(height: 14),
      Text(pesoFmt.format(account.balance), style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: account.balance < 0 ? kDangerColor : colors.textPrimary)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: ActionPill(label: 'Deposit', color: kSuccessColor, icon: Icons.arrow_downward_rounded, onTap: () => _tx(context, p, true))),
        const SizedBox(width: 8),
        Expanded(child: ActionPill(label: 'Withdraw', color: kDangerColor, icon: Icons.arrow_upward_rounded, onTap: () => _tx(context, p, false))),
      ]),
      if (account.transactions.isNotEmpty) ...[
        const SizedBox(height: 14),
        Divider(color: colors.divider),
        const SizedBox(height: 10),
        Text('Recent', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        ...account.transactions.take(4).map((tx) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: tx.amount > 0 ? kSuccessColor.withOpacity(0.1) : kDangerColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(tx.amount > 0 ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 13, color: tx.amount > 0 ? kSuccessColor : kDangerColor)),
            const SizedBox(width: 10),
            Expanded(child: Text(tx.description, style: GoogleFonts.inter(fontSize: 13, color: colors.textPrimary), overflow: TextOverflow.ellipsis)),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(pesoFmt.format(tx.amount.abs()), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: tx.amount > 0 ? kSuccessColor : kDangerColor)),
              Text(shortDateFmt.format(tx.date), style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted)),
            ]),
          ]),
        )),
      ],
    ]));
  }

  void _tx(BuildContext ctx, AppProvider p, bool dep) {
    final ac = TextEditingController(), dc = TextEditingController(text: dep ? 'Deposit' : 'Withdrawal');
    final fk = GlobalKey<FormState>();
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Form(key: fk, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SheetHandle(),
        Text(dep ? 'Add Deposit' : 'Record Withdrawal', style: Theme.of(ctx).textTheme.headlineSmall),
        const SizedBox(height: 20),
        buildAmountField(controller: ac),
        const SizedBox(height: 12),
        TextFormField(controller: dc, decoration: const InputDecoration(labelText: 'Description'), validator: (v) => v!.isEmpty ? 'Required' : null),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            if (!fk.currentState!.validate()) return;
            final amt = double.parse(ac.text.trim());
            p.addBankTransaction(account.id, BankTransaction(id: p.newId(), description: dc.text.trim(), amount: dep ? amt : -amt, date: DateTime.now()));
            Navigator.pop(ctx);
          },
          child: Text(dep ? 'Add Deposit' : 'Record Withdrawal'),
        )),
      ])),
    ));
  }

  void _del(BuildContext ctx, AppProvider p) {
    showDialog(context: ctx, builder: (d) => AlertDialog(
      title: const Text('Delete Account'),
      content: Text('Delete "${account.name}"?'),
      actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')), TextButton(onPressed: () { p.deleteBankAccount(account.id); Navigator.pop(d); }, child: Text('Delete', style: TextStyle(color: kDangerColor)))],
    ));
  }
}
