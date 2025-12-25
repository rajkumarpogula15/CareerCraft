import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../state/app_state.dart';

/// Inline model (no separate models folder needed)
class RecentActivity {
  final String message;
  final DateTime createdAt;

  RecentActivity({required this.message, required this.createdAt});

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ActivityService {
  static Future<List<RecentActivity>> fetchRecent() async {
    final res = await http.get(
      Uri.parse('${AppConfig.backendBaseUrl}/activity/recent'),
      headers: {'Authorization': 'Bearer ${AppState.jwt}'},
    );

    if (res.statusCode != 200) {
      return [];
    }

    final List<dynamic> data = json.decode(res.body);
    return data
        .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
