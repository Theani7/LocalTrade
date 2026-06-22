import 'dart:convert';
import '../network/api_service.dart';
import '../network/auth_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getAllProducts({
    String? search,
    String? category,
    String? location,
    String? sort,
    bool? showAll,
    int? page,
    int limit = 10,
    String? vendorId,
  }) async {
    String query = '?limit=$limit';
    if (search != null && search.isNotEmpty) query += '&search=${Uri.encodeComponent(search)}';
    if (category != null && category != 'All') query += '&category=${Uri.encodeComponent(category)}';
    if (location != null && location.isNotEmpty) query += '&location=${Uri.encodeComponent(location)}';
    if (sort != null) query += '&sort=$sort';
    if (showAll != null) query += '&showAll=$showAll';
    if (page != null) query += '&page=$page';
    if (vendorId != null) query += '&vendorId=$vendorId';

    final token = await _authService.getToken();
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await _apiService.get('/products$query', headers: headers);
    final Map<String, dynamic> data;
    try {
      data = json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Invalid server response'};
    }
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch products');
    }
  }

  Future<Map<String, dynamic>> getProduct(String id) async {
    final token = await _authService.getToken();
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await _apiService.get('/products/$id', headers: headers);
    final Map<String, dynamic> data;
    try {
      data = json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Invalid server response'};
    }
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch product');
    }
  }

  Future<Map<String, dynamic>> getMyProducts({int page = 1, int limit = 20}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _apiService.get('/products/my-products?page=$page&limit=$limit', headers: {
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
      throw Exception(data['message'] ?? 'Failed to fetch your products');
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData, List<dynamic> images) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final Map<String, String> fields = productData.map((key, value) => MapEntry(key, value.toString()));
    final response = await _apiService.multipartPost('/products', fields: fields, files: images);

    final Map<String, dynamic> data;
    try {
      data = json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Invalid server response'};
    }
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to create product');
    }
  }

  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData, {List<dynamic>? images}) async {
    if (images != null && images.isNotEmpty) {
       final token = await _authService.getToken();
       if (token == null) throw Exception('Not authenticated');
       final Map<String, String> fields = productData.map((key, value) => MapEntry(key, value.toString()));
       final response = await _apiService.multipartPatch('/products/$id', fields: fields, files: images);
       final Map<String, dynamic> data;
       try {
         data = json.decode(response.body);
       } catch (e) {
         return {'success': false, 'message': 'Invalid server response'};
       }
        if (response.statusCode == 200) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to update product');
        }
    } else {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Not authenticated');
      final response = await _apiService.patch(
        '/products/$id',
        body: productData,
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
        throw Exception(data['message'] ?? 'Failed to update product');
      }
    }
  }

  Future<void> deleteProduct(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _apiService.delete('/products/$id', headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 204) {
      final Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        throw Exception('Failed to delete product');
      }
      throw Exception(data['message'] ?? 'Failed to delete product');
    }
  }

  Future<Map<String, dynamic>> updateProductStock(String id, int quantity, String status) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _apiService.patch(
      '/products/$id/stock',
      body: {'stockQuantity': quantity, 'productStatus': status},
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
      throw Exception(data['message'] ?? 'Failed to update stock');
    }
  }
}
