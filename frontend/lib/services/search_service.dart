import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../state/app_state.dart';

class SearchService {
  static Future<Map<String, dynamic>> globalSearch(String query) async {
    if (query.trim().isEmpty) {
      return {'repos': [], 'chats': [], 'interviews': []};
    }

    final uri = Uri.parse('${AppConfig.backendBaseUrl}/auth/github/search?q=${Uri.encodeQueryComponent(query)}');
    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${AppState.jwt}'},
    );

    if (res.statusCode != 200) {
      throw Exception('Search failed');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid search response');
    }
    return decoded;
  }
}
