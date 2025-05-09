// lib/controllers/chat/chat_cubit.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Cho Timestamp và Firestore instance
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // CHO listEquals
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart'; // Đảm bảo đã import AuthCubit
import 'package:flutter_ecommerce/models/chat/conversation_model.dart';
import 'package:flutter_ecommerce/models/chat/message_model.dart';
import 'package:flutter_ecommerce/models/user_model.dart'; // Đảm bảo đã import UserModel
import 'package:flutter_ecommerce/services/chat_service.dart';
// Import file chứa hằng số ID Admin nếu có
import 'package:flutter_ecommerce/utilities/constants.dart'; // Giả sử ADMIN_SELLER_ID ở đây

part 'chat_state.dart'; // Đảm bảo file state đúng và đã cập nhật

class ChatCubit extends Cubit<ChatState> {
  final ChatService _chatService = ChatService();
  final AuthCubit authCubit; // Biến để giữ instance AuthCubit
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Để truy cập Firestore
  StreamSubscription? _conversationsSubscription;
  StreamSubscription? _messagesSubscription;
  String? _currentUserId; // Lưu userId của người dùng đang đăng nhập

  // Constructor nhận AuthCubit
  ChatCubit({required this.authCubit}) : super(ChatInitial());

  // Helper lấy UserModel hiện tại
  UserModel? get _currentUser {
    final authState = authCubit.state;
    return authState is AuthSuccess ? authState.user : null;
  }

  // Helper lấy role hiện tại
  String? get _currentUserRole => _currentUser?.role.toLowerCase();

  // Load danh sách conversations cho user dựa trên ID và Role
  void loadUser(String userId, String userRole) {
    // Tránh load lại không cần thiết nếu user và state đã đúng
    if (_currentUserId == userId && state is! ChatInitial && state is! ChatError) {
      print("ChatCubit: User $userId already loaded.");
      // Optional: Thêm logic refresh nếu cần load lại khi quay lại tab
      // Ví dụ:
      // if (state is ChatConversationsLoaded || state is ChatScreenLoaded) {
      //   print("ChatCubit: Refreshing conversation list for $userId");
      //   // Không cần emit loading, chỉ cập nhật list trong listen
      // } else {
      //    return; // Vẫn đang loading hoặc lỗi, không làm gì
      // }
       return; // Bỏ qua nếu đã load
    }
    print("ChatCubit: Loading user $userId with role $userRole");
    _currentUserId = userId;
    _conversationsSubscription?.cancel(); // Hủy subscription cũ
    emit(ChatLoading()); // Emit trạng thái loading

    // Lắng nghe stream conversations từ service
    _conversationsSubscription = _chatService
        .getUserConversationsStream(userId, userRole)
        .listen((conversations) {
      if (isClosed) return; // Kiểm tra cubit còn active không
      print("ChatCubit: Received ${conversations.length} conversations for $userId");
      final currentState = state; // Lấy state hiện tại
      // Cập nhật state với danh sách conversations mới
       if (currentState is ChatScreenLoaded) {
          // Nếu đang ở màn hình chat, cập nhật list nền
          emit((currentState).copyWith(conversations: conversations));
       } else if (currentState is ChatScreenLoading) {
           // Nếu đang load màn hình chat, KHÔNG cập nhật list ở đây
           // Chờ ChatScreenLoaded được emit từ stream messages
           print("ChatCubit: Currently ChatScreenLoading, deferring conversation list update.");
       } else {
          // Các trường hợp khác (Loading, Initial, Error, ConversationsLoaded cũ) -> Emit ConversationsLoaded mới
          emit(ChatConversationsLoaded(conversations));
       }
    }, onError: (error) {
      if (isClosed) return;
      print("ChatCubit: Error loading conversations: $error");
      emit(ChatError("Failed to load conversations: $error")); // Emit trạng thái lỗi
    });
  }

