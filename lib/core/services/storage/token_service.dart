import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'auth_token';
  final SharedPreferences _prefs;

  TokenService({required SharedPreferences prefs}) : _prefs = prefs;

  // Save token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  // Get token
  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  // Remove token (for logout)
  Future<void> removeToken() async {
    await _prefs.remove(_tokenKey);
  }
}
