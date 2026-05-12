// lib/screens/budget_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/shared_widgets.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_budget_fab',
        onPressed: () => _showAddSub(context),
        backgroundColor: colors.textPrimary,
        foregroundColor: colors.bg,
        icon: const Icon(Icons.add, size: 18),
        label: Text('Add Sub-category', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        elevation: 0,
      ),
      body: Builder(builder: (context) {
        final isWide = Breakpoints.isWide(context);
        final hPad = isWide ? 24.0 : 16.0;
        return ResponsiveCenter(
          maxWidth: 1000,
          child: ListView(
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 100),
            children: [
              _BudgetSummaryRow(p: p),
              const SizedBox(height: 20),
              if (isWide) ...[
                TwoColumnLayout(
                  left: _CategorySection(type: CategoryType.needs,   label: 'Needs',   budget: p.needsBudget),
                  right: _CategorySection(type: CategoryType.wants,  label: 'Wants',   budget: p.wantsBudget),
                ),
                const SizedBox(height: 16),
                _CategorySection(type: CategoryType.savings, label: 'Savings', budget: p.savingsBudget),
              ] else ...[
                _CategorySection(type: CategoryType.needs,   label: 'Needs',   budget: p.needsBudget),
                const SizedBox(height: 16),
                _CategorySection(type: CategoryType.wants,   label: 'Wants',   budget: p.wantsBudget),
                const SizedBox(height: 16),
                _CategorySection(type: CategoryType.savings, label: 'Savings', budget: p.savingsBudget),
              ],
            ],
          ),
        );
      }),
    );
  }

  void _showAddSub(BuildContext ctx) {
    final p = ctx.read<AppProvider>();
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    CategoryType selectedType = CategoryType.needs;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        final totalSub = p.totalSubBudgetByType(selectedType);
        final budget = selectedType == CategoryType.needs ? p.needsBudget : selectedType == CategoryType.wants ? p.wantsBudget : p.savingsBudget;
        final avail = budget - totalSub;
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            Text('Add Sub-category', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 20),
            TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. Electricity, Rent)', prefixIcon: Icon(Icons.category_outlined, size: 18)), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            buildAmountField(controller: amountCtrl, label: 'Budget Amount'),
            const SizedBox(height: 20),
            const SectionLabel('Category'),
            CategorySelector(value: selectedType, onChanged: (v) => ss(() => selectedType = v)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: avail > 0 ? kSuccessColor.withOpacity(0.08) : kDangerColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: avail > 0 ? kSuccessColor.withOpacity(0.3) : kDangerColor.withOpacity(0.3))),
              child: Row(children: [
                Icon(avail > 0 ? Icons.check_circle_outline : Icons.warning_amber_rounded, size: 15, color: avail > 0 ? kSuccessColor : kDangerColor),
                const SizedBox(width: 8),
                Text('${pesoFmt.format(avail)} available in ${selectedType.name}', style: GoogleFonts.inter(fontSize: 12, color: avail > 0 ? kSuccessColor : kDangerColor, fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final amount = double.parse(amountCtrl.text.trim());
                if (totalSub + amount > budget) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Exceeds ${selectedType.name} budget'), backgroundColor: kDangerColor));
                  return;
                }
                p.addSubCategory(BudgetSubCategory(id: p.newId(), name: nameCtrl.text.trim(), budgetAmount: amount, category: selectedType));
                Navigator.pop(ctx);
              },
              child: const Text('Add Sub-category'),
            )),
          ])),
        );
      }),
    );
  }
}

class _BudgetSummaryRow extends StatelessWidget {
  final AppProvider p;
  const _BudgetSummaryRow({required this.p});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _MiniStat('Total Budget', p.totalIncome, Theme.of(context).extension<AppColors>()!.textPrimary)),
    const SizedBox(width: 10),
    Expanded(child: _MiniStat('Allocated', p.subCategories.fold(0.0, (s, c) => s + c.budgetAmount), kWantsColor)),
    const SizedBox(width: 10),
    Expanded(child: _MiniStat('Spent', p.totalSpent, kDangerColor)),
  ]);
}

