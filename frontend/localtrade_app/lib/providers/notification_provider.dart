import 'package:flutter/foundation.dart';
import '../core/network/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;

  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get unreadCount => _notifications.where((n) => n['isRead'] != true).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();
    try {
      final result = await _notificationService.getNotifications(page: 1, limit: 20);
      _notifications = result['data']['notifications'];
      if (result['totalPages'] != null) {
        _totalPages = result['totalPages'];
        _hasMore = _currentPage < _totalPages;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreNotifications() async {
    if (_isFetchingMore || !_hasMore) return;
    _isFetchingMore = true;
    notifyListeners();
    try {
      _currentPage++;
      final result = await _notificationService.getNotifications(page: _currentPage, limit: 20);
      final newNotifications = result['data']['notifications'] as List<dynamic>;
      _notifications.addAll(newNotifications);
      if (result['totalPages'] != null) {
        _totalPages = result['totalPages'];
        _hasMore = _currentPage < _totalPages;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _currentPage--;
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isFetchingMore = false;
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
