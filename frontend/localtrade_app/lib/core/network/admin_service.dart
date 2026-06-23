import 'dart:convert';
import '../network/api_service.dart';
import '../network/auth_service.dart';

class AdminService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getSystemAnalytics() async {
    final token = await _authService.getToken();
    final response = await _apiService.get('/admin/analytics', headers: {
      'Authorization': 'Bearer $token',
    });

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch analytics');
    }
  }

  Future<Map<String, dynamic>> getAllUsers({String? search, String? role, int page = 1}) async {
    final token = await _authService.getToken();
    String query = '?page=$page';
    if (search != null && search.isNotEmpty) query += '&search=$search';
    if (role != null && role != 'All') query += '&role=$role';

    final response = await _apiService.get('/admin/users$query', headers: {
      'Authorization': 'Bearer $token',
    });

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch users');
    }
  }

  Future<Map<String, dynamic>> getAllVendors({String? search, String? status, int page = 1}) async {
    final token = await _authService.getToken();
    String query = '?page=$page';
    if (search != null && search.isNotEmpty) query += '&search=$search';
    if (status != null && status != 'All') query += '&status=$status';

    final response = await _apiService.get('/admin/vendors$query', headers: {
      'Authorization': 'Bearer $token',
    });

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch vendors');
    }
  }

  Future<Map<String, dynamic>> getAllProducts({String? search, String? category, int page = 1}) async {
    final token = await _authService.getToken();
    String query = '?page=$page';
    if (search != null && search.isNotEmpty) query += '&search=$search';
    if (category != null && category != 'All') query += '&category=$category';

    final response = await _apiService.get('/admin/products$query', headers: {
      'Authorization': 'Bearer $token',
    });

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch products');
    }
  }

  Future<Map<String, dynamic>> getAllOrders({String? search, String? status, int page = 1}) async {
    final token = await _authService.getToken();
    String query = '?page=$page';
    if (search != null && search.isNotEmpty) query += '&search=$search';
    if (status != null && status != 'All') query += '&status=$status';

    final response = await _apiService.get('/admin/orders$query', headers: {
      'Authorization': 'Bearer $token',
    });

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch orders');
    }
  }

  Future<Map<String, dynamic>> updateVendorStatus(String vendorId, String status) async {
    final token = await _authService.getToken();
    final response = await _apiService.patch(
      '/admin/vendors/$vendorId/status',
      body: {'status': status},
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update vendor status');
    }
  }

  Future<Map<String, dynamic>> toggleUserStatus(String userId) async {
    final token = await _authService.getToken();
    final response = await _apiService.patch(
      '/admin/users/$userId/toggle-status',
      body: {},
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update user status');
    }
  }

  Future<void> deleteProduct(String productId) async {
    final token = await _authService.getToken();
    final response = await _apiService.delete(
      '/admin/products/$productId',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete product');
    }
  }

  Future<String> exportAnalytics({String type = 'overview'}) async {
    final token = await _authService.getToken();
    final response = await _apiService.get(
      '/admin/analytics/export?type=$type',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to export data');
    }
  }
}
