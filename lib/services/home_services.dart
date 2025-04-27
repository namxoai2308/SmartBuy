import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_ecommerce/models/product.dart';

abstract class HomeServices {
  Future<List<Product>> getSalesProducts();
  Future<List<Product>> getNewProducts();
  Future<List<Product>> getAllProducts(); // 🆕 Thêm để hỗ trợ ShopPage
}

class HomeServicesImpl implements HomeServices {
  List<Product>? _cachedProducts;

  /// Load product list from local JSON file
  Future<List<Product>> _loadLocalProducts() async {
    if (_cachedProducts != null) return _cachedProducts!;

    try {
      final jsonString = await rootBundle.loadString('assets/products.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _cachedProducts = jsonList.map<Product>((jsonItem) {
        final id = jsonItem['id'] ?? DateTime.now().microsecondsSinceEpoch.toString();
        return Product.fromMap(jsonItem, id);
      }).toList();

      return _cachedProducts!;
    } catch (e) {
      print('❌ Error loading products.json: $e');
      return [];
    }
  }

  @override
  Future<List<Product>> getNewProducts() async {
    final products = await _loadLocalProducts();
    products.shuffle(); // giả lập sản phẩm mới
    return products.take(20).toList(); // lấy 20 sản phẩm
  }

  @override
  Future<List<Product>> getSalesProducts() async {
    final products = await _loadLocalProducts();
    return products
        .where((p) => p.discountValue != null && p.discountValue! > 0)
        .toList();
  }

  @override
  Future<List<Product>> getAllProducts() async {
    return await _loadLocalProducts();
  }
}
