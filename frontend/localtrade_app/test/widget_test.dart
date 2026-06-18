// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:localtrade_app/main.dart';
import 'package:localtrade_app/providers/auth_provider.dart';
import 'package:localtrade_app/providers/admin_provider.dart';
import 'package:localtrade_app/providers/product_provider.dart';
import 'package:localtrade_app/providers/cart_provider.dart';
import 'package:localtrade_app/providers/order_provider.dart';
import 'package:localtrade_app/providers/notification_provider.dart';
import 'package:localtrade_app/providers/vendor_provider.dart';
import 'package:localtrade_app/providers/feedback_provider.dart';
import 'package:localtrade_app/providers/review_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';

class FakeFirebaseMessagingPlatform extends FirebaseMessagingPlatform {
  @override
  FirebaseMessagingPlatform delegateFor({required FirebaseApp app}) {
    return this;
  }

  @override
  FirebaseMessagingPlatform setInitialValues({
    bool? isAutoInitEnabled,
  }) {
    return this;
  }

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    return const NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      authorizationStatus: AuthorizationStatus.authorized,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      criticalAlert: AppleNotificationSetting.disabled,
      showPreviews: AppleShowPreviewSetting.always,
      sound: AppleNotificationSetting.enabled,
      timeSensitive: AppleNotificationSetting.disabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
    );
  }

  @override
  Future<String?> getToken({
    String? vapidKey,
  }) async {
    return 'fake-token';
  }

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseMessagingPlatform.instance = FakeFirebaseMessagingPlatform();
  });

  testWidgets('App splash screen renders smoke test', (WidgetTester tester) async {
    // Build our app under MultiProvider to ensure all state providers are present.
    await tester.pumpWidget(
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

    // Verify that the splash screen shows the app logo and branding.
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('LocalTrade'), findsOneWidget);

    // Advance the virtual clock by 3 seconds to let the splash timer complete
    // and avoid the pending timer assertion failure.
    await tester.pump(const Duration(seconds: 3));
  });
}
