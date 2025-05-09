import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ConversationModel extends Equatable {
  final String id; // Document ID from Firestore
  final String buyerId;
  final String sellerId;
  final List<String> participantIds; // [buyerId, sellerId]
  final String buyerName;
  final String sellerName;
  final String? buyerAvatar;
  final String? sellerAvatar;
  final String lastMessageText;
  final Timestamp lastMessageTimestamp;
  final String lastMessageSenderId;
  final String? productId;
  final String? productName;
  final String? productImageUrl;
  final Timestamp createdAt;

  const ConversationModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.participantIds,
    required this.buyerName,
    required this.sellerName,
    this.buyerAvatar,
    this.sellerAvatar,
    required this.lastMessageText,
    required this.lastMessageTimestamp,
    required this.lastMessageSenderId,
    this.productId,
    this.productName,
    this.productImageUrl,
    required this.createdAt,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Conversation data not found for document ${snapshot.id}");
    }
    return ConversationModel(
      id: snapshot.id,
      buyerId: data['buyerId'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      participantIds: List<String>.from(data['participantIds'] as List<dynamic>? ?? []),
      buyerName: data['buyerName'] as String? ?? 'Buyer',
      sellerName: data['sellerName'] as String? ?? 'Seller',
      buyerAvatar: data['buyerAvatar'] as String?,
      sellerAvatar: data['sellerAvatar'] as String?,
      lastMessageText: data['lastMessageText'] as String? ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] as Timestamp? ?? Timestamp.now(),
      lastMessageSenderId: data['lastMessageSenderId'] as String? ?? '',
      productId: data['productId'] as String?,
      productName: data['productName'] as String?,
      productImageUrl: data['productImageUrl'] as String?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // toFirestore không cần thiết trừ khi bạn muốn ghi đè toàn bộ doc từ client
  // Thông thường chỉ cập nhật các field cần thiết (lastMessage...)

  @override
  List<Object?> get props => [
        id, buyerId, sellerId, participantIds, buyerName, sellerName,
        buyerAvatar, sellerAvatar, lastMessageText, lastMessageTimestamp,
        lastMessageSenderId, productId, productName, productImageUrl, createdAt
      ];
}