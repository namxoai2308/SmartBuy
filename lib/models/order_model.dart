import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'order_item_model.dart';

enum OrderStatus { pending, processing, delivered, cancelled }

OrderStatus statusFromString(String? statusStr) {
  switch (statusStr?.toLowerCase()) {
    case 'processing':
      return OrderStatus.processing;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'pending':
    default:
      return OrderStatus.pending;
  }
}

String statusToString(OrderStatus status) {
  return status.toString().split('.').last;
}

class OrderModel extends Equatable {
  final String id;
  final String userId;
  final List<OrderItemModel> items;
  final double totalAmount;
  final double deliveryFee;
  final String shippingAddress;
  final String paymentMethodDetails;
  final OrderStatus status;
  final Timestamp createdAt;
  final String trackingNumber;
  final String deliveryMethodInfo;
  final String? discountInfo;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.deliveryFee,
    required this.shippingAddress,
    required this.paymentMethodDetails,
    this.status = OrderStatus.pending,
    required this.createdAt,
    required this.trackingNumber,
    required this.deliveryMethodInfo,
    this.discountInfo,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderModel(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((itemMap) => OrderItemModel.fromMap(itemMap as Map<String, dynamic>))
              .toList() ?? [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      shippingAddress: map['shippingAddress'] as String? ?? 'N/A',
      paymentMethodDetails: map['paymentMethodDetails'] as String? ?? 'N/A',
      status: statusFromString(map['status'] as String?),
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      trackingNumber: map['trackingNumber'] as String? ?? 'N/A',
      deliveryMethodInfo: map['deliveryMethodInfo'] as String? ?? 'N/A',
      discountInfo: map['discountInfo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'deliveryFee': deliveryFee,
      'shippingAddress': shippingAddress,
      'paymentMethodDetails': paymentMethodDetails,
      'status': statusToString(status),
      'createdAt': createdAt,
      'trackingNumber': trackingNumber,
      'deliveryMethodInfo': deliveryMethodInfo,
      'discountInfo': discountInfo,
    };
  }

  @override
  List<Object?> get props => [
        id, userId, items, totalAmount, deliveryFee, shippingAddress,
        paymentMethodDetails, status, createdAt, trackingNumber,
        deliveryMethodInfo, discountInfo
      ];
}
