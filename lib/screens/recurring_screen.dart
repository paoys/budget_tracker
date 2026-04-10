// lib/screens/recurring_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/shared_widgets.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final active   = p.recurringTemplates.where((t) => t.isActive).toList();
    final inactive = p.recurringTemplates.where((t) => !t.isActive).toList();
    final due      = p.overdueRecurring;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BudgetWise', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textMuted, letterSpacing: 1)),
          Text('Recurring', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary, letterSpacing: -0.3)),
        ]),
        toolbarHeight: 60,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_recurring_fab',
        onPressed: () => _showAddRecurring(context),
        backgroundColor: colors.textPrimary,
        foregroundColor: colors.bg,
        icon: const Icon(Icons.add, size: 18),
        label: Text('Add Recurring', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Summary
          if (p.recurringTemplates.isNotEmpty) ...[
            Row(children: [
              Expanded(child: StatTile(label: 'Active', value: active.length.toDouble(), icon: Icons.repeat_rounded, isCurrency: false)),
              const SizedBox(width: 10),
              Expanded(child: StatTile(
                label: 'Monthly Cost',
                value: active.fold(0.0, (s, t) => s + _monthlyEquivalent(t)),
                accentColor: kDangerColor,
                icon: Icons.currency_exchange_rounded,
              )),
            ]),
            const SizedBox(height: 16),
          ],

          // Due now banner
          if (due.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kNeedsColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kNeedsColor.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.alarm_rounded, size: 15, color: kNeedsColor),
                  const SizedBox(width: 8),
                  Text('${due.length} recurring item${due.length > 1 ? "s" : ""} due now', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: kNeedsColor)),
                ]),
                const SizedBox(height: 10),
                ...due.map((t) => _DueRow(template: t, provider: p)),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          if (p.recurringTemplates.isEmpty)
            const EmptyState(
              icon: Icons.repeat_rounded,
              title: 'No recurring transactions',
              message: 'Add recurring expenses like rent, subscriptions, or utilities that repeat automatically.',
            )
          else ...[
            if (active.isNotEmpty) ...[
              const SectionLabel('Active'),
              ...active.map((t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _RecurringCard(template: t, provider: p))),
            ],
            if (inactive.isNotEmpty) ...[
              const SizedBox(height: 8),
              const SectionLabel('Ended'),
              ...inactive.map((t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _RecurringCard(template: t, provider: p, faded: true))),
            ],
          ],
        ],
      ),
    );
  }

  double _monthlyEquivalent(RecurringTemplate t) {
    switch (t.frequency) {
      case RecurringFrequency.daily:   return t.amount * 30;
      case RecurringFrequency.weekly:  return t.amount * 4.33;
      case RecurringFrequency.monthly: return t.amount;
      case RecurringFrequency.yearly:  return t.amount / 12;
    }
  }

  void _showAddRecurring(BuildContext ctx) {
    final p = ctx.read<AppProvider>();
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    CategoryType selectedCat = CategoryType.needs;
    PaymentMode selectedPayment = PaymentMode.cash;
    RecurringFrequency selectedFreq = RecurringFrequency.monthly;
    String? selectedSubId;
    String? selectedCCId;
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        final subs = p.subCategoriesByType(selectedCat);
        return SingleChildScrollView(
          padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            Text('Add Recurring Transaction', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('This will remind you to log it each time it\'s due.', style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 20),
            buildAmountField(controller: amountCtrl),
            const SizedBox(height: 12),
            TextFormField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Netflix, Rent, Electric Bill', prefixIcon: Icon(Icons.repeat_rounded, size: 18)), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            const SectionLabel('Frequency'),
            _FrequencySelector(value: selectedFreq, onChanged: (v) => ss(() => selectedFreq = v)),
            const SizedBox(height: 16),
            const SectionLabel('Category'),
            CategorySelector(value: selectedCat, onChanged: (v) => ss(() { selectedCat = v; selectedSubId = null; })),
            if (subs.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedSubId,
                decoration: const InputDecoration(labelText: 'Sub-category (optional)'),
                items: [const DropdownMenuItem(value: null, child: Text('None')), ...subs.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))],
                onChanged: (v) => ss(() => selectedSubId = v),
              ),
            ],
            const SizedBox(height: 16),
            const SectionLabel('Payment Method'),
            DropdownButtonFormField<PaymentMode>(
              value: selectedPayment,
              decoration: const InputDecoration(labelText: 'How do you pay?'),
              items: PaymentMode.values.map((m) {
                final labels = ['Cash', 'Credit Card', 'Debit Card', 'GCash', 'Maya', 'Bank Transfer', 'Other'];
                return DropdownMenuItem(value: m, child: Text(labels[m.index]));
              }).toList(),
              onChanged: (v) => ss(() { selectedPayment = v!; if (v != PaymentMode.creditCard) selectedCCId = null; }),
            ),
            if (selectedPayment == PaymentMode.creditCard && p.creditCards.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCCId,
                decoration: const InputDecoration(labelText: 'Credit Card'),
                items: p.creditCards.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => ss(() => selectedCCId = v),
              ),
            ],
            const SizedBox(height: 16),
            // Start date
            _DateRow(label: 'Starts', date: startDate, onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
              if (d != null) ss(() => startDate = d);
            }),
            const SizedBox(height: 10),
            // End date (optional)
            _DateRow(
              label: 'Ends (optional)',
              date: endDate,
              placeholder: 'No end date',
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: endDate ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime(2040));
                ss(() => endDate = d);
              },
              trailing: endDate != null ? GestureDetector(
                onTap: () => ss(() => endDate = null),
                child: const Icon(Icons.close, size: 14, color: kDangerColor),
              ) : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes_outlined, size: 18)), maxLines: 2),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                p.addRecurringTemplate(RecurringTemplate(
                  id: p.newId(),
                  title: titleCtrl.text.trim(),
                  amount: double.parse(amountCtrl.text.trim()),
                  category: selectedCat,
                  subCategoryId: selectedSubId,
                  paymentMode: selectedPayment,
                  frequency: selectedFreq,
                  startDate: startDate,
                  endDate: endDate,
                  creditCardId: selectedCCId,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Add Recurring Transaction'),
            )),
          ])),
        );
      }),
    );
  }
}

