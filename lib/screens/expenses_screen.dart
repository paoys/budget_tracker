// lib/screens/expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/shared_widgets.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  CategoryType? _filter;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final filtered = (_filter == null ? p.expenses : p.expenses.where((e) => e.category == _filter).toList())..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_expenses_fab',
        onPressed: () => _showAddExpense(context),
        backgroundColor: colors.textPrimary,
        foregroundColor: colors.bg,
        icon: const Icon(Icons.add, size: 18),
        label: Text('Log Expense', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        elevation: 0,
      ),
      body: Column(children: [
        Container(
          color: colors.bg,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            Expanded(child: StatTile(label: 'Spent', value: p.totalSpent, icon: Icons.trending_up_rounded)),
            const SizedBox(width: 10),
            Expanded(child: StatTile(label: 'Remaining', value: p.remainingTotal, accentColor: p.remainingTotal < 0 ? kDangerColor : kSuccessColor, icon: Icons.account_balance_wallet_outlined)),
          ]),
        ),
        Container(
          color: colors.bg,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _Pill('All', _filter == null, colors, () => setState(() => _filter = null)),
              const SizedBox(width: 8),
              _CategoryPill(CategoryType.needs, _filter, colors, () => setState(() => _filter = _filter == CategoryType.needs ? null : CategoryType.needs)),
              const SizedBox(width: 8),
              _CategoryPill(CategoryType.wants, _filter, colors, () => setState(() => _filter = _filter == CategoryType.wants ? null : CategoryType.wants)),
              const SizedBox(width: 8),
              _CategoryPill(CategoryType.savings, _filter, colors, () => setState(() => _filter = _filter == CategoryType.savings ? null : CategoryType.savings)),
            ]),
          ),
        ),
        Divider(height: 1, color: colors.divider),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'No expenses', message: 'Log your first expense to start tracking.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _ExpenseCard(expense: filtered[i], provider: p),
                ),
        ),
      ]),
    );
  }

  void _showAddExpense(BuildContext ctx) {
    final p = ctx.read<AppProvider>();
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    CategoryType selectedCat = CategoryType.needs;
    PaymentMode selectedPayment = PaymentMode.cash;
    String? selectedSubId;
    String? selectedCCId;
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        final subs = p.subCategoriesByType(selectedCat);
        return SingleChildScrollView(
          padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            Text('Log Expense', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 20),
            buildAmountField(controller: amountCtrl),
            const SizedBox(height: 12),
            TextFormField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.edit_outlined, size: 18)), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 20),
            const SectionLabel('Category'),
            CategorySelector(value: selectedCat, onChanged: (v) => ss(() { selectedCat = v; selectedSubId = null; })),
            if (subs.isNotEmpty) ...[
              const SizedBox(height: 16),
              const SectionLabel('Sub-category'),
              DropdownButtonFormField<String>(
                value: selectedSubId,
                decoration: const InputDecoration(labelText: 'Select sub-category (optional)'),
                items: [const DropdownMenuItem(value: null, child: Text('None')), ...subs.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))],
                onChanged: (v) => ss(() => selectedSubId = v),
              ),
            ],
            const SizedBox(height: 16),
            const SectionLabel('Payment Method'),
            DropdownButtonFormField<PaymentMode>(
              value: selectedPayment,
              decoration: const InputDecoration(labelText: 'How did you pay?'),
              items: PaymentMode.values.map((m) {
                final icons = [Icons.payments_outlined, Icons.credit_card, Icons.credit_card_outlined, Icons.phone_android, Icons.phone_android_outlined, Icons.account_balance_outlined, Icons.more_horiz];
                final labels = ['Cash', 'Credit Card', 'Debit Card', 'GCash', 'Maya', 'Bank Transfer', 'Other'];
                return DropdownMenuItem(value: m, child: Row(children: [Icon(icons[m.index], size: 16), const SizedBox(width: 8), Text(labels[m.index])]));
              }).toList(),
              onChanged: (v) => ss(() { selectedPayment = v!; if (v != PaymentMode.creditCard) selectedCCId = null; }),
            ),
            if (selectedPayment == PaymentMode.creditCard && p.creditCards.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCCId,
                decoration: const InputDecoration(labelText: 'Select Card'),
                items: p.creditCards.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => ss(() => selectedCCId = v),
                validator: (v) => selectedPayment == PaymentMode.creditCard && v == null ? 'Pick a card' : null,
              ),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) ss(() => selectedDate = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Theme.of(ctx).extension<AppColors>()!.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(ctx).extension<AppColors>()!.divider)),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined, size: 18, color: Theme.of(ctx).extension<AppColors>()!.textSecondary),
                  const SizedBox(width: 10),
                  Text(dateFmt.format(selectedDate), style: GoogleFonts.inter(fontSize: 14, color: Theme.of(ctx).extension<AppColors>()!.textPrimary)),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 16, color: Theme.of(ctx).extension<AppColors>()!.textMuted),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes_outlined, size: 18)), maxLines: 2),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                p.addExpense(Expense(id: p.newId(), title: titleCtrl.text.trim(), amount: double.parse(amountCtrl.text.trim()), category: selectedCat, subCategoryId: selectedSubId, paymentMode: selectedPayment, date: selectedDate, notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(), creditCardId: selectedCCId));
                Navigator.pop(ctx);
              },
              child: const Text('Log Expense'),
            )),
          ])),
        );
      }),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final AppProvider provider;
  const _ExpenseCard({required this.expense, required this.provider});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final c = colors.forCategory(expense.category);
    final sub = expense.subCategoryId != null ? provider.subCategories.where((s) => s.id == expense.subCategoryId).firstOrNull : null;
    final cc  = expense.creditCardId  != null ? provider.creditCards.where((card) => card.id == expense.creditCardId).firstOrNull : null;

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: kDangerColor.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.delete_outline_rounded, color: kDangerColor), Text('Delete', style: GoogleFonts.inter(fontSize: 11, color: kDangerColor, fontWeight: FontWeight.w600))]),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Remove "${expense.title}"?'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: kDangerColor)))],
      )),
      onDismissed: (_) => provider.deleteExpense(expense.id),
      child: AppCard(child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: c.withOpacity(colors.isDark ? 0.15 : 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(_catIcon(expense.category), size: 20, color: c)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(expense.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Wrap(spacing: 5, runSpacing: 4, children: [
            CategoryChip(category: expense.category),
            if (sub != null) _Tag(sub.name, colors),
            if (cc  != null) _Tag('💳 ${cc.name}', colors),
          ]),
          const SizedBox(height: 3),
          Row(children: [PaymentModeChip(mode: expense.paymentMode), const SizedBox(width: 8), Text('·', style: TextStyle(color: colors.textMuted)), const SizedBox(width: 8), Text(shortDateFmt.format(expense.date), style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted))]),
          if (expense.notes != null && expense.notes!.isNotEmpty)
            Text(expense.notes!, style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 10),
        Text(pesoFmt.format(expense.amount), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
      ])),
    );
  }

  IconData _catIcon(CategoryType t) => t == CategoryType.needs ? Icons.home_outlined : t == CategoryType.wants ? Icons.shopping_bag_outlined : Icons.savings_outlined;
}

class _Tag extends StatelessWidget {
  final String label; final AppColors colors;
  const _Tag(this.label, this.colors);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(5)), child: Text(label, style: GoogleFonts.inter(fontSize: 10, color: colors.textSecondary)));
}

class _Pill extends StatelessWidget {
  final String label; final bool selected; final AppColors colors; final VoidCallback onTap;
  const _Pill(this.label, this.selected, this.colors, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: selected ? colors.textPrimary : colors.surface2, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? colors.textPrimary : colors.divider)), child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? colors.bg : colors.textSecondary))));
}

class _CategoryPill extends StatelessWidget {
  final CategoryType type; final CategoryType? selected; final AppColors colors; final VoidCallback onTap;
  const _CategoryPill(this.type, this.selected, this.colors, this.onTap);
  @override
  Widget build(BuildContext context) {
    final isSelected = selected == type;
    final c = colors.forCategory(type);
    final label = type.name[0].toUpperCase() + type.name.substring(1);
    return GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: isSelected ? c.withOpacity(colors.isDark ? 0.2 : 0.12) : colors.surface2, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? c.withOpacity(0.6) : colors.divider)), child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? c : colors.textSecondary))));
  }
}
