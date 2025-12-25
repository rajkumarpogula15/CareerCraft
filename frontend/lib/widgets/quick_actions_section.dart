import 'package:flutter/material.dart';
import 'section_title.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Quick Actions'),
        const SizedBox(height: 12),

        _ActionCard(
          icon: Icons.folder,
          title: 'My Repositories',
          subtitle: 'View and manage your GitHub repositories',
        ),
        _ActionCard(
          icon: Icons.auto_awesome,
          title: 'AI README Generator',
          subtitle: 'Generate professional README files',
        ),
        _ActionCard(
          icon: Icons.chat,
          title: 'Repository Chatbot',
          subtitle: 'Ask questions about your codebase',
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4F46E5)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // navigation can be added later
        },
      ),
    );
  }
}
