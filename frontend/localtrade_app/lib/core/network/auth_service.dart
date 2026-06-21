import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';


class AuthService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      await _saveToken(data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to login');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await _apiService.post('/auth/register', body: userData);

    final data = json.decode(response.body);
    if (response.statusCode == 201) {
      await _saveToken(data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to register');
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    final response = await _apiService.get('/auth/me', headers: {
      'Authorization': 'Bearer $token',
    });

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data['data']['user'];
    } else {
      throw Exception(data['message'] ?? 'Failed to get user data');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, String> fields, {dynamic profileImage}) async {
    final response = await _apiService.multipartPatch(
      '/auth/profile', 
      fields: fields, 
      files: profileImage != null ? [profileImage] : null,
      fieldName: 'profileImage'
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update profile');
    }
  }

  Future<void> _saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
  }
}
