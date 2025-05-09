import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ecommerce/models/order/order_model.dart';
import 'package:flutter_ecommerce/models/order/order_item_model.dart';

abstract class OrderServices {
  Future<String> createOrder(OrderModel order);
  Future<List<OrderModel>> getOrders(String userId);
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus);
  Future<List<OrderModel>> getAllOrders();
}

class OrderServicesImpl implements OrderServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> createOrder(OrderModel order) async {
    try {
      final orderRef = _firestore.collection('orders').doc();
      await orderRef.set(order.toMap());
      debugPrint('✅ Order created successfully in Firestore with ID: ${orderRef.id}');
      return orderRef.id;
    } catch (e) {
      debugPrint('Error creating order in Firestore: $e');
      throw Exception('Failed to create order.');
    }
  }

  @override
  Future<List<OrderModel>> getOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('No orders found for user $userId.');
        return [];
      }

      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      debugPrint('✅ Fetched ${orders.length} orders for user $userId.');
      return orders;
    } catch (e) {
      debugPrint('Error fetching orders for user $userId: $e');
      throw Exception('Failed to fetch orders.');
    }
  }
@override
Future<List<OrderModel>> getAllOrders() async {
  debugPrint('📦 OrderService: Fetching ALL orders for Admin.');
  try {
    final snapshot = await _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        // .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id)) // LỖI Ở ĐÂY
        .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)) // SỬA Ở ĐÂY
        .toList();
  } catch (e) {
    debugPrint('📦 OrderService: Error fetching all orders for admin: $e');
    rethrow;
  }
}

   @override
    Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
      try {
        await _firestore.collection('orders').doc(orderId).update({
          'status': statusToString(newStatus),
        });
        debugPrint('✅ Order $orderId status updated to ${statusToString(newStatus)}');
      } catch (e) {
         debugPrint('Error updating order status for $orderId: $e');
         throw Exception('Failed to update order status.');
      }
    }
}