class _MiniStat extends StatelessWidget {
  final String label; final double value; final Color color;
  const _MiniStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        Text(pesoFmt.format(value), style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.3)),
      ]),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final CategoryType type; final String label; final double budget;
  const _CategorySection({required this.type, required this.label, required this.budget});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final subs = p.subCategoriesByType(type);
    final c = colors.forCategory(type);
    final totalAllocated = p.totalSubBudgetByType(type);
    final totalSpent = type == CategoryType.needs ? p.totalNeedsSpent : type == CategoryType.wants ? p.totalWantsSpent : p.totalSavingsSpent;
    final icons = {CategoryType.needs: Icons.home_rounded, CategoryType.wants: Icons.shopping_bag_rounded, CategoryType.savings: Icons.savings_rounded};

    return AppCard(padding: const EdgeInsets.all(0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(color: c.withOpacity(colors.isDark ? 0.08 : 0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: c.withOpacity(colors.isDark ? 0.2 : 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icons[type], size: 16, color: c)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              Text('${pesoFmt.format(totalSpent)} spent of ${pesoFmt.format(budget)}', style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary)),
            ])),
            Text(pesoFmt.format(budget - totalSpent), style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: budget - totalSpent < 0 ? kDangerColor : c)),
          ]),
          const SizedBox(height: 10),
          BudgetProgressBar(label: '', spent: totalSpent, budget: budget, color: c, compact: true),
        ]),
      ),
      Padding(padding: const EdgeInsets.all(14), child: Column(children: [
        if (subs.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('No sub-categories. Tap "Add Sub-category" to create one.', style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted)))
        else
          ...subs.asMap().entries.map((entry) {
            final sub = entry.value;
            final subSpent = p.subCategorySpent(sub.id);
            return Column(children: [
              if (entry.key > 0) Divider(color: colors.divider, height: 16),
              Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(sub.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary))),
                  IconButton(onPressed: () => _editSub(context, p, sub), icon: const Icon(Icons.edit_outlined, size: 14), constraints: const BoxConstraints(), padding: const EdgeInsets.only(left: 8)),
                  IconButton(onPressed: () => _deleteSub(context, p, sub.id), icon: Icon(Icons.delete_outline, size: 14, color: kDangerColor), constraints: const BoxConstraints(), padding: const EdgeInsets.only(left: 4)),
                ]),
                const SizedBox(height: 6),
                BudgetProgressBar(label: '', spent: subSpent, budget: sub.budgetAmount, color: c, compact: true),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${pesoFmt.format(subSpent)} used', style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted)),
                  Text('${pesoFmt.format(sub.budgetAmount - subSpent)} left', style: GoogleFonts.inter(fontSize: 10, color: sub.budgetAmount - subSpent < 0 ? kDangerColor : colors.textMuted)),
                ]),
              ]))]),
            ]);
          }),
        if (totalAllocated < budget) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.info_outline, size: 12, color: colors.textMuted), const SizedBox(width: 6), Text('${pesoFmt.format(budget - totalAllocated)} unallocated', style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted))])),
        ],
      ])),
    ]));
  }

  void _editSub(BuildContext ctx, AppProvider p, BudgetSubCategory sub) {
    final nameCtrl = TextEditingController(text: sub.name);
    final amountCtrl = TextEditingController(text: sub.budgetAmount.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SheetHandle(),
        Text('Edit ${sub.name}', style: Theme.of(ctx).textTheme.headlineSmall),
        const SizedBox(height: 20),
        TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        buildAmountField(controller: amountCtrl, label: 'Budget Amount'),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            p.updateSubCategory(BudgetSubCategory(id: sub.id, name: nameCtrl.text.trim(), budgetAmount: double.parse(amountCtrl.text.trim()), category: sub.category));
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        )),
      ])),
    ));
  }

  void _deleteSub(BuildContext ctx, AppProvider p, String id) {
    showDialog(context: ctx, builder: (ctx) => AlertDialog(
      title: const Text('Delete Sub-category'),
      content: const Text('Are you sure?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), TextButton(onPressed: () { p.deleteSubCategory(id); Navigator.pop(ctx); }, child: Text('Delete', style: TextStyle(color: kDangerColor)))],
    ));
  }
}