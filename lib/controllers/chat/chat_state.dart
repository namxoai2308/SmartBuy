part of 'chat_cubit.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

// State khi danh sách cuộc trò chuyện đã được load
class ChatConversationsLoaded extends ChatState {
  final List<ConversationModel> conversations;

  const ChatConversationsLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

// State khi đang load màn hình chat cụ thể (vẫn giữ list conversations nền)
class ChatScreenLoading extends ChatState {
   final List<ConversationModel> conversations; // Danh sách chat nền
   final ConversationModel currentConversation; // Chat đang mở

   const ChatScreenLoading({required this.conversations, required this.currentConversation});

    @override
   List<Object?> get props => [conversations, currentConversation];
}


// State khi màn hình chat cụ thể đã load xong tin nhắn
class ChatScreenLoaded extends ChatState {
  final List<ConversationModel> conversations; // Danh sách chat nền
  final ConversationModel currentConversation; // Chat đang mở
  final List<MessageModel> messages; // Tin nhắn của chat đang mở

  const ChatScreenLoaded({
     required this.conversations,
     required this.currentConversation,
     required this.messages,
  });

  @override
  List<Object?> get props => [conversations, currentConversation, messages];

  // Helper để copy state khi chỉ cập nhật list conversations nền
  ChatScreenLoaded copyWith({
    List<ConversationModel>? conversations,
    ConversationModel? currentConversation,
    List<MessageModel>? messages,
  }) {
    return ChatScreenLoaded(
      conversations: conversations ?? this.conversations,
      currentConversation: currentConversation ?? this.currentConversation,
      messages: messages ?? this.messages,
    );
  }
}

// State khi có lỗi xảy ra
class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}