import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/app.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/services/hive/hive_service.dart';
import 'package:motion_ai/core/services/storage/token_service.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPrefs = await SharedPreferences.getInstance();

  final hiveService = HiveService();
  await hiveService.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        tokenServiceProvider.overrideWithValue(
          TokenService(prefs: sharedPrefs),
        ),
        hiveServiceProvider.overrideWithValue(hiveService),
        userSessionServiceProvider.overrideWithValue(
          UserSessionService(prefs: sharedPrefs),
        ),
      ],
      child: const App(),
    ),
  );
}
