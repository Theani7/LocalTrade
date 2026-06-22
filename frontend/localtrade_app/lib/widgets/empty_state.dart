import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_animations.dart';

class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onAction,
    this.actionLabel,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _offsetY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _offsetY = Tween(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return _buildContent(context);
    }

    return TickBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _offsetY.value),
            child: _buildContent(context),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.coralLight,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, size: 36, color: AppColors.coralDark),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.onAction != null && widget.actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(widget.actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
