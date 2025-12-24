import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

import 'screens/home_screen.dart';
import 'screens/repos_screen.dart';
import 'screens/profile_screen.dart';
import 'state/app_state.dart';

void main() {
  runApp(const CareerCraftApp());
}

class CareerCraftApp extends StatelessWidget {
  const CareerCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF4F46E5),
        useMaterial3: true,
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int index = 0;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  late final List<Widget> screens = [
    HomeScreen(onLogin: _refresh),
    ReposScreen(),
    ProfileScreen(onLogout: _refresh),
  ];

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    // Handle app opened from terminated state
    final uri = await _appLinks.getInitialLink();
    _handleUri(uri);

    // Handle app opened while running
    _linkSub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;

    if (uri.scheme == 'careercraft' && uri.host == 'login-success') {
      AppState.isLoggedIn = true;
      setState(() {
        index = 0;
      });
    }
  }

  void _refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (value) => setState(() => index = value),
        selectedItemColor: const Color(0xFF4F46E5),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'My Repos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
