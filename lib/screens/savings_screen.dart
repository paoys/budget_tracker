// lib/screens/savings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import '../widgets/shared_widgets.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final total = p.bankAccounts.fold(0.0, (s, a) => s + a.balance);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccount(context),
        backgroundColor: colors.textPrimary,
        foregroundColor: colors.bg,
        icon: const Icon(Icons.add, size: 18),
        label: Text('Add Bank', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors.isDark ? [const Color(0xFF0D2818), const Color(0xFF0A1F12)] : [const Color(0xFF064E3B), const Color(0xFF065F46)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total Savings', style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.savings_rounded, size: 18, color: Colors.white70)),
              ]),
              const SizedBox(height: 8),
              Text(pesoFmt.format(total), style: GoogleFonts.plusJakartaSans(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
              const SizedBox(height: 4),
              Text('across ${p.bankAccounts.length} account${p.bankAccounts.length == 1 ? "" : "s"}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
            ]),
          ),
          const SizedBox(height: 20),
          if (p.bankAccounts.isEmpty)
            const EmptyState(icon: Icons.account_balance_outlined, title: 'No bank accounts', message: 'Add your savings accounts to track your money.')
          else ...[
            const SectionLabel('Accounts'),
            ...p.bankAccounts.map((acc) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _BankCard(account: acc))),
          ],
        ],
      ),
    );
  }

  void _showAddAccount(BuildContext ctx) {
    final p = ctx.read<AppProvider>();
    final nameCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final balCtrl  = TextEditingController();
    final formKey  = GlobalKey<FormState>();

    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Text('Add Bank Account', style: Theme.of(ctx).textTheme.headlineSmall),
          const SizedBox(height: 20),
          TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Account Name', hintText: 'e.g. Main Savings, Emergency Fund', prefixIcon: Icon(Icons.account_circle_outlined, size: 18)), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'Bank / Wallet', hintText: 'e.g. BDO, BPI, GCash, Maya', prefixIcon: Icon(Icons.account_balance_outlined, size: 18)), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          buildAmountField(controller: balCtrl, label: 'Current Balance'),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              p.addBankAccount(BankAccount(id: p.newId(), name: nameCtrl.text.trim(), bankName: bankCtrl.text.trim(), balance: double.parse(balCtrl.text.trim())));
              Navigator.pop(ctx);
            },
            child: const Text('Add Account'),
          )),
        ])),
      ),
    );
  }
}

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
        GestureDetector(onTap: () => _confirmDelete(context, p), child: Icon(Icons.delete_outline_rounded, size: 18, color: colors.textMuted)),
      ]),
      const SizedBox(height: 14),
      Text(pesoFmt.format(account.balance), style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: account.balance < 0 ? kDangerColor : colors.textPrimary)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: ActionPill(label: 'Deposit', color: kSuccessColor, icon: Icons.arrow_downward_rounded, onTap: () => _showTx(context, p, true))),
        const SizedBox(width: 8),
        Expanded(child: ActionPill(label: 'Withdraw', color: kDangerColor, icon: Icons.arrow_upward_rounded, onTap: () => _showTx(context, p, false))),
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

  void _showTx(BuildContext ctx, AppProvider p, bool isDeposit) {
    final amountCtrl = TextEditingController();
    final descCtrl   = TextEditingController(text: isDeposit ? 'Deposit' : 'Withdrawal');
    final formKey    = GlobalKey<FormState>();
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SheetHandle(),
        Text(isDeposit ? 'Add Deposit' : 'Record Withdrawal', style: Theme.of(ctx).textTheme.headlineSmall),
        const SizedBox(height: 20),
        buildAmountField(controller: amountCtrl),
        const SizedBox(height: 12),
        TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), validator: (v) => v!.isEmpty ? 'Required' : null),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            final amt = double.parse(amountCtrl.text.trim());
            p.addBankTransaction(account.id, BankTransaction(id: p.newId(), description: descCtrl.text.trim(), amount: isDeposit ? amt : -amt, date: DateTime.now()));
            Navigator.pop(ctx);
          },
          child: Text(isDeposit ? 'Add Deposit' : 'Record Withdrawal'),
        )),
      ])),
    ));
  }

  void _confirmDelete(BuildContext ctx, AppProvider p) {
    showDialog(context: ctx, builder: (ctx) => AlertDialog(
      title: const Text('Delete Account'),
      content: Text('Delete "${account.name}"?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), TextButton(onPressed: () { p.deleteBankAccount(account.id); Navigator.pop(ctx); }, child: Text('Delete', style: TextStyle(color: kDangerColor)))],
    ));
  }
}
