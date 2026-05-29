import 'dart:convert';
import '../network/api_service.dart';
import '../network/auth_service.dart';

class FeedbackService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> submitFeedback(Map<String, dynamic> feedbackData) async {
    final token = await _authService.getToken();
    final response = await _apiService.post(
      '/feedback',
      body: feedbackData,
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to submit feedback');
    }
  }

  Future<Map<String, dynamic>> getAllFeedback() async {
    final token = await _authService.getToken();
    final response = await _apiService.get('/feedback', headers: {
      'Authorization': 'Bearer $token',
    });

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch feedback');
    }
  }
}
