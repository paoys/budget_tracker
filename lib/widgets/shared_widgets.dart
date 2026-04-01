// lib/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../utils/theme.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: colors.textMuted)),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  const AppCard({super.key, required this.child, this.padding, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Material(
      color: color ?? colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.divider)),
          padding: padding ?? const EdgeInsets.all(18),
          child: child,
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final double value;
  final Color? accentColor;
  final String? sub;
  final IconData? icon;
  final bool isCurrency;
  const StatTile({super.key, required this.label, required this.value, this.accentColor, this.sub, this.icon, this.isCurrency = true});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final accent = accentColor ?? colors.textMuted;
    final valueText = isCurrency
      ? pesoFmt.format(value)
      : (value == value.truncateToDouble() ? value.toInt().toString() : value.toStringAsFixed(2));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: colors.textMuted)),
          if (icon != null) Icon(icon, size: 14, color: colors.textMuted),
        ]),
        const SizedBox(height: 10),
        Text(valueText, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: accent == colors.textMuted ? colors.textPrimary : accent)),
        if (sub != null) ...[const SizedBox(height: 4), Text(sub!, style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary))],
      ]),
    );
  }
}

class BudgetProgressBar extends StatelessWidget {
  final String label;
  final double spent;
  final double budget;
  final Color color;
  final bool compact;
  const BudgetProgressBar({super.key, required this.label, required this.spent, required this.budget, required this.color, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final pct  = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final over = budget > 0 && spent > budget;
    final barColor = over ? kDangerColor : color;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label.isNotEmpty) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary)),
        Row(children: [
          Text(pesoFmt.format(spent), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: over ? kDangerColor : colors.textPrimary)),
          Text(' / ${pesoFmt.format(budget)}', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
        ]),
      ]),
      SizedBox(height: label.isEmpty ? 0 : 8),
      Stack(children: [
        Container(height: compact ? 5 : 7, decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(10))),
        FractionallySizedBox(
          widthFactor: pct,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            height: compact ? 5 : 7,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: barColor.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
            ),
          ),
        ),
      ]),
      if (!compact) ...[
        const SizedBox(height: 5),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${(pct * 100).toStringAsFixed(0)}% used', style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w500)),
          Text(over ? 'Over by ${pesoFmt.format(spent - budget)}' : '${pesoFmt.format(budget - spent)} left',
            style: GoogleFonts.inter(fontSize: 10, color: over ? kDangerColor : colors.textMuted, fontWeight: FontWeight.w500)),
        ]),
      ],
    ]);
  }
}

class CategoryChip extends StatelessWidget {
  final CategoryType category;
  const CategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final c = colors.forCategory(category);
    final name = category.name[0].toUpperCase() + category.name.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(colors.isDark ? 0.18 : 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(name, style: GoogleFonts.inter(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }
}

class PaymentModeChip extends StatelessWidget {
  final PaymentMode mode;
  const PaymentModeChip({super.key, required this.mode});

  String get label => const ['Cash','Credit Card','Debit Card','GCash','Maya','Bank Transfer','Other'][PaymentMode.values.indexOf(mode)];
  IconData get icon => const [Icons.payments_outlined, Icons.credit_card, Icons.credit_card_outlined, Icons.phone_android, Icons.phone_android_outlined, Icons.account_balance_outlined, Icons.more_horiz][PaymentMode.values.indexOf(mode)];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: colors.textSecondary),
      const SizedBox(width: 3),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary)),
    ]);
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: colors.surface2, shape: BoxShape.circle), child: Icon(icon, size: 32, color: colors.textMuted)),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ]),
      ),
    );
  }
}

Widget buildAmountField({required TextEditingController controller, String label = 'Amount', String? hint}) {
  return TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16),
    decoration: InputDecoration(
      labelText: label, hintText: hint ?? '0.00',
      prefixText: '₱  ',
      prefixStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
    ),
    validator: (v) {
      if (v == null || v.trim().isEmpty) return 'Required';
      final parsed = double.tryParse(v.trim());
      if (parsed == null) return 'Enter a valid number';
      // Check for maximum 2 decimal places
      final parts = v.trim().split('.');
      if (parts.length > 2) return 'Invalid number format';
      if (parts.length == 2 && parts[1].length > 2) return 'Maximum 2 decimal places';
      return null;
    },
  );
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: colors.surface3, borderRadius: BorderRadius.circular(2))));
  }
}

class ActionPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;
  const ActionPill({super.key, required this.label, required this.color, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.35))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 5)],
        Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    ),
  );
}

class AppSegmented<T> extends StatelessWidget {
  final T value;
  final List<T> values;
  final List<String> labels;
  final ValueChanged<T> onChanged;
  const AppSegmented({super.key, required this.value, required this.values, required this.labels, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(12)),
      child: Row(children: List.generate(values.length, (i) {
        final selected = values[i] == value;
        return Expanded(child: GestureDetector(
          onTap: () => onChanged(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? colors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))] : [],
            ),
            alignment: Alignment.center,
            child: Text(labels[i], style: GoogleFonts.inter(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? colors.textPrimary : colors.textSecondary)),
          ),
        ));
      })),
    );
  }
}

class CategorySelector extends StatelessWidget {
  final CategoryType value;
  final ValueChanged<CategoryType> onChanged;
  const CategorySelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(children: CategoryType.values.asMap().entries.map((e) {
      final t = e.value;
      final sel = t == value;
      final c = colors.forCategory(t);
      final name = t.name[0].toUpperCase() + t.name.substring(1);
      return Expanded(child: Padding(
        padding: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
        child: GestureDetector(
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: sel ? c.withOpacity(colors.isDark ? 0.2 : 0.12) : colors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? c.withOpacity(0.6) : colors.divider, width: sel ? 1.5 : 1),
            ),
            alignment: Alignment.center,
            child: Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? c : colors.textSecondary)),
          ),
        ),
      ));
    }).toList());
  }
}
