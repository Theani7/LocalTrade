import 'address.dart';

class OrderItem {
  final String productId;
  final String? productTitle;
  final String? productImage;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    this.productTitle,
    this.productImage,
    required this.quantity,
    required this.price,
  });

  double get totalPrice => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    String productId = '';
    String? title;
    String? image;

    if (product is Map) {
      productId = product['_id'] ?? '';
      title = product['title'];
      final images = product['images'];
      if (images is List && images.isNotEmpty) {
        image = images[0];
      }
    } else {
      productId = product ?? '';
    }

    return OrderItem(
      productId: productId,
      productTitle: title,
      productImage: image,
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'product': productId,
    'quantity': quantity,
    'price': price,
  };
}

enum OrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  processing('Processing'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.label);
  final String label;

  factory OrderStatus.fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

class Order {
  final String id;
  final String customerId;
  final String vendorId;
  final String? vendorName;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final Address shippingAddress;
  final String? notes;
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.customerId,
    required this.vendorId,
    this.vendorName,
    required this.items,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    required this.shippingAddress,
    this.notes,
    this.createdAt,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  String get displayTotal => 'Rs. ${totalAmount.toStringAsFixed(totalAmount % 1 == 0 ? 0 : 2)}';

  bool get canBeCancelled => status == OrderStatus.pending || status == OrderStatus.confirmed;

  factory Order.fromJson(Map<String, dynamic> json) {
    final vendorIdRaw = json['vendorId'];
    String vendorId;
    String? vendorName;

    if (vendorIdRaw is Map) {
      vendorId = vendorIdRaw['_id'] ?? '';
      vendorName = vendorIdRaw['shopName'] ?? vendorIdRaw['fullName'];
    } else {
      vendorId = vendorIdRaw ?? '';
    }

    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      vendorId: vendorId,
      vendorName: vendorName,
      items: (json['products'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.fromString(json['orderStatus'] ?? 'Pending'),
      shippingAddress: Address.fromJson(json['shippingAddress']),
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'customerId': customerId,
    'vendorId': vendorId,
    'products': items.map((item) => item.toJson()).toList(),
    'totalAmount': totalAmount,
    'orderStatus': status.label,
    'shippingAddress': shippingAddress.toJson(),
    'notes': notes,
    'createdAt': createdAt?.toIso8601String(),
  };
}
