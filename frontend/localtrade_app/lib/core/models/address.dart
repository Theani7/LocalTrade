class Address {
  final String fullName;
  final String phone;
  final String flatHouse;
  final String street;
  final String landmark;
  final String city;
  final String state;
  final String zipCode;

  const Address({
    required this.fullName,
    required this.phone,
    this.flatHouse = '',
    this.street = '',
    this.landmark = '',
    required this.city,
    required this.state,
    required this.zipCode,
  });

  /// Full address as a single display string (for order tracking / vendor view).
  String get fullAddress {
    final parts = <String>[
      if (flatHouse.isNotEmpty) flatHouse,
      if (street.isNotEmpty) street,
      if (landmark.isNotEmpty) 'Landmark: $landmark',
      city,
      state,
      zipCode,
    ];
    return parts.join(', ');
  }

  /// Short one-line summary for compact displays (max 2 lines).
  String get shortAddress {
    final parts = <String>[
      if (flatHouse.isNotEmpty) flatHouse,
      if (street.isNotEmpty) street,
      city,
      state,
    ];
    return parts.join(', ');
  }

  factory Address.fromJson(dynamic json) {
    if (json is String) {
      // Legacy orders stored as plain string
      return Address(
        fullName: '',
        phone: '',
        city: json,
        state: '',
        zipCode: '',
      );
    }
    if (json is Map) {
      return Address(
        fullName: json['fullName'] ?? '',
        phone: json['phone'] ?? '',
        flatHouse: json['flatHouse'] ?? '',
        street: json['street'] ?? '',
        landmark: json['landmark'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        zipCode: json['zipCode'] ?? '',
      );
    }
    return const Address(fullName: '', phone: '', city: '', state: '', zipCode: '');
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'flatHouse': flatHouse,
    'street': street,
    'landmark': landmark,
    'city': city,
    'state': state,
    'zipCode': zipCode,
  };

  bool get isEmpty => fullName.isEmpty && city.isEmpty && zipCode.isEmpty;
}
