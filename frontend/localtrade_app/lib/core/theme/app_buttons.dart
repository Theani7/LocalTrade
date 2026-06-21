import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppButtons {
  AppButtons._();

  // ── Primary: coral fill, ink text ─────────────────────────────
  static ButtonStyle get primary => ElevatedButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.4),
        disabledForegroundColor: AppColors.ink.withValues(alpha: 0.4),
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
      );

  // ── Secondary: white fill, ink border, ink text ───────────────
  static ButtonStyle get secondary => OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.surface,
        disabledForegroundColor: AppColors.ink.withValues(alpha: 0.4),
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
      );

  // ── Destructive: red fill, white text (delete only) ───────────
  static ButtonStyle get destructive => ElevatedButton.styleFrom(
        backgroundColor: AppColors.danger,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      );

  // ── Outline negative: ink border, ink text (reject/suspend) ───
  static ButtonStyle get outlineNegative => OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(0, AppSpacing.touchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        side: const BorderSide(color: AppColors.ink, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );

  // ── Small inline (e.g., reserve on card) ──────────────────────
  static ButtonStyle get smallPrimary => ElevatedButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: AppColors.ink,
        elevation: 0,
        minimumSize: const Size(0, AppSpacing.touchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
}
