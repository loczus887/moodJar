import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gemini_models.dart';

class GeminiRepository {
  // Default URL for local development (Android Emulator uses 10.0.2.2 for localhost)
  // If running on a real device, replace with your machine's local IP address
  static const String _baseUrl = 'http://192.168.1.72:3000';

  final String baseUrl;
  final http.Client _client;

  GeminiRepository({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? _baseUrl,
      _client = client ?? http.Client();

  /// Checks if the API is accessible
  Future<bool> checkHealth() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Analyzes diaries and memories using the Gemini API
  Future<GeminiAnalysisResponse> analyze({
    required List<DiaryEntry> diaries,
    List<MemoryEntry> memories = const [],
    AnalysisOptions options = const AnalysisOptions(),
  }) async {
    try {
      final request = GeminiAnalysisRequest(
        diaries: diaries,
        memories: memories,
        options: options,
      );

      final response = await _client.post(
        Uri.parse('$baseUrl/api/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return GeminiAnalysisResponse.fromJson(jsonResponse);
      } else {
        // Handle non-200 responses that might still return a structured error
        try {
          final jsonResponse = jsonDecode(response.body);
          return GeminiAnalysisResponse.fromJson(jsonResponse);
        } catch (_) {
          return GeminiAnalysisResponse(
            success: false,
            error: AnalysisError(
              message: 'HTTP Error: ${response.statusCode}',
              code: 'HTTP_ERROR',
            ),
          );
        }
      }
    } catch (e) {
      return GeminiAnalysisResponse(
        success: false,
        error: AnalysisError(
          message: 'Connection failed: $e',
          code: 'CONNECTION_ERROR',
        ),
      );
    }
  }
}
