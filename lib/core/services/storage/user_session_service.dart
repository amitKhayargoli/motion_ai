import 'package:shared_preferences/shared_preferences.dart';

class UserSessionService {
  final SharedPreferences _prefs;

  UserSessionService({required SharedPreferences prefs}) : _prefs = prefs;

  static const String _keysIsLoggedIn = 'is_logged_in';
  static const String _keysUserId = 'user_id';
  static const String _keysUserEmail = 'user_email';
  // username
  static const String _keysUsername = 'username';

  Future<void> saveUserSession({
    required String userId,
    required String userEmail,
    required String username,
  }) async {
    await _prefs.setBool(_keysIsLoggedIn, true);
    await _prefs.setString(_keysUserId, userId);
    await _prefs.setString(_keysUserEmail, userEmail);
    await _prefs.setString(_keysUsername, username);
  }

  Future<void> clearUserService() async {
    await _prefs.remove(_keysUserId);
    await _prefs.remove(_keysUserEmail);
    await _prefs.remove(_keysIsLoggedIn);
    await _prefs.remove(_keysUsername);
  }

  bool isLoggedIn() {
    return _prefs.getBool(_keysIsLoggedIn) ?? false;
  }

  String? getUserId() => _prefs.getString(_keysUserId);
  String? getUserEmail() => _prefs.getString(_keysUserEmail);
  String? getUsername() => _prefs.getString(_keysUsername);
}
