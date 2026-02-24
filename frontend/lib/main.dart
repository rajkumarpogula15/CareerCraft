import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/mock_interview_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/repos_screen.dart';
import 'services/auth_service.dart';
import 'state/app_state.dart';
import 'state/theme_controller.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/top_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const CareerCraftApp());
}

class CareerCraftApp extends StatefulWidget {
  const CareerCraftApp({super.key});

  @override
  State<CareerCraftApp> createState() => _CareerCraftAppState();
}

class _CareerCraftAppState extends State<CareerCraftApp> {
  final AppLinks _appLinks = AppLinks();
  final ThemeController _themeController = ThemeController();
  StreamSubscription<Uri>? _linkSub;

  int index = 0;

  late final List<Widget> screens = [
    HomeScreen(onLogin: _onLogin),
    const ReposScreen(),
    const MockInterviewScreen(),
    ProfileScreen(onLogout: _refresh, onLogin: _onLogin),
  ];

  @override
  void initState() {
    super.initState();
    _themeController.load();
    _restoreSession();
    _initDeepLinks();
  }

  Future<void> _restoreSession() async {
    final token = await AuthService.getToken();
    if (token != null) {
      AppState.jwt = token;
      AppState.isLoggedIn = true;
      setState(() {});
    }
  }

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

      setState(() => index = 0);
    }
  }

  void _refresh() {
    setState(() {});
  }

  void _onLogin() {
    AuthService.loginWithGitHub();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _themeController.themeMode,
          home: Scaffold(
            appBar: TopBar(themeController: _themeController),
            body: screens[index],
            bottomNavigationBar: BottomBar(
              currentIndex: index,
              onTap: (value) => setState(() => index = value),
            ),
          ),
        );
      },
    );
  }
}
