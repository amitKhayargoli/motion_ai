import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/feature/auth/presentation/pages/login_page.dart';

import '../providers/mock_providers.dart';

void main() {
  testWidgets('LoginPage contains "Sign in" text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hiveServiceProvider.overrideWithValue(MockHiveService()),
          sharedPreferencesProvider.overrideWithValue(MockSharedPreferences()),
          tokenServiceProvider.overrideWithValue(MockTokenService()),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
  });
}
