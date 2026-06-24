import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final String id;
  final String title;
  final double price;
  final String priceUnit;
  final String imageUrl;
  final String vendorId;
  final String vendorName;
  int quantity;
  final String? size;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    this.priceUnit = 'piece',
    required this.imageUrl,
    required this.vendorId,
    this.vendorName = '',
    this.quantity = 1,
    this.size,
  });

  String get priceUnitLabel {
    switch (priceUnit) {
      case 'kg': return 'kg';
      case '100g': return '100g';
      case 'liter': return 'L';
      case 'dozen': return 'dozen';
      case 'packet': return 'pkt';
      case 'bundle': return 'bundle';
      default: return '';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': price,
    'priceUnit': priceUnit,
    'imageUrl': imageUrl,
    'vendorId': vendorId,
    'vendorName': vendorName,
    'quantity': quantity,
    'size': size,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'],
    title: json['title'],
    price: json['price'].toDouble(),
    priceUnit: json['priceUnit'] ?? 'piece',
    imageUrl: json['imageUrl'],
    vendorId: json['vendorId'],
    vendorName: json['vendorName'] ?? '',
    quantity: json['quantity'],
    size: json['size'],
  );
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  bool _disposed = false;

  CartProvider() {
    _loadCart();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void onLogout() {
    _items = {};
    _safeNotifyListeners();
  }

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = json.encode(_items.map((key, item) => MapEntry(key, item.toJson())));
    await prefs.setString('shopping_cart', cartData);
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('shopping_cart')) return;

      final cartJson = prefs.getString('shopping_cart');
      if (cartJson == null || cartJson.isEmpty) return;

      final cartData = json.decode(cartJson) as Map<String, dynamic>;
      _items = cartData.map((key, value) => MapEntry(key, CartItem.fromJson(value)));
      _safeNotifyListeners();
    } catch (e) {
      // Clear corrupted cart data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('shopping_cart');
      } catch (_) {}
      _items = {};
    }
  }

  void addItem(String productId, String title, double price, String imageUrl, String vendorId, {String vendorName = '', String priceUnit = 'piece', String? size}) {
    final key = '${productId}_${size ?? ''}';
    if (_items.containsKey(key)) {
      _items.update(
        key,
        (existingItem) => CartItem(
          id: existingItem.id,
          title: existingItem.title,
          price: existingItem.price,
          priceUnit: existingItem.priceUnit,
          imageUrl: existingItem.imageUrl,
          vendorId: existingItem.vendorId,
          vendorName: existingItem.vendorName,
          quantity: existingItem.quantity + 1,
          size: existingItem.size,
        ),
      );
    } else {
      _items.putIfAbsent(
        key,
        () => CartItem(
          id: productId,
          title: title,
          price: price,
          priceUnit: priceUnit,
          imageUrl: imageUrl,
          vendorId: vendorId,
          vendorName: vendorName,
          size: size,
        ),
      );
    }
    _saveCart();
    _safeNotifyListeners();
  }

  /// Bulk-add items for reorder. Each entry: {productId, title, price, priceUnit, imageUrl, vendorId, vendorName, quantity}
  /// Items from the same vendor get grouped. If an item already exists in cart, quantity is set to the reorder quantity.
  void addItems(List<Map<String, dynamic>> reorderItems) {
    for (final item in reorderItems) {
      final productId = item['productId']?.toString() ?? '';
      if (productId.isEmpty) continue;

      final size = item['size'] as String?;
      final key = '${productId}_${size ?? ''}';
      final quantity = item['quantity'] ?? 1;
      if (_items.containsKey(key)) {
        _items.update(
          key,
          (existing) => CartItem(
            id: existing.id,
            title: existing.title,
            price: existing.price,
            priceUnit: existing.priceUnit,
            imageUrl: existing.imageUrl,
            vendorId: existing.vendorId,
            vendorName: existing.vendorName,
            quantity: quantity,
            size: existing.size,
          ),
        );
      } else {
        _items[key] = CartItem(
          id: productId,
          title: item['title'] ?? '',
          price: (item['price'] ?? 0).toDouble(),
          priceUnit: item['priceUnit'] ?? 'piece',
          imageUrl: item['imageUrl'] ?? '',
          vendorId: item['vendorId'] ?? '',
          vendorName: item['vendorName'] ?? '',
          quantity: quantity,
          size: size,
        );
      }
    }
    _saveCart();
    _safeNotifyListeners();
  }

  void updateQuantity(String productId, int quantity, {String? size}) {
    final key = '${productId}_${size ?? ''}';
    if (!_items.containsKey(key)) return;
    if (quantity <= 0) {
      removeItem(productId, size: size);
    } else {
      _items[key]!.quantity = quantity;
      _saveCart();
      _safeNotifyListeners();
    }
  }

  void removeItem(String productId, {String? size}) {
    final key = '${productId}_${size ?? ''}';
    _items.remove(key);
    _saveCart();
    _safeNotifyListeners();
  }

  void clear() {
    _items.clear();
    _saveCart();
    _safeNotifyListeners();
  }

  // Group items by vendor since orders are per vendor
  Map<String, List<CartItem>> get itemsByVendor {
    Map<String, List<CartItem>> grouped = {};
    _items.forEach((key, item) {
      if (!grouped.containsKey(item.vendorId)) {
        grouped[item.vendorId] = [];
      }
      grouped[item.vendorId]!.add(item);
    });
    return grouped;
  }
}
