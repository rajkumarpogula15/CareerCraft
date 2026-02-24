import 'package:flutter/material.dart';

import '../services/github_api.dart';
import '../widgets/loading/app_skeleton.dart';
import 'interview_session_screen.dart';

class InterviewSetupScreen extends StatefulWidget {
  const InterviewSetupScreen({super.key});

  @override
  State<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends State<InterviewSetupScreen> {
  List<Map<String, dynamic>> repos = [];
  final Set<int> selectedRepoIds = {};
  String difficulty = 'medium';

  bool loading = true;
  bool summarizing = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRepos();
  }

  Future<void> _loadRepos() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final data = await GithubApi.fetchRepos();
      if (!mounted) return;

      setState(() {
        repos = data
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load repositories';
        loading = false;
      });
    }
  }

  Future<void> _startInterview() async {
    if (selectedRepoIds.length < 2 || selectedRepoIds.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select 2-4 repositories')),
      );
      return;
    }

    setState(() {
      summarizing = true;
      errorMessage = null;
    });

    try {
      final selectedRepos = repos
          .where((r) => selectedRepoIds.contains(r['id']))
          .map(
            (r) => {
              'id': r['id'],
              'name': r['name'],
              'description': r['description'],
              'updated_at': r['updated_at'],
            },
          )
          .toList();

      await GithubApi.summarizeRepos(selectedRepos);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InterviewSessionScreen(
            repoIds: selectedRepoIds.toList(),
            difficulty: difficulty,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        summarizing = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return const Scaffold(body: CardListSkeleton(itemCount: 6, itemHeight: 74));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Interview Setup'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Let\'s get you ready',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose repositories and difficulty to generate a personalized interview session.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Select Repositories',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick 2-4 projects to be interviewed on',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ...repos.map(
                  (repo) => _RepoCard(
                    repo: repo,
                    selected: selectedRepoIds.contains(repo['id']),
                    disabled: summarizing,
                    onTap: () {
                      setState(() {
                        selectedRepoIds.contains(repo['id'])
                            ? selectedRepoIds.remove(repo['id'])
                            : selectedRepoIds.add(repo['id']);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Difficulty',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How challenging should the interview be?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'easy', label: Text('Easy')),
                    ButtonSegment(value: 'medium', label: Text('Medium')),
                    ButtonSegment(value: 'hard', label: Text('Hard')),
                  ],
                  selected: {difficulty},
                  onSelectionChanged: summarizing
                      ? null
                      : (val) => setState(() => difficulty = val.first),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: summarizing ? null : _startInterview,
                  child: summarizing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Preparing interview...'),
                          ],
                        )
                      : const Text(
                          'Start Interview',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepoCard extends StatelessWidget {
  final Map<String, dynamic> repo;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _RepoCard({
    required this.repo,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repo['name'],
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        repo['description'] ?? 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
