import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'order_item_model.dart';

enum OrderStatus { pending, processing, delivered, cancelled } // Chỉ giữ lại các trạng thái trong mockup

// Helper function để chuyển đổi String thành OrderStatus
OrderStatus statusFromString(String? statusStr) {
  switch (statusStr?.toLowerCase()) {
    case 'processing':
      return OrderStatus.processing;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'pending':
    default: // Mặc định là pending nếu không khớp hoặc null
      return OrderStatus.pending;
  }
}

// Helper function để chuyển OrderStatus thành String
String statusToString(OrderStatus status) {
  return status.toString().split('.').last;
}


class OrderModel extends Equatable {
  final String id;
  final String userId;
  final List<OrderItemModel> items;
  final double totalAmount; // Tổng tiền cuối cùng (có thể đã bao gồm discount)
  final double deliveryFee; // Phí vận chuyển (nếu có riêng)
  final String shippingAddress; // Địa chỉ đầy đủ dưới dạng String
  final String paymentMethodDetails; // Ví dụ: "Visa **** 3947"
  final OrderStatus status;
  final Timestamp createdAt;
  final String trackingNumber; // <-- Thêm mới
  final String deliveryMethodInfo; // <-- Thêm mới (Ví dụ: "FedEx, 3 days, 15$")
  final String? discountInfo; // <-- Thêm mới (Có thể null)

  // --- Tính toán số lượng tổng ---
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  // ---------------------------

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.deliveryFee, // Giữ lại nếu bạn lưu riêng, nếu không lấy từ deliveryMethodInfo
    required this.shippingAddress,
    required this.paymentMethodDetails, // Đổi tên từ paymentMethod
    this.status = OrderStatus.pending,
    required this.createdAt,
    required this.trackingNumber, // Yêu cầu khi tạo
    required this.deliveryMethodInfo, // Yêu cầu khi tạo
    this.discountInfo, // Không bắt buộc
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderModel(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((itemMap) => OrderItemModel.fromMap(itemMap as Map<String, dynamic>))
              .toList() ?? [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0, // Lấy deliveryFee nếu có
      shippingAddress: map['shippingAddress'] as String? ?? 'N/A',
      paymentMethodDetails: map['paymentMethodDetails'] as String? ?? 'N/A', // Đọc trường mới
      status: statusFromString(map['status'] as String?), // Dùng helper function
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      trackingNumber: map['trackingNumber'] as String? ?? 'N/A', // Đọc trường mới
      deliveryMethodInfo: map['deliveryMethodInfo'] as String? ?? 'N/A', // Đọc trường mới
      discountInfo: map['discountInfo'] as String?, // Đọc trường mới (có thể null)
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'deliveryFee': deliveryFee, // Lưu deliveryFee nếu cần
      'shippingAddress': shippingAddress,
      'paymentMethodDetails': paymentMethodDetails, // Lưu trường mới
      'status': statusToString(status), // Dùng helper function
      'createdAt': createdAt,
      'trackingNumber': trackingNumber, // Lưu trường mới
      'deliveryMethodInfo': deliveryMethodInfo, // Lưu trường mới
      'discountInfo': discountInfo, // Lưu trường mới
    };
  }

  @override
  List<Object?> get props => [
        id, userId, items, totalAmount, deliveryFee, shippingAddress,
        paymentMethodDetails, status, createdAt, trackingNumber,
        deliveryMethodInfo, discountInfo
      ];
}