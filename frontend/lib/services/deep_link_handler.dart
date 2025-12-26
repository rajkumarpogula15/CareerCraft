import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';

class DeepLinkHandler {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;
  static bool _handled = false; // 🔒 prevents double execution

  static void init(BuildContext context) {
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) async {
        if (_handled) return;

        if (uri.scheme == 'myapp' &&
            uri.host == 'auth' &&
            uri.path == '/callback') {
          final token = uri.queryParameters['token'];

          if (token != null && token.isNotEmpty) {
            _handled = true;

            await AuthService.saveToken(token);

            // Navigate to home/dashboard
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (_) => false);
          }
        }
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  static void dispose() {
    _sub?.cancel();
    _handled = false;
  }
}
