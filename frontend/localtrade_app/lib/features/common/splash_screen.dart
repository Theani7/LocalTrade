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
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final AnimationController _textCtrl;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final AnimationController _subtitleCtrl;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;
  late final AnimationController _spinnerCtrl;
  late final Animation<double> _spinnerOpacity;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: AppCurves.standard),
    );
    _logoScale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: AppCurves.standard),
    );
    _textSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _textCtrl, curve: AppCurves.standard),
    );

    _subtitleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _subtitleOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleCtrl, curve: AppCurves.standard),
    );
    _subtitleSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _subtitleCtrl, curve: AppCurves.standard),
    );

    _spinnerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _spinnerOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _spinnerCtrl, curve: AppCurves.standard),
    );

    _startAnimations();
    _initializeApp();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _subtitleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _spinnerCtrl.forward();
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
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _subtitleCtrl.dispose();
    _spinnerCtrl.dispose();
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
            // Logo with fade + elastic scale
            FadeTransition(
              opacity: _logoOpacity,
              child: ScaleTransition(
                scale: _logoScale,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 140,
                  height: 140,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // App name with fade + slide up
            FadeTransition(
              opacity: _textOpacity,
              child: SlideTransition(
                position: _textSlide,
                child: Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle with fade + slide up
            FadeTransition(
              opacity: _subtitleOpacity,
              child: SlideTransition(
                position: _subtitleSlide,
                child: const Text(
                  'Community marketplace',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Spinner with fade in
            FadeTransition(
              opacity: _spinnerOpacity,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.coral,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
