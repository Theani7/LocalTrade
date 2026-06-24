import 'package:flutter/foundation.dart';
import '../core/network/product_service.dart';
import '../core/utils/cache_manager.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  
  static const String _catalogCacheKey = 'product_catalog';
  static const String _myProductsCacheKey = 'my_products';

  List<dynamic> _products = [];
  List<dynamic> _myProducts = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;

  // Catalog pagination & Filters State
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  String? _search;
  String? _category;
  String? _location;
  String? _sort;
  bool _showAll = false;

  // My products pagination
  int _myCurrentPage = 1;
  int _myTotalPages = 1;
  int _myTotalResults = 0;
  bool _myHasMore = false;
  bool _isFetchingMoreMyProducts = false;

  // Getters
  List<dynamic> get products => _products;
  List<dynamic> get myProducts => _myProducts;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get isFetchingMoreMyProducts => _isFetchingMoreMyProducts;
  String? get error => _error;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  bool get hasMore => _currentPage <= _totalPages;
  
  bool get myHasMore => _myHasMore;
  int get myTotalResults => _myTotalResults;
  
  String? get selectedCategory => _category;
  String? get selectedSort => _sort;
  String? get selectedLocation => _location;
  bool get showAll => _showAll;

  Future<void> fetchProducts({
    String? search,
    String? category,
    String? location,
    String? sort,
    bool? showAll,
    String? vendorId,
    bool refresh = true,
  }) async {
    if (refresh) {
      _setLoading(true);
      _currentPage = 1;
      _products = [];
    } else {
      if (_isFetchingMore || !hasMore) return;
      _isFetchingMore = true;
      notifyListeners();
    }

    _error = null;
    
    // Update local filter state if provided
    if (search != null) _search = search;
    if (category != null) _category = category;
    if (location != null) _location = location;
    if (sort != null) _sort = sort;
    if (showAll != null) _showAll = showAll;

    try {
      final result = await _productService.getAllProducts(
        search: _search,
        category: _category,
        location: _location,
        sort: _sort,
        showAll: _showAll,
        page: _currentPage,
        vendorId: vendorId,
      );

      final List<dynamic> newProducts = result['data']['products'];
      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _totalPages = result['totalPages'] ?? 1;
      _totalCount = result['totalCount'] ?? _products.length;
      
      if (!refresh && newProducts.isNotEmpty) {
        _currentPage++;
      } else if (refresh) {
        _currentPage = 2; // Next page to fetch
      }

      await CacheManager.cacheData(_catalogCacheKey, {
        'data': {'products': _products},
        'totalPages': _totalPages,
        'totalCount': _totalCount,
      });
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      if (_products.isEmpty) {
        final cached = await CacheManager.getCachedData(_catalogCacheKey);
        if (cached != null) {
          _products = List<dynamic>.from(cached['data']['products'] ?? []);
          _totalPages = cached['totalPages'] ?? 1;
          _totalCount = cached['totalCount'] ?? _products.length;
        }
      }
    } finally {
      _setLoading(false);
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  void clearFilters() {
    _search = null;
    _category = 'All';
    _location = null;
    _sort = null;
    _showAll = false;
    fetchProducts();
  }

  Future<bool> updateProductStock(String id, int quantity, String status) async {
    _error = null;
    try {
      final result = await _productService.updateProductStock(id, quantity, status);
      final updatedProduct = result['data']['product'];
      
      // Update in both lists if present
      int myIndex = _myProducts.indexWhere((p) => p['_id'] == id);
      if (myIndex != -1) {
        _myProducts[myIndex] = updatedProduct;
      }

      int pIndex = _products.indexWhere((p) => p['_id'] == id);
      if (pIndex != -1) {
        _products[pIndex] = updatedProduct;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyProducts() async {
    _setLoading(true);
    _error = null;
    _myCurrentPage = 1;
    try {
      final result = await _productService.getMyProducts(page: 1, limit: 20);
      _myProducts = result['data']['products'];
      if (result['totalPages'] != null) {
        _myTotalPages = result['totalPages'];
        _myTotalResults = result['totalResults'] ?? _myProducts.length;
        _myHasMore = _myCurrentPage < _myTotalPages;
      } else {
        _myHasMore = false;
      }
      await CacheManager.cacheData(_myProductsCacheKey, result);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      if (_myProducts.isEmpty) {
        final cached = await CacheManager.getCachedData(_myProductsCacheKey);
        if (cached != null) {
          _myProducts = List<dynamic>.from(cached['data']['products'] ?? []);
          _myTotalPages = cached['totalPages'] ?? 1;
          _myTotalResults = cached['totalResults'] ?? _myProducts.length;
          _myHasMore = _myCurrentPage < _myTotalPages;
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreMyProducts() async {
    if (_isFetchingMoreMyProducts || !_myHasMore) return;
    _isFetchingMoreMyProducts = true;
    notifyListeners();
    try {
      _myCurrentPage++;
      final result = await _productService.getMyProducts(page: _myCurrentPage, limit: 20);
      final newProducts = result['data']['products'] as List<dynamic>;
      _myProducts.addAll(newProducts);
      if (result['totalPages'] != null) {
        _myTotalPages = result['totalPages'];
        _myHasMore = _myCurrentPage < _myTotalPages;
      } else {
        _myHasMore = false;
      }
    } catch (e) {
      _myCurrentPage--;
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isFetchingMoreMyProducts = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Map<String, dynamic> productData, List<dynamic> images) async {
    _setLoading(true);
    _error = null;
    try {
      await _productService.createProduct(productData, images);
      await fetchMyProducts();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> productData, {List<dynamic>? images}) async {
    _setLoading(true);
    _error = null;
    try {
      await _productService.updateProduct(id, productData, images: images);
      await fetchMyProducts();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProduct(String id) async {
    _setLoading(true);
    _error = null;
    try {
      await _productService.deleteProduct(id);
      _myProducts.removeWhere((p) => p['_id'] == id);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
