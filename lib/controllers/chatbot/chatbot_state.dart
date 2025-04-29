part of 'chatbot_cubit.dart';

@immutable
class ChatbotState extends Equatable {
  final List<Map<String, String>> messages;
  final bool isLoading;
  final String? error;

  const ChatbotState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  factory ChatbotState.initial() {
    return const ChatbotState(
      messages: [
        {'role': 'bot', 'text': 'Hi there! How can I help you find a product today? You can ask me or send an image.'}
      ],
      isLoading: false,
      error: null,
    );
  }

  ChatbotState copyWith({
    List<Map<String, String>>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
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
