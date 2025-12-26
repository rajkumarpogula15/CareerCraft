import 'package:flutter/material.dart';

class BlogPopup extends StatelessWidget {
  const BlogPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Header(title: "CareerCraft Blog"),
          SizedBox(height: 12),

          Text(
            "CareerCraft: Your AI-Powered Developer Companion",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),

          Text(
            "Modern developers spend countless hours understanding legacy code, "
            "writing documentation, and explaining their work. CareerCraft was "
            "built to solve exactly this problem.",
          ),
          SizedBox(height: 12),

          Text(
            "CareerCraft acts as an intelligent assistant that understands your "
            "GitHub repositories. From generating professional README files to "
            "answering deep questions about your codebase, it reduces friction "
            "in everyday development workflows.",
          ),
          SizedBox(height: 12),

          Text(
            "Unlike generic AI tools, CareerCraft is repository-aware. It analyzes "
            "your project structure and code to provide grounded, contextual explanations—"
            "making it ideal for onboarding, interviews, and open-source work.",
          ),
          SizedBox(height: 12),

          Text(
            "With features like contextual chat, portfolio generation, and activity tracking, "
            "CareerCraft is more than a tool—it’s a platform built to help developers grow "
            "their careers with confidence.",
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
