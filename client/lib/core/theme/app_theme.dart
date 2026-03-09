import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════
/// LUMOS 原生企业级设计系统 — Clean, Native, Premium iOS-Style
/// ═══════════════════════════════════════════════════════════
class LumosColors {
  // ── 品牌核心色 (干净的 Apple 风格亮蓝色) ──
  static const Color primary = Color(0xFF007AFF); // iOS Blue Light
  static const Color primaryDark = Color(0xFF0A84FF); // iOS Blue Dark
  static const Color secondary = Color(0xFF5AC8FA); // iOS Cyan
  
  // ── 强调色 ──
  static const Color accent = Color(0xFF5856D6); // iOS Purple
  static const Color gold = Color(0xFFFF9500); // iOS Orange
  static const Color emerald = Color(0xFF34C759); // iOS Green
  static const Color red = Color(0xFFFF3B30); // iOS Red

  // ── Light Mode 色板 ──
  static const Color bgLight = Color(0xFFF2F2F7); // iOS Grouped Background
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLightPrimary = Color(0xFF000000);
  static const Color textLightSecondary = Color(0xFF3C3C43); // iOS Secondary Label (alpha)
  static const Color textLightTertiary = Color(0xFF8E8E93); // iOS Tertiary Label
  static const Color dividerLight = Color(0xFFC6C6C8); // iOS Separator

  // ── Dark Mode 色板 ──
  static const Color bgDark = Color(0xFF000000); // OLED Black
  static const Color surfaceDark = Color(0xFF1C1C1E); // iOS Elevated Background
  static const Color textDarkPrimary = Color(0xFFFFFFFF);
  static const Color textDarkSecondary = Color(0xFFEBEBF5); // iOS Secondary Label Dark (alpha)
  static const Color textDarkTertiary = Color(0xFF8E8E93); 
  static const Color dividerDark = Color(0xFF38383A); // iOS Separator Dark

  // ── 纯色底盘系统 ──
  static final List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> cardShadowDark = []; // 暗黑模式无阴影，纯靠背景区分
}

class LumosTheme {
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0; // 类似 iOS widget 弧度

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: LumosColors.primary,
        secondary: LumosColors.secondary,
        tertiary: LumosColors.accent,
        surface: LumosColors.surfaceLight,
        onSurface: LumosColors.textLightPrimary,
      ),
      scaffoldBackgroundColor: LumosColors.bgLight,
      dividerColor: LumosColors.dividerLight.withValues(alpha: 0.5),
      textTheme: _buildTextTheme(LumosColors.textLightPrimary, LumosColors.textLightSecondary.withValues(alpha: 0.6)),
      appBarTheme: AppBarTheme(
        backgroundColor: LumosColors.bgLight, // iOS通常和背景融为一体
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: LumosColors.primary),
        titleTextStyle: GoogleFonts.notoSansSc(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: LumosColors.textLightPrimary,
          letterSpacing: -0.41,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: LumosColors.primaryDark,
        secondary: LumosColors.secondary,
        tertiary: LumosColors.accent,
        surface: LumosColors.surfaceDark,
        onSurface: LumosColors.textDarkPrimary,
      ),
      scaffoldBackgroundColor: LumosColors.bgDark,
      dividerColor: LumosColors.dividerDark,
      textTheme: _buildTextTheme(LumosColors.textDarkPrimary, LumosColors.textDarkSecondary.withValues(alpha: 0.6)),
      appBarTheme: AppBarTheme(
        backgroundColor: LumosColors.bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: LumosColors.primaryDark),
        titleTextStyle: GoogleFonts.notoSansSc(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: LumosColors.textDarkPrimary,
          letterSpacing: -0.41,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.notoSansSc(fontSize: 34, fontWeight: FontWeight.bold, color: primary, letterSpacing: 0.37), // iOS Large Title
      displayMedium: GoogleFonts.notoSansSc(fontSize: 28, fontWeight: FontWeight.bold, color: primary, letterSpacing: 0.36), // iOS Title 1
      headlineLarge: GoogleFonts.notoSansSc(fontSize: 22, fontWeight: FontWeight.bold, color: primary, letterSpacing: 0.35), // iOS Title 2
      headlineMedium: GoogleFonts.notoSansSc(fontSize: 20, fontWeight: FontWeight.w600, color: primary, letterSpacing: 0.38), // iOS Title 3
      titleLarge: GoogleFonts.notoSansSc(fontSize: 17, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.41), // iOS Headline
      titleMedium: GoogleFonts.notoSansSc(fontSize: 17, fontWeight: FontWeight.w400, color: primary, letterSpacing: -0.41), // iOS Body
      bodyLarge: GoogleFonts.notoSansSc(fontSize: 16, color: primary),
      bodyMedium: GoogleFonts.notoSansSc(fontSize: 15, fontWeight: FontWeight.w400, color: secondary, letterSpacing: -0.24), // iOS Subheadline
      bodySmall: GoogleFonts.notoSansSc(fontSize: 13, fontWeight: FontWeight.w400, color: secondary, letterSpacing: -0.08), // iOS Footnote
      labelLarge: GoogleFonts.notoSansSc(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      labelMedium: GoogleFonts.notoSansSc(fontSize: 12, fontWeight: FontWeight.w500, color: primary),
    );
  }
}
