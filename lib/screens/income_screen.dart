// lib/screens/income_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/shared_widgets.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIncome(context),
        backgroundColor: colors.textPrimary,
        foregroundColor: colors.bg,
        icon: const Icon(Icons.add, size: 18),
        label: Text('Add Income', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors.isDark ? [const Color(0xFF1C1C22), const Color(0xFF141418)] : [const Color(0xFF1A1A2E), const Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Monthly Income', style: GoogleFonts.inter(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(pesoFmt.format(p.totalIncome), style: GoogleFonts.plusJakartaSans(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
              const SizedBox(height: 16),
              Row(children: [
                _IncomePill('Needs', p.needsBudget, kNeedsColor),
                const SizedBox(width: 8),
                _IncomePill('Wants', p.wantsBudget, kWantsColor),
                const SizedBox(width: 8),
                _IncomePill('Savings', p.savingsBudget, kSavingsColor),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          if (p.incomes.isNotEmpty) ...[
            const SectionLabel('Income Sources'),
            ...p.incomes.map((income) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(child: Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(12)), child: Icon(income.mode == IncomeMode.monthly ? Icons.calendar_month_outlined : Icons.date_range_outlined, size: 20, color: colors.textSecondary)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(income.label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(income.mode == IncomeMode.monthly ? 'Monthly · ${dateFmt.format(income.date)}' : 'Cut-off ${income.cutoffPeriod == 1 ? "1–15" : "16–End"} · ${dateFmt.format(income.date)}', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
                ])),
                Text(pesoFmt.format(income.amount), style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => p.deleteIncome(income.id),
                  child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: kDangerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.close, size: 14, color: kDangerColor)),
                ),
              ])),
            )),
            const SizedBox(height: 20),
          ] else ...[
            const EmptyState(icon: Icons.wallet_outlined, title: 'No income added', message: 'Add your monthly salary or cut-off income to start budgeting.'),
            const SizedBox(height: 20),
          ],
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const SectionLabel('Budget Split'),
            GestureDetector(
              onTap: () => _showSplitSettings(context, p),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.divider)), child: Row(children: [Icon(Icons.tune_rounded, size: 14, color: colors.textSecondary), const SizedBox(width: 5), Text('Adjust', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary))])),
            ),
          ]),
          const SizedBox(height: 12),
          AppCard(child: Column(children: [
            _SplitRow('Needs', p.settings.needsPercent, p.needsBudget, colors.needs),
            Divider(color: colors.divider, height: 20),
            _SplitRow('Wants', p.settings.wantsPercent, p.wantsBudget, colors.wants),
            Divider(color: colors.divider, height: 20),
            _SplitRow('Savings', p.settings.savingsPercent, p.savingsBudget, colors.savings),
            const SizedBox(height: 14),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Row(children: [
              _ColorBar(flex: p.settings.needsPercent.round(),   color: colors.needs,   label: '${p.settings.needsPercent.toStringAsFixed(0)}%'),
              _ColorBar(flex: p.settings.wantsPercent.round(),   color: colors.wants,   label: '${p.settings.wantsPercent.toStringAsFixed(0)}%'),
              _ColorBar(flex: p.settings.savingsPercent.round(), color: colors.savings, label: '${p.settings.savingsPercent.toStringAsFixed(0)}%'),
            ])),
          ])),
        ],
      ),
    );
  }

  void _showAddIncome(BuildContext ctx) {
    final p = ctx.read<AppProvider>();
    final labelCtrl = TextEditingController(text: 'Salary');
    final amountCtrl = TextEditingController();
    IncomeMode mode = IncomeMode.monthly;
    int cutoffPeriod = 1;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Text('Add Income', style: Theme.of(ctx).textTheme.headlineSmall),
          const SizedBox(height: 20),
          TextFormField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label', prefixIcon: Icon(Icons.label_outline, size: 18)), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          buildAmountField(controller: amountCtrl),
          const SizedBox(height: 20),
          const SectionLabel('Income Type'),
          AppSegmented<IncomeMode>(value: mode, values: const [IncomeMode.monthly, IncomeMode.cutoff], labels: const ['Monthly', 'Cut-off'], onChanged: (v) => ss(() => mode = v)),
          if (mode == IncomeMode.cutoff) ...[
            const SizedBox(height: 16),
            const SectionLabel('Cut-off Period'),
            AppSegmented<int>(value: cutoffPeriod, values: const [1, 2], labels: const ['1st Half (1–15)', '2nd Half (16–End)'], onChanged: (v) => ss(() => cutoffPeriod = v)),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              p.addIncome(Income(id: p.newId(), amount: double.parse(amountCtrl.text.trim()), label: labelCtrl.text.trim(), mode: mode, cutoffPeriod: mode == IncomeMode.cutoff ? cutoffPeriod : null, date: DateTime.now()));
              Navigator.pop(ctx);
            },
            child: const Text('Add Income'),
          )),
        ])),
      )),
    );
  }

  void _showSplitSettings(BuildContext ctx, AppProvider p) {
    double needs = p.settings.needsPercent;
    double wants = p.settings.wantsPercent;
    double savings = p.settings.savingsPercent;

    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        final total = needs + wants + savings;
        final valid = (total - 100).abs() < 0.5;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            Text('Budget Split', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Total must equal 100%', style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 24),
            _SliderRow('Needs', needs, kNeedsColor, (v) => ss(() => needs = v)),
            const SizedBox(height: 20),
            _SliderRow('Wants', wants, kWantsColor, (v) => ss(() => wants = v)),
            const SizedBox(height: 20),
            _SliderRow('Savings', savings, kSavingsColor, (v) => ss(() => savings = v)),
            const SizedBox(height: 20),
            Center(child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: valid ? kSuccessColor.withOpacity(0.1) : kDangerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('Total: ${total.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: valid ? kSuccessColor : kDangerColor)),
            )),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: valid ? () {
                p.updateSettings(AppSettings(needsPercent: needs, wantsPercent: wants, savingsPercent: savings, incomeMode: p.settings.incomeMode, isDarkMode: p.settings.isDarkMode));
                Navigator.pop(ctx);
              } : null,
              child: const Text('Save'),
            )),
          ]),
        );
      }),
    );
  }
}

class _IncomePill extends StatelessWidget {
  final String label; final double amount; final Color color;
  const _IncomePill(this.label, this.amount, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white54))]),
      const SizedBox(height: 4),
      Text(pesoFmt.format(amount), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
    ]),
  ));
}

class _SplitRow extends StatelessWidget {
  final String label; final double percent; final double amount; final Color color;
  const _SplitRow(this.label, this.percent, this.amount, this.color);
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary))),
      Text(pesoFmt.format(amount), style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary)),
      const SizedBox(width: 10),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)), child: Text('${percent.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color))),
    ]);
  }
}

class _ColorBar extends StatelessWidget {
  final int flex; final Color color; final String label;
  const _ColorBar({required this.flex, required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Flexible(flex: flex, child: Container(height: 26, color: color, alignment: Alignment.center, child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.9)))));
}

class _SliderRow extends StatelessWidget {
  final String label; final double value; final Color color; final ValueChanged<double> onChanged;
  const _SliderRow(this.label, this.value, this.color, this.onChanged);
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)), child: Text('${value.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color))),
      ]),
      const SizedBox(height: 6),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(activeTrackColor: color, thumbColor: color, inactiveTrackColor: color.withOpacity(0.15), overlayColor: color.withOpacity(0.12), trackHeight: 5, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10)),
        child: Slider(value: value, min: 0, max: 100, divisions: 100, onChanged: onChanged),
      ),
    ]);
  }
}
