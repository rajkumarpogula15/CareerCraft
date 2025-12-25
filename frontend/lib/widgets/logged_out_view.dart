import 'package:flutter/material.dart';

import '../widgets/feature_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';

class LoggedOutView extends StatelessWidget {
  final VoidCallback onLogin;

  const LoggedOutView({Key? key, required this.onLogin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CareerCraft',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Build your developer career using AI.',
          style: TextStyle(color: Color(0xFF475569)),
        ),
        const SizedBox(height: 30),

        const SectionTitle(title: 'What you can do'),
        const SizedBox(height: 16),

        const FeatureCard(
          icon: Icons.description,
          title: 'AI README Generator',
          description: 'Generate professional README files.',
        ),
        const FeatureCard(
          icon: Icons.chat,
          title: 'Repository Chatbot',
          description: 'Understand repositories with AI.',
        ),
        const FeatureCard(
          icon: Icons.work,
          title: 'Career Portfolio',
          description: 'Create resumes from GitHub projects.',
        ),

        const Spacer(),
        PrimaryButton(label: 'Login with GitHub', onTap: onLogin),
      ],
    );
  }
}
