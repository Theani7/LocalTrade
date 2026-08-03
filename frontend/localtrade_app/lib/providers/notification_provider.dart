import 'package:flutter/foundation.dart';
import '../core/network/notification_service.dart';
import '../core/utils/cache_manager.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  static const String _cacheKey = 'notifications';

  List<dynamic> _notifications = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;
  bool _disposed = false;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;
  int _serverUnreadCount = -1;

  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get unreadCount => _serverUnreadCount >= 0
      ? _serverUnreadCount
      : _notifications.where((n) => n['isRead'] != true).length;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _safeNotifyListeners();
    try {
      final result = await _notificationService.getNotifications(page: 1, limit: 20);
      if (result['success'] == false) {
        _error = result['message'] ?? 'Failed to load';
        return;
      }
      final data = result['data'] as Map<String, dynamic>?;
      _notifications = (data?['notifications'] as List<dynamic>?) ?? [];
      if (result['unreadCount'] is num) {
        _serverUnreadCount = (result['unreadCount'] as num).toInt();
      }
      final totalPages = result['totalPages'];
      if (totalPages != null) {
        _totalPages = totalPages as int;
        _hasMore = _currentPage < _totalPages;
      } else {
        _hasMore = false;
      }
      await CacheManager.cacheData(_cacheKey, result);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      if (_notifications.isEmpty) {
        final cached = await CacheManager.getCachedData(_cacheKey);
        if (cached != null) {
          final data = cached['data'] as Map<String, dynamic>?;
          _notifications = (data?['notifications'] as List<dynamic>?) ?? [];
          if (cached['unreadCount'] is num) {
            _serverUnreadCount = (cached['unreadCount'] as num).toInt();
          }
          final totalPages = cached['totalPages'];
          if (totalPages != null) {
            _totalPages = totalPages as int;
            _hasMore = _currentPage < _totalPages;
          }
        }
      }
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> loadMoreNotifications() async {
    if (_isFetchingMore || !_hasMore) return;
    _isFetchingMore = true;
    _safeNotifyListeners();
    try {
      _currentPage++;
      final result = await _notificationService.getNotifications(page: _currentPage, limit: 20);
      if (result['success'] == false) {
        _currentPage--;
        return;
      }
      final data = result['data'] as Map<String, dynamic>?;
      final newNotifications = (data?['notifications'] as List<dynamic>?) ?? [];
      _notifications.addAll(newNotifications);
      if (result['unreadCount'] is num) {
        _serverUnreadCount = (result['unreadCount'] as num).toInt();
      }
      final totalPages = result['totalPages'];
      if (totalPages != null) {
        _totalPages = totalPages as int;
        _hasMore = _currentPage < _totalPages;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _currentPage--;
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isFetchingMore = false;
      _safeNotifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _notificationService.markAsRead(id);
      final index = _notifications.indexWhere((n) => n['_id'] == id);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
        if (_serverUnreadCount > 0) _serverUnreadCount--;
        _safeNotifyListeners();
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _safeNotifyListeners();
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
      _serverUnreadCount = 0;
      _safeNotifyListeners();

      await _notificationService.markAllRead();
      await fetchNotifications();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      await fetchNotifications();
    }
  }

  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }
}
