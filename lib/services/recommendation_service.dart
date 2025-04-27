import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_ecommerce/services/home_services.dart';

class RecommendationServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeServicesImpl _homeServices = HomeServicesImpl();

  Future<List<Product>> getRecommendations(String? userId) async {
    if (userId == null) {
      return await _getNonPersonalizedRecommendations();
    }

    try {
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      if (ordersSnapshot.docs.length < 3) {
        return await _getNonPersonalizedRecommendations();
      } else {
        return await _getPersonalizedRecommendations(userId);
      }
    } catch (e) {
      return await _getNonPersonalizedRecommendations();
    }
  }

  Future<List<Product>> _getNonPersonalizedRecommendations() async {
    final allProducts = await _homeServices.getAllProducts();
    allProducts.shuffle();
    return allProducts.take(10).toList();
  }

  Future<List<Product>> _getPersonalizedRecommendations(String userId) async {
    final allProducts = await _homeServices.getAllProducts();

    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> purchasedItems = [];

    for (var doc in ordersSnapshot.docs) {
      final items = List<Map<String, dynamic>>.from(doc['items']);
      purchasedItems.addAll(items);
    }

    int totalQuantity = purchasedItems.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] ?? 0) as num).toInt(),
    );

    if (totalQuantity <= 5) {
      Set<String> titles = purchasedItems.map((item) => item['title'] as String).toSet();

      List<Product> recommended = allProducts.where((product) {
        return titles.contains(product.title);
      }).toList();

      recommended.shuffle();
      return recommended.take(10).toList();
    } else {
      Set<String> brands = purchasedItems.map((item) => item['brand'] as String).toSet();
      Set<String> categories = purchasedItems.map((item) => item['category'] as String).toSet();

      List<Product> recommended = allProducts.where((product) {
        return brands.contains(product.brand) || categories.contains(product.category);
      }).toList();

      recommended.shuffle();
      return recommended.take(10).toList();
    }
  }
}
