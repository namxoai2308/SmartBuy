// lib/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
// import 'dart:io'; // Không cần File ở đây nữa, chỉ cần path

class MessageModel extends Equatable {
  final String? id; // Có thể null nếu chưa lưu vào Firestore (vd: từ chatbot)
  final String senderId; // 'user', 'chatbot', hoặc userId của Seller
  final String text;
  final Timestamp timestamp; // Chatbot có thể tạo Timestamp.now() khi hiển thị
  final String? imageUrl; // Link ảnh đã upload (nếu có, từ Firestore)
  final String? localImagePath; // Đường dẫn ảnh local (cho chatbot preview trước khi gửi)

  const MessageModel({
    this.id,
    required this.senderId,
    required this.text,
    required this.timestamp, // Sẽ luôn được cung cấp
    this.imageUrl,
    this.localImagePath,
  });

 factory MessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
     if (data == null) {
      throw Exception("Message data not found for document ${snapshot.id}");
    }
    return MessageModel(
      id: snapshot.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(), // Cung cấp default
      imageUrl: data['imageUrl'] as String?,
      // localImagePath không được lưu vào Firestore
    );
  }

  // Dùng khi gửi tin nhắn người-người (ChatCubit) hoặc khi chatbot lưu (nếu có)
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp, // Luôn có timestamp khi lưu
      if (imageUrl != null) 'imageUrl': imageUrl,
      // Không lưu localImagePath vào Firestore
    };
  }

  // Factory để tạo MessageModel từ dữ liệu Map của ChatbotCubit
  factory MessageModel.fromChatbotMap(Map<String, dynamic> chatbotMsgData, {bool isUserMessage = false}) {
    String sender;
    if (isUserMessage || chatbotMsgData['role'] == 'user') {
      sender = 'user'; // Hoặc ID của người dùng hiện tại nếu bạn muốn phân biệt user nào chat với bot
    } else {
      sender = 'chatbot'; // ID cố định cho chatbot
    }

    return MessageModel(
      // id sẽ là null vì đây là tin nhắn từ chatbot, chưa có trên Firestore
      senderId: sender,
      text: chatbotMsgData['text'] as String? ?? '',
      timestamp: Timestamp.now(), // Chatbot không có timestamp từ API, dùng now() khi hiển thị
      localImagePath: chatbotMsgData['imagePath'] as String?, // Nếu chatbot gửi ảnh local
      // imageUrl sẽ null ban đầu cho chatbot, trừ khi API trả về link ảnh đã upload
    );
  }


  @override
  List<Object?> get props => [id, senderId, text, timestamp, imageUrl, localImagePath];
}