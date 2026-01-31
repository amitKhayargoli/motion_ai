import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/feature/auth/presentation/pages/signup_page.dart';

import '../providers/mock_providers.dart';

void main() {
  testWidgets('SignupPage contains "Sign Up" text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hiveServiceProvider.overrideWithValue(MockHiveService()),
          sharedPreferencesProvider.overrideWithValue(MockSharedPreferences()),
          tokenServiceProvider.overrideWithValue(MockTokenService()),
        ],
        child: const MaterialApp(home: SignupPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sign Up'), findsOneWidget);
  });
}
