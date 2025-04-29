import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/chatbot/chatbot_cubit.dart';
import 'dart:io';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  File? _imagePreview;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessageOrPrompt() {
    final messageText = _textController.text.trim();
    final imageToSend = _imagePreview;

    if (imageToSend != null || messageText.isNotEmpty) {
      final cubit = context.read<ChatbotCubit>();

      if (imageToSend != null) {
        cubit.sendImageWithPrompt(messageText);
      } else {
        cubit.sendMessage(messageText);
      }

      _textController.clear();
      if (mounted) {
        setState(() {
          _imagePreview = null;
        });
      }
      FocusScope.of(context).unfocus();
      _scrollToBottom();
    }
  }

  Future<void> _pickImage() async {
    File? pickedImage = await context.read<ChatbotCubit>().pickImageFromGallery();
    if (pickedImage != null && mounted) {
      setState(() {
        _imagePreview = pickedImage;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.grey.shade200,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, size: 28, color: Colors.black54),
              tooltip: 'Search Products (Not Implemented)',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search function not implemented yet.')),
                );
              },
            ),
          ],
        ),
        body: Container(
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Chatbot",
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: BlocConsumer<ChatbotCubit, ChatbotState>(
                  listener: (context, state) => _scrollToBottom(),
                  builder: (context, state) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                        itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (state.isLoading && index == 0) {
                            return _buildMessageBubble(text: '...', isUser: false);
                          }

                          final reversedIndex = state.messages.length - 1 - (index - (state.isLoading ? 1 : 0));
                          if (reversedIndex < 0 || reversedIndex >= state.messages.length) {
                            return const SizedBox.shrink();
                          }

                          final message = state.messages[reversedIndex];
                          final isUserMessage = message['role'] == 'user';
                          final imagePath = message['imagePath'];

                          if (imagePath != null) {
                            return _buildImageMessageBubble(
                              text: message['text'] ?? '',
                              imagePath: imagePath,
                              isUser: isUserMessage,
                            );
                          } else {
                            return _buildMessageBubble(
                              text: message['text'] ?? '',
                              isUser: isUserMessage,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              BlocSelector<ChatbotCubit, ChatbotState, String?>(
                selector: (state) => state.error,
                builder: (context, error) {
                  if (error == null) return const SizedBox.shrink();
                  return Container(
                    color: Colors.red.shade100,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(error, style: const TextStyle(color: Colors.red))),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, color: Colors.red, size: 18),
                          onPressed: () => context.read<ChatbotCubit>().emit(
                              context.read<ChatbotCubit>().state.copyWith(clearError: true)),
                        )
                      ],
                    ),
                  );
                },
              ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_imagePreview != null) _buildImagePreview(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image_outlined),
                          onPressed: _pickImage,
                          tooltip: 'Select image',
                          color: Theme.of(context).primaryColor,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: _imagePreview == null
                                  ? 'Enter message...'
                                  : 'Add a caption or question...',
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
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessageOrPrompt(),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        IconButton(
                          icon: const Icon(Icons.send),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                          onPressed: _sendMessageOrPrompt,
                        ),
                      ],
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

  Widget _buildMessageBubble({required String text, required bool isUser}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(18),
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
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildImageMessageBubble({required String text, required String imagePath, required bool isUser}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor.withOpacity(0.9) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imagePath),
                width: screenWidth * 0.6,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => Container(
                  height: 150,
                  width: screenWidth * 0.6,
                  color: Colors.grey.shade100,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                ),
              ),
            ),
            if (text.isNotEmpty && text != '[Image Sent]')
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 4, right: 4, bottom: 2),
                child: Text(
                  text,
                  style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final chatbotCubit = context.read<ChatbotCubit>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 50, right: 50),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                _imagePreview!,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.error_outline, color: Colors.red),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _imagePreview = null;
              });
              chatbotCubit.clearSelectedImage();
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          )
        ],
      ),
    );
  }
}
