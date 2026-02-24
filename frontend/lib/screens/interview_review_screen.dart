import 'package:flutter/material.dart';

import '../services/interview_api.dart';
import '../widgets/common/state_views.dart';
import '../widgets/loading/app_skeleton.dart';

class InterviewReviewScreen extends StatefulWidget {
  final String sessionId;

  const InterviewReviewScreen({super.key, required this.sessionId});

  @override
  State<InterviewReviewScreen> createState() => _InterviewReviewScreenState();
}

class _InterviewReviewScreenState extends State<InterviewReviewScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _interview;

  @override
  void initState() {
    super.initState();
    _loadInterview();
  }

  String _feedbackText(Map<String, dynamic> evaluation) {
    final direct = (evaluation['feedback'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;

    final parts = <String>[];
    final correctness = (evaluation['correctness'] ?? '').toString().trim();
    final clarity = (evaluation['clarity'] ?? '').toString().trim();
    final notes = (evaluation['notes'] ?? '').toString().trim();

    if (correctness.isNotEmpty) parts.add('Correctness: $correctness');
    if (clarity.isNotEmpty) parts.add('Clarity: $clarity');
    if (notes.isNotEmpty) parts.add(notes);

    return parts.isEmpty ? 'No feedback available' : parts.join('\n');
  }

  Future<void> _loadInterview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final interview = await InterviewApi.getInterviewById(widget.sessionId);

      if (!mounted) return;

      setState(() {
        _interview = interview;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load interview';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Review')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const CardListSkeleton(itemCount: 5, itemHeight: 130);
    }

    if (_error != null) {
      return AppErrorState(message: _error!, onRetry: _loadInterview);
    }

    if (_interview == null) {
      return const AppEmptyState(title: 'Interview data unavailable');
    }

    final questions = (_interview!['questions'] as List<dynamic>? ?? const []);
    final answers = (_interview!['answers'] as List<dynamic>? ?? const []);
    final evaluations =
        (_interview!['evaluations'] as List<dynamic>? ?? const []);
    final finalResult = _interview!['finalResult'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: const Text('Final Score'),
            trailing: Text(
              finalResult?['overallScore']?.toString() ?? '-',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(questions.length, (i) {
          final q = questions[i];

          final a = answers.cast<Map<String, dynamic>>().firstWhere(
            (x) => x['index'] == q['index'],
            orElse: () => {},
          );

          final e = evaluations.cast<Map<String, dynamic>>().firstWhere(
            (x) => x['index'] == q['index'],
            orElse: () => {},
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${i + 1}: ${q['text']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Answer:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(a['text'] ?? '-'),
                  const SizedBox(height: 8),
                  const Text(
                    'AI Feedback:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(_feedbackText(e)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
