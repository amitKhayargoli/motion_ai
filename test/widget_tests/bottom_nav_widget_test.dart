import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/bottom_nav_widget.dart';

void main() {
  Widget buildBottomNav({int selectedIndex = 0, Function(int)? onItemTapped}) {
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: BottomNavWidget(
          selectedIndex: selectedIndex,
          onItemTapped: onItemTapped ?? (_) {},
        ),
      ),
    );
  }

  group('BottomNavWidget rendering', () {
    testWidgets('displays all four navigation labels', (tester) async {
      await tester.pumpWidget(buildBottomNav());

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Recordings'), findsOneWidget);
      expect(find.text('Mindspace'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('displays all four navigation icons', (tester) async {
      await tester.pumpWidget(buildBottomNav());

      expect(find.byIcon(Icons.home_filled), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    });

    testWidgets('has four InkWell tap targets', (tester) async {
      await tester.pumpWidget(buildBottomNav());

      expect(find.byType(InkWell), findsNWidgets(4));
    });
  });

  group('BottomNavWidget selection', () {
    testWidgets('highlights the selected Home item with accent color',
        (tester) async {
      await tester.pumpWidget(buildBottomNav(selectedIndex: 0));

      final homeIcon = tester.widget<Icon>(find.byIcon(Icons.home_filled));
      expect(homeIcon.color, const Color(0xFFAEFB2A));
    });

    testWidgets('non-selected items use white70 color', (tester) async {
      await tester.pumpWidget(buildBottomNav(selectedIndex: 0));

      final micIcon = tester.widget<Icon>(find.byIcon(Icons.mic_none));
      expect(micIcon.color, Colors.white70);
    });

    testWidgets('highlights Recordings when selectedIndex is 1',
        (tester) async {
      await tester.pumpWidget(buildBottomNav(selectedIndex: 1));

      final micIcon = tester.widget<Icon>(find.byIcon(Icons.mic_none));
      expect(micIcon.color, const Color(0xFFAEFB2A));

      final homeIcon = tester.widget<Icon>(find.byIcon(Icons.home_filled));
      expect(homeIcon.color, Colors.white70);
    });

    testWidgets('highlights Mindspace when selectedIndex is 2', (tester) async {
      await tester.pumpWidget(buildBottomNav(selectedIndex: 2));

      final icon = tester.widget<Icon>(find.byIcon(Icons.lightbulb_outline));
      expect(icon.color, const Color(0xFFAEFB2A));
    });

    testWidgets('highlights Notes when selectedIndex is 3', (tester) async {
      await tester.pumpWidget(buildBottomNav(selectedIndex: 3));

      final icon = tester.widget<Icon>(find.byIcon(Icons.description_outlined));
      expect(icon.color, const Color(0xFFAEFB2A));
    });
  });

  group('BottomNavWidget interactions', () {
    testWidgets('tapping Home calls onItemTapped with 0', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        buildBottomNav(onItemTapped: (i) => tappedIndex = i),
      );

      await tester.tap(find.text('Home'));
      expect(tappedIndex, 0);
    });

    testWidgets('tapping Recordings calls onItemTapped with 1', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        buildBottomNav(onItemTapped: (i) => tappedIndex = i),
      );

      await tester.tap(find.text('Recordings'));
      expect(tappedIndex, 1);
    });

    testWidgets('tapping Mindspace calls onItemTapped with 2', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        buildBottomNav(onItemTapped: (i) => tappedIndex = i),
      );

      await tester.tap(find.text('Mindspace'));
      expect(tappedIndex, 2);
    });

    testWidgets('tapping Notes calls onItemTapped with 3', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        buildBottomNav(onItemTapped: (i) => tappedIndex = i),
      );

      await tester.tap(find.text('Notes'));
      expect(tappedIndex, 3);
    });
  });
}
