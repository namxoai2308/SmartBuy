class ShippingAddress {
  final String id;
  final String fullName;
  final String country;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;

  ShippingAddress({
    required this.id,
    required this.fullName,
    required this.country,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
  });

  // ... (các factory constructor và methods khác giữ nguyên) ...

  // THÊM GETTER NÀY:
  bool get isEmpty {
    // Một địa chỉ được coi là "trống" nếu các trường thông tin chính đều rỗng.
    // ID có thể không rỗng nếu nó được tạo từ `ShippingAddress.empty()` rồi gán ID sau,
    // nhưng về mặt hiển thị, nội dung mới quan trọng.
    // Hoặc bạn có thể bao gồm cả id.trim().isEmpty nếu muốn.
    return fullName.trim().isEmpty &&
           address.trim().isEmpty &&
           city.trim().isEmpty &&
           country.trim().isEmpty && // Thêm các trường quan trọng khác nếu cần
           state.trim().isEmpty;
  }

  factory ShippingAddress.empty() {
    return ShippingAddress(
      id: '', // id cũng rỗng khi tạo bằng empty()
      fullName: '',
      country: '',
      address: '',
      city: '',
      state: '',
      zipCode: '',
      isDefault: false,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'fullName': fullName});
    result.addAll({'country': country});
    result.addAll({'address': address});
    result.addAll({'city': city});
    result.addAll({'state': state});
    result.addAll({'zipCode': zipCode});
    result.addAll({'isDefault': isDefault});

    return result;
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map, String documentId) {
    return ShippingAddress(
      id: documentId,
      fullName: map['fullName'] ?? '',
      country: map['country'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  ShippingAddress copyWith({
    String? id,
    String? fullName,
    String? country,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    bool? isDefault,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      country: country ?? this.country,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}