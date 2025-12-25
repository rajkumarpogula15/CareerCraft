import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppState {
  static bool isLoggedIn = false;
  static String? jwt;
  static Map<String, dynamic>? user;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Save token securely and update app state
  static Future<void> saveToken(String token) async {
    jwt = token;
    isLoggedIn = true;
    await _storage.write(key: 'jwt', value: token);
  }

  /// Load token from secure storage on app start
  static Future<void> loadToken() async {
    jwt = await _storage.read(key: 'jwt');
    isLoggedIn = jwt != null;
  }

  /// Login and persist token
  static Future<void> login({
    required String token,
    required Map<String, dynamic> profile,
  }) async {
    user = profile;
    await saveToken(token);
  }

  /// Logout and clear all stored data
  static Future<void> logout() async {
    jwt = null;
    user = null;
    isLoggedIn = false;
    await _storage.delete(key: 'jwt');
  }
}
