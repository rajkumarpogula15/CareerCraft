import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../services/activity_service.dart';
import '../widgets/home_header.dart';
import '../widgets/workspace_section.dart';
import '../widgets/continue_session_card.dart';
import '../widgets/smart_suggestions_section.dart';
import '../widgets/home_footer.dart';
import '../utils/iterable_ext.dart';

class LoggedInView extends StatefulWidget {
  const LoggedInView({super.key});

  @override
  State<LoggedInView> createState() => _LoggedInViewState();
}

class _LoggedInViewState extends State<LoggedInView> {
  List<RecentActivity> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('[LoggedInView] initState');
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    debugPrint('[LoggedInView] Loading recent activities...');
    try {
      final data = await ActivityService.fetchRecent();

      if (!mounted) return;

      debugPrint('[LoggedInView] Activities loaded: ${data.length}');

      setState(() {
        _activities = data;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('[LoggedInView] Failed to load activities: $e');
      debugPrint(st.toString());

      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[LoggedInView] build');

    final user = AppState.user;
    if (user == null) {
      debugPrint('[LoggedInView] user is null');
      return const Center(child: Text("Failed to load profile"));
    }

    /// Safely extract username
    final String owner =
        user['username'] ?? user['login'] ?? user['name'] ?? 'unknown';

    debugPrint('[LoggedInView] current user = $owner');

    /// Latest repo chat activity
    final repoChat = _activities
        .where((a) => a.type == 'repo_chat')
        .firstOrNull();

    if (repoChat == null) {
      debugPrint('[LoggedInView] No repo_chat activity found');
    } else {
      debugPrint('[LoggedInView] repo_chat found → repo=${repoChat.repoName}');
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeader(),
          const SizedBox(height: 8),
          const WorkspaceSection(),
          const SizedBox(height: 4),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CircularProgressIndicator(),
            )
          else if (repoChat != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ContinueSessionCard(
                repoName: repoChat.repoName,
                owner: owner,
                lastQuestion: 'Continue from where we paused',
                type: 'RepoBot',
              ),
            ),

          const SizedBox(height: 4),

          const SmartSuggestionsSection(
            suggestions: [
              "Your repo has no README — generate one?",
              "Want updated documentation?",
              "Create a repo showcase summary?",
            ],
          ),

          const SizedBox(height: 12),
          const HomeFooter(),
        ],
      ),
    );
  }
}
