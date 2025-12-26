import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  static const String _githubLoginPath = '/auth/github/login';

  /// 🔐 Save JWT securely
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// 🔁 Restore JWT
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// 🚪 Logout
  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  /// 🚀 Start GitHub OAuth (SAFE)
  static Future<void> loginWithGitHub() async {
    // 🛑 Prevent infinite loop
    final existingToken = await getToken();
    if (existingToken != null) {
      return;
    }

    final Uri url = Uri.parse('${AppConfig.backendBaseUrl}$_githubLoginPath');

    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (!launched) {
      throw Exception('Could not launch GitHub login');
    }
  }
}
