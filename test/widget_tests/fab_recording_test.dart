import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/floating_button_widget.dart';

void main() {
  Widget buildWidget({required bool isRecording, required VoidCallback onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: RecordingFab(isRecording: isRecording, onTap: onTap),
      ),
    );
  }

  group('RecordingFab rendering', () {
    testWidgets('shows "Recording" text and icon when isRecording is true',
        (tester) async {
      await tester.pumpWidget(buildWidget(isRecording: true, onTap: () {}));

      expect(find.text('Recording'), findsOneWidget);
      expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
    });

    testWidgets(
        'hides "Recording" text but keeps icon when isRecording is false',
        (tester) async {
      await tester.pumpWidget(buildWidget(isRecording: false, onTap: () {}));

      expect(find.text('Recording'), findsNothing);
      expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
    });

    testWidgets('uses AnimatedContainer with correct padding when recording',
        (tester) async {
      await tester.pumpWidget(buildWidget(isRecording: true, onTap: () {}));

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final padding = animatedContainer.padding as EdgeInsets;
      expect(padding.left, 20);
      expect(padding.right, 20);
    });

    testWidgets('uses smaller padding when not recording', (tester) async {
      await tester.pumpWidget(buildWidget(isRecording: false, onTap: () {}));

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final padding = animatedContainer.padding as EdgeInsets;
      expect(padding.left, 14);
      expect(padding.right, 14);
    });
  });

  group('RecordingFab interaction', () {
    testWidgets('calls onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildWidget(isRecording: false, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('calls onTap when recording and tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildWidget(isRecording: true, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });
  });

  group('RecordingFab structure', () {
    testWidgets('wraps content in Material and InkWell', (tester) async {
      await tester.pumpWidget(buildWidget(isRecording: false, onTap: () {}));

      // RecordingFab uses Material > InkWell > AnimatedContainer
      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('contains InkWell with circular border radius', (tester) async {
      await tester.pumpWidget(buildWidget(isRecording: false, onTap: () {}));

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.borderRadius, BorderRadius.circular(30));
    });

    testWidgets('icon has correct color and size', (tester) async {
      await tester.pumpWidget(buildWidget(isRecording: false, onTap: () {}));

      final icon = tester.widget<Icon>(find.byIcon(Icons.graphic_eq));
      expect(icon.color, Colors.black);
      expect(icon.size, 24);
    });

    testWidgets('text has bold font weight when recording', (tester) async {
      await tester.pumpWidget(buildWidget(isRecording: true, onTap: () {}));

      final text = tester.widget<Text>(find.text('Recording'));
      expect(text.style!.fontWeight, FontWeight.bold);
      expect(text.style!.fontSize, 16);
    });
  });
}
