// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/shared_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BudgetWise', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textMuted, letterSpacing: 1)),
          Text('Settings', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary, letterSpacing: -0.3)),
        ]),
        toolbarHeight: 60,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SectionLabel('Appearance'),
        AppCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(10)), child: Icon(p.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, size: 18, color: colors.textSecondary)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.isDarkMode ? 'Dark Mode' : 'Light Mode', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary)),
              Text('Tap to switch theme', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
            ]),
          ]),
          Switch.adaptive(value: p.isDarkMode, onChanged: (_) => p.toggleTheme(), activeColor: colors.textPrimary),
        ])),
        const SizedBox(height: 20),
        const SectionLabel('Budget Allocation'),
        AppCard(child: Column(children: [
          _SettingRow(icon: Icons.home_rounded, label: 'Needs', value: '${p.settings.needsPercent.toStringAsFixed(0)}%  ·  ${pesoFmt.format(p.needsBudget)}', color: kNeedsColor),
          Divider(color: colors.divider, height: 20),
          _SettingRow(icon: Icons.shopping_bag_rounded, label: 'Wants', value: '${p.settings.wantsPercent.toStringAsFixed(0)}%  ·  ${pesoFmt.format(p.wantsBudget)}', color: kWantsColor),
          Divider(color: colors.divider, height: 20),
          _SettingRow(icon: Icons.savings_rounded, label: 'Savings', value: '${p.settings.savingsPercent.toStringAsFixed(0)}%  ·  ${pesoFmt.format(p.savingsBudget)}', color: kSavingsColor),
        ])),
        const SizedBox(height: 20),
        const SectionLabel('App Info'),
        AppCard(child: Column(children: [
          _InfoRow(icon: Icons.info_outline_rounded, label: 'App Name', value: 'BudgetWise', colors: colors),
          Divider(color: colors.divider, height: 16),
          _InfoRow(icon: Icons.storage_rounded, label: 'Storage', value: 'Offline · Local only', colors: colors),
          Divider(color: colors.divider, height: 16),
          _InfoRow(icon: Icons.currency_exchange_rounded, label: 'Currency', value: 'Philippine Peso (₱)', colors: colors),
          Divider(color: colors.divider, height: 16),
          _InfoRow(icon: Icons.phone_android_rounded, label: 'Version', value: '1.0.0', colors: colors),
        ])),
        const SizedBox(height: 20),
        const SectionLabel('Financial Tips'),
        AppCard(child: Column(children: [
          _TipRow('💡', 'The 50/30/20 rule is a proven starting point. Adjust to fit your lifestyle.'),
          const SizedBox(height: 12),
          _TipRow('💳', 'Always pay credit card bills in full before the due date to avoid interest charges.'),
          const SizedBox(height: 12),
          _TipRow('📊', 'Track every expense — small daily purchases add up over the month.'),
          const SizedBox(height: 12),
          _TipRow('🏦', 'Keep an emergency fund of 3–6 months of living expenses in a separate account.'),
          const SizedBox(height: 12),
          _TipRow('📈', 'Review your budget monthly and adjust allocations as your needs change.'),
        ])),
        const SizedBox(height: 32),
      ]),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _SettingRow({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(colors.isDark ? 0.15 : 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary))),
      Text(value, style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value; final AppColors colors;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.colors});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: colors.textMuted),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary))),
    Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
  ]);
}

class _TipRow extends StatelessWidget {
  final String emoji, text;
  const _TipRow(this.emoji, this.text);
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary, height: 1.5))),
    ]);
  }
}
