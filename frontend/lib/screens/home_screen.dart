import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

import '../state/app_state.dart';
import '../config/app_config.dart';
import '../widgets/feature_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const HomeScreen({super.key, required this.onLogin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  /// 🔗 Listen for GitHub OAuth deep link
  void _initDeepLinks() {
    _linkSub = _appLinks.uriLinkStream.listen((Uri uri) async {
      if (!mounted) return;

      if (uri.scheme == 'careercraft' && uri.host == 'login-success') {
        final token = uri.queryParameters['token'];

        if (token != null) {
          await AppState.saveToken(token);

          setState(() {}); // 🔥 THIS updates UI instantly
          widget.onLogin();
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _loginWithGitHub() async {
    final url = Uri.parse('${AppConfig.backendBaseUrl}/auth/github/login');
    await launchUrl(url, mode: LaunchMode.externalApplication);
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

  /// UI BEFORE LOGIN
  Widget _loggedOut() {
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
          style: TextStyle(color: Color(0xFF475569), fontSize: 14),
        ),
        const SizedBox(height: 30),

        const SectionTitle(title: 'What you can do'),
        const SizedBox(height: 16),

        const FeatureCard(
          icon: Icons.description,
          title: 'AI README Generator',
          description:
              'Generate professional README files for your repositories.',
        ),
        const FeatureCard(
          icon: Icons.chat,
          title: 'Repository Chatbot',
          description: 'Ask questions and understand any repository instantly.',
        ),
        const FeatureCard(
          icon: Icons.work,
          title: 'Career Portfolio',
          description: 'Create resumes and portfolios from your GitHub work.',
        ),

        const Spacer(),

        PrimaryButton(label: 'Login with GitHub', onTap: _loginWithGitHub),
      ],
    );
  }

  /// UI AFTER LOGIN
  Widget _loggedIn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionTitle(title: 'My Workspace'),
        SizedBox(height: 20),

        FeatureCard(
          icon: Icons.star,
          title: 'Favourite Repositories',
          description: 'Quick access to repositories you care about.',
        ),
        FeatureCard(
          icon: Icons.history,
          title: 'Recent Activity',
          description: 'Continue where you left off.',
        ),
        FeatureCard(
          icon: Icons.auto_awesome,
          title: 'AI Tools',
          description: 'Generate READMEs, chat with repos, and more.',
        ),
      ],
    );
  }
}
