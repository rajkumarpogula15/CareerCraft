import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'home_header.dart';
import 'quick_actions_section.dart';
import 'workspace_section.dart';

class LoggedInView extends StatelessWidget {
  const LoggedInView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = AppState.user;

    if (user == null) {
      return const Center(child: Text('Failed to load profile'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          HomeHeader(),
          SizedBox(height: 24),
          QuickActionsSection(),
          SizedBox(height: 24),
          WorkspaceSection(),
        ],
      ),
    );
  }
}
