// import 'dart:convert';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:flutter_ecommerce/models/home/product.dart';
//
// abstract class HomeServices {
//   Future<List<Product>> getSalesProducts();
//   Future<List<Product>> getNewProducts();
//   Future<List<Product>> getAllProducts();
// }
//
// class HomeServicesImpl implements HomeServices {
//   List<Product>? _cachedProducts;
//
//   /// Load product list from local JSON file
//   Future<List<Product>> _loadLocalProducts() async {
//     if (_cachedProducts != null) return _cachedProducts!;
//
//     try {
//       final jsonString = await rootBundle.loadString('assets/products.json');
//       final List<dynamic> jsonList = json.decode(jsonString);
//
//       _cachedProducts = jsonList.map<Product>((jsonItem) {
//         final id = jsonItem['id'] ?? DateTime.now().microsecondsSinceEpoch.toString();
//         return Product.fromMap(jsonItem, id);
//       }).toList();
//
//       print("📦 Đã load ${_cachedProducts!.length} sản phẩm từ assets/products.json");
//
//       return _cachedProducts!;
//     } catch (e) {
//       print('❌ Error loading products.json: $e');
//       return [];
//     }
//   }
//
//   @override
//   Future<List<Product>> getNewProducts() async {
//     final products = await _loadLocalProducts();
//     products.shuffle(); // giả lập sản phẩm mới
//     return products.take(20).toList(); // lấy 20 sản phẩm
//   }
//
//   @override
//   Future<List<Product>> getSalesProducts() async {
//     final products = await _loadLocalProducts();
//     return products
//         .where((p) => p.discountValue != null && p.discountValue! > 0)
//         .toList();
//   }
//
//   @override
//   Future<List<Product>> getAllProducts() async {
//     return await _loadLocalProducts();
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ecommerce/models/home/product.dart';

abstract class HomeServices {
  Future<List<Product>> getSalesProducts();
  Future<List<Product>> getNewProducts();
  Future<List<Product>> getAllProducts();
}

class HomeServicesImpl implements HomeServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Product>? _cachedProducts;

  /// Load product list from Firestore (only once)
  Future<List<Product>> _loadProductsFromFirestore() async {
    if (_cachedProducts != null) return _cachedProducts!;

    try {
      final snapshot = await _firestore.collection('products').get();
      _cachedProducts = snapshot.docs.map((doc) {
        final data = doc.data();
        final id = doc.id;
        return Product.fromMap(data, id);
      }).toList();

      print("📦 Đã load ${_cachedProducts!.length} sản phẩm từ Firestore");
      return _cachedProducts!;
    } catch (e) {
      print('❌ Error loading products from Firestore: $e');
      return [];
    }
  }

  @override
  Future<List<Product>> getSalesProducts() async {
    final products = await _loadProductsFromFirestore();
    return products.where((p) => p.discountValue != null && p.discountValue! > 0).toList();
  }

  @override
  Future<List<Product>> getNewProducts() async {
    final products = await _loadProductsFromFirestore();
    return products.where((p) => p.discountValue == null || p.discountValue == 0).toList();
  }

  @override
  Future<List<Product>> getAllProducts() async {
    return await _loadProductsFromFirestore();
  }
}


