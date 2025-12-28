import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../config/app_config.dart';

class InterviewApi {
  static const baseUrl = '${AppConfig.backendBaseUrl}/interviews';

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

    debugPrint('📡 POST $url');
    debugPrint('📤 Payload: repoIds=$repoIds, difficulty=$difficulty');

    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'repoIds': repoIds, 'difficulty': difficulty}),
    );

    debugPrint('📥 Status: ${res.statusCode}');
    debugPrint('📥 Body: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('startInterview failed (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    if (decoded == null || decoded is! Map<String, dynamic>) {
      throw Exception('Invalid JSON response: ${res.body}');
    }

    final sessionId = decoded['sessionId'];

    if (sessionId == null || sessionId is! String || sessionId.isEmpty) {
      throw Exception('sessionId missing in response: $decoded');
    }

    debugPrint('✅ Interview session created: $sessionId');
    return sessionId;
  }

  // --------------------------------------------------
  // ❓ FIRST QUESTION
  // --------------------------------------------------
  static Future<String> getFirstQuestion(String sessionId) async {
    final url = Uri.parse('$baseUrl/$sessionId/first-question');

    debugPrint('📡 POST $url');

    final res = await http.post(url, headers: _headers());

    debugPrint('📥 Status: ${res.statusCode}');
    debugPrint('📥 Body: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception(
        'getFirstQuestion failed (${res.statusCode}): ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);

    final question = decoded['question'];

    if (question == null || question is! String || question.isEmpty) {
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

    debugPrint('📡 POST $url');
    debugPrint('📤 Answer: $answer');

    final res = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'answer': answer}),
    );

    debugPrint('📥 Status: ${res.statusCode}');
    debugPrint('📥 Body: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('submitAnswer failed (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    if (decoded == null || decoded is! Map<String, dynamic>) {
      throw Exception('Invalid submitAnswer response: ${res.body}');
    }

    return decoded;
  }

  // --------------------------------------------------
  // 🏁 FINAL RESULT
  // --------------------------------------------------
  static Future<Map<String, dynamic>> getFinalResult(String sessionId) async {
    final url = Uri.parse('$baseUrl/$sessionId/final-analysis');

    debugPrint('📡 POST $url');

    final res = await http.post(url, headers: _headers());

    debugPrint('📥 Status: ${res.statusCode}');
    debugPrint('📥 Body: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('getFinalResult failed (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    final result = decoded['finalResult'];

    if (result == null || result is! Map<String, dynamic>) {
      throw Exception('Invalid finalResult response: $decoded');
    }

    return result;
  }
}
