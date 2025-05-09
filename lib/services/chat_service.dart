// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ecommerce/models/chat/conversation_model.dart';
import 'package:flutter_ecommerce/models/chat/message_model.dart';
// Import file chứa ADMIN_SELLER_ID
import 'package:flutter_ecommerce/utilities/constants.dart'; // Đảm bảo đường dẫn đúng

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Tham chiếu đến collection 'conversations'
  late final CollectionReference _conversationsRef = _firestore.collection('conversations');

  // Hàm lấy hoặc tạo cuộc trò chuyện giữa Buyer và Admin cố định
  Future<String> getOrCreateConversationWithAdmin({
    required String buyerId,
    String? buyerName,
    String? buyerAvatar,
    String adminName = ADMIN_SELLER_NAME, // Lấy từ constant
    String? adminAvatar,
    String? productIdContext,
    String? productNameContext,
    String? productImageUrlContext,
  }) async {
    const String adminSellerId = ADMIN_SELLER_ID; // Lấy ID admin cố định

    // Query tìm conversation hiện có
    final querySnapshot = await _conversationsRef
        .where('buyerId', isEqualTo: buyerId)
        .where('adminSellerId', isEqualTo: adminSellerId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Conversation đã tồn tại
      final conversationDocRef = querySnapshot.docs.first.reference;
      final docData = querySnapshot.docs.first.data() as Map<String, dynamic>?;

      // Optional: Cập nhật context sản phẩm nếu khác
      if (productIdContext != null && docData?['productIdContext'] != productIdContext) {
           print("ChatService: Updating product context for existing conversation ${conversationDocRef.id}");
           await conversationDocRef.update({
              'productIdContext': productIdContext,
              'productNameContext': productNameContext,
              'productImageUrlContext': productImageUrlContext,
           });
      }
      return conversationDocRef.id; // Trả về ID đã tồn tại
    } else {
      // Tạo conversation mới
      print("ChatService: Creating new conversation between buyer $buyerId and admin $adminSellerId");
      final newConversationRef = _conversationsRef.doc(); // Tự tạo ID mới
      final timestamp = Timestamp.now();
      final participantIds = [buyerId, adminSellerId]..sort();

      await newConversationRef.set({
        'buyerId': buyerId,
        'adminSellerId': adminSellerId,
        'participantIds': participantIds,
        'buyerName': buyerName ?? 'Buyer',
        'sellerName': adminName, // Tên Admin
        'buyerAvatar': buyerAvatar,
        'sellerAvatar': adminAvatar,
        'lastMessageText': productNameContext != null ? 'Asked about: $productNameContext' : 'Conversation started',
        'lastMessageTimestamp': timestamp,
        'lastMessageSenderId': buyerId, // Buyer là người khởi tạo context hoặc convo
        'productIdContext': productIdContext,
        'productNameContext': productNameContext,
        'productImageUrlContext': productImageUrlContext,
        'createdAt': timestamp,
        // 'unreadForAdmin': 1, // Khởi tạo unread count nếu cần
        // 'unreadForBuyer': 0,
      });
      print("ChatService: New conversation created with ID: ${newConversationRef.id}");
      return newConversationRef.id; // Trả về ID mới được tạo
    }
  }

  // Hàm lấy stream danh sách conversations của một user
  Stream<List<ConversationModel>> getUserConversationsStream(String userId, String userRole) {
    print("ChatService: Getting conversations stream for user $userId (Role: $userRole)");
    Query query;
    const String adminId = ADMIN_SELLER_ID; // Dùng hằng số đã import

    if (userRole.toLowerCase() == 'buyer') {
      query = _conversationsRef
          .where('buyerId', isEqualTo: userId)
          .where('adminSellerId', isEqualTo: adminId); // Chỉ lấy convo với Admin
    } else if (userRole.toLowerCase() == 'seller' || userRole.toLowerCase() == 'admin') {
      // Admin/Seller thấy các convo họ tham gia với vai trò adminSellerId
      query = _conversationsRef.where('adminSellerId', isEqualTo: userId);
    } else {
      print("ChatService Warning: Unknown user role '$userRole'. Returning empty stream.");
      return Stream.value([]); // Trả về stream rỗng nếu role không hợp lệ
    }

    // Thêm sắp xếp và trả về stream
    return query
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
            print("ChatService: Conversations stream update received (${snapshot.docs.length} docs)");
            return snapshot.docs
              .map((doc) => ConversationModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList();
         })
        .handleError((error) {
           print("ChatService ERROR in getUserConversationsStream for $userId: $error");
           throw error; // Rethrow lỗi để lớp trên xử lý
        });
  }

  // Hàm lấy stream các tin nhắn trong một cuộc trò chuyện cụ thể
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    print("ChatService: Getting messages stream for conversation $conversationId");
    return _conversationsRef
        .doc(conversationId)
        .collection('messages') // Truy cập subcollection 'messages'
        .orderBy('timestamp', descending: false) // Sắp xếp tin nhắn theo thời gian tăng dần
        .snapshots() // Lắng nghe thay đổi real-time
        .map((snapshot) {
            print("ChatService: Messages stream update received for $conversationId (${snapshot.docs.length} docs)");
            return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList(); // Chuyển đổi snapshot thành List<MessageModel>
         })
        .handleError((error) {
            print("ChatService ERROR in getMessagesStream for $conversationId: $error");
            throw error; // Rethrow lỗi
         });
  }

  // ****** THÊM HÀM NÀY ******
  // Hàm gửi tin nhắn mới và cập nhật last message của conversation
  Future<void> sendMessage(String conversationId, MessageModel message) async {
    if (conversationId.isEmpty) {
      print("ChatService Error: Cannot send message, conversationId is empty.");
      throw ArgumentError("conversationId cannot be empty.");
    }
     print("ChatService: Attempting to send message '${message.text}' to conversation $conversationId from ${message.senderId}");

    // Tham chiếu đến document conversation chính
    final conversationRef = _conversationsRef.doc(conversationId);
    // Tham chiếu đến document mới trong subcollection 'messages'
    final messageRef = conversationRef.collection('messages').doc(); // Firestore tự tạo ID

    // Sử dụng WriteBatch để đảm bảo tính nhất quán (atomic)
    WriteBatch batch = _firestore.batch();

    // 1. Thêm tin nhắn mới vào subcollection 'messages'
    // Dữ liệu tin nhắn được lấy từ message.toFirestore()
    batch.set(messageRef, message.toFirestore());
    print("ChatService: Added set operation for new message ${messageRef.id}");

    // 2. Cập nhật thông tin tin nhắn cuối cùng trên document conversation chính
    // Chỉ cập nhật các trường cần thiết
    batch.update(conversationRef, {
      'lastMessageText': message.text.length > 150 ? '${message.text.substring(0, 147)}...' : message.text, // Giới hạn độ dài preview
      'lastMessageTimestamp': message.timestamp, // Dùng timestamp từ message object
      'lastMessageSenderId': message.senderId,
      // --- Tùy chọn: Cập nhật unread count ---
      // Cần logic phức tạp hơn để biết người nhận là ai và tăng count của họ
      // Ví dụ đơn giản (cần lấy thông tin participant kia):
      // final recipientId = message.senderId == conversationData['buyerId'] ? conversationData['adminSellerId'] : conversationData['buyerId'];
      // batch.update(conversationRef, {'unreadCount.$recipientId': FieldValue.increment(1)});
      // -----------------------------------------
    });
     print("ChatService: Added update operation for conversation $conversationId last message.");

    // Thực hiện cả hai thao tác ghi trong batch
    try {
      await batch.commit();
      print("ChatService: Batch commit successful for sending message to $conversationId");
    } catch (e) {
      print("ChatService: ERROR committing message batch for conversation $conversationId: $e");
      // Ném lại lỗi để lớp gọi (Cubit) có thể bắt và xử lý
      throw Exception("Failed to send message. Error: ${e.toString()}");
    }
  }
  // ************************
}