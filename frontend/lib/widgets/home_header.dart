import 'package:flutter/material.dart';
import '../state/app_state.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = AppState.user!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: user['avatar'] != null
                  ? NetworkImage(user['avatar'])
                  : null,
              child: user['avatar'] == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user['name'] ?? user['username'] ?? 'Developer',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user['username'] != null)
                    Text(
                      '@${user['username']}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
