import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_service.dart';
import '../network/auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isWeb = false;
  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  void Function(RemoteMessage message)? onForegroundMessage;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _isWeb = kIsWeb;

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _fcm.getToken();
    if (token != null) {
      await _updateTokenOnBackend(token);
    }

    _fcm.onTokenRefresh.listen(_updateTokenOnBackend);

    if (!_isWeb) {
      await _initLocalNotifications();
    }

    _setupForegroundListener();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Android 13+ needs explicit POST_NOTIFICATIONS permission
    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final channel = AndroidNotificationChannel(
        'localtrade_channel',
        'LocalTrade Notifications',
        description: 'Notifications from LocalTrade marketplace',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFFFF6F52),
      );

      await androidPlugin.createNotificationChannel(channel);
    }
  }

  void _setupForegroundListener() {
    _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        if (!_isWeb) {
          showLocalNotification(message);
        }
        onForegroundMessage?.call(message);
      },
      onError: (e) {
        debugPrint('Foreground FCM error: $e');
      },
    );
  }

  Future<void> _updateTokenOnBackend(String token) async {
    try {
      final authToken = await _authService.getToken();
      if (authToken != null) {
        await _apiService.patch(
          '/auth/update-fcm-token',
          body: {'fcmToken': token},
          headers: {'Authorization': 'Bearer $authToken'},
        );
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  Future<void> showLocalNotification(RemoteMessage message) async {
    if (_isWeb) return;

    final androidDetails = AndroidNotificationDetails(
      'localtrade_channel',
      'LocalTrade Notifications',
      channelDescription: 'Notifications from LocalTrade marketplace',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      color: const Color(0xFFFF6F52),
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFFFF6F52),
      styleInformation: const DefaultStyleInformation(true, true),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'LocalTrade',
      body: message.notification?.body ?? '',
      notificationDetails: details,
    );
  }

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }
    final response = await _apiService.get(
      '/notifications?page=$page&limit=$limit',
      headers: {'Authorization': 'Bearer $token'},
    );

    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return data;
      return {'success': false, 'message': data['message'] ?? 'Failed'};
    } catch (e) {
      return {'success': false, 'message': 'Invalid server response'};
    }
  }

  Future<void> markAsRead(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    await _apiService.patch(
      '/notifications/$id/read',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> markAllRead() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    await _apiService.patch(
      '/notifications/mark-all-read',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (!_isWeb) {
      await _localNotifications.cancelAll();
    }
  }

  void dispose() {
    _foregroundSubscription?.cancel();
  }
}
