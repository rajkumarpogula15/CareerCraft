import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

import 'screens/home_screen.dart';
import 'screens/repos_screen.dart';
import 'screens/profile_screen.dart';
import 'state/app_state.dart';
import 'services/auth_service.dart';
import 'widgets/top_bar.dart';

void main() {
  runApp(const CareerCraftApp());
}

class CareerCraftApp extends StatefulWidget {
  const CareerCraftApp({super.key});

  @override
  State<CareerCraftApp> createState() => _CareerCraftAppState();
}

class _CareerCraftAppState extends State<CareerCraftApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  int index = 0;

  late final List<Widget> screens = [
    HomeScreen(onLogin: _onLogin),
    const ReposScreen(),
    ProfileScreen(
      onLogout: _refresh,
      onLogin: _onLogin, // ✅ FIX: REQUIRED PARAM
    ),
  ];

  @override
  void initState() {
    super.initState();
    _restoreSession();
    _initDeepLinks();
  }

  /// Restore JWT from secure storage
  Future<void> _restoreSession() async {
    final token = await AuthService.getToken();
    if (token != null) {
      AppState.jwt = token;
      AppState.isLoggedIn = true;
      setState(() {});
    }
  }

  /// Handle deep links from GitHub OAuth
  void _initDeepLinks() async {
    final uri = await _appLinks.getInitialLink();
    _handleUri(uri);

    _linkSub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri? uri) async {
    if (uri == null) return;

    if (uri.scheme == 'careercraft' &&
        uri.host == 'login-success' &&
        uri.queryParameters['token'] != null) {
      final token = uri.queryParameters['token']!;

      await AuthService.saveToken(token);
      AppState.jwt = token;
      AppState.isLoggedIn = true;

      setState(() {
        index = 0; // go back to Home after login
      });
    }
  }

  /// Called after login or logout to rebuild UI
  void _refresh() {
    setState(() {});
  }

  /// Trigger GitHub OAuth (used by Home & Profile logged-out views)
  void _onLogin() {
    AuthService.loginWithGitHub();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF4F46E5),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: const TopBar(),
        body: screens[index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: index,
          onTap: (value) => setState(() => index = value),
          selectedItemColor: const Color(0xFF4F46E5),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: 'My Repos',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
