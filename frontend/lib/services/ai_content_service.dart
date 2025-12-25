import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../config/app_config.dart';

class AIContentService {
  static const _timeout = Duration(seconds: 20);

  static Map<String, String> get _headers {
    final token = AppState.jwt;

    debugPrint(
      '[AIContentService] JWT present: ${token != null && token.isNotEmpty}',
    );

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// ================================
  /// Generates AI-powered social post
  /// ================================
  static Future<String> generateSocialPost({
    required String repoName,
    String platform = 'LinkedIn',
  }) async {
    debugPrint('-------------------------------');
    debugPrint('[AIContentService] generateSocialPost START');
    debugPrint('[AIContentService] repoName: $repoName');
    debugPrint('[AIContentService] platform: $platform');

    final uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/ai/readme/generate-social-post',
    );

    debugPrint('[AIContentService] POST $uri');

    final payload = {'repoName': repoName, 'platform': platform};

    debugPrint('[AIContentService] Payload: $payload');
    debugPrint('[AIContentService] Headers: $_headers');

    http.Response response;

    try {
      response = await http
          .post(uri, headers: _headers, body: jsonEncode(payload))
          .timeout(_timeout);
    } on SocketException catch (e) {
      debugPrint('[AIContentService] ❌ SocketException');
      debugPrint(e.toString());
      throw Exception('No internet connection');
    } on HttpException catch (e) {
      debugPrint('[AIContentService] ❌ HttpException');
      debugPrint(e.toString());
      throw Exception('HTTP error');
    } on FormatException catch (e) {
      debugPrint('[AIContentService] ❌ FormatException');
      debugPrint(e.toString());
      throw Exception('Invalid request format');
    } catch (e, st) {
      debugPrint('[AIContentService] ❌ Unknown exception');
      debugPrint(e.toString());
      debugPrint(st.toString());
      rethrow;
    }

    debugPrint('[AIContentService] Status Code: ${response.statusCode}');
    debugPrint('[AIContentService] Raw Response: ${response.body}');

    if (response.statusCode != 200) {
      final errorMessage = _extractError(response);
      debugPrint('[AIContentService] ❌ Backend Error: $errorMessage');
      throw Exception(errorMessage);
    }

    if (response.body.isEmpty) {
      debugPrint('[AIContentService] ❌ Empty response body');
      throw Exception('Empty server response');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      debugPrint('[AIContentService] ❌ JSON decode failed');
      debugPrint(e.toString());
      throw Exception('Invalid JSON from server');
    }

    debugPrint('[AIContentService] Decoded JSON: $decoded');

    final post = decoded['post'];

    if (post == null || post.toString().trim().isEmpty) {
      debugPrint('[AIContentService] ❌ "post" field missing or empty');
      throw Exception('AI response missing post content');
    }

    debugPrint('[AIContentService] ✅ Post generated successfully');
    debugPrint('-------------------------------');

    return post.toString();
  }

  /// ================================
  /// Generates ATS resume bullet points
  /// ================================
  static Future<String> generateResumePoints({required String repoName}) async {
    debugPrint('[AIContentService] generateResumePoints START');

    final uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/ai/readme/generate-resume-points',
    );

    http.Response response;

    try {
      response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({'repoName': repoName}),
          )
          .timeout(_timeout);
    } on SocketException {
      throw Exception('No internet connection');
    }

    debugPrint('[AIContentService] Status Code: ${response.statusCode}');
    debugPrint('[AIContentService] Raw Response: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final decoded = jsonDecode(response.body);
    final points = decoded['points'];

    if (points == null || points.toString().trim().isEmpty) {
      throw Exception('AI response missing resume points');
    }

    return points.toString();
  }

  /// ================================
  /// Safe backend error extraction
  /// ================================
  static String _extractError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['message'] ??
          body['error'] ??
          'Request failed (${response.statusCode})';
    } catch (_) {
      return 'Request failed (${response.statusCode})';
    }
  }
}
