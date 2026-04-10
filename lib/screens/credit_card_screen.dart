// lib/screens/credit_card_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/shared_widgets.dart';

class CreditCardScreen extends StatelessWidget {
  const CreditCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final totalOwed = p.creditCards.fold(0.0, (s, c) => s + c.balance);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_card_fab',
        onPressed: () => _showAddCard(context),
        backgroundColor: colors.textPrimary,
        foregroundColor: colors.bg,
        icon: const Icon(Icons.add, size: 18),
        label: Text('Add Card', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (p.creditCards.isNotEmpty) ...[
            Row(children: [
              Expanded(child: StatTile(label: 'Total Owed', value: totalOwed, accentColor: totalOwed > 0 ? kDangerColor : kSuccessColor, icon: Icons.credit_card)),
              const SizedBox(width: 10),
              Expanded(child: StatTile(label: 'Cards', value: p.creditCards.length.toDouble(), icon: Icons.layers_outlined, isCurrency: false)),
            ]),
            const SizedBox(height: 20),
          ],
          if (p.creditCards.isEmpty)
            const EmptyState(icon: Icons.credit_card_outlined, title: 'No credit cards', message: 'Add your credit cards to track bills and get due-date reminders.')
          else ...[
            const SectionLabel('My Cards'),
            ...p.creditCards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _CreditCardWidget(card: card))),
          ],
        ],
      ),
    );
  }

  void _showAddCard(BuildContext ctx) {
    final p = ctx.read<AppProvider>();
    final nameCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    int statDay = 25, dueDay = 20;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => SingleChildScrollView(
        padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Text('Add Credit Card', style: Theme.of(ctx).textTheme.headlineSmall),
          const SizedBox(height: 20),
          TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Card Name', hintText: 'e.g. BPI Gold Rewards', prefixIcon: Icon(Icons.credit_card_outlined, size: 18)), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'Bank', hintText: 'e.g. BPI, BDO, Metrobank', prefixIcon: Icon(Icons.account_balance_outlined, size: 18)), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          buildAmountField(controller: limitCtrl, label: 'Credit Limit'),
          const SizedBox(height: 20),
          const SectionLabel('Statement Cut-off Day'),
          _DayPicker(value: statDay, onChanged: (v) => ss(() => statDay = v)),
          const SizedBox(height: 16),
          const SectionLabel('Payment Due Day'),
          _DayPicker(value: dueDay, onChanged: (v) => ss(() => dueDay = v)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              p.addCreditCard(CreditCard(id: p.newId(), name: nameCtrl.text.trim(), bank: bankCtrl.text.trim(), creditLimit: double.parse(limitCtrl.text.trim()), balance: 0, statementDay: statDay, dueDay: dueDay));
              Navigator.pop(ctx);
            },
            child: const Text('Add Card'),
          )),
        ])),
      )),
    );
  }
}

class _CreditCardWidget extends StatefulWidget {
  final CreditCard card;
  const _CreditCardWidget({required this.card});
  @override
  State<_CreditCardWidget> createState() => _CreditCardWidgetState();
}

class _CreditCardWidgetState extends State<_CreditCardWidget> {
  bool _showAllTx = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    // Re-fetch card from provider so it reflects paid state updates
    final card = p.creditCards.firstWhere((c) => c.id == widget.card.id, orElse: () => widget.card);
    final colors = Theme.of(context).extension<AppColors>()!;
    final util = card.creditLimit > 0 ? (card.balance / card.creditLimit).clamp(0.0, 1.0) : 0.0;

    // Previous (closed) statement — these are what's actually DUE now
    final prevStatTxs = card.previousStatementTransactions;
    final unpaidStatBal = card.currentStatementBalance; // unpaid from previous statement
    final hasBillAlert = card.hasBillDue;
    final dueColor = card.daysUntilDue <= 3 ? kDangerColor : card.daysUntilDue <= 7 ? kWarningColor : colors.textSecondary;
    // Current (open) statement — transactions after last cutoff, not yet due
    final statTxs = card.currentStatementTransactions;

