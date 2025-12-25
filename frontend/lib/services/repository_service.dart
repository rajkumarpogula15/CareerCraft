import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../config/app_config.dart';

class RepositoryService {
  /// ⭐ TOGGLE FAVOURITE REPOSITORY
  static Future<void> toggleFavourite(Map<String, dynamic> repo) async {
    final token = AppState.jwt;

    if (token == null) {
      debugPrint('❌ No JWT token found');
      throw Exception('User not authenticated');
    }

    final repoId = repo['id'];

    final url = '${AppConfig.backendBaseUrl}/repositories/$repoId/favourite';

    debugPrint('🌐 POST $url');
    debugPrint('📦 Payload: ${jsonEncode(repo)}');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(repo),
    );

    debugPrint('🌐 Status Code: ${response.statusCode}');
    debugPrint('🌐 Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle favourite');
    }

    debugPrint('✅ Favourite toggled successfully');
  }

  /// ⭐ FETCH FAVOURITE REPOSITORIES
  static Future<List<dynamic>> fetchFavourites() async {
    final token = AppState.jwt;

    if (token == null) {
      debugPrint('❌ No JWT token found');
      throw Exception('User not authenticated');
    }

    final url = '${AppConfig.backendBaseUrl}/repositories/favourites';

    debugPrint('🌐 GET $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint('🌐 Status Code: ${response.statusCode}');
    debugPrint('🌐 Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch favourites');
    }

    final List<dynamic> data = jsonDecode(response.body);
    debugPrint('✅ Fetched ${data.length} favourite repositories');

    return data;
  }
}
