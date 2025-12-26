import 'package:flutter/material.dart';

class PrivacyPopup extends StatelessWidget {
  const PrivacyPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Header(title: "Privacy Policy"),
          SizedBox(height: 12),
          _PolicyItem("CareerCraft does not store GitHub passwords."),
          _PolicyItem("Authentication is handled securely via GitHub OAuth."),
          _PolicyItem("Only necessary repository metadata is accessed."),
          _PolicyItem(
            "Chat history is stored securely and visible only to you.",
          ),
          _PolicyItem("CareerCraft does not sell or share user data."),
          _PolicyItem("AI processing is limited to requested features only."),
          _PolicyItem("You may request deletion of your data at any time."),
          _PolicyItem(
            "Logs and analytics are used only for product improvement.",
          ),
          _PolicyItem("Private repository data is never exposed publicly."),
          _PolicyItem(
            "All stored data follows standard security best practices.",
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final String text;
  const _PolicyItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  "),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
