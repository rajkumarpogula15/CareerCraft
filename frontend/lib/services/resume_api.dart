import 'dart:convert';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../config/app_config.dart';

class ResumeApi {
  static final String _base = AppConfig.backendBaseUrl;

  /// Fetch saved resume
  static Future<Map<String, dynamic>?> fetchResume() async {
    final token = AppState.jwt;
    if (token == null) {
      throw Exception('User is not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_base/resume'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // No resume exists yet
    if (response.statusCode == 404 || response.body == 'null') {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch resume');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid resume format: expected Map but got ${decoded.runtimeType}',
      );
    }

    return decoded;
  }

  /// Save resume
  static Future<void> saveResume(Map<String, dynamic> resume) async {
    final token = AppState.jwt;
    if (token == null) {
      throw Exception('User is not authenticated');
    }

    final response = await http.post(
      Uri.parse('$_base/resume'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(resume),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save resume');
    }
  }

  static Future<String> generateSummary(Map<String, dynamic> payload) async {
    final token = AppState.jwt;
    if (token == null) {
      throw Exception('User is not authenticated');
    }

    final response = await http.post(
      Uri.parse('$_base/resume/ai-summary'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to generate summary');
    }

    final decoded = jsonDecode(response.body);
    final summary = decoded['summary'];
    if (summary is! String || summary.trim().isEmpty) {
      throw Exception('Invalid summary response');
    }

    return summary.trim();
  }

  static Future<List<String>> suggestSkills(Map<String, dynamic> payload) async {
    final token = AppState.jwt;
    if (token == null) {
      throw Exception('User is not authenticated');
    }

    final response = await http.post(
      Uri.parse('$_base/resume/skill-suggestions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to suggest skills');
    }

    final decoded = jsonDecode(response.body);
    final skills = decoded['skills'];
    if (skills is! List) {
      throw Exception('Invalid skills response');
    }

    return skills.map((item) => item.toString()).toList();
  }
}
