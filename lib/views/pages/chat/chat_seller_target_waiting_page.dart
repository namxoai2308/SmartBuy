import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/chat/chat_cubit.dart'; // Import ChatCubit người-người
import 'package:flutter_ecommerce/views/pages/chat/seller_chat_page.dart'; // Import trang chat chính
import 'package:flutter_ecommerce/models/chat/message_model.dart';

// Widget này hoạt động như một màn hình trung gian để chờ ChatCubit
// sẵn sàng trước khi điều hướng đến màn hình chat thực sự.
class ChatSellerTargetWaitingPage extends StatelessWidget {
  const ChatSellerTargetWaitingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // BlocListener lắng nghe sự thay đổi state của ChatCubit
    return BlocListener<ChatCubit, ChatState>(
      // Lắng nghe tất cả các state để xử lý lỗi và điều hướng
      listener: (context, state) {
        print("ChatSellerTargetWaitingPage Listener received state: ${state.runtimeType}"); // Debug state

        // Khi ChatCubit đã load xong màn hình chat (có messages)
        // hoặc đang trong quá trình load màn hình chat (có currentConversation)
        if (state is ChatScreenLoaded || state is ChatScreenLoading) {
          String conversationIdToOpen = "";
          // Lấy conversationId từ state hiện tại
          if (state is ChatScreenLoaded) {
            conversationIdToOpen = state.currentConversation.id;
          } else if (state is ChatScreenLoading) {
            conversationIdToOpen = state.currentConversation.id;
          }

          // Kiểm tra xem trang chờ này có còn active trên cây widget không
          // và conversationId có hợp lệ không trước khi điều hướng
          if (ModalRoute.of(context)?.isCurrent ?? false) {
            if (conversationIdToOpen.isNotEmpty) {
              print("Navigating to SellerChatPage with conversationId: $conversationIdToOpen");
              // Thay thế màn hình chờ bằng màn hình chat thực sự.
              // pushReplacement ngăn người dùng nhấn back quay lại màn hình chờ.
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => SellerChatPage(conversationId: conversationIdToOpen),
                ),
              );
            } else {
              // Trường hợp hiếm gặp: state đúng nhưng conversationId rỗng
              print("Error: Conversation ID is empty in ChatScreenLoaded/Loading state.");
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Could not open chat. Invalid ID.")));
              if (Navigator.canPop(context)) Navigator.pop(context); // Quay lại
            }
          } else {
             print("ChatSellerTargetWaitingPage is no longer current route. Skipping navigation.");
          }
        }
        // Nếu có lỗi xảy ra trong quá trình load chat
        else if (state is ChatError) {
          print("ChatSellerTargetWaitingPage received ChatError: ${state.message}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error connecting to chat: ${state.message}")),
          );
          // Tự động quay lại trang trước nếu có lỗi
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
        // Các state khác như ChatInitial, ChatLoading, ChatConversationsLoaded
        // sẽ được bỏ qua bởi listener này, màn hình chờ sẽ tiếp tục hiển thị.
      },
      // Giao diện của màn hình chờ
      child: const Scaffold(
        backgroundColor: Colors.white, // Hoặc màu nền phù hợp
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator.adaptive(
                // valueColor: AlwaysStoppedAnimation<Color>(Colors.red), // Tùy chọn màu
              ),
              SizedBox(height: 20),
              Text(
                "Connecting to support...", // Hoặc "Loading chat..."
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}