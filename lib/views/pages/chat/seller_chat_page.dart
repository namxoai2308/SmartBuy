import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/controllers/chat/chat_cubit.dart'; // ChatCubit người-người
import 'package:flutter_ecommerce/models/chat/conversation_model.dart'; // Cần để lấy tên người chat
import 'package:flutter_ecommerce/views/widgets/chat/chat_interface_widget.dart'; // UI CHUNG
// import 'dart:io'; // Không cần File cho chat người-người (trừ khi bạn thêm gửi ảnh)
import 'package:flutter_ecommerce/models/chat/message_model.dart';

class SellerChatPage extends StatelessWidget {
  final String conversationId; // Nhận ID cuộc trò chuyện với Seller

  const SellerChatPage({Key? key, required this.conversationId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    // ID của người dùng hiện tại, dùng để xác định tin nhắn "của tôi"
    final currentUserId = (authState is AuthSuccess) ? authState.user.uid : '';
    final currentUserRole = (authState is AuthSuccess) ? authState.user.role.toLowerCase() : '';


    // Đảm bảo ChatCubit (người-người) được cung cấp ở một widget cha
    // và đã gọi openChatScreen(conversation) trước khi điều hướng đến trang này.
    // Nếu không, bạn cần xử lý việc load conversation ở đây.
    // Ví dụ, nếu ChatCubit chưa load đúng conversation:
    final chatCubit = context.read<ChatCubit>();
    final currentChatState = chatCubit.state;
    bool shouldCallOpenChat = true;
    if (currentChatState is ChatScreenLoaded && currentChatState.currentConversation.id == conversationId) {
        shouldCallOpenChat = false;
    } else if (currentChatState is ChatScreenLoading && currentChatState.currentConversation.id == conversationId) {
        shouldCallOpenChat = false;
    }

    if (shouldCallOpenChat) {
        // Tìm conversation trong danh sách đã load hoặc fetch mới
        ConversationModel? conversationToOpen;
        if (chatCubit.state is ChatConversationsLoaded) {
            try {
                conversationToOpen = (chatCubit.state as ChatConversationsLoaded)
                    .conversations
                    .firstWhere((c) => c.id == conversationId);
            } catch (e) { /* không tìm thấy */ }
        }
        // Bạn có thể cần fetch conversation nếu không có trong list
        // Hoặc dựa vào việc màn hình trước đó phải đảm bảo conversation đã được set trong ChatCubit
        if (conversationToOpen != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ModalRoute.of(context)?.isCurrent ?? false) { // Đảm bảo trang còn active
                    chatCubit.openChatScreen(conversationToOpen!);
                }
            });
        } else {
            // Xử lý trường hợp không tìm thấy conversation, có thể pop hoặc hiển thị lỗi
            print("SellerChatPage: Conversation $conversationId not found in loaded list. Consider fetching or ensuring it's opened before navigating.");
            // return Scaffold(body: Center(child: Text("Could not load chat.")));
        }
    }


    return BlocBuilder<ChatCubit, ChatState>( // Lắng nghe ChatCubit người-người
      builder: (context, chatState) {
        String appBarTitle = "Chat"; // Default
        List<MessageModel> messagesToShow = [];
        bool isLoadingChat = true; // Mặc định là loading
        String? chatError;

        if (chatState is ChatScreenLoaded && chatState.currentConversation.id == conversationId) {
          isLoadingChat = false;
          messagesToShow = chatState.messages;
          final conversation = chatState.currentConversation;
          // Xác định tên người kia để hiển thị trên AppBar
          if (currentUserRole == 'buyer') {
            appBarTitle = conversation.sellerName;
          } else if (currentUserRole == 'seller') {
            appBarTitle = conversation.buyerName;
          } else { // Fallback
             appBarTitle = conversation.participantIds.firstWhere((id) => id != currentUserId, orElse: () => "Chat");
             if (appBarTitle == conversation.buyerId) appBarTitle = conversation.buyerName;
             if (appBarTitle == conversation.sellerId) appBarTitle = conversation.sellerName;
          }
        } else if (chatState is ChatScreenLoading && chatState.currentConversation.id == conversationId) {
          isLoadingChat = true;
          final conversation = chatState.currentConversation;
          if (currentUserRole == 'buyer') appBarTitle = conversation.sellerName;
          else if (currentUserRole == 'seller') appBarTitle = conversation.buyerName;
          else {
             appBarTitle = conversation.participantIds.firstWhere((id) => id != currentUserId, orElse: () => "Chat");
             if (appBarTitle == conversation.buyerId) appBarTitle = conversation.buyerName;
             if (appBarTitle == conversation.sellerId) appBarTitle = conversation.sellerName;
          }
        } else if (chatState is ChatError) {
          isLoadingChat = false;
          chatError = chatState.message;
        } else if (chatState is ChatInitial || chatState is ChatConversationsLoaded) {
            // State này không nên là state cuối cùng khi ở màn hình chat chi tiết
            // Vẫn hiển thị loading và chờ openChatScreen được gọi lại (nếu cần)
            isLoadingChat = true;
        }


        return Scaffold(
          // AppBar đã được tích hợp vào ChatInterfaceWidget (nếu bạn muốn)
          // Hoặc bạn có thể giữ AppBar ở đây và không truyền onAppBarBackPressed cho ChatInterfaceWidget
          appBar: AppBar(
            title: Text(appBarTitle),
            backgroundColor: Colors.white,
            elevation: 1,
            foregroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.read<ChatCubit>().closeChatScreen(); // Báo cho cubit
                Navigator.of(context).pop();
              },
            ),
          ),
          body: ChatInterfaceWidget(
            messages: messagesToShow,
            currentUserIdForDisplay: currentUserId,
            isLoading: isLoadingChat,
            error: chatError,
            onSendMessage: (text, _) { // Chat người-người hiện tại chưa gửi ảnh
              context.read<ChatCubit>().sendMessage(text);
            },
            onPickImage: null, // Không có chức năng chọn ảnh cho chat người-người (hiện tại)
            onClearError: null, // ChatCubit (người-người) không có clearError riêng
          ),
        );
      },
    );
  }
}