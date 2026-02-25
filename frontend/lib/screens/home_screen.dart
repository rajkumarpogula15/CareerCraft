import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../services/dashboard_service.dart';
import '../state/app_state.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/logged_in_view.dart';
import '../widgets/logged_out_view.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback? onOpenProfile;

  const HomeScreen({super.key, required this.onLogin, this.onOpenProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();

    if (AppState.isLoggedIn && AppState.jwt != null && AppState.user == null) {
      _fetchProfile();
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _linkSub = _appLinks.uriLinkStream.listen((uri) async {
      if (!mounted) return;

      if (uri.scheme == 'careercraft' && uri.host == 'login-success') {
        final token = uri.queryParameters['token'];

        if (token != null && token.isNotEmpty) {
          await AppState.saveToken(token);
          await _fetchProfile();
          widget.onLogin();
        }
      }
    });
  }

  Future<void> _fetchProfile() async {
    if (AppState.jwt == null) return;

    setState(() => _loadingProfile = true);

    try {
      final dashboard = await DashboardService.fetchDashboard();
      if (dashboard != null) {
        AppState.dashboard = dashboard;
        AppState.user = Map<String, dynamic>.from(dashboard['profile'] ?? {});
      }
    } catch (_) {
      // Keep logged out fallback behavior unchanged.
    }

    if (mounted) {
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loginWithGitHub() async {
    final url = Uri.parse('${AppConfig.backendBaseUrl}/auth/github/login');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final content = AppState.isLoggedIn
        ? (_loadingProfile
              ? const HomeLoggedInSkeleton()
              : LoggedInView(onOpenProfile: widget.onOpenProfile))
        : LoggedOutView(onLogin: _loginWithGitHub);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey('${AppState.isLoggedIn}-${_loadingProfile.toString()}'),
          child: content,
        ),
      ),
    );
  }
}
