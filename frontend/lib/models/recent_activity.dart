class RecentActivity {
  final String repoName;
  final String message;
  final String type;
  final DateTime createdAt;

  RecentActivity({
    required this.repoName,
    required this.message,
    required this.type,
    required this.createdAt,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      repoName: json['repoName'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
