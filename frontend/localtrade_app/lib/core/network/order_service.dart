import 'dart:convert';
import '../network/api_service.dart';
import '../network/auth_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _apiService.post(
      '/orders',
      body: orderData,
      headers: {'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data;
    try {
      data = json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Invalid server response'};
    }
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to place order');
    }
  }

  Future<Map<String, dynamic>> getMyOrders({int page = 1, int limit = 20}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _apiService.get('/orders/my-orders?page=$page&limit=$limit', headers: {
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
      throw Exception(data['message'] ?? 'Failed to fetch orders');
    }
  }

  Future<Map<String, dynamic>> getVendorOrders({int page = 1, int limit = 20}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _apiService.get('/orders/vendor-orders?page=$page&limit=$limit', headers: {
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
      throw Exception(data['message'] ?? 'Failed to fetch vendor orders');
    }
  }

  Future<Map<String, dynamic>> getOrder(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _apiService.get('/orders/$id', headers: {
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
      throw Exception(data['message'] ?? 'Failed to fetch order details');
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(String id, String status) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _apiService.patch(
      '/orders/$id/status',
      body: {'status': status},
      headers: {'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data;
    try {
      data = json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Invalid server response'};
    }
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update order status');
    }
  }

  Future<Map<String, dynamic>> cancelOrder(String id, {String? reason, String? feedback}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final body = <String, dynamic>{};
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;
    if (feedback != null && feedback.isNotEmpty) body['feedback'] = feedback;
    final response = await _apiService.patch(
      '/orders/$id/cancel',
      body: body,
      headers: {'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data;
    try {
      data = json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Invalid server response'};
    }
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to cancel order');
    }
  }
}