  // Mở màn hình chi tiết của một cuộc trò chuyện
  void openChatScreen(ConversationModel conversation) {
     if (_currentUserId == null) {
        print("ChatCubit Error: Cannot open chat screen, user not loaded.");
        emit(const ChatError("User not loaded"));
        return;
     }
     // Tránh mở lại/load lại nếu đã đúng màn hình/đang load
     if ((state is ChatScreenLoaded && (state as ChatScreenLoaded).currentConversation.id == conversation.id) ||
         (state is ChatScreenLoading && (state as ChatScreenLoading).currentConversation.id == conversation.id)) {
        print("ChatCubit: Chat screen for ${conversation.id} already open or loading.");
        return;
     }

    print("ChatCubit: Opening chat screen for ${conversation.id}");
    _messagesSubscription?.cancel(); // Hủy sub messages cũ

    // Lấy list conversations nền từ state hiện tại
    List<ConversationModel> backgroundConversations = [];
    final currentStateBeforeLoading = state;
    if(currentStateBeforeLoading is ChatConversationsLoaded) backgroundConversations = currentStateBeforeLoading.conversations;
    if(currentStateBeforeLoading is ChatScreenLoaded) backgroundConversations = currentStateBeforeLoading.conversations;

    // Emit state loading cho màn hình chat mới
    emit(ChatScreenLoading(
       conversations: backgroundConversations,
       currentConversation: conversation,
    ));

    // Bắt đầu lắng nghe stream messages cho conversation này
    _messagesSubscription = _chatService
        .getMessagesStream(conversation.id)
        .listen((messages) { // Khi có dữ liệu messages mới
          if (isClosed) return;
          print("ChatCubit: Stream listener received ${messages.length} messages for ${conversation.id}.");
          if (messages.isNotEmpty) {
             print("ChatCubit: Last message received: '${messages.last.text}' from ${messages.last.senderId} at ${messages.last.timestamp.toDate()}");
          }

          final currentState = state; // Lấy state hiện tại ngay lúc nhận stream

          // Chỉ cập nhật state nếu đang loading hoặc đã load ĐÚNG conversation này
          if ((currentState is ChatScreenLoading && currentState.currentConversation.id == conversation.id) ||
              (currentState is ChatScreenLoaded && currentState.currentConversation.id == conversation.id))
          {
              // Lấy list conversations nền từ state hiện tại (loading hoặc loaded)
              List<ConversationModel> currentBackgroundConvos = [];
              if(currentState is ChatScreenLoading) currentBackgroundConvos = currentState.conversations;
              if(currentState is ChatScreenLoaded) currentBackgroundConvos = currentState.conversations;

               // So sánh list messages mới và cũ (nếu đã loaded) để tránh emit thừa
               bool messagesChanged = true;
               if (currentState is ChatScreenLoaded) {
                   messagesChanged = !listEquals(currentState.messages, messages); // Dùng listEquals đã import
               }

               if (messagesChanged) {
                  print("ChatCubit: Emitting ChatScreenLoaded for ${conversation.id} with ${messages.length} messages.");
                  emit(ChatScreenLoaded(
                      conversations: currentBackgroundConvos, // Giữ list nền
                      currentConversation: conversation,      // Conversation hiện tại
                      messages: messages,                   // List messages mới
                  ));
                  // TODO: Gọi logic đánh dấu đã đọc ở đây
               } else {
                   print("ChatCubit: Messages for ${conversation.id} haven't changed. Skipping emit.");
               }

           } else {
               print("ChatCubit: State changed (${currentState.runtimeType}) while processing stream for ${conversation.id}. Ignoring update.");
           }

        }, onError: (error) { // Xử lý lỗi từ stream messages
           if (isClosed) return;
           print("ChatCubit: ERROR in messages stream for ${conversation.id}: $error");
           final currentState = state;
           // Chỉ emit lỗi nếu đang loading/xem convo này
           if ((currentState is ChatScreenLoading && currentState.currentConversation.id == conversation.id) ||
               (currentState is ChatScreenLoaded && currentState.currentConversation.id == conversation.id)) {
              emit(ChatError("Failed to load messages: $error"));
           }
        });
  }

  // Đóng màn hình chat chi tiết, quay lại màn hình danh sách
  void closeChatScreen() {
     print("ChatCubit: Closing chat screen.");
     _messagesSubscription?.cancel(); // Hủy lắng nghe stream messages
     _messagesSubscription = null;
     final currentState = state;
     // Quay về trạng thái hiển thị danh sách conversations
     if (currentState is ChatScreenLoaded) {
        emit(ChatConversationsLoaded(currentState.conversations));
     } else if (currentState is ChatScreenLoading) {
        emit(ChatConversationsLoaded(currentState.conversations));
     } else if (currentState is ChatConversationsLoaded) {
        print("ChatCubit: Already in ConversationsLoaded state.");
     } else {
        print("ChatCubit: Closing chat screen from state: ${currentState.runtimeType}");
        emit(const ChatConversationsLoaded([])); // Trạng thái an toàn là list rỗng
     }
  }

