import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/presentation/pages/mindspace_view.dart';

void main() {
  testWidgets('Mindspace screen loads correctly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MindspaceView()));

    expect(find.textContaining('Ask MindSpace anything'), findsOneWidget);
  });
}
