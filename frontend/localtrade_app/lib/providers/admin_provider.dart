import 'package:flutter/material.dart';
import '../core/network/admin_service.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();
  
  Map<String, dynamic>? _analytics;
  List<dynamic> _users = [];
  List<dynamic> _vendors = [];
  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  
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
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _adminService.getSystemAnalytics();
      _analytics = result['data'];
    } catch (e) {
      _error = e.toString();
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
      
      if (refresh) {
        _users = newUsers;
      } else {
        _users.addAll(newUsers);
      }
      
      _hasMoreUsers = _usersPage < (result['totalPages'] ?? 1);
      if (_hasMoreUsers) _usersPage++;
    } catch (e) {
      _error = e.toString();
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

      if (refresh) {
        _vendors = newVendors;
      } else {
        _vendors.addAll(newVendors);
      }

      _hasMoreVendors = _vendorsPage < (result['totalPages'] ?? 1);
      if (_hasMoreVendors) _vendorsPage++;
    } catch (e) {
      _error = e.toString();
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

      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _hasMoreProducts = _productsPage < (result['totalPages'] ?? 1);
      if (_hasMoreProducts) _productsPage++;
    } catch (e) {
      _error = e.toString();
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

      if (refresh) {
        _orders = newOrders;
      } else {
        _orders.addAll(newOrders);
      }

      _hasMoreOrders = _ordersPage < (result['totalPages'] ?? 1);
      if (_hasMoreOrders) _ordersPage++;
    } catch (e) {
      _error = e.toString();
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
    _isLoading = true;
    notifyListeners();
    try {
      await _adminService.deleteProduct(productId);
      await Future.wait([
        fetchProducts(refresh: true),
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
