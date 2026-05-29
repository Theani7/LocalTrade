import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/vendor_provider.dart';
import 'providers/feedback_provider.dart';
import 'providers/review_provider.dart';
import 'core/network/notification_service.dart';
import 'features/auth/login_screen.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/vendor/vendor_dashboard.dart';
import 'features/vendor/vendor_pending_screen.dart';
import 'features/customer/customer_home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: const LocalTradeApp(),
    ),
  );
}

class LocalTradeApp extends StatelessWidget {
  const LocalTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for splash animation (min 2 seconds)
    final splashFuture = Future.delayed(const Duration(seconds: 2));

    // Init notifications
    final notificationFuture = _notificationService.init().then((_) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _notificationService.showLocalNotification(message);
        if (mounted) {
          Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
        }
      });
    }).catchError((e) { debugPrint('Notification init error: $e'); return null; });

    // Validate session
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final authFuture = auth.isAuthenticated ? auth.validateToken() : Future.value(false);

    // Wait for all essential startup tasks
    await Future.wait([splashFuture, notificationFuture, authFuture]);

    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.isAuthenticated) {
      final role = auth.user?['role'];
      final status = auth.user?['vendorApprovalStatus'];

      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else if (role == 'vendor') {
        if (status == 'approved') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VendorDashboard()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VendorPendingScreen()));
        }
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerHomeScreen()));
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.storefront_rounded,
              size: 100,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Community Marketplace 🇳🇵',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
