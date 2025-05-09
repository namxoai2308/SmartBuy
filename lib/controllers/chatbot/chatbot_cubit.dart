import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Cho Timestamp

// --- Đảm bảo các đường dẫn models và services là đúng ---
import '../../models/home/product.dart'; // Giữ lại nếu _findSimilarProducts dùng
import '../../models/chat/message_model.dart'; // SỬ DỤNG MESSAGE MODEL CHUNG
import '../../services/gemini_service.dart';
// ------------------------------------------------------

part 'chatbot_state.dart'; // Liên kết với file state (sẽ được sửa ở bước tiếp theo)

class ChatbotCubit extends Cubit<ChatbotState> {
  final GeminiService _geminiService = GeminiService();
  final List<Product> _allProducts;
  // Không cần _selectedImage ở đây nữa, File sẽ được truyền trực tiếp vào hàm send

  ChatbotCubit({required List<Product> allProducts})
      : _allProducts = allProducts,
        super(ChatbotState.initial()) {
    print("ChatbotCubit initialized. Product count: ${_allProducts.length}");
    if (_allProducts.isEmpty) {
      print("ChatbotCubit Warning: Initialized with an empty product list.");
    }
    // sendInitialGreetingIfNeeded(); // Có thể gọi ở đây
  }

  void sendInitialGreetingIfNeeded() {
    if (state.messages.isEmpty) { // Kiểm tra xem đã có tin nhắn nào chưa
      final initialMessage = MessageModel(
        senderId: 'chatbot',
        text: "Hello! How can I assist you with our products today?",
        timestamp: Timestamp.now(),
      );
      emit(state.copyWith(messages: [initialMessage]));
    }
  }

  @override
  void emit(ChatbotState state) {
    if (isClosed) return;
    super.emit(state);
  }

  Future<void> sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;

    final userMessage = MessageModel(
      senderId: 'user', // Hoặc ID người dùng hiện tại nếu bạn muốn phân biệt user nào chat với bot
      text: trimmedMessage,
      timestamp: Timestamp.now(),
    );

