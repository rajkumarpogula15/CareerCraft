import 'package:flutter/material.dart';
import '../services/interview_api.dart';

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

  Future<void> _loadInterview() async {
    try {
      final interview = await InterviewApi.getInterviewById(widget.sessionId);

      setState(() {
        _interview = interview;
        _loading = false;
      });
    } catch (e) {
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final questions = _interview!['questions'] as List<dynamic>;
    final answers = _interview!['answers'] as List<dynamic>;
    final evaluations = _interview!['evaluations'] as List<dynamic>;
    final finalResult = _interview!['finalResult'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        /// 🏁 Final Score
        Card(
          elevation: 2,
          child: ListTile(
            title: const Text('Final Score'),
            trailing: Text(
              finalResult?['overallScore']?.toString() ?? '-',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 24),

        /// 📄 Question-by-question review
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
                  Text(e['feedback'] ?? 'No feedback'),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
