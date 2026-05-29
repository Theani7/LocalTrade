import 'dart:convert';
import '../network/api_service.dart';
import '../network/auth_service.dart';

class ReviewService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getProductReviews(String productId) async {
    final response = await _apiService.get('/products/$productId/reviews');
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch reviews');
    }
  }

  Future<Map<String, dynamic>> addReview(String productId, int rating, String reviewText) async {
    final token = await _authService.getToken();
    final response = await _apiService.post(
      '/reviews',
      body: {
        'productId': productId,
        'rating': rating,
        'reviewText': reviewText,
      },
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to submit review');
    }
  }
}
