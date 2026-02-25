import 'package:flutter/material.dart';

import '../services/interview_api.dart';
import '../widgets/common/state_views.dart';
import '../widgets/interview/interview_progress.dart';
import '../widgets/loading/app_skeleton.dart';
import 'interview_result_screen.dart';

class InterviewSessionScreen extends StatefulWidget {
  final List<int> repoIds;
  final String difficulty;
  final String? existingSessionId;

  const InterviewSessionScreen({
    super.key,
    required this.repoIds,
    required this.difficulty,
    this.existingSessionId,
  });

  @override
  State<InterviewSessionScreen> createState() => _InterviewSessionScreenState();
}

class _InterviewSessionScreenState extends State<InterviewSessionScreen> {
  String? sessionId;
  String? currentQuestion;
  int currentIndex = 0;
  bool initialLoading = true;
  bool submitting = false;
  String? errorMessage;

  final TextEditingController _answerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeInterview();
  }

  Future<void> _initializeInterview() async {
    setState(() {
      initialLoading = true;
      errorMessage = null;
    });

    try {
      if (widget.existingSessionId != null && widget.existingSessionId!.isNotEmpty) {
        final resumed = await InterviewApi.resumeInterview(widget.existingSessionId!);
        if (!mounted) return;

        if (resumed['done'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => InterviewResultPopup(sessionId: widget.existingSessionId!),
            ),
          );
          return;
        }

        setState(() {
          sessionId = resumed['sessionId']?.toString() ?? widget.existingSessionId;
          currentQuestion = resumed['question']?.toString();
          currentIndex = (resumed['questionIndex'] ?? 0) as int;
          initialLoading = false;
        });
        return;
      }

      final createdSessionId = await InterviewApi.startInterview(
        repoIds: widget.repoIds,
        difficulty: widget.difficulty,
      );
      final firstQuestion = await InterviewApi.getFirstQuestion(createdSessionId);

      if (!mounted) return;

      setState(() {
        sessionId = createdSessionId;
        currentQuestion = firstQuestion;
        currentIndex = 0;
        initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        initialLoading = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty || sessionId == null || submitting) return;

    setState(() => submitting = true);

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
        currentIndex = (response['questionIndex'] ?? currentIndex) as int;
        currentQuestion = response['question']?.toString();
        submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to submit answer';
        submitting = false;
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
    if (initialLoading && currentQuestion == null) {
      return const Scaffold(body: CardListSkeleton(itemCount: 3, itemHeight: 120));
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mock Interview')),
        body: AppErrorState(message: errorMessage!, onRetry: _initializeInterview),
      );
    }

    if (currentQuestion == null) {
      return const Scaffold(
        body: AppEmptyState(title: 'No question available', icon: Icons.help_outline),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mock Interview'), elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InterviewProgress(current: currentIndex + 1, total: 10),
            ),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${currentIndex + 1}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.primaryContainer,
                        ),
                        child: Text(
                          currentQuestion!,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _answerCtrl,
                      minLines: 1,
                      maxLines: 5,
                      enabled: !submitting,
                      decoration: const InputDecoration(
                        hintText: 'Type your answer...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  submitting
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
