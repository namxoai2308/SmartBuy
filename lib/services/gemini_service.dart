import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const _apiKey = 'AIzaSyA-IfGTYz3t0YDvU89UdtNw3Hnvbu0sFQM';

  final model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
  );

  Future<String> sendMessage(String userMessage) async {
    try {
      final content = [Content.text(userMessage)];
      final response = await model.generateContent(content);
      return response.text ?? 'Bot không có phản hồi.';
    } catch (e) {
      return 'Đã xảy ra lỗi: $e';
    }
  }

  Future<String> analyzeImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);
      final content = [
        Content.multi([
          imagePart,
          TextPart('Hãy mô tả sản phẩm trong ảnh này')
        ])
      ];
      final response = await model.generateContent(content);
      return response.text ?? 'Không mô tả được ảnh.';
    } catch (e) {
      return 'Lỗi khi phân tích ảnh: $e';
    }
  }

  Future<String> analyzeImageWithPrompt(File imageFile, String prompt) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);
      final content = [
        Content.multi([
          imagePart,
          TextPart(prompt),
        ])
      ];
      final response = await model.generateContent(content);
      return response.text ?? 'Không có phản hồi từ Gemini.';
    } catch (e) {
      return 'Lỗi khi gửi ảnh và prompt: $e';
    }
  }
}
