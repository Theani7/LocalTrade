import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Shows a small circular widget that flies from [sourceContext] to
/// [cartIconKey] and then fades out. Call [show] to trigger.
class CartFlyAnimation {
  static OverlayEntry? _entry;

  /// Triggers a fly-to-cart animation.
  ///
  /// [sourceContext] — the widget to fly from (e.g. the add-to-cart button).
  /// [cartIconKey] — GlobalKey attached to the cart icon in the bottom nav.
  static void show({
    required BuildContext sourceContext,
    required GlobalKey cartIconKey,
  }) {
    dismiss();

    final sourceBox =
        sourceContext.findRenderObject() as RenderBox?;
    final cartBox =
        cartIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (sourceBox == null || cartBox == null) return;

    final sourcePos = sourceBox.localToGlobal(Offset.zero);
    final cartPos = cartBox.localToGlobal(Offset.zero);

    final overlay = Overlay.of(sourceContext);
    final navigator = Navigator.of(sourceContext);
    final renderBox = navigator.context.findRenderObject() as RenderBox;
    final overlaySize = renderBox.size;

    const flySize = 36.0;

    final startX = sourcePos.dx + sourceBox.size.width / 2 - flySize / 2;
    final startY = sourcePos.dy + sourceBox.size.height / 2 - flySize / 2;
    final endX = cartPos.dx + cartBox.size.width / 2 - flySize / 2;
    final endY = cartPos.dy + cartBox.size.height / 2 - flySize / 2;

    _entry = OverlayEntry(
      builder: (context) => _FlyingWidget(
        startX: startX,
        startY: startY,
        endX: endX,
        endY: endY,
        overlaySize: overlaySize,
        onDismiss: dismiss,
      ),
    );

    overlay.insert(_entry!);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _FlyingWidget extends StatefulWidget {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Size overlaySize;
  final VoidCallback onDismiss;

  const _FlyingWidget({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.overlaySize,
    required this.onDismiss,
  });

  @override
  State<_FlyingWidget> createState() => _FlyingWidgetState();
}

class _FlyingWidgetState extends State<_FlyingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _xAnim;
  late final Animation<double> _yAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final curve = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOutCubic,
    );

    _xAnim = Tween<double>(
      begin: widget.startX,
      end: widget.endX,
    ).animate(curve);

    _yAnim = Tween<double>(
      begin: widget.startY,
      end: widget.endY,
    ).animate(curve);

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.3), weight: 70),
    ]).animate(curve);

    _fadeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(curve);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final arcOffset =
            -80.0 * (1.0 - (2.0 * t - 1.0) * (2.0 * t - 1.0));

        return Positioned(
          left: _xAnim.value,
          top: _yAnim.value + arcOffset,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Opacity(
              opacity: _fadeAnim.value,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33FF6F52),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  size: 18,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A simple AnimatedWidget that rebuilds on each animation tick.
class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
