import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Screen titles ─────────────────────────────────────────────
  static TextStyle screenTitle = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    letterSpacing: -0.3,
  );

  // ── Section headings ──────────────────────────────────────────
  static TextStyle sectionHeading = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    letterSpacing: -0.2,
  );

  // ── Product / vendor names ────────────────────────────────────
  static TextStyle cardTitle = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  // ── Prices ────────────────────────────────────────────────────
  static TextStyle price = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  // ── Body ──────────────────────────────────────────────────────
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    height: 1.5,
  );

  static TextStyle bodyMuted = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: 1.5,
  );

  // ── Labels / captions ─────────────────────────────────────────
  static TextStyle label = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    letterSpacing: 0.2,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );

  // ── Button text ───────────────────────────────────────────────
  static TextStyle buttonPrimary = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  static TextStyle buttonSecondary = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  static TextStyle buttonDestructive = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // ── Badge text ────────────────────────────────────────────────
  static TextStyle badge = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}
