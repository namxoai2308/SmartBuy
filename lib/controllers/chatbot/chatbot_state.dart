part of 'chatbot_cubit.dart'; // Đảm bảo tên file ChatbotCubit là đúng

@immutable
class ChatbotState extends Equatable {
  final List<MessageModel> messages; // <-- THAY ĐỔI: Sử dụng List<MessageModel>
  final bool isLoading;
  final String? error;

  const ChatbotState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  // Factory constructor cho trạng thái ban đầu
  factory ChatbotState.initial() {
    // Tạo một tin nhắn chào mừng ban đầu dưới dạng MessageModel
    return ChatbotState(
      messages: [
        MessageModel(
          senderId: 'chatbot', // ID của chatbot
          text: 'Hi there! How can I help you find a product today? You can ask me or send an image.',
          timestamp: Timestamp.now(), // Cung cấp timestamp hiện tại
        ),
      ],
      isLoading: false,
      error: null,
    );
  }

  // Phương thức copyWith để dễ dàng tạo state mới
  ChatbotState copyWith({
    List<MessageModel>? messages, // <-- THAY ĐỔI: Sử dụng List<MessageModel>
    bool? isLoading,
    String? error,
    bool clearError = false, // Flag để xóa lỗi
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, error];
}