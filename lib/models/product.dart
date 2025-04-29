import 'package:flutter_ecommerce/models/review.dart';

class Product {
  final String id;
  final String title;
  final double price;
  final String imgUrl;
  final int? discountValue;
  final String category;
  final int? rate;
  final List<Review> reviews;
  final String? description;
  final String? brand;
  final bool? inStock;
  final List<String> relatedProductIds;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.imgUrl,
    this.discountValue,
    this.category = 'Other',
    this.rate,
    this.reviews = const [],
    this.description,
    this.brand,
    this.inStock,
    this.relatedProductIds = const [],
  });

  double get averageRating {
    if (reviews.isEmpty) return 0;
    double total = reviews.fold(0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }

  int get reviewCount => reviews.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'imgUrl': imgUrl,
      'discountValue': discountValue,
      'category': category,
      'rate': rate,
      'description': description,
      'brand': brand,
      'inStock': inStock,
      'reviews': {
        for (var review in reviews) review.id: review.toMap(),
      },
      'relatedProductIds': relatedProductIds,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    final reviewsMap = map['reviews'] as Map<String, dynamic>?;

    final reviewsFromMap = reviewsMap?.entries.map((entry) {
      final reviewId = entry.key;
      final reviewData = entry.value as Map<String, dynamic>;
      return Review.fromMap(reviewId, reviewData);
    }).toList();

    final relatedProductIdsList = (map['relatedProductIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return Product(
      id: id,
      title: map['title']?.toString() ?? '',
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] ?? 0).toDouble(),
      imgUrl: map['imgUrl']?.toString() ?? '',
      discountValue: (map['discountValue'] is int)
          ? map['discountValue'] as int
          : null,
      category: map['category']?.toString() ?? 'Other',
      rate: (map['rate'] is int) ? map['rate'] as int : null,
      description: map['description']?.toString(),
      brand: map['brand']?.toString(),
      inStock: map['inStock'] as bool?,
      reviews: reviewsFromMap ?? [],
      relatedProductIds: relatedProductIdsList,
    );
  }
}
