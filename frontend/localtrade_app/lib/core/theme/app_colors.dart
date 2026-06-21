import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Base ──────────────────────────────────────────────────────
  static const Color background = Color(0xFFFBF5EA); // Cream
  static const Color surface = Color(0xFFFFFFFF); // White card

  // ── Text ──────────────────────────────────────────────────────
  static const Color ink = Color(0xFF2B2620); // Primary text
  static const Color muted = Color(0xFF6E6557); // Secondary text

  // ── Coral (primary action) ────────────────────────────────────
  static const Color coral = Color(0xFFFF6F52); // Button fills only
  static const Color coralLight = Color(0xFFFCE0D6); // Badge/chip fill
  static const Color coralDark = Color(0xFF9A3318); // Text on coral-light

  // ── Electric blue (charts/data) ───────────────────────────────
  static const Color blue = Color(0xFF2F6FED);
  static const Color blueLight = Color(0xFFDEE9FE);
  static const Color blueDark = Color(0xFF1A3E8C);

  // ── Success ───────────────────────────────────────────────────
  static const Color success = Color(0xFF3B8C5A);
  static const Color successLight = Color(0xFFE0F2E6);
  static const Color successDark = Color(0xFF1F5C38);

  // ── Warning ───────────────────────────────────────────────────
  static const Color warning = Color(0xFFD9A441);
  static const Color warningLight = Color(0xFFFBEEDA);
  static const Color warningDark = Color(0xFF8A5F18);

  // ── Danger (delete only) ──────────────────────────────────────
  static const Color danger = Color(0xFFD32F2F);

  // ── Divider ───────────────────────────────────────────────────
  static const Color divider = Color(0xFFF1E9DA);
}
