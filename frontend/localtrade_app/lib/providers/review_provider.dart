import 'package:flutter/material.dart';
import '../core/network/review_service.dart';
import '../core/utils/cache_manager.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  
  static const String _myReviewsCacheKey = 'my_reviews';

  List<dynamic> _reviews = [];
  List<dynamic> _myReviews = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get reviews => _reviews;
  List<dynamic> get myReviews => _myReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProductReviews(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final cacheKey = 'product_reviews_$productId';
    try {
      final result = await _reviewService.getProductReviews(productId);
      _reviews = result['data']['reviews'];
      await CacheManager.cacheData(cacheKey, result);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      if (_reviews.isEmpty) {
        final cached = await CacheManager.getCachedData(cacheKey);
        if (cached != null) {
          _reviews = cached['data']['reviews'] ?? [];
        }
      }
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
      await fetchProductReviews(productId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateReview(String reviewId, String productId, {int? rating, String? reviewText}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _reviewService.updateReview(reviewId, rating: rating, reviewText: reviewText);
      await fetchProductReviews(productId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReview(String reviewId, String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _reviewService.deleteReview(reviewId);
      await fetchProductReviews(productId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyReviews() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _reviewService.getMyReviews();
      _myReviews = result['data']['reviews'];
      await CacheManager.cacheData(_myReviewsCacheKey, result);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      if (_myReviews.isEmpty) {
        final cached = await CacheManager.getCachedData(_myReviewsCacheKey);
        if (cached != null) {
          _myReviews = cached['data']['reviews'] ?? [];
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addVendorReply(String reviewId, String text) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _reviewService.addVendorReply(reviewId, text);
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
