import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import '../widgets/primary_button.dart';
import '../config/app_config.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String backendUrl = AppConfig.backendBaseUrl;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    if (AppState.isLoggedIn && AppState.jwt != null) {
      fetchProfile();
    } else {
      loading = false;
    }
  }

  Future<void> fetchProfile() async {
    try {
      final res = await http.get(
        Uri.parse('$backendUrl/auth/github/profile'),
        headers: {
          'Authorization': 'Bearer ${AppState.jwt}',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          AppState.user = json.decode(res.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ SHOW MESSAGE INSTEAD OF EMPTY SCREEN
    if (!AppState.isLoggedIn) {
      return const Center(
        child: Text(
          'Login to view your profile',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = AppState.user;
    if (user == null) {
      return const Center(child: Text('Failed to load profile'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _profileHeader(user),
          const SizedBox(height: 24),
          _statsSection(user),
          const SizedBox(height: 32),
          _actionsSection(),
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  Widget _profileHeader(Map user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: user['avatar'] != null
                  ? NetworkImage(user['avatar'])
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user['name'] ?? 'No Name',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '@${user['username']}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (user['email'] != null) ...[
              const SizedBox(height: 6),
              Text(user['email'], style: const TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statsSection(Map user) {
    return Row(
      children: [
        _statCard('Repos', user['public_repos'] ?? 0),
        _statCard('Followers', user['followers'] ?? 0),
        _statCard('Following', user['following'] ?? 0),
      ],
    );
  }

  Widget _statCard(String label, int value) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionsSection() {
    return Column(
      children: [
        PrimaryButton(label: 'Create Resume', onTap: () {}),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _confirmLogout,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }

  // ---------------- LOGOUT ----------------

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _logout() {
    setState(() {
      AppState.isLoggedIn = false;
      AppState.jwt = null;
      AppState.user = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));

    widget.onLogout(); // parent rebuilds & shows login
  }
}
