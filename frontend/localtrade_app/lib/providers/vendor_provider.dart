import 'package:flutter/foundation.dart';
import '../core/network/vendor_service.dart';
import '../core/utils/cache_manager.dart';

class VendorProvider with ChangeNotifier {
  final VendorService _vendorService = VendorService();
  
  static const String _analyticsCacheKey = 'vendor_analytics';
  static const String _profileCacheKey = 'vendor_profile';

  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get analytics => _analytics;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _vendorService.getAnalytics();
      _analytics = result['data'];
      await CacheManager.cacheData(_analyticsCacheKey, result);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      if (_analytics == null) {
        final cached = await CacheManager.getCachedData(_analyticsCacheKey);
        if (cached != null) {
          _analytics = cached['data'];
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _vendorService.getProfile();
      _profile = result['data']['vendor'];
      await CacheManager.cacheData(_profileCacheKey, result);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      if (_profile == null) {
        final cached = await CacheManager.getCachedData(_profileCacheKey);
        if (cached != null) {
          _profile = cached['data']['vendor'];
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, String> fields, {dynamic image}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _vendorService.updateProfile(fields, profileImage: image);
      _profile = result['data']['vendor'];
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
