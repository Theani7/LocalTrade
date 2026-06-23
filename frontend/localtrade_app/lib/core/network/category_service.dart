import 'dart:convert';
import '../network/api_service.dart';
import '../network/auth_service.dart';

class CategoryService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getActiveCategories() async {
    final response = await _apiService.get('/categories');
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['data']['categories']);
    }
    throw Exception(data['message'] ?? 'Failed to fetch categories');
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final token = await _authService.getToken();
    final response = await _apiService.get('/categories/admin', headers: {
      'Authorization': 'Bearer $token',
    });
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['data']['categories']);
    }
    throw Exception(data['message'] ?? 'Failed to fetch categories');
  }

  Future<Map<String, dynamic>> createCategory(String name, {String icon = 'category', int sortOrder = 0}) async {
    final token = await _authService.getToken();
    final response = await _apiService.post('/categories', body: {
      'name': name,
      'icon': icon,
      'sortOrder': sortOrder,
    }, headers: {
      'Authorization': 'Bearer $token',
    });
    final data = json.decode(response.body);
    if (response.statusCode == 201) {
      return data['data']['category'];
    }
    throw Exception(data['message'] ?? 'Failed to create category');
  }

  Future<Map<String, dynamic>> updateCategory(String id, {String? name, String? icon, int? sortOrder, bool? isActive}) async {
    final token = await _authService.getToken();
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (icon != null) body['icon'] = icon;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    if (isActive != null) body['isActive'] = isActive;
    final response = await _apiService.patch('/categories/$id', body: body, headers: {
      'Authorization': 'Bearer $token',
    });
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data['data']['category'];
    }
    throw Exception(data['message'] ?? 'Failed to update category');
  }

  Future<void> deleteCategory(String id) async {
    final token = await _authService.getToken();
    final response = await _apiService.delete('/categories/$id', headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode != 204) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete category');
    }
  }
}
