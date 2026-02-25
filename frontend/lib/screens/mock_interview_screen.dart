import 'package:flutter/material.dart';

import '../services/interview_api.dart';
import '../state/app_state.dart';
import '../widgets/common/state_views.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/logoutView.dart';
import 'interview_review_screen.dart';
import 'interview_session_screen.dart';
import 'interview_setup_screen.dart';

class MockInterviewScreen extends StatefulWidget {
  const MockInterviewScreen({super.key});

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _interviews = [];

  @override
  void initState() {
    super.initState();
    _loadInterviewHistory();
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  String _formatDate(dynamic raw) {
    final parsed = raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
    if (parsed == null) return '-';
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  String _formatDuration(Map<String, dynamic> interview) {
    final started = DateTime.tryParse((interview['startedAt'] ?? '').toString());
    final completed = DateTime.tryParse((interview['completedAt'] ?? '').toString());
    if (started == null || completed == null || completed.isBefore(started)) {
      return '-';
    }

    final diff = completed.difference(started);
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds.remainder(60);
    if (minutes == 0) return '${diff.inSeconds}s';
    return '${minutes}m ${seconds}s';
  }

  Future<void> _loadInterviewHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final interviews = await InterviewApi.getInterviewHistory();
      if (!mounted) return;

      setState(() {
        _interviews = interviews;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load interview history';
        _loading = false;
      });
    }
  }

  Future<void> _deleteInterview(String sessionId) async {
    try {
      await InterviewApi.deleteInterview(sessionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interview deleted')),
      );
      _loadInterviewHistory();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete interview')),
      );
    }
  }

  void _confirmDelete(String sessionId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete interview'),
        content: const Text('This interview history will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteInterview(sessionId);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppState.isLoggedIn) {
      return const Scaffold(body: LoggedOutView());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Interview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInterviewHistory,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mock Interviews',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Practice questions generated from your GitHub projects and track your progress.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.play_circle_fill),
                title: const Text('Start New Mock Interview'),
                subtitle: const Text('Project-based and adaptive'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InterviewSetupScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildHistory()),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_loading) {
      return const CardListSkeleton(itemCount: 5, itemHeight: 92);
    }

    if (_error != null) {
      return AppErrorState(message: _error!, onRetry: _loadInterviewHistory);
    }

    if (_interviews.isEmpty) {
      return const AppEmptyState(
        title: 'No interviews yet',
        subtitle: 'Start your first mock interview to get AI feedback.',
        icon: Icons.mic_none,
      );
    }

    final inProgress = _interviews.where((e) => e['status'] != 'completed').toList();
    final completed = _interviews.where((e) => e['status'] == 'completed').toList();

    return ListView(
      children: [
        if (inProgress.isNotEmpty) ...[
          Text(
            'Continue Your Interviews',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...inProgress.map((raw) {
            final interview = Map<String, dynamic>.from(raw as Map);
            final difficulty = _capitalize((interview['difficulty'] ?? '-').toString());
            final progress = interview['progressText']?.toString() ?? '-';
            final sessionId = interview['_id'].toString();

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.pending_actions_outlined),
                title: Text('$difficulty interview'),
                subtitle: Text('Progress: $progress'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(sessionId);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InterviewSessionScreen(
                        repoIds: const [],
                        difficulty: interview['difficulty']?.toString() ?? 'medium',
                        existingSessionId: sessionId,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        Text(
          'Previous Interviews',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (completed.isEmpty)
          const AppEmptyState(
            title: 'No completed interviews',
            subtitle: 'Complete an interview to see your final analysis.',
            icon: Icons.analytics_outlined,
          )
        else
          ...completed.map((raw) {
            final interview = Map<String, dynamic>.from(raw as Map);
            final score = interview['finalResult']?['overallScore'];
            final difficulty = _capitalize((interview['difficulty'] ?? '-').toString());
            final date = _formatDate(interview['completedAt']);
            final duration = _formatDuration(interview);
            final sessionId = interview['_id'].toString();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  '$difficulty interview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Score: ${score ?? '-'}  |  Date: $date  |  Duration: $duration',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'review') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InterviewReviewScreen(sessionId: sessionId),
                        ),
                      );
                    }
                    if (value == 'delete') {
                      _confirmDelete(sessionId);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'review', child: Text('View Review')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InterviewReviewScreen(sessionId: sessionId),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }
}
