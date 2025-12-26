import 'package:flutter/material.dart';

class TermsPopup extends StatelessWidget {
  const TermsPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Header(title: "Terms & Conditions"),
          SizedBox(height: 12),
          _TermItem(
            "CareerCraft is provided “as is” without service guarantees.",
          ),
          _TermItem("Users are responsible for actions performed via GitHub."),
          _TermItem("CareerCraft does not claim ownership of your code."),
          _TermItem("The platform must not be used for illegal activities."),
          _TermItem("AI-generated content should be reviewed before use."),
          _TermItem("Features and pricing may change without notice."),
          _TermItem("Abuse of AI services may result in suspension."),
          _TermItem("Approved repository changes are user responsibility."),
          _TermItem("All CareerCraft intellectual property remains protected."),
          _TermItem("Continued use implies acceptance of updated terms."),
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

class _TermItem extends StatelessWidget {
  final String text;
  const _TermItem(this.text);

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
