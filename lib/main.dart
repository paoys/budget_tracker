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
import 'services/notification_service.dart';
import 'widgets/notification_sheet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only lock to portrait on mobile; tablets/desktop stay free.
  // We do this lazily after first frame so we have a MediaQuery.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Leave orientation unlocked globally — MainShell re-locks if needed.
  });
  // Default portrait lock (overridden on wide screens inside MainShell)
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
       DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

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
class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      final appProvider = context.read<AppProvider>();
      if (user != null) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 72, height: 72, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF4338CA)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 36),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('BudgetWise',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28, fontWeight: FontWeight.w800,
                color: colors.textPrimary, letterSpacing: -1,
              )),
          const SizedBox(height: 24),
          const CircularProgressIndicator(strokeWidth: 2),
        ]),
      ),
    );
  }
}

// ── Nav item definition ───────────────────────────────────────────────────────
class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
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
    _NavItem(icon: Icons.space_dashboard_outlined,  activeIcon: Icons.space_dashboard_rounded,  label: 'Home'),
    _NavItem(icon: Icons.receipt_long_outlined,     activeIcon: Icons.receipt_long_rounded,     label: 'Expenses'),
    _NavItem(icon: Icons.donut_large_outlined,      activeIcon: Icons.donut_large_rounded,      label: 'Budget'),
    _NavItem(icon: Icons.savings_outlined,          activeIcon: Icons.savings_rounded,          label: 'Savings'),
    _NavItem(icon: Icons.credit_card_outlined,      activeIcon: Icons.credit_card_rounded,      label: 'Cards'),
  ];

  static const _screens = [
    DashboardScreen(),
    ExpensesScreen(),
    BudgetScreen(),
    SavingsScreen(),
    CreditCardScreen(),
  ];

  static const _titles = ['Overview', 'Expenses', 'Budget', 'Savings', 'Credit Cards'];

  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(
        _items.length,
        (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 300)));
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
    final isWide = Breakpoints.isWide(context);
    return isWide ? _buildWideLayout(context) : _buildNarrowLayout(context);
  }

  // ── Phone layout: AppBar + BottomBar ─────────────────────────────────────
  Widget _buildNarrowLayout(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final p = context.watch<AppProvider>();
    final auth = context.watch<ap.AuthProvider>();
    final allNotifs = NotificationService.buildNotifications(p);
    final recurringDueCount = p.overdueRecurring.length;
    final ccDueCount = p.cardsDueSoon.length;
    final totalAlerts = allNotifs.length;

    return Scaffold(
      appBar: _buildAppBar(context, colors, p, auth, allNotifs, totalAlerts),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomBar(
        currentIndex: _currentIndex,
        items: _items,
        controllers: _iconControllers,
        onTap: _onTap,
        badges: {
          0: recurringDueCount > 0,
          2: allNotifs.any((n) => n.type == NotifType.overBudget),
          4: ccDueCount > 0,
        },
      ),
    );
  }

  // ── Tablet/Desktop layout: Side Rail + expanded content ──────────────────
  Widget _buildWideLayout(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final p = context.watch<AppProvider>();
    final auth = context.watch<ap.AuthProvider>();
    final allNotifs = NotificationService.buildNotifications(p);
    final recurringDueCount = p.overdueRecurring.length;
    final ccDueCount = p.cardsDueSoon.length;
    final totalAlerts = allNotifs.length;
    final isExpanded = Breakpoints.isExpanded(context);

    final badges = {
      0: recurringDueCount > 0,
      2: allNotifs.any((n) => n.type == NotifType.overBudget),
      4: ccDueCount > 0,
    };

    return Scaffold(
      body: Row(
        children: [
          // ── Side Navigation Rail / Drawer ──────────────────────────────
          _SideNav(
            currentIndex: _currentIndex,
            items: _items,
            controllers: _iconControllers,
            onTap: _onTap,
            badges: badges,
            colors: colors,
            p: p,
            auth: auth,
            allNotifs: allNotifs,
            totalAlerts: totalAlerts,
            isExpanded: isExpanded,
            currentTitle: _titles[_currentIndex],
            context: context,
          ),
          // ── Vertical divider ───────────────────────────────────────────
          VerticalDivider(width: 1, thickness: 1, color: colors.divider),
          // ── Main content area ──────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar (no hamburger needed, rail is always visible)
                _WideTopBar(
                  title: _titles[_currentIndex],
                  colors: colors,
                  p: p,
                  auth: auth,
                  allNotifs: allNotifs,
                  totalAlerts: totalAlerts,
                  currentIndex: _currentIndex,
                  context: context,
                ),
                Divider(height: 1, thickness: 1, color: colors.divider),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: _screens),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, AppColors colors, AppProvider p,
      ap.AuthProvider auth, List<dynamic> allNotifs, int totalAlerts) {
    return AppBar(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BudgetWise',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: colors.textMuted, letterSpacing: 1)),
        Text(_titles[_currentIndex],
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: colors.textPrimary, letterSpacing: -0.3)),
      ]),
      toolbarHeight: 60,
      actions: _buildActions(context, colors, p, auth, allNotifs, totalAlerts),
    );
  }

  List<Widget> _buildActions(BuildContext context, AppColors colors,
      AppProvider p, ap.AuthProvider auth, List<dynamic> allNotifs, int totalAlerts) {
    return [
      _SyncIndicator(status: p.syncStatus),
      if (totalAlerts > 0)
        Stack(children: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => showNotificationSheet(context),
            icon: const Icon(Icons.notifications_outlined, size: 22),
          ),
          Positioned(
              top: 8, right: 8,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(color: kWarningColor, shape: BoxShape.circle),
                child: Center(child: Text('$totalAlerts',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black))),
              )),
        ]),
      if (_currentIndex == 2)
        IconButton(
          tooltip: 'Income & Setup',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
                  value: context.read<AppProvider>(), child: const IncomeScreen()))),
          icon: const Icon(Icons.account_balance_wallet_outlined, size: 22),
        ),
      if (_currentIndex == 4)
        IconButton(
          tooltip: 'Recurring',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
                  value: context.read<AppProvider>(), child: const RecurringScreen()))),
          icon: const Icon(Icons.repeat_outlined, size: 22),
        ),
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => MultiProvider(providers: [
            ChangeNotifierProvider.value(value: context.read<AppProvider>()),
            ChangeNotifierProvider.value(value: context.read<ap.AuthProvider>()),
          ], child: const SettingsScreen()),
        )),
        child: Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: CircleAvatar(
            radius: 16, backgroundColor: colors.surface2,
            backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
            onBackgroundImageError: auth.photoUrl != null ? (e, s) {} : null,
            child: auth.photoUrl == null
                ? Text((auth.displayName ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary))
                : null,
          ),
        ),
      ),
    ];
  }
}

