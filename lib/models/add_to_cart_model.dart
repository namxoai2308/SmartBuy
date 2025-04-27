import 'package:equatable/equatable.dart';

class AddToCartModel extends Equatable {
  final String id;
  final String productId;
  final String title;
  final double price;
  final int quantity;
  final String imgUrl;
  final int discountValue;
  final String color;
  final String size;
  final String brand;
  final String category;

  const AddToCartModel({
    required this.id,
    required this.title,
    required this.price,
    required this.productId,
    this.quantity = 1,
    required this.imgUrl,
    this.discountValue = 0,
    required this.color,
    required this.size,
    required this.brand,
    required this.category,
  });

  AddToCartModel copyWith({
    String? id,
    String? productId,
    String? title,
    double? price,
    int? quantity,
    String? imgUrl,
    int? discountValue,
    String? color,
    String? size,
    String? brand,
    String? category,
  }) {
    return AddToCartModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      title: title ?? this.title,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imgUrl: imgUrl ?? this.imgUrl,
      discountValue: discountValue ?? this.discountValue,
      color: color ?? this.color,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'title': title,
      'price': price,
      'quantity': quantity,
      'imgUrl': imgUrl,
      'discountValue': discountValue,
      'color': color,
      'size': size,
      'brand' : brand,
      'category': category,
    };
  }

  factory AddToCartModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AddToCartModel(
      id: documentId,
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 0,
      imgUrl: map['imgUrl'] ?? '',
      discountValue: map['discountValue']?.toInt() ?? 0,
      color: map['color'] ?? '',
      size: map['size'] ?? '',
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
    );
  }

  factory AddToCartModel.empty() => const AddToCartModel(
        id: '',
        productId: '',
        title: '',
        price: 0.0,
        quantity: 0,
        imgUrl: '',
        discountValue: 0,
        color: '',
        size: '',
        brand: '',
        category: '',
      );

  bool get isEmpty => id.isEmpty;

  @override
  List<Object?> get props => [
        id,
        productId,
        title,
        price,
        quantity,
        imgUrl,
        discountValue,
        color,
        size,
        brand,
        category,
      ];
}
