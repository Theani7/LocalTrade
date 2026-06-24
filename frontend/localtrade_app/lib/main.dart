import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/network/notification_service.dart';
import 'core/widgets/floating_notification.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/vendor_provider.dart';
import 'providers/feedback_provider.dart';
import 'providers/review_provider.dart';
import 'providers/category_provider.dart';
import 'features/common/splash_screen.dart';
import 'features/customer/order_tracking_screen.dart';
import 'features/customer/notification_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize notification service (singleton) — sets up channel + permissions
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Notification service init error: $e');
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
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: Builder(
        builder: (context) {
          final cart = Provider.of<CartProvider>(context, listen: false);
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final notificationProvider =
              Provider.of<NotificationProvider>(context, listen: false);
          auth.onLogoutCallback = cart.onLogout;

          // Set up foreground FCM handler — shows floating overlay + refreshes provider
          NotificationService().onForegroundMessage = (message) {
            final ctx = navigatorKey.currentContext;
            if (ctx == null) return;

            // Refresh notification list
            notificationProvider.fetchNotifications();

            // Show in-app floating overlay
            final title = message.notification?.title ?? 'LocalTrade';
            final body = message.notification?.body ?? '';
            final type = message.data['type'] ?? 'System';

            showFloatingNotification(
              ctx,
              title: title,
              body: body,
              type: type,
              onTap: () {
                final orderId = message.data['orderId'];
                final nav = navigatorKey.currentState;
                if (nav == null) return;

                if (orderId != null) {
                  nav.push(MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(orderId: orderId),
                  ));
                } else {
                  nav.push(MaterialPageRoute(
                    builder: (_) => const NotificationScreen(),
                  ));
                }
              },
            );
          };

          return const LocalTradeApp();
        },
      ),
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
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}
