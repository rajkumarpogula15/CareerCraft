import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../state/app_state.dart';

class ProfileApi {
  static final String _base = AppConfig.backendBaseUrl;

  /// Fetch logged-in user profile
  static Future<Map<String, dynamic>?> fetchProfile() async {
    print('[ProfileApi] fetchProfile() called');

    final token = AppState.jwt;
    if (token == null) {
      throw Exception('User is not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_base/auth/github/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('[ProfileApi] Status: ${response.statusCode}');
    print('[ProfileApi] Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch profile');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid profile format');
    }

    return decoded;
  }
}
