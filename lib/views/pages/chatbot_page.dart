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
                          decoration: BoxDecoration( // Thêm style cho đẹp hơn (tùy chọn)
                             color: Colors.white,
                             boxShadow: [
                               BoxShadow(
                                 offset: const Offset(0, -1),
                                 blurRadius: 4,
                                 color: Colors.black.withOpacity(0.05),
                               )
                             ]
                          ),
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12), // Điều chỉnh padding nếu cần
                          child: Row(
                            children: [
                              // *** THÊM NÚT CHỌN ẢNH Ở ĐÂY ***
                              IconButton(
                                icon: const Icon(Icons.image_outlined), // Icon chọn ảnh
                                onPressed: () {
                                  // Gọi hàm trong Cubit để mở thư viện ảnh
                                  // Quan trọng: Đảm bảo ChatbotPage này được cung cấp ChatbotCubit
                                  // thông qua BlocProvider như các bước trước đã làm.
                                   try {
                                     context.read<ChatbotCubit>().sendImageFromGallery();
                                   } catch (e) {
                                      print("Lỗi khi gọi sendImageFromGallery: $e");
                                      // Có thể hiển thị SnackBar thông báo lỗi nếu BlocProvider chưa sẵn sàng
                                      ScaffoldMessenger.of(context).showSnackBar(
                                         const SnackBar(content: Text('Không thể thực hiện hành động này ngay bây giờ.'))
                                      );
                                   }
                                },
                                tooltip: 'Gửi ảnh từ thư viện', // Tooltip hướng dẫn
                                color: Theme.of(context).primaryColor, // Màu icon (tùy chọn)
                              ),
                              // S*** KẾT THÚC PHẦN THÊM NÚT ***

                              // Ô nhập text (giữ nguyên)
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
                                    fillColor: Colors.grey.shade100, // Màu nền nhẹ hơn
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                  ),
                                   minLines: 1,
                                   maxLines: 5, // Cho phép nhập nhiều dòng
                                   textInputAction: TextInputAction.send, // Bàn phím có nút Send
                                  onSubmitted: (text) { // Gửi khi nhấn Enter/Send trên bàn phím
                                    _sendMessage(context, textController);
                                  },
                                   onEditingComplete: () => _sendMessage(context, textController), // Gửi khi nhấn nút Send trên bàn phím
                                ),
                              ),
                              const SizedBox(width: 8.0), // Khoảng cách

                              // Nút gửi text (giữ nguyên)
                              IconButton(
                                icon: const Icon(Icons.send),
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(12), // Nút to hơn chút
                                ),
                                onPressed: () => _sendMessage(context, textController),
                              ),
                            ],
                          ),
                        ),
          ],
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
