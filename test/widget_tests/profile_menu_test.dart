import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/feature/home/presentation/pages/user_profile_view.dart';

void main() {
  Widget buildProfileMenu({
    String text = 'Settings',
    IconData icon = Icons.settings_outlined,
    VoidCallback? press,
    bool isLogout = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ProfileMenu(
          text: text,
          icon: icon,
          press: press,
          isLogout: isLogout,
        ),
      ),
    );
  }

  group('ProfileMenu rendering', () {
    testWidgets('displays the menu text', (tester) async {
      await tester.pumpWidget(buildProfileMenu(text: 'My Account'));
      expect(find.text('My Account'), findsOneWidget);
    });

    testWidgets('displays the menu icon', (tester) async {
      await tester.pumpWidget(
          buildProfileMenu(icon: Icons.notifications_none_outlined));
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
    });

    testWidgets('displays forward arrow icon', (tester) async {
      await tester.pumpWidget(buildProfileMenu());
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('uses TextButton for tap area', (tester) async {
      await tester.pumpWidget(buildProfileMenu());
      expect(find.byType(TextButton), findsOneWidget);
    });
  });

  group('ProfileMenu normal style', () {
    testWidgets('non-logout item uses accent green icon color', (tester) async {
      await tester.pumpWidget(buildProfileMenu(isLogout: false));

      final icon = tester.widget<Icon>(find.byIcon(Icons.settings_outlined));
      expect(icon.color, const Color(0xFFAEFB2A));
    });

    testWidgets('non-logout item text uses white color', (tester) async {
      await tester.pumpWidget(buildProfileMenu(text: 'Settings'));

      final textWidget = tester.widget<Text>(find.text('Settings'));
      // Color is white with opacity (Colors.white.withOpacity(0.8))
      expect(textWidget.style?.color?.alpha, lessThan(255));
      expect(textWidget.style?.color?.red, 255);
    });
  });

  group('ProfileMenu logout style', () {
    testWidgets('logout item uses red icon color', (tester) async {
      await tester.pumpWidget(
        buildProfileMenu(
          text: 'Log Out',
          icon: Icons.logout,
          isLogout: true,
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.logout));
      expect(icon.color, Colors.redAccent);
    });

    testWidgets('logout item text uses red color', (tester) async {
      await tester.pumpWidget(
        buildProfileMenu(text: 'Log Out', isLogout: true),
      );

      final textWidget = tester.widget<Text>(find.text('Log Out'));
      expect(textWidget.style?.color, Colors.redAccent);
    });
  });

  group('ProfileMenu interactions', () {
    testWidgets('tapping calls press callback', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        buildProfileMenu(press: () => pressed = true),
      );

      await tester.tap(find.byType(TextButton));
      expect(pressed, true);
    });

    testWidgets('works when press is null', (tester) async {
      await tester.pumpWidget(buildProfileMenu(press: null));

      // Should not throw
      await tester.tap(find.byType(TextButton));
      await tester.pump();
    });
  });
}
