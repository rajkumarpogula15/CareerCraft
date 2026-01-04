import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/logoutView.dart';
import '../services/interview_api.dart';
import 'interview_setup_screen.dart';
import 'interview_review_screen.dart';

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

  Future<void> _loadInterviewHistory() async {
    try {
      final interviews = await InterviewApi.getInterviewHistory();
      setState(() {
        _interviews = interviews;
        _loading = false;
      });
    } catch (e) {
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
      appBar: AppBar(title: const Text('Mock Interview')),
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
            const Text(
              'Practice real interview questions based on your GitHub projects.',
            ),
            const SizedBox(height: 24),

            /// ▶️ Start New Interview
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.play_circle_fill),
                title: const Text('Start New Mock Interview'),
                subtitle: const Text('Project-based, adaptive'),
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

            const SizedBox(height: 32),

            /// 🕘 History Section
            Text(
              'Previous Interviews',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(child: _buildHistory()),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_interviews.isEmpty) {
      return const Center(
        child: Text(
          'No interviews yet.\nStart your first mock interview!',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _interviews.length,
      itemBuilder: (context, index) {
        final interview = _interviews[index];
        final score = interview['finalResult']?['overallScore'];

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.history),
            title: Text(
              'Difficulty: ${interview['difficulty'].toString().toUpperCase()}',
            ),
            subtitle: Text(
              score != null ? 'Final Score: $score' : 'Completed interview',
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
