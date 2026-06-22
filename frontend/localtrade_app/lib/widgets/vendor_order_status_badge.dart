import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class VendorOrderStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const VendorOrderStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _config();
    final iconSize = compact ? 10.0 : 12.0;
    final gap = compact ? 3.0 : 4.0;
    final fontSize = compact ? 10.0 : 12.0;
    final hPad = compact ? 6.0 : 8.0;
    final vPad = compact ? 3.0 : 4.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: iconSize, color: config.foreground),
          SizedBox(width: gap),
          Text(
            config.label,
            style: AppTextStyles.badge.copyWith(
              color: config.foreground,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _config() {
    switch (status) {
      case 'Pending':
        return _BadgeConfig(
          background: AppColors.warningLight,
          foreground: AppColors.warningDark,
          icon: Icons.schedule_outlined,
          label: 'Pending',
        );
      case 'Confirmed':
        return _BadgeConfig(
          background: AppColors.blueLight,
          foreground: AppColors.blueDark,
          icon: Icons.check_circle_outline_rounded,
          label: 'Confirmed',
        );
      case 'Delivered':
        return _BadgeConfig(
          background: AppColors.successLight,
          foreground: AppColors.successDark,
          icon: Icons.local_shipping_outlined,
          label: 'Delivered',
        );
      case 'Cancelled':
        return _BadgeConfig(
          background: AppColors.mutedLight,
          foreground: AppColors.muted,
          icon: Icons.close_rounded,
          label: 'Cancelled',
        );
      default:
        return _BadgeConfig(
          background: AppColors.warningLight,
          foreground: AppColors.warningDark,
          icon: Icons.schedule_outlined,
          label: status,
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
