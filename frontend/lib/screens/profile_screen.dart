import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_links/app_links.dart';

import '../state/app_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/logoutView.dart';
import '../config/app_config.dart';
import 'resume_builder_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onLogin; // triggers OAuth (browser open)

  const ProfileScreen({
    super.key,
    required this.onLogout,
    required this.onLogin,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String backendUrl = AppConfig.backendBaseUrl;

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  bool loading = false;

  // =====================================================
  // =================== LIFECYCLE =======================
  // =====================================================

  @override
  void initState() {
    super.initState();

    if (AppState.isLoggedIn && AppState.jwt != null) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  // =====================================================
  // ================= PROFILE FETCH =====================
  // =====================================================

  Future<void> _loadProfile() async {
    setState(() => loading = true);

    try {
      final res = await http.get(
        Uri.parse('$backendUrl/auth/github/profile'),
        headers: {
          'Authorization': 'Bearer ${AppState.jwt}',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        AppState.user = json.decode(res.body);
      } else {
        AppState.user = null;
      }
    } catch (e) {
      debugPrint('❌ Profile load error: $e');
      AppState.user = null;
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // =====================================================
  // =================== UI ==============================
  // =====================================================

  @override
  Widget build(BuildContext context) {
    // 🔒 NOT LOGGED IN → show LoggedOutView (no login button now)
    if (!AppState.isLoggedIn) {
      return const LoggedOutView();
    }

    // ⏳ LOADING
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = AppState.user;

    // ❌ ERROR
    if (user == null) {
      return const Center(child: Text('Failed to load profile'));
    }

    // ✅ PROFILE VIEW
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

  // =====================================================
  // ================= PROFILE UI ========================
  // =====================================================

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
              child: user['avatar'] == null
                  ? const Icon(Icons.person, size: 48)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user['name'] ?? 'No Name',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (user['username'] != null)
              Text(
                '@${user['username']}',
                style: const TextStyle(color: Colors.grey),
              ),
            if (user['email'] != null)
              Text(user['email'], style: const TextStyle(color: Colors.grey)),
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
        PrimaryButton(
          label: 'Create Resume',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResumeBuilderScreen()),
            );
          },
        ),

        const SizedBox(height: 12),
        OutlinedButton(onPressed: _confirmLogout, child: const Text('Logout')),
      ],
    );
  }

  // =====================================================
  // ================= LOGOUT ============================
  // =====================================================

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

    widget.onLogout();
  }
}
