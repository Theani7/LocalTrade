import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String title;
  final double price;
  final String imageUrl;
  final String vendorId;
  int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.vendorId,
    this.quantity = 1,
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(String productId, String title, double price, String imageUrl, String vendorId) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          title: existingItem.title,
          price: existingItem.price,
          imageUrl: existingItem.imageUrl,
          vendorId: existingItem.vendorId,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: productId,
          title: title,
          price: price,
          imageUrl: imageUrl,
          vendorId: vendorId,
        ),
      );
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (!_items.containsKey(productId)) return;
    if (quantity <= 0) {
      removeItem(productId);
    } else {
      _items[productId]!.quantity = quantity;
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
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