    // Sort all transactions by date desc (latest first)
    final sortedTxs = [...card.transactions]..sort((a, b) => b.date.compareTo(a.date));
    final displayTxs = _showAllTx ? sortedTxs : sortedTxs.take(5).toList();

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Visual card face
      Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(card.bank, style: GoogleFonts.inter(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w500)),
              Text(card.name, style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
            const Icon(Icons.credit_card_rounded, color: Colors.white30, size: 28),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('OUTSTANDING', style: GoogleFonts.inter(fontSize: 9, color: Colors.white38, letterSpacing: 1)),
              Text(pesoFmt.format(card.balance), style: GoogleFonts.plusJakartaSans(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('AVAILABLE', style: GoogleFonts.inter(fontSize: 9, color: Colors.white38, letterSpacing: 1)),
              Text(pesoFmt.format(card.availableCredit), style: GoogleFonts.plusJakartaSans(fontSize: 16, color: kSuccessColor, fontWeight: FontWeight.w700)),
            ]),
          ]),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: util, backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(util > 0.9 ? kDangerColor : util > 0.7 ? kWarningColor : kSuccessColor), minHeight: 4)),
          const SizedBox(height: 6),
          Text('${(util * 100).toStringAsFixed(0)}% utilization · Limit ${shortPesoFmt.format(card.creditLimit)}', style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
        ]),
      ),
      const SizedBox(height: 14),

      // Statement period info
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Previous Statement', style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w500)),
            Text('${shortDateFmt.format(card.prevStatementDate)} – ${shortDateFmt.format(card.lastStatementDate)}',
              style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Billed amount', style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w500)),
            Text(pesoFmt.format(prevStatTxs.fold(0.0, (s, t) => s + t.amount)),
              style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Unpaid (due ${shortDateFmt.format(card.nextDueDate)})', style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w500)),
            Text(pesoFmt.format(unpaidStatBal),
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: unpaidStatBal > 0 ? kDangerColor : kSuccessColor)),
          ]),
          if (statTxs.isNotEmpty) ...[
            const Divider(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Current period (not yet due)', style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w500)),
              Text(pesoFmt.format(statTxs.fold(0.0, (s, t) => s + t.amount)),
                style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.w600)),
            ]),
          ],
        ]),
      ),
      const SizedBox(height: 10),

      // Due date banner — only shown when there's an actual bill due from this statement
      if (hasBillAlert)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: dueColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: dueColor.withOpacity(0.25)),
          ),
          child: Row(children: [
            Icon(Icons.notifications_active_rounded, size: 15, color: dueColor),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Payment Due ${dateFmt.format(card.nextDueDate)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: dueColor)),
              Text('${pesoFmt.format(unpaidStatBal)} unpaid from current statement', style: GoogleFonts.inter(fontSize: 11, color: dueColor.withOpacity(0.8))),
            ])),
            Text('${card.daysUntilDue}d', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: dueColor)),
          ]),
        )
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined, size: 15, color: colors.textMuted),
            const SizedBox(width: 8),
            Text('Next due: ${dateFmt.format(card.nextDueDate)}', style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary)),
            const Spacer(),
            Text('${card.daysUntilDue} days', style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted)),
          ]),
        ),
      const SizedBox(height: 12),

      // Actions
      Row(children: [
        Expanded(child: ActionPill(label: 'Add Charge', color: kDangerColor, icon: Icons.add_rounded, onTap: () => _addCharge(context, p, card))),
        const SizedBox(width: 8),
        Expanded(child: ActionPill(label: 'Pay Bill', color: kSuccessColor, icon: Icons.check_rounded, onTap: () => _payBill(context, p, card))),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _confirmDelete(context, p, card),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kDangerColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: kDangerColor.withOpacity(0.25))),
            child: const Icon(Icons.delete_outline_rounded, size: 16, color: kDangerColor),
          ),
        ),
      ]),

      // Transactions list — sorted by date (latest first)
      if (card.transactions.isNotEmpty) ...[
        const SizedBox(height: 14),
        Divider(color: colors.divider),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Transactions', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textMuted, letterSpacing: 0.5)),
          GestureDetector(
            onTap: () => setState(() => _showAllTx = !_showAllTx),
            child: Text(_showAllTx ? 'Show less' : 'Show all (${card.transactions.length})',
              style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.w500)),
          ),
        ]),
        const SizedBox(height: 8),
        ...displayTxs.map((tx) => _TxTile(tx: tx, card: card, provider: p)),
      ],
    ]));
  }

  void _addCharge(BuildContext ctx, AppProvider p, CreditCard card) {
    final descCtrl   = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime date    = DateTime.now();
    final formKey    = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Text('Add Charge — ${card.name}', style: Theme.of(ctx).textTheme.headlineSmall),
          const SizedBox(height: 6),
          // Show statement period
          _StatementInfo(card: card, ctx: ctx),
          const SizedBox(height: 16),
          buildAmountField(controller: amountCtrl),
          const SizedBox(height: 12),
          TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
              if (d != null) ss(() => date = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Theme.of(ctx).extension<AppColors>()!.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(ctx).extension<AppColors>()!.divider)),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: Theme.of(ctx).extension<AppColors>()!.textSecondary),
                const SizedBox(width: 10),
                Text(dateFmt.format(date)),
                const Spacer(),
                // Hint whether date is in current statement
                _InStatementBadge(date: date, card: card, ctx: ctx),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              p.addCreditCardTransaction(card.id, CreditCardTransaction(id: p.newId(), description: descCtrl.text.trim(), amount: double.parse(amountCtrl.text.trim()), date: date));
              Navigator.pop(ctx);
            },
            child: const Text('Add Charge'),
          )),
        ])),
      )),
    );
  }

  void _payBill(BuildContext ctx, AppProvider p, CreditCard card) {
    // Show only unpaid transactions from the current statement period
    final statUnpaid = card.previousStatementTransactions.where((t) => !t.isPaid).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (statUnpaid.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('No unpaid charges from the previous statement.')));
      return;
    }

    showModalBottomSheet(
      context: ctx,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Text('Pay Bill — ${card.name}', style: Theme.of(ctx).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Current statement: ${dateFmt.format(card.lastStatementDate)} – ${dateFmt.format(card.nextStatementDate)}\n'
            'Total unpaid: ${pesoFmt.format(statUnpaid.fold(0.0, (s, t) => s + t.amount))}',
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...statUnpaid.map((tx) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: kDangerColor.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.receipt_outlined, size: 16, color: kDangerColor)),
            title: Text(tx.description, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
            subtitle: Text(dateFmt.format(tx.date), style: GoogleFonts.inter(fontSize: 11)),
            trailing: Text(pesoFmt.format(tx.amount), style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            onTap: () { p.markCreditCardPaid(card.id, tx.id); Navigator.pop(ctx); },
          )),
          // Pay all button
          if (statUnpaid.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () {
                for (final tx in statUnpaid) p.markCreditCardPaid(card.id, tx.id);
                Navigator.pop(ctx);
              },
              child: Text('Pay All (${pesoFmt.format(statUnpaid.fold(0.0, (s, t) => s + t.amount))})'),
            )),
          ],
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, AppProvider p, CreditCard card) {
    showDialog(context: ctx, builder: (ctx) => AlertDialog(
      title: const Text('Delete Card'),
      content: Text('Delete "${card.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () { p.deleteCreditCard(card.id); Navigator.pop(ctx); }, child: Text('Delete', style: TextStyle(color: kDangerColor))),
      ],
    ));
  }
}