// ─── Due Row ─────────────────────────────────────────────────────────────────
class _DueRow extends StatelessWidget {
  final RecurringTemplate template;
  final AppProvider provider;
  const _DueRow({required this.template, required this.provider});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(template.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).extension<AppColors>()!.textPrimary)),
        Text('${template.frequencyLabel} · ${pesoFmt.format(template.amount)}', style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).extension<AppColors>()!.textSecondary)),
      ])),
      GestureDetector(
        onTap: () => provider.skipRecurringTemplate(template.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(8), border: Border.all(color: kNeedsColor.withOpacity(0.3))),
          child: Text('Skip', style: GoogleFonts.inter(fontSize: 12, color: kNeedsColor, fontWeight: FontWeight.w500)),
        ),
      ),
      GestureDetector(
        onTap: () => provider.processRecurringTemplate(template.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: kNeedsColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Text('Log Now', style: GoogleFonts.inter(fontSize: 12, color: kNeedsColor, fontWeight: FontWeight.w700)),
        ),
      ),
    ]),
  );
}

// ─── Recurring Card ───────────────────────────────────────────────────────────
class _RecurringCard extends StatelessWidget {
  final RecurringTemplate template;
  final AppProvider provider;
  final bool faded;
  const _RecurringCard({required this.template, required this.provider, this.faded = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final c = colors.forCategory(template.category);
    final isDue = template.isDue && template.isActive;

    return Opacity(
      opacity: faded ? 0.5 : 1.0,
      child: AppCard(
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: c.withOpacity(colors.isDark ? 0.15 : 0.1), borderRadius: BorderRadius.circular(12)),
            child: Stack(alignment: Alignment.center, children: [
              Icon(_freqIcon(template.frequency), size: 20, color: c),
              if (isDue) Positioned(top: 4, right: 4, child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: kWarningColor, shape: BoxShape.circle),
              )),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(template.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                child: Text(template.frequencyLabel, style: GoogleFonts.inter(fontSize: 10, color: c, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              CategoryChip(category: template.category),
            ]),
            const SizedBox(height: 3),
            if (template.lastProcessed != null)
              Text('Last logged: ${shortDateFmt.format(template.lastProcessed!)}', style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted))
            else
              Text('Starts: ${shortDateFmt.format(template.startDate)}', style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted)),
            if (template.endDate != null)
              Text('Ends: ${dateFmt.format(template.endDate!)}', style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted)),
            if (isDue)
              Text('⚡ Due now — next: ${dateFmt.format(template.nextDueDate)}', style: GoogleFonts.inter(fontSize: 10, color: kWarningColor, fontWeight: FontWeight.w600)),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(pesoFmt.format(template.amount), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 8),
            Row(children: [
              if (isDue) ...[
                _IconBtn(Icons.play_arrow_rounded, kSuccessColor, () => provider.processRecurringTemplate(template.id)),
                const SizedBox(width: 4),
              ],
              _IconBtn(Icons.edit_outlined, colors.textSecondary, () => _editDialog(context, provider, template)),
              const SizedBox(width: 4),
              _IconBtn(Icons.delete_outline_rounded, kDangerColor, () => _deleteDialog(context, provider, template.id)),
            ]),
          ]),
        ]),
      ),
    );
  }

  IconData _freqIcon(RecurringFrequency f) {
    switch (f) {
      case RecurringFrequency.daily:   return Icons.today_rounded;
      case RecurringFrequency.weekly:  return Icons.view_week_rounded;
      case RecurringFrequency.monthly: return Icons.calendar_month_rounded;
      case RecurringFrequency.yearly:  return Icons.event_repeat_rounded;
    }
  }

  void _editDialog(BuildContext ctx, AppProvider p, RecurringTemplate t) {
    final titleCtrl  = TextEditingController(text: t.title);
    final amountCtrl = TextEditingController(text: t.amount.toStringAsFixed(0));
    final formKey    = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Text('Edit ${t.title}', style: Theme.of(ctx).textTheme.headlineSmall),
          const SizedBox(height: 20),
          TextFormField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title'), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          buildAmountField(controller: amountCtrl),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final updated = RecurringTemplate(
                id: t.id, title: titleCtrl.text.trim(), amount: double.parse(amountCtrl.text.trim()),
                category: t.category, subCategoryId: t.subCategoryId, paymentMode: t.paymentMode,
                frequency: t.frequency, startDate: t.startDate, endDate: t.endDate,
                creditCardId: t.creditCardId, notes: t.notes, lastProcessed: t.lastProcessed,
              );
              p.updateRecurringTemplate(updated);
              Navigator.pop(ctx);
            },
            child: const Text('Save Changes'),
          )),
        ])),
      ),
    );
  }

  void _deleteDialog(BuildContext ctx, AppProvider p, String id) {
    showDialog(context: ctx, builder: (ctx) => AlertDialog(
      title: const Text('Delete Recurring'),
      content: const Text('This will stop the recurring reminder but won\'t delete past expenses.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () { p.deleteRecurringTemplate(id); Navigator.pop(ctx); }, child: Text('Delete', style: TextStyle(color: kDangerColor))),
      ],
    ));
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

// ─── Frequency Selector ───────────────────────────────────────────────────────
class _FrequencySelector extends StatelessWidget {
  final RecurringFrequency value;
  final ValueChanged<RecurringFrequency> onChanged;
  const _FrequencySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final freqs = RecurringFrequency.values;
    final labels = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
    final icons  = [Icons.today_rounded, Icons.view_week_rounded, Icons.calendar_month_rounded, Icons.event_repeat_rounded];

    return Wrap(spacing: 8, runSpacing: 8, children: List.generate(freqs.length, (i) {
      final sel = freqs[i] == value;
      return GestureDetector(
        onTap: () => onChanged(freqs[i]),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? colors.textPrimary : colors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? colors.textPrimary : colors.divider),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icons[i], size: 14, color: sel ? colors.bg : colors.textSecondary),
            const SizedBox(width: 6),
            Text(labels[i], style: GoogleFonts.inter(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? colors.bg : colors.textSecondary)),
          ]),
        ),
      );
    }));
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String? placeholder;
  final VoidCallback onTap;
  final Widget? trailing;
  const _DateRow({required this.label, this.date, this.placeholder, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.divider)),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 16, color: colors.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted)),
          const SizedBox(width: 10),
          Expanded(child: Text(date != null ? dateFmt.format(date!) : placeholder ?? 'Select date', style: GoogleFonts.inter(fontSize: 13, color: date != null ? colors.textPrimary : colors.textMuted))),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}
