import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_animations.dart';

enum BadgeStatus { pending, confirmed, delivered, rejected }

class StatusBadge extends StatefulWidget {
  final BadgeStatus status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _scale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _config();

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      return _buildBadge(config);
    }

    return TickBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: _buildBadge(config),
          ),
        );
      },
    );
  }

  Widget _buildBadge(_BadgeConfig config) {
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
            widget.customLabel ?? config.label,
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
    switch (widget.status) {
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
          background: AppColors.mutedLight,
          foreground: AppColors.muted,
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
