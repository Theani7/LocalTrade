class CartItem {
  final String productId;
  final String title;
  final double price;
  final String imageUrl;
  final String vendorId;
  int quantity;

  CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.vendorId,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'title': title,
    'price': price,
    'imageUrl': imageUrl,
    'vendorId': vendorId,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? '',
      title: json['title'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      vendorId: json['vendorId'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }
}
