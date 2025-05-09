import 'package:equatable/equatable.dart';

class OrderItemModel extends Equatable {
  final String productId;
  final String title;
  final double price;
  final int quantity;
  final String imgUrl;
  final String? color;
  final String? size;
  final String? brand;
  final String? category;

  const OrderItemModel({
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
    required this.imgUrl,
    required this.brand,
    required this.category,
    this.color,
    this.size,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      imgUrl: map['imgUrl'] as String? ?? '',
      color: map['color'] as String?,
      size: map['size'] as String?,
      brand: map['brand'] as String?,
      category: map['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'quantity': quantity,
      'imgUrl': imgUrl,
      'color': color,
      'size': size,
      'brand': brand,
      'category' : category,
    };
  }

  @override
  List<Object?> get props => [productId, title, price, quantity, imgUrl, color, size, brand, category];
}