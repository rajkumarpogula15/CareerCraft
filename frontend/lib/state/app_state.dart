class AppState {
  static bool isLoggedIn = false;

  /// Stores GitHub profile data
  /// Example:
  /// {
  ///   name, username, avatar, bio,
  ///   followers, following, public_repos
  /// }
  static Map<String, dynamic>? user;
}
