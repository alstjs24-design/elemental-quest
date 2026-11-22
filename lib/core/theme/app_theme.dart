import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Color Tokens ──────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Backgrounds
  static const bgDeep    = Color(0xFF050D14);
  static const bgDark    = Color(0xFF0D1B2A);
  static const bgPurple  = Color(0xFF1A0A2E);
  static const bgCard    = Color(0xFF0F1923);

  // Gradients
  static const gradientTop    = Color(0xFF1A0A2E);
  static const gradientBottom = Color(0xFF0D1B2A);

  // Accent colors (per zone/feature)
  static const fire    = Color(0xFFE07840); // 소리치는 아이 / PvP
  static const water   = Color(0xFF4A90D9); // 받아들이는 아이 / 캐릭터
  static const wind    = Color(0xFF4DB6AC); // 바라보는 아이 / 런
  static const earth   = Color(0xFF78C55A); // 작아지는 아이

  // Feature colors
  static const run       = Color(0xFF4DB6AC);
  static const dungeon   = Color(0xFF8B2FC9);
  static const pvp       = Color(0xFFE07840);
  static const character = Color(0xFF4A90D9);
  static const legacy    = Color(0xFF9C27B0);
  static const soul      = Color(0xFFCE93D8);

  // HP colors
  static const hpHigh = Color(0xFF4CAF50);
  static const hpMid  = Color(0xFFFF9800);
  static const hpLow  = Color(0xFFF44336);

  // Text
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF); // white70
  static const textMuted     = Color(0x99FFFFFF); // white60
  static const textDisabled  = Color(0x3DFFFFFF); // white24
}

// ── Typography ────────────────────────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.notoSansKr(
        fontSize: 32, fontWeight: FontWeight.w900,
        color: AppColors.textPrimary, letterSpacing: 1.5,
      );

  static TextStyle get titleLarge => GoogleFonts.notoSansKr(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.notoSansKr(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.notoSansKr(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.notoSansKr(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get labelBold => GoogleFonts.notoSansKr(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.notoSansKr(
        fontSize: 11, fontWeight: FontWeight.w400,
        color: AppColors.textDisabled,
      );

  static TextStyle get battleLog => GoogleFonts.notoSansKr(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.6,
      );
}

// ── Theme ─────────────────────────────────────────────────────────────────────

ThemeData buildAppTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bgDeep,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.fire,
      secondary: AppColors.water,
      surface: AppColors.bgCard,
      onPrimary: AppColors.textPrimary,
      onSecondary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: GoogleFonts.notoSansKrTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.titleMedium,
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.dungeon,
        foregroundColor: AppColors.textPrimary,
        textStyle: AppTextStyles.titleMedium,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x1AFFFFFF),
      thickness: 1,
    ),
    splashFactory: InkRipple.splashFactory,
  );
}
