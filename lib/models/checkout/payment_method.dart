// lib/models/payment_method.dart (hoặc đường dẫn của bạn)
import 'dart:convert';

class PaymentMethod {
  final String id;
  final String name;
  final String cardNumber;
  final String expiryDate;
  final String cvv;
  final bool isPreferred;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    this.isPreferred = false,
  });

  // Getter isEmpty
  bool get isEmpty {
    return id.trim().isEmpty &&
           name.trim().isEmpty &&
           cardNumber.trim().isEmpty;
  }

  static PaymentMethod empty() {
    return const PaymentMethod(
      id: '',
      name: '',
      cardNumber: '',
      expiryDate: '',
      cvv: '',
      isPreferred: false,
    );
  }

  // ... các hàm toMap, fromMap, toJson, fromJson, copyWith giữ nguyên
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'isPreferred': isPreferred,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      cardNumber: map['cardNumber'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      cvv: map['cvv'] ?? '',
      isPreferred: map['isPreferred'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory PaymentMethod.fromJson(String source) =>
      PaymentMethod.fromMap(json.decode(source));

  PaymentMethod copyWith({
    String? id,
    String? name,
    String? cardNumber,
    String? expiryDate,
    String? cvv,
    bool? isPreferred,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      isPreferred: isPreferred ?? this.isPreferred,
    );
  }
}