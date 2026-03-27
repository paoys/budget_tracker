// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

// ── Semantic Colors ───────────────────────────────────────────────────────────
const kNeedsColor    = Color(0xFF60A5FA);
const kWantsColor    = Color(0xFFA78BFA);
const kSavingsColor  = Color(0xFF34D399);
const kDangerColor   = Color(0xFFF87171);
const kSuccessColor  = Color(0xFF34D399);
const kWarningColor  = Color(0xFFFBBF24);
const kNeedsLight    = Color(0xFF2563EB);
const kWantsLight    = Color(0xFF7C3AED);
const kSavingsLight  = Color(0xFF059669);

ThemeData buildTheme({required bool dark}) {
  final bg       = dark ? const Color(0xFF0D0D0F) : const Color(0xFFF7F7F8);
  final surface  = dark ? const Color(0xFF17171A) : const Color(0xFFFFFFFF);
  final surface2 = dark ? const Color(0xFF1F1F23) : const Color(0xFFF0F0F2);
  final surface3 = dark ? const Color(0xFF27272C) : const Color(0xFFE4E4EA);
  final divider  = dark ? const Color(0xFF2A2A30) : const Color(0xFFE2E2E8);
  final text     = dark ? const Color(0xFFF2F2F4) : const Color(0xFF0F0F12);
  final textSub  = dark ? const Color(0xFF8A8A9A) : const Color(0xFF6B6B7E);
  final textMuted= dark ? const Color(0xFF4A4A5A) : const Color(0xFFAAAAAB);
  final needsC   = dark ? kNeedsColor  : kNeedsLight;
  final wantsC   = dark ? kWantsColor  : kWantsLight;
  final savingsC = dark ? kSavingsColor: kSavingsLight;

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: dark ? Colors.white : Colors.black,
      onPrimary: dark ? Colors.black : Colors.white,
      secondary: needsC,
      onSecondary: Colors.white,
      tertiary: wantsC,
      error: kDangerColor,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      headlineLarge:  GoogleFonts.plusJakartaSans(color: text, fontWeight: FontWeight.w800, letterSpacing: -1, fontSize: 30),
      headlineMedium: GoogleFonts.plusJakartaSans(color: text, fontWeight: FontWeight.w700, letterSpacing: -0.5, fontSize: 24),
      headlineSmall:  GoogleFonts.plusJakartaSans(color: text, fontWeight: FontWeight.w600, letterSpacing: -0.3, fontSize: 20),
      titleLarge:     GoogleFonts.inter(color: text, fontWeight: FontWeight.w600, fontSize: 17),
      titleMedium:    GoogleFonts.inter(color: text, fontWeight: FontWeight.w500, fontSize: 15),
      titleSmall:     GoogleFonts.inter(color: text, fontWeight: FontWeight.w500, fontSize: 13),
      bodyLarge:      GoogleFonts.inter(color: text, fontWeight: FontWeight.w400, fontSize: 15),
      bodyMedium:     GoogleFonts.inter(color: textSub, fontWeight: FontWeight.w400, fontSize: 14),
      bodySmall:      GoogleFonts.inter(color: textSub, fontWeight: FontWeight.w400, fontSize: 12),
      labelLarge:     GoogleFonts.inter(color: text, fontWeight: FontWeight.w600, fontSize: 14),
      labelMedium:    GoogleFonts.inter(color: textSub, fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall:     GoogleFonts.inter(color: textMuted, fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 0.8),
    ),
    cardTheme: CardThemeData(
      color: surface, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: divider)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(color: text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      iconTheme: IconThemeData(color: text),
    ),
    dividerTheme: DividerThemeData(color: divider, space: 1, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: text, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kDangerColor)),
      labelStyle: GoogleFonts.inter(color: textSub, fontSize: 13),
      hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: dark ? Colors.white : Colors.black,
        foregroundColor: dark ? Colors.black : Colors.white,
        elevation: 0, shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? surface3 : const Color(0xFF1A1A1E),
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    extensions: [
      AppColors(
        bg: bg, surface: surface, surface2: surface2, surface3: surface3,
        divider: divider, textPrimary: text, textSecondary: textSub, textMuted: textMuted,
        needs: needsC, wants: wantsC, savings: savingsC, isDark: dark,
      ),
    ],
  );
}

class AppColors extends ThemeExtension<AppColors> {
  final Color bg, surface, surface2, surface3, divider;
  final Color textPrimary, textSecondary, textMuted;
  final Color needs, wants, savings;
  final bool isDark;

  const AppColors({required this.bg, required this.surface, required this.surface2, required this.surface3, required this.divider, required this.textPrimary, required this.textSecondary, required this.textMuted, required this.needs, required this.wants, required this.savings, required this.isDark});

  Color forCategory(CategoryType cat) => cat == CategoryType.needs ? needs : cat == CategoryType.wants ? wants : savings;
  Color bgForCategory(CategoryType cat) => forCategory(cat).withOpacity(isDark ? 0.15 : 0.1);

  @override
  AppColors copyWith({Color? bg, Color? surface, Color? surface2, Color? surface3, Color? divider, Color? textPrimary, Color? textSecondary, Color? textMuted, Color? needs, Color? wants, Color? savings, bool? isDark}) =>
    AppColors(bg: bg??this.bg, surface: surface??this.surface, surface2: surface2??this.surface2, surface3: surface3??this.surface3, divider: divider??this.divider, textPrimary: textPrimary??this.textPrimary, textSecondary: textSecondary??this.textSecondary, textMuted: textMuted??this.textMuted, needs: needs??this.needs, wants: wants??this.wants, savings: savings??this.savings, isDark: isDark??this.isDark);

  @override
  AppColors lerp(AppColors? other, double t) => this;
}

final pesoFmt      = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
final shortPesoFmt = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
final dateFmt      = DateFormat('MMM dd, yyyy');
final shortDateFmt = DateFormat('MMM dd');
final monthFmt     = DateFormat('MMMM yyyy');
