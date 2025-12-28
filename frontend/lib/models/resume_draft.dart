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
  /// Profile fields like phone, location, linkedin, portfolio
  Map<String, dynamic> profile = {};

  /// List of skills
  List<String> skills = [];

  /// ✅ FIXED: education must allow dynamic values
  /// degree, institution, year are strings,
  /// but JSON decoding requires Map<String, dynamic>
  List<Map<String, dynamic>> education = [];

  /// Projects mapped by repo name
  Map<String, ProjectResumeData> projects = {};
}
