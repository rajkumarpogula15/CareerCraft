import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../state/app_state.dart';

/// Inline model (extended, still no separate models folder)
class RecentActivity {
  final String message;
  final String repoName;
  final String type;
  final DateTime createdAt;

  RecentActivity({
    required this.message,
    required this.repoName,
    required this.type,
    required this.createdAt,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      message: json['message'] as String? ?? '',
      repoName: json['repoName'] as String? ?? '',
      type: json['type'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ActivityService {
  /// Fetch last 5 recent activities for the user
  static Future<List<RecentActivity>> fetchRecent() async {
    try {
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
    } catch (_) {
      // Fail silently – home screen should never crash
      return [];
    }
  }
}
