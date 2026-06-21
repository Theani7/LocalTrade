import 'package:flutter/material.dart';
import '../core/network/review_service.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  
  List<dynamic> _reviews = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProductReviews(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _reviewService.getProductReviews(productId);
      _reviews = result['data']['reviews'];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReview(String productId, int rating, String reviewText) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _reviewService.addReview(productId, rating, reviewText);
      await fetchProductReviews(productId); // Refresh reviews
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