  // Gửi một tin nhắn văn bản mới
  Future<void> sendMessage(String text) async {
    print("ChatCubit: Attempting to send message: '$text'");

    if (_currentUserId == null) { print("ChatCubit Send Error: User not loaded."); return; }

    final currentState = state;
    ConversationModel? currentConversation;

    // Chỉ gửi được khi đang ở màn hình chat cụ thể (Loaded hoặc Loading)
    if (currentState is ChatScreenLoaded) { currentConversation = currentState.currentConversation; }
    else if (currentState is ChatScreenLoading) { currentConversation = currentState.currentConversation; print("ChatCubit Send Warning: Trying to send while chat screen is still loading."); }
    else { print("ChatCubit Send Error: Chat screen not active (Current state: ${currentState.runtimeType})."); return; }

    if (currentConversation == null) { print("ChatCubit Send Error: Current conversation is null."); return; }
    final convoId = currentConversation.id;

    if (text.trim().isEmpty) { print("ChatCubit Send Error: Message text is empty."); return; }

    // Tạo đối tượng MessageModel
    final message = MessageModel(
      id: '', // Firestore sẽ tự tạo ID
      senderId: _currentUserId!,
      text: text.trim(),
      timestamp: Timestamp.now(),
    );

    try {
      print("ChatCubit: Calling _chatService.sendMessage for convo $convoId");
      // Gọi service để lưu tin nhắn và cập nhật conversation
      await _chatService.sendMessage(convoId, message);
      print("ChatCubit: Message sent successfully to service for convo $convoId. Waiting for stream update...");
      // Stream listener trong openChatScreen sẽ tự động cập nhật UI khi tin nhắn mới xuất hiện
    } catch (e) {
      print("ChatCubit: ERROR sending message via service for convo $convoId: $e");
      // Emit lỗi để UI có thể hiển thị thông báo
      emit(ChatError("Failed to send message: ${e.toString()}"));
      // Không tự động đóng chat để người dùng thấy lỗi và thử lại nếu muốn
    }
  }

  // Hàm để Buyer bắt đầu chat với Admin (có thể kèm context sản phẩm)
  Future<void> startChatWithAdmin({
    String? productIdContext,
    String? productNameContext,
    String? productImageUrlContext,
  }) async {
    final currentUser = _currentUser;
    if (currentUser == null) { emit(const ChatError("Cannot start chat: Please log in first.")); return; }
    if (currentUser.role.toLowerCase() != 'buyer') { emit(const ChatError("Only buyers can initiate chat with support.")); return; }

    print("ChatCubit: Buyer ${currentUser.uid} starting chat with Admin. Context: $productNameContext");
    emit(ChatLoading()); // Báo hiệu đang xử lý
    try {
      // Bước 1: Lấy hoặc tạo Conversation ID với Admin
      final conversationId = await _chatService.getOrCreateConversationWithAdmin(
        buyerId: currentUser.uid,
        buyerName: currentUser.name,
        buyerAvatar: null, // Lấy từ UserModel nếu có
        productIdContext: productIdContext,
        productNameContext: productNameContext,
        productImageUrlContext: productImageUrlContext,
      );
      print("ChatCubit: Got conversationId $conversationId with Admin.");

      // Bước 2: Lấy thông tin Conversation đầy đủ
      final convDoc = await _firestore.collection('conversations').doc(conversationId).get();
      if (!convDoc.exists) {
         print("ChatCubit: Error - Conversation document $conversationId not found after creation/retrieval.");
         emit(const ChatError("Failed to retrieve the chat details."));
         return;
      }
      final conversation = ConversationModel.fromFirestore(convDoc as DocumentSnapshot<Map<String, dynamic>>);

      // Bước 3: Gửi tin nhắn tự động (nếu có context sản phẩm)
      if (productNameContext != null && productNameContext.isNotEmpty) {
          String initialMessageText = "Hi, I have a question about the product: $productNameContext";
          final autoMessage = MessageModel(
            id: '',
            senderId: currentUser.uid, // Buyer gửi
            text: initialMessageText,
            timestamp: Timestamp.now(),
          );
          try {
             print("ChatCubit: Sending automatic product context message to $conversationId");
             await _chatService.sendMessage(conversationId, autoMessage);
             print("ChatCubit: Automatic message sent successfully.");
          } catch (sendMessageError) {
             print("ChatCubit: WARNING - Failed to send automatic message: $sendMessageError");
             // Bỏ qua lỗi này để vẫn mở màn hình chat
          }
      }

      // Bước 4: Mở màn hình chat (load messages và chuyển state)
      print("ChatCubit: Calling openChatScreen for $conversationId after potential auto-message.");
      openChatScreen(conversation);

    } catch (e) { // Bắt lỗi từ getOrCreateConversationWithAdmin hoặc get convDoc
      print("Error during startChatWithAdmin process: $e");
       if (e is FirebaseException && e.code == 'permission-denied') {
        emit(const ChatError("Failed to start chat: Permission denied. Check Firestore rules."));
      } else {
        emit(const ChatError("Failed to start chat with support. Please try again."));
      }
    }
  }

  // Hàm dọn dẹp khi người dùng logout hoặc cubit bị dispose
  void clearChatData() {
    print("ChatCubit: Clearing chat data.");
    _conversationsSubscription?.cancel(); // Hủy lắng nghe list convo
    _messagesSubscription?.cancel();    // Hủy lắng nghe list messages
    _conversationsSubscription = null;
    _messagesSubscription = null;
    _currentUserId = null;              // Reset user ID
    emit(ChatInitial());              // Quay về state ban đầu
  }

  @override
  Future<void> close() {
    print("ChatCubit closing and clearing data.");
    clearChatData(); // Gọi clearData khi cubit bị đóng
    return super.close();
  }
}