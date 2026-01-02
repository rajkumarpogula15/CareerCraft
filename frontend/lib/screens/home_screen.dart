import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/app_config.dart';
import '../state/app_state.dart';

// UI SECTIONS
import '../widgets/logged_out_view.dart';
import '../widgets/logged_in_view.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const HomeScreen({Key? key, required this.onLogin}) : super(key: key);

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

    _initDevAutoLogin();
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

  // ================= DEV AUTO LOGIN =================

  void _initDevAutoLogin() async {
    final devAutoLogin = dotenv.env['DEV_AUTO_LOGIN'] == 'true';
    final devJwt = dotenv.env['DEV_JWT'];

    if (devAutoLogin && devJwt != null && devJwt.isNotEmpty) {
      // Force login state
      await AppState.saveToken(devJwt);

      if (mounted) {
        setState(() {
          AppState.isLoggedIn = true;
        });
      }
    }
  }

  // ================= DEEP LINKS (PROD LOGIN) =================

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

  // ================= PROFILE =================

  Future<void> _fetchProfile() async {
    if (AppState.jwt == null) return;

    setState(() => _loadingProfile = true);

    try {
      final res = await http.get(
        Uri.parse('${AppConfig.backendBaseUrl}/auth/github/profile'),
        headers: {
          'Authorization': 'Bearer ${AppState.jwt}',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        AppState.user = json.decode(res.body);
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingProfile = false);
  }

  // ================= LOGIN =================

  Future<void> _loginWithGitHub() async {
    final url = Uri.parse('${AppConfig.backendBaseUrl}/auth/github/login');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: AppState.isLoggedIn
          ? (_loadingProfile
                ? const Center(child: CircularProgressIndicator())
                : const LoggedInView())
          : LoggedOutView(onLogin: _loginWithGitHub),
    );
  }
}
