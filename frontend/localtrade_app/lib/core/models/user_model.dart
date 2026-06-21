import 'address.dart';

class User {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final Address? address;
  final String role;
  final String vendorApprovalStatus;
  final bool isActive;
  final String profileImage;
  final String? shopName;
  final String? businessDescription;
  final String? openingHours;
  final List<String> categories;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.address,
    required this.role,
    this.vendorApprovalStatus = 'approved',
    this.isActive = true,
    this.profileImage = '',
    this.shopName,
    this.businessDescription,
    this.openingHours,
    this.categories = const [],
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isVendor => role == 'vendor';
  bool get isCustomer => role == 'customer';
  bool get isApprovedVendor => isVendor && vendorApprovalStatus == 'approved';
  bool get isPendingVendor => isVendor && vendorApprovalStatus == 'pending';
  bool get hasAddress => address != null && address!.city.isNotEmpty;

  String get displayName => shopName ?? fullName;
  String get initials => fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join().toUpperCase();

  /// Short address string for compact displays (e.g. settings tiles).
  String get addressSummary {
    if (address == null || address!.city.isEmpty) return 'No address set';
    return address!.shortAddress;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: Address.fromJson(json['address']),
      role: json['role'] ?? 'customer',
      vendorApprovalStatus: json['vendorApprovalStatus'] ?? 'approved',
      isActive: json['isActive'] ?? true,
      profileImage: json['profileImage'] ?? '',
      shopName: json['shopName'],
      businessDescription: json['businessDescription'],
      openingHours: json['openingHours'],
      categories: List<String>.from(json['categories'] ?? []),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address?.toJson(),
      'role': role,
      'vendorApprovalStatus': vendorApprovalStatus,
      'isActive': isActive,
      'profileImage': profileImage,
      'shopName': shopName,
      'businessDescription': businessDescription,
      'openingHours': openingHours,
      'categories': categories,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? fullName,
    String? phone,
    Address? address,
    String? profileImage,
    String? shopName,
    String? businessDescription,
    String? openingHours,
    List<String>? categories,
  }) {
    return User(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role,
      vendorApprovalStatus: vendorApprovalStatus,
      isActive: isActive,
      profileImage: profileImage ?? this.profileImage,
      shopName: shopName ?? this.shopName,
      businessDescription: businessDescription ?? this.businessDescription,
      openingHours: openingHours ?? this.openingHours,
      categories: categories ?? this.categories,
      createdAt: createdAt,
    );
  }
}
