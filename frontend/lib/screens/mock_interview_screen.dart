import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/logoutView.dart';
import 'interview_setup_screen.dart';

class MockInterviewScreen extends StatelessWidget {
  const MockInterviewScreen({super.key});

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
            const SizedBox(height: 12),
            const Text(
              'Practice real interview questions based on your GitHub projects.',
            ),
            const SizedBox(height: 24),
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
          ],
        ),
      ),
    );
  }
}
