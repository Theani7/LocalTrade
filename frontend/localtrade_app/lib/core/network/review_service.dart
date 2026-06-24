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

  Future<Map<String, dynamic>> updateReview(String reviewId, {int? rating, String? reviewText}) async {
    final token = await _authService.getToken();
    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (reviewText != null) body['reviewText'] = reviewText;

    final response = await _apiService.patch(
      '/reviews/$reviewId',
      body: body,
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to update review');
    }
  }

  Future<void> deleteReview(String reviewId) async {
    final token = await _authService.getToken();
    final response = await _apiService.delete(
      '/reviews/$reviewId',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete review');
    }
  }

  Future<Map<String, dynamic>> getMyReviews() async {
    final token = await _authService.getToken();
    final response = await _apiService.get(
      '/reviews/my-reviews',
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch your reviews');
    }
  }

  Future<Map<String, dynamic>> addVendorReply(String reviewId, String text) async {
    final token = await _authService.getToken();
    final response = await _apiService.patch(
      '/reviews/$reviewId/reply',
      body: {'text': text},
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to submit reply');
    }
  }
}
