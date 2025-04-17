import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../services/gemini_service.dart';
import 'chatbot_state.dart';

class ChatbotCubit extends Cubit<ChatbotState> {
  final GeminiService _geminiService = GeminiService();
  final List<Product> _allProducts;

  File? _selectedImage; // Ảnh được chọn nhưng chưa gửi

  ChatbotCubit(this._allProducts) : super(ChatbotState.initial());

  // Gửi tin nhắn văn bản
  void sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    emit(state.copyWith(messages: [
      ...state.messages,
      {'role': 'user', 'text': message}
    ]));

    final botReply = await _geminiService.sendMessage(message);

    emit(state.copyWith(messages: [
      ...state.messages,
      {'role': 'bot', 'text': botReply}
    ]));
  }

  // Chọn ảnh từ thư viện và lưu tạm
  Future<File?> pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      _selectedImage = File(picked.path);
      return _selectedImage;
    }
    return null;
  }

  // Gửi ảnh + câu hỏi
  Future<void> sendImageWithPrompt(String prompt) async {
    final image = _selectedImage;
    if (image == null || prompt.trim().isEmpty) return;

    // Gửi tin nhắn của user
    emit(state.copyWith(messages: [
      ...state.messages,
      {
        'role': 'user',
        'text': prompt,
        'imagePath': image.path,
      }
    ]));

    // Gửi ảnh + prompt đến Gemini
    final description = await _geminiService.analyzeImageWithPrompt(image, prompt);

    // Tìm sản phẩm tương tự
    final similarProducts = _findSimilarProducts(description);

    // Bot trả lời
    final botMessages = [
      {'role': 'bot', 'text': 'Mô tả từ ảnh và câu hỏi: $description'},
      if (similarProducts.isEmpty)
        {'role': 'bot', 'text': 'Không tìm thấy sản phẩm nào phù hợp.'}
      else
        {'role': 'bot', 'text': 'Sản phẩm tương tự:\n${similarProducts.join('\n')}'}
    ];

    emit(state.copyWith(messages: [...state.messages, ...botMessages]));

    // Reset ảnh sau khi gửi xong
    _selectedImage = null;
  }

  // Gửi ảnh ngay (KHÔNG có câu hỏi — phiên bản cũ)
  Future<void> sendImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final imageFile = File(picked.path);
    emit(state.copyWith(messages: [...state.messages, {'role': 'user', 'text': '[Đã gửi ảnh]'}]));

    final description = await _geminiService.analyzeImage(imageFile);
    final similarProducts = _findSimilarProducts(description);

    emit(state.copyWith(messages: [
      ...state.messages,
      {'role': 'bot', 'text': 'Mô tả ảnh: $description'},
      if (similarProducts.isEmpty)
        {'role': 'bot', 'text': 'Không tìm thấy sản phẩm nào phù hợp.'}
      else
        {'role': 'bot', 'text': 'Sản phẩm tương tự:\n${similarProducts.join('\n')}'}
    ]));
  }

  // So sánh mô tả để tìm sản phẩm phù hợp
  List<String> _findSimilarProducts(String description) {
    final lowerDesc = description.toLowerCase();

    final matched = _allProducts.where((product) {
      final title = product.title.toLowerCase();
      final productDesc = product.description?.toLowerCase() ?? '';
      final brand = product.brand?.toLowerCase() ?? '';
      return title.contains(lowerDesc) ||
          productDesc.contains(lowerDesc) ||
          brand.contains(lowerDesc);
    }).toList();

    return matched.map((p) => "- ${p.title}").toList();
  }

  // Truy cập ảnh được chọn (dùng trong UI nếu cần hiển thị preview)
  File? get selectedImage => _selectedImage;
}
