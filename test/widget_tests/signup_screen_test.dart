import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/feature/auth/presentation/pages/signup_page.dart';
import 'package:motion_ai/feature/auth/presentation/state/auth_state.dart';
import 'package:motion_ai/feature/auth/presentation/view_model/auth_viewmodel.dart';

import '../providers/mock_providers.dart';

class FakeAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState();

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> register({
    String? username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
  }

  @override
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

void main() {
  Widget buildSignupPage() {
    return ProviderScope(
      overrides: [
        hiveServiceProvider.overrideWithValue(MockHiveService()),
        sharedPreferencesProvider.overrideWithValue(MockSharedPreferences()),
        tokenServiceProvider.overrideWithValue(MockTokenService()),
        authViewModelProvider.overrideWith(FakeAuthViewModel.new),
      ],
      child: const MaterialApp(home: SignupPage()),
    );
  }

  group('SignupPage rendering', () {
    testWidgets('displays Sign Up button text', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('displays sign-up header text', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('Sign up a new'), findsOneWidget);
    });

    testWidgets('displays all four field labels', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('has four TextFormFields', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('displays Sign in navigation link', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      expect(find.text('Already a user? '), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });
  });

  group('SignupPage form validation', () {
    testWidgets('shows error when username is empty', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final usernameField = find.byType(TextFormField).at(0);
      await tester.enterText(usernameField, '');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Username cannot be empty'), findsOneWidget);
    });

    testWidgets('shows error when email is empty', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).at(1);
      await tester.enterText(emailField, '');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Email cannot be empty'), findsOneWidget);
    });

    testWidgets('shows error when email is invalid', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).at(1);
      await tester.enterText(emailField, 'notanemail');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField).at(2);
      await tester.enterText(passwordField, '');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Password cannot be empty'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField).at(2);
      await tester.enterText(passwordField, '12345');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('shows error when confirm password is empty', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField).at(2);
      await tester.enterText(passwordField, 'validpassword');

      final confirmField = find.byType(TextFormField).at(3);
      await tester.enterText(confirmField, '');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField).at(2);
      await tester.enterText(passwordField, 'validpassword');

      final confirmField = find.byType(TextFormField).at(3);
      await tester.enterText(confirmField, 'differentpassword');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('no validation error with valid inputs', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final usernameField = find.byType(TextFormField).at(0);
      await tester.enterText(usernameField, 'johndoe');

      final emailField = find.byType(TextFormField).at(1);
      await tester.enterText(emailField, 'valid@email.com');

      final passwordField = find.byType(TextFormField).at(2);
      await tester.enterText(passwordField, 'validpassword');

      final confirmField = find.byType(TextFormField).at(3);
      await tester.enterText(confirmField, 'validpassword');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      // Use pump() instead of pumpAndSettle() because the fake register
      // sets loading state which shows an infinite CircularProgressIndicator.
      await tester.pump();

      expect(find.text('Username cannot be empty'), findsNothing);
      expect(find.text('Email cannot be empty'), findsNothing);
      expect(find.text('Enter a valid email'), findsNothing);
      expect(find.text('Password cannot be empty'), findsNothing);
      expect(find.text('Password must be at least 6 characters'), findsNothing);
      expect(find.text('Please confirm your password'), findsNothing);
      expect(find.text('Passwords do not match'), findsNothing);
    });
  });

  group('SignupPage interactions', () {
    testWidgets('show password checkbox toggles visibility', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkbox).value, isFalse);

      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(checkbox).value, isTrue);

      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(checkbox).value, isFalse);
    });

    testWidgets('can enter text in username field', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final usernameField = find.byType(TextFormField).at(0);
      await tester.enterText(usernameField, 'johndoe');
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(usernameField);
      expect(field.controller!.text, 'johndoe');
    });

    testWidgets('can enter text in email field', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final emailField = find.byType(TextFormField).at(1);
      await tester.enterText(emailField, 'user@test.com');
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(emailField);
      expect(field.controller!.text, 'user@test.com');
    });

    testWidgets('can enter text in password field', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField).at(2);
      await tester.enterText(passwordField, 'secretpass');
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(passwordField);
      expect(field.controller!.text, 'secretpass');
    });

    testWidgets('can enter text in confirm password field', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      final confirmField = find.byType(TextFormField).at(3);
      await tester.enterText(confirmField, 'secretpass');
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(confirmField);
      expect(field.controller!.text, 'secretpass');
    });

    testWidgets('Sign in link navigates to LoginPage', (tester) async {
      await tester.pumpWidget(buildSignupPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      // After navigation, login page text should be visible
      expect(find.textContaining('Sign in to your'), findsOneWidget);
    });
  });
}
