import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../config/app_config.dart';

class GithubApi {
  static const String baseUrl = AppConfig.backendBaseUrl;

  // --------------------------------------------------
  // 📦 FETCH USER REPOS
  // --------------------------------------------------
  static Future<List<dynamic>> fetchRepos() async {
    final url = Uri.parse('$baseUrl/auth/github/repos');

    debugPrint('📡 GET $url');
    debugPrint('🔐 JWT present: ${AppState.jwt != null}');

    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${AppState.jwt}'},
    );

    debugPrint('📥 Status: ${res.statusCode}');
    debugPrint(
      '📥 Body (repos): ${res.body.length > 500 ? res.body.substring(0, 500) + "..." : res.body}',
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load repositories (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! List) {
      throw Exception('Invalid repos response format');
    }

    return decoded;
  }

  // --------------------------------------------------
  // 🧠 SUMMARIZE REPOS
  // --------------------------------------------------
  static Future<void> summarizeRepos(List<Map<String, dynamic>> repos) async {
    final url = Uri.parse('$baseUrl/interviews/summarize-repos');

    debugPrint('📡 POST $url');
    debugPrint('🔐 JWT present: ${AppState.jwt != null}');
    debugPrint('📤 Repo count: ${repos.length}');

    for (final repo in repos) {
      debugPrint('   • Repo payload: $repo');
    }

    final body = jsonEncode({'repos': repos});
    debugPrint('📤 JSON body size: ${body.length} bytes');

    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${AppState.jwt}',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    debugPrint('📥 Status: ${res.statusCode}');
    debugPrint('📥 Raw body: ${res.body}');

    if (res.statusCode != 200) {
      String message = 'Summarization failed';

      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['error'] != null) {
          message = decoded['error'];
        }
      } catch (e) {
        debugPrint('⚠️ Failed to parse error JSON: $e');
      }

      debugPrint('❌ Summarization error message: $message');
      throw Exception(message);
    }

    debugPrint('✅ Summarization completed successfully');
  }
}
