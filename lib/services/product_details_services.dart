import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_ecommerce/models/product.dart';

abstract class ProductDetailsServices {
  Future<Product> getProductDetails(String productId);
}

class ProductDetailsServicesImpl implements ProductDetailsServices {
  List<Product>? _cachedProducts;

  Future<void> _loadProducts() async {
    if (_cachedProducts != null) return;

    final jsonString = await rootBundle.loadString('assets/products.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);

    _cachedProducts = jsonList.map((json) => Product.fromMap(json, json['id'])).toList();
  }

  @override
  Future<Product> getProductDetails(String productId) async {
    await _loadProducts();
    final product = _cachedProducts!.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found'),
    );
    return product;
  }
}
