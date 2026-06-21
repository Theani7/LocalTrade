import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppBadges {
  AppBadges._();

  // ── Status badge styles (light-fill + dark-text) ──────────────
  static const Map<String, _BadgeStyle> statusStyles = {
    'pending': _BadgeStyle(
      background: AppColors.warningLight,
      foreground: AppColors.warningDark,
    ),
    'confirmed': _BadgeStyle(
      background: AppColors.blueLight,
      foreground: AppColors.blueDark,
    ),
    'delivered': _BadgeStyle(
      background: AppColors.successLight,
      foreground: AppColors.successDark,
    ),
    'rejected': _BadgeStyle(
      background: AppColors.coralLight,
      foreground: AppColors.coralDark,
    ),
  };

  static _BadgeStyle styleFor(String status) =>
      statusStyles[status.toLowerCase()] ??
      const _BadgeStyle(background: AppColors.coralLight, foreground: AppColors.coralDark);

  // ── Category chip (coral-light fill, coral-dark text) ─────────
  static const Map<String, Color> categoryChipColors = {
    'fill': AppColors.coralLight,
    'text': AppColors.coralDark,
  };
}

class _BadgeStyle {
  final Color background;
  final Color foreground;
  const _BadgeStyle({required this.background, required this.foreground});
}
