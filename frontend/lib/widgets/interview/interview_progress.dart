import 'package:flutter/material.dart';

class InterviewProgress extends StatelessWidget {
  final int current;
  final int total;

  const InterviewProgress({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question $current of $total'),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: current / total),
      ],
    );
  }
}