// ── Side Navigation (tablet/desktop) ─────────────────────────────────────────
class _SideNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final List<AnimationController> controllers;
  final void Function(int) onTap;
  final Map<int, bool> badges;
  final AppColors colors;
  final AppProvider p;
  final ap.AuthProvider auth;
  final List<dynamic> allNotifs;
  final int totalAlerts;
  final bool isExpanded;
  final String currentTitle;
  final BuildContext context;

  const _SideNav({
    required this.currentIndex,
    required this.items,
    required this.controllers,
    required this.onTap,
    required this.badges,
    required this.colors,
    required this.p,
    required this.auth,
    required this.allNotifs,
    required this.totalAlerts,
    required this.isExpanded,
    required this.currentTitle,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final width = isExpanded ? 220.0 : 72.0;

    return Container(
      width: width,
      color: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Logo / brand ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isExpanded ? 20 : 0, vertical: 20),
              child: isExpanded
                  ? Row(children: [
                      _LogoIcon(),
                      const SizedBox(width: 10),
                      Text('BudgetWise',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16, fontWeight: FontWeight.w800,
                              color: colors.textPrimary, letterSpacing: -0.5)),
                    ])
                  : Center(child: _LogoIcon()),
            ),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: 8),
            // ── Nav items ─────────────────────────────────────────────────
            ...List.generate(items.length, (i) {
              final sel = currentIndex == i;
              final item = items[i];
              final hasBadge = badges[i] ?? false;
              return _SideNavItem(
                item: item,
                selected: sel,
                hasBadge: hasBadge,
                controller: controllers[i],
                isExpanded: isExpanded,
                colors: colors,
                onTap: () => onTap(i),
              );
            }),
            const Spacer(),
            Divider(height: 1, color: colors.divider),
            // ── Bottom actions ─────────────────────────────────────────────
            _SideNavAction(
              icon: Icons.notifications_outlined,
              label: 'Alerts',
              badge: totalAlerts > 0 ? '$totalAlerts' : null,
              isExpanded: isExpanded,
              colors: colors,
              onTap: totalAlerts > 0 ? () => showNotificationSheet(ctx) : null,
            ),
            _SideNavAction(
              icon: Icons.settings_outlined,
              label: 'Settings',
              isExpanded: isExpanded,
              colors: colors,
              onTap: () => Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => MultiProvider(providers: [
                  ChangeNotifierProvider.value(value: ctx.read<AppProvider>()),
                  ChangeNotifierProvider.value(value: ctx.read<ap.AuthProvider>()),
                ], child: const SettingsScreen()),
              )),
            ),
            // ── User avatar ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 16 : 0, vertical: 16),
              child: isExpanded
                  ? GestureDetector(
                      onTap: () => Navigator.push(ctx, MaterialPageRoute(
                        builder: (_) => MultiProvider(providers: [
                          ChangeNotifierProvider.value(value: ctx.read<AppProvider>()),
                          ChangeNotifierProvider.value(value: ctx.read<ap.AuthProvider>()),
                        ], child: const SettingsScreen()),
                      )),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 16, backgroundColor: colors.surface3,
                            backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
                            child: auth.photoUrl == null
                                ? Text((auth.displayName ?? 'U')[0].toUpperCase(),
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(auth.displayName ?? 'User',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
                                  overflow: TextOverflow.ellipsis),
                              Text(auth.email ?? '',
                                  style: GoogleFonts.inter(fontSize: 11, color: colors.textMuted),
                                  overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                        ]),
                      ),
                    )
                  : Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => MultiProvider(providers: [
                            ChangeNotifierProvider.value(value: ctx.read<AppProvider>()),
                            ChangeNotifierProvider.value(value: ctx.read<ap.AuthProvider>()),
                          ], child: const SettingsScreen()),
                        )),
                        child: CircleAvatar(
                          radius: 16, backgroundColor: colors.surface2,
                          backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
                          child: auth.photoUrl == null
                              ? Text((auth.displayName ?? 'U')[0].toUpperCase(),
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary))
                              : null,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/images/app_logo.png',
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF4338CA)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 17),
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool hasBadge;
  final AnimationController controller;
  final bool isExpanded;
  final AppColors colors;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.item, required this.selected, required this.hasBadge,
    required this.controller, required this.isExpanded,
    required this.colors, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final t = controller.value;
        final iconColor = Color.lerp(colors.textMuted, colors.textPrimary, t)!;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12 : 8, vertical: 2),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 12 : 0, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.textPrimary.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: isExpanded
                  ? Row(children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Icon(selected ? item.activeIcon : item.icon, size: 20, color: iconColor),
                        if (hasBadge)
                          Positioned(top: -2, right: -2,
                            child: Container(width: 7, height: 7,
                              decoration: const BoxDecoration(color: kWarningColor, shape: BoxShape.circle))),
                      ]),
                      const SizedBox(width: 12),
                      Text(item.label,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: iconColor)),
                    ])
                  : Center(
                      child: Stack(clipBehavior: Clip.none, children: [
                        Icon(selected ? item.activeIcon : item.icon, size: 22, color: iconColor),
                        if (hasBadge)
                          Positioned(top: -2, right: -2,
                            child: Container(width: 7, height: 7,
                              decoration: const BoxDecoration(color: kWarningColor, shape: BoxShape.circle))),
                      ]),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _SideNavAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool isExpanded;
  final AppColors colors;
  final VoidCallback? onTap;

  const _SideNavAction({
    required this.icon, required this.label, required this.isExpanded,
    required this.colors, this.badge, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12 : 8, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12 : 0, vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: isExpanded
              ? Row(children: [
                  Stack(clipBehavior: Clip.none, children: [
                    Icon(icon, size: 20, color: colors.textMuted),
                    if (badge != null)
                      Positioned(top: -4, right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: kWarningColor, shape: BoxShape.circle),
                          child: Text(badge!, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.black)))),
                  ]),
                  const SizedBox(width: 12),
                  Text(label, style: GoogleFonts.inter(fontSize: 14, color: colors.textMuted)),
                ])
              : Center(
                  child: Stack(clipBehavior: Clip.none, children: [
                    Icon(icon, size: 22, color: colors.textMuted),
                    if (badge != null)
                      Positioned(top: -4, right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: kWarningColor, shape: BoxShape.circle),
                          child: Text(badge!, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.black)))),
                  ]),
                ),
        ),
      ),
    );
  }
}

