import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/chatbot/chatbot_cubit.dart';
import '../../controllers/chatbot/chatbot_state.dart';

class ChatbotPage extends StatelessWidget {
  const ChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController textController = TextEditingController();

    return BlocProvider(
      create: (_) => ChatbotCubit(),
      child: SafeArea( // ✅ Tránh bị đè bởi system UI
        child: Scaffold(
          resizeToAvoidBottomInset: true, // ✅ Đẩy lên khi mở bàn phím
          appBar: AppBar(
            title: const Text("Chatbot Gemini"),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: BlocBuilder<ChatbotCubit, ChatbotState>(
                  builder: (context, state) {
                    if (state.messages.isEmpty) {
                      return const Center(
                        child: Text('Bắt đầu trò chuyện nào!'),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final reversedIndex = state.messages.length - 1 - index;
                        final message = state.messages[reversedIndex];
                        final isUserMessage = message['role'] == 'user';

                        return _buildMessageBubble(
                          context: context,
                          text: message['text'] ?? '',
                          isUser: isUserMessage,
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                color: Colors.white, // ✅ Tách rõ với phần hiển thị tin nhắn
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16), // ✅ Cách bottom nav
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            _sendMessage(context, textController);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    BlocBuilder<ChatbotCubit, ChatbotState>(
                      builder: (context, state) {
                        return IconButton(
                          icon: const Icon(Icons.send),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _sendMessage(context, textController),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage(BuildContext context, TextEditingController controller) {
    final messageText = controller.text.trim();
    if (messageText.isNotEmpty) {
      context.read<ChatbotCubit>().sendMessage(messageText);
      controller.clear();
      FocusScope.of(context).unfocus(); // ✅ Ẩn bàn phím
    }
  }

  Widget _buildMessageBubble({
    required BuildContext context,
    required String text,
    required bool isUser,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}