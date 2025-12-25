import 'package:flutter/material.dart';
import 'section_title.dart';
import '../screens/favourites_screen.dart';

class WorkspaceSection extends StatelessWidget {
  const WorkspaceSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Workspace'),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavouriteReposScreen()),
            );
          },
          child: const _InfoCard(
            icon: Icons.star,
            label: 'Favourite Repositories',
            value: 'View',
          ),
        ),

        const _InfoCard(
          icon: Icons.history,
          label: 'Recent Activity',
          value: 'Tracked automatically',
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(value, style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
