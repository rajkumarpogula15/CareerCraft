import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../state/app_state.dart';

class GithubApi {
  static final String _base = AppConfig.backendBaseUrl;

  static Future<List<Map<String, dynamic>>> fetchRepos() async {
    print('[GithubApi] fetchRepos() called');

    final token = AppState.jwt;
    if (token == null) {
      throw Exception('User is not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_base/auth/github/repos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('[GithubApi] Status: ${response.statusCode}');
    print('[GithubApi] Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch repos');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Invalid repos format');
    }

    return decoded
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<List<String>> generateResumePoints(String repoName) async {
    print('[GithubApi] generateResumePoints: $repoName');

    final token = AppState.jwt;
    if (token == null) {
      throw Exception('User is not authenticated');
    }

    final response = await http.post(
      Uri.parse('$_base/ai/readme/generate-resume-points'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'repoName': repoName}),
    );

    print('[GithubApi] Status: ${response.statusCode}');
    print('[GithubApi] Body: ${response.body}');

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(decoded['message'] ?? 'Failed');
    }

    final points = decoded['points'];

    if (points is List) {
      return points.map((e) => e.toString()).toList();
    }

    if (points is String) {
      return points
          .split('\n')
          .where((l) => l.trim().startsWith('*'))
          .map(
            (l) =>
                l.replaceFirst('*', '').replaceAll(RegExp(r'\*\*'), '').trim(),
          )
          .toList();
    }

    throw Exception('Invalid points format');
  }
}