// ── Wide Top Bar ──────────────────────────────────────────────────────────────
class _WideTopBar extends StatelessWidget {
  final String title;
  final AppColors colors;
  final AppProvider p;
  final ap.AuthProvider auth;
  final List<dynamic> allNotifs;
  final int totalAlerts;
  final int currentIndex;
  final BuildContext context;

  const _WideTopBar({
    required this.title, required this.colors, required this.p,
    required this.auth, required this.allNotifs, required this.totalAlerts,
    required this.currentIndex, required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Container(
      height: 60,
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('BudgetWise',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: colors.textMuted, letterSpacing: 1)),
            Text(title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: colors.textPrimary, letterSpacing: -0.3)),
          ]),
          const Spacer(),
          _SyncIndicator(status: p.syncStatus),
          // Contextual actions
          if (currentIndex == 2)
            TextButton.icon(
              onPressed: () => Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                      value: ctx.read<AppProvider>(), child: const IncomeScreen()))),
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
              label: const Text('Income'),
            ),
          if (currentIndex == 4)
            TextButton.icon(
              onPressed: () => Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                      value: ctx.read<AppProvider>(), child: const RecurringScreen()))),
              icon: const Icon(Icons.repeat_outlined, size: 16),
              label: const Text('Recurring'),
            ),
        ],
      ),
    );
  }
}

