import 'package:flutter/foundation.dart';
import '../core/network/category_service.dart';
import '../core/utils/cache_manager.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  static const String _activeCacheKey = 'active_categories';
  static const String _allCacheKey = 'all_categories';

  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get categoryNames => _categories.map((c) => c['name'] as String).toList();

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  Future<void> fetchActiveCategories() async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();
    try {
      _categories = await _service.getActiveCategories();
      await CacheManager.cacheData(_activeCacheKey, _categories);
    } catch (e) {
      _error = e.toString();
      if (_categories.isEmpty) {
        final cached = await CacheManager.getCachedData(_activeCacheKey);
        if (cached != null) {
          _categories = List<Map<String, dynamic>>.from(cached);
        }
      }
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllCategories() async {
    try {
      final result = await _service.getAllCategories();
      await CacheManager.cacheData(_allCacheKey, result);
      return result;
    } catch (e) {
      _error = e.toString();
      final cached = await CacheManager.getCachedData(_allCacheKey);
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached);
      }
      return [];
    }
  }

  Future<bool> createCategory(String name, {String icon = 'category', int sortOrder = 0}) async {
    try {
      await _service.createCategory(name, icon: icon, sortOrder: sortOrder);
      await fetchActiveCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(String id, {String? name, String? icon, int? sortOrder, bool? isActive}) async {
    try {
      await _service.updateCategory(id, name: name, icon: icon, sortOrder: sortOrder, isActive: isActive);
      await fetchActiveCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _service.deleteCategory(id);
      await fetchActiveCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return false;
    }
  }
}
