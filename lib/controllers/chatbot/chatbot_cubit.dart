import 'package:flutter_bloc/flutter_bloc.dart';
import 'chatbot_state.dart';
import '../../services/gemini_service.dart';

class ChatbotCubit extends Cubit<ChatbotState> {
  final GeminiService _geminiService = GeminiService();

  ChatbotCubit() : super(ChatbotState.initial());

  void sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    emit(state.copyWith(messages: [...state.messages, {'role': 'user', 'text': message}]));

    final botReply = await _geminiService.sendMessage(message);
    emit(state.copyWith(messages: [...state.messages, {'role': 'bot', 'text': botReply}]));
  }
}
