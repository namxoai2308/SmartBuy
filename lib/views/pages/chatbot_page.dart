import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/controllers/chatbot/chatbot_cubit.dart';
import 'package:flutter_ecommerce/controllers/home/home_cubit.dart';
// --- THÊM IMPORT CHO CHAT VỚI ADMIN ---
import 'package:flutter_ecommerce/controllers/chat/chat_cubit.dart'; // Cubit người-người
import 'package:flutter_ecommerce/views/pages/chat/chat_seller_target_waiting_page.dart'; // Trang chờ
// --- KẾT THÚC IMPORT ---
import 'package:flutter_ecommerce/views/widgets/chat/chat_interface_widget.dart'; // UI CHUNG
import 'package:flutter_ecommerce/models/home/product.dart';
import 'dart:io';

class ChatbotPage extends StatelessWidget { // Đổi thành StatelessWidget
  const ChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final String currentUserIdForChatbot = (authState is AuthSuccess) ? authState.user.uid : 'user';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("AI Assistant"), // Đổi tiêu đề nếu muốn
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        foregroundColor: Colors.black,
        actions: [
          // ****** THÊM NÚT CHUYỂN SANG CHAT VỚI ADMIN ******
          IconButton(
            icon: const Icon(Icons.support_agent_outlined), // Icon người hỗ trợ
            tooltip: 'Chat with Human Support',
            onPressed: () {
              // 1. Kiểm tra đăng nhập
              final currentAuthState = context.read<AuthCubit>().state; // Lấy lại state mới nhất
              if (currentAuthState is! AuthSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in to chat with support.')),
                );
                // TODO: Điều hướng đăng nhập nếu cần
                return;
              }
              // 2. Chỉ cho phép Buyer chat với Admin từ đây
              if (currentAuthState.user.role.toLowerCase() != 'buyer') {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Only buyers can initiate support chat.')),
                );
                return;
              }

              // 3. Gọi hàm startChatWithAdmin của ChatCubit (người-người)
              // Không cần truyền context sản phẩm từ đây, vì đang ở màn hình chatbot chung
              context.read<ChatCubit>().startChatWithAdmin();

              // 4. Điều hướng đến trang chờ
              // Trang chờ sẽ lắng nghe ChatCubit (người-người) và chuyển đến SellerChatPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatSellerTargetWaitingPage()),
              );
            },
          ),
          // ************************************************
        ],
      ),
      body: BlocProvider(
        create: (_) {
           final homeState = context.read<HomeCubit>().state;
           final allProductsForChatbot = (homeState is HomeSuccess) ? homeState.allProducts : <Product>[];
           return ChatbotCubit(allProducts: allProductsForChatbot)..sendInitialGreetingIfNeeded();
        },
        child: BlocBuilder<ChatbotCubit, ChatbotState>(
          builder: (context, chatbotState) {
            return ChatInterfaceWidget(
              messages: chatbotState.messages,
              currentUserIdForDisplay: currentUserIdForChatbot,
              isLoading: chatbotState.isLoading,
              error: chatbotState.error,
              onSendMessage: (text, File? imageFile) {
                final cubit = context.read<ChatbotCubit>();
                if (imageFile != null) {
                  cubit.sendImageWithPrompt(text, imageFile);
                } else {
                  cubit.sendMessage(text);
                }
              },
              onPickImage: () async {
                return await context.read<ChatbotCubit>().pickImageFromGallery();
              },
              onClearError: () {
                context.read<ChatbotCubit>().emit(chatbotState.copyWith(clearError: true));
              },
              // Không cần onAppBarBackPressed vì AppBar có nút back riêng
            );
          },
        ),
      ),
    );
  }
}