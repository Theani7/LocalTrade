import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  // ── Backward-compat color aliases (screens will migrate to AppColors) ──
  static const Color primaryColor = AppColors.coral;
  static const Color primaryLight = AppColors.coralLight;
  static const Color primaryDark = AppColors.coralDark;
  static const Color secondaryColor = AppColors.blue;
  static const Color secondaryLight = AppColors.blueLight;
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceColor = AppColors.surface;
  static const Color errorColor = AppColors.danger;
  static const Color successColor = AppColors.success;
  static const Color warningColor = AppColors.warning;
  static const Color textPrimary = AppColors.ink;
  static const Color textSecondary = AppColors.muted;
  static const Color textLight = AppColors.muted;
  static const Color borderSubtle = AppColors.divider;
  static const Color borderMedium = AppColors.divider;

  static const Gradient primaryGradient = LinearGradient(
    colors: [AppColors.coral, AppColors.coralLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [AppColors.blue, AppColors.blueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient darkGradient = LinearGradient(
    colors: [AppColors.ink, AppColors.muted],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Shadows ───────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.ink.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: AppColors.ink.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Backward-compat aliases ────────────────────────────────────
  static ThemeData get lightTheme => light;

  static BoxDecoration glassDecoration({
    Color color = AppColors.surface,
    double opacity = 0.70,
    double borderRadius = 24,
  }) =>
      BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: softShadow,
      );

  // ── ThemeData ─────────────────────────────────────────────────
  static ThemeData get light {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.coral,
        onPrimary: AppColors.ink,
        secondary: AppColors.blue,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
          fontSize: 20,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
          fontSize: 17,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
          fontSize: 14,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.muted,
          fontSize: 13,
          height: 1.5,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.muted,
          fontSize: 11,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.coral.withOpacity(0.4),
          disabledForegroundColor: AppColors.ink.withOpacity(0.4),
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surface,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: const BorderSide(color: AppColors.ink, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        color: AppColors.surface,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: GoogleFonts.inter(color: AppColors.muted.withOpacity(0.6), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.coral,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 11),
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        backgroundColor: AppColors.coralLight,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: AppColors.coralDark,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
