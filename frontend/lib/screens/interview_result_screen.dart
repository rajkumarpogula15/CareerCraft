import 'package:flutter/material.dart';

import '../services/interview_api.dart';
import '../widgets/common/state_views.dart';
import '../widgets/loading/app_skeleton.dart';

class InterviewResultPopup extends StatelessWidget {
  final String sessionId;

  const InterviewResultPopup({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Result')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: InterviewApi.getFinalResult(sessionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CardListSkeleton(itemCount: 4, itemHeight: 120);
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const AppErrorState(message: 'Could not load interview result');
          }

          final result = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _scoreCard(context, result['overallScore']),
              const SizedBox(height: 20),
              _resultSection(
                context: context,
                title: 'Strengths',
                icon: Icons.check_circle,
                color: Colors.green,
                items: List<String>.from(result['strongAreas'] ?? const []),
              ),
              _resultSection(
                context: context,
                title: 'Needs Improvement',
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                items: List<String>.from(result['weakAreas'] ?? const []),
              ),
              _resultSection(
                context: context,
                title: 'Suggestions',
                icon: Icons.lightbulb_outline,
                color: Colors.blue,
                items: List<String>.from(result['improvements'] ?? const []),
              ),
              const SizedBox(height: 12),
              _difficultyChip(result['suggestedDifficulty']?.toString() ?? 'medium'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _scoreCard(BuildContext context, dynamic score) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Overall Score',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score / 100',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    final list = items.isEmpty ? ['No notes available'] : items;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...list.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('-  '),
                    Expanded(child: Text(e)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _difficultyChip(String difficulty) {
    return Center(
      child: Chip(
        label: Text(
          'Suggested Level: $difficulty',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        avatar: const Icon(Icons.trending_up),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
