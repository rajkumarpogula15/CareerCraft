import 'package:flutter/material.dart';

class RepoCard extends StatelessWidget {
  final Map repo;
  final bool included;
  final bool generating;
  final List<String> points;
  final VoidCallback onToggleInclude;
  final VoidCallback onGenerate;
  final VoidCallback onEditPoints;

  const RepoCard({
    super.key,
    required this.repo,
    required this.included,
    required this.generating,
    required this.points,
    required this.onToggleInclude,
    required this.onGenerate,
    required this.onEditPoints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: included,
                  onChanged: (_) => onToggleInclude(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (repo['name'] ?? 'Repository').toString(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (repo['description'] ?? 'No description').toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (included) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: generating ? null : onGenerate,
                    child: generating
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Text(points.isEmpty ? 'Generate Points' : 'Regenerate Points'),
                  ),
                  OutlinedButton(
                    onPressed: points.isEmpty ? null : onEditPoints,
                    child: const Text('Edit Points'),
                  ),
                ],
              ),
            ],
            if (points.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...points.take(2).map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '- $point',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
