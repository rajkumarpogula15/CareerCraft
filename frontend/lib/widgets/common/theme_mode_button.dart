import 'package:flutter/material.dart';

import '../../state/theme_controller.dart';

class ThemeModeButton extends StatelessWidget {
  final ThemeController controller;

  const ThemeModeButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      initialValue: controller.themeMode,
      onSelected: controller.setThemeMode,
      itemBuilder: (context) => const [
        PopupMenuItem(value: ThemeMode.system, child: Text('System Theme')),
        PopupMenuItem(value: ThemeMode.light, child: Text('Light Theme')),
        PopupMenuItem(value: ThemeMode.dark, child: Text('Dark Theme')),
      ],
      icon: Icon(_iconForMode(controller.themeMode)),
    );
  }

  IconData _iconForMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
      ThemeMode.system => Icons.brightness_auto,
    };
  }
}
