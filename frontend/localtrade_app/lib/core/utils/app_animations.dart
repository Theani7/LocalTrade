import 'package:flutter/material.dart';

/// Returns true if the user has enabled "reduce motion" in accessibility settings.
bool shouldReduceMotion(BuildContext context) {
  return MediaQuery.of(context).disableAnimations;
}

/// Duration constants for the animation system.
class AppDurations {
  AppDurations._();
  static const micro = Duration(milliseconds: 200);
  static const page = Duration(milliseconds: 280);
  static const feedback = Duration(milliseconds: 350);
  static const celebrate = Duration(milliseconds: 400);
}

/// Curves used throughout the app.
class AppCurves {
  AppCurves._();
  static const standard = Curves.easeInOut;
  static const elastic = Curves.elasticOut;
  static const decelerate = Curves.easeOut;
}

/// A page route that slides from the right and fades in simultaneously.
class SlideFadePageRoute<T> extends PageRouteBuilder<T> {
  SlideFadePageRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: AppDurations.page,
          reverseTransitionDuration: AppDurations.page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final reduceMotion = MediaQuery.of(context).disableAnimations;
            if (reduceMotion) return child;

            final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: AppCurves.standard));
            final fadeTween = Tween(begin: 0.0, end: 1.0);

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Wraps a child in staggered fade+translate animation based on [index].
class StaggeredListItem extends StatelessWidget {
  final int index;
  final int totalCount;
  final Widget child;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.totalCount,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;

    final delay = (index * 0.05).clamp(0.0, 0.4);
    final duration = AppDurations.feedback;

    return TweenAnimationWidget(
      delay: delay,
      duration: duration,
      builder: (context, anim) {
        return Opacity(
          opacity: anim,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - anim)),
            child: child,
          ),
        );
      },
    );
  }
}

/// A generic tween animation widget that plays once on build.
class TweenAnimationWidget extends StatefulWidget {
  final double delay;
  final Duration duration;
  final Widget Function(BuildContext context, double value) builder;

  const TweenAnimationWidget({
    super.key,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 350),
    required this.builder,
  });

  @override
  State<TweenAnimationWidget> createState() => _TweenAnimationWidgetState();
}

class _TweenAnimationWidgetState extends State<TweenAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: AppCurves.standard);

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).round()), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TickBuilder(
      listenable: _ctrl,
      builder: (context, _) => widget.builder(context, _anim.value),
    );
  }
}

/// Wraps a widget with a fade+scale entrance animation.
class FadeScaleIn extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FadeScaleIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<FadeScaleIn> createState() => _FadeScaleInState();
}

class _FadeScaleInState extends State<FadeScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppCurves.standard),
    );
    _scale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppCurves.elastic),
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
    return TickBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(scale: _scale.value, child: widget.child),
        );
      },
    );
  }
}

/// Wraps a widget with a fade+translateY entrance animation.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double translateY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.translateY = 20,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppCurves.standard),
    );
    _offset = Tween(begin: widget.translateY, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppCurves.standard),
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
    return TickBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _offset.value),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// TickBuilder - a simple AnimatedWidget that rebuilds on each animation tick.
/// Named to avoid conflict with Flutter's built-in AnimatedBuilder.
class TickBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const TickBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
