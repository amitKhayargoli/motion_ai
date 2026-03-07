import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/feature/auth/presentation/pages/login_page.dart';
import 'package:motion_ai/feature/auth/presentation/state/auth_state.dart';
import 'package:motion_ai/feature/auth/presentation/view_model/auth_viewmodel.dart';

import '../providers/mock_providers.dart';

// Fake AuthViewModel that doesn't depend on real usecases
class FakeAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState();

  @override
  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);
  }

  @override
  Future<void> register({
    String? username,
    required String email,
    required String password,
  }) async {}

  @override
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

void main() {
  Widget buildLoginPage() {
    return ProviderScope(
      overrides: [
        hiveServiceProvider.overrideWithValue(MockHiveService()),
        sharedPreferencesProvider.overrideWithValue(MockSharedPreferences()),
        tokenServiceProvider.overrideWithValue(MockTokenService()),
        authViewModelProvider.overrideWith(FakeAuthViewModel.new),
      ],
      child: const MaterialApp(home: LoginPage()),
    );
  }

  group('LoginPage rendering', () {
    testWidgets('displays Sign in button text', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('displays sign-in header text', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('Sign in to your'), findsOneWidget);
    });

    testWidgets('displays email and password labels', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('has two TextFormFields for email and password',
        (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('displays Sign Up navigation link', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });
  });

  group('LoginPage interactions', () {
    testWidgets('show password checkbox toggles visibility', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      final checkbox = find.byType(Checkbox);
      expect(tester.widget<Checkbox>(checkbox).value, isFalse);

      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(checkbox).value, isTrue);

      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(checkbox).value, isFalse);
    });

    testWidgets('can enter text in email field', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(emailField);
      expect(field.controller!.text, 'test@example.com');
    });

    testWidgets('can enter text in password field', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'newpassword123');
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(passwordField);
      expect(field.controller!.text, 'newpassword123');
    });

    testWidgets('Sign Up link navigates to SignupPage', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // After navigation, signup text should be visible
      expect(find.textContaining('Sign up a new'), findsOneWidget);
    });
  });
}
