import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum BadgeStatus { pending, confirmed, delivered, rejected }

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final config = _config();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.foreground),
          const SizedBox(width: 5),
          Text(
            customLabel ?? config.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: config.foreground,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _config() {
    switch (status) {
      case BadgeStatus.pending:
        return _BadgeConfig(
          background: AppColors.warningLight,
          foreground: AppColors.warningDark,
          icon: Icons.access_time_rounded,
          label: 'Pending',
        );
      case BadgeStatus.confirmed:
        return _BadgeConfig(
          background: AppColors.blueLight,
          foreground: AppColors.blueDark,
          icon: Icons.check_rounded,
          label: 'Confirmed',
        );
      case BadgeStatus.delivered:
        return _BadgeConfig(
          background: AppColors.successLight,
          foreground: AppColors.successDark,
          icon: Icons.check_circle_outline_rounded,
          label: 'Delivered',
        );
      case BadgeStatus.rejected:
        return _BadgeConfig(
          background: AppColors.coralLight,
          foreground: AppColors.coralDark,
          icon: Icons.close_rounded,
          label: 'Rejected',
        );
    }
  }
}

class _BadgeConfig {
  final Color background;
  final Color foreground;
  final IconData icon;
  final String label;
  const _BadgeConfig({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
  });
}
