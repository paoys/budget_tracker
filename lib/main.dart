// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart' as ap;
import 'utils/theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/income_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/credit_card_screen.dart';
import 'screens/recurring_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final provider = AppProvider();
  await provider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider(create: (_) => ap.AuthProvider()),
      ],
      child: const BudgetWiseApp(),
    ),
  );
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
      home: const _AuthGate(),
    );
  }
}

// ── Auth Gate ─────────────────────────────────────────────────────────────────
// Sits between BudgetWiseApp and MainShell.
// Listens to FirebaseAuth state and routes accordingly.
class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    // When auth state changes, trigger data sync in AppProvider
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      final appProvider = context.read<AppProvider>();
      if (user != null) {
        // Always clear stale data first, then load the new user's data.
        // clearUser() wipes both in-memory state and the local prefs cache,
        // preventing the previous account's data from bleeding into the new one.
        await appProvider.clearUser();
        appProvider.initForUser(user.uid);
      } else {
        appProvider.clearUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<ap.AuthProvider>().status;
    switch (authStatus) {
      case ap.AuthStatus.unknown:
        return const _SplashScreen();
      case ap.AuthStatus.authenticated:
        return const MainShell();
      case ap.AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}

// ── Splash Screen ─────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          Text('BudgetWise',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                letterSpacing: -1,
              )),
          const SizedBox(height: 24),
          const CircularProgressIndicator(strokeWidth: 2),
        ]),
      ),
    );
  }
}

// ── Main Shell ────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<AnimationController> _iconControllers;

  static const _items = [
    _NavItem(
        icon: Icons.space_dashboard_outlined,
        activeIcon: Icons.space_dashboard_rounded,
        label: 'Home'),
    _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Expenses'),
    _NavItem(
        icon: Icons.donut_large_outlined,
        activeIcon: Icons.donut_large_rounded,
        label: 'Budget'),
    _NavItem(
        icon: Icons.savings_outlined,
        activeIcon: Icons.savings_rounded,
        label: 'Savings'),
    _NavItem(
        icon: Icons.credit_card_outlined,
        activeIcon: Icons.credit_card_rounded,
        label: 'Cards'),
  ];

  static const _screens = [
    DashboardScreen(),
    ExpensesScreen(),
    BudgetScreen(),
    SavingsScreen(),
    CreditCardScreen(),
  ];

  static const _titles = [
    'Overview',
    'Expenses',
    'Budget',
    'Savings',
    'Credit Cards',
  ];

  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(
        _items.length,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 300)));
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
    final auth = context.watch<ap.AuthProvider>(); // for avatar + sync

    final ccDueCount = p.cardsDueSoon.length;
    final recurringDueCount = p.overdueRecurring.length;
    final totalAlerts = ccDueCount + recurringDueCount;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BudgetWise',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                  letterSpacing: 1)),
          Text(_titles[_currentIndex],
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  letterSpacing: -0.3)),
        ]),
        toolbarHeight: 60,
        actions: [
          // ── Cloud sync status pill ───────────────────────────────────
          _SyncIndicator(status: p.syncStatus),

          // ── Notifications badge ───────────────────────────
          if (totalAlerts > 0)
            Stack(children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => _onTap(4),
                icon: const Icon(Icons.notifications_outlined, size: 22),
              ),
              Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: kWarningColor, shape: BoxShape.circle),
                    child: Center(
                        child: Text('$totalAlerts',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.black))),
                  )),
            ]),

          // ── Income shortcut on Budget tab ──────────────────
          if (_currentIndex == 2)
            IconButton(
              tooltip: 'Income & Setup',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<AppProvider>(),
                          child: const IncomeScreen()))),
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 22),
            ),

          // ── Recurring shortcut on Cards tab ────────────────
          if (_currentIndex == 4)
            IconButton(
              tooltip: 'Recurring',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<AppProvider>(),
                          child: const RecurringScreen()))),
              icon: const Icon(Icons.repeat_outlined, size: 22),
            ),

          // The avatar taps through to Settings, keeping the same behaviour.
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(
                          value: context.read<AppProvider>()),
                      ChangeNotifierProvider.value(
                          value: context.read<ap.AuthProvider>()),
                    ],
                    child: const SettingsScreen(),
                  ),
                )),
            child: Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colors.surface2,
                backgroundImage:
                    auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
                onBackgroundImageError: auth.photoUrl != null
                    ? (exception, stackTrace) {
                        // Silently ignore, falls back to child widget
                      }
                    : null,
                child: auth.photoUrl == null
                    ? Text(
                        (auth.displayName ?? 'U')[0].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomBar(
        currentIndex: _currentIndex,
        items: _items,
        controllers: _iconControllers,
        onTap: _onTap,
        badges: {4: ccDueCount > 0},
      ),
    );
  }
}

// ── Sync status pill shown in the app bar ────────────────────────────────
class _SyncIndicator extends StatelessWidget {
  final SyncStatus status;
  const _SyncIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.idle) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (status == SyncStatus.syncing)
            SizedBox(
                width: 10,
                height: 10,
                child:
                    CircularProgressIndicator(strokeWidth: 1.5, color: _color))
          else
            Icon(_icon, size: 11, color: _color),
          const SizedBox(width: 4),
          Text(_label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: _color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Color get _color => status == SyncStatus.synced
      ? kSuccessColor
      : status == SyncStatus.error
          ? kDangerColor
          : kWarningColor;
  IconData get _icon => status == SyncStatus.synced
      ? Icons.cloud_done_rounded
      : Icons.cloud_off_rounded;
  String get _label => status == SyncStatus.syncing
      ? 'Syncing…'
      : status == SyncStatus.synced
          ? 'Synced'
          : 'Offline';
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final List<AnimationController> controllers;
  final void Function(int) onTap;
  final Map<int, bool> badges;
  const _BottomBar(
      {required this.currentIndex,
      required this.items,
      required this.controllers,
      required this.onTap,
      required this.badges});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.divider, width: 1))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(items.length, (i) {
              final sel = currentIndex == i;
              final item = items[i];
              final hasBadge = badges[i] ?? false;
              return Expanded(
                  child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedBuilder(
                  animation: controllers[i],
                  builder: (ctx, _) {
                    final t = controllers[i].value;
                    return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36,
                              height: 24,
                              decoration: BoxDecoration(
                                color: sel
                                    ? colors.textPrimary.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            Positioned.fill(
                                child: Center(
                                    child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                  Icon(sel ? item.activeIcon : item.icon,
                                      size: 19,
                                      color: Color.lerp(colors.textMuted,
                                          colors.textPrimary, t)),
                                  if (hasBadge)
                                    Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                                color: kWarningColor,
                                                shape: BoxShape.circle))),
                                ]))),
                          ]),
                          const SizedBox(height: 3),
                          Text(item.label,
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight:
                                      sel ? FontWeight.w700 : FontWeight.w400,
                                  color: Color.lerp(colors.textMuted,
                                      colors.textPrimary, t))),
                        ]);
                  },
                ),
              ));
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}
