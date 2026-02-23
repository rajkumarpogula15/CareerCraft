import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../services/activity_service.dart';
import '../widgets/home_header.dart';
import '../widgets/workspace_section.dart';
import '../widgets/continue_session_card.dart';
import '../widgets/smart_suggestions_section.dart';
import '../widgets/home_footer.dart';
import '../utils/iterable_ext.dart';
import '../config/app_config.dart';
import '../widgets/readme_preview_sheet.dart';

import '../widgets/loading/repo_skeleton.dart';
import '../widgets/loading/section_skeleton.dart';

/// ---------------------------------------------------------------------------
/// Repo model
/// ---------------------------------------------------------------------------
class Repo {
  final int id;
  final String name;
  final String? description;
  final bool hasReadme;
  final DateTime updatedAt;

  Repo({
    required this.id,
    required this.name,
    required this.description,
    required this.hasReadme,
    required this.updatedAt,
  });

  factory Repo.fromJson(Map<String, dynamic> json) {
    return Repo(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      hasReadme: json['has_readme'] ?? false,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Repo service
/// ---------------------------------------------------------------------------
class RepoService {
  static Future<List<Repo>> fetchUserRepos() async {
    final token = AppState.jwt;

    if (token == null) throw Exception('JWT missing');

    final res = await http.get(
      Uri.parse('${AppConfig.backendBaseUrl}/auth/github/repos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load repos');
    }

    final List data = jsonDecode(res.body);

    return data.map((e) => Repo.fromJson(e)).toList();
  }
}

/// ---------------------------------------------------------------------------
/// Smart suggestion engine
/// ---------------------------------------------------------------------------
class SmartSuggestionService {
  static List<String> generate(List<Repo> repos) {
    final now = DateTime.now();
    final List<String> suggestions = [];

    for (final repo in repos) {
      if (suggestions.length >= 4) break;

      final inactivityDays = now.difference(repo.updatedAt).inDays;

      if (!repo.hasReadme) {
        suggestions.add('"${repo.name}" has no README — generate one?');
        continue;
      }

      if (inactivityDays > 30) {
        suggestions.add(
          '"${repo.name}" inactive for $inactivityDays days — review it with RepoBot?',
        );
      }
    }

    return suggestions;
  }
}

/// ---------------------------------------------------------------------------
/// LoggedInView
/// ---------------------------------------------------------------------------
class LoggedInView extends StatefulWidget {
  const LoggedInView({super.key});

  @override
  State<LoggedInView> createState() => _LoggedInViewState();
}

class _LoggedInViewState extends State<LoggedInView>
    with SingleTickerProviderStateMixin {
  /// 🔧 TEST MODE: Change to false in production
  static const bool _debugDelay = true;

  List<RecentActivity> _activities = [];
  List<String> _rawSmartSuggestions = [];

  bool _loadingActivities = true;
  bool _loadingSuggestions = true;

  String? _pendingReadmeRepo;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _loadActivities();
    _loadSmartSuggestions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// ---------------- Load Activities ----------------
  Future<void> _loadActivities() async {
    try {
      // 🔴 Artificial delay for testing
      if (_debugDelay) {
        await Future.delayed(const Duration(seconds: 3));
      }

      final data = await ActivityService.fetchRecent();

      if (!mounted) return;

      setState(() {
        _activities = data;
        _loadingActivities = false;
      });

      _fadeController.forward();
    } catch (_) {
      if (mounted) {
        setState(() => _loadingActivities = false);
      }
    }
  }

  /// ---------------- Load Suggestions ----------------
  Future<void> _loadSmartSuggestions() async {
    try {
      // 🔴 Artificial delay for testing
      if (_debugDelay) {
        await Future.delayed(const Duration(seconds: 3));
      }

      final repos = await RepoService.fetchUserRepos();

      final suggestions = SmartSuggestionService.generate(repos);

      if (!mounted) return;

      setState(() {
        _rawSmartSuggestions = suggestions;
        _loadingSuggestions = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingSuggestions = false);
      }
    }
  }

  /// Convert backend text → UI model
  List<SmartSuggestion> get _smartSuggestionsUI {
    return _rawSmartSuggestions.map((text) {
      final match = RegExp(r'"([^"]+)"').firstMatch(text);
      final repoName = match?.group(1);

      final isReadme = text.toLowerCase().contains('readme');

      if (isReadme) {
        _pendingReadmeRepo = repoName;
      }

      return SmartSuggestion(
        label: text,
        repoName: repoName,
        action: isReadme
            ? SuggestionAction.readmeGeneration
            : SuggestionAction.repoChat,
      );
    }).toList();
  }

  /// README launcher
  void _showReadmeGenerator(String repoName, String owner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ReadmePreviewSheet(
        repoName: repoName,
        owner: owner,
        description: '',
        language: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.user;

    if (user == null) {
      return const Center(child: Text("Failed to load profile"));
    }

    final owner =
        user['username'] ?? user['login'] ?? user['name'] ?? 'unknown';

    final repoChat = _activities
        .where((a) => a.type == 'repo_chat')
        .firstOrNull();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeader(),
          const WorkspaceSection(),

          /// ---------------- Activities ----------------
          if (_loadingActivities)
            const SectionSkeleton(count: 2)
          else
            FadeTransition(
              opacity: _fadeAnimation,
              child: repoChat != null
                  ? ContinueSessionCard(
                      repoName: repoChat.repoName,
                      owner: owner,
                      lastQuestion: 'Continue from where we paused',
                      type: 'RepoBot',
                    )
                  : const SizedBox(),
            ),

          /// ---------------- Suggestions ----------------
          if (_loadingSuggestions)
            const SectionSkeleton(count: 3)
          else
            FadeTransition(
              opacity: _fadeAnimation,
              child: _smartSuggestionsUI.isNotEmpty
                  ? SmartSuggestionsSection(
                      owner: owner,
                      suggestions: _smartSuggestionsUI,
                      onGenerateReadme: () {
                        if (_pendingReadmeRepo == null) return;

                        _showReadmeGenerator(_pendingReadmeRepo!, owner);
                      },
                    )
                  : const SizedBox(),
            ),

          const HomeFooter(),
        ],
      ),
    );
  }
}
