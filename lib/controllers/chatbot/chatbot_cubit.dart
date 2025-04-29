import 'dart:async'; // Có thể cần cho StreamSubscription nếu dùng sau này
import 'dart:io';    // Cho File
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Cho @immutable
import 'package:image_picker/image_picker.dart';
// --- Đảm bảo các đường dẫn models và services là đúng ---
import '../../models/product.dart';
import '../../services/gemini_service.dart';
// ------------------------------------------------------

part 'chatbot_state.dart'; // Liên kết với file state

class ChatbotCubit extends Cubit<ChatbotState> {
  final GeminiService _geminiService = GeminiService(); // Service gọi API Gemini
  final List<Product> _allProducts; // Danh sách sản phẩm để tìm kiếm
  File? _selectedImage; // Ảnh đang được chọn để gửi kèm prompt

  // Constructor: yêu cầu danh sách sản phẩm và khởi tạo state ban đầu
  ChatbotCubit({required List<Product> allProducts})
      : _allProducts = allProducts,
        super(ChatbotState.initial()) { // Gọi super với factory initial() của state
     print("ChatbotCubit initialized. Product count: ${_allProducts.length}");
     if (_allProducts.isEmpty) {
       print("ChatbotCubit Warning: Initialized with an empty product list.");
     }
  }

  // Ghi đè hàm emit để thêm log hoặc kiểm tra (tùy chọn)
  @override
  void emit(ChatbotState state) {
    if (isClosed) return; // Không emit nếu cubit đã đóng
    // print("ChatbotCubit Emitting State: ${state.runtimeType}"); // Debug
    super.emit(state);
  }

  // Hàm gửi tin nhắn văn bản (không có ảnh)
  Future<void> sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return; // Bỏ qua tin nhắn rỗng

    // Lấy danh sách tin nhắn hiện tại từ state
    final currentMessages = List<Map<String, String>>.from(state.messages);

    // Emit state mới: thêm tin nhắn user và bật loading, xóa lỗi cũ
    emit(state.copyWith(
      isLoading: true,
      clearError: true, // Sử dụng flag clearError trong copyWith của state
      messages: [
        ...currentMessages,
        {'role': 'user', 'text': trimmedMessage}
      ],
    ));