// ── Sync status pill ──────────────────────────────────────────────────────────
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
          color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (status == SyncStatus.syncing)
            SizedBox(width: 10, height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: _color))
          else
            Icon(_icon, size: 11, color: _color),
          const SizedBox(width: 4),
          Text(_label, style: GoogleFonts.inter(fontSize: 10, color: _color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Color get _color => status == SyncStatus.synced ? kSuccessColor
      : status == SyncStatus.error ? kDangerColor : kWarningColor;
  IconData get _icon => status == SyncStatus.synced
      ? Icons.cloud_done_rounded : Icons.cloud_off_rounded;
  String get _label => status == SyncStatus.syncing ? 'Syncing…'
      : status == SyncStatus.synced ? 'Synced' : 'Offline';
}

// ── Bottom Navigation Bar (phone only) ───────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final List<AnimationController> controllers;
  final void Function(int) onTap;
  final Map<int, bool> badges;
  const _BottomBar({required this.currentIndex, required this.items,
      required this.controllers, required this.onTap, required this.badges});

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
                    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Stack(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36, height: 24,
                          decoration: BoxDecoration(
                            color: sel ? colors.textPrimary.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Positioned.fill(child: Center(
                            child: Stack(clipBehavior: Clip.none, children: [
                          Icon(sel ? item.activeIcon : item.icon,
                              size: 19,
                              color: Color.lerp(colors.textMuted, colors.textPrimary, t)),
                          if (hasBadge)
                            Positioned(top: -2, right: -2,
                              child: Container(width: 6, height: 6,
                                decoration: const BoxDecoration(color: kWarningColor, shape: BoxShape.circle))),
                        ]))),
                      ]),
                      const SizedBox(height: 3),
                      Text(item.label,
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                              color: Color.lerp(colors.textMuted, colors.textPrimary, t))),
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