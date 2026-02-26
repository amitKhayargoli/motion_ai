import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:motion_ai/feature/notes/presentation/pages/notes_view.dart';

void main() {
  testWidgets('Notes screen loads correctly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotesListView()));

    expect(find.textContaining('NOTES'), findsOneWidget);
  });
}
