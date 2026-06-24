import 'package:flutter/material.dart';
import '../core/network/feedback_service.dart';
import '../core/utils/cache_manager.dart';

class FeedbackProvider with ChangeNotifier {
  final FeedbackService _feedbackService = FeedbackService();
  
  static const String _cacheKey = 'feedback';

  List<dynamic> _feedbackList = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;

  List<dynamic> get feedbackList => _feedbackList;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> submitFeedback(Map<String, dynamic> feedbackData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _feedbackService.submitFeedback(feedbackData);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllFeedback() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _feedbackService.getAllFeedback();
      _feedbackList = result['data']['feedback'];
      _stats = result['data']['stats'];
      await CacheManager.cacheData(_cacheKey, result);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      if (_feedbackList.isEmpty) {
        final cached = await CacheManager.getCachedData(_cacheKey);
        if (cached != null) {
          _feedbackList = cached['data']['feedback'] ?? [];
          _stats = cached['data']['stats'];
        }
      }
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
