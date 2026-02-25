import 'dart:convert';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../config/app_config.dart';

class InterviewApi {
  static final String baseUrl = '${AppConfig.backendBaseUrl}/interviews';

  static Map<String, String> _headers() => {
    'Authorization': 'Bearer ${AppState.jwt}',
    'Content-Type': 'application/json',
  };

  // --------------------------------------------------
  // 🚀 START INTERVIEW
  // --------------------------------------------------
  static Future<String> startInterview({
    required List<int> repoIds,
    required String difficulty,
  }) async {
    final url = Uri.parse('$baseUrl/start');

    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'repoIds': repoIds, 'difficulty': difficulty}),
    );

    if (res.statusCode != 200) {
      throw Exception('startInterview failed (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    final sessionId = decoded['sessionId'];

    if (sessionId is! String || sessionId.isEmpty) {
      throw Exception('sessionId missing in response: $decoded');
    }

    return sessionId;
  }

  // --------------------------------------------------
  // ❓ FIRST QUESTION
  // --------------------------------------------------
  static Future<String> getFirstQuestion(String sessionId) async {
    final url = Uri.parse('$baseUrl/$sessionId/first-question');

    final res = await http.post(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception(
        'getFirstQuestion failed (${res.statusCode}): ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);

    final question = decoded['question'];

    if (question is! String || question.isEmpty) {
      throw Exception('Invalid question response: $decoded');
    }

    return question;
  }

  // --------------------------------------------------
  // ✍️ SUBMIT ANSWER
  // --------------------------------------------------
  static Future<Map<String, dynamic>> submitAnswer(
    String sessionId,
    String answer,
  ) async {
    final url = Uri.parse('$baseUrl/$sessionId/answer');

    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'answer': answer}),
    );

    if (res.statusCode != 200) {
      throw Exception('submitAnswer failed (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid submitAnswer response: ${res.body}');
    }

    return decoded;
  }

  static Future<Map<String, dynamic>> resumeInterview(String sessionId) async {
    final url = Uri.parse('$baseUrl/$sessionId/resume');

    final res = await http.get(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('resumeInterview failed (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid resumeInterview response: ${res.body}');
    }

    return decoded;
  }

  // --------------------------------------------------
  // 🏁 FINAL RESULT
  // --------------------------------------------------
  static Future<Map<String, dynamic>> getFinalResult(String sessionId) async {
    final url = Uri.parse('$baseUrl/$sessionId/final-analysis');

    final res = await http.post(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('getFinalResult failed (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    final result = decoded['finalResult'];

    if (result is! Map<String, dynamic>) {
      throw Exception('Invalid finalResult response: $decoded');
    }

    return result;
  }

  // ==================================================
  // 🕘 INTERVIEW HISTORY (NEW)
  // ==================================================
  static Future<List<dynamic>> getInterviewHistory() async {
    final url = Uri.parse('$baseUrl/history');

    final res = await http.get(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception(
        'getInterviewHistory failed (${res.statusCode}): ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);

    final interviews = decoded['interviews'];

    if (interviews is! List) {
      throw Exception('Invalid interview history response: $decoded');
    }

    return interviews;
  }

  // ==================================================
  // 📄 INTERVIEW REVIEW (NEW)
  // ==================================================
  static Future<Map<String, dynamic>> getInterviewById(String sessionId) async {
    final url = Uri.parse('$baseUrl/$sessionId');

    final res = await http.get(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception(
        'getInterviewById failed (${res.statusCode}): ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);

    final interview = decoded['interview'];

    if (interview is! Map<String, dynamic>) {
      throw Exception('Invalid interview response: $decoded');
    }

    return interview;
  }

  static Future<void> deleteInterview(String sessionId) async {
    final url = Uri.parse('$baseUrl/$sessionId');
    final res = await http.delete(url, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('deleteInterview failed (${res.statusCode}): ${res.body}');
    }
  }
}
