class ChatbotState {
  final List<Map<String, String>> messages;

  ChatbotState({required this.messages});

  factory ChatbotState.initial() => ChatbotState(messages: []);

  ChatbotState copyWith({List<Map<String, String>>? messages}) {
    return ChatbotState(messages: messages ?? this.messages);
  }
}
