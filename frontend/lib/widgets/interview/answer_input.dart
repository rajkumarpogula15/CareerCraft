import 'package:flutter/material.dart';

class AnswerInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const AnswerInput({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Type your answer here...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: const Text('Submit Answer'),
          ),
        ),
      ],
    );
  }
}
