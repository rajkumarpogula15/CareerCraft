import 'package:flutter/material.dart';
import '../services/interview_api.dart';

class InterviewResultPopup extends StatelessWidget {
  final String sessionId;

  const InterviewResultPopup({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder(
            future: InterviewApi.getFinalResult(sessionId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final result = snapshot.data!;

              return ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  _dragHandle(),
                  const SizedBox(height: 16),

                  _scoreCard(context, result['overallScore']),
                  const SizedBox(height: 20),

                  _resultSection(
                    title: 'Strengths',
                    icon: Icons.check_circle,
                    color: Colors.green,
                    items: result['strongAreas'],
                  ),

                  _resultSection(
                    title: 'Needs Improvement',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                    items: result['weakAreas'],
                  ),

                  _resultSection(
                    title: 'Suggestions',
                    icon: Icons.lightbulb_outline,
                    color: Colors.blue,
                    items: result['improvements'],
                  ),

                  const SizedBox(height: 12),

                  _difficultyChip(result['suggestedDifficulty']),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _scoreCard(BuildContext context, dynamic score) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigo.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Overall Score', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '$score / 100',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultSection({
    required String title,
    required IconData icon,
    required Color color,
    required List items,
  }) {
    return Card(
      elevation: 0,
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
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
