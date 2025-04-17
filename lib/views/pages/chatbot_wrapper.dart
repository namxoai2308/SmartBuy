import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/chatbot/chatbot_cubit.dart';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_ecommerce/services/firestore_services.dart';
import 'chatbot_page.dart';

class ChatbotWrapper extends StatelessWidget {
  final String uid;
  const ChatbotWrapper({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: FirestoreServices.instance.newProductsStream(uid), // Đã sửa ở đây
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final products = snapshot.data!;
        return BlocProvider(
          create: (_) => ChatbotCubit(products),
          child: const ChatbotPage(),
        );
      },
    );
  }
}


