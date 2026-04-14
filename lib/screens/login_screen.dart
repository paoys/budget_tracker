// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as ap;
import '../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regPass2Ctrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureReg1 = true;
  bool _obscureReg2 = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [
      _emailCtrl,
      _passCtrl,
      _nameCtrl,
      _regEmailCtrl,
      _regPassCtrl,
      _regPass2Ctrl
    ]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final auth = context.watch<ap.AuthProvider>();

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Top hero ────────────────────────────────────────────────────────
          _TopHero(colors: colors),

          // ── Card panel ──────────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: colors.divider),
                  left: BorderSide(color: colors.divider),
                  right: BorderSide(color: colors.divider),
                ),
              ),
              child: Column(children: [
                const SizedBox(height: 20),

                // Tab switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicator: BoxDecoration(
                        color: colors.textPrimary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      unselectedLabelStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w400, fontSize: 14),
                      labelColor: colors.bg,
                      unselectedLabelColor: colors.textSecondary,
                      tabs: const [Tab(text: 'Sign In'), Tab(text: 'Register')],
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Error banner
                if (auth.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: _ErrorBanner(
                        message: auth.errorMessage!,
                        onDismiss: auth.clearError),
                  ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      // Sign In tab
                      _FormShell(
                        child: Form(
                          key: _loginKey,
                          child: Column(children: [
                            _Field(
                              controller: _emailCtrl,
                              label: 'Email address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || !v.contains('@')
                                  ? 'Enter a valid email'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _passCtrl,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscurePass,
                              onToggleObscure: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                              validator: (v) => v == null || v.length < 6
                                  ? 'Minimum 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => _showForgotSheet(context, auth),
                                child: Text(
                                  'Forgot password?',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _PrimaryButton(
                              label: 'Sign In',
                              isLoading: auth.isLoading,
                              onTap: () => _signIn(auth),
                            ),
                            const SizedBox(height: 16),
                            _OrDivider(colors: colors),
                            const SizedBox(height: 16),
                            _GoogleButton(
                                isLoading: auth.isLoading,
                                onTap: () => _googleSignIn(auth)),
                          ]),
                        ),
                      ),

                      // Register tab
                      _FormShell(
                        child: Form(
                          key: _registerKey,
                          child: Column(children: [
                            _Field(
                              controller: _nameCtrl,
                              label: 'Full name',
                              icon: Icons.person_outline_rounded,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _regEmailCtrl,
                              label: 'Email address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || !v.contains('@')
                                  ? 'Enter a valid email'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _regPassCtrl,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscureReg1,
                              onToggleObscure: () =>
                                  setState(() => _obscureReg1 = !_obscureReg1),
                              validator: (v) => v == null || v.length < 6
                                  ? 'Minimum 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _regPass2Ctrl,
                              label: 'Confirm password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscureReg2,
                              onToggleObscure: () =>
                                  setState(() => _obscureReg2 = !_obscureReg2),
                              validator: (v) => v != _regPassCtrl.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            _PrimaryButton(
                              label: 'Create Account',
                              isLoading: auth.isLoading,
                              onTap: () => _register(auth),
                            ),
                            const SizedBox(height: 16),
                            _OrDivider(colors: colors),
                            const SizedBox(height: 16),
                            _GoogleButton(
                                isLoading: auth.isLoading,
                                onTap: () => _googleSignIn(auth)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _signIn(ap.AuthProvider auth) async {
    if (!_loginKey.currentState!.validate()) return;
    await auth.signInWithEmail(_emailCtrl.text, _passCtrl.text);
  }

  Future<void> _register(ap.AuthProvider auth) async {
    if (!_registerKey.currentState!.validate()) return;
    await auth.registerWithEmail(
        _regEmailCtrl.text, _regPassCtrl.text, _nameCtrl.text);
  }

  Future<void> _googleSignIn(ap.AuthProvider auth) => auth.signInWithGoogle();

  void _showForgotSheet(BuildContext ctx, ap.AuthProvider auth) {
    final ctrl = TextEditingController(text: _emailCtrl.text);
    final colors = Theme.of(ctx).extension<AppColors>()!;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 32),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                          color: colors.surface3,
                          borderRadius: BorderRadius.circular(2)))),
              Text('Reset Password',
                  style: Theme.of(sheetCtx).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text("Enter your email and we'll send a reset link.",
                  style: Theme.of(sheetCtx).textTheme.bodyMedium),
              const SizedBox(height: 20),
              TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined, size: 18)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await auth.sendPasswordReset(ctrl.text);
                    if (sheetCtx.mounted) {
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text(ok
                            ? 'Reset link sent! Check your inbox.'
                            : auth.errorMessage ?? 'Failed'),
                        backgroundColor: ok ? kSuccessColor : kDangerColor,
                      ));
                    }
                  },
                  child: const Text('Send Reset Link'),
                ),
              ),
            ]),
      ),
    );
  }
}

// ─── Top Hero ─────────────────────────────────────────────────────────────────
class _TopHero extends StatelessWidget {
  final AppColors colors;
  const _TopHero({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      color: colors.bg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // App icon
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: colors.isDark
                ? const Color(0xFF1C1C22)
                : const Color(0xFF0F0F12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.asset(
            'images/app_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text('BudgetWise',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                letterSpacing: -1)),
        const SizedBox(height: 4),
        Text('Track. Save. Thrive.',
            style:
                GoogleFonts.inter(fontSize: 15, color: colors.textSecondary)),
      ]),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kDangerColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kDangerColor.withOpacity(0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: kDangerColor),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(fontSize: 13, color: kDangerColor))),
          GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close_rounded,
                  size: 16, color: kDangerColor)),
        ]),
      );
}

// ─── Form Shell (scrollable padding) ─────────────────────────────────────────
class _FormShell extends StatelessWidget {
  final Widget child;
  const _FormShell({required this.child});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: child,
      );
}

// ─── Input Field ──────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool? obscure;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscure,
    this.onToggleObscure,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure ?? false,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: colors.textSecondary),
        suffixIcon: onToggleObscure != null
            ? GestureDetector(
                onTap: onToggleObscure,
                child: Icon(
                  (obscure ?? false)
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: colors.textSecondary,
                ),
              )
            : null,
      ),
    );
  }
}

// ─── Primary Button ───────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  const _PrimaryButton(
      {required this.label, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: colors.bg),
              )
            : Text(label,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Or Divider ───────────────────────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  final AppColors colors;
  const _OrDivider({required this.colors});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Divider(color: colors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('or continue with',
              style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted)),
        ),
        Expanded(child: Divider(color: colors.divider)),
      ]);
}

// ─── Google Button ────────────────────────────────────────────────────────────
class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _GoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.divider),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _GoogleG(),
              const SizedBox(width: 10),
              Text('Google',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Image.asset('images/google_logo.png', fit: BoxFit.contain),
    );
  }
}
