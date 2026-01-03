import 'dart:convert';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../config/app_config.dart';

class GithubApi {
  static final String baseUrl = AppConfig.backendBaseUrl;

  // --------------------------------------------------
  // 📦 FETCH USER REPOS
  // --------------------------------------------------
  static Future<List<dynamic>> fetchRepos() async {
    final url = Uri.parse('$baseUrl/auth/github/repos');

    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${AppState.jwt}'},
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

    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${AppState.jwt}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'repos': repos}),
    );

    if (res.statusCode != 200) {
      String message = 'Summarization failed';

      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['error'] != null) {
          message = decoded['error'];
        }
      } catch (_) {
        // ignore parsing errors
      }

      throw Exception(message);
    }
  }
}
