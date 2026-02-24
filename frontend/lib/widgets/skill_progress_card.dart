import 'package:flutter/material.dart';

class SkillProgressCard extends StatelessWidget {
  final Map<String, dynamic> distribution;
  final String title;

  const SkillProgressCard({
    super.key,
    required this.distribution,
    this.title = 'Language Heatmap',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _sortedEntries();

    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'No language data available yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...entries.asMap().entries.map((entry) {
              final rank = entry.key;
              final item = entry.value;
              final alpha = (0.95 - (rank * 0.12)).clamp(0.35, 0.95);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SkillRow(
                  label: item.key,
                  value: item.value,
                  color: theme.colorScheme.primary.withValues(alpha: alpha),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, int>> _sortedEntries() {
    final list = distribution.entries.map((entry) {
      final raw = entry.value;
      final value = raw is num ? raw.clamp(0, 100).round() : 0;
      return MapEntry(entry.key, value);
    }).toList();

    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }
}

class _SkillRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SkillRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: value / 100,
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
