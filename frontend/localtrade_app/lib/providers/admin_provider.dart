import 'package:flutter/material.dart';
import '../core/network/admin_service.dart';
import '../core/utils/cache_manager.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();
  
  static const String _analyticsCacheKey = 'admin_analytics';
  static const String _usersCacheKey = 'admin_users';
  static const String _vendorsCacheKey = 'admin_vendors';
  static const String _productsCacheKey = 'admin_products';
  static const String _ordersCacheKey = 'admin_orders';

  Map<String, dynamic>? _analytics;
  List<dynamic> _users = [];
  List<dynamic> _vendors = [];
  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _vendorStats;
  Map<String, dynamic>? _productStats;
  Map<String, dynamic>? _orderStats;
  
  bool _isLoading = false;
  String? _error;

  // Pagination State
  int _usersPage = 1;
  int _vendorsPage = 1;
  int _productsPage = 1;
  int _ordersPage = 1;
  
  bool _hasMoreUsers = true;
  bool _hasMoreVendors = true;
  bool _hasMoreProducts = true;
  bool _hasMoreOrders = true;

  Map<String, dynamic>? get analytics => _analytics;
  List<dynamic> get users => _users;
  List<dynamic> get vendors => _vendors;
  List<dynamic> get products => _products;
  List<dynamic> get orders => _orders;
  Map<String, dynamic>? get userStats => _userStats;
  Map<String, dynamic>? get vendorStats => _vendorStats;
  Map<String, dynamic>? get productStats => _productStats;
  Map<String, dynamic>? get orderStats => _orderStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _adminService.getSystemAnalytics();
      _analytics = result['data'];
      await CacheManager.cacheData(_analyticsCacheKey, result);
    } catch (e) {
      _error = e.toString();
      if (_analytics == null) {
        final cached = await CacheManager.getCachedData(_analyticsCacheKey);
        if (cached != null) {
          _analytics = cached['data'];
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUsers({String? search, String? role, bool refresh = true}) async {
    if (refresh) {
      _usersPage = 1;
      _users = [];
      _hasMoreUsers = true;
      _isLoading = true;
    } else {
      if (!_hasMoreUsers || _isLoading) return;
      _isLoading = true;
    }
    
    _error = null;
    notifyListeners();
    
    try {
      final result = await _adminService.getAllUsers(search: search, role: role, page: _usersPage);
      final List<dynamic> newUsers = result['data']['users'];
      _userStats = result['data']['stats'];
      
      if (refresh) {
        _users = newUsers;
      } else {
        _users.addAll(newUsers);
      }
      
      _hasMoreUsers = _usersPage < (result['totalPages'] ?? 1);
      if (_hasMoreUsers) _usersPage++;

      if (refresh) {
        await CacheManager.cacheData(_usersCacheKey, result);
      }
    } catch (e) {
      _error = e.toString();
      if (_users.isEmpty) {
        final cached = await CacheManager.getCachedData(_usersCacheKey);
        if (cached != null) {
          _users = List<dynamic>.from(cached['data']['users'] ?? []);
          _userStats = cached['data']['stats'];
          _hasMoreUsers = false;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchVendors({String? search, String? status, bool refresh = true}) async {
    if (refresh) {
      _vendorsPage = 1;
      _vendors = [];
      _hasMoreVendors = true;
      _isLoading = true;
    } else {
      if (!_hasMoreVendors || _isLoading) return;
      _isLoading = true;
    }

    _error = null;
    notifyListeners();
    
    try {
      final result = await _adminService.getAllVendors(search: search, status: status, page: _vendorsPage);
      final List<dynamic> newVendors = result['data']['vendors'];
      _vendorStats = result['data']['stats'];

      if (refresh) {
        _vendors = newVendors;
      } else {
        _vendors.addAll(newVendors);
      }

      _hasMoreVendors = _vendorsPage < (result['totalPages'] ?? 1);
      if (_hasMoreVendors) _vendorsPage++;

      if (refresh) {
        await CacheManager.cacheData(_vendorsCacheKey, result);
      }
    } catch (e) {
      _error = e.toString();
      if (_vendors.isEmpty) {
        final cached = await CacheManager.getCachedData(_vendorsCacheKey);
        if (cached != null) {
          _vendors = List<dynamic>.from(cached['data']['vendors'] ?? []);
          _vendorStats = cached['data']['stats'];
          _hasMoreVendors = false;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProducts({String? search, String? category, bool refresh = true}) async {
    if (refresh) {
      _productsPage = 1;
      _products = [];
      _hasMoreProducts = true;
      _isLoading = true;
    } else {
      if (!_hasMoreProducts || _isLoading) return;
      _isLoading = true;
    }

    _error = null;
    notifyListeners();
    
    try {
      final result = await _adminService.getAllProducts(search: search, category: category, page: _productsPage);
      final List<dynamic> newProducts = result['data']['products'];
      _productStats = result['data']['stats'];

      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _hasMoreProducts = _productsPage < (result['totalPages'] ?? 1);
      if (_hasMoreProducts) _productsPage++;

      if (refresh) {
        await CacheManager.cacheData(_productsCacheKey, result);
      }
    } catch (e) {
      _error = e.toString();
      if (_products.isEmpty) {
        final cached = await CacheManager.getCachedData(_productsCacheKey);
        if (cached != null) {
          _products = List<dynamic>.from(cached['data']['products'] ?? []);
          _productStats = cached['data']['stats'];
          _hasMoreProducts = false;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrders({String? search, String? status, bool refresh = true}) async {
    if (refresh) {
      _ordersPage = 1;
      _orders = [];
      _hasMoreOrders = true;
      _isLoading = true;
    } else {
      if (!_hasMoreOrders || _isLoading) return;
      _isLoading = true;
    }

    _error = null;
    notifyListeners();
    
    try {
      final result = await _adminService.getAllOrders(search: search, status: status, page: _ordersPage);
      final List<dynamic> newOrders = result['data']['orders'];
      _orderStats = result['data']['stats'];

      if (refresh) {
        _orders = newOrders;
      } else {
        _orders.addAll(newOrders);
      }

      _hasMoreOrders = _ordersPage < (result['totalPages'] ?? 1);
      if (_hasMoreOrders) _ordersPage++;

      if (refresh) {
        await CacheManager.cacheData(_ordersCacheKey, result);
      }
    } catch (e) {
      _error = e.toString();
      if (_orders.isEmpty) {
        final cached = await CacheManager.getCachedData(_ordersCacheKey);
        if (cached != null) {
          _orders = List<dynamic>.from(cached['data']['orders'] ?? []);
          _orderStats = cached['data']['stats'];
          _hasMoreOrders = false;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateVendorStatus(String vendorId, String status) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.updateVendorStatus(vendorId, status);
      await Future.wait([
        fetchVendors(refresh: true),
        fetchAnalytics(),
      ]);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleUserStatus(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.toggleUserStatus(userId);
      await Future.wait([
        fetchUsers(refresh: true),
        fetchAnalytics(),
      ]);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(String productId) async {
    _products.removeWhere((p) => p['_id'] == productId);
    notifyListeners();
    try {
      await _adminService.deleteProduct(productId);
      await fetchAnalytics();
      return true;
    } catch (e) {
      _error = e.toString();
      await fetchProducts(refresh: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> exportAnalytics({String type = 'overview'}) async {
    try {
      return await _adminService.exportAnalytics(type: type);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
