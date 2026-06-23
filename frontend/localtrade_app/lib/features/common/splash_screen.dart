import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_animations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/network/notification_service.dart';
import '../admin/admin_shell.dart';
import '../vendor/vendor_dashboard.dart';
import '../vendor/vendor_pending_screen.dart';
import '../customer/customer_shell.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<RemoteMessage>? _messageSubscription;

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

    final notificationFuture = _notificationService.init().then((_) {
      _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _notificationService.showLocalNotification(message);
        if (mounted) {
          Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
        }
      });
    }).catchError((e) {
      debugPrint('Notification init error: $e');
      return null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('Splash: waiting for auth.ready...');
    await auth.ready;
    debugPrint('Splash: auth.ready done. isAuthenticated=${auth.isAuthenticated}, userRole=${auth.user?["role"]}, userId=${auth.user?["_id"]}');

    final authFuture = auth.isAuthenticated ? auth.validateToken() : Future.value(false);
    debugPrint('Splash: calling validateToken=${auth.isAuthenticated}');

    await Future.wait([splashFuture, notificationFuture, authFuture]);
    debugPrint('Splash: all futures done. isAuthenticated=${auth.isAuthenticated}, userRole=${auth.user?["role"]}, userId=${auth.user?["_id"]}');

    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    debugPrint('Splash _navigate: isAuthenticated=${auth.isAuthenticated}, role=${auth.user?["role"]}, keys=${auth.user?.keys.toList()}');

    if (auth.isAuthenticated) {
      final role = auth.user?['role'];
      final status = auth.user?['vendorApprovalStatus'];
      debugPrint('Splash routing: role=$role, status=$status, user=${auth.user != null}');

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
    _messageSubscription?.cancel();
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
