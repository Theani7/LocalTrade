import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppBadges {
  AppBadges._();

  // ── Status badge styles (light-fill + dark-text) ──────────────
  static const Map<String, BadgeStyle> statusStyles = {
    'pending': BadgeStyle(
      background: AppColors.warningLight,
      foreground: AppColors.warningDark,
    ),
    'confirmed': BadgeStyle(
      background: AppColors.blueLight,
      foreground: AppColors.blueDark,
    ),
    'delivered': BadgeStyle(
      background: AppColors.successLight,
      foreground: AppColors.successDark,
    ),
    'rejected': BadgeStyle(
      background: AppColors.coralLight,
      foreground: AppColors.coralDark,
    ),
  };

  static BadgeStyle styleFor(String status) =>
      statusStyles[status.toLowerCase()] ??
      const BadgeStyle(background: AppColors.coralLight, foreground: AppColors.coralDark);

  // ── Category chip (coral-light fill, coral-dark text) ─────────
  static const Map<String, Color> categoryChipColors = {
    'fill': AppColors.coralLight,
    'text': AppColors.coralDark,
  };
}

class BadgeStyle {
  final Color background;
  final Color foreground;
  const BadgeStyle({required this.background, required this.foreground});
}
