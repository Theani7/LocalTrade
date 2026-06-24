import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_animations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../admin/admin_shell.dart';
import '../vendor/vendor_dashboard.dart';
import '../vendor/vendor_pending_screen.dart';
import '../customer/customer_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _lineCtrl;
  late final Animation<double> _lineWidth;

  late final AnimationController _nameCtrl;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;

  late final AnimationController _taglineCtrl;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

  late final AnimationController _dotCtrl;
  late final Animation<double> _dotOpacity;
  late final Animation<double> _dotScale;

  @override
  void initState() {
    super.initState();

    // Accent line expands from center
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _lineWidth = Tween(begin: 0.0, end: 48.0).animate(
      CurvedAnimation(parent: _lineCtrl, curve: AppCurves.standard),
    );

    // App name fades + slides up
    _nameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _nameOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _nameCtrl, curve: AppCurves.standard),
    );
    _nameSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _nameCtrl, curve: AppCurves.standard),
    );

    // Tagline fades + slides up
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineCtrl, curve: AppCurves.standard),
    );
    _taglineSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _taglineCtrl, curve: AppCurves.standard),
    );

    // Loading dots pulse
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _dotOpacity = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotCtrl,
        curve: const Interval(0.0, 0.5, curve: AppCurves.standard),
      ),
    );
    _dotScale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _startAnimations();
    _initializeApp();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _lineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _nameCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _taglineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _dotCtrl.repeat(reverse: true);
  }

  Future<void> _initializeApp() async {
    final splashFuture = Future.delayed(const Duration(seconds: 2));

    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.ready;

    final authFuture = auth.isAuthenticated ? auth.validateToken() : Future.value(false);

    await Future.wait([splashFuture, authFuture]);

    // Pre-fetch notifications if authenticated so badge count is ready
    if (auth.isAuthenticated && mounted) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    }

    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.isAuthenticated) {
      final role = auth.user?['role'];
      final status = auth.user?['vendorApprovalStatus'];

      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminShell()));
      } else if (role == 'vendor') {
        if (status == 'approved') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VendorDashboard()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VendorPendingScreen()));
        }
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerShell()));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerShell()));
    }
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Accent line expands from center
            AnimatedBuilder(
              animation: _lineCtrl,
              builder: (context, _) {
                return Container(
                  width: _lineWidth.value,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            // App name
            FadeTransition(
              opacity: _nameOpacity,
              child: SlideTransition(
                position: _nameSlide,
                child: Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            FadeTransition(
              opacity: _taglineOpacity,
              child: SlideTransition(
                position: _taglineSlide,
                child: Text(
                  'Your local community marketplace',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 56),
            // Pulsing loading dots
            FadeTransition(
              opacity: _dotOpacity,
              child: ScaleTransition(
                scale: _dotScale,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                  )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
