import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/notes_card_widget.dart';

void main() {
  Widget buildNoteCard({
    String title = 'Test Note',
    String content = 'Some content here',
    String category = 'Manual Note',
    String time = '01 Jan 2025 • 12:00',
    bool isPinned = false,
    bool isSelected = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: NoteCard(
          title: title,
          content: content,
          category: category,
          time: time,
          isPinned: isPinned,
          isSelected: isSelected,
        ),
      ),
    );
  }

  group('NoteCard rendering', () {
    testWidgets('displays the title', (tester) async {
      await tester.pumpWidget(buildNoteCard(title: 'My Note Title'));
      expect(find.text('My Note Title'), findsOneWidget);
    });

    testWidgets('displays the content preview', (tester) async {
      await tester.pumpWidget(buildNoteCard(content: 'Preview text'));
      expect(find.text('Preview text'), findsOneWidget);
    });

    testWidgets('displays the category label', (tester) async {
      await tester.pumpWidget(buildNoteCard(category: 'Voice Transcript'));
      expect(find.text('Voice Transcript'), findsOneWidget);
    });

    testWidgets('displays the time', (tester) async {
      await tester.pumpWidget(buildNoteCard(time: '15 Mar 2025 • 09:30'));
      expect(find.text('15 Mar 2025 • 09:30'), findsOneWidget);
    });

    testWidgets('hides content section when content is empty', (tester) async {
      await tester.pumpWidget(buildNoteCard(content: ''));
      // Only title, category, and time should be visible
      expect(find.text('Test Note'), findsOneWidget);
      expect(find.text('Manual Note'), findsOneWidget);
    });
  });

  group('NoteCard category types', () {
    testWidgets('Voice Transcript shows mic icon', (tester) async {
      await tester.pumpWidget(buildNoteCard(category: 'Voice Transcript'));
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('Manual Note does not show mic icon', (tester) async {
      await tester.pumpWidget(buildNoteCard(category: 'Manual Note'));
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('Meeting Summary does not show mic icon', (tester) async {
      await tester.pumpWidget(buildNoteCard(category: 'Meeting Summary'));
      expect(find.byIcon(Icons.mic), findsNothing);
    });
  });

  group('NoteCard states', () {
    testWidgets('shows pin icon when isPinned is true', (tester) async {
      await tester.pumpWidget(buildNoteCard(isPinned: true));
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('hides pin icon when isPinned is false', (tester) async {
      await tester.pumpWidget(buildNoteCard(isPinned: false));
      expect(find.byIcon(Icons.push_pin), findsNothing);
    });

    testWidgets('shows check_circle when isSelected is true', (tester) async {
      await tester.pumpWidget(buildNoteCard(isSelected: true));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('hides check_circle when isSelected is false', (tester) async {
      await tester.pumpWidget(buildNoteCard(isSelected: false));
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('selected state hides pin icon even if isPinned is true',
        (tester) async {
      await tester.pumpWidget(buildNoteCard(isSelected: true, isPinned: true));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsNothing);
    });
  });
}
