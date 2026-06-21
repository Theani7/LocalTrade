import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';

class ApiService {
  final http.Client _client = http.Client();
  final _storage = const FlutterSecureStorage();

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      debugPrint('API GET: $url');
      final response = await _client.get(url, headers: await _getHeaders(headers))
          .timeout(const Duration(seconds: 15));
      debugPrint('API GET Response [${response.statusCode}]: $url');
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Could not connect to server. Please ensure the backend is running.');
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> post(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      debugPrint('API POST: $url');
      final response = await _client.post(
        url,
        headers: await _getHeaders(headers),
        body: json.encode(body ?? {}),
      ).timeout(const Duration(seconds: 20));
      debugPrint('API POST Response [${response.statusCode}]: $url');
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> patch(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      debugPrint('API PATCH: $url');
      final response = await _client.patch(
        url,
        headers: await _getHeaders(headers),
        body: json.encode(body ?? {}),
      ).timeout(const Duration(seconds: 20));
      debugPrint('API PATCH Response [${response.statusCode}]: $url');
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client.delete(url, headers: await _getHeaders(headers))
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> multipartPost(String endpoint, {Map<String, String>? fields, List<dynamic>? files, String fieldName = 'images'}) async {
    return _handleResponse(await _multipartRequest('POST', endpoint, fields: fields, files: files, fieldName: fieldName));
  }

  Future<http.Response> multipartPatch(String endpoint, {Map<String, String>? fields, List<dynamic>? files, String fieldName = 'images'}) async {
    return _handleResponse(await _multipartRequest('PATCH', endpoint, fields: fields, files: files, fieldName: fieldName));
  }

  Future<http.Response> _multipartRequest(String method, String endpoint, {Map<String, String>? fields, List<dynamic>? files, String fieldName = 'images'}) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final token = await _storage.read(key: AppConstants.tokenKey);
      
      var request = http.MultipartRequest(method, url);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (fields != null) request.fields.addAll(fields);

      if (files != null) {
        for (var file in files) {
          if (file is File) {
            String ext = file.path.split('.').last.toLowerCase();
            String subtype = (ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : ext;
            request.files.add(await http.MultipartFile.fromPath(
              fieldName, 
              file.path,
              contentType: MediaType('image', subtype),
            ));
          } else if (file is XFile) {
            String ext = file.name.split('.').last.toLowerCase();
            String subtype = (ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : (ext.isEmpty ? 'jpeg' : ext);
            final bytes = await file.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
              fieldName,
              bytes,
              filename: file.name,
              contentType: MediaType('image', subtype),
            ));
          }
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      return await http.Response.fromStream(streamedResponse);
    } on SocketException {
      throw Exception('No internet connection during upload.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, String>> _getHeaders(Map<String, String>? extraHeaders) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } 
    
    String message = 'An unexpected error occurred';
    try {
      final body = json.decode(response.body);
      message = body['message'] ?? message;
    } catch (_) {
      if (response.statusCode == 404) message = 'Requested resource not found.';
      if (response.statusCode == 401) message = 'Session expired. Please login again.';
      if (response.statusCode == 403) message = 'You do not have permission to perform this action.';
      if (response.statusCode >= 500) message = 'Server error. Please try again later.';
    }

    throw Exception(message);
  }
}
