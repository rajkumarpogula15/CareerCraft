import 'package:flutter/material.dart';

class RepoCard extends StatelessWidget {
  final Map repo;
  final bool included;
  final bool generating;
  final List<String> points;

  final VoidCallback onToggleInclude;
  final VoidCallback onGenerate;
  final Function(int, String) onEditPoint;

  const RepoCard({
    super.key,
    required this.repo,
    required this.included,
    required this.generating,
    required this.points,
    required this.onToggleInclude,
    required this.onGenerate,
    required this.onEditPoint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: included,
              onChanged: (_) => onToggleInclude(),
              title: Text(repo['name']),
              subtitle: Text(repo['description'] ?? 'No description'),
            ),

            if (included)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: generating ? null : onGenerate,
                  child: generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generate Resume Points'),
                ),
              ),

            if (points.isNotEmpty)
              Column(
                children: points.asMap().entries.map((e) {
                  return TextFormField(
                    initialValue: e.value,
                    maxLines: 2,
                    decoration: const InputDecoration(prefixText: '• '),
                    onChanged: (v) => onEditPoint(e.key, v),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
