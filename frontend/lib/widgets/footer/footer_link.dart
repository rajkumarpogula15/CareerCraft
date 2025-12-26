import 'package:flutter/material.dart';
import 'popup_helper.dart';

class FooterLink extends StatelessWidget {
  final String label;
  final Widget popup;

  const FooterLink({super.key, required this.label, required this.popup});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showFooterPopup(context, popup),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
