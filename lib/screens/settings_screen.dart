// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart' as ap;
import '../utils/theme.dart';
import '../widgets/shared_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p      = context.watch<AppProvider>();
    final auth   = context.watch<ap.AuthProvider>();
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

        // ── Account Card ─────────────────────────────────────────────────────
        const SectionLabel('Account'),
        AppCard(child: Column(children: [
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colors.surface2,
              backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
              child: auth.photoUrl == null
                  ? Text((auth.displayName ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.displayName ?? 'User', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              Text(auth.email ?? '', style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: kSuccessColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_done_rounded, size: 12, color: kSuccessColor),
                const SizedBox(width: 4),
                Text('Cloud Sync', style: GoogleFonts.inter(fontSize: 11, color: kSuccessColor, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Divider(color: colors.divider),
          const SizedBox(height: 10),
          Row(children: [
            Icon(_syncIcon(p.syncStatus), size: 16, color: _syncColor(p.syncStatus)),
            const SizedBox(width: 8),
            Expanded(child: Text(_syncLabel(p.syncStatus),
                style: GoogleFonts.inter(fontSize: 13, color: _syncColor(p.syncStatus), fontWeight: FontWeight.w500))),
            if (p.syncStatus == SyncStatus.error)
              GestureDetector(
                onTap: () => p.syncNow(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: kDangerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Retry', style: GoogleFonts.inter(fontSize: 12, color: kDangerColor, fontWeight: FontWeight.w600)),
                ),
              )
            else
              Row(children: [
                GestureDetector(
                  onTap: () => _confirmPush(context, p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.divider)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.upload_rounded, size: 12, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Text('Push', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _confirmPull(context, p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.divider)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.download_rounded, size: 12, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Text('Pull', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ]),
          ]),
        ])),
        const SizedBox(height: 20),

        // ── Appearance ───────────────────────────────────────────────────────
        const SectionLabel('Appearance'),
        AppCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(10)),
                child: Icon(p.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, size: 18, color: colors.textSecondary)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.isDarkMode ? 'Dark Mode' : 'Light Mode',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary)),
              Text('Tap to switch theme', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
            ]),
          ]),
          Switch.adaptive(value: p.isDarkMode, onChanged: (_) => p.toggleTheme(), activeColor: colors.textPrimary),
        ])),
        const SizedBox(height: 20),

        // ── Budget allocation ─────────────────────────────────────────────────
        const SectionLabel('Budget Allocation'),
        AppCard(child: Column(children: [
          _SettingRow(icon: Icons.home_rounded,         label: 'Needs',   value: '${p.settings.needsPercent.toStringAsFixed(0)}%  ·  ${pesoFmt.format(p.needsBudget)}',   color: kNeedsColor),
          Divider(color: colors.divider, height: 20),
          _SettingRow(icon: Icons.shopping_bag_rounded,  label: 'Wants',   value: '${p.settings.wantsPercent.toStringAsFixed(0)}%  ·  ${pesoFmt.format(p.wantsBudget)}',   color: kWantsColor),
          Divider(color: colors.divider, height: 20),
          _SettingRow(icon: Icons.savings_rounded,       label: 'Savings', value: '${p.settings.savingsPercent.toStringAsFixed(0)}%  ·  ${pesoFmt.format(p.savingsBudget)}', color: kSavingsColor),
        ])),
        const SizedBox(height: 20),

        // ── App info ──────────────────────────────────────────────────────────
        const SectionLabel('App Info'),
        AppCard(child: Column(children: [
          _InfoRow(icon: Icons.info_outline_rounded,      label: 'App Name', value: 'BudgetWise',        colors: colors),
          Divider(color: colors.divider, height: 16),
          _InfoRow(icon: Icons.storage_rounded,             label: 'Storage',  value: 'Offline · Local only', colors: colors),
          Divider(color: colors.divider, height: 16),
          _InfoRow(icon: Icons.cloud_rounded,             label: 'Cloud Storage',  value: 'Firebase Firestore', colors: colors),
          Divider(color: colors.divider, height: 16),
          _InfoRow(icon: Icons.currency_exchange_rounded, label: 'Currency', value: 'Philippine Peso (₱)', colors: colors),
          Divider(color: colors.divider, height: 16),
          _InfoRow(icon: Icons.phone_android_rounded,     label: 'Version',  value: '1.0.0',              colors: colors),
        ])),
        const SizedBox(height: 20),

        // ── Tips ──────────────────────────────────────────────────────────────
        const SectionLabel('Financial Tips'),
        AppCard(child: Column(children: [
          _TipRow('💡', 'The 50/30/20 rule is a proven starting point. Adjust to fit your lifestyle.'),
          const SizedBox(height: 12),
          _TipRow('💳', 'Always pay credit card bills in full before the due date to avoid interest charges.'),
          const SizedBox(height: 12),
          _TipRow('📊', 'Track every expense — small daily purchases add up over the month.'),
          const SizedBox(height: 12),
          _TipRow('🏦', 'Keep an emergency fund of 3–6 months of living expenses in a separate account.'),
        ])),
        const SizedBox(height: 20),

        // ── Sign Out ──────────────────────────────────────────────────────────
        // FIX 1: Use Material InkWell directly so the entire card area is tappable,
        //        not just the Row contents inside GestureDetector.
        // FIX 2: Pass the root Navigator context so sign-out pops all routes back
        //        to the auth gate (LoginScreen), not just closes Settings.
        Material(
          color: kDangerColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _confirmSignOut(context, auth),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kDangerColor.withOpacity(0.2)),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: kDangerColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.logout_rounded, size: 18, color: kDangerColor),
                ),
                const SizedBox(width: 14),
                Text('Sign Out', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: kDangerColor)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: kDangerColor, size: 18),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  void _confirmSignOut(BuildContext ctx, ap.AuthProvider auth) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Your data is safely backed up to the cloud. Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx); // close dialog
              await auth.signOut();
              // FIX 2: Pop all routes so the auth gate (which is the root) is revealed.
              // This works whether Settings was pushed or is part of the nav stack.
              if (ctx.mounted) {
                Navigator.of(ctx, rootNavigator: true).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: kDangerColor)),
          ),
        ],
      ),
    );
  }

  void _confirmPush(BuildContext ctx, AppProvider p) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Push to Cloud'),
        content: const Text(
          "This will OVERWRITE the cloud with this device's data.\n\n"
          "Any data on other devices that have not been pushed here will be lost.\n\n"
          "Are you sure?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              await p.syncNow();
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(p.syncStatus == SyncStatus.synced
                      ? "Cloud updated with this device's data"
                      : 'Push failed — check your connection'),
                  backgroundColor: p.syncStatus == SyncStatus.synced ? kSuccessColor : kDangerColor,
                ));
              }
            },
            child: const Text('Push', style: TextStyle(color: kDangerColor)),
          ),
        ],
      ),
    );
  }

  void _confirmPull(BuildContext ctx, AppProvider p) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Pull from Cloud'),
        content: const Text(
          "This will REPLACE this device's data with the cloud version.\n\n"
          "Any local changes not yet pushed will be lost.\n\n"
          "Are you sure?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              await p.pullFromCloud();
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(p.syncStatus == SyncStatus.synced
                      ? 'Data updated from cloud'
                      : 'Pull failed — check your connection'),
                  backgroundColor: p.syncStatus == SyncStatus.synced ? kSuccessColor : kDangerColor,
                ));
              }
            },
            child: const Text('Pull', style: TextStyle(color: kDangerColor)),
          ),
        ],
      ),
    );
  }
  Color    _syncColor(SyncStatus s) => s == SyncStatus.synced ? kSuccessColor : s == SyncStatus.error ? kDangerColor : kWarningColor;
  IconData _syncIcon(SyncStatus s)  => s == SyncStatus.synced ? Icons.cloud_done_rounded : s == SyncStatus.error ? Icons.cloud_off_rounded : Icons.cloud_sync_rounded;
  String   _syncLabel(SyncStatus s) => s == SyncStatus.synced ? 'Data synced with cloud' : s == SyncStatus.error ? 'Sync failed' : s == SyncStatus.syncing ? 'Syncing...' : 'Not synced';
}

class _SettingRow extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _SettingRow({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(colors.isDark ? 0.15 : 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color)),
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