import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/floating_button_widget.dart';

void main() {
  group("Testing if Floating Button changes Text when tapped", () {
    testWidgets(
      'Floating Action Button shows "Recording" text when isRecording is true',
      (tester) async {
        // Arrange: Pump the widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecordingFab(
                isRecording: true,
                onTap: () {}, // or (){} if you want tap
              ),
            ),
          ),
        );

        // Assert: Text "Recording" is displayed
        expect(find.text('Recording'), findsOneWidget);

        // Assert: The icon is present
        expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
      },
    );

    testWidgets(
      'Floating Button Text Doesnt change when isRecording is false',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecordingFab(isRecording: false, onTap: () {}),
            ),
          ),
        );

        expect(find.text('Recording'), findsNothing);
        expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
      },
    );
  });
}
