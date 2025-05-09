import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/auth/auth_cubit.dart';
import 'package:flutter_ecommerce/controllers/chat/chat_cubit.dart';
import 'package:flutter_ecommerce/models/chat/conversation_model.dart';
import 'package:flutter_ecommerce/views/pages/chat/seller_chat_page.dart'; // Trang chat chi tiết dùng chung
import 'package:flutter_ecommerce/views/widgets/chat/conversation_tile.dart';

class ConversationListPage extends StatefulWidget {
  const ConversationListPage({Key? key}) : super(key: key);

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {

  @override
  void initState() {
    super.initState();
     // Đảm bảo dữ liệu chat được load cho người dùng hiện tại
     final authState = context.read<AuthCubit>().state;
     if (authState is AuthSuccess) {
        // Gọi lại loadUser để chắc chắn hoặc nếu có logic refresh
        print("ConversationListPage: Ensuring conversations are loaded for ${authState.user.uid}");
        context.read<ChatCubit>().loadUser(authState.user.uid, authState.user.role);
     }
  }


  @override
  Widget build(BuildContext context) {
     final authState = context.watch<AuthCubit>().state;
     final currentUserId = (authState is AuthSuccess) ? authState.user.uid : null;
     final currentUserRole = (authState is AuthSuccess) ? authState.user.role.toLowerCase() : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Messages'), // Tiêu đề chung
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading || state is ChatInitial) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (state is ChatError) {
            return Center(child: Text('Error loading conversations: ${state.message}'));
          } else if (state is ChatConversationsLoaded || state is ChatScreenLoaded || state is ChatScreenLoading) {
             List<ConversationModel> conversations = [];
             if(state is ChatConversationsLoaded) conversations = state.conversations;
             if(state is ChatScreenLoaded) conversations = state.conversations;
             if(state is ChatScreenLoading) conversations = state.conversations;

            if (conversations.isEmpty) {
              return Center(child: Text( currentUserRole == 'buyer' ? 'Chat with support about products.' : 'No customer messages yet.'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                 if (currentUserId != null && currentUserRole != null) {
                    context.read<ChatCubit>().loadUser(currentUserId, currentUserRole);
                 }
              },
              child: ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (context, index) => const Divider(height: 0, indent: 70),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  String otherUserName = 'Chat Partner';
                  String? otherUserAvatar;

                  // Xác định thông tin người kia dựa trên vai trò người dùng hiện tại
                  if (currentUserRole == 'buyer') {
                     otherUserName = conversation.sellerName; // Buyer thấy tên Seller/Admin
                     otherUserAvatar = conversation.sellerAvatar;
                  } else if (currentUserRole == 'seller' || currentUserRole == 'admin') {
                     otherUserName = conversation.buyerName; // Seller/Admin thấy tên Buyer
                     otherUserAvatar = conversation.buyerAvatar;
                  } else {
                     // Fallback nếu role không xác định
                     final otherId = conversation.participantIds.firstWhere((id) => id != currentUserId, orElse: ()=> '');
                     if (otherId == conversation.buyerId) {
                         otherUserName = conversation.buyerName; otherUserAvatar = conversation.buyerAvatar;
                     } else { // Giả định người còn lại là seller/admin
                         otherUserName = conversation.sellerName; otherUserAvatar = conversation.sellerAvatar;
                     }
                  }

                  return ConversationTile(
                    conversation: conversation,
                    otherUserName: otherUserName,
                    otherUserAvatar: otherUserAvatar,
                    onTap: () {
                      context.read<ChatCubit>().openChatScreen(conversation);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Điều hướng đến SellerChatPage (trang chi tiết dùng chung)
                          builder: (_) => SellerChatPage(conversationId: conversation.id),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          } else {
            return const Center(child: Text('Something went wrong.'));
          }
        },
      ),
    );
  }
}