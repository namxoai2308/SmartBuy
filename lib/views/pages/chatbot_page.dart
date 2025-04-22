import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/chatbot/chatbot_cubit.dart';
import '../../controllers/chatbot/chatbot_state.dart';

class ChatbotPage extends StatelessWidget {
  const ChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Chatbot",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, size: 28, color: Colors.black87),
                onPressed: () {
                  print('Search button pressed');
                },
              ),
            ],
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Container(
          color: Colors.white,
          child: Column(
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
              // Phần nhập tin nhắn và gửi tin nhắn giờ ở dưới body
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, -1),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.05),
                    )
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Row(
                  children: [
                    // Nút chọn ảnh
                    IconButton(
                      icon: const Icon(Icons.image_outlined),
                      onPressed: () {
                        try {
                          context.read<ChatbotCubit>().sendImageFromGallery();
                        } catch (e) {
                          print("Lỗi khi gọi sendImageFromGallery: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Không thể thực hiện hành động này ngay bây giờ.')),
                          );
                        }
                      },
                      tooltip: 'Gửi ảnh từ thư viện',
                      color: Theme.of(context).primaryColor,
                    ),
                    // Ô nhập tin nhắn
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
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        ),
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (text) {
                          _sendMessage(context, textController);
                        },
                        onEditingComplete: () => _sendMessage(context, textController),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // Nút gửi tin nhắn
                    IconButton(
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () => _sendMessage(context, textController),
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
      FocusScope.of(context).unfocus();
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
