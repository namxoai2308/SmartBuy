import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/models/chat/message_model.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatInterfaceWidget extends StatefulWidget {
  final List<MessageModel> messages;
  final String currentUserIdForDisplay;
  final bool isLoading;
  final String? error;
  final Function(String text, File? image) onSendMessage;
  final Future<File?> Function()? onPickImage;
  final VoidCallback? onClearError;

  const ChatInterfaceWidget({
    Key? key,
    required this.messages,
    required this.currentUserIdForDisplay,
    required this.isLoading,
    this.error,
    required this.onSendMessage,
    this.onPickImage,
    this.onClearError,
  }) : super(key: key);

  @override
  State<ChatInterfaceWidget> createState() => _ChatInterfaceWidgetState();
}

class _ChatInterfaceWidgetState extends State<ChatInterfaceWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  File? _imagePreview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (widget.messages.isNotEmpty) _scrollToBottom(jump: true);
    });
  }

  @override
  void didUpdateWidget(covariant ChatInterfaceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length || widget.isLoading != oldWidget.isLoading) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    print("ChatInterfaceWidget: _handleSendMessage called."); // DEBUG
    final messageText = _textController.text.trim();
    if (_imagePreview != null || messageText.isNotEmpty) {
       print("ChatInterfaceWidget: Calling widget.onSendMessage with text: '$messageText', image: ${_imagePreview?.path ?? 'null'}"); // DEBUG
      widget.onSendMessage(messageText, _imagePreview);
      _textController.clear();
      if (mounted) {
        setState(() {
          _imagePreview = null;
        });
      }
      FocusScope.of(context).unfocus();
    } else {
       print("ChatInterfaceWidget: _handleSendMessage - Nothing to send."); // DEBUG
    }
  }

  Future<void> _handlePickImage() async {
    if (widget.onPickImage != null) {
      File? pickedImage = await widget.onPickImage!();
      if (pickedImage != null && mounted) {
        setState(() {
          _imagePreview = pickedImage;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom({bool jump = false}) {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (_scrollController.hasClients) {
            final targetScroll = _scrollController.position.minScrollExtent;
            if (jump) {
              _scrollController.jumpTo(targetScroll);
            } else {
              _scrollController.animateTo(targetScroll, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
            }
         }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
            itemCount: widget.messages.length + (widget.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (widget.isLoading && index == 0) {
                return _buildMessageBubble(
                    message: MessageModel( senderId: 'system_loading', text: '...', timestamp: Timestamp.now()),
                    isUser: false);
              }
              final messageIndex = widget.messages.length - 1 - (index - (widget.isLoading ? 1 : 0));
              if (messageIndex < 0 || messageIndex >= widget.messages.length) {
                return const SizedBox.shrink();
              }
              final message = widget.messages[messageIndex];
              final isUserMessage = message.senderId == widget.currentUserIdForDisplay;
              return _buildMessageBubble(message: message, isUser: isUserMessage);
            },
          ),
        ),
        if (widget.error != null && widget.onClearError != null)
          _buildErrorBanner(widget.error!, widget.onClearError!),
        _buildInputArea(), // Gọi hàm build input area
      ],
    );
  }

  Widget _buildMessageBubble({required MessageModel message, required bool isUser}) {
    // ... (Code _buildMessageBubble đã sửa lỗi const ở padding timestamp) ...
     final screenWidth = MediaQuery.of(context).size.width;
     Widget content;
     bool hasImage = false;
     final formattedTime = DateFormat('hh:mm a').format(message.timestamp.toDate());

     if (message.localImagePath != null) {
       hasImage = true;
       content = ClipRRect(/* ... Image.file ... */);
     } else if (message.imageUrl != null) {
       hasImage = true;
       content = ClipRRect(/* ... Image.network ... */);
     } else {
       content = SelectableText(message.text, /* ... */);
     }

     return Align(
       alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
       child: Container(
         constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
         margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
         padding: hasImage ? const EdgeInsets.all(6) : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
         decoration: BoxDecoration(/* ... */),
         child: Column(
           crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
           mainAxisSize: MainAxisSize.min,
           children: [
             content,
             if (hasImage && message.text.isNotEmpty && (!message.text.startsWith("[Image") || message.text.length > 15))
               Padding(
                 padding: const EdgeInsets.only(top: 6.0, left: 4, right: 4, bottom: 2),
                 child: SelectableText(message.text, /* ... */),
               ),
             Padding(
               padding: EdgeInsets.only( // <-- Bỏ const
                   top: 4.0,
                   left: hasImage ? 4 : 0,
                   right: hasImage ? 4 : 0
               ),
               // *************************
               child: Text(formattedTime, /* ... */),
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildErrorBanner(String errorText, VoidCallback onClear) {
    // ... (Code _buildErrorBanner giữ nguyên) ...
    return MaterialBanner(
      content: Text(errorText),
      backgroundColor: Colors.red.shade100,
      actions: [ TextButton(onPressed: onClear, child: const Text('DISMISS')) ],
    );
  }

  Widget _buildImagePreviewWidget() {
    // ... (Code _buildImagePreviewWidget giữ nguyên, đảm bảo Stack đúng) ...
     if (_imagePreview == null) return const SizedBox.shrink();
     return Padding(
       padding: const EdgeInsets.only(bottom: 8.0, left: 50, right: 50),
       child: Stack(
         alignment: Alignment.topRight,
         children: [ /* ... Container, Image, InkWell ... */ ],
       ),
     );
  }

  // Hàm build khu vực input, sử dụng ValueListenableBuilder cho nút Send
  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(offset: const Offset(0, -1), blurRadius: 4, color: Colors.black.withOpacity(0.05))]
      ),
      padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImagePreviewWidget(), // Hiển thị ảnh preview
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Nút chọn ảnh
              if (widget.onPickImage != null)
                IconButton(
                    icon: Icon(Icons.image_outlined, color: Theme.of(context).primaryColor ?? Colors.blue),
                    onPressed: _handlePickImage,
                    tooltip: 'Select image',
                 ),
              // Ô nhập text
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: _imagePreview == null ? 'Enter message...' : 'Add a caption...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  ),
                  minLines: 1, maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) { // Gửi khi nhấn Enter/Send trên bàn phím
                    // Chỉ gửi nếu nút send đang bật (có text hoặc ảnh)
                     final canSendNow = _textController.text.trim().isNotEmpty || _imagePreview != null;
                     if(canSendNow) _handleSendMessage();
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              // Nút gửi (sử dụng ValueListenableBuilder)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textController,
                builder: (context, textValue, _) {
                   // Nút được bật khi có text HOẶC có ảnh preview
                   final bool canSend = textValue.text.trim().isNotEmpty || _imagePreview != null;
                   return IconButton(
                     icon: const Icon(Icons.send),
                     style: IconButton.styleFrom(
                       backgroundColor: Theme.of(context).primaryColor ?? Colors.blue,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.all(12),
                     ),
                     // onPressed chỉ gọAi _handleSendMessage nếu canSend là true
                     onPressed: canSend ? _handleSendMessage : null,
                   );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}