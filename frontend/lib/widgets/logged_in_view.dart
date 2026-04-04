import 'package:flutter/material.dart';
import '../services/activity_service.dart';
import '../services/github_api.dart';
import '../state/app_state.dart';
import '../utils/iterable_ext.dart';
import 'continue_session_card.dart';
import 'home_footer.dart';
import 'home_header.dart';
import 'loading/app_skeleton.dart';
import 'readme_preview_sheet.dart';
import 'smart_suggestions_section.dart';
import 'workspace_section.dart';

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

class SmartSuggestionService {
  static List<SmartSuggestion> generate(List<Repo> repos) {
    if (repos.isEmpty) return const [];

    final sorted = [...repos]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final withoutReadme = sorted.where((r) => !r.hasReadme).toList();
    final primary = sorted.first;
    final secondary = sorted.length > 1 ? sorted[1] : sorted.first;
    final tertiary = sorted.length > 2 ? sorted[2] : sorted.first;

    return [
      SmartSuggestion(
        label:
            'Generate a professional README for ${withoutReadme.isNotEmpty ? withoutReadme.first.name : primary.name}.',
        repoName: withoutReadme.isNotEmpty
            ? withoutReadme.first.name
            : primary.name,
        action: SuggestionAction.readmeGeneration,
      ),
      SmartSuggestion(
        label:
            'Ask ${primary.name} assistant for repository-specific guidance.',
        repoName: primary.name,
        action: SuggestionAction.repoChat,
      ),
      SmartSuggestion(
        label: 'Create a social post showcasing ${secondary.name}.',
        repoName: secondary.name,
        action: SuggestionAction.socialPost,
      ),
      SmartSuggestion(
        label: 'Generate ATS-ready resume points from ${tertiary.name}.',
        repoName: tertiary.name,
        action: SuggestionAction.resumePoints,
      ),
    ];
  }
}

class LoggedInView extends StatefulWidget {
  final VoidCallback? onOpenProfile;

  const LoggedInView({super.key, this.onOpenProfile});

  @override
  State<LoggedInView> createState() => _LoggedInViewState();
}

class _LoggedInViewState extends State<LoggedInView>
    with SingleTickerProviderStateMixin {
  List<RecentActivity> _activities = [];
  List<SmartSuggestion> _smartSuggestions = [];
  bool _loadingActivities = true;
  bool _loadingSuggestions = true;

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

  Future<void> _loadActivities() async {
    try {
      final data = await ActivityService.fetchRecent();
      if (!mounted) return;
      setState(() {
        _activities = data;
        _loadingActivities = false;
      });
      _fadeController.forward();
    } catch (_) {
      if (mounted) setState(() => _loadingActivities = false);
    }
  }

  Future<void> _loadSmartSuggestions() async {
    try {
      final repoJson = await GithubApi.fetchRepos();
      final repos = repoJson
          .map<Repo>((e) => Repo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final suggestions = SmartSuggestionService.generate(repos);
      if (!mounted) return;
      setState(() {
        _smartSuggestions = suggestions;
        _loadingSuggestions = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

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
      return const Center(child: Text('Failed to load profile'));
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
          HomeHeader(onTap: widget.onOpenProfile),
          const SizedBox(height: 10),
          if (_loadingSuggestions)
            const AppSkeleton(child: SuggestionSectionSkeleton())
          else
            FadeTransition(
              opacity: _fadeAnimation,
              child: SmartSuggestionsSection(
                owner: owner,
                suggestions: _smartSuggestions,
                onGenerateReadme: (repoName) =>
                    _showReadmeGenerator(repoName, owner),
              ),
            ),
          const SizedBox(height: 10),
          if (_loadingActivities)
            const AppSkeleton(child: ContinueSessionSkeleton())
          else if (repoChat != null)
            FadeTransition(
              opacity: _fadeAnimation,
              child: ContinueSessionCard(
                repoName: repoChat.repoName,
                owner: owner,
                lastQuestion: 'Continue from where we paused',
                type: 'RepoBot',
              ),
            ),
          const SizedBox(height: 8),
          const WorkspaceSection(),
          const HomeFooter(),
        ],
      ),
    );
  }
}
