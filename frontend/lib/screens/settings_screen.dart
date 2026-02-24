import 'package:flutter/material.dart';

import '../services/dashboard_service.dart';
import '../state/app_state.dart';
import '../state/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeController themeController;

  const SettingsScreen({super.key, required this.themeController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final dashboard = AppState.dashboard;
    _notificationsEnabled =
        dashboard?['stats']?['notificationsEnabled'] != false;
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
      _saving = true;
    });

    final ok = await DashboardService.updateNotifications(value);
    if (!mounted) return;

    if (!ok) {
      setState(() => _notificationsEnabled = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update notifications')),
      );
    } else {
      final stats = (AppState.dashboard?['stats'] as Map<String, dynamic>?) ?? {};
      stats['notificationsEnabled'] = value;
      AppState.dashboard ??= {};
      AppState.dashboard!['stats'] = stats;
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AppState.user ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                      ),
                      ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {widget.themeController.themeMode},
                    onSelectionChanged: (selected) {
                      widget.themeController.setThemeMode(selected.first);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile.adaptive(
              title: const Text('Notifications'),
              subtitle: Text(_saving ? 'Saving...' : 'Receive product updates'),
              value: _notificationsEnabled,
              onChanged: _saving ? null : _toggleNotifications,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('Name: ${user['name'] ?? '-'}'),
                  Text('Username: @${user['username'] ?? '-'}'),
                  Text('Email: ${user['email'] ?? '-'}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
