import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/interview_api.dart';
import 'interview_setup_screen.dart';
import '../widgets/common/state_views.dart';
import '../widgets/loading/app_skeleton.dart';

class InterviewResultPopup extends StatefulWidget {
  final String sessionId;

  const InterviewResultPopup({super.key, required this.sessionId});

  @override
  State<InterviewResultPopup> createState() => _InterviewResultPopupState();
}

class _InterviewResultPopupState extends State<InterviewResultPopup> {
  late final Future<_InterviewStoryData> _storyFuture;

  @override
  void initState() {
    super.initState();
    _storyFuture = _loadStory();
  }

  Future<_InterviewStoryData> _loadStory() async {
    final resultFuture = InterviewApi.getFinalResult(widget.sessionId);
    final sessionFuture = InterviewApi.getInterviewById(widget.sessionId);
    final historyFuture = InterviewApi.getInterviewHistory();

    final values = await Future.wait([
      resultFuture,
      sessionFuture,
      historyFuture,
    ]);

    final result = values[0] as Map<String, dynamic>;
    final session = values[1] as Map<String, dynamic>;
    final history = List<dynamic>.from(values[2] as List);

    return _InterviewStoryData(
      result: result,
      session: session,
      history: history,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Result')),
      body: FutureBuilder<_InterviewStoryData>(
        future: _storyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CardListSkeleton(itemCount: 4, itemHeight: 120);
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const AppErrorState(message: 'Could not load interview result');
          }

          final story = snapshot.data!;
          final result = story.result;
          final score = (result['overallScore'] as num?)?.toInt() ?? 0;
          final celebrate = score >= 80;
          final strengths = List<String>.from(result['strongAreas'] ?? const []);
          final weakAreas = List<String>.from(result['weakAreas'] ?? const []);
          final improvements = List<String>.from(result['improvements'] ?? const []);

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _scoreCard(context, story, score, celebrate),
                  const SizedBox(height: 20),
                  _comparisonCard(context, story, score),
                  const SizedBox(height: 16),
                  _confidenceCard(context, story),
                  const SizedBox(height: 16),
                  _insightRow(
                    context,
                    leftTitle: 'Strengths',
                    leftIcon: Icons.check_circle_outline,
                    leftColor: Colors.green,
                    leftItems: strengths,
                    rightTitle: 'Weak Spots',
                    rightIcon: Icons.trending_down_rounded,
                    rightColor: Colors.orange,
                    rightItems: weakAreas,
                  ),
                  const SizedBox(height: 16),
                  _resultSection(
                    context: context,
                    title: 'Next Moves',
                    icon: Icons.auto_awesome_outlined,
                    color: Colors.blue,
                    items: improvements,
                  ),
                  const SizedBox(height: 12),
                  _difficultyChip(result['suggestedDifficulty']?.toString() ?? 'medium'),
                  const SizedBox(height: 16),
                  _redoWeakAreasCard(context, story, weakAreas),
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

  Widget _scoreCard(
    BuildContext context,
    _InterviewStoryData story,
    int score,
    bool celebrate,
  ) {
    final theme = Theme.of(context);
    final repos = (story.session['repos'] as List<dynamic>? ?? const [])
        .map((repo) => repo['repoName']?.toString() ?? 'Repo')
        .take(3)
        .join(' • ');

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            celebrate ? 'Outstanding performance' : 'Interview recap',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score.toDouble()),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Text(
                    '${value.round()}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  '/ 100',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            celebrate
                ? 'You handled this round with strong clarity and momentum.'
                : 'Here is the story of where you were strongest and what to tighten next.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          if (repos.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeroPill(
                  icon: Icons.folder_open_outlined,
                  label: repos,
                  foreground: theme.colorScheme.onPrimary,
                ),
                _HeroPill(
                  icon: Icons.flag_outlined,
                  label:
                      '${_labelize(story.session['difficulty']?.toString() ?? 'medium')} difficulty',
                  foreground: theme.colorScheme.onPrimary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _comparisonCard(
    BuildContext context,
    _InterviewStoryData story,
    int score,
  ) {
    final theme = Theme.of(context);
    final previousScores = story.history
        .where((entry) => entry['_id']?.toString() != widget.sessionId)
        .map((entry) => (entry['finalResult']?['overallScore'] as num?)?.toInt())
        .whereType<int>()
        .toList();
    final previous = previousScores.isNotEmpty ? previousScores.first : null;
    final delta = previous == null ? null : score - previous;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress snapshot',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Current',
                    value: '$score',
                    accent: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Previous',
                    value: previous?.toString() ?? '—',
                    accent: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Change',
                    value: delta == null ? 'New' : '${delta >= 0 ? '+' : ''}$delta',
                    accent: delta == null
                        ? theme.colorScheme.tertiary
                        : delta >= 0
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _confidenceCard(BuildContext context, _InterviewStoryData story) {
    final theme = Theme.of(context);
    final breakdown = _buildTopicBreakdown(story);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confidence by question type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A quick read on where your answers felt strongest across the interview.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...breakdown.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ConfidenceBar(item: item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightRow(
    BuildContext context, {
    required String leftTitle,
    required IconData leftIcon,
    required Color leftColor,
    required List<String> leftItems,
    required String rightTitle,
    required IconData rightIcon,
    required Color rightColor,
    required List<String> rightItems,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final children = [
          Expanded(
            child: _resultSection(
              context: context,
              title: leftTitle,
              icon: leftIcon,
              color: leftColor,
              items: leftItems,
            ),
          ),
          if (!compact) const SizedBox(width: 16),
          Expanded(
            child: _resultSection(
              context: context,
              title: rightTitle,
              icon: rightIcon,
              color: rightColor,
              items: rightItems,
            ),
          ),
        ];

        if (compact) {
          return Column(
            children: [
              children[0],
              const SizedBox(height: 16),
              children[1],
            ],
          );
        }

        return Row(children: children);
      },
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

  Widget _redoWeakAreasCard(
    BuildContext context,
    _InterviewStoryData story,
    List<String> weakAreas,
  ) {
    final theme = Theme.of(context);
    final repos = (story.session['repos'] as List<dynamic>? ?? const [])
        .map((repo) => repo['repoId'] as int?)
        .whereType<int>()
        .toList();
    final suggestedDifficulty = story.result['suggestedDifficulty']?.toString() ??
        story.session['difficulty']?.toString() ??
        'medium';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Redo weak areas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            weakAreas.isEmpty
                ? 'Start another round with the same projects and keep the momentum going.'
                : 'Launch a focused retry using the same repositories and keep these weak spots in view.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (weakAreas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: weakAreas
                  .take(3)
                  .map((item) => Chip(label: Text(item)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InterviewSetupScreen(
                      initialRepoIds: repos,
                      initialDifficulty: suggestedDifficulty,
                      focusAreas: weakAreas,
                      flowTitle: 'Redo Weak Areas',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Start Focused Retry'),
            ),
          ),
        ],
      ),
    );
  }

  List<_TopicScore> _buildTopicBreakdown(_InterviewStoryData story) {
    final questions = List<dynamic>.from(story.session['questions'] ?? const []);
    final evaluations = List<dynamic>.from(story.session['evaluations'] ?? const []);
    final scoresByTopic = <String, List<double>>{};

    for (final raw in questions) {
      final question = Map<String, dynamic>.from(raw as Map);
      final evaluation = evaluations
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (entry) => entry['index'] == question['index'],
            orElse: () => const {},
          );
      final topic = _labelize(
        question['topic']?.toString().trim().isNotEmpty == true
            ? question['topic'].toString()
            : 'General',
      );
      final correctness = _scoreFromLevel(evaluation['correctness']?.toString());
      final clarity = _scoreFromLevel(evaluation['clarity']?.toString());
      scoresByTopic.putIfAbsent(topic, () => []).add((correctness + clarity) / 2);
    }

    final entries = scoresByTopic.entries
        .map(
          (entry) => _TopicScore(
            label: entry.key,
            score: entry.value.reduce((a, b) => a + b) / entry.value.length,
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return entries.isNotEmpty
        ? entries.take(4).toList()
        : const [
            _TopicScore(label: 'Communication', score: 0.62),
            _TopicScore(label: 'Problem Solving', score: 0.56),
          ];
  }

  double _scoreFromLevel(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'high':
        return 0.92;
      case 'medium':
        return 0.64;
      case 'low':
        return 0.34;
      default:
        return 0.5;
    }
  }

  String _labelize(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _InterviewStoryData {
  final Map<String, dynamic> result;
  final Map<String, dynamic> session;
  final List<dynamic> history;

  const _InterviewStoryData({
    required this.result,
    required this.session,
    required this.history,
  });
}

class _TopicScore {
  final String label;
  final double score;

  const _TopicScore({required this.label, required this.score});
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;

  const _HeroPill({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final _TopicScore item;

  const _ConfidenceBar({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(item.score * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: item.score,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
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
