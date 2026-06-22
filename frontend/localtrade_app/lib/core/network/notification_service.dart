import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../network/api_service.dart';
import '../network/auth_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isWeb = false;

  Future<void> init() async {
    _isWeb = kIsWeb;

    // 1) Request Permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2) Get Token and update backend
    String? token = await _fcm.getToken();
    if (token != null) {
      await _updateTokenOnBackend(token);
    }

    // 3) Listen for token refresh
    _fcm.onTokenRefresh.listen(_updateTokenOnBackend);

    // 4) Initialize Local Notifications (skip on web — not supported)
    if (!_isWeb) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
      );
    }
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

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'LocalTrade_channel',
      'LocalTrade Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }

  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    final token = await _authService.getToken();
    if (token == null) return {'success': false, 'message': 'Not authenticated'};
    final response = await _apiService.get('/notifications?page=$page&limit=$limit', headers: {
      'Authorization': 'Bearer $token',
    });

    final Map<String, dynamic> data;
    try {
      data = json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Invalid server response'};
    }
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch notifications');
    }
  }

  Future<void> markAsRead(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    await _apiService.patch('/notifications/$id/read', headers: {
      'Authorization': 'Bearer $token',
    });
  }

  Future<void> markAllRead() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    await _apiService.patch('/notifications/mark-all-read', headers: {
      'Authorization': 'Bearer $token',
    });
    if (!_isWeb) {
      await _localNotifications.cancelAll();
    }
  }
}
