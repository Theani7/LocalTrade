import 'package:flutter/material.dart';
import '../core/network/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  bool _isLoading = false;

  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => n['isRead'] != true).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _notificationService.getNotifications();
      _notifications = result['data']['notifications'];
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _notificationService.markAsRead(id);
      final index = _notifications.indexWhere((n) => n['_id'] == id);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      // 1. Aggressively update local state FIRST for instant UI feedback
      debugPrint('MarkAllAsRead: Updating local state first...');
      _notifications = _notifications.map((n) {
        if (n is Map) {
          final updated = Map<String, dynamic>.from(n);
          updated['isRead'] = true;
          return updated;
        }
        return n;
      }).toList();
      notifyListeners();
      debugPrint('MarkAllAsRead: Local state updated. unreadCount should be 0 now.');

      // 2. Send request to backend
      await _notificationService.markAllRead();
      
      // 3. Re-fetch from backend to ensure we are in sync with the actual server state
      // (This handles cases where the local update might have missed something)
      await fetchNotifications();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      // If backend fails, re-fetch to revert to actual state from server
      await fetchNotifications();
    }
  }
}
