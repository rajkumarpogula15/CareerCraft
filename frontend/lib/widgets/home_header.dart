import 'package:flutter/material.dart';

import '../state/app_state.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback? onTap;

  const HomeHeader({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = AppState.user ?? {};
    final stats = (AppState.dashboard?['stats'] as Map<String, dynamic>?) ?? {};
    final name = user['name'] ?? user['username'] ?? 'Developer';
    final streak = (stats['loginStreak'] ?? 0) as int;
    final activeDays = (stats['totalActiveDays'] ?? 0) as int;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
                child: user['avatar'] == null ? const Icon(Icons.person, size: 22) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $name',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MetricPill(
                          icon: Icons.local_fire_department_outlined,
                          label: '$streak-day streak',
                        ),
                        _MetricPill(
                          icon: Icons.calendar_today_outlined,
                          label: '$activeDays active days',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
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
}
