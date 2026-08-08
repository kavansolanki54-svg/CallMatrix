import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService instance = GeminiService._();

  GeminiService._();

  String get _apiKey {
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<String?> generateSummary({
    required String contactName,
    required String phoneNumber,
    required String transcript,
  }) async {
    if (!isConfigured) {
      throw Exception("Gemini API key is not configured in .env file.");
    }

    final model = GenerativeModel(model: 'gemini-flash-latest', apiKey: _apiKey);
    final prompt = '''
Analyze the following call transcript for contact $contactName ($phoneNumber):
"$transcript"

Provide:
1. Short Summary (2-3 sentences)
2. Key Discussion Points (bullet points)  
3. Action Items (bullet points)
4. Sentiment (Positive / Neutral / Negative)
5. Important Keywords
6. Follow-up Suggestions
''';

    final response = await model.generateContent([Content.text(prompt)]);
    return response.text;
  }
}