// ─── Statement Info Widget ────────────────────────────────────────────────────
class _StatementInfo extends StatelessWidget {
  final CreditCard card;
  final BuildContext ctx;
  const _StatementInfo({required this.card, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(Icons.info_outline, size: 13, color: colors.textMuted),
        const SizedBox(width: 8),
        Text('Current statement: ${shortDateFmt.format(card.lastStatementDate)} – ${shortDateFmt.format(card.nextStatementDate)}',
          style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary)),
      ]),
    );
  }
}

class _InStatementBadge extends StatelessWidget {
  final DateTime date;
  final CreditCard card;
  final BuildContext ctx;
  const _InStatementBadge({required this.date, required this.card, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final inStatement = !date.isBefore(card.lastStatementDate) && date.isBefore(card.nextStatementDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: inStatement ? kSuccessColor.withOpacity(0.12) : kWarningColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        inStatement ? 'Current period' : 'Previous statement',
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: inStatement ? kSuccessColor : kWarningColor),
      ),
    );
  }
}

// ─── Transaction Tile ─────────────────────────────────────────────────────────
class _TxTile extends StatelessWidget {
  final CreditCardTransaction tx;
  final CreditCard card;
  final AppProvider provider;
  const _TxTile({required this.tx, required this.card, required this.provider});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    // Is this tx in the CURRENT open period (after last cutoff, not yet billed)?
    final inCurrentPeriod = !tx.date.isBefore(card.lastStatementDate) && tx.date.isBefore(card.nextStatementDate);
    // Is this tx in the PREVIOUS closed statement (billed, possibly due)?
    final inPrevStatement = !tx.date.isBefore(card.prevStatementDate) && tx.date.isBefore(card.lastStatementDate);

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(color: kDangerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.delete_outline_rounded, color: kDangerColor, size: 18),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text('Remove "${tx.description}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: kDangerColor))),
          ],
        ),
      ),
      onDismissed: (_) => provider.deleteCreditCardTransaction(card.id, tx.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tx.isPaid ? kSuccessColor : inPrevStatement ? kDangerColor : inCurrentPeriod ? kWarningColor : colors.surface3),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx.description, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary, decoration: tx.isPaid ? TextDecoration.lineThrough : null)),
            Row(children: [
              Text(dateFmt.format(tx.date), style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted)),
              if (inPrevStatement && !tx.isPaid) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: kWarningColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text('Due', style: GoogleFonts.inter(fontSize: 9, color: kDangerColor, fontWeight: FontWeight.w600)),
                ),
              ],
              if (tx.isPaid) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: kSuccessColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text('Paid', style: GoogleFonts.inter(fontSize: 9, color: kSuccessColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
          ])),
          Text(pesoFmt.format(tx.amount), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: tx.isPaid ? colors.textMuted : colors.textPrimary)),
          const SizedBox(width: 8),
          if (!tx.isPaid)
            GestureDetector(
              onTap: () => provider.markCreditCardPaid(card.id, tx.id),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: kSuccessColor.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 14, color: kSuccessColor),
              ),
            ),
        ]),
      ),
    );
  }
}

class _DayPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _DayPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 28,
        itemBuilder: (ctx, i) {
          final day = i + 1;
          final sel = day == value;
          return GestureDetector(
            onTap: () => onChanged(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 38, height: 38,
              margin: const EdgeInsets.only(right: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? colors.textPrimary : colors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? colors.textPrimary : colors.divider),
              ),
              child: Text('$day', style: GoogleFonts.inter(fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, color: sel ? colors.bg : colors.textSecondary)),
            ),
          );
        },
      ),
    );
  }
}
