import 'package:flutter/foundation.dart';
import '../core/network/order_service.dart';
import '../core/utils/cache_manager.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  static const String _myOrdersCacheKey = 'my_orders';
  static const String _vendorOrdersCacheKey = 'vendor_orders';

  List<dynamic> _orders = [];
  List<dynamic> _vendorOrders = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalResults = 0;
  bool _hasMore = false;

  int _myCurrentPage = 1;
  int _myTotalPages = 1;
  int _myTotalResults = 0;
  bool _myHasMore = false;

  List<dynamic> get orders => _orders;
  List<dynamic> get vendorOrders => _vendorOrders;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get myHasMore => _myHasMore;
  int get totalResults => _totalResults;
  int get myTotalResults => _myTotalResults;

  Future<void> fetchMyOrders() async {
    _setLoading(true);
    _error = null;
    _myCurrentPage = 1;
    try {
      final result = await _orderService.getMyOrders(page: 1, limit: 20);
      _orders = result['data']['orders'];
      if (result['totalPages'] != null) {
        _myTotalPages = result['totalPages'];
        _myTotalResults = result['totalResults'] ?? _orders.length;
        _myHasMore = _myCurrentPage < _myTotalPages;
      } else {
        _myHasMore = false;
      }
      await CacheManager.cacheData(_myOrdersCacheKey, result);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      if (_orders.isEmpty) {
        final cached = await CacheManager.getCachedData(_myOrdersCacheKey);
        if (cached != null) {
          _orders = List<dynamic>.from(cached['data']['orders'] ?? []);
          _myTotalPages = cached['totalPages'] ?? 1;
          _myTotalResults = cached['totalResults'] ?? _orders.length;
          _myHasMore = _myCurrentPage < _myTotalPages;
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreMyOrders() async {
    if (_isFetchingMore || !_myHasMore) return;
    _isFetchingMore = true;
    notifyListeners();
    try {
      _myCurrentPage++;
      final result = await _orderService.getMyOrders(page: _myCurrentPage, limit: 20);
      final newOrders = result['data']['orders'] as List<dynamic>;
      _orders.addAll(newOrders);
      if (result['totalPages'] != null) {
        _myTotalPages = result['totalPages'];
        _myHasMore = _myCurrentPage < _myTotalPages;
      } else {
        _myHasMore = false;
      }
    } catch (e) {
      _myCurrentPage--;
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchVendorOrders() async {
    _setLoading(true);
    _error = null;
    _currentPage = 1;
    try {
      final result = await _orderService.getVendorOrders(page: 1, limit: 20);
      _vendorOrders = result['data']['orders'];
      if (result['totalPages'] != null) {
        _totalPages = result['totalPages'];
        _totalResults = result['totalResults'] ?? _vendorOrders.length;
        _hasMore = _currentPage < _totalPages;
      } else {
        _hasMore = false;
      }
      await CacheManager.cacheData(_vendorOrdersCacheKey, result);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      if (_vendorOrders.isEmpty) {
        final cached = await CacheManager.getCachedData(_vendorOrdersCacheKey);
        if (cached != null) {
          _vendorOrders = List<dynamic>.from(cached['data']['orders'] ?? []);
          _totalPages = cached['totalPages'] ?? 1;
          _totalResults = cached['totalResults'] ?? _vendorOrders.length;
          _hasMore = _currentPage < _totalPages;
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreVendorOrders() async {
    if (_isFetchingMore || !_hasMore) return;
    _isFetchingMore = true;
    notifyListeners();
    try {
      _currentPage++;
      final result = await _orderService.getVendorOrders(page: _currentPage, limit: 20);
      final newOrders = result['data']['orders'] as List<dynamic>;
      _vendorOrders.addAll(newOrders);
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

  Future<bool> placeOrder(Map<String, dynamic> orderData) async {
    _setLoading(true);
    _error = null;
    try {
      await _orderService.placeOrder(orderData);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateOrderStatus(String id, String status) async {
    _setLoading(true);
    _error = null;
    try {
      await _orderService.updateOrderStatus(id, status);
      await fetchVendorOrders();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelOrder(String id, {String? reason, String? feedback}) async {
    _setLoading(true);
    _error = null;
    try {
      await _orderService.cancelOrder(id, reason: reason, feedback: feedback);
      await fetchMyOrders();
      await fetchVendorOrders();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
