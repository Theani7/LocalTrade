import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class FloatingNotification extends StatefulWidget {
  final String title;
  final String? body;
  final String type;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const FloatingNotification({
    super.key,
    required this.title,
    this.body,
    this.type = 'System',
    this.onTap,
    this.onDismissed,
  });

  @override
  State<FloatingNotification> createState() => _FloatingNotificationState();
}

class _FloatingNotificationState extends State<FloatingNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      widget.onDismissed?.call();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _typeBorderColor() {
    switch (widget.type) {
      case 'Order':
        return AppColors.coral;
      case 'Account':
        return AppColors.success;
      case 'Promotional':
        return AppColors.muted;
      case 'System':
      default:
        return AppColors.blue;
    }
  }

  IconData _typeIcon() {
    switch (widget.type) {
      case 'Order':
        return Icons.shopping_bag_outlined;
      case 'Account':
        return Icons.person_outline;
      case 'Promotional':
        return Icons.local_offer_outlined;
      case 'System':
      default:
        return Icons.info_outline;
    }
  }

  Color _typeIconBg() {
    switch (widget.type) {
      case 'Order':
        return AppColors.coralLight;
      case 'Account':
        return AppColors.successLight;
      case 'Promotional':
        return AppColors.mutedLight;
      case 'System':
      default:
        return AppColors.blueLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 0),
          child: GestureDetector(
            onTap: () {
              widget.onTap?.call();
              _dismiss();
            },
            onVerticalDragEnd: (_) => _dismiss(),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(
                    color: _typeBorderColor(),
                    width: 3,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Type icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _typeIconBg(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _typeIcon(),
                      size: 18,
                      color: _typeBorderColor(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.body != null && widget.body!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.body!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.muted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close button
                  GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.mutedLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a floating notification overlay on top of the current screen.
/// Returns an OverlayEntry that can be removed manually if needed.
OverlayEntry showFloatingNotification(
  BuildContext context, {
  required String title,
  String? body,
  String type = 'System',
  VoidCallback? onTap,
}) {
  OverlayEntry? entry;

  entry = OverlayEntry(
    builder: (ctx) => FloatingNotification(
      title: title,
      body: body,
      type: type,
      onTap: onTap,
      onDismissed: () {
        entry?.remove();
      },
    ),
  );

  Overlay.of(context).insert(entry);

  // Auto-remove after 5 seconds as fallback
  Future.delayed(const Duration(seconds: 5), () {
    if (entry?.mounted == true) {
      entry?.remove();
    }
  });

  return entry;
}
