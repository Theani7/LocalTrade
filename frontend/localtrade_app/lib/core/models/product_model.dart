class Product {
  final String id;
  final String title;
  final String description;
  final String category;
  final double price;
  final String priceUnit;
  final double minOrder;
  final List<String> images;
  final String vendorId;
  final String? vendorName;
  final String? location;
  final int stockQuantity;
  final String productStatus;
  final double ratingsAverage;
  final int ratingsQuantity;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.priceUnit = 'piece',
    this.minOrder = 1,
    required this.images,
    required this.vendorId,
    this.vendorName,
    this.location,
    this.stockQuantity = 0,
    this.productStatus = 'Available',
    this.ratingsAverage = 0,
    this.ratingsQuantity = 0,
    this.createdAt,
  });

  bool get isAvailable => productStatus == 'Available' && stockQuantity > 0;
  bool get isOutOfStock => productStatus == 'OutOfStock' || stockQuantity <= 0;
  bool get isInactive => productStatus == 'Inactive';

  String get displayPrice => 'Rs. ${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}';

  String get priceWithUnit {
    final unitLabel = priceUnitLabel;
    if (unitLabel.isEmpty) return displayPrice;
    return '$displayPrice/$unitLabel';
  }

  String get priceUnitLabel {
    switch (priceUnit) {
      case 'kg': return 'kg';
      case '100g': return '100g';
      case 'liter': return 'L';
      case 'dozen': return 'dozen';
      case 'packet': return 'packet';
      case 'bundle': return 'bundle';
      default: return '';
    }
  }

  String get stockLabel => isOutOfStock ? 'Out of Stock' : '$stockQuantity in stock';
  String get categoryEmoji {
    switch (category) {
      case 'Vegetables': return '🥬';
      case 'Dairy': return '🥛';
      case 'Handicrafts': return '🎨';
      case 'Clothing': return '👕';
      case 'Local Goods': return '🌾';
      case 'Tailoring': return '✂️';
      case 'Groceries': return '🧺';
      case 'Bakery': return '🍞';
      case 'Meat': return '🥩';
      default: return '📦';
    }
  }

  String get primaryImage => images.isNotEmpty ? images.first : '';

  factory Product.fromJson(Map<String, dynamic> json) {
    final vendorIdRaw = json['vendorId'];
    String vendorId;
    String? vendorName;

    if (vendorIdRaw is Map) {
      vendorId = vendorIdRaw['_id'] ?? '';
      vendorName = vendorIdRaw['shopName'] ?? vendorIdRaw['fullName'];
    } else {
      vendorId = vendorIdRaw ?? '';
      vendorName = json['vendorName'];
    }

    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Others',
      price: (json['price'] ?? 0).toDouble(),
      priceUnit: json['priceUnit'] ?? 'piece',
      minOrder: (json['minOrder'] ?? 1).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      vendorId: vendorId,
      vendorName: vendorName,
      location: json['location'],
      stockQuantity: json['stockQuantity'] ?? json['stock'] ?? 0,
      productStatus: json['productStatus'] ?? 'Available',
      ratingsAverage: (json['ratingsAverage'] ?? 0).toDouble(),
      ratingsQuantity: json['ratingsQuantity'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'priceUnit': priceUnit,
      'minOrder': minOrder,
      'images': images,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'location': location,
      'stockQuantity': stockQuantity,
      'productStatus': productStatus,
      'ratingsAverage': ratingsAverage,
      'ratingsQuantity': ratingsQuantity,
    };
  }
}
