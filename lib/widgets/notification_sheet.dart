// lib/widgets/notification_sheet.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';

// ── Public entry-point ────────────────────────────────────────────────────────
void showNotificationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppProvider>(),
      child: const _NotificationSheet(),
    ),
  );
}

// ── Sheet ─────────────────────────────────────────────────────────────────────
class _NotificationSheet extends StatelessWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final notifs = NotificationService.buildNotifications(p);

    final recurringNotifs = notifs.where((n) => n.type == NotifType.recurringOverdue).toList();
    final ccNotifs        = notifs.where((n) => n.type == NotifType.creditCardDue).toList();
    final budgetNotifs    = notifs.where((n) => n.type == NotifType.overBudget).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // ── Handle ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: colors.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(children: [
              Text('Notifications',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              const SizedBox(width: 8),
              if (notifs.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kWarningColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${notifs.length}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: kWarningColor)),
                ),
            ]),
          ),
          const Divider(height: 1),
          // ── Content ────────────────────────────────────────────────────
          Expanded(
            child: notifs.isEmpty
              ? _EmptyState(colors: colors)
              : ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    if (recurringNotifs.isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.repeat_rounded,
                        label: 'Recurring Due',
                        count: recurringNotifs.length,
                        color: kNeedsColor,
                      ),
                      const SizedBox(height: 8),
                      ...recurringNotifs.map((n) => _RecurringTile(notif: n, p: p, colors: colors)),
                      const SizedBox(height: 16),
                    ],
                    if (ccNotifs.isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.credit_card_rounded,
                        label: 'Payment Due Soon',
                        count: ccNotifs.length,
                        color: kWarningColor,
                      ),
                      const SizedBox(height: 8),
                      ...ccNotifs.map((n) => _CcTile(notif: n, colors: colors)),
                      const SizedBox(height: 16),
                    ],
                    if (budgetNotifs.isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.pie_chart_rounded,
                        label: 'Over Budget',
                        count: budgetNotifs.length,
                        color: kDangerColor,
                      ),
                      const SizedBox(height: 8),
                      ...budgetNotifs.map((n) => _BudgetTile(notif: n, colors: colors)),
                    ],
                  ],
                ),
          ),
        ]),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _SectionHeader({required this.icon, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 13, color: color),
    const SizedBox(width: 6),
    Text(label.toUpperCase(),
      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.8)),
    const Spacer(),
    Text('$count', style: GoogleFonts.inter(fontSize: 10, color: color)),
  ]);
}

// ── Recurring Tile (with Log / Skip actions) ──────────────────────────────────
class _RecurringTile extends StatelessWidget {
  final AppNotification notif;
  final AppProvider p;
  final AppColors colors;
  const _RecurringTile({required this.notif, required this.p, required this.colors});

  @override
  Widget build(BuildContext context) => _NotifCard(
    color: kNeedsColor,
    child: Row(children: [
      _IconBadge(icon: Icons.repeat_rounded, color: kNeedsColor),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(notif.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
        const SizedBox(height: 2),
        Text(notif.subtitle, style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary)),
      ])),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(pesoFmt.format(notif.amount ?? 0),
          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        const SizedBox(height: 6),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _ActionButton(
            label: 'Skip',
            color: kNeedsColor,
            filled: false,
            onTap: () {
              p.skipRecurringTemplate(notif.actionId!);
            },
          ),
          const SizedBox(width: 6),
          _ActionButton(
            label: 'Log',
            color: kNeedsColor,
            filled: true,
            onTap: () {
              p.processRecurringTemplate(notif.actionId!);
            },
          ),
        ]),
      ]),
    ]),
  );
}

// ── CC Tile ───────────────────────────────────────────────────────────────────
class _CcTile extends StatelessWidget {
  final AppNotification notif;
  final AppColors colors;
  const _CcTile({required this.notif, required this.colors});

  @override
  Widget build(BuildContext context) => _NotifCard(
    color: kWarningColor,
    child: Row(children: [
      _IconBadge(icon: Icons.credit_card_rounded, color: kWarningColor),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(notif.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
        const SizedBox(height: 2),
        Text(notif.subtitle, style: GoogleFonts.inter(fontSize: 11, color: kWarningColor)),
      ])),
      const SizedBox(width: 8),
      Text(pesoFmt.format(notif.amount ?? 0),
        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: kDangerColor)),
    ]),
  );
}

// ── Budget Tile ───────────────────────────────────────────────────────────────
class _BudgetTile extends StatelessWidget {
  final AppNotification notif;
  final AppColors colors;
  const _BudgetTile({required this.notif, required this.colors});

  @override
  Widget build(BuildContext context) => _NotifCard(
    color: kDangerColor,
    child: Row(children: [
      _IconBadge(icon: Icons.pie_chart_rounded, color: kDangerColor),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(notif.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
        const SizedBox(height: 2),
        Text(notif.subtitle, style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary)),
      ])),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('over by', style: GoogleFonts.inter(fontSize: 10, color: colors.textMuted)),
        Text(pesoFmt.format(notif.amount ?? 0),
          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: kDangerColor)),
      ]),
    ]),
  );
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final Widget child;
  final Color color;
  const _NotifCard({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 18, color: color),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(filled ? 0 : 0.4)),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final AppColors colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.check_circle_outline_rounded, size: 48, color: kSuccessColor.withOpacity(0.6)),
      const SizedBox(height: 12),
      Text("You're all caught up!",
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
      const SizedBox(height: 4),
      Text('No overdue items or alerts right now.',
        style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary)),
    ]),
  );
}
