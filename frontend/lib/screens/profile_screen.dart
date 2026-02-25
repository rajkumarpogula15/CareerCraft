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
    final activeDates = _parseActiveDates(stats['activeDates']);

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _profileHeader(user, stats),
          const SizedBox(height: 12),
          _resumeBuilderButton(),
          const SizedBox(height: 12),
          _statsRow(user),
          const SizedBox(height: 12),
          _activeDaysCalendar(
            activeDates: activeDates,
            fallbackCount: (stats['totalActiveDays'] ?? 0) as int,
          ),
          const SizedBox(height: 12),
          SkillProgressCard(
            distribution: languageDistribution,
            title: 'Language Heatmap',
          ),
          const SizedBox(height: 12),
          _actionsSection(),
        ],
      ),
    );
  }

  Widget _profileHeader(Map user, Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final streak = (stats['loginStreak'] ?? 0) as int;
    final activeDays = (stats['totalActiveDays'] ?? 0) as int;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
              child: user['avatar'] == null ? const Icon(Icons.person, size: 40) : null,
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _badge(Icons.local_fire_department_outlined, '$streak-day streak'),
                _badge(Icons.calendar_today_outlined, '$activeDays active days'),
              ],
            ),
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

  Widget _badge(IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumeBuilderButton() {
    return PrimaryButton(
      label: 'Build Resume',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResumeBuilderScreen()),
        );
      },
    );
  }

  Widget _statsRow(Map user) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: 'Repositories',
            value: user['public_repos'] ?? 0,
            icon: Icons.folder_open_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            label: 'Followers',
            value: user['followers'] ?? 0,
            icon: Icons.people_alt_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            label: 'Following',
            value: user['following'] ?? 0,
            icon: Icons.group_work_outlined,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required dynamic value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeDaysCalendar({
    required Set<DateTime> activeDates,
    required int fallbackCount,
  }) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final dayCells = List<DateTime>.generate(
      35,
      (index) => DateTime(today.year, today.month, today.day).subtract(
        Duration(days: 34 - index),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Days Calendar',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: dayCells.map((day) {
                final key = DateTime(day.year, day.month, day.day);
                final isActive = activeDates.contains(key);
                return Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              activeDates.isEmpty
                  ? '$fallbackCount total active days'
                  : '${activeDates.length} days marked in recent activity',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<DateTime> _parseActiveDates(dynamic raw) {
    if (raw is! List) return <DateTime>{};
    final dates = <DateTime>{};
    for (final value in raw) {
      final parsed = DateTime.tryParse(value.toString());
      if (parsed == null) continue;
      dates.add(DateTime(parsed.year, parsed.month, parsed.day));
    }
    return dates;
  }

  Widget _actionsSection() {
    return Column(
      children: [
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
