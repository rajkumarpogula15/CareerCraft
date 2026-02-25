import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/interview_api.dart';
import '../widgets/common/state_views.dart';
import '../widgets/loading/app_skeleton.dart';

class InterviewResultPopup extends StatefulWidget {
  final String sessionId;

  const InterviewResultPopup({super.key, required this.sessionId});

  @override
  State<InterviewResultPopup> createState() => _InterviewResultPopupState();
}

class _InterviewResultPopupState extends State<InterviewResultPopup> {
  late final Future<Map<String, dynamic>> _resultFuture;

  @override
  void initState() {
    super.initState();
    _resultFuture = InterviewApi.getFinalResult(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Result')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _resultFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CardListSkeleton(itemCount: 4, itemHeight: 120);
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const AppErrorState(message: 'Could not load interview result');
          }

          final result = snapshot.data!;
          final score = (result['overallScore'] as num?)?.toInt() ?? 0;
          final celebrate = score >= 80;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _scoreCard(context, score, celebrate),
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
              ),
              if (celebrate) const IgnorePointer(child: _CelebrationOverlay()),
            ],
          );
        },
      ),
    );
  }

  Widget _scoreCard(BuildContext context, int score, bool celebrate) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            celebrate ? Colors.green.shade600 : theme.colorScheme.primary,
            celebrate
                ? Colors.green.shade400
                : theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            celebrate ? 'Outstanding performance' : 'Overall Score',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
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

class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return CustomPaint(
          painter: _ConfettiPainter(progress: value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Colors.amber,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.pink,
    ];

    final paint = Paint()..style = PaintingStyle.fill;
    final count = 36;
    for (int i = 0; i < count; i++) {
      final t = i / count;
      final x = (size.width * t) + (math.sin((progress * 10) + i) * 12);
      final startY = -20 - (i % 5) * 10;
      final endY = size.height * (0.55 + (i % 3) * 0.12);
      final y = startY + ((endY - startY) * progress);

      paint.color = colors[i % colors.length].withValues(alpha: 1 - progress * 0.75);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 7, height: 11),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
