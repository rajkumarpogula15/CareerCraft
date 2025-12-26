import 'package:flutter/material.dart';

class FAQsPopup extends StatelessWidget {
  const FAQsPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Header(title: "Frequently Asked Questions"),
          SizedBox(height: 12),

          _FAQItem(
            question: "What is CareerCraft?",
            answer:
                "CareerCraft is an AI-powered developer assistant that integrates with GitHub to help you understand, document, and showcase your repositories.",
          ),
          _FAQItem(
            question: "How do I log in?",
            answer:
                "You log in securely using GitHub OAuth. CareerCraft never asks for your GitHub password.",
          ),
          _FAQItem(
            question: "Does CareerCraft modify my repositories?",
            answer:
                "No. Changes like committing a README happen only after explicit user confirmation.",
          ),
          _FAQItem(
            question: "Does the chatbot remember conversations?",
            answer:
                "Yes. Each repository chat supports multi-turn contextual conversations and saved history.",
          ),
          _FAQItem(
            question: "Is CareerCraft free?",
            answer:
                "CareerCraft offers free features, with advanced AI capabilities planned under premium tiers.",
          ),
          _FAQItem(
            question: "Does it support private repositories?",
            answer:
                "Yes. Private repositories are fully supported with your permission.",
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(answer),
        ],
      ),
    );
  }
}
