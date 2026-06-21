import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final String id;
  final String title;
  final double price;
  final String imageUrl;
  final String vendorId;
  final String vendorName;
  int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.vendorId,
    this.vendorName = '',
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': price,
    'imageUrl': imageUrl,
    'vendorId': vendorId,
    'vendorName': vendorName,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'],
    title: json['title'],
    price: json['price'].toDouble(),
    imageUrl: json['imageUrl'],
    vendorId: json['vendorId'],
    vendorName: json['vendorName'] ?? '',
    quantity: json['quantity'],
  );
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  CartProvider() {
    _loadCart();
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
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('shopping_cart')) return;
    
    final cartData = json.decode(prefs.getString('shopping_cart')!) as Map<String, dynamic>;
    _items = cartData.map((key, value) => MapEntry(key, CartItem.fromJson(value)));
    notifyListeners();
  }

  void addItem(String productId, String title, double price, String imageUrl, String vendorId, {String vendorName = ''}) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          title: existingItem.title,
          price: existingItem.price,
          imageUrl: existingItem.imageUrl,
          vendorId: existingItem.vendorId,
          vendorName: existingItem.vendorName,
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
          vendorName: vendorName,
        ),
      );
    }
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (!_items.containsKey(productId)) return;
    if (quantity <= 0) {
      removeItem(productId);
    } else {
      _items[productId]!.quantity = quantity;
      _saveCart();
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _saveCart();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _saveCart();
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
