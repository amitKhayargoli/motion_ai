//Shared Prefs provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError("Unexpected Error in Shared Pref");
});

// Provider
final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  return UserSessionService(prefs: ref.read(sharedPreferencesProvider));
});

class UserSessionService {
  final SharedPreferences _prefs;

  UserSessionService({required SharedPreferences prefs}) : _prefs = prefs;

  // Keys for Storing data
  static const String _keysIsLoggedIn = 'is_logged_in';
  static const String _keysUserId = 'user_id';
  static const String _keysUserEmail = 'user_email';

  //Store user session data
  Future<void> saveUserSession({
    required String userId,
    required String userEmail,
  }) async {
    await _prefs.setBool(_keysIsLoggedIn, true);
    await _prefs.setString(_keysUserId, userId);
    await _prefs.setString(_keysUserEmail, userEmail);
  }

  // Clear user session data
  Future<void> clearUserService() async {
    await _prefs.remove(_keysUserId);
    await _prefs.remove(_keysUserEmail);
    await _prefs.remove(_keysIsLoggedIn);
  }

  bool isLoggedIn() {
    return _prefs.getBool(_keysIsLoggedIn) ?? false;
  }

  String? getUserId() {
    return _prefs.getString(_keysUserId);
  }

  String? getUserEmail() {
    return _prefs.getString(_keysUserEmail);
  }
}
