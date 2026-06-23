import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
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

class _SplashScreenState extends State<SplashScreen> {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<RemoteMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
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
            // Use the app logo image to satisfy the test expectation for an Image widget.
            // The logo asset is defined in pubspec.yaml under assets/images/.
            Image.asset(
              'assets/images/logo.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 24),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Community marketplace',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.coral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
