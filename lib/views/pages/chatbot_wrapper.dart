import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ecommerce/controllers/chatbot/chatbot_cubit.dart';
import 'package:flutter_ecommerce/models/home/product.dart';
import 'chatbot_page.dart';

class ChatbotWrapper extends StatelessWidget {
  final List<Product> products;

  const ChatbotWrapper({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatbotCubit(allProducts: products),
      child: const ChatbotPage(),
    );
  }
}
