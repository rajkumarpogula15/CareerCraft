import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/feature_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onLogin;
  const HomeScreen({super.key, required this.onLogin});

  final String backendUrl = AppConfig.backendBaseUrl;

  Future<void> login() async {
    await launchUrl(
      Uri.parse('$backendUrl/auth/github/login'),
      mode: LaunchMode.externalApplication,
    );
    AppState.isLoggedIn = true;
    onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AppState.isLoggedIn ? _loggedIn() : _loggedOut(),
      ),
    );
  }

  Widget _loggedOut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CareerCraft',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Build your developer career using AI.',
          style: TextStyle(color: Color(0xFF475569)),
        ),
        const SizedBox(height: 30),

        const SectionTitle(title: 'Features'),
        const SizedBox(height: 15),

        const FeatureCard(
          icon: Icons.description,
          title: 'AI README Generator',
          description: 'Generate professional README files.',
        ),
        const FeatureCard(
          icon: Icons.chat,
          title: 'Repo Chatbot',
          description: 'Ask questions about any repo.',
        ),
        const FeatureCard(
          icon: Icons.work,
          title: 'Career Portfolio',
          description: 'Create resume from GitHub work.',
        ),

        const Spacer(),
        PrimaryButton(label: 'Login with GitHub', onTap: login),
      ],
    );
  }

  Widget _loggedIn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionTitle(title: 'My Workspace'),
        SizedBox(height: 20),
        FeatureCard(
          icon: Icons.star,
          title: 'Favourite Repos',
          description: 'Quick access to starred repos.',
        ),
        FeatureCard(
          icon: Icons.history,
          title: 'Recent Activity',
          description: 'Continue your recent work.',
        ),
      ],
    );
  }
}
