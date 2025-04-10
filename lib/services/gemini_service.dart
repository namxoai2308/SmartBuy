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
}
