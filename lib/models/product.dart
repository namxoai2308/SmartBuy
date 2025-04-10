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

  // New fields for more detailed product info
  final String? description;
  final String? brand;
  final bool? inStock;

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
  });

  /// Calculate average rating from reviews
  double get averageRating {
    if (reviews.isEmpty) return 0;
    double total = reviews.fold(0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }

  /// Count total number of reviews
  int get reviewCount => reviews.length;

  /// Convert Product to Map (for Firestore or serialization)
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
    };
  }

  /// Create Product from Map (e.g., from Firestore)
  factory Product.fromMap(Map<String, dynamic> map, String id) {
    final reviewsMap = map['reviews'] as Map<String, dynamic>?;

    final reviewsFromMap = reviewsMap?.entries.map((entry) {
      final reviewId = entry.key;
      final reviewData = entry.value as Map<String, dynamic>;
      return Review.fromMap(reviewId, reviewData);
    }).toList();

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
    );
  }
}
