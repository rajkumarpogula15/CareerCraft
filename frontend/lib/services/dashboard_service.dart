import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../state/app_state.dart';

class DashboardService {
  static Map<String, String> _headers() => {
    'Authorization': 'Bearer ${AppState.jwt}',
    'Content-Type': 'application/json',
  };

  static Future<Map<String, dynamic>?> fetchDashboard() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/auth/github/dashboard'),
        headers: _headers(),
      );

      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateNotifications(bool enabled) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/auth/github/settings'),
        headers: _headers(),
        body: jsonEncode({'notificationEnabled': enabled}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
