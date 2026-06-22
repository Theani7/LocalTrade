import 'package:flutter/material.dart';
import '../core/network/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<dynamic> _orders = [];
  List<dynamic> _vendorOrders = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get orders => _orders;
  List<dynamic> get vendorOrders => _vendorOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyOrders() async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _orderService.getMyOrders();
      _orders = result['data']['orders'];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchVendorOrders() async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _orderService.getVendorOrders();
      _vendorOrders = result['data']['orders'];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _setLoading(false);
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
