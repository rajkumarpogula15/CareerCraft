import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription? _sub;

  static void init({required void Function(String token) onLoginSuccess}) {
    _sub = _appLinks.uriLinkStream.listen((uri) {
      if (uri == null) return;

      if (uri.scheme == 'careercraft' && uri.host == 'login-success') {
        final token = uri.queryParameters['token'];
        if (token != null) {
          onLoginSuccess(token);
        }
      }
    });
  }

  static void dispose() {
    _sub?.cancel();
  }
}
