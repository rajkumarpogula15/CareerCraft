import 'package:flutter/material.dart';

import '../services/interview_api.dart';
import '../state/app_state.dart';
import '../widgets/common/state_views.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/logoutView.dart';
import 'interview_review_screen.dart';
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
    final started = DateTime.tryParse(
      (interview['startedAt'] ?? '').toString(),
    );
    final completed = DateTime.tryParse(
      (interview['completedAt'] ?? '').toString(),
    );
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
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Practice real interview questions generated from your GitHub projects.',
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
            const SizedBox(height: 24),
            Text(
              'Previous Interviews',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildHistory()),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_loading) {
      return const CardListSkeleton(itemCount: 5, itemHeight: 78);
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

    return ListView.builder(
      itemCount: _interviews.length,
      itemBuilder: (context, index) {
        final interview = Map<String, dynamic>.from(_interviews[index] as Map);
        final score = interview['finalResult']?['overallScore'];
        final difficulty = _capitalize(
          (interview['difficulty'] ?? '-').toString(),
        );
        final date = _formatDate(interview['completedAt']);
        final duration = _formatDuration(interview);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.history),
            title: Text(
              '$difficulty interview',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Score: ${score ?? '-'}  |  Date: $date  |  Duration: $duration',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      InterviewReviewScreen(sessionId: interview['_id']),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
