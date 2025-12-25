import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/home_header.dart';
import '../widgets/workspace_section.dart';
import '../widgets/continue_session_card.dart';
import '../widgets/smart_suggestions_section.dart';
import '../widgets/home_footer.dart';

class LoggedInView extends StatelessWidget {
  const LoggedInView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppState.user;

    if (user == null) {
      return const Center(child: Text("Failed to load profile"));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeader(),

          const SizedBox(height: 24),

          const WorkspaceSection(),

          const SizedBox(height: 24),

          ContinueSessionCard(
            repoName: "auth-service",
            lastQuestion:
                "Can you explain how JWT refresh tokens are implemented?",
            type: "Chat",
            onContinue: () {
              // TODO: Navigate to AI session
            },
          ),

          const SizedBox(height: 24),

          SmartSuggestionsSection(
            suggestions: const [
              "Your repo auth-service has no README — generate one?",
              "You recently added 5 APIs — want updated documentation?",
              "This repo looks interview-ready — create a showcase summary?",
            ],
          ),

          const SizedBox(height: 32),

          const HomeFooter(),
        ],
      ),
    );
  }
}
