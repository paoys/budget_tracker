// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'utils/theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/income_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/credit_card_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  final provider = AppProvider();
  await provider.init();
  runApp(ChangeNotifierProvider.value(value: provider, child: const BudgetWiseApp()));
}

class BudgetWiseApp extends StatelessWidget {
  const BudgetWiseApp({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = context.select<AppProvider, bool>((p) => p.isDarkMode);
    return MaterialApp(
      title: 'BudgetWise',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(dark: false),
      darkTheme: buildTheme(dark: true),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<AnimationController> _iconControllers;

  static const _items = [
    _NavItem(icon: Icons.space_dashboard_outlined, activeIcon: Icons.space_dashboard_rounded, label: 'Home'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Income'),
    _NavItem(icon: Icons.donut_large_outlined, activeIcon: Icons.donut_large_rounded, label: 'Budget'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Expenses'),
    _NavItem(icon: Icons.savings_outlined, activeIcon: Icons.savings_rounded, label: 'Savings'),
    _NavItem(icon: Icons.credit_card_outlined, activeIcon: Icons.credit_card_rounded, label: 'Cards'),
  ];

  static const _screens = [
    DashboardScreen(), IncomeScreen(), BudgetScreen(),
    ExpensesScreen(), SavingsScreen(), CreditCardScreen(),
  ];

  static const _titles = [
    'Overview', 'Income & Setup', 'Budget', 'Expenses', 'Savings', 'Credit Cards',
  ];

  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(_items.length, (_) =>
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300)));
    _iconControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _iconControllers) c.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (i == _currentIndex) return;
    _iconControllers[_currentIndex].reverse();
    setState(() => _currentIndex = i);
    _iconControllers[i].forward();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final p = context.watch<AppProvider>();
    final dueSoonCount = p.creditCards.where((c) => c.daysUntilDue <= 7 && c.balance > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BudgetWise', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textMuted, letterSpacing: 1)),
          Text(_titles[_currentIndex], style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary, letterSpacing: -0.3)),
        ]),
        toolbarHeight: 60,
        actions: [
          if (dueSoonCount > 0)
            Stack(children: [
              IconButton(onPressed: () => _onTap(5), icon: const Icon(Icons.notifications_outlined, size: 22)),
              Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: kWarningColor, shape: BoxShape.circle))),
            ]),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(value: context.read<AppProvider>(), child: const SettingsScreen()))),
            icon: const Icon(Icons.settings_outlined, size: 22),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomBar(
        currentIndex: _currentIndex, items: _items, controllers: _iconControllers,
        onTap: _onTap, dueBadgeIndex: 5, hasDue: dueSoonCount > 0,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final List<AnimationController> controllers;
  final void Function(int) onTap;
  final int dueBadgeIndex;
  final bool hasDue;
  const _BottomBar({required this.currentIndex, required this.items, required this.controllers, required this.onTap, required this.dueBadgeIndex, required this.hasDue});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.divider, width: 1))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(children: List.generate(items.length, (i) {
            final sel = currentIndex == i;
            final item = items[i];
            return Expanded(child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: controllers[i],
                builder: (ctx, _) {
                  final t = controllers[i].value;
                  return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Stack(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: sel ? 40 : 28, height: sel ? 26 : 0,
                        decoration: sel ? BoxDecoration(color: colors.textPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(13)) : null,
                      ),
                      Positioned.fill(child: Center(child: Stack(clipBehavior: Clip.none, children: [
                        Icon(sel ? item.activeIcon : item.icon, size: 20, color: Color.lerp(colors.textMuted, colors.textPrimary, t)),
                        if (i == dueBadgeIndex && hasDue)
                          Positioned(top: -2, right: -2, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: kWarningColor, shape: BoxShape.circle))),
                      ]))),
                    ]),
                    const SizedBox(height: 3),
                    Text(item.label, style: GoogleFonts.inter(fontSize: 10, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, color: Color.lerp(colors.textMuted, colors.textPrimary, t))),
                  ]);
                },
              ),
            ));
          })),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
