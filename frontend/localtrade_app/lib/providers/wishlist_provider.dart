import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistProvider with ChangeNotifier {
  static const String _wishlistKey = 'wishlist_product_ids';
  static const String _wishlistDetailsKey = 'wishlist_details';

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;

  List<String> get itemIds => _items.map((e) => e['_id'].toString()).toList();

  Future<void> loadWishlist() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final detailsJson = prefs.getString(_wishlistDetailsKey);
      if (detailsJson != null) {
        final List<dynamic> decoded = jsonDecode(detailsJson);
        _items = decoded.cast<Map<String, dynamic>>();
      } else {
        _items = [];
      }
    } catch (_) {
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isWishlisted(String productId) {
    return _items.any((item) => item['_id']?.toString() == productId);
  }

  Future<void> toggleWishlist(Map<String, dynamic> product) async {
    final productId = product['_id']?.toString() ?? '';
    if (productId.isEmpty) return;

    final existingIndex =
        _items.indexWhere((item) => item['_id']?.toString() == productId);

    if (existingIndex != -1) {
      _items.removeAt(existingIndex);
    } else {
      _items.add(Map<String, dynamic>.from(product));
    }

    notifyListeners();
    await _persistWishlist();
  }

  Future<void> removeFromWishlist(String productId) async {
    _items.removeWhere((item) => item['_id']?.toString() == productId);
    notifyListeners();
    await _persistWishlist();
  }

  Future<void> _persistWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final detailsJson = jsonEncode(_items);
    await prefs.setString(_wishlistDetailsKey, detailsJson);
    // Also maintain the ID list for backward compatibility
    final ids = _items.map((e) => e['_id'].toString()).toList();
    await prefs.setStringList(_wishlistKey, ids);
  }
}
