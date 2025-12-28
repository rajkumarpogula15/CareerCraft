import 'package:flutter/material.dart';

import '../services/interview_api.dart';
import '../widgets/interview/interview_progress.dart';
import 'interview_result_screen.dart';

class InterviewSessionScreen extends StatefulWidget {
  final List<int> repoIds;
  final String difficulty;

  const InterviewSessionScreen({
    super.key,
    required this.repoIds,
    required this.difficulty,
  });

  @override
  State<InterviewSessionScreen> createState() => _InterviewSessionScreenState();
}

class _InterviewSessionScreenState extends State<InterviewSessionScreen> {
  String? sessionId;
  String? currentQuestion;
  int currentIndex = 0;
  bool loading = true;
  String? errorMessage;

  final TextEditingController _answerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startInterview();
  }

  Future<void> _startInterview() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final createdSessionId = await InterviewApi.startInterview(
        repoIds: widget.repoIds,
        difficulty: widget.difficulty,
      );

      final firstQuestion = await InterviewApi.getFirstQuestion(
        createdSessionId,
      );

      if (!mounted) return;

      setState(() {
        sessionId = createdSessionId;
        currentQuestion = firstQuestion;
        currentIndex = 0;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to start interview';
        loading = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty || sessionId == null) return;

    setState(() => loading = true);

    try {
      final response = await InterviewApi.submitAnswer(sessionId!, answer);

      _answerCtrl.clear();

      if (!mounted) return;

      if (response['done'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InterviewResultPopup(sessionId: sessionId!),
          ),
        );
        return;
      }

      setState(() {
        currentIndex = response['questionIndex'] ?? currentIndex;
        currentQuestion = response['question'];
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to submit answer';
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading && currentQuestion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mock Interview')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startInterview,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (currentQuestion == null) {
      return const Scaffold(body: Center(child: Text('No question available')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mock Interview'), elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Progress Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InterviewProgress(current: currentIndex + 1, total: 10),
            ),

            // 🔹 Question Area (Scrollable)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${currentIndex + 1}',
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                        child: Text(
                          currentQuestion!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 🔹 Answer Input (Sticky Bottom)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: const [
                  BoxShadow(blurRadius: 8, color: Colors.black12),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _answerCtrl,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Type your answer…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _submitAnswer,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