    // Cập nhật state với tin nhắn của người dùng và trạng thái loading
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      messages: List.from(state.messages)..add(userMessage), // Thêm vào list hiện tại
    ));

    try {
      final botReplyText = await _geminiService.sendMessage(trimmedMessage);
      final botMessage = MessageModel(
        senderId: 'chatbot',
        text: botReplyText,
        timestamp: Timestamp.now(),
      );
      // Cập nhật state với tin nhắn của bot
      emit(state.copyWith(
        isLoading: false,
        messages: List.from(state.messages)..add(botMessage),
      ));
    } catch (e) {
      print("Error sending message to Gemini: $e");
      final errorMessage = MessageModel(
        senderId: 'chatbot',
        text: 'Sorry, I encountered an error. Please try again.',
        timestamp: Timestamp.now(),
      );
      emit(state.copyWith(
        isLoading: false,
        error: "Failed to get response: ${e.toString()}",
        messages: List.from(state.messages)..add(errorMessage),
      ));
    }
  }

  // Hàm chọn ảnh, chỉ trả về File?, không lưu vào state của Cubit nữa
  Future<File?> pickImageFromGallery() async {
    emit(state.copyWith(clearError: true)); // Xóa lỗi cũ nếu có
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        print("ChatbotCubit: Image picked from gallery: ${picked.path}");
        return File(picked.path); // Trả về File object
      } else {
        print("ChatbotCubit: Image picking cancelled.");
        return null;
      }
    } catch (e) {
      print("Error picking image: $e");
      emit(state.copyWith(error: "Failed to pick image: ${e.toString()}"));
      return null;
    }
  }

  // Hàm gửi ảnh và prompt, nhận File làm tham số
  Future<void> sendImageWithPrompt(String prompt, File imageFile) async {
    final trimmedPrompt = prompt.trim();

    final userMessageWithImage = MessageModel(
      senderId: 'user', // Hoặc ID người dùng hiện tại
      text: trimmedPrompt.isNotEmpty ? trimmedPrompt : "[Image Analysis Request]", // Text cho tin nhắn user
      timestamp: Timestamp.now(),
      localImagePath: imageFile.path, // Lưu đường dẫn ảnh local để UI hiển thị
    );

    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      messages: List.from(state.messages)..add(userMessageWithImage),
    ));

    try {
      final description = await _geminiService.analyzeImageWithPrompt(imageFile, trimmedPrompt);
      print("ChatbotCubit: Gemini analysis result: $description");
      final similarProducts = _findSimilarProducts(description);
      print("ChatbotCubit: Found similar products: ${similarProducts.length}");

      final List<MessageModel> botResponseMessages = [];

      // (Tùy chọn) Gửi lại ảnh mà bot đã phân tích, cùng với mô tả
      // botResponseMessages.add(MessageModel(
      //   senderId: 'chatbot',
      //   text: 'Here is what I see: $description',
      //   timestamp: Timestamp.now(),
      //   // Nếu Gemini trả về URL ảnh đã xử lý, bạn có thể dùng imageUrl ở đây
      // ));


      if (similarProducts.isEmpty) {
        botResponseMessages.add(MessageModel(
            senderId: 'chatbot',
            text: 'Sorry, I couldn\'t find any similar products based on the image${trimmedPrompt.isNotEmpty ? ' and your query' : ''}.',
            timestamp: Timestamp.now()));
      } else {
        botResponseMessages.add(MessageModel(
            senderId: 'chatbot',
            text: 'Based on the image${trimmedPrompt.isNotEmpty ? ' and your query' : ''}, here are some products you might like:',
            timestamp: Timestamp.now()));
        // Tạo một tin nhắn riêng cho danh sách sản phẩm để dễ xử lý hiển thị nếu cần
        // Hoặc bạn có thể tạo một loại MessageModel đặc biệt cho danh sách sản phẩm
        botResponseMessages.add(MessageModel(
            senderId: 'chatbot',
            text: similarProducts.join('\n\n'), // Dùng \n\n để dễ đọc hơn
            timestamp: Timestamp.now()));
      }

      emit(state.copyWith(
        isLoading: false,
        messages: List.from(state.messages)..addAll(botResponseMessages),
      ));
    } catch (e) {
      print("Error sending image with prompt: $e");
      final errorMessage = MessageModel(
        senderId: 'chatbot',
        text: 'Sorry, an error occurred while processing your request with the image.',
        timestamp: Timestamp.now(),
      );
      emit(state.copyWith(
        isLoading: false,
        error: "Failed to process the image and prompt: ${e.toString()}",
        messages: List.from(state.messages)..add(errorMessage),
      ));
    }
  }

  // Hàm tìm sản phẩm tương tự (logic giữ nguyên)
  List<String> _findSimilarProducts(String description) {
    if (description.trim().isEmpty) return [];
    final lowerDesc = description.toLowerCase();
    final descriptionWords = lowerDesc
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .split(' ')
        .where((word) => word.length > 2)
        .toSet()
        .toList();
    if (descriptionWords.isEmpty) {
      print("ChatbotCubit: No meaningful keywords found in description.");
      return [];
    }
    print("ChatbotCubit: Keywords from description: $descriptionWords");

    const validBrands = [
      'adidas', 'cartier', 'gucci', 'h&m', 'levi\'s', 'nike', 'prada', 'zara'
    ];
    const validCategories = ['clothing', 'shoes', 'jewelry'];

    final matched = _allProducts.where((product) {
      final title = product.title.toLowerCase();
      final productDesc = product.description?.toLowerCase() ?? '';
      final category = product.category.toLowerCase();
      final brand = product.brand?.toLowerCase() ?? '';
      final isValidBrand = validBrands.any((b) => brand.contains(b));
      final isValidCategory = validCategories.any((c) => category.contains(c));
      final matchesDescription = descriptionWords.any((keyword) =>
        title.contains(keyword) ||
        productDesc.contains(keyword) ||
        category.contains(keyword) ||
        brand.contains(keyword)
      );
      return isValidBrand && isValidCategory && matchesDescription;
    }).toList();

    print("ChatbotCubit: Matched products count: ${matched.length}");
    final limitedResults = matched.take(5).toList();
    return limitedResults.map((p) {
      final titlePrice = "- ${p.title} (\$${p.price.toStringAsFixed(2)})";
      final productDescription = p.description?.trim();
      if (productDescription != null && productDescription.isNotEmpty) {
        final shortDesc = productDescription.length > 100
            ? '${productDescription.substring(0, 100)}...'
            : productDescription;
        return "$titlePrice\n  Desc: $shortDesc";
      } else {
        return titlePrice;
      }
    }).toList();
  }

  // Không cần các hàm clearSelectedImage hoặc selectedImage getter nữa
  // vì UI sẽ quản lý File preview và truyền vào sendImageWithPrompt

  @override
  Future<void> close() {
    print("ChatbotCubit closing.");
    return super.close();
  }
}