import 'dart:convert';
import '../network/api_service.dart';
import '../network/auth_service.dart';

class VendorService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getAnalytics() async {
    final token = await _authService.getToken();
    final response = await _apiService.get('/vendors/analytics', headers: {
      'Authorization': 'Bearer $token',
    });
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch analytics');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await _authService.getToken();
    final response = await _apiService.get('/vendors/profile', headers: {
      'Authorization': 'Bearer $token',
    });
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch profile');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, String> fields, {dynamic profileImage}) async {
    final response = await _apiService.multipartPatch(
      '/vendors/profile',
      fields: fields,
      files: profileImage != null ? [profileImage] : null,
      fieldName: 'profileImage',
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update profile');
    }
  }
}
