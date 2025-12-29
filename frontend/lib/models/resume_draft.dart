class ProjectResumeData {
  bool included;
  List<String> bulletPoints;

  ProjectResumeData({this.included = false, List<String>? bulletPoints})
    : bulletPoints = bulletPoints ?? [];

  Map<String, dynamic> toJson(String repoName) {
    return {
      'repoName': repoName,
      'included': included,
      'bulletPoints': bulletPoints,
    };
  }
}

class ResumeDraft {
  // ================= PROFILE =================
  Map<String, dynamic> profile = {};

  // ================= SUMMARY =================
  String summary = '';

  // ================= SKILLS =================
  List<String> skills = [];

  // ================= EDUCATION =================
  List<Map<String, dynamic>> education = [];

  // ================= EXPERIENCE =================
  List<Map<String, dynamic>> experience = [];

  // ================= ACHIEVEMENTS =================
  List<String> achievements = [];

  // ================= PROJECTS =================
  Map<String, ProjectResumeData> projects = {};

  // ================= HELPERS =================

  /// Converts draft to a savable JSON structure
  Map<String, dynamic> toJson() {
    return {
      'profile': profile,
      'summary': summary,
      'skills': skills,
      'education': education,
      'experience': experience,
      'achievements': achievements,
      'projects': projects.entries.map((e) => e.value.toJson(e.key)).toList(),
    };
  }

  /// Hydrates draft from backend data
  void loadFromJson(Map<String, dynamic> data) {
    profile = Map<String, dynamic>.from(data['profile'] ?? {});
    summary = data['summary'] ?? '';

    skills
      ..clear()
      ..addAll(List<String>.from(data['skills'] ?? []));

    education
      ..clear()
      ..addAll(List<Map<String, dynamic>>.from(data['education'] ?? []));

    experience
      ..clear()
      ..addAll(List<Map<String, dynamic>>.from(data['experience'] ?? []));

    achievements
      ..clear()
      ..addAll(List<String>.from(data['achievements'] ?? []));

    projects.clear();
    final projectList = data['projects'] as List<dynamic>? ?? [];
    for (final p in projectList) {
      projects[p['repoName']] = ProjectResumeData(
        included: p['included'] ?? false,
        bulletPoints: List<String>.from(p['bulletPoints'] ?? []),
      );
    }
  }
}
