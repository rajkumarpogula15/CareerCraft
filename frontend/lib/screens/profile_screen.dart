import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../services/dashboard_service.dart';
import '../state/app_state.dart';
import '../widgets/common/state_views.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/logoutView.dart';
import '../widgets/primary_button.dart';
import '../widgets/skill_progress_card.dart';
import 'resume_builder_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onLogin;

  const ProfileScreen({
    super.key,
    required this.onLogout,
    required this.onLogin,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String backendUrl = AppConfig.backendBaseUrl;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (AppState.isLoggedIn && AppState.jwt != null) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() => loading = true);

    try {
      final dashboard = await DashboardService.fetchDashboard();
      if (dashboard != null) {
        AppState.dashboard = dashboard;
        AppState.user = Map<String, dynamic>.from(dashboard['profile'] ?? {});
      } else {
        final res = await http.get(
          Uri.parse('$backendUrl/auth/github/profile'),
          headers: {
            'Authorization': 'Bearer ${AppState.jwt}',
            'Content-Type': 'application/json',
          },
        );

        if (res.statusCode == 200) {
          AppState.user = json.decode(res.body);
        } else {
          AppState.user = null;
        }
      }
    } catch (_) {
      AppState.user = null;
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppState.isLoggedIn) {
      return const LoggedOutView();
    }

    if (loading) {
      return const ProfileSkeleton();
    }

    final user = AppState.user;
    if (user == null) {
      return AppErrorState(message: 'Failed to load profile', onRetry: _loadProfile);
    }

    final stats = (AppState.dashboard?['stats'] as Map<String, dynamic>?) ?? {};
    final languageDistribution =
        (AppState.dashboard?['languageDistribution'] as Map<String, dynamic>?) ?? {};

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _profileHeader(user, stats),
          const SizedBox(height: 12),
          _statTile('Public Repositories', user['public_repos'] ?? 0),
          _statTile('Followers', user['followers'] ?? 0),
          _statTile('Following', user['following'] ?? 0),
          const SizedBox(height: 12),
          SkillProgressCard(
            distribution: languageDistribution,
            title: 'Language Heatmap',
          ),
          const SizedBox(height: 12),
          _actionsSection(user),
        ],
      ),
    );
  }

  Widget _profileHeader(Map user, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final streak = stats['loginStreak'] ?? 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: user['avatar'] != null
                  ? NetworkImage(user['avatar'])
                  : null,
              child: user['avatar'] == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              user['name'] ?? 'No Name',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (user['username'] != null)
              Text(
                '@${user['username']}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (streak > 0) ...[
              const SizedBox(height: 6),
              Text(
                '🔥 $streak-day login streak',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openGitHubProfile(user['username']),
              icon: const Icon(Icons.open_in_new),
              label: const Text('View on GitHub'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, int value) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(label),
        trailing: Text(
          value.toString(),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _actionsSection(Map user) {
    return Column(
      children: [
        PrimaryButton(
          label: 'Build Resume',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResumeBuilderScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _confirmLogout,
          child: Text(
            'Logout',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await AppState.logout();
    if (!mounted) return;
    setState(() {});
    widget.onLogout();
  }

  Future<void> _openGitHubProfile(String? username) async {
    if (username == null || username.isEmpty) return;
    final uri = Uri.parse('https://github.com/$username');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