    try {
      // Gọi API Gemini để lấy phản hồi
      final botReply = await _geminiService.sendMessage(trimmedMessage);
      // Lấy lại danh sách tin nhắn mới nhất từ state (quan trọng vì state có thể đã thay đổi)
      final updatedMessages = List<Map<String, String>>.from(state.messages);
      // Emit state mới: thêm tin nhắn bot và tắt loading
      emit(state.copyWith(
        isLoading: false,
        messages: [
          ...updatedMessages,
          {'role': 'bot', 'text': botReply}
        ],
      ));
    } catch (e) {
      // Xử lý lỗi khi gọi API
      print("Error sending message to Gemini: $e");
      final updatedMessages = List<Map<String, String>>.from(state.messages);
      emit(state.copyWith(
        isLoading: false,
        error: "Failed to get response: ${e.toString()}",
        messages: [
          ...updatedMessages,
          {'role': 'bot', 'text': 'Sorry, I encountered an error. Please try again.'}
        ],
      ));
    }
  }

  // Hàm chỉ chọn ảnh từ thư viện và lưu vào _selectedImage
  Future<File?> pickImageFromGallery() async {
    _selectedImage = null; // Reset ảnh đang chọn trước khi mở picker
    emit(state.copyWith(clearError: true)); // Xóa lỗi cũ nếu có
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        _selectedImage = File(picked.path); // Lưu ảnh đã chọn vào biến tạm
        print("ChatbotCubit: Image picked and stored: ${_selectedImage?.path}");
        return _selectedImage; // Trả về File để UI hiển thị preview
      } else {
         print("ChatbotCubit: Image picking cancelled.");
         return null; // Người dùng hủy
      }
    } catch (e) {
       print("Error picking image: $e");
       emit(state.copyWith(error: "Failed to pick image: ${e.toString()}"));
       return null; // Có lỗi
    }
  }

  // Hàm gửi ảnh ĐÃ CHỌN (_selectedImage) cùng với prompt (text)
  Future<void> sendImageWithPrompt(String prompt) async {
    final image = _selectedImage; // Lấy ảnh đã được chọn ở bước pickImageFromGallery
    final trimmedPrompt = prompt.trim(); // Prompt có thể rỗng

    // Kiểm tra xem có ảnh được chọn chưa
    if (image == null) {
      emit(state.copyWith(error: "Please select an image before sending."));
      return;
    }

    // Lấy danh sách tin nhắn hiện tại
    final currentMessages = List<Map<String, String>>.from(state.messages);

    // Emit state mới: thêm tin nhắn user (gồm text và path ảnh) và bật loading
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      messages: [
        ...currentMessages,
        {
          'role': 'user',
          'text': trimmedPrompt, // Prompt người dùng nhập (có thể rỗng)
          'imagePath': image.path  // Đường dẫn ảnh để UI hiển thị
        }
      ],
    ));

    // --- QUAN TRỌNG: Reset _selectedImage NGAY SAU KHI DÙNG ---
    // Để tránh việc ảnh này bị gửi lại ở lần gửi tin nhắn tiếp theo nếu người dùng chỉ nhập text
    _selectedImage = null;
    // -------------------------------------------------------

    try {
      // Gọi API Gemini để phân tích ảnh và prompt
      final description = await _geminiService.analyzeImageWithPrompt(image, trimmedPrompt);
      print("ChatbotCubit: Gemini analysis result: $description");

      // Tìm sản phẩm tương tự dựa trên mô tả
      final similarProducts = _findSimilarProducts(description);
      print("ChatbotCubit: Found similar products: ${similarProducts.length}");

      // Chuẩn bị tin nhắn trả lời từ bot
      final botMessages = <Map<String, String>>[];
      // Có thể thêm tin nhắn chứa mô tả nếu muốn
      // botMessages.add({'role': 'bot', 'text': 'Analysis: $description'});

      if (similarProducts.isEmpty) {
        botMessages.add({'role': 'bot', 'text': 'Sorry, I couldn\'t find any similar products based on that.'});
      } else {
         botMessages.add({'role': 'bot', 'text': 'Based on the image${trimmedPrompt.isNotEmpty ? ' and your query' : ''}, here are some similar products:'});
         botMessages.add({'role': 'bot', 'text': similarProducts.join('\n')}); // Gộp kết quả
      }

      // Lấy lại state messages mới nhất
      final updatedMessages = List<Map<String, String>>.from(state.messages);
      // Emit state cuối cùng: thêm tin nhắn bot và tắt loading
      emit(state.copyWith(
          isLoading: false,
          messages: [...updatedMessages, ...botMessages]
      ));

    } catch (e) {
      // Xử lý lỗi khi gọi API hoặc tìm sản phẩm
      print("Error sending image with prompt: $e");
      final updatedMessages = List<Map<String, String>>.from(state.messages);
      emit(state.copyWith(
        isLoading: false,
        error: "Failed to process the image and prompt: ${e.toString()}",
        messages: [
          ...updatedMessages,
          {'role': 'bot', 'text': 'Sorry, an error occurred while processing your request.'}
        ],
      ));
    }
  }

  // --- HÀM sendImageFromGallery ĐÃ BỊ XÓA HOẶC COMMENT ---
  // Future<void> sendImageFromGallery() async { /* ... */ }
  // -------------------------------------------------

  // Hàm tìm sản phẩm tương tự
    // Hàm tìm sản phẩm tương tự - Đã cải thiện
      // Hàm tìm sản phẩm tương tự - Trả về cả mô tả
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

  // --- Khai báo danh sách brand và category hợp lệ ---
  const validBrands = [
    'adidas', 'cartier', 'gucci', 'h&m', 'levi\'s', 'nike', 'prada', 'zara'
  ];
  const validCategories = ['clothing', 'shoes', 'jewelry'];

  // --- Lọc sản phẩm ---
  final matched = _allProducts.where((product) {
    final title = product.title.toLowerCase();
    final productDesc = product.description?.toLowerCase() ?? '';
    final category = product.category.toLowerCase();
    final brand = product.brand?.toLowerCase() ?? '';

    // Lọc mạnh theo brand và category hợp lệ
    final isValidBrand = validBrands.any((b) => brand.contains(b));
    final isValidCategory = validCategories.any((c) => category.contains(c));

    // Lọc bổ sung theo từ khóa mô tả
    final matchesDescription = descriptionWords.any((keyword) =>
      title.contains(keyword) ||
      productDesc.contains(keyword) ||
      category.contains(keyword) ||
      brand.contains(keyword)
    );

    return isValidBrand && isValidCategory && matchesDescription;
  }).toList();

  print("ChatbotCubit: Matched products count: ${matched.length}");

  // --- Giới hạn số kết quả ---
  final limitedResults = matched.take(5).toList();

  // --- Định dạng kết quả trả về ---
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


  // Getter để UI có thể truy cập ảnh đang được chọn (nếu cần)
  File? get selectedImage => _selectedImage;

  // Hàm để UI xóa ảnh đã chọn (ví dụ: nhấn nút 'x' trên preview)
  void clearSelectedImage() {
    if (_selectedImage != null) {
      print("ChatbotCubit: Clearing selected image.");
      _selectedImage = null;
      // Không cần emit state ở đây trừ khi UI cần biết ảnh đã bị xóa
      // emit(state.copyWith());
    }
  }

  // Đóng các tài nguyên khi Cubit không còn dùng
  @override
  Future<void> close() {
    print("ChatbotCubit closing.");
    // Hủy StreamSubscriptions nếu có
    return super.close();
  }
}