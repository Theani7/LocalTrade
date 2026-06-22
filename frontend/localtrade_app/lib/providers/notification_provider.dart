import 'package:flutter/foundation.dart';
import '../core/network/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => n['isRead'] != true).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _notificationService.getNotifications();
      _notifications = result['data']['notifications'];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
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
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      _notifications = _notifications.map((n) {
        if (n is Map) {
          final updated = Map<String, dynamic>.from(n);
          updated['isRead'] = true;
          return updated;
        }
        return n;
      }).toList();
      notifyListeners();

      await _notificationService.markAllRead();
      await fetchNotifications();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      await fetchNotifications();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
